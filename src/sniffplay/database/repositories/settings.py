from __future__ import annotations

from sniffplay.database.engine import Database
from sniffplay.database.models import SettingRecord


class SettingsRepository:
    def __init__(self, database: Database) -> None:
        self._database = database

    def get(self, key: str, default: str | None = None) -> str | None:
        with self._database.session_factory() as session:
            record = session.get(SettingRecord, key)
            return record.value if record is not None else default

    def set(self, key: str, value: str) -> None:
        with self._database.session_factory.begin() as session:
            record = session.get(SettingRecord, key)
            if record is None:
                session.add(SettingRecord(key=key, value=value))
            else:
                record.value = value

    def delete(self, key: str) -> None:
        with self._database.session_factory.begin() as session:
            record = session.get(SettingRecord, key)
            if record is not None:
                session.delete(record)
