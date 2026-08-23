import asyncio
from pathlib import Path

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import (
    FavoriteRepository,
    HistoryRepository,
    PlaylistRepository,
)
from sniffplay.models import StreamInfo, Track
from sniffplay.player import MockPlayer
from sniffplay.providers import ProviderRegistry
from sniffplay.providers.base import ProviderError
from sniffplay.providers.mock import MockProvider
from sniffplay.services.search_service import SearchService


def test_controller_records_history_only_after_threshold(tmp_path: Path) -> None:
    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "controller.db")
    database.initialize()
    history = HistoryRepository(database)
    player = MockPlayer()
    registry = ProviderRegistry()
    registry.register(MockProvider())
    controller = AppController(
        SearchService(registry),
        player,
        PlaylistRepository(database),
        history,
    )
    track = Track("local", "one", "Test", "Artist", "Album", 120_000)

    player.play(track, StreamInfo("test.wav"))
    controller._poll_player()
    assert history.recent() == []

    player.seek(30_000)
    controller._poll_player()
    controller._poll_player()
    assert len(history.recent()) == 1

    controller.close()
    database.close()
    assert app is not None


async def test_controller_manages_and_plays_playlist_tracks(tmp_path: Path) -> None:
    class PlayableMockProvider(MockProvider):
        async def resolve_stream(self, track: Track) -> StreamInfo:
            return StreamInfo("test.wav")

    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "playlist-controller.db")
    database.initialize()
    playlists = PlaylistRepository(database)
    player = MockPlayer()
    registry = ProviderRegistry()
    registry.register(PlayableMockProvider())
    controller = AppController(
        SearchService(registry),
        player,
        playlists,
        HistoryRepository(database),
        FavoriteRepository(database),
    )
    playlist = playlists.create("测试歌单")

    await controller.search("")
    controller.addSearchTrackToPlaylist(0, playlist.id)
    controller.addSearchTrackToPlaylist(1, playlist.id)
    controller.openPlaylist(playlist.id)

    assert controller.hasSelectedPlaylist
    assert controller.selectedPlaylistName == "测试歌单"
    assert [
        entry.track.title for entry in controller._playlist_track_model.entries
    ] == ["夜航", "迟来的风"]

    second_item = controller._playlist_track_model.entries[1]
    controller.movePlaylistItem(second_item.item_id, 0)
    assert [
        entry.track.title for entry in controller._playlist_track_model.entries
    ] == ["迟来的风", "夜航"]

    await controller._play_playlist_index(1)
    assert player.current_track is not None
    assert player.current_track.title == "夜航"
    assert controller.queueLabel == "队列 2/2"
    assert controller.canGoPrevious

    controller.togglePlaylistTrackFavorite(0)
    assert controller._playlist_track_model._items[0]["isFavorite"] is True

    copied_playlist = playlists.create("复制歌曲")
    controller.addPlaylistTrackToPlaylist(0, copied_playlist.id)
    assert playlists.list_tracks(copied_playlist.id)[0].track.title == "迟来的风"

    controller.createPlaylistWithPlaylistTrack("新歌单", 1)
    created = next(item for item in playlists.list_all() if item.name == "新歌单")
    assert playlists.list_tracks(created.id)[0].track.title == "夜航"

    controller.deletePlaylist(playlist.id)
    assert not controller.hasSelectedPlaylist
    assert controller._playlist_track_model.entries == []
    assert all(item.id != playlist.id for item in playlists.list_all())

    controller.close()
    database.close()
    assert app is not None


async def test_controller_updates_favorite_roles_and_current_state(
    tmp_path: Path,
) -> None:
    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "favorite-controller.db")
    database.initialize()
    registry = ProviderRegistry()
    registry.register(MockProvider())
    favorites = FavoriteRepository(database)
    controller = AppController(
        SearchService(registry),
        MockPlayer(),
        PlaylistRepository(database),
        HistoryRepository(database),
        favorites,
    )

    await controller.search("")
    controller.toggleTrackFavorite(0)
    assert controller.favoriteCount == 1
    assert controller.favoriteModel.rowCount() == 1
    assert controller.trackModel.data(
        controller.trackModel.index(0, 0),
        next(
            role
            for role, name in controller.trackModel.roleNames().items()
            if bytes(name).decode() == "isFavorite"
        ),
    )

    playlist = controller._playlist_repository.create("收藏歌单")
    controller.addFavoriteTrackToPlaylist(0, playlist.id)
    assert controller._playlist_repository.list_tracks(playlist.id)[0].track.title == "夜航"

    controller.createPlaylistWithFavorite("新建收藏歌单", 0)
    created = next(
        item
        for item in controller._playlist_repository.list_all()
        if item.name == "新建收藏歌单"
    )
    assert controller._playlist_repository.list_tracks(created.id)[0].track.title == "夜航"

    controller.toggleTrackFavorite(0)
    assert controller.favoriteCount == 0
    controller.close()
    database.close()
    assert app is not None


