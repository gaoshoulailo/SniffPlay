from __future__ import annotations

from pathlib import Path

import httpx
import pytest

from sniffplay.models import Track
from sniffplay.providers.BilibiliDataSource import BilibiliDataSource, _cover_url
from sniffplay.providers.base import ProviderError, StreamUnavailableError


def _response(request: httpx.Request, payload: dict[str, object]) -> httpx.Response:
    return httpx.Response(200, json=payload, request=request)


def test_bilibili_cover_url_requests_high_resolution_square() -> None:
    assert _cover_url(
        "//i0.hdslb.com/bfs/archive/example.jpg@128w_128h.jpg?token=old"
    ) == "https://i0.hdslb.com/bfs/archive/example.jpg@512w_512h_1c.jpg"


def test_bilibili_default_cover_cache_uses_application_directory(
    tmp_path: Path,
    monkeypatch,
) -> None:
    monkeypatch.setattr(
        "sniffplay.providers.BilibiliDataSource.application_directory",
        lambda: tmp_path,
    )

    provider = BilibiliDataSource()

    assert provider._cover_cache_dir == (  # noqa: SLF001
        tmp_path / "data" / "cache" / "covers" / "bilibili"
    )


@pytest.mark.asyncio
async def test_bilibili_search_and_stream_are_normalized(tmp_path: Path) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/nav"):
            return _response(
                request,
                {
                    "code": 0,
                    "data": {
                        "wbi_img": {
                            "img_url": f"https://i.example/{'a' * 32}.png",
                            "sub_url": f"https://i.example/{'b' * 32}.png",
                        }
                    },
                },
            )
        if request.url.path.endswith("/search/all/v2"):
            assert request.url.params["keyword"] == "Python"
            assert request.url.params["w_rid"]
            return _response(
                request,
                {
                    "code": 0,
                    "data": {
                        "result": [
                            {
                                "result_type": "video",
                                "data": [
                                    {
                                        "bvid": "BV1Example001",
                                        "title": "<em>Python</em> 入门",
                                        "author": "测试UP主",
                                        "typename": "知识",
                                        "duration": "03:05",
                                        "pic": "//i.example/cover.jpg",
                                    }
                                ],
                            }
                        ]
                    },
                },
            )
        if request.url.path.endswith("/view"):
            assert request.url.params["bvid"] == "BV1Example001"
            return _response(
                request,
                {
                    "code": 0,
                    "data": {"aid": 123, "pages": [{"cid": 456}]},
                },
            )
        if request.url.path.endswith("/playurl"):
            assert request.url.params["cid"] == "456"
            return _response(
                request,
                {
                    "code": 0,
                    "data": {
                        "dash": {
                            "audio": [
                                {
                                    "id": 30216,
                                    "bandwidth": 64000,
                                    "baseUrl": "https://audio.example/low.m4a",
                                },
                                {
                                    "id": 30280,
                                    "bandwidth": 192000,
                                    "baseUrl": "https://audio.example/high.m4a",
                                },
                            ]
                        }
                    },
                },
            )
        if request.url.host == "i.example":
            return httpx.Response(
                200,
                content=b"\xff\xd8\xff\xe0test-jpeg",
                headers={"Content-Type": "image/jpeg"},
                request=request,
            )
        raise AssertionError(f"Unexpected request: {request.url}")

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        provider = BilibiliDataSource(client=client, cover_cache_dir=tmp_path)
        tracks = await provider.search(" Python ")
        stream = await provider.resolve_stream(tracks[0])

    assert tracks[0].cover_url is not None
    assert tracks[0].cover_url.startswith("file:///")
    assert len(list(tmp_path.glob("*.jpg"))) == 1
    assert tracks == [
        Track(
            provider_id="bilibili",
            provider_track_id="BV1Example001",
            title="Python 入门",
            artist="测试UP主",
            album="知识",
            duration_ms=185_000,
            accent="#fb7299",
            cover_url=tracks[0].cover_url,
        )
    ]
    assert stream.url == "https://audio.example/high.m4a"
    assert stream.http_headers["Referer"].endswith("/BV1Example001/")
    assert stream.http_headers["Origin"] == "https://www.bilibili.com"


@pytest.mark.asyncio
async def test_bilibili_empty_search_does_not_make_a_request() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise AssertionError(f"Unexpected request: {request.url}")

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        provider = BilibiliDataSource(client=client)
        assert await provider.search("   ") == []
        assert await provider.search("Python", limit=0) == []


@pytest.mark.asyncio
async def test_bilibili_rejects_track_from_another_provider() -> None:
    provider = BilibiliDataSource()
    track = Track("other", "1", "Title", "Artist", "Album", 1_000)

    with pytest.raises(ProviderError, match="不属于"):
        await provider.resolve_stream(track)


@pytest.mark.asyncio
async def test_bilibili_reports_missing_audio_stream() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/nav"):
            return _response(
                request,
                {
                    "code": 0,
                    "data": {
                        "wbi_img": {
                            "img_url": f"https://i.example/{'a' * 32}.png",
                            "sub_url": f"https://i.example/{'b' * 32}.png",
                        }
                    },
                },
            )
        if request.url.path.endswith("/view"):
            return _response(
                request,
                {"code": 0, "data": {"aid": 123, "pages": [{"cid": 456}]}},
            )
        if request.url.path.endswith("/playurl"):
            return _response(request, {"code": 0, "data": {"dash": {}}})
        raise AssertionError(f"Unexpected request: {request.url}")

    track = Track("bilibili", "BV1Example001", "Title", "Artist", "Album", 0)
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        provider = BilibiliDataSource(client=client)
        with pytest.raises(StreamUnavailableError, match="DASH"):
            await provider.resolve_stream(track)
