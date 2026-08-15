from pathlib import Path

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

