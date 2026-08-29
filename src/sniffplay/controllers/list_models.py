from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from PySide6.QtCore import QAbstractListModel, QByteArray, QModelIndex, Qt

from sniffplay.database.repositories.history import HistoryEntry
from sniffplay.database.repositories.favorites import FavoriteEntry
from sniffplay.database.repositories.playlists import (
    PlaylistSummary,
    PlaylistTrackEntry,
)
from sniffplay.models import Track

FALLBACK_COVER_ACCENT = "#3d8bff"


def _cover_accent(track: Track) -> str:
    return track.accent if track.cover_url else FALLBACK_COVER_ACCENT


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
                "isFavorite",
            )
        )
        self.tracks: list[Track] = []

    def set_tracks(
        self,
        tracks: Sequence[Track],
        favorite_keys: set[tuple[str, str]] | None = None,
    ) -> None:
        self.tracks = list(tracks)
        favorite_keys = favorite_keys or set()
        self.replace(
            [
                {
                    "title": track.title,
                    "artist": track.artist,
                    "album": track.album,
                    "duration": track.duration_text,
                    "source": track.provider_id.upper(),
                    "accent": _cover_accent(track),
                    "initials": track.initials,
                    "coverUrl": track.cover_url or "",
                    "isFavorite": (
                        track.provider_id,
                        track.provider_track_id,
                    ) in favorite_keys,
                }
                for track in self.tracks
            ]
        )


class QueueListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(
            (
                "index",
                "title",
                "artist",
                "duration",
                "accent",
                "initials",
                "coverUrl",
                "isCurrent",
            )
        )
        self.tracks: list[Track] = []

    def set_tracks(self, tracks: Sequence[Track], current_index: int = -1) -> None:
        self.tracks = list(tracks)
        self.replace(
            [
                {
                    "index": index,
                    "title": track.title,
                    "artist": track.artist,
                    "duration": track.duration_text,
                    "accent": _cover_accent(track),
                    "initials": track.initials,
                    "coverUrl": track.cover_url or "",
                    "isCurrent": index == current_index,
                }
                for index, track in enumerate(self.tracks)
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


class FavoriteListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(
            (
                "favoriteId",
                "title",
                "artist",
                "album",
                "duration",
                "source",
                "accent",
                "initials",
                "coverUrl",
                "favoritedAt",
            )
        )
        self.entries: list[FavoriteEntry] = []

    def set_entries(self, entries: Sequence[FavoriteEntry]) -> None:
        self.entries = list(entries)
        self.replace(
            [
                {
                    "favoriteId": entry.id,
                    "title": entry.track.title,
                    "artist": entry.track.artist,
                    "album": entry.track.album,
                    "duration": entry.track.duration_text,
                    "source": entry.track.provider_id.upper(),
                    "accent": _cover_accent(entry.track),
                    "initials": entry.track.initials,
                    "coverUrl": entry.track.cover_url or "",
                    "favoritedAt": entry.favorited_at.astimezone().strftime(
                        "%m-%d %H:%M"
                    ),
                }
                for entry in self.entries
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
                "isFavorite",
                "canMoveUp",
                "canMoveDown",
            )
        )
        self.entries: list[PlaylistTrackEntry] = []

    def set_entries(
        self,
        entries: Sequence[PlaylistTrackEntry],
        favorite_keys: set[tuple[str, str]] | None = None,
    ) -> None:
        self.entries = list(entries)
        favorite_keys = favorite_keys or set()
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
                    "accent": _cover_accent(entry.track),
                    "initials": entry.track.initials,
                    "coverUrl": entry.track.cover_url or "",
                    "isFavorite": (
                        entry.track.provider_id,
                        entry.track.provider_track_id,
                    ) in favorite_keys,
                    "canMoveUp": index > 0,
                    "canMoveDown": index < last_index,
                }
                for index, entry in enumerate(self.entries)
            ]
        )


class HistoryListModel(DictionaryListModel):
    def __init__(self) -> None:
        super().__init__(
            (
                "historyId",
                "title",
                "artist",
                "album",
                "duration",
                "source",
                "accent",
                "initials",
                "coverUrl",
                "playedAt",
                "listenedText",
                "completed",
                "isFavorite",
            )
        )
        self.entries: list[HistoryEntry] = []

    def set_entries(
        self,
        entries: Sequence[HistoryEntry],
        favorite_keys: set[tuple[str, str]] | None = None,
    ) -> None:
        self.entries = list(entries)
        favorite_keys = favorite_keys or set()
        self.replace(
            [
                {
                    "historyId": entry.id,
                    "title": entry.track.title,
                    "artist": entry.track.artist,
                    "album": entry.track.album,
                    "duration": entry.track.duration_text,
                    "source": entry.track.provider_id.upper(),
                    "accent": _cover_accent(entry.track),
                    "initials": entry.track.initials,
                    "coverUrl": entry.track.cover_url or "",
                    "playedAt": entry.played_at.astimezone().strftime("%m-%d %H:%M"),
                    "listenedText": self._format_duration(entry.listened_ms),
                    "completed": entry.completed,
                    "isFavorite": (
                        entry.track.provider_id,
                        entry.track.provider_track_id,
                    ) in favorite_keys,
                }
                for entry in self.entries
            ]
        )

    @staticmethod
    def _format_duration(milliseconds: int) -> str:
        total_seconds = max(0, milliseconds // 1000)
        minutes, seconds = divmod(total_seconds, 60)
        return f"{minutes}:{seconds:02d}"
