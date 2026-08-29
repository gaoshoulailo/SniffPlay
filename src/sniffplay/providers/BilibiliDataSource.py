from __future__ import annotations

import asyncio
import hashlib
import html
import re
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass, replace
from pathlib import Path, PurePosixPath
from typing import Any, AsyncIterator, Iterator, Mapping
from urllib.parse import urlencode, urlparse

import httpx

from sniffplay.config import application_directory
from sniffplay.models import StreamInfo, Track
from sniffplay.providers.base import (
    MusicProvider,
    ProviderError,
    StreamUnavailableError,
)

NAV_URL = "https://api.bilibili.com/x/web-interface/nav"
SEARCH_URL = "https://api.bilibili.com/x/web-interface/wbi/search/all/v2"
VIEW_URL = "https://api.bilibili.com/x/web-interface/view"
PLAYURL_URL = "https://api.bilibili.com/x/player/wbi/playurl"
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/140.0.0.0 Safari/537.36"
)
DEFAULT_HEADERS = {
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "zh-CN,zh;q=0.9",
    "User-Agent": USER_AGENT,
}
MIXIN_KEY_ENC_TAB = (
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52,
)
FORBIDDEN_CHARS_RE = re.compile(r"[!'()*]")
HTML_TAG_RE = re.compile(r"<[^>]+>")
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}
WBI_REFRESH_CODES = {-403, -352, -412}
COVER_DOWNLOAD_CONCURRENCY = 10
COVER_DOWNLOAD_TIMEOUT = 4.0
COVER_BATCH_TIMEOUT = 6.0
MAX_COVER_BYTES = 2 * 1024 * 1024
COVER_EDGE_PX = 512


class BilibiliAPIError(ProviderError):
    """Raised when Bilibili returns an invalid or unsuccessful response."""


@dataclass(frozen=True, slots=True)
class WBIKeys:
    img_key: str
    sub_key: str
    fetched_at: float


@dataclass(frozen=True, slots=True)
class _AudioStream:
    url: str
    audio_id: int
    bandwidth: int
    quality_rank: int


def _key_from_url(url: str) -> str:
    stem = PurePosixPath(urlparse(url).path).stem
    if not stem:
        raise BilibiliAPIError("Bilibili WBI 密钥地址无效")
    return stem


def _make_mixin_key(img_key: str, sub_key: str) -> str:
    raw_key = img_key + sub_key
    if len(raw_key) < 64:
        raise BilibiliAPIError("Bilibili WBI 密钥长度异常")
    return "".join(raw_key[index] for index in MIXIN_KEY_ENC_TAB)[:32]


def _sign_params(
    params: Mapping[str, Any],
    keys: WBIKeys,
    *,
    timestamp: int | None = None,
) -> dict[str, str]:
    signed = {
        str(key): FORBIDDEN_CHARS_RE.sub("", str(value))
        for key, value in params.items()
        if value is not None
    }
    signed["wts"] = str(int(time.time()) if timestamp is None else timestamp)
    canonical_query = urlencode(sorted(signed.items()))
    signed["w_rid"] = hashlib.md5(
        (canonical_query + _make_mixin_key(keys.img_key, keys.sub_key)).encode(
            "utf-8"
        )
    ).hexdigest()
    return signed


def _clean_text(value: Any, fallback: str = "") -> str:
    if not isinstance(value, str):
        return fallback
    cleaned = html.unescape(HTML_TAG_RE.sub("", value)).strip()
    return cleaned or fallback


def _cover_url(value: Any) -> str | None:
    url = _clean_text(value)
    if url.startswith("//"):
        url = f"https:{url}"
    elif url.startswith("http://"):
        url = f"https://{url.removeprefix('http://')}"
    elif not url.startswith("https://"):
        return None

    hostname = urlparse(url).hostname or ""
    if hostname == "hdslb.com" or hostname.endswith(".hdslb.com"):
        original = url.split("?", 1)[0].split("@", 1)[0]
        return f"{original}@{COVER_EDGE_PX}w_{COVER_EDGE_PX}h_1c.jpg"
    return url


def _duration_ms(value: Any) -> int:
    if isinstance(value, (int, float)):
        return max(0, int(float(value) * 1000))
    if not isinstance(value, str):
        return 0
    parts = value.strip().split(":")
    try:
        seconds = 0
        for part in parts:
            seconds = seconds * 60 + int(part)
    except ValueError:
        return 0
    return max(0, seconds * 1000)


