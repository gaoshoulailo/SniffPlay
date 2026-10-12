import asyncio
from types import SimpleNamespace

import pytest

from sniffplay.qt_bootstrap import prepare_qt_runtime

prepare_qt_runtime()

from PySide6.QtCore import QCoreApplication

from sniffplay.controllers import AppController
from sniffplay.database import Database
from sniffplay.database.repositories import HistoryRepository, PlaylistRepository
from sniffplay.models import StreamInfo, Track
from sniffplay.player import MockPlayer, PlayerState
from sniffplay.player.base import PlayerSnapshot
from sniffplay.player.mpv_backend import MpvPlayer
from sniffplay.providers import ProviderRegistry
from sniffplay.providers.base import ProviderError
from sniffplay.providers.mock import MockProvider
from sniffplay.services.search_service import SearchService


class FailingProvider(MockProvider):
    id = "failing"

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        raise ProviderError("network unavailable")


@pytest.fixture
def controller(tmp_path):
    app = QCoreApplication.instance() or QCoreApplication([])
    database = Database(tmp_path / "regressions.db")
    database.initialize()
    instance = AppController(
        SearchService(ProviderRegistry()),
        MockPlayer(),
        PlaylistRepository(database),
        HistoryRepository(database),
    )
    try:
        yield instance
    finally:
        instance.close()
        database.close()
    assert app is not None


@pytest.mark.parametrize("first_result", ["old", "new"])
@pytest.mark.parametrize("old_fails", [False, True])
async def test_search_ignores_stale_results_and_errors(
    controller, monkeypatch, first_result, old_fails
) -> None:
    gates = {query: asyncio.Event() for query in ("old", "new")}
    tracks = {
        query: Track("demo", query, query, "artist", "album", 60_000)
        for query in gates
    }

    async def search(query):
        await gates[query].wait()
        if query == "old" and old_fails:
            raise ProviderError("old request failed")
        return [tracks[query]]

    monkeypatch.setattr(controller._search_service, "search", search)
    messages = []
    controller.toastRequested.connect(messages.append)
    old_request = asyncio.create_task(controller._search("old", show_result_toast=True))
    await asyncio.sleep(0)
    new_request = asyncio.create_task(controller._search("new", show_result_toast=True))
    await asyncio.sleep(0)
    requests = {"old": old_request, "new": new_request}
    try:
        gates[first_result].set()
        await requests[first_result]
        assert controller.searching is (first_result == "old")
        if first_result == "old":
            assert controller._track_model.tracks == []
            assert messages == []
        for gate in gates.values():
            gate.set()
        await asyncio.gather(*requests.values())
        assert controller._search_results == [tracks["new"]]
        assert controller._track_model.tracks == [tracks["new"]]
        assert controller.searching is False
        assert controller.statusMessage == "找到 1 首歌曲"
        assert messages == ["找到 1 首歌曲"]
    finally:
        for request in requests.values():
            request.cancel()
        await asyncio.gather(*requests.values(), return_exceptions=True)


async def test_all_failed_providers_raise_error() -> None:
    registry = ProviderRegistry()
    registry.register(FailingProvider())
    with pytest.raises(ProviderError, match="所有音乐来源搜索失败"):
        await SearchService(registry).search("query")


@pytest.mark.parametrize("query, expected_count", [("雨", 1), ("no matching song", 0)])
async def test_partial_provider_failure_preserves_success(query, expected_count) -> None:
    registry = ProviderRegistry()
    registry.register(FailingProvider())
    registry.register(MockProvider())
    assert len(await SearchService(registry).search(query)) == expected_count


async def test_search_without_providers_returns_empty_results() -> None:
    assert await SearchService(ProviderRegistry()).search("query") == []


