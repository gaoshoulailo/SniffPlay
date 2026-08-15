from pathlib import Path

from sniffplay.application import _startup_audio_path


def test_startup_audio_path_finds_existing_file(tmp_path: Path) -> None:
    audio_path = tmp_path / "example.wav"
    audio_path.write_bytes(b"test")

    assert _startup_audio_path(["sniffplay", str(audio_path)]) == audio_path.resolve()


def test_startup_audio_path_ignores_options_and_missing_files() -> None:
    assert _startup_audio_path(["sniffplay", "--debug", "missing.wav"]) is None

