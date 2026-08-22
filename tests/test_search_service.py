from pathlib import Path

import pytest

from sniffplay.models import Track
from sniffplay.providers import ProviderRegistry
from sniffplay.providers.mock import MockProvider
from sniffplay.services.search_service import SearchService


async def test_search_service_aggregates_registered_providers() -> None:
    registry = ProviderRegistry()
    registry.register(MockProvider())

    tracks = await SearchService(registry).search("雨")

    assert len(tracks) == 1
    assert tracks[0].title == "雨停之后"


async def test_search_service_reports_missing_local_file(tmp_path: Path) -> None:
    registry = ProviderRegistry()
    track = Track(
        "local",
        str(tmp_path / "missing.wav"),
        "Missing",
        "Local",
        "Files",
        0,
        playback_uri=str(tmp_path / "missing.wav"),
    )

    with pytest.raises(FileNotFoundError, match="本地音频文件已不存在"):
        await SearchService(registry).resolve_stream(track)
