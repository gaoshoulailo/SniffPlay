from sniffplay.controllers.list_models import QueueListModel, TrackListModel
from sniffplay.models import Track


def test_track_models_expose_compact_source_labels() -> None:
    bilibili = Track("bilibili", "1", "在线歌曲", "歌手", "专辑", 60_000)
    local = Track("local", "2", "本地歌曲", "歌手", "专辑", 90_000)

    tracks = TrackListModel()
    tracks.set_tracks([bilibili, local])
    queue = QueueListModel()
    queue.set_tracks([bilibili, local])

    assert [item["source"] for item in tracks._items] == ["BILI", "LOCAL"]
    assert [item["source"] for item in queue._items] == ["BILI", "LOCAL"]
