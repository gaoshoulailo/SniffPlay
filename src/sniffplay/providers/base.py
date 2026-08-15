from __future__ import annotations

from abc import ABC, abstractmethod

from sniffplay.models import StreamInfo, Track


class ProviderError(RuntimeError):
    pass


class StreamUnavailableError(ProviderError):
    pass


class MusicProvider(ABC):
    id: str
    display_name: str

    @abstractmethod
    async def search(self, query: str, limit: int = 30) -> list[Track]:
        """Search this provider and return normalized tracks."""

    @abstractmethod
    async def resolve_stream(self, track: Track) -> StreamInfo:
        """Resolve a short-lived stream immediately before playback."""

    async def get_lyrics(self, track: Track) -> str | None:
        """Return LRC text when a public lyric endpoint is available."""
        return None
