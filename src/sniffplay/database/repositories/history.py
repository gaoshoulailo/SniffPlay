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
    track: Track
    played_at: datetime
    listened_ms: int
    completed: bool


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
                    PlayHistoryRecord.played_at,
                    PlayHistoryRecord.listened_ms,
                    PlayHistoryRecord.completed,
                    TrackRecord.provider_id,
                    TrackRecord.provider_track_id,
                    TrackRecord.title,
                    TrackRecord.artist,
                    TrackRecord.album,
                    TrackRecord.duration_ms,
                    TrackRecord.cover_url,
                    TrackRecord.source_cover_url,
                )
                .join(TrackRecord, TrackRecord.id == PlayHistoryRecord.track_id)
                .order_by(
                    PlayHistoryRecord.played_at.desc(),
                    PlayHistoryRecord.id.desc(),
                )
                .limit(limit)
            ).all()
        return [
            HistoryEntry(
                id=row[0],
                played_at=row[1],
                listened_ms=row[2],
                completed=row[3],
                track=Track(
                    provider_id=row[4],
                    provider_track_id=row[5],
                    title=row[6],
                    artist=row[7],
                    album=row[8],
                    duration_ms=row[9],
                    playback_uri=row[5] if row[4] == "local" else None,
                    # Prefer the cached local cover; the source URL is only a fallback.
                    cover_url=row[10] or row[11],
                    source_cover_url=row[11],
                ),
            )
            for row in rows
        ]

    def remove_by_id(self, history_id: int) -> None:
        with self._database.session_factory.begin() as session:
            record = session.get(PlayHistoryRecord, history_id)
            if record is not None:
                session.delete(record)
