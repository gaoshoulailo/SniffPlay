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

    controller.deletePlaylist(playlist.id)
    assert not controller.hasSelectedPlaylist
    assert controller._playlist_track_model.entries == []
    assert playlists.list_all() == []

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

    controller.toggleTrackFavorite(0)
    assert controller.favoriteCount == 0
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
    )

    await controller.playHistory(1)

    assert player.current_track is not None
    assert player.current_track.title == "较早"
    assert controller.queueLabel == "队列 2/2"
    assert controller.canGoPrevious

    controller.close()
    database.close()
    assert app is not None
