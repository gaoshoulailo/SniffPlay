from sniffplay.providers.mock import MockProvider


async def test_mock_provider_returns_recommendations_for_empty_query() -> None:
    tracks = await MockProvider().search("")

    assert len(tracks) == 5
    assert tracks[0].provider_id == "demo"


async def test_mock_provider_filters_tracks() -> None:
    tracks = await MockProvider().search("北岸")

    assert [track.title for track in tracks] == ["迟来的风"]

