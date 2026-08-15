from __future__ import annotations

import logging
import os
import sys
from pathlib import Path
from typing import Any

from sniffplay.models import StreamInfo, Track
from sniffplay.player.base import (
    Player,
    PlayerSnapshot,
    PlayerState,
    PlayerUnavailableError,
)

logger = logging.getLogger(__name__)
_dll_directory_handles: list[Any] = []


def _candidate_directories() -> tuple[Path, ...]:
    configured_dll = os.getenv("SNIFFPLAY_MPV_DLL")
    configured_path = Path(configured_dll).expanduser().parent if configured_dll else None
    project_root = Path(__file__).resolve().parents[3]
    executable_dir = Path(sys.executable).resolve().parent
    candidates = [
        configured_path,
        project_root / "vendor" / "mpv",
        executable_dir / "vendor" / "mpv",
        executable_dir,
    ]
    return tuple(path for path in candidates if path is not None and path.exists())


def _prepare_dll_search_path() -> None:
    if os.name != "nt":
        return
    for directory in _candidate_directories():
        path_value = str(directory.resolve())
        os.environ["PATH"] = path_value + os.pathsep + os.environ.get("PATH", "")
        _dll_directory_handles.append(os.add_dll_directory(path_value))


class MpvPlayer(Player):
    def __init__(self) -> None:
        _prepare_dll_search_path()
        try:
            import mpv

            self._client = mpv.MPV(
                audio_display="no",
                idle="yes",
                keep_open="no",
                loglevel="warn",
                vid="no",
                ytdl=False,
            )
        except (ImportError, OSError) as error:
            raise PlayerUnavailableError(
                "未检测到 libmpv，请将 mpv-2.dll 放入 vendor/mpv"
            ) from error

        self._current_track: Track | None = None
        self._state = PlayerState.IDLE
        self._volume = 80
        self._client.volume = self._volume

    @property
    def backend_name(self) -> str:
        return "libmpv"

    @property
    def available(self) -> bool:
        return True

    @property
    def state(self) -> PlayerState:
        return self.snapshot().state

    @property
    def current_track(self) -> Track | None:
        return self._current_track

    def play(self, track: Track, stream: StreamInfo) -> None:
        header_fields = ",".join(
            f"{name}: {value}" for name, value in stream.http_headers.items()
        )
        self._client.http_header_fields = header_fields
        self._current_track = track
        self._state = PlayerState.LOADING
        self._client.play(stream.url)

    def toggle(self) -> None:
        if self._current_track is None:
            return
        self._client.pause = not bool(self._client.pause)

    def seek(self, position_ms: int) -> None:
        if self._current_track is not None:
            self._client.seek(max(0, position_ms) / 1000, reference="absolute")

    def set_volume(self, volume: int) -> None:
        self._volume = max(0, min(volume, 100))
        self._client.volume = self._volume

    def snapshot(self) -> PlayerSnapshot:
        if self._current_track is None:
            return PlayerSnapshot(PlayerState.IDLE, volume=self._volume)
        position_ms = int(float(self._read_property("time_pos", 0) or 0) * 1000)
        duration_ms = int(float(self._read_property("duration", 0) or 0) * 1000)
        if bool(self._read_property("eof_reached", False)):
            state = PlayerState.ENDED
        elif bool(self._read_property("core_idle", True)):
            state = self._state
        elif bool(self._read_property("pause", False)):
            state = PlayerState.PAUSED
        else:
            state = PlayerState.PLAYING
        self._state = state
        return PlayerSnapshot(state, position_ms, duration_ms, self._volume)

    def _read_property(self, name: str, default: object) -> object:
        try:
            return getattr(self._client, name)
        except Exception:
            return default

    def close(self) -> None:
        self._client.terminate()
        self._state = PlayerState.IDLE
        self._current_track = None
