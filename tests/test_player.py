from sniffplay.models import StreamInfo, Track
from sniffplay.player import MockPlayer, PlayerState
from sniffplay.player.mpv_backend import MpvPlayer


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


def test_mpv_snapshot_prefers_pause_over_core_idle() -> None:
    class FakeMpvClient:
        time_pos = 2.0
        duration = 10.0
        eof_reached = False
        pause = True
        core_idle = True

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "one", "Test", "Artist", "Album", 10_000)
    player._state = PlayerState.PLAYING
    player._volume = 80

    assert player.snapshot().state is PlayerState.PAUSED


def test_mpv_snapshot_detects_end_when_position_reaches_duration() -> None:
    class FakeMpvClient:
        time_pos = 10.0
        duration = 10.0
        eof_reached = False
        pause = False
        core_idle = True

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "one", "Test", "Artist", "Album", 10_000)
    player._state = PlayerState.LOADING
    player._volume = 80

    assert player.snapshot().state is PlayerState.ENDED
