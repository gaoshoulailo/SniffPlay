from types import SimpleNamespace

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
    player._state = PlayerState.PLAYING
    player._volume = 80

    assert player.snapshot().state is PlayerState.ENDED


def test_mpv_snapshot_ignores_stale_eof_property() -> None:
    class FakeMpvClient:
        time_pos = 0.0
        duration = 10.0
        eof_reached = True
        pause = False
        core_idle = True

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "one", "Test", "Artist", "Album", 10_000)
    player._state = PlayerState.PLAYING
    player._volume = 80

    assert player.snapshot().state is PlayerState.PLAYING


def test_mpv_toggle_tracks_pause_state_without_rereading_async_property() -> None:
    class FakeMpvClient:
        pause = False
        time_pos = 2.0
        duration = 10.0
        core_idle = True

        def __setattr__(self, name: str, value: object) -> None:
            object.__setattr__(self, name, value)

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "one", "Test", "Artist", "Album", 10_000)
    player._state = PlayerState.PLAYING
    player._paused = False
    player._volume = 80

    player.toggle()
    assert player._paused is True
    assert player._client.pause is True
    assert player.snapshot().state is PlayerState.PAUSED
    player.toggle()
    assert player._paused is False
    assert player._client.pause is False
    assert player.snapshot().state is PlayerState.PLAYING


def test_mpv_snapshot_stays_loading_until_new_file_starts() -> None:
    class FakeMpvClient:
        time_pos = 10.0
        duration = 10.0
        pause = False
        core_idle = False

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "two", "Next", "Artist", "Album", 10_000)
    player._state = PlayerState.LOADING
    player._paused = False
    player._end_file_seen = False
    player._awaiting_start_file = True
    player._volume = 80

    assert player.snapshot().state is PlayerState.LOADING


def test_mpv_snapshot_does_not_treat_loading_duration_as_ended() -> None:
    class FakeMpvClient:
        time_pos = 10.0
        duration = 10.0
        pause = False
        core_idle = True

    player = MpvPlayer.__new__(MpvPlayer)
    player._client = FakeMpvClient()
    player._current_track = Track("local", "two", "Next", "Artist", "Album", 10_000)
    player._state = PlayerState.LOADING
    player._paused = False
    player._end_file_seen = False
    player._awaiting_start_file = False
    player._volume = 80

    assert player.snapshot().state is PlayerState.LOADING


def test_mpv_ignores_previous_file_end_event_while_switching() -> None:
    player = MpvPlayer.__new__(MpvPlayer)
    player._awaiting_start_file = True
    player._end_file_seen = False

    player._handle_end_file(SimpleNamespace(data=SimpleNamespace(reason=0)))

    assert player._end_file_seen is False


def test_mpv_ignores_restarted_end_event_for_new_track() -> None:
    player = MpvPlayer.__new__(MpvPlayer)
    player._awaiting_start_file = False
    player._end_file_seen = False

    player._handle_end_file(SimpleNamespace(data=SimpleNamespace(reason=1)))

    assert player._end_file_seen is False


def test_mpv_accepts_natural_end_after_new_file_starts() -> None:
    player = MpvPlayer.__new__(MpvPlayer)
    player._awaiting_start_file = True
    player._end_file_seen = True

    player._handle_start_file(SimpleNamespace())
    player._handle_end_file(SimpleNamespace(data=SimpleNamespace(reason=0)))

    assert player._awaiting_start_file is False
    assert player._end_file_seen is True
