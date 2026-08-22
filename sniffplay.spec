# PyInstaller specification for the Windows single-file build.
from pathlib import Path
import sys

from PyInstaller.utils.hooks import collect_submodules


project_root = Path(SPECPATH)
source_root = project_root / "src"
ui_root = source_root / "sniffplay_ui"
mpv_dll = project_root / "vendor" / "mpv" / "libmpv-2.dll"

if not mpv_dll.is_file():
    raise RuntimeError(
        "Missing vendor/mpv/libmpv-2.dll. "
        "Set up the DLL before building, or remove the binary entry from sniffplay.spec."
    )

qml_datas = [
    (str(path), str(Path("sniffplay_ui") / path.relative_to(ui_root).parent))
    for path in ui_root.rglob("*")
    if path.is_file() and path.suffix.lower() in {".qml", ".json"}
]

runtime_binaries = [(str(mpv_dll), "vendor/mpv")]
conda_bin = Path(sys.base_prefix) / "Library" / "bin"
for dll_name in (
    "liblzma.dll",
    "libbz2.dll",
    "ffi.dll",
    "libexpat.dll",
    "sqlite3.dll",
):
    dll_path = conda_bin / dll_name
    if dll_path.is_file():
        runtime_binaries.append((str(dll_path), "."))

analysis = Analysis(
    [str(source_root / "sniffplay" / "__main__.py")],
    pathex=[str(source_root)],
    binaries=runtime_binaries,
    datas=qml_datas,
    hiddenimports=collect_submodules("mpv"),
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)

pyz = PYZ(analysis.pure)

exe = EXE(
    pyz,
    analysis.scripts,
    analysis.binaries,
    analysis.datas,
    [],
    name="SniffPlay",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
