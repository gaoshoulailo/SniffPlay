from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import (
    HistoryRepository,
    PlaylistRepository,
)
from sniffplay.player import MockPlayer
from sniffplay.providers import ProviderRegistry
from sniffplay.services.search_service import SearchService


def test_controller_emits_repeatable_toasts(tmp_path) -> None:
    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "feedback-controller.db")
    database.initialize()
    controller = AppController(
        SearchService(ProviderRegistry()),
        MockPlayer(),
        PlaylistRepository(database),
        HistoryRepository(database),
    )
    messages: list[str] = []
    controller.toastRequested.connect(messages.append)

    controller._set_status("重复操作")
    controller._set_status("重复操作")
    assert messages[-2:] == ["重复操作", "重复操作"]

    controller.close()
    database.close()
    assert app is not None
