from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import func, select

from sniffplay.database.engine import Database
from sniffplay.database.models import PlaylistItemRecord, PlaylistRecord


@dataclass(frozen=True, slots=True)
class PlaylistSummary:
    id: int
    name: str
    item_count: int


class PlaylistRepository:
    def __init__(self, database: Database) -> None:
        self._database = database

    def create(self, name: str) -> PlaylistSummary:
        cleaned_name = name.strip()
        if not cleaned_name:
            raise ValueError("Playlist name cannot be empty")
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