async def test_controller_reports_search_failure_and_clears_loading(controller) -> None:
    registry = ProviderRegistry()
    registry.register(FailingProvider())
    controller._search_service = SearchService(registry)
    track = MockProvider._tracks[0]
    controller._search_results = [track]
    controller._track_model.set_tracks([track])
    await controller._search("query", show_result_toast=True)
    assert controller.statusMessage == "搜索失败，请稍后重试"
    assert controller.searching is False
    assert controller._search_results == []
    assert controller._track_model.tracks == []


@pytest.fixture
def mpv_player():
    player = MpvPlayer.__new__(MpvPlayer)
    player._client = SimpleNamespace(
        time_pos=60.0,
        duration=120.0,
        pause=False,
        core_idle=False,
        play=lambda url: None,
    )
    player._current_track = Track("demo", "one", "first", "artist", "album", 120_000)
    player._state = PlayerState.PLAYING
    player._volume = 80
    player._paused = False
    player._awaiting_start_file = False
    player._end_file_seen = False
    player._end_file_error = False
    return player


@pytest.mark.parametrize("paused", [False, True])
def test_mpv_error_is_not_reported_as_natural_end(mpv_player, paused) -> None:
    mpv_player._paused = paused
    mpv_player._client.time_pos = mpv_player._client.duration
    mpv_player._handle_end_file(SimpleNamespace(data=SimpleNamespace(reason=4)))
    assert mpv_player.snapshot().state is PlayerState.ERROR
    mpv_player.toggle()
    assert mpv_player.snapshot().state is PlayerState.ERROR
    track = Track("demo", "two", "second", "artist", "album", 180_000)
    mpv_player.play(track, StreamInfo("test.wav"))
    assert mpv_player.snapshot().state is PlayerState.LOADING
    mpv_player._handle_start_file(None)
    mpv_player._client.time_pos = 0.0
    assert mpv_player.snapshot().state is PlayerState.PLAYING


def test_mpv_ignores_previous_track_error_while_switching(mpv_player) -> None:
    mpv_player._awaiting_start_file = True
    mpv_player._handle_end_file(SimpleNamespace(data=SimpleNamespace(reason=4)))
    assert mpv_player._end_file_error is False
    assert mpv_player.snapshot().state is PlayerState.LOADING


def test_mpv_loading_snapshot_does_not_expose_previous_track_progress(mpv_player) -> None:
    track = Track("demo", "two", "second", "artist", "album", 180_000)
    mpv_player.play(track, StreamInfo("test.wav"))
    snapshot = mpv_player.snapshot()
    assert snapshot.state is PlayerState.LOADING
    assert snapshot.position_ms == 0
    assert snapshot.duration_ms == 180_000


@pytest.mark.parametrize("repeat_mode", [0, 1, 2])
async def test_playback_error_advances_once_even_in_single_repeat(
    controller, monkeypatch, repeat_mode
) -> None:
    track = MockProvider._tracks[0]
    controller._player.play(track, StreamInfo("test.wav"))
    controller._queue = [track, MockProvider._tracks[1]]
    controller._queue_index = 0
    controller._repeat_mode = repeat_mode
    original_snapshot = controller._player.snapshot
    monkeypatch.setattr(
        controller._player,
        "snapshot",
        lambda: (
            PlayerSnapshot(PlayerState.ERROR, 60_000, 120_000)
            if controller._player.current_track == track else original_snapshot()
        ),
    )
    async def resolve_stream(track):
        return StreamInfo("test.wav")

    monkeypatch.setattr(controller._search_service, "resolve_stream", resolve_stream)
    messages = []
    controller.toastRequested.connect(messages.append)
    request_id = controller._play_request_id
    controller._poll_player()
    controller._poll_player()
    await asyncio.sleep(0)
    assert controller._advance_scheduled is False
    assert controller._play_request_id == request_id + 1
    assert controller._queue_index == 1
    assert messages == ["播放失败，正在尝试下一首"]
    assert controller._history_repository.recent() == []


