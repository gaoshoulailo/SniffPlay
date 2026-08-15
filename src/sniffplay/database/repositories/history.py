from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select

from sniffplay.database.engine import Database
from sniffplay.database.models import PlayHistoryRecord, TrackRecord
from sniffplay.database.repositories.tracks import get_or_create_track
from sniffplay.models import Track


@dataclass(frozen=True, slots=True)
class HistoryEntry:
    id: int
    title: str
    artist: str
    played_at: datetime


class HistoryRepository:
    def __init__(self, database: Database) -> None:
        self._database = database

    def record(self, track: Track, listened_ms: int = 0) -> None:
        with self._database.session_factory.begin() as session:
            track_record = get_or_create_track(session, track)
            session.add(
                PlayHistoryRecord(track_id=track_record.id, listened_ms=listened_ms)
            )

    def recent(self, limit: int = 100) -> list[HistoryEntry]:
        with self._database.session_factory() as session:
            rows = session.execute(
                select(
                    PlayHistoryRecord.id,
                    TrackRecord.title,
                    TrackRecord.artist,
                    PlayHistoryRecord.played_at,
                )
                .join(TrackRecord, TrackRecord.id == PlayHistoryRecord.track_id)
                .order_by(PlayHistoryRecord.played_at.desc())
                .limit(limit)
            ).all()
        return [HistoryEntry(row[0], row[1], row[2], row[3]) for row in rows]
