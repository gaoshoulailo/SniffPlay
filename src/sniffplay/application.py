from __future__ import annotations

import asyncio
import logging
import os
from pathlib import Path

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication, Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from qasync import QEventLoop

import sniffplay_ui
from sniffplay.config import AppSettings
from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import HistoryRepository, PlaylistRepository
from sniffplay.logging_config import configure_logging
from sniffplay.player import create_player
from sniffplay.providers import ProviderRegistry
from sniffplay.providers.mock import MockProvider
from sniffplay.services.search_service import SearchService

logger = logging.getLogger(__name__)


def _ui_directory() -> Path:
    return Path(sniffplay_ui.__file__).resolve().parent


def run() -> int:
    settings = AppSettings.from_environment()
    settings.ensure_directories()
    configure_logging(settings.log_path)

    QCoreApplication.setOrganizationName("SniffPlay")
    QCoreApplication.setApplicationName("SniffPlay")
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication([])
    event_loop = QEventLoop(app)
    asyncio.set_event_loop(event_loop)

    database = Database(settings.database_path)
    database.initialize()

    registry = ProviderRegistry()
    registry.register(MockProvider())
    controller = AppController(
        search_service=SearchService(registry),
        player=create_player(),
        playlist_repository=PlaylistRepository(database),
        history_repository=HistoryRepository(database),
    )

    engine = QQmlApplicationEngine()
    ui_directory = _ui_directory()
    engine.addImportPath(str(ui_directory))
    engine.setInitialProperties({"controller": controller})
    engine.load(QUrl.fromLocalFile(str(ui_directory / "Main.qml")))
    if not engine.rootObjects():
        logger.error("Could not load the QML interface")
        database.close()
        event_loop.close()
        return 1

    app.aboutToQuit.connect(controller.close)
    app.aboutToQuit.connect(database.close)
    app.aboutToQuit.connect(event_loop.stop)
    with event_loop:
        event_loop.run_forever()
    return 0
