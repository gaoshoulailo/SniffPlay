from pathlib import Path

import sniffplay.config as config_module
from sniffplay.config import AppSettings


def test_settings_default_to_project_data_directory_regardless_of_cwd(
    tmp_path: Path,
    monkeypatch,
) -> None:
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("SNIFFPLAY_DATA_DIR", raising=False)
    project_root = Path(config_module.__file__).resolve().parents[2]

    settings = AppSettings.from_environment()

    assert settings.data_dir == project_root / "data"
    assert settings.database_path == project_root / "data" / "sniffplay.db"
    assert settings.log_path == project_root / "data" / "logs" / "sniffplay.log"
    assert settings.cover_cache_dir == (
        project_root / "data" / "cache" / "covers" / "bilibili"
    )


def test_settings_use_executable_directory_when_frozen(
    tmp_path: Path,
    monkeypatch,
) -> None:
    executable = tmp_path / "SniffPlay" / "SniffPlay.exe"
    monkeypatch.delenv("SNIFFPLAY_DATA_DIR", raising=False)
    monkeypatch.setattr(config_module.sys, "frozen", True, raising=False)
    monkeypatch.setattr(config_module.sys, "executable", str(executable))

    settings = AppSettings.from_environment()

    assert settings.data_dir == executable.parent / "data"
    assert settings.database_path == executable.parent / "data" / "sniffplay.db"


def test_settings_environment_override_controls_all_storage_paths(
    tmp_path: Path,
    monkeypatch,
) -> None:
    configured_dir = tmp_path / "portable-data"
    monkeypatch.setenv("SNIFFPLAY_DATA_DIR", str(configured_dir))

    settings = AppSettings.from_environment()

    assert settings.data_dir == configured_dir
    assert settings.database_path.parent == configured_dir
    assert settings.log_path.is_relative_to(configured_dir)
    assert settings.cover_cache_dir.is_relative_to(configured_dir)

    settings.ensure_directories()
    assert settings.data_dir.is_dir()
    assert settings.log_path.parent.is_dir()
    assert settings.cover_cache_dir.is_dir()