async def test_controller_copies_search_track_information(
    tmp_path: Path,
    monkeypatch,
) -> None:
    class Clipboard:
        text = ""

        def setText(self, value: str) -> None:
            self.text = value

    class GuiApplication:
        clipboard_instance = Clipboard()

        @classmethod
        def clipboard(cls) -> Clipboard:
            return cls.clipboard_instance

    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "copy-track-controller.db")
    database.initialize()
    registry = ProviderRegistry()
    registry.register(MockProvider())
    controller = AppController(
        SearchService(registry),
        MockPlayer(),
        PlaylistRepository(database),
        HistoryRepository(database),
    )
    monkeypatch.setattr(
        "sniffplay.controllers.app_controller.QGuiApplication",
        GuiApplication,
    )

    await controller.search("")
    controller.copySearchTrackInfo(0)

    assert GuiApplication.clipboard_instance.text == (
        "夜航 - 林屿\n专辑：城市回声\n来源：DEMO\n时长：3:45"
    )
    assert controller.statusMessage == "已复制歌曲信息：夜航"

    controller.copySearchTrackInfo(-1)
    controller.copySearchTrackInfo(99)
    assert GuiApplication.clipboard_instance.text.startswith("夜航 - 林屿")

    controller.close()
    database.close()
    assert app is not None


async def test_controller_plays_history_as_a_queue(tmp_path: Path) -> None:
    class PlayableMockProvider(MockProvider):
        async def resolve_stream(self, track: Track) -> StreamInfo:
            return StreamInfo("test.wav")

    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "history-controller.db")
    database.initialize()
    history = HistoryRepository(database)
    history.record(Track("demo", "one", "较早", "歌手", "专辑", 60_000))
    history.record(Track("demo", "two", "最近", "歌手", "专辑", 60_000))
    registry = ProviderRegistry()
    registry.register(PlayableMockProvider())
    player = MockPlayer()
    controller = AppController(
        SearchService(registry),
        player,
        PlaylistRepository(database),
        history,
        FavoriteRepository(database),
    )

    await controller.playHistory(1)

    assert player.current_track is not None
    assert player.current_track.title == "较早"
    assert controller.queueLabel == "队列 2/2"
    assert controller.canGoPrevious

    controller.toggleHistoryTrackFavorite(0)
    assert controller._history_model._items[0]["isFavorite"] is True

    target_playlist = controller._playlist_repository.create("历史歌曲")
    controller.addHistoryTrackToPlaylist(0, target_playlist.id)
    assert history.recent()[0].track.title == "最近"
    assert (
        controller._playlist_repository.list_tracks(target_playlist.id)[0].track.title
        == "最近"
    )

    controller.createPlaylistWithHistoryTrack("新建历史歌单", 1)
    created = next(
        item
        for item in controller._playlist_repository.list_all()
        if item.name == "新建历史歌单"
    )
    assert controller._playlist_repository.list_tracks(created.id)[0].track.title == "较早"

    removed_id = controller._history_model.entries[0].id
    controller.removeHistory(removed_id)
    assert all(entry.id != removed_id for entry in history.recent())
    assert controller._history_model.rowCount() == 1

    controller.close()
    database.close()
    assert app is not None


async def test_controller_ignores_stale_playback_resolution(tmp_path: Path) -> None:
    class ControlledSearchService:
        def __init__(self) -> None:
            self.gates = {"old": asyncio.Event(), "new": asyncio.Event()}

        async def resolve_stream(self, track: Track) -> StreamInfo:
            await self.gates[track.provider_track_id].wait()
            return StreamInfo(f"{track.provider_track_id}.wav")

    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "playback-race-controller.db")
    database.initialize()
    service = ControlledSearchService()
    player = MockPlayer()
    controller = AppController(
        service,  # type: ignore[arg-type]
        player,
        PlaylistRepository(database),
        HistoryRepository(database),
    )
    old_queue = [
        Track("demo", "old", "旧请求", "歌手", "专辑", 60_000),
        Track("demo", "old-next", "旧队列下一首", "歌手", "专辑", 60_000),
    ]
    new_queue = [
        Track("demo", "new", "新请求", "歌手", "专辑", 60_000),
        Track("demo", "new-next", "新队列下一首", "歌手", "专辑", 60_000),
    ]

    old_request = asyncio.create_task(controller._play_tracks(old_queue, 0))
    await asyncio.sleep(0)
    new_request = asyncio.create_task(controller._play_tracks(new_queue, 0))
    await asyncio.sleep(0)

    service.gates["new"].set()
    await new_request
    service.gates["old"].set()
    await old_request

    assert player.current_track == new_queue[0]
    assert controller._queue == new_queue
    assert controller.queueLabel == "队列 1/2"

    controller.close()
    database.close()
    assert app is not None


async def test_controller_keeps_committed_queue_when_new_playback_fails(
    tmp_path: Path,
) -> None:
    class FailingSearchService:
        async def resolve_stream(self, track: Track) -> StreamInfo:
            if track.provider_track_id == "broken":
                raise ProviderError("无法解析新歌曲")
            return StreamInfo(f"{track.provider_track_id}.wav")

    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "playback-failure-controller.db")
    database.initialize()
    player = MockPlayer()
    controller = AppController(
        FailingSearchService(),  # type: ignore[arg-type]
        player,
        PlaylistRepository(database),
        HistoryRepository(database),
    )
    committed_queue = [
        Track("demo", "playing", "正在播放", "歌手", "专辑", 60_000),
        Track("demo", "next", "下一首", "歌手", "专辑", 60_000),
    ]
    broken_queue = [
        Track("demo", "broken", "无法播放", "歌手", "专辑", 60_000)
    ]

    await controller._play_tracks(committed_queue, 0)
    committed_request_id = controller._play_request_id
    await controller._play_tracks(broken_queue, 0)

    assert player.current_track == committed_queue[0]
    assert controller._queue == committed_queue
    assert controller._queue_index == 0
    assert controller.statusMessage == "无法解析新歌曲"

    await controller._advance_after_end(committed_request_id)
    assert player.current_track == committed_queue[0]
    assert controller._queue_index == 0

    controller.close()
    database.close()
    assert app is not None
