from __future__ import annotations

import asyncio
import logging
import random
from collections.abc import Sequence
from pathlib import Path

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication
from qasync import asyncSlot

from sniffplay.controllers.list_models import (
    FavoriteListModel,
    HistoryListModel,
    PlaylistListModel,
    PlaylistTrackListModel,
    QueueListModel,
    TrackListModel,
)
from sniffplay.database.repositories import (
    FavoriteRepository,
    HistoryRepository,
    PlaylistRepository,
)
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
    currentFavoriteChanged = Signal()
    playlistSelectionChanged = Signal()
    favoritesChanged = Signal()
    queueChanged = Signal()
    playbackModeChanged = Signal()

    def __init__(
        self,
        search_service: SearchService,
        player: Player,
        playlist_repository: PlaylistRepository,
        history_repository: HistoryRepository,
        favorite_repository: FavoriteRepository | None = None,
    ) -> None:
        super().__init__()
        self._search_service = search_service
        self._player = player
        self._playlist_repository = playlist_repository
        self._history_repository = history_repository
        self._favorite_repository = favorite_repository
        self._track_model = TrackListModel()
        self._favorite_model = FavoriteListModel()
        self._playlist_model = PlaylistListModel()
        self._playlist_track_model = PlaylistTrackListModel()
        self._queue_model = QueueListModel()
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
        self._queue_revision = 0
        self._shuffle_enabled = False
        self._repeat_mode = 0
        self._play_request_id = 0
        self._history_recorded = False
        self._advance_scheduled = False
        self._selected_playlist_id = -1
        self._selected_playlist_name = ""
        self._favorite_keys: set[tuple[str, str]] = set()

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
    def playlistTrackModel(self) -> QObject:
        return self._playlist_track_model

    @Property(QObject, constant=True)
    def historyModel(self) -> QObject:
        return self._history_model

    @Property(QObject, constant=True)
    def favoriteModel(self) -> QObject:
        return self._favorite_model

    @Property(QObject, constant=True)
    def queueModel(self) -> QObject:
        return self._queue_model

    @Property(int, notify=queueChanged)
    def queueIndex(self) -> int:
        return self._queue_index

    @Property(int, notify=favoritesChanged)
    def favoriteCount(self) -> int:
        return len(self._favorite_model.entries)

    @Property(int, notify=playlistSelectionChanged)
    def selectedPlaylistId(self) -> int:
        return self._selected_playlist_id

    @Property(str, notify=playlistSelectionChanged)
    def selectedPlaylistName(self) -> str:
        return self._selected_playlist_name

    @Property(bool, notify=playlistSelectionChanged)
    def hasSelectedPlaylist(self) -> bool:
        return self._selected_playlist_id >= 0

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

    @Property(str, notify=playerChanged)
    def currentCoverUrl(self) -> str:
        track = self._player.current_track
        return track.cover_url if track and track.cover_url else ""

    @Property(bool, notify=playerChanged)
    def hasCurrentTrack(self) -> bool:
        return self._player.current_track is not None

    @Property(bool, notify=currentFavoriteChanged)
    def currentFavorite(self) -> bool:
        track = self._player.current_track
        return bool(track and self._is_favorite(track))

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

    @Property(bool, notify=playbackModeChanged)
    def shuffleEnabled(self) -> bool:
        return self._shuffle_enabled

    @Property(int, notify=playbackModeChanged)
    def repeatMode(self) -> int:
        return self._repeat_mode

    @Property(bool, notify=playerChanged)
    def canGoPrevious(self) -> bool:
        return (
            self._queue_index > 0
            or self._snapshot.position_ms > 0
            or (self._repeat_mode == 1 and len(self._queue) > 1)
        )

    @Property(bool, notify=playerChanged)
    def canGoNext(self) -> bool:
        return (
            0 <= self._queue_index < len(self._queue) - 1
            or (self._repeat_mode == 1 and len(self._queue) > 1)
        )

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
            self._track_model.set_tracks(tracks, self._favorite_keys)
            self._set_status(f"找到 {len(tracks)} 首歌曲")
        except Exception:
            logger.exception("Search failed")
            self._track_model.set_tracks([])
            self._set_status("搜索失败，请稍后重试")
        finally:
            self._set_searching(False)

    @asyncSlot(int)
    async def playTrack(self, index: int) -> None:
        await self._play_tracks(self._track_model.tracks, index)

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
        await self._play_tracks([track], 0)

    async def _play_tracks(self, tracks: Sequence[Track], index: int) -> None:
        candidate_queue = list(tracks)
        if not 0 <= index < len(candidate_queue):
            return
        await self._play_candidate(candidate_queue, index)

    async def _play_queue_index(self, index: int) -> None:
        candidate_queue = list(self._queue)
        if not 0 <= index < len(candidate_queue):
            return
        await self._play_candidate(
            candidate_queue,
            index,
            expected_queue_revision=self._queue_revision,
        )

    async def _play_candidate(
        self,
        candidate_queue: list[Track],
        index: int,
        expected_queue_revision: int | None = None,
    ) -> None:
        self._play_request_id += 1
        request_id = self._play_request_id
        track = candidate_queue[index]
        self._set_status(f"正在解析：{track.title}")
        try:
            stream = await self._search_service.resolve_stream(track)
            if request_id != self._play_request_id:
                return
            if (
                expected_queue_revision is not None
                and expected_queue_revision != self._queue_revision
            ):
                return
            self._player.play(track, stream)
        except (LookupError, OSError, ProviderError, PlayerUnavailableError) as error:
            if request_id != self._play_request_id:
                return
            logger.warning("Could not play %s: %s", track.title, error)
            self._set_status(str(error))
            return
        except Exception:
            if request_id != self._play_request_id:
                return
            logger.exception("Unexpected playback failure for %s", track.title)
            self._set_status("播放失败，请检查音频来源")
            return

        if self._shuffle_enabled and expected_queue_revision is None:
            remaining = candidate_queue[:index] + candidate_queue[index + 1 :]
            random.shuffle(remaining)
            candidate_queue = [track, *remaining]
            index = 0

        self._queue = candidate_queue
        self._queue_index = index
        self._queue_revision += 1
        self._refresh_queue_model()
        self._snapshot = self._player.snapshot()
        self._history_recorded = False
        self._advance_scheduled = False
        self.playerChanged.emit()
        self.currentFavoriteChanged.emit()
        self._set_status(f"正在播放：{track.title}")

    @Slot()
    def togglePlayback(self) -> None:
        if not self._player.available:
            self._set_status("未检测到 libmpv，请先安装播放内核")
            return
        self._player.toggle()
        self._snapshot = self._player.snapshot()
        self.playerChanged.emit()

    @Slot()
    def toggleShuffle(self) -> None:
        self._shuffle_enabled = not self._shuffle_enabled
        if self._shuffle_enabled and 0 <= self._queue_index < len(self._queue):
            current = self._queue[self._queue_index]
            remaining = (
                self._queue[: self._queue_index]
                + self._queue[self._queue_index + 1 :]
            )
            random.shuffle(remaining)
            self._queue = [current, *remaining]
            self._queue_index = 0
            self._queue_revision += 1
            self._refresh_queue_model()
        self.playbackModeChanged.emit()
        self.playerChanged.emit()
        self._set_status("已开启随机播放" if self._shuffle_enabled else "已关闭随机播放")

    @Slot()
    def cycleRepeatMode(self) -> None:
        self._repeat_mode = (self._repeat_mode + 1) % 3
        self.playbackModeChanged.emit()
        self.playerChanged.emit()
        labels = ("已关闭循环播放", "已开启列表循环", "已开启单曲循环")
        self._set_status(labels[self._repeat_mode])

    @asyncSlot()
    async def nextTrack(self) -> None:
        if not self.canGoNext:
            return
        next_index = self._queue_index + 1
        if next_index >= len(self._queue):
            next_index = 0
        await self._play_queue_index(next_index)

    @asyncSlot(int)
    async def playQueueTrack(self, index: int) -> None:
        await self._play_queue_index(index)

    @Slot(int)
    def playQueueTrackNext(self, index: int) -> None:
        if not 0 <= index < len(self._queue) or index == self._queue_index:
            return
        track = self._queue.pop(index)
        if index < self._queue_index:
            self._queue_index -= 1
        self._queue.insert(self._queue_index + 1, track)
        self._commit_queue_edit(f"下一首播放：{track.title}")

    @Slot(int)
    def removeQueueTrack(self, index: int) -> None:
        if not 0 <= index < len(self._queue) or index == self._queue_index:
            return
        track = self._queue.pop(index)
        if index < self._queue_index:
            self._queue_index -= 1
        self._commit_queue_edit(f"已从队列移除：{track.title}")

    @Slot()
    def clearQueueExceptCurrent(self) -> None:
        if not 0 <= self._queue_index < len(self._queue) or len(self._queue) <= 1:
            return
        current = self._queue[self._queue_index]
        self._queue = [current]
        self._queue_index = 0
        self._commit_queue_edit("已清理播放队列")

    @asyncSlot()
    async def previousTrack(self) -> None:
        if self._snapshot.position_ms > 5_000:
            self.seek(0)
            return
        if self._queue_index > 0:
            await self._play_queue_index(self._queue_index - 1)
        elif self._repeat_mode == 1 and len(self._queue) > 1:
            await self._play_queue_index(len(self._queue) - 1)
        else:
            self.seek(0)

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

    @Slot(int)
    def toggleTrackFavorite(self, track_index: int) -> None:
        if self._favorite_repository is None:
            self._set_status("收藏功能尚未初始化")
            return
        if not 0 <= track_index < len(self._track_model.tracks):
            return
        track = self._track_model.tracks[track_index]
        is_favorite = self._favorite_repository.toggle(track)
        self._refresh_favorites()
        self._set_status(
            f"已收藏：{track.title}" if is_favorite else f"已取消收藏：{track.title}"
        )

    @Slot(int)
    def copySearchTrackInfo(self, track_index: int) -> None:
        if not 0 <= track_index < len(self._track_model.tracks):
            return
        track = self._track_model.tracks[track_index]
        QGuiApplication.clipboard().setText(self._format_track_info(track))
        self._set_status(f"已复制歌曲信息：{track.title}")

    @staticmethod
    def _format_track_info(track: Track) -> str:
        return "\n".join(
            (
                f"{track.title} - {track.artist}",
                f"专辑：{track.album or '未知专辑'}",
                f"来源：{track.provider_id.upper()}",
                f"时长：{track.duration_text}",
            )
        )

    @Slot()
    def toggleCurrentFavorite(self) -> None:
        track = self._player.current_track
        if track is None:
            return
        if self._favorite_repository is None:
            self._set_status("收藏功能尚未初始化")
            return
        is_favorite = self._favorite_repository.toggle(track)
        self._refresh_favorites()
        self.playerChanged.emit()
        self.currentFavoriteChanged.emit()
        self._set_status(
            f"已收藏：{track.title}" if is_favorite else f"已取消收藏：{track.title}"
        )

    @Slot(int)
    def removeFavorite(self, favorite_id: int) -> None:
        if self._favorite_repository is None:
            return
        self._favorite_repository.remove_by_id(favorite_id)
        self._refresh_favorites()
        self._set_status("已取消收藏")

    @Slot(int, int)
    def addFavoriteTrackToPlaylist(
        self,
        favorite_index: int,
        playlist_id: int,
    ) -> None:
        if not 0 <= favorite_index < len(self._favorite_model.entries):
            return
        self._add_track_to_playlist(
            self._favorite_model.entries[favorite_index].track,
            playlist_id,
        )

    @Slot(str, int)
    def createPlaylistWithFavorite(self, name: str, favorite_index: int) -> None:
        if not 0 <= favorite_index < len(self._favorite_model.entries):
            return
        self._create_playlist_with_track(
            name,
            self._favorite_model.entries[favorite_index].track,
        )

    @asyncSlot(int)
    async def playFavorite(self, index: int) -> None:
        await self._play_tracks(
            [entry.track for entry in self._favorite_model.entries],
            index,
        )

    @asyncSlot(int)
    async def playHistory(self, index: int) -> None:
        await self._play_tracks(
            [entry.track for entry in self._history_model.entries],
            index,
        )

    @Slot(int)
    def toggleHistoryTrackFavorite(self, index: int) -> None:
        if self._favorite_repository is None:
            return
        if not 0 <= index < len(self._history_model.entries):
            return
        track = self._history_model.entries[index].track
        is_favorite = self._favorite_repository.toggle(track)
        self._refresh_favorites()
        self._set_status(
            f"已收藏：{track.title}" if is_favorite else f"已取消收藏：{track.title}"
        )

    @Slot(int, int)
    def addHistoryTrackToPlaylist(self, history_index: int, playlist_id: int) -> None:
        if not 0 <= history_index < len(self._history_model.entries):
            return
        self._add_track_to_playlist(
            self._history_model.entries[history_index].track,
            playlist_id,
        )

    @Slot(str, int)
    def createPlaylistWithHistoryTrack(self, name: str, history_index: int) -> None:
        if not 0 <= history_index < len(self._history_model.entries):
            return
        self._create_playlist_with_track(
            name,
            self._history_model.entries[history_index].track,
        )

    @Slot(int)
    def removeHistory(self, history_id: int) -> None:
        self._history_repository.remove_by_id(history_id)
        self._refresh_history()
        self._set_status("已删除播放记录")

    @Slot(str)
    def createPlaylist(self, name: str) -> None:
        try:
            playlist = self._playlist_repository.create(name)
        except ValueError as error:
            self._set_status(str(error))
            return
        self._playlist_model.set_playlists(self._playlist_repository.list_all())
        self._set_status(f"已创建歌单：{playlist.name}")

    @Slot(str, int)
    def createPlaylistWithTrack(self, name: str, track_index: int) -> None:
        if not 0 <= track_index < len(self._track_model.tracks):
            return
        self._create_playlist_with_track(name, self._track_model.tracks[track_index])

    def _create_playlist_with_track(self, name: str, track: Track) -> None:
        try:
            playlist = self._playlist_repository.create(name)
            self._playlist_repository.add_track(playlist.id, track)
        except (LookupError, ValueError) as error:
            self._set_status(str(error))
            return
        self._refresh_playlists()
        self._set_status(f"已创建歌单并添加歌曲：{playlist.name}")

    @Slot(int)
    def openPlaylist(self, playlist_id: int) -> None:
        try:
            playlist = self._playlist_repository.get(playlist_id)
            entries = self._playlist_repository.list_tracks(playlist_id)
        except LookupError as error:
            self._set_status(str(error))
            return
        self._selected_playlist_id = playlist.id
        self._selected_playlist_name = playlist.name
        self._playlist_track_model.set_entries(entries, self._favorite_keys)
        self.playlistSelectionChanged.emit()

    @asyncSlot(int)
    async def playPlaylist(self, playlist_id: int) -> None:
        try:
            entries = self._playlist_repository.list_tracks(playlist_id)
        except LookupError as error:
            self._set_status(str(error))
            return
        if entries:
            await self._play_tracks([entry.track for entry in entries], 0)

    @Slot()
    def closePlaylist(self) -> None:
        self._clear_selected_playlist()

    @Slot(int, str)
    def renamePlaylist(self, playlist_id: int, name: str) -> None:
        try:
            playlist = self._playlist_repository.rename(playlist_id, name)
        except (LookupError, ValueError) as error:
            self._set_status(str(error))
            return
        self._refresh_playlists()
        if self._selected_playlist_id == playlist_id:
            self._selected_playlist_name = playlist.name
            self.playlistSelectionChanged.emit()
        self._set_status(f"已重命名歌单：{playlist.name}")

    @Slot(int)
    def deletePlaylist(self, playlist_id: int) -> None:
        try:
            playlist = self._playlist_repository.get(playlist_id)
            self._playlist_repository.delete(playlist_id)
        except LookupError as error:
            self._set_status(str(error))
            return
        if self._selected_playlist_id == playlist_id:
            self._clear_selected_playlist()
        self._refresh_playlists()
        self._set_status(f"已删除歌单：{playlist.name}")

    @Slot(int, int)
    def addSearchTrackToPlaylist(self, track_index: int, playlist_id: int) -> None:
        if not 0 <= track_index < len(self._track_model.tracks):
            return
        self._add_track_to_playlist(self._track_model.tracks[track_index], playlist_id)

    def _add_track_to_playlist(self, track: Track, playlist_id: int) -> None:
        try:
            playlist = self._playlist_repository.get(playlist_id)
            self._playlist_repository.add_track(playlist_id, track)
        except (LookupError, ValueError) as error:
            self._set_status(str(error))
            return
        self._refresh_playlists()
        self._refresh_selected_playlist_if(playlist_id)
        self._set_status(f"已将《{track.title}》添加到 {playlist.name}")

    @Slot(int)
    def removePlaylistItem(self, item_id: int) -> None:
        if not self.hasSelectedPlaylist:
            return
        try:
            self._playlist_repository.remove_item(
                self._selected_playlist_id,
                item_id,
            )
        except LookupError as error:
            self._set_status(str(error))
            return
        self._refresh_playlists()
        self._refresh_selected_playlist_if(self._selected_playlist_id)
        self._set_status("已从歌单移除歌曲")

    @Slot(int)
    def togglePlaylistTrackFavorite(self, index: int) -> None:
        if self._favorite_repository is None:
            return
        if not 0 <= index < len(self._playlist_track_model.entries):
            return
        track = self._playlist_track_model.entries[index].track
        is_favorite = self._favorite_repository.toggle(track)
        self._refresh_favorites()
        self._set_status(
            f"已收藏：{track.title}" if is_favorite else f"已取消收藏：{track.title}"
        )

    @Slot(int, int)
    def addPlaylistTrackToPlaylist(self, track_index: int, playlist_id: int) -> None:
        if not 0 <= track_index < len(self._playlist_track_model.entries):
            return
        self._add_track_to_playlist(
            self._playlist_track_model.entries[track_index].track,
            playlist_id,
        )

    @Slot(str, int)
    def createPlaylistWithPlaylistTrack(self, name: str, track_index: int) -> None:
        if not 0 <= track_index < len(self._playlist_track_model.entries):
            return
        self._create_playlist_with_track(
            name,
            self._playlist_track_model.entries[track_index].track,
        )

    @Slot(int, int)
    def movePlaylistItem(self, item_id: int, target_index: int) -> None:
        if not self.hasSelectedPlaylist:
            return
        try:
            self._playlist_repository.move_item(
                self._selected_playlist_id,
                item_id,
                target_index,
            )
        except (LookupError, ValueError) as error:
            self._set_status(str(error))
            return
        self._refresh_selected_playlist_if(self._selected_playlist_id)

    @asyncSlot(int)
    async def playPlaylistItem(self, index: int) -> None:
        await self._play_playlist_index(index)

    async def _play_playlist_index(self, index: int) -> None:
        await self._play_tracks(
            [entry.track for entry in self._playlist_track_model.entries],
            index,
        )

    @asyncSlot()
    async def playSelectedPlaylist(self) -> None:
        if self._playlist_track_model.entries:
            await self._play_playlist_index(0)

    @Slot()
    def refreshLibrary(self) -> None:
        self.refresh_library()

    def refresh_library(self) -> None:
        self._refresh_playlists()
        self._refresh_history()
        self._refresh_favorites()

    def _refresh_playlists(self) -> None:
        self._playlist_model.set_playlists(self._playlist_repository.list_all())

    def _refresh_favorites(self) -> None:
        if self._favorite_repository is None:
            self._favorite_keys = set()
            self._favorite_model.set_entries([])
        else:
            entries = self._favorite_repository.list_all()
            self._favorite_model.set_entries(entries)
            self._favorite_keys = {
                (entry.track.provider_id, entry.track.provider_track_id)
                for entry in entries
            }
        self._track_model.set_tracks(self._track_model.tracks, self._favorite_keys)
        self._playlist_track_model.set_entries(
            self._playlist_track_model.entries,
            self._favorite_keys,
        )
        self._history_model.set_entries(
            self._history_model.entries,
            self._favorite_keys,
        )
        self.favoritesChanged.emit()
        self.currentFavoriteChanged.emit()

    def _is_favorite(self, track: Track) -> bool:
        return (
            track.provider_id,
            track.provider_track_id,
        ) in self._favorite_keys

    def _refresh_queue_model(self) -> None:
        self._queue_model.set_tracks(self._queue, self._queue_index)
        self.queueChanged.emit()

    def _commit_queue_edit(self, status_message: str) -> None:
        self._queue_revision += 1
        self._refresh_queue_model()
        self.playerChanged.emit()
        self._set_status(status_message)

    def _refresh_selected_playlist_if(self, playlist_id: int) -> None:
        if self._selected_playlist_id != playlist_id:
            return
        self._playlist_track_model.set_entries(
            self._playlist_repository.list_tracks(playlist_id),
            self._favorite_keys,
        )

    def _refresh_history(self) -> None:
        self._history_model.set_entries(
            self._history_repository.recent(),
            self._favorite_keys,
        )

    def _clear_selected_playlist(self) -> None:
        if not self.hasSelectedPlaylist:
            return
        self._selected_playlist_id = -1
        self._selected_playlist_name = ""
        self._playlist_track_model.set_entries([])
        self.playlistSelectionChanged.emit()

    @Slot()
    def close(self) -> None:
        self._play_request_id += 1
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
            asyncio.create_task(self._advance_after_end(self._play_request_id))

    def _record_history_when_eligible(self) -> None:
        track = self._player.current_track
        if track is None or self._history_recorded:
            return
        duration = self._snapshot.duration_ms or track.duration_ms
        threshold = 30_000 if duration <= 0 else min(30_000, max(1_000, duration // 2))
        if self._snapshot.position_ms < threshold:
            return
        self._history_repository.record(track, listened_ms=self._snapshot.position_ms)
        self._refresh_history()
        self._history_recorded = True

    async def _advance_after_end(self, expected_request_id: int) -> None:
        if expected_request_id != self._play_request_id:
            return
        if self._repeat_mode == 2 and 0 <= self._queue_index < len(self._queue):
            await self._play_queue_index(self._queue_index)
        elif self.canGoNext:
            next_index = self._queue_index + 1
            if next_index >= len(self._queue):
                next_index = 0
            await self._play_queue_index(next_index)
        else:
            self._set_status("播放队列已结束")
