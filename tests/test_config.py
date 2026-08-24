from pathlib import Path

from sniffplay.config import AppSettings


def test_settings_default_to_data_directory_in_current_path(
    tmp_path: Path,
    monkeypatch,
) -> None:
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("SNIFFPLAY_DATA_DIR", raising=False)

    settings = AppSettings.from_environment()

    assert settings.data_dir == tmp_path / "data"
    assert settings.database_path == tmp_path / "data" / "sniffplay.db"
    assert settings.log_path == tmp_path / "data" / "logs" / "sniffplay.log"
    assert settings.cover_cache_dir == (
        tmp_path / "data" / "cache" / "covers" / "bilibili"
    )

    settings.ensure_directories()
    assert settings.data_dir.is_dir()
    assert settings.log_path.parent.is_dir()
    assert settings.cover_cache_dir.is_dir()


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
