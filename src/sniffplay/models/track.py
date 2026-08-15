from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Track:
    provider_id: str
    provider_track_id: str
    title: str
    artist: str
    album: str
    duration_ms: int
    accent: str = "#55d98b"
    playback_uri: str | None = None

    @property
    def duration_text(self) -> str:
        total_seconds = max(0, self.duration_ms // 1000)
        minutes, seconds = divmod(total_seconds, 60)
        return f"{minutes}:{seconds:02d}"

    @property
    def initials(self) -> str:
        title = self.title.strip()
        return title[:1].upper() if title else "?"
