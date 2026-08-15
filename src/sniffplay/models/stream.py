from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class StreamInfo:
    url: str
    http_headers: dict[str, str] = field(default_factory=dict)

