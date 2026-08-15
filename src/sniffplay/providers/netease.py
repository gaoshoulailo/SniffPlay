from __future__ import annotations

import time
from collections.abc import Mapping
from typing import Any

import httpx

from sniffplay.models import StreamInfo, Track
from sniffplay.providers.base import MusicProvider, ProviderError, StreamUnavailableError


class NeteaseProvider(MusicProvider):
    id = "netease"
    display_name = "网易云音乐"

    _base_url = "https://music.163.com"
    _headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 SniffPlay/0.1"
        ),
        "Referer": "https://music.163.com/",
        "Accept": "application/json,text/plain,*/*",
    }

    def __init__(
        self,
        *,
        transport: httpx.AsyncBaseTransport | None = None,
        cache_ttl_seconds: int = 60,
    ) -> None:
        self._transport = transport
        self._cache_ttl_seconds = cache_ttl_seconds
        self._search_cache: dict[
            tuple[str, int], tuple[float, tuple[Track, ...]]
        ] = {}
        self._lyrics_cache: dict[str, tuple[float, str | None]] = {}

    def _client(self) -> httpx.AsyncClient:
        return httpx.AsyncClient(
            base_url=self._base_url,
            headers=self._headers,
            follow_redirects=True,
            timeout=httpx.Timeout(12, connect=5),
            transport=self._transport,
        )

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        cleaned_query = query.strip()
        if not cleaned_query:
            return []
        safe_limit = max(1, min(limit, 50))
        cache_key = (cleaned_query.casefold(), safe_limit)
        cached = self._search_cache.get(cache_key)
        if cached and cached[0] > time.monotonic():
            return list(cached[1])

        try:
            async with self._client() as client:
                response = await client.get(
                    "/api/cloudsearch/pc",
                    params={
                        "s": cleaned_query,
                        "type": 1,
                        "offset": 0,
                        "total": "true",
                        "limit": safe_limit,
                    },
                )
                response.raise_for_status()
                payload = response.json()
        except (httpx.HTTPError, ValueError) as error:
            raise ProviderError("网易云搜索暂时不可用") from error

        if not isinstance(payload, Mapping) or payload.get("code") != 200:
            raise ProviderError("网易云返回了无效的搜索响应")
        result = payload.get("result")
        songs = result.get("songs", []) if isinstance(result, Mapping) else []
        tracks = [
            track
            for song in songs
            if isinstance(song, Mapping)
            if (track := self._parse_track(song)) is not None
        ][:safe_limit]
        self._store_search_cache(cache_key, tracks)
        return tracks

    async def resolve_stream(self, track: Track) -> StreamInfo:
        if track.provider_id != self.id or not track.provider_track_id.isdigit():
            raise StreamUnavailableError("无效的网易云歌曲标识")
        outer_url = f"/song/media/outer/url?id={track.provider_track_id}.mp3"
        try:
            async with self._client() as client:
                async with client.stream(
                    "GET", outer_url, headers={"Range": "bytes=0-1023"}
                ) as response:
                    content_type = response.headers.get("content-type", "").lower()
                    if response.status_code not in (200, 206) or not content_type.startswith(
                        "audio/"
                    ):
                        raise StreamUnavailableError(
                            "该歌曲不是网易云公开可播放资源"
                        )
                    first_chunk = await anext(response.aiter_bytes(1024), b"")
                    if not first_chunk:
                        raise StreamUnavailableError("网易云返回了空的音频资源")
                    stream_url = str(response.url)
        except StreamUnavailableError:
            raise
        except httpx.HTTPError as error:
            raise ProviderError("网易云播放地址解析失败") from error

        return StreamInfo(
            url=stream_url,
            http_headers={
                "User-Agent": self._headers["User-Agent"],
                "Referer": self._headers["Referer"],
            },
        )

    async def get_lyrics(self, track: Track) -> str | None:
        track_id = track.provider_track_id
        if track.provider_id != self.id or not track_id.isdigit():
            return None
        cached = self._lyrics_cache.get(track_id)
        if cached and cached[0] > time.monotonic():
            return cached[1]
        try:
            async with self._client() as client:
                response = await client.get(
                    "/api/song/lyric",
                    params={"id": track_id, "lv": 1, "kv": 1, "tv": -1},
                )
                response.raise_for_status()
                payload = response.json()
        except (httpx.HTTPError, ValueError):
            return None
        lyrics: str | None = None
        if isinstance(payload, Mapping):
            lrc = payload.get("lrc")
            if isinstance(lrc, Mapping) and isinstance(lrc.get("lyric"), str):
                lyrics = lrc["lyric"]
        self._lyrics_cache[track_id] = (time.monotonic() + 600, lyrics)
        return lyrics

    def _parse_track(self, song: Mapping[str, Any]) -> Track | None:
        track_id = song.get("id")
        title = song.get("name")
        if not isinstance(track_id, int) or not isinstance(title, str):
            return None
        artists_data = song.get("ar") or song.get("artists")
        artist_names = []
        if isinstance(artists_data, list):
            artist_names = [
                artist["name"]
                for artist in artists_data
                if isinstance(artist, Mapping) and isinstance(artist.get("name"), str)
            ]
        album_data = song.get("al") or song.get("album")
        album_name = ""
        artwork_url: str | None = None
        if isinstance(album_data, Mapping):
            if isinstance(album_data.get("name"), str):
                album_name = album_data["name"]
            if isinstance(album_data.get("picUrl"), str):
                artwork_url = self._https_url(album_data["picUrl"])
        duration = song.get("dt") if isinstance(song.get("dt"), int) else song.get("duration")
        duration_ms = duration if isinstance(duration, int) else 0
        return Track(
            provider_id=self.id,
            provider_track_id=str(track_id),
            title=title,
            artist=" / ".join(artist_names) or "未知歌手",
            album=album_name,
            duration_ms=duration_ms,
            accent="#d94f60",
            artwork_url=artwork_url,
            source_name=self.display_name,
        )

    def _store_search_cache(
        self, cache_key: tuple[str, int], tracks: list[Track]
    ) -> None:
        now = time.monotonic()
        if len(self._search_cache) >= 50:
            self._search_cache = {
                key: value for key, value in self._search_cache.items() if value[0] > now
            }
            if len(self._search_cache) >= 50:
                oldest_key = min(self._search_cache, key=lambda key: self._search_cache[key][0])
                self._search_cache.pop(oldest_key, None)
        self._search_cache[cache_key] = (
            now + self._cache_ttl_seconds,
            tuple(tracks),
        )

    @staticmethod
    def _https_url(url: str) -> str:
        return "https://" + url.removeprefix("http://") if url.startswith("http://") else url
