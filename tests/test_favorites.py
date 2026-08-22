from pathlib import Path

from sniffplay.database import Database
from sniffplay.database.repositories import FavoriteRepository
from sniffplay.models import Track


def test_favorites_are_unique_toggleable_and_persisted(tmp_path: Path) -> None:
    database = Database(tmp_path / "favorites.db")
    database.initialize()
    favorites = FavoriteRepository(database)
    track = Track("demo", "one", "歌曲", "歌手", "专辑", 120_000)

    assert not favorites.is_favorited(track)
    first = favorites.add(track)
    second = favorites.add(track)
    assert first.id == second.id
    assert favorites.is_favorited(track)
    assert len(favorites.list_all()) == 1

    assert favorites.toggle(track) is False
    assert favorites.list_all() == []
    assert favorites.toggle(track) is True
    assert favorites.list_all()[0].track.title == "歌曲"

    database.close()


def test_favorites_restore_local_playback_and_isolate_provider_ids(
    tmp_path: Path,
) -> None:
    database = Database(tmp_path / "local-favorites.db")
    database.initialize()
    favorites = FavoriteRepository(database)
    local_path = tmp_path / "song.wav"
    local = Track("local", str(local_path), "本地歌曲", "本地文件", "音乐", 0)
    other_provider = Track("other", str(local_path), "另一首", "歌手", "专辑", 0)

    favorites.add(local)
    favorites.add(other_provider)
    entries = favorites.list_all()

    assert len(entries) == 2
    local_entry = next(entry for entry in entries if entry.track.provider_id == "local")
    assert local_entry.track.playback_uri == str(local_path)
    assert favorites.is_favorited(other_provider)

    database.close()