@pytest.mark.parametrize("state", [PlayerState.LOADING, PlayerState.ERROR, PlayerState.IDLE])
async def test_history_ignores_stale_progress_until_track_is_playing(
    controller, monkeypatch, state
) -> None:
    track = Track("demo", "new", "new track", "artist", "album", 120_000)
    controller._player.play(track, StreamInfo("test.wav"))
    snapshot = PlayerSnapshot(state, 60_000, 120_000)
    monkeypatch.setattr(controller._player, "snapshot", lambda: snapshot)
    controller._poll_player()
    assert controller._history_repository.recent() == []
    assert controller._history_recorded is False
    snapshot = PlayerSnapshot(PlayerState.PLAYING, 0, 120_000)
    controller._poll_player()
    assert controller._history_repository.recent() == []
    snapshot = PlayerSnapshot(PlayerState.PLAYING, 30_000, 120_000)
    controller._poll_player()
    controller._poll_player()
    entries = controller._history_repository.recent()
    assert len(entries) == 1
    assert entries[0].track.provider_track_id == "new"
    assert entries[0].listened_ms == 30_000


@pytest.mark.parametrize("repeat_mode", [0, 1, 2])
async def test_error_at_queue_end_stops_without_repeated_notifications(
    controller, monkeypatch, repeat_mode
) -> None:
    track = MockProvider._tracks[0]
    controller._player.play(track, StreamInfo("test.wav"))
    controller._queue = [track]
    controller._queue_index = 0
    controller._repeat_mode = repeat_mode
    monkeypatch.setattr(
        controller._player, "snapshot",
        lambda: PlayerSnapshot(PlayerState.ERROR),
    )
    messages = []
    controller.toastRequested.connect(messages.append)
    request_id = controller._play_request_id
    controller._poll_player()
    await asyncio.sleep(0)
    controller._poll_player()
    await asyncio.sleep(0)
    assert controller._play_request_id == request_id
    assert messages == [
        "播放失败，正在尝试下一首",
        "没有可播放的后续歌曲，已停止自动切歌",
    ]


@pytest.mark.parametrize("all_fail", [False, True])
async def test_error_skip_continues_past_unresolvable_tracks(
    controller, monkeypatch, all_fail
) -> None:
    tracks = [Track("demo", str(index), str(index), "artist", "album", 60_000)
              for index in range(3)]
    controller._queue = tracks
    controller._queue_index = 0
    attempts = []

    async def resolve_stream(track):
        attempts.append(track)
        if all_fail or track == tracks[1]:
            raise ProviderError("unavailable")
        return StreamInfo("test.wav")

    monkeypatch.setattr(controller._search_service, "resolve_stream", resolve_stream)
    await controller._advance_after_error(controller._play_request_id)
    assert attempts == tracks[1:]
    if all_fail:
        assert controller.statusMessage == "没有可播放的后续歌曲，已停止自动切歌"
    else:
        assert controller._player.current_track == tracks[2]
        assert controller._queue_index == 2


async def test_pending_error_skip_does_not_override_manual_playback(controller, monkeypatch):
    tracks = [Track("demo", str(index), str(index), "artist", "album", 60_000)
              for index in range(3)]
    controller._queue = tracks
    controller._queue_index = 0
    gate = asyncio.Event()
    attempts = []

    async def resolve_stream(track):
        attempts.append(track)
        if track == tracks[1]:
            await gate.wait()
            raise ProviderError("unavailable")
        return StreamInfo("test.wav")

    monkeypatch.setattr(controller._search_service, "resolve_stream", resolve_stream)
    skip = asyncio.create_task(controller._advance_after_error(controller._play_request_id))
    try:
        await asyncio.sleep(0)
        await controller._play_tracks([tracks[0]], 0)
        gate.set()
        await skip
        assert attempts == [tracks[1], tracks[0]]
        assert controller._player.current_track == tracks[0]
        assert controller._queue == [tracks[0]]
    finally:
        gate.set()
        await skip
