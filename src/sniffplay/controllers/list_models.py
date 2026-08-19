from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from PySide6.QtCore import QAbstractListModel, QByteArray, QModelIndex, Qt

from sniffplay.database.repositories.history import HistoryEntry
from sniffplay.database.repositories.playlists import (
    PlaylistSummary,
    PlaylistTrackEntry,
)
from sniffplay.models import Track


class DictionaryListModel(QAbstractListModel):
    def __init__(self, role_names: Sequence[str]) -> None:
        super().__init__()
        self._items: list[Mapping[str, Any]] = []
        self._roles = {
            Qt.ItemDataRole.UserRole + index + 1: QByteArray(name.encode("utf-8"))
            for index, name in enumerate(role_names)
        }

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: B008
        return 0 if parent.isValid() else len(self._items)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> Any:
        if not index.isValid() or not 0 <= index.row() < len(self._items):
            return None
        role_name = self._roles.get(role)
        if role_name is None:
            return None
        return self._items[index.row()].get(bytes(role_name).decode("utf-8"))

    def roleNames(self) -> dict[int, QByteArray]:
        return self._roles

    def replace(self, items: Sequence[Mapping[str, Any]]) -> None:
        self.beginResetModel()
        self._items = list(items)
        self.endResetModel()


class TrackListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(
            (
                "title",
                "artist",
                "album",
                "duration",
                "source",
                "accent",
                "initials",
                "coverUrl",
            )
        )
        self.tracks: list[Track] = []

    def set_tracks(self, tracks: Sequence[Track]) -> None:
        self.tracks = list(tracks)
        self.replace(
            [
                {
                    "title": track.title,
                    "artist": track.artist,
                    "album": track.album,
                    "duration": track.duration_text,
                    "source": track.provider_id.upper(),
                    "accent": track.accent,
                    "initials": track.initials,
                    "coverUrl": track.cover_url or "",
                }
                for track in self.tracks
            ]
        )


class PlaylistListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(("playlistId", "name", "itemCount", "countLabel"))

    def set_playlists(self, playlists: Sequence[PlaylistSummary]) -> None:
        self.replace(
            [
                {
                    "playlistId": playlist.id,
                    "name": playlist.name,
                    "itemCount": playlist.item_count,
                    "countLabel": f"{playlist.item_count} 首歌曲",
                }
                for playlist in playlists
            ]
        )


class PlaylistTrackListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(
            (
                "itemId",
                "playlistId",
                "position",
                "title",
                "artist",
                "album",
                "duration",
                "source",
                "accent",
                "initials",
                "coverUrl",
                "canMoveUp",
                "canMoveDown",
            )
        )
        self.entries: list[PlaylistTrackEntry] = []

    def set_entries(self, entries: Sequence[PlaylistTrackEntry]) -> None:
        self.entries = list(entries)
        last_index = len(self.entries) - 1
        self.replace(
            [
                {
                    "itemId": entry.item_id,
                    "playlistId": entry.playlist_id,
                    "position": entry.position,
                    "title": entry.track.title,
                    "artist": entry.track.artist,
                    "album": entry.track.album,
                    "duration": entry.track.duration_text,
                    "source": entry.track.provider_id.upper(),
                    "accent": entry.track.accent,
                    "initials": entry.track.initials,
                    "coverUrl": entry.track.cover_url or "",
                    "canMoveUp": index > 0,
                    "canMoveDown": index < last_index,
                }
                for index, entry in enumerate(self.entries)
            ]
        )


class HistoryListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(("historyId", "title", "artist", "playedAt"))

    def set_entries(self, entries: Sequence[HistoryEntry]) -> None:
        self.replace(
            [
                {
                    "historyId": entry.id,
                    "title": entry.title,
                    "artist": entry.artist,
                    "playedAt": entry.played_at.astimezone().strftime("%m-%d %H:%M"),
                }
                for entry in entries
            ]
        )
