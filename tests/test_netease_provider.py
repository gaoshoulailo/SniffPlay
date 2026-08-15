from __future__ import annotations

import httpx
import pytest

from sniffplay.models import Track
from sniffplay.providers.base import StreamUnavailableError
from sniffplay.providers.netease import NeteaseProvider


def _track(track_id: str = "1960404337") -> Track:
    return Track(
        "netease",
        track_id,
        "蓝莲花（现场版）",
        "许巍",
        "现场版合辑",
        502_218,
    )


async def test_netease_search_normalizes_and_caches_results() -> None:
    search_calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal search_calls
        assert request.url.path == "/api/cloudsearch/pc"
        search_calls += 1
        return httpx.Response(
            200,
            json={
                "code": 200,
                "result": {
                    "songs": [
                        {
                            "id": 1960404337,
                            "name": "蓝莲花（现场版）",
                            "ar": [{"name": "许巍"}],
                            "al": {
                                "name": "现场版合辑",
                                "picUrl": "http://example.test/cover.jpg",
                            },
                            "dt": 502218,
                        }
                    ]
                },
            },
        )

    provider = NeteaseProvider(transport=httpx.MockTransport(handler))
    first = await provider.search("蓝莲花")
    second = await provider.search("蓝莲花")

    assert first == second
    assert search_calls == 1
    assert first[0].provider_track_id == "1960404337"
    assert first[0].source_display == "网易云音乐"
    assert first[0].artwork_url == "https://example.test/cover.jpg"


async def test_netease_resolves_only_audio_redirects() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "music.163.com":
            return httpx.Response(
                302, headers={"location": "https://cdn.test/audio.mp3"}
            )
        return httpx.Response(
            206,
            headers={"content-type": "audio/mpeg"},
            content=b"ID3" + bytes(1021),
        )

    provider = NeteaseProvider(transport=httpx.MockTransport(handler))

    stream = await provider.resolve_stream(_track())

    assert stream.url == "https://cdn.test/audio.mp3"
    assert stream.http_headers["Referer"] == "https://music.163.com/"


async def test_netease_rejects_copyright_redirect() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.startswith("/song/media/outer/url"):
            return httpx.Response(302, headers={"location": "/404"})
        return httpx.Response(
            200, headers={"content-type": "text/html"}, text="not available"
        )

    provider = NeteaseProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(StreamUnavailableError, match="公开可播放"):
        await provider.resolve_stream(_track("168091"))


async def test_netease_returns_public_lyrics() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/song/lyric"
        return httpx.Response(
            200,
            json={"code": 200, "lrc": {"lyric": "[00:01.00]Test line"}},
        )

    provider = NeteaseProvider(transport=httpx.MockTransport(handler))

    assert await provider.get_lyrics(_track()) == "[00:01.00]Test line"
