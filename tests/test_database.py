from pathlib import Path

import pytest

from sniffplay.database import Database
from sniffplay.database.repositories import HistoryRepository, PlaylistRepository
from sniffplay.models import Track


def test_playlist_and_history_are_persisted(tmp_path: Path) -> None:
    database = Database(tmp_path / "test.db")
    database.initialize()
    playlists = PlaylistRepository(database)
    history = HistoryRepository(database)

    created = playlists.create("通勤")
    history.record(
        Track("demo", "track-1", "测试歌曲", "测试歌手", "测试专辑", 180_000)
    )

    assert created.name == "通勤"
    assert playlists.list_all()[0].item_count == 0
    assert history.recent()[0].title == "测试歌曲"

    database.close()


def test_playlist_tracks_can_be_added_reordered_and_removed(tmp_path: Path) -> None:
    database = Database(tmp_path / "playlist-tracks.db")
    database.initialize()
    playlists = PlaylistRepository(database)
    playlist = playlists.create("通勤")
    first = Track("demo", "one", "第一首", "歌手", "专辑", 60_000)
    second = Track("demo", "two", "第二首", "歌手", "专辑", 90_000)
    third = Track("demo", "three", "第三首", "歌手", "专辑", 120_000)

    first_item = playlists.add_track(playlist.id, first)
    second_item = playlists.add_track(playlist.id, second)
    third_item = playlists.add_track(playlist.id, third)

    assert playlists.get(playlist.id).item_count == 3
    assert [entry.track.title for entry in playlists.list_tracks(playlist.id)] == [
        "第一首",
        "第二首",
        "第三首",
    ]

    playlists.move_item(playlist.id, third_item.item_id, 0)
    assert [entry.item_id for entry in playlists.list_tracks(playlist.id)] == [
        third_item.item_id,
        first_item.item_id,
        second_item.item_id,
    ]

    playlists.remove_item(playlist.id, first_item.item_id)
    entries = playlists.list_tracks(playlist.id)
    assert [entry.item_id for entry in entries] == [
        third_item.item_id,
        second_item.item_id,
    ]
    assert [entry.position for entry in entries] == [0, 1]

    database.close()


def test_playlist_rejects_duplicates_and_supports_rename_and_delete(
    tmp_path: Path,
) -> None:
    database = Database(tmp_path / "playlist-management.db")
    database.initialize()
    playlists = PlaylistRepository(database)
    playlist = playlists.create("原名称")
    track = Track("demo", "one", "歌曲", "歌手", "专辑", 60_000)
    playlists.add_track(playlist.id, track)

    try:
        playlists.add_track(playlist.id, track)
    except ValueError as error:
        assert str(error) == "歌曲已在歌单中"
    else:
        raise AssertionError("Duplicate playlist track was accepted")

    assert playlists.rename(playlist.id, "新名称").name == "新名称"
    playlists.delete(playlist.id)
    assert playlists.list_all() == []

    try:
        playlists.list_tracks(playlist.id)
    except LookupError:
        pass
    else:
        raise AssertionError("Deleted playlist still exists")

    database.close()


def test_playlist_preserves_local_playback_and_rejects_invalid_move(
    tmp_path: Path,
) -> None:
    database = Database(tmp_path / "local-playlist.db")
    database.initialize()
    playlists = PlaylistRepository(database)
    playlist = playlists.create("本地音乐")
    audio_path = tmp_path / "song.flac"
    track = Track(
        "local",
        str(audio_path),
        "本地歌曲",
        "本地文件",
        tmp_path.name,
        0,
        playback_uri=str(audio_path),
    )
    item = playlists.add_track(playlist.id, track)

    restored = playlists.list_tracks(playlist.id)[0]
    assert restored.track.playback_uri == str(audio_path)

    with pytest.raises(ValueError, match="out of range"):
        playlists.move_item(playlist.id, item.item_id, 1)
    assert playlists.list_tracks(playlist.id)[0].item_id == item.item_id

    with pytest.raises(ValueError, match="160"):
        playlists.rename(playlist.id, "x" * 161)

    database.close()
