from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy import select

from sniffplay.database.engine import Database
from sniffplay.database.models import FavoriteRecord, TrackRecord
from sniffplay.database.repositories.tracks import get_or_create_track
from sniffplay.models import Track


@dataclass(frozen=True, slots=True)
class FavoriteEntry:
    id: int
    track: Track
    favorited_at: datetime


class FavoriteRepository:
    def __init__(self, database: Database) -> None:
        self._database = database

    def is_favorited(self, track: Track) -> bool:
        with self._database.session_factory() as session:
            track_id = session.scalar(
                select(TrackRecord.id).where(
                    TrackRecord.provider_id == track.provider_id,
                    TrackRecord.provider_track_id == track.provider_track_id,
                )
            )
            if track_id is None:
                return False
            return (
                session.scalar(
                    select(FavoriteRecord.id).where(
                        FavoriteRecord.track_id == track_id
                    )
                )
                is not None
            )

    def add(self, track: Track) -> FavoriteEntry:
        with self._database.session_factory.begin() as session:
            track_record = get_or_create_track(session, track)
            existing = session.scalar(
                select(FavoriteRecord).where(
                    FavoriteRecord.track_id == track_record.id
                )
            )
            if existing is not None:
                return self._entry_from_records(existing, track_record)
            favorite = FavoriteRecord(
                track_id=track_record.id,
                created_at=datetime.now(timezone.utc),
            )
            session.add(favorite)
            session.flush()
            return self._entry_from_records(favorite, track_record, track=track)

    def remove(self, track: Track) -> None:
        with self._database.session_factory.begin() as session:
            track_id = session.scalar(
                select(TrackRecord.id).where(
                    TrackRecord.provider_id == track.provider_id,
                    TrackRecord.provider_track_id == track.provider_track_id,
                )
            )
            if track_id is None:
                return
            favorite = session.scalar(
                select(FavoriteRecord).where(FavoriteRecord.track_id == track_id)
            )
            if favorite is not None:
                session.delete(favorite)

    def remove_by_id(self, favorite_id: int) -> None:
        with self._database.session_factory.begin() as session:
            favorite = session.get(FavoriteRecord, favorite_id)
            if favorite is not None:
                session.delete(favorite)

    def toggle(self, track: Track) -> bool:
        if self.is_favorited(track):
            self.remove(track)
            return False
        self.add(track)
        return True

    def list_all(self, limit: int = 100) -> list[FavoriteEntry]:
        if limit <= 0:
            return []
        with self._database.session_factory() as session:
            rows = session.execute(
                select(
                    FavoriteRecord.id,
                    FavoriteRecord.created_at,
                    TrackRecord.provider_id,
                    TrackRecord.provider_track_id,
                    TrackRecord.title,
                    TrackRecord.artist,
                    TrackRecord.album,
                    TrackRecord.duration_ms,
                )
                .join(TrackRecord, TrackRecord.id == FavoriteRecord.track_id)
                .order_by(FavoriteRecord.created_at.desc(), FavoriteRecord.id.desc())
                .limit(limit)
            ).all()
        return [
            FavoriteEntry(
                id=row[0],
                favorited_at=row[1],
                track=Track(
                    provider_id=row[2],
                    provider_track_id=row[3],
                    title=row[4],
                    artist=row[5],
                    album=row[6],
                    duration_ms=row[7],
                    playback_uri=row[3] if row[2] == "local" else None,
                ),
            )
            for row in rows
        ]

    @staticmethod
    def _entry_from_records(
        favorite: FavoriteRecord,
        track_record: TrackRecord,
        *,
        track: Track | None = None,
    ) -> FavoriteEntry:
        resolved_track = track or Track(
            provider_id=track_record.provider_id,
            provider_track_id=track_record.provider_track_id,
            title=track_record.title,
            artist=track_record.artist,
            album=track_record.album,
            duration_ms=track_record.duration_ms,
            playback_uri=(
                track_record.provider_track_id
                if track_record.provider_id == "local"
                else None
            ),
        )
        return FavoriteEntry(favorite.id, resolved_track, favorite.created_at)
