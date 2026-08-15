from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from platformdirs import user_data_path


@dataclass(frozen=True, slots=True)
class AppSettings:
    data_dir: Path
    database_path: Path
    log_path: Path

    @classmethod
    def from_environment(cls) -> "AppSettings":
        configured_dir = os.getenv("SNIFFPLAY_DATA_DIR")
        data_dir = (
            Path(configured_dir).expanduser().resolve()
            if configured_dir
            else user_data_path("SniffPlay", "SniffPlay", roaming=True)
        )
        return cls(
            data_dir=data_dir,
            database_path=data_dir / "sniffplay.db",
            log_path=data_dir / "logs" / "sniffplay.log",
        )

    def ensure_directories(self) -> None:
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

