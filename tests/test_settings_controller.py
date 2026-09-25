from pathlib import Path

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import (
    HistoryRepository,
    PlaylistRepository,
    SettingsRepository,
)
from sniffplay.player import MockPlayer
from sniffplay.providers import ProviderRegistry
from sniffplay.services.search_service import SearchService


def test_controller_clears_persisted_background_image(tmp_path: Path) -> None:
    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "settings-controller.db")
    database.initialize()
    settings = SettingsRepository(database)
    controller = AppController(
        SearchService(ProviderRegistry()),
        MockPlayer(),
        PlaylistRepository(database),
        HistoryRepository(database),
        settings_repository=settings,
    )
    messages: list[str] = []
    controller.toastRequested.connect(messages.append)
    background = tmp_path / "background.png"
    background.write_bytes(b"not-decoded-by-controller")

    controller.setBackgroundImage(str(background))
    assert controller.backgroundImage == background.resolve().as_uri()
    assert settings.get("background_image") == controller.backgroundImage
    assert messages[-1] == "已应用背景图片"

    controller.clearBackgroundImage()
    assert controller.backgroundImage == ""
    assert settings.get("background_image") is None
    assert messages[-1] == "已清除背景图片"

    controller.close()
    database.close()
    assert app is not None
