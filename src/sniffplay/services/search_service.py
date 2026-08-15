from __future__ import annotations

import asyncio
import logging

from sniffplay.models import StreamInfo, Track
from sniffplay.providers import ProviderRegistry

logger = logging.getLogger(__name__)


class SearchService:
    def __init__(self, registry: ProviderRegistry) -> None:
        self._registry = registry

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        providers = self._registry.enabled()
        if not providers:
            return []

        results = await asyncio.gather(
            *(provider.search(query, limit) for provider in providers),
            return_exceptions=True,
        )
        tracks: list[Track] = []
        for provider, result in zip(providers, results, strict=True):
            if isinstance(result, BaseException):
                logger.warning("Provider %s search failed: %s", provider.id, result)
                continue
            tracks.extend(result)
        return tracks[:limit]

    async def resolve_stream(self, track: Track) -> StreamInfo:
        if track.playback_uri:
            return StreamInfo(track.playback_uri)
        provider = self._registry.get(track.provider_id)
        return await provider.resolve_stream(track)
