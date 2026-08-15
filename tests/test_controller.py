from pathlib import Path

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import HistoryRepository, PlaylistRepository
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
