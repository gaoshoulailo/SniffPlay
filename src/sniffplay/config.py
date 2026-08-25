from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path


def application_directory() -> Path:
    """Return the stable directory that owns portable application data."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent

    source_root = Path(__file__).resolve().parents[2]
    if (source_root / "pyproject.toml").is_file():
        return source_root
    return Path.cwd().resolve()


@dataclass(frozen=True, slots=True)
class AppSettings:
    data_dir: Path
    database_path: Path
    log_path: Path
    cover_cache_dir: Path

    @classmethod
    def from_environment(cls) -> "AppSettings":
        configured_dir = os.getenv("SNIFFPLAY_DATA_DIR")
        data_dir = (
            Path(configured_dir).expanduser().resolve()
            if configured_dir
            else application_directory() / "data"
        )
        return cls(
            data_dir=data_dir,
            database_path=data_dir / "sniffplay.db",
            log_path=data_dir / "logs" / "sniffplay.log",
            cover_cache_dir=data_dir / "cache" / "covers" / "bilibili",
        )

    def ensure_directories(self) -> None:
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self.cover_cache_dir.mkdir(parents=True, exist_ok=True)

