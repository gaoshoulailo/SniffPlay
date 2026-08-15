from sniffplay.providers import ProviderRegistry
from sniffplay.providers.mock import MockProvider
from sniffplay.services.search_service import SearchService


async def test_search_service_aggregates_registered_providers() -> None:
    registry = ProviderRegistry()
    registry.register(MockProvider())

    tracks = await SearchService(registry).search("雨")

    assert len(tracks) == 1
    assert tracks[0].title == "雨停之后"

