from __future__ import annotations

import time

from sniffplay.models import StreamInfo, Track
from sniffplay.player.base import Player, PlayerSnapshot, PlayerState


class MockPlayer(Player):
    def __init__(self) -> None:
        self._state = PlayerState.IDLE
        self._current_track: Track | None = None
        self._position_ms = 0
        self._started_at = 0.0
        self._volume = 80

    @property
    def backend_name(self) -> str:
        return "Mock"

    @property
    def available(self) -> bool:
        return True

    @property
    def state(self) -> PlayerState:
        return self._state

    @property
    def current_track(self) -> Track | None:
        return self._current_track

    def play(self, track: Track, stream: StreamInfo) -> None:
        self._current_track = track
        self._state = PlayerState.PLAYING
        self._position_ms = 0
        self._started_at = time.monotonic()

    def toggle(self) -> None:
        if self._current_track is None:
            return
        if self._state is PlayerState.PLAYING:
            self._position_ms = self.snapshot().position_ms
            self._state = PlayerState.PAUSED
        else:
            self._started_at = time.monotonic()
            self._state = PlayerState.PLAYING

    def seek(self, position_ms: int) -> None:
        duration = self._current_track.duration_ms if self._current_track else 0
        self._position_ms = max(0, min(position_ms, duration))
        self._started_at = time.monotonic()

    def set_volume(self, volume: int) -> None:
        self._volume = max(0, min(volume, 100))

    def snapshot(self) -> PlayerSnapshot:
        duration = self._current_track.duration_ms if self._current_track else 0
        position = self._position_ms
        if self._state is PlayerState.PLAYING:
            position += int((time.monotonic() - self._started_at) * 1000)
        if duration and position >= duration:
            position = duration
            self._position_ms = position
            self._state = PlayerState.ENDED
        return PlayerSnapshot(self._state, position, duration, self._volume)

    def close(self) -> None:
        self._state = PlayerState.IDLE
        self._current_track = None