class BilibiliDataSource(MusicProvider):
    """Search Bilibili videos and resolve their public DASH audio streams."""

    id = "bilibili"
    display_name = "Bilibili"

    def __init__(
        self,
        *,
        timeout: float = 20.0,
        key_ttl: float = 600.0,
        page: int = 1,
        client: httpx.AsyncClient | None = None,
        cover_cache_dir: Path | None = None,
    ) -> None:
        if timeout <= 0:
            raise ValueError("timeout must be greater than zero")
        if key_ttl <= 0:
            raise ValueError("key_ttl must be greater than zero")
        if page < 1:
            raise ValueError("page must be at least 1")
        self._timeout = timeout
        self._key_ttl = key_ttl
        self._page = page
        self._external_client = client
        self._cover_cache_dir = cover_cache_dir or (
            application_directory() / "data" / "cache" / "covers" / self.id
        )
        self._keys: WBIKeys | None = None

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        keyword = query.strip()
        if not keyword or limit <= 0:
            return []

        async with self._client_scope() as client:
            payload = await self._search_page(client, keyword)
            tracks = list(self._tracks_from_search(payload, limit=limit))
            return await self._cache_track_covers(client, tracks)

    async def resolve_stream(self, track: Track) -> StreamInfo:
        if track.provider_id != self.id:
            raise ProviderError("歌曲不属于 Bilibili 数据源")
        bvid = track.provider_track_id.strip()
        if not bvid:
            raise ProviderError("Bilibili 歌曲缺少 bvid")

        async with self._client_scope() as client:
            video = await self._video_info(client, bvid)
            pages = video.get("pages")
            if not isinstance(pages, list) or not pages:
                raise StreamUnavailableError("该视频没有可播放的分P")
            first_page = pages[0]
            if not isinstance(first_page, dict):
                raise StreamUnavailableError("该视频的分P信息无效")
            try:
                aid = int(video["aid"])
                cid = int(first_page["cid"])
            except (KeyError, TypeError, ValueError) as error:
                raise StreamUnavailableError("该视频缺少播放参数") from error

            payload = await self._playurl(
                client,
                aid=aid,
                bvid=bvid,
                cid=cid,
            )
            stream = _select_best_audio(payload)

        return StreamInfo(
            url=stream.url,
            http_headers={
                "User-Agent": USER_AGENT,
                "Referer": f"https://www.bilibili.com/video/{bvid}/",
                "Origin": "https://www.bilibili.com",
            },
            cover_url=_cover_url(video.get("pic")) if isinstance(video, dict) else None,
        )

    @asynccontextmanager
    async def _client_scope(self) -> AsyncIterator[httpx.AsyncClient]:
        if self._external_client is not None:
            yield self._external_client
            return
        async with httpx.AsyncClient(
            headers=DEFAULT_HEADERS,
            timeout=self._timeout,
            follow_redirects=True,
        ) as client:
            yield client

    async def _json_get(
        self,
        client: httpx.AsyncClient,
        url: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        for attempt in range(3):
            try:
                response = await client.get(url, **kwargs)
                response.raise_for_status()
            except httpx.HTTPStatusError as error:
                if (
                    error.response.status_code not in RETRYABLE_STATUS_CODES
                    or attempt == 2
                ):
                    raise BilibiliAPIError(
                        f"Bilibili 请求失败：HTTP {error.response.status_code}"
                    ) from error
            except httpx.RequestError as error:
                if attempt == 2:
                    raise BilibiliAPIError("无法连接 Bilibili") from error
            else:
                try:
                    payload = response.json()
                except ValueError as error:
                    raise BilibiliAPIError("Bilibili 返回了无效的 JSON") from error
                if not isinstance(payload, dict):
                    raise BilibiliAPIError("Bilibili 返回了无法识别的数据")
                return payload

            await asyncio.sleep(0.4 * (2**attempt))

        raise BilibiliAPIError("Bilibili 请求失败")

    async def _cache_track_covers(
        self,
        client: httpx.AsyncClient,
        tracks: list[Track],
    ) -> list[Track]:
        try:
            await asyncio.to_thread(
                self._cover_cache_dir.mkdir,
                parents=True,
                exist_ok=True,
            )
        except OSError:
            return [replace(track, cover_url=None) for track in tracks]

        semaphore = asyncio.Semaphore(COVER_DOWNLOAD_CONCURRENCY)

        async def cache(track: Track) -> Track:
            if not track.cover_url:
                return track
            async with semaphore:
                local_uri = await self._cache_cover(client, track.cover_url)
            return replace(track, cover_url=local_uri, source_cover_url=track.cover_url)

        tasks = [asyncio.create_task(cache(track)) for track in tracks]
        done, pending = await asyncio.wait(tasks, timeout=COVER_BATCH_TIMEOUT)
        for task in pending:
            task.cancel()
        if pending:
            await asyncio.gather(*pending, return_exceptions=True)

        cached_tracks: list[Track] = []
        for track, task in zip(tracks, tasks, strict=True):
            if task not in done or task.cancelled() or task.exception() is not None:
                cached_tracks.append(replace(track, cover_url=None))
            else:
                cached_tracks.append(task.result())
        return cached_tracks

    async def _cache_cover(
        self,
        client: httpx.AsyncClient,
        remote_url: str,
    ) -> str | None:
        cache_key = hashlib.sha256(remote_url.encode("utf-8")).hexdigest()
        destination = self._cover_cache_dir / f"{cache_key}.jpg"
        try:
            if await asyncio.to_thread(_is_usable_cache_file, destination):
                return destination.resolve().as_uri()

            response = await client.get(
                remote_url,
                headers={"Referer": "https://www.bilibili.com/"},
                timeout=COVER_DOWNLOAD_TIMEOUT,
            )
            response.raise_for_status()
            content_type = response.headers.get("content-type", "").lower()
            content = response.content
            if not content_type.startswith("image/"):
                return None
            if not content or len(content) > MAX_COVER_BYTES:
                return None

            temporary = destination.with_name(
                f".{destination.name}.{time.time_ns()}.tmp"
            )
            try:
                await asyncio.to_thread(temporary.write_bytes, content)
                await asyncio.to_thread(temporary.replace, destination)
            finally:
                if temporary.exists():
                    await asyncio.to_thread(temporary.unlink, missing_ok=True)
            return destination.resolve().as_uri()
        except (httpx.HTTPError, OSError):
            return None

    async def _get_wbi_keys(
        self,
        client: httpx.AsyncClient,
        *,
        force_refresh: bool = False,
    ) -> WBIKeys:
        if (
            not force_refresh
            and self._keys is not None
            and time.monotonic() - self._keys.fetched_at < self._key_ttl
        ):
            return self._keys

        payload = await self._json_get(client, NAV_URL)
        data = payload.get("data")
        wbi_img = data.get("wbi_img") if isinstance(data, dict) else None
        if not isinstance(wbi_img, dict):
            raise BilibiliAPIError("Bilibili 未返回 WBI 密钥")
        try:
            keys = WBIKeys(
                img_key=_key_from_url(str(wbi_img["img_url"])),
                sub_key=_key_from_url(str(wbi_img["sub_url"])),
                fetched_at=time.monotonic(),
            )
        except KeyError as error:
            raise BilibiliAPIError("Bilibili WBI 密钥字段缺失") from error
        self._keys = keys
        return keys

    async def _search_page(
        self,
        client: httpx.AsyncClient,
        keyword: str,
    ) -> dict[str, Any]:
        for attempt in range(2):
            keys = await self._get_wbi_keys(
                client,
                force_refresh=attempt > 0,
            )
            payload = await self._json_get(
                client,
                SEARCH_URL,
                params=_sign_params(
                    {"keyword": keyword, "page": self._page},
                    keys,
                ),
                headers={
                    "Referer": "https://search.bilibili.com/",
                },
            )
            if payload.get("code") == 0:
                return payload
            if attempt == 0 and payload.get("code") in WBI_REFRESH_CODES:
                continue
            raise BilibiliAPIError(
                "Bilibili 搜索失败："
                f"code={payload.get('code')}, message={payload.get('message')!r}"
            )
        raise BilibiliAPIError("刷新 WBI 密钥后搜索仍然失败")

    def _tracks_from_search(
        self,
        payload: Mapping[str, Any],
        *,
        limit: int,
    ) -> Iterator[Track]:
        data = payload.get("data")
        sections = data.get("result") if isinstance(data, dict) else None
        if not isinstance(sections, list):
            return

        emitted = 0
        for section in sections:
            if not isinstance(section, dict) or section.get("result_type") != "video":
                continue
            items = section.get("data")
            if not isinstance(items, list):
                continue
            for item in items:
                if not isinstance(item, dict):
                    continue
                bvid = str(item.get("bvid") or "").strip()
                if not bvid:
                    continue
                yield Track(
                    provider_id=self.id,
                    provider_track_id=bvid,
                    title=_clean_text(item.get("title"), "未知视频"),
                    artist=_clean_text(
                        item.get("author") or item.get("up_name"),
                        "未知UP主",
                    ),
                    album=_clean_text(
                        item.get("typename") or item.get("type_name"),
                        "Bilibili 视频",
                    ),
                    duration_ms=_duration_ms(item.get("duration")),
                    accent="#fb7299",
                    cover_url=_cover_url(item.get("pic")),
                )
                emitted += 1
                if emitted >= limit:
                    return

    async def _video_info(
        self,
        client: httpx.AsyncClient,
        bvid: str,
    ) -> dict[str, Any]:
        payload = await self._json_get(client, VIEW_URL, params={"bvid": bvid})
        data = payload.get("data")
        if payload.get("code") != 0 or not isinstance(data, dict):
            raise StreamUnavailableError(
                "无法获取 Bilibili 视频信息："
                f"code={payload.get('code')}, message={payload.get('message')!r}"
            )
        return data

    async def _playurl(
        self,
        client: httpx.AsyncClient,
        *,
        aid: int,
        bvid: str,
        cid: int,
    ) -> dict[str, Any]:
        request_params = {
            "avid": aid,
            "bvid": bvid,
            "cid": cid,
            "qn": 127,
            "type": "",
            "otype": "json",
            "high_quality": 1,
            "fnver": 0,
            "fnval": 4048,
            "fourk": 1,
        }
        referer = f"https://www.bilibili.com/video/{bvid}/"
        for attempt in range(2):
            keys = await self._get_wbi_keys(
                client,
                force_refresh=attempt > 0,
            )
            payload = await self._json_get(
                client,
                PLAYURL_URL,
                params=_sign_params(request_params, keys),
                headers={
                    "Referer": referer,
                    "Origin": "https://www.bilibili.com",
                },
            )
            if payload.get("code") == 0:
                return payload
            if attempt == 0 and payload.get("code") in WBI_REFRESH_CODES:
                continue
            if payload.get("code") in {-10403, -404, 87007}:
                raise StreamUnavailableError("该视频当前没有公开可播放音频")
            raise BilibiliAPIError(
                "Bilibili 播放地址解析失败："
                f"code={payload.get('code')}, message={payload.get('message')!r}"
            )
        raise BilibiliAPIError("刷新 WBI 密钥后仍无法解析播放地址")


def _iter_audio_streams(payload: Mapping[str, Any]) -> Iterator[_AudioStream]:
    data = payload.get("data")
    dash = data.get("dash") if isinstance(data, dict) else None
    if not isinstance(dash, dict):
        return

    groups: list[tuple[int, Any]] = [(1, dash.get("audio"))]
    dolby = dash.get("dolby")
    if isinstance(dolby, dict):
        groups.append((2, dolby.get("audio")))
    flac = dash.get("flac")
    if isinstance(flac, dict):
        groups.append((3, flac.get("audio")))

    seen_urls: set[str] = set()
    for quality_rank, values in groups:
        if isinstance(values, dict):
            values = [values]
        if not isinstance(values, list):
            continue
        for value in values:
            if not isinstance(value, dict):
                continue
            url = value.get("baseUrl") or value.get("base_url")
            if not isinstance(url, str) or not url or url in seen_urls:
                continue
            seen_urls.add(url)
            try:
                audio_id = int(value.get("id") or 0)
                bandwidth = int(value.get("bandwidth") or 0)
            except (TypeError, ValueError):
                continue
            yield _AudioStream(
                url=url,
                audio_id=audio_id,
                bandwidth=bandwidth,
                quality_rank=quality_rank,
            )


def _select_best_audio(payload: Mapping[str, Any]) -> _AudioStream:
    streams = list(_iter_audio_streams(payload))
    if not streams:
        raise StreamUnavailableError("Bilibili 未返回公开 DASH 音频流")
    known_quality = {30251: 5, 30250: 4, 30280: 3, 30232: 2, 30216: 1}
    return max(
        streams,
        key=lambda stream: (
            stream.quality_rank,
            known_quality.get(stream.audio_id, 0),
            stream.bandwidth,
        ),
    )


def _is_usable_cache_file(path: Path) -> bool:
    try:
        return path.is_file() and 0 < path.stat().st_size <= MAX_COVER_BYTES
    except OSError:
        return False
