from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import StrEnum

from sniffplay.models import StreamInfo, Track


class PlayerState(StrEnum):
    IDLE = "idle"
    LOADING = "loading"
    PLAYING = "playing"
    PAUSED = "paused"
    ENDED = "ended"
    ERROR = "error"


class PlayerUnavailableError(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class PlayerSnapshot:
    state: PlayerState
    position_ms: int = 0
    duration_ms: int = 0
    volume: int = 80


class Player(ABC):
    @property
    @abstractmethod
    def backend_name(self) -> str: ...

    @property
    @abstractmethod
    def available(self) -> bool: ...

    @property
    @abstractmethod
    def state(self) -> PlayerState: ...

    @property
    @abstractmethod
    def current_track(self) -> Track | None: ...

    @abstractmethod
    def play(self, track: Track, stream: StreamInfo) -> None: ...

    @abstractmethod
    def toggle(self) -> None: ...

    @abstractmethod
    def seek(self, position_ms: int) -> None: ...

    @abstractmethod
    def set_volume(self, volume: int) -> None: ...

    @abstractmethod
    def snapshot(self) -> PlayerSnapshot: ...

    @abstractmethod
    def close(self) -> None: ...
