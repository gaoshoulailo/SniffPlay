from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


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
            else (Path.cwd() / "data").resolve()
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

