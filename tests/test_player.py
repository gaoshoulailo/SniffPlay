from sniffplay.models import StreamInfo, Track
from sniffplay.player import MockPlayer, PlayerState


def test_mock_player_tracks_position_volume_and_end_state() -> None:
    player = MockPlayer()
    track = Track("local", "one", "Test", "Artist", "Album", 10_000)

    player.play(track, StreamInfo("test.wav"))
    player.seek(9_500)
    player.set_volume(42)
    snapshot = player.snapshot()

    assert snapshot.state is PlayerState.PLAYING
    assert 9_500 <= snapshot.position_ms < 10_000
    assert snapshot.volume == 42

    player.seek(10_000)
    assert player.snapshot().state is PlayerState.ENDED

