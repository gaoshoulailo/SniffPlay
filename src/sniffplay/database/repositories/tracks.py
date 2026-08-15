from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from sniffplay.database.models import TrackRecord
from sniffplay.models import Track


def get_or_create_track(session: Session, track: Track) -> TrackRecord:
    record = session.scalar(
        select(TrackRecord).where(
            TrackRecord.provider_id == track.provider_id,
            TrackRecord.provider_track_id == track.provider_track_id,
        )
    )
    if record is None:
        record = TrackRecord(
            provider_id=track.provider_id,
            provider_track_id=track.provider_track_id,
            title=track.title,
            artist=track.artist,
            album=track.album,
            duration_ms=track.duration_ms,
        )
        session.add(record)
        session.flush()
    return record

