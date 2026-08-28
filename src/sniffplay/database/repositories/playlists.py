from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from sniffplay.database.engine import Database
from sniffplay.database.models import PlaylistItemRecord, PlaylistRecord, TrackRecord
from sniffplay.database.repositories.tracks import get_or_create_track
from sniffplay.models import Track


@dataclass(frozen=True, slots=True)
class PlaylistSummary:
    id: int
    name: str
    item_count: int


@dataclass(frozen=True, slots=True)
class PlaylistTrackEntry:
    item_id: int
    playlist_id: int
    position: int
    track: Track


class PlaylistRepository:
    def __init__(self, database: Database) -> None:
        self._database = database

    def create(self, name: str) -> PlaylistSummary:
        cleaned_name = self._clean_name(name)
        with self._database.session_factory.begin() as session:
            playlist = PlaylistRecord(name=cleaned_name)
            session.add(playlist)
            session.flush()
            return PlaylistSummary(playlist.id, playlist.name, 0)

    def list_all(self) -> list[PlaylistSummary]:
        with self._database.session_factory() as session:
            rows = session.execute(
                select(
                    PlaylistRecord.id,
                    PlaylistRecord.name,
                    func.count(PlaylistItemRecord.id),
                )
                .outerjoin(
                    PlaylistItemRecord,
                    PlaylistItemRecord.playlist_id == PlaylistRecord.id,
                )
                .group_by(PlaylistRecord.id)
                .order_by(PlaylistRecord.created_at.desc())
            ).all()
        return [PlaylistSummary(row[0], row[1], row[2]) for row in rows]

    def get(self, playlist_id: int) -> PlaylistSummary:
        with self._database.session_factory() as session:
            row = session.execute(
                select(
                    PlaylistRecord.id,
                    PlaylistRecord.name,
                    func.count(PlaylistItemRecord.id),
                )
                .outerjoin(
                    PlaylistItemRecord,
                    PlaylistItemRecord.playlist_id == PlaylistRecord.id,
                )
                .where(PlaylistRecord.id == playlist_id)
                .group_by(PlaylistRecord.id)
            ).one_or_none()
        if row is None:
            raise LookupError("Playlist not found")
        return PlaylistSummary(row[0], row[1], row[2])

    def rename(self, playlist_id: int, name: str) -> PlaylistSummary:
        cleaned_name = self._clean_name(name)
        with self._database.session_factory.begin() as session:
            playlist = session.get(PlaylistRecord, playlist_id)
            if playlist is None:
                raise LookupError("Playlist not found")
            playlist.name = cleaned_name
        return self.get(playlist_id)

    def delete(self, playlist_id: int) -> None:
        with self._database.session_factory.begin() as session:
            playlist = session.get(PlaylistRecord, playlist_id)
            if playlist is None:
                raise LookupError("Playlist not found")
            session.delete(playlist)

    def list_tracks(self, playlist_id: int) -> list[PlaylistTrackEntry]:
        with self._database.session_factory() as session:
            if session.get(PlaylistRecord, playlist_id) is None:
                raise LookupError("Playlist not found")
            rows = session.execute(
                select(
                    PlaylistItemRecord.id,
                    PlaylistItemRecord.playlist_id,
                    PlaylistItemRecord.position,
                    TrackRecord.provider_id,
                    TrackRecord.provider_track_id,
                    TrackRecord.title,
                    TrackRecord.artist,
                    TrackRecord.album,
                    TrackRecord.duration_ms,
                    TrackRecord.cover_url,
                )
                .join(TrackRecord, TrackRecord.id == PlaylistItemRecord.track_id)
                .where(PlaylistItemRecord.playlist_id == playlist_id)
                .order_by(PlaylistItemRecord.position, PlaylistItemRecord.id)
            ).all()
        return [
            PlaylistTrackEntry(
                item_id=row[0],
                playlist_id=row[1],
                position=row[2],
                track=Track(
                    provider_id=row[3],
                    provider_track_id=row[4],
                    title=row[5],
                    artist=row[6],
                    album=row[7],
                    duration_ms=row[8],
                    playback_uri=row[4] if row[3] == "local" else None,
                    cover_url=row[9],
                ),
            )
            for row in rows
        ]

    def add_track(self, playlist_id: int, track: Track) -> PlaylistTrackEntry:
        with self._database.session_factory.begin() as session:
            if session.get(PlaylistRecord, playlist_id) is None:
                raise LookupError("Playlist not found")
            track_record = get_or_create_track(session, track)
            existing = session.scalar(
                select(PlaylistItemRecord).where(
                    PlaylistItemRecord.playlist_id == playlist_id,
                    PlaylistItemRecord.track_id == track_record.id,
                )
            )
            if existing is not None:
                raise ValueError("歌曲已在歌单中")
            last_position = session.scalar(
                select(func.max(PlaylistItemRecord.position)).where(
                    PlaylistItemRecord.playlist_id == playlist_id
                )
            )
            item = PlaylistItemRecord(
                playlist_id=playlist_id,
                track_id=track_record.id,
                position=(last_position if last_position is not None else -1) + 1,
            )
            session.add(item)
            session.flush()
            return PlaylistTrackEntry(
                item_id=item.id,
                playlist_id=playlist_id,
                position=item.position,
                track=track,
            )

    def remove_item(self, playlist_id: int, item_id: int) -> None:
        with self._database.session_factory.begin() as session:
            item = session.scalar(
                select(PlaylistItemRecord).where(
                    PlaylistItemRecord.id == item_id,
                    PlaylistItemRecord.playlist_id == playlist_id,
                )
            )
            if item is None:
                raise LookupError("Playlist item not found")
            session.delete(item)
            session.flush()
            self._normalize_positions(session, playlist_id)

    def move_item(self, playlist_id: int, item_id: int, target_index: int) -> None:
        with self._database.session_factory.begin() as session:
            items = list(
                session.scalars(
                    select(PlaylistItemRecord)
                    .where(PlaylistItemRecord.playlist_id == playlist_id)
                    .order_by(PlaylistItemRecord.position, PlaylistItemRecord.id)
                )
            )
            if not items:
                if session.get(PlaylistRecord, playlist_id) is None:
                    raise LookupError("Playlist not found")
                raise LookupError("Playlist item not found")
            if not 0 <= target_index < len(items):
                raise ValueError("Target position is out of range")
            try:
                item = next(item for item in items if item.id == item_id)
            except StopIteration as error:
                raise LookupError("Playlist item not found") from error
            items.remove(item)
            items.insert(target_index, item)
            for position, ordered_item in enumerate(items):
                ordered_item.position = position

    @staticmethod
    def _normalize_positions(session: Session, playlist_id: int) -> None:
        items = list(
            session.scalars(
                select(PlaylistItemRecord)
                .where(PlaylistItemRecord.playlist_id == playlist_id)
                .order_by(PlaylistItemRecord.position, PlaylistItemRecord.id)
            )
        )
        for position, item in enumerate(items):
            item.position = position

    @staticmethod
    def _clean_name(name: str) -> str:
        cleaned_name = name.strip()
        if not cleaned_name:
            raise ValueError("Playlist name cannot be empty")
        if len(cleaned_name) > 160:
            raise ValueError("Playlist name cannot exceed 160 characters")
        return cleaned_name
