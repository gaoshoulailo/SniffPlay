from __future__ import annotations

import asyncio
import logging
from pathlib import Path

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from qasync import asyncSlot

from sniffplay.controllers.list_models import (
    HistoryListModel,
    PlaylistListModel,
    TrackListModel,
)
from sniffplay.database.repositories import HistoryRepository, PlaylistRepository
from sniffplay.models import Track
from sniffplay.player import Player, PlayerState, PlayerUnavailableError
from sniffplay.player.base import PlayerSnapshot
from sniffplay.providers.base import ProviderError
from sniffplay.services.search_service import SearchService

logger = logging.getLogger(__name__)


class AppController(QObject):
    searchingChanged = Signal()
    statusMessageChanged = Signal()
    playerChanged = Signal()

    def __init__(
        self,
        search_service: SearchService,
        player: Player,
        playlist_repository: PlaylistRepository,
        history_repository: HistoryRepository,
    ) -> None:
        super().__init__()
        self._search_service = search_service
        self._player = player
        self._playlist_repository = playlist_repository
        self._history_repository = history_repository
        self._track_model = TrackListModel()
        self._playlist_model = PlaylistListModel()
        self._history_model = HistoryListModel()
        self._searching = False
        self._status_message = (
            f"{player.backend_name} 已就绪"
            if player.available
            else "未检测到 libmpv，本地播放暂不可用"
        )
        self._snapshot = player.snapshot()
        self._queue: list[Track] = []
        self._queue_index = -1
        self._history_recorded = False
        self._advance_scheduled = False

        self._player_timer = QTimer(self)
        self._player_timer.setInterval(250)
        self._player_timer.timeout.connect(self._poll_player)
        self._player_timer.start()
        self.refresh_library()

    @Property(QObject, constant=True)
    def trackModel(self) -> QObject:
        return self._track_model

    @Property(QObject, constant=True)
    def playlistModel(self) -> QObject:
        return self._playlist_model

    @Property(QObject, constant=True)
    def historyModel(self) -> QObject:
        return self._history_model

    @Property(bool, notify=searchingChanged)
    def searching(self) -> bool:
        return self._searching

    @Property(str, notify=statusMessageChanged)
    def statusMessage(self) -> str:
        return self._status_message

    @Property(bool, constant=True)
    def playerAvailable(self) -> bool:
        return self._player.available

    @Property(str, constant=True)
    def playerBackend(self) -> str:
        return self._player.backend_name

    @Property(str, notify=playerChanged)
    def currentTitle(self) -> str:
        track = self._player.current_track
        return track.title if track else "尚未播放"

    @Property(str, notify=playerChanged)
    def currentArtist(self) -> str:
        track = self._player.current_track
        return track.artist if track else "打开本地音频或选择可播放歌曲"

    @Property(str, notify=playerChanged)
    def currentAccent(self) -> str:
        track = self._player.current_track
        return track.accent if track else "#343b37"

    @Property(str, notify=playerChanged)
    def currentInitials(self) -> str:
        track = self._player.current_track
        return track.initials if track else "SP"

    @Property(bool, notify=playerChanged)
    def hasCurrentTrack(self) -> bool:
        return self._player.current_track is not None

    @Property(bool, notify=playerChanged)
    def playing(self) -> bool:
        return self._snapshot.state is PlayerState.PLAYING

    @Property(bool, notify=playerChanged)
    def loading(self) -> bool:
        return self._snapshot.state is PlayerState.LOADING

    @Property(int, notify=playerChanged)
    def positionMs(self) -> int:
        return self._snapshot.position_ms

    @Property(int, notify=playerChanged)
    def durationMs(self) -> int:
        return self._snapshot.duration_ms

    @Property(str, notify=playerChanged)
    def positionText(self) -> str:
        return self._format_duration(self._snapshot.position_ms)

    @Property(str, notify=playerChanged)
    def durationText(self) -> str:
        return self._format_duration(self._snapshot.duration_ms)

    @Property(int, notify=playerChanged)
    def volume(self) -> int:
        return self._snapshot.volume

    @Property(bool, notify=playerChanged)
    def canGoPrevious(self) -> bool:
        return self._queue_index > 0 or self._snapshot.position_ms > 0

    @Property(bool, notify=playerChanged)
    def canGoNext(self) -> bool:
        return 0 <= self._queue_index < len(self._queue) - 1

    @Property(str, notify=playerChanged)
    def queueLabel(self) -> str:
        if not self._queue or self._queue_index < 0:
            return "队列为空"
        return f"队列 {self._queue_index + 1}/{len(self._queue)}"

    @staticmethod
    def _format_duration(milliseconds: int) -> str:
        total_seconds = max(0, milliseconds // 1000)
        minutes, seconds = divmod(total_seconds, 60)
        return f"{minutes}:{seconds:02d}"

    def _set_searching(self, value: bool) -> None:
        if self._searching != value:
            self._searching = value
            self.searchingChanged.emit()

    def _set_status(self, message: str) -> None:
        if self._status_message != message:
            self._status_message = message
            self.statusMessageChanged.emit()

    @asyncSlot(str)
    async def search(self, query: str) -> None:
        self._set_searching(True)
        self._set_status("正在搜索...")
        try:
            tracks = await self._search_service.search(query)
            self._track_model.set_tracks(tracks)
            self._set_status(f"找到 {len(tracks)} 首歌曲")
        except Exception:
            logger.exception("Search failed")
            self._track_model.set_tracks([])
            self._set_status("搜索失败，请稍后重试")
        finally:
            self._set_searching(False)

    @asyncSlot(int)
    async def playTrack(self, index: int) -> None:
        if not 0 <= index < len(self._track_model.tracks):
            return
        self._queue = list(self._track_model.tracks)
        await self._play_queue_index(index)

    @asyncSlot(QUrl)
    async def openLocalFile(self, file_url: QUrl) -> None:
        path = Path(file_url.toLocalFile()).resolve()
        if not path.is_file():
            self._set_status("无法打开所选音频文件")
            return
        track = Track(
            provider_id="local",
            provider_track_id=str(path),
            title=path.stem,
            artist="本地文件",
            album=path.parent.name,
            duration_ms=0,
            accent="#e9b44c",
            playback_uri=str(path),
        )
        self._queue = [track]
        await self._play_queue_index(0)

    async def _play_queue_index(self, index: int) -> None:
        if not 0 <= index < len(self._queue):
            return
        track = self._queue[index]
        self._set_status(f"正在解析：{track.title}")
        try:
            stream = await self._search_service.resolve_stream(track)
            self._player.play(track, stream)
        except (LookupError, OSError, ProviderError, PlayerUnavailableError) as error:
            logger.warning("Could not play %s: %s", track.title, error)
            self._set_status(str(error))
            return
        except Exception:
            logger.exception("Unexpected playback failure for %s", track.title)
            self._set_status("播放失败，请检查音频来源")
            return

        self._queue_index = index
        self._snapshot = self._player.snapshot()
        self._history_recorded = False
        self._advance_scheduled = False
        self.playerChanged.emit()
        self._set_status(f"正在播放：{track.title}")

    @Slot()
    def togglePlayback(self) -> None:
        if not self._player.available:
            self._set_status("未检测到 libmpv，请先安装播放内核")
            return
        self._player.toggle()
        self._snapshot = self._player.snapshot()
        self.playerChanged.emit()

    @asyncSlot()
    async def nextTrack(self) -> None:
        if self.canGoNext:
            await self._play_queue_index(self._queue_index + 1)

    @asyncSlot()
    async def previousTrack(self) -> None:
        if self._snapshot.position_ms > 5_000 or self._queue_index <= 0:
            self.seek(0)
            return
        await self._play_queue_index(self._queue_index - 1)

    @Slot(int)
    def seek(self, position_ms: int) -> None:
        self._player.seek(position_ms)
        self._snapshot = self._player.snapshot()
        self.playerChanged.emit()

    @Slot(int)
    def setVolume(self, volume: int) -> None:
        self._player.set_volume(volume)
        self._snapshot = self._player.snapshot()
        self.playerChanged.emit()

    @Slot(str)
    def createPlaylist(self, name: str) -> None:
        try:
            playlist = self._playlist_repository.create(name)
        except ValueError as error:
            self._set_status(str(error))
            return
        self._playlist_model.set_playlists(self._playlist_repository.list_all())
        self._set_status(f"已创建歌单：{playlist.name}")

    @Slot()
    def refreshLibrary(self) -> None:
        self.refresh_library()

    def refresh_library(self) -> None:
        self._playlist_model.set_playlists(self._playlist_repository.list_all())
        self._history_model.set_entries(self._history_repository.recent())

    @Slot()
    def close(self) -> None:
        self._player_timer.stop()
        self._player.close()

    @Slot()
    def _poll_player(self) -> None:
        previous_state = self._snapshot.state
        self._snapshot = self._player.snapshot()
        self._record_history_when_eligible()
        self.playerChanged.emit()

        if self._snapshot.state is PlayerState.PLAYING and previous_state is not PlayerState.PLAYING:
            track = self._player.current_track
            if track:
                self._set_status(f"正在播放：{track.title}")
        elif self._snapshot.state is PlayerState.ERROR:
            self._set_status("播放内核发生错误")
        elif self._snapshot.state is PlayerState.ENDED and not self._advance_scheduled:
            self._advance_scheduled = True
            asyncio.create_task(self._advance_after_end())

    def _record_history_when_eligible(self) -> None:
        track = self._player.current_track
        if track is None or self._history_recorded:
            return
        duration = self._snapshot.duration_ms or track.duration_ms
        threshold = 30_000 if duration <= 0 else min(30_000, max(1_000, duration // 2))
        if self._snapshot.position_ms < threshold:
            return
        self._history_repository.record(track, listened_ms=self._snapshot.position_ms)
        self._history_model.set_entries(self._history_repository.recent())
        self._history_recorded = True

    async def _advance_after_end(self) -> None:
        if self.canGoNext:
            await self._play_queue_index(self._queue_index + 1)
        else:
            self._set_status("播放队列已结束")

