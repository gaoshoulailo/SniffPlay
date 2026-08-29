from __future__ import annotations

from pathlib import Path

from sqlalchemy import Engine, create_engine, event
from sqlalchemy.orm import Session, sessionmaker

from sniffplay.database.models import Base


class Database:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.engine: Engine = create_engine(f"sqlite:///{path.as_posix()}")
        event.listen(self.engine, "connect", self._enable_foreign_keys)
        self.session_factory = sessionmaker(
            bind=self.engine,
            class_=Session,
            expire_on_commit=False,
        )

    @staticmethod
    def _enable_foreign_keys(dbapi_connection: object, _: object) -> None:
        cursor = dbapi_connection.cursor()  # type: ignore[attr-defined]
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    def initialize(self) -> None:
        Base.metadata.create_all(self.engine)
        self._migrate_track_cover_url()

    def _migrate_track_cover_url(self) -> None:
        """Add columns introduced after the initial SQLite schema."""
        with self.engine.begin() as connection:
            columns = {
                row[1]
                for row in connection.exec_driver_sql("PRAGMA table_info(tracks)")
            }
            if "cover_url" not in columns:
                connection.exec_driver_sql(
                    "ALTER TABLE tracks ADD COLUMN cover_url VARCHAR(1000)"
                )
            if "source_cover_url" not in columns:
                connection.exec_driver_sql(
                    "ALTER TABLE tracks ADD COLUMN source_cover_url VARCHAR(1000)"
                )

    def close(self) -> None:
        self.engine.dispose()
