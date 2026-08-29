from __future__ import annotations

import asyncio
import ctypes
import logging
import os
import sys
from pathlib import Path

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication, Qt, QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon, QPalette, QColor
from PySide6.QtQml import QQmlApplicationEngine
from qasync import QEventLoop

import sniffplay_ui
from sniffplay.config import AppSettings
from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import (
    FavoriteRepository,
    HistoryRepository,
    PlaylistRepository,
    SettingsRepository,
)
from sniffplay.logging_config import configure_logging
from sniffplay.player import create_player
from sniffplay.providers.BilibiliDataSource import BilibiliDataSource
from sniffplay.providers import ProviderRegistry
from sniffplay.services.search_service import SearchService

logger = logging.getLogger(__name__)


def _ui_directory() -> Path:
    return Path(sniffplay_ui.__file__).resolve().parent


def _set_windows_app_id() -> None:
    if os.name == "nt":
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "SniffPlay.SniffPlay"
        )


def _startup_audio_path(arguments: list[str]) -> Path | None:
    for argument in arguments[1:]:
        if argument.startswith("-"):
            continue
        candidate = Path(argument).expanduser().resolve()
        if candidate.is_file():
            return candidate
    return None


def run() -> int:
    settings = AppSettings.from_environment()
    settings.ensure_directories()
    configure_logging(settings.log_path)

    QCoreApplication.setOrganizationName("SniffPlay")
    QCoreApplication.setApplicationName("SniffPlay")
    _set_windows_app_id()
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    startup_audio = _startup_audio_path(sys.argv)
    app = QGuiApplication(sys.argv)
    palette = app.palette()
    palette.setColor(QPalette.ColorRole.Window, QColor("#1b1b1e"))
    palette.setColor(QPalette.ColorRole.WindowText, QColor("#f1f1f3"))
    palette.setColor(QPalette.ColorRole.Base, QColor("#242428"))
    palette.setColor(QPalette.ColorRole.Text, QColor("#f1f1f3"))
    palette.setColor(QPalette.ColorRole.Button, QColor("#29292f"))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor("#f1f1f3"))
    palette.setColor(QPalette.ColorRole.Highlight, QColor("#0a84ff"))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor("#ffffff"))
    app.setPalette(palette)
    app.setWindowIcon(
        QIcon(str(_ui_directory() / "assets" / "sniffplay-taskbar.ico"))
    )
    event_loop = QEventLoop(app)
    asyncio.set_event_loop(event_loop)

    database = Database(settings.database_path)
    database.initialize()

    registry = ProviderRegistry()
    registry.register(
        BilibiliDataSource(cover_cache_dir=settings.cover_cache_dir)
    )
    controller = AppController(
        search_service=SearchService(registry),
        player=create_player(),
        playlist_repository=PlaylistRepository(database),
        history_repository=HistoryRepository(database),
        favorite_repository=FavoriteRepository(database),
        settings_repository=SettingsRepository(database),
        cover_cache_dir=settings.cover_cache_dir,
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

    if startup_audio is not None:
        audio_url = QUrl.fromLocalFile(str(startup_audio))
        QTimer.singleShot(0, lambda: controller.openLocalFile(audio_url))

    app.aboutToQuit.connect(controller.close)
    app.aboutToQuit.connect(database.close)
    app.aboutToQuit.connect(event_loop.stop)
    with event_loop:
        event_loop.run_forever()
    return 0
