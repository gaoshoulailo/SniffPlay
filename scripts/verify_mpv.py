from __future__ import annotations

import argparse
import math
import struct
import tempfile
import time
import wave
from pathlib import Path

from sniffplay.models import StreamInfo, Track
from sniffplay.player import PlayerState
from sniffplay.player.mpv_backend import MpvPlayer


def create_test_audio(path: Path, duration_seconds: int) -> None:
    sample_rate = 44_100
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        for second in range(duration_seconds):
            frames = bytearray()
            for index in range(sample_rate):
                offset = second * sample_rate + index
                sample = int(1_200 * math.sin(2 * math.pi * 440 * offset / sample_rate))
                frames.extend(struct.pack("<h", sample))
            output.writeframes(frames)


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify SniffPlay's libmpv backend")
    parser.add_argument("--duration", type=int, default=8)
    args = parser.parse_args()
    duration = max(3, args.duration)
    audio_path = Path(tempfile.gettempdir()) / "sniffplay-mpv-verification.wav"
    create_test_audio(audio_path, duration)

    player = MpvPlayer()
    player.set_volume(0)
    track = Track(
        "local",
        str(audio_path),
        "Playback Verification",
        "SniffPlay",
        "Diagnostics",
        duration * 1_000,
    )
    try:
        player.play(track, StreamInfo(str(audio_path)))
        deadline = time.monotonic() + duration - 1
        while time.monotonic() < deadline:
            snapshot = player.snapshot()
            if snapshot.state not in (PlayerState.LOADING, PlayerState.PLAYING):
                raise RuntimeError(f"Unexpected player state: {snapshot.state}")
            time.sleep(0.25)
        print(player.snapshot())
        print("libmpv verification passed")
        return 0
    finally:
        player.close()


if __name__ == "__main__":
    raise SystemExit(main())

