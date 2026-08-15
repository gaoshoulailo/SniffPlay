from __future__ import annotations

from sniffplay.providers.base import MusicProvider


class ProviderRegistry:
    def __init__(self) -> None:
        self._providers: dict[str, MusicProvider] = {}

    def register(self, provider: MusicProvider) -> None:
        if provider.id in self._providers:
            raise ValueError(f"Provider already registered: {provider.id}")
        self._providers[provider.id] = provider

    def enabled(self) -> tuple[MusicProvider, ...]:
        return tuple(self._providers.values())

    def get(self, provider_id: str) -> MusicProvider:
        try:
            return self._providers[provider_id]
        except KeyError as error:
            raise LookupError(f"Unknown provider: {provider_id}") from error
