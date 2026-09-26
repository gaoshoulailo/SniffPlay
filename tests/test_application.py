import subprocess
import sys
import time
from pathlib import Path

from sniffplay.application import _startup_audio_path
from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.single_instance import SingleInstanceGuard


def test_startup_audio_path_finds_existing_file(tmp_path: Path) -> None:
    audio_path = tmp_path / "example.wav"
    audio_path.write_bytes(b"test")

    assert _startup_audio_path(["sniffplay", str(audio_path)]) == audio_path.resolve()


def test_startup_audio_path_ignores_options_and_missing_files() -> None:
    assert _startup_audio_path(["sniffplay", "--debug", "missing.wav"]) is None


def test_second_instance_notifies_primary(tmp_path: Path) -> None:
    app = QCoreApplication.instance() or QCoreApplication([])
    audio_path = tmp_path / "track.wav"
    audio_path.write_bytes(b"test")
    primary = SingleInstanceGuard(tmp_path)
    activations: list[str] = []
    primary.activationRequested.connect(activations.append)

    try:
        assert primary.acquire_or_notify()
        script = "\n".join(
            (
                "import sys",
                "from pathlib import Path",
                "from PySide6.QtCore import QCoreApplication",
                "from sniffplay.single_instance import SingleInstanceGuard",
                "app = QCoreApplication([])",
                "guard = SingleInstanceGuard(Path(sys.argv[1]))",
                "raise SystemExit(1 if guard.acquire_or_notify(Path(sys.argv[2])) else 0)",
            )
        )
        secondary = subprocess.Popen(
            [sys.executable, "-c", script, str(tmp_path), str(audio_path)]
        )

        deadline = time.monotonic() + 2
        while (
            (not activations or secondary.poll() is None)
            and time.monotonic() < deadline
        ):
            app.processEvents()
            time.sleep(0.01)

        assert secondary.wait(timeout=1) == 0
        assert activations == [str(audio_path)]
    finally:
        primary.close()

    assert app is not None
