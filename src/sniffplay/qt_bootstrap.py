from __future__ import annotations

import ctypes
import os
from pathlib import Path

_system_icu: ctypes.CDLL | None = None


def prepare_qt_runtime() -> None:
    """Prefer the Windows ICU runtime over incompatible Conda copies."""
    global _system_icu
    if os.name != "nt" or _system_icu is not None:
        return

    system_root = Path(os.environ.get("SystemRoot", r"C:\Windows"))
    icu_path = system_root / "System32" / "icuuc.dll"
    if icu_path.exists():
        _system_icu = ctypes.WinDLL(str(icu_path))

