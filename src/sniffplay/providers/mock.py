from __future__ import annotations

import asyncio

from sniffplay.models import StreamInfo, Track
from sniffplay.providers.base import MusicProvider, StreamUnavailableError


class MockProvider(MusicProvider):
    id = "demo"
    display_name = "Demo Source"

    _tracks = (
        Track(id, "001", "夜航", "林屿", "城市回声", 225_000, "#55d98b"),
        Track(id, "002", "迟来的风", "北岸乐队", "候鸟", 247_000, "#e9b44c"),
        Track(id, "003", "雨停之后", "青禾", "未寄出的信", 198_000, "#52a7d8"),
        Track(id, "004", "漫游时刻", "白昼电台", "沿线风景", 262_000, "#d66d75"),
        Track(id, "005", "无声海面", "周末计划", "潮汐之间", 214_000, "#a98bd4"),
    )

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        await asyncio.sleep(0.18)
        normalized_query = query.strip().casefold()
        if not normalized_query:
            return list(self._tracks[:limit])
        matches = [
            track
            for track in self._tracks
            if normalized_query
            in f"{track.title} {track.artist} {track.album}".casefold()
        ]
        return matches[:limit]

    async def resolve_stream(self, track: Track) -> StreamInfo:
        raise StreamUnavailableError("演示数据没有真实音频，请打开本地音频文件")
