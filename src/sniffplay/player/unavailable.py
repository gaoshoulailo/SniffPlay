from __future__ import annotations

from sniffplay.models import StreamInfo, Track
from sniffplay.player.base import (
    Player,
    PlayerSnapshot,
    PlayerState,
    PlayerUnavailableError,
)


class UnavailablePlayer(Player):
    def __init__(self, reason: str) -> None:
        self.reason = reason

    @property
    def backend_name(self) -> str:
        return "Unavailable"

    @property
    def available(self) -> bool:
        return False

    @property
    def state(self) -> PlayerState:
        return PlayerState.IDLE

    @property
    def current_track(self) -> Track | None:
        return None

    def play(self, track: Track, stream: StreamInfo) -> None:
        raise PlayerUnavailableError(self.reason)

    def toggle(self) -> None:
        return

    def seek(self, position_ms: int) -> None:
        return

    def set_volume(self, volume: int) -> None:
        return

    def snapshot(self) -> PlayerSnapshot:
        return PlayerSnapshot(PlayerState.IDLE)

    def close(self) -> None:
        return
