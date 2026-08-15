import logging

from sniffplay.player.base import Player, PlayerState, PlayerUnavailableError
from sniffplay.player.mock import MockPlayer
from sniffplay.player.mpv_backend import MpvPlayer
from sniffplay.player.unavailable import UnavailablePlayer

logger = logging.getLogger(__name__)


def create_player() -> Player:
    try:
        return MpvPlayer()
    except PlayerUnavailableError as error:
        logger.warning("libmpv is unavailable: %s", error)
        return UnavailablePlayer(str(error))


__all__ = [
    "MockPlayer",
    "Player",
    "PlayerState",
    "PlayerUnavailableError",
    "create_player",
]
