from pathlib import Path
import sys

from PyInstaller.utils.hooks import collect_data_files


project_root = Path(SPECPATH)
source_root = project_root / "src"
icon_path = project_root / "assets" / "sniffplay.ico"
mpv_dll = project_root / "vendor" / "mpv" / "libmpv-2.dll"

if not icon_path.is_file():
    raise FileNotFoundError(f"Application icon not found: {icon_path}")
if not mpv_dll.is_file():
    raise FileNotFoundError(
        "libmpv-2.dll not found. Place it in vendor/mpv before building."
    )

qml_data = collect_data_files(
    "sniffplay_ui",
    includes=[
        "*.qml",
        "assets/*.ico",
        "assets/*.png",
        "components/*.qml",
        "pages/*.qml",
        "themes/*",
    ],
)

runtime_binaries = [(str(mpv_dll), "vendor/mpv")]
conda_runtime_dir = Path(sys.base_prefix) / "Library" / "bin"
for dll_name in (
    "ffi.dll",
    "libbz2.dll",
    "libexpat.dll",
    "liblzma.dll",
    "sqlite3.dll",
):
    dll_path = conda_runtime_dir / dll_name
    if dll_path.is_file():
        runtime_binaries.append((str(dll_path), "."))

excluded_qt_modules = [
    "PySide6.QtWebEngineCore",
    "PySide6.QtWebEngineWidgets",
    "PySide6.QtWebEngineQuick",
    "PySide6.QtPdf",
    "PySide6.QtPdfWidgets",
    "PySide6.Qt3DCore",
    "PySide6.Qt3DRender",
    "PySide6.Qt3DInput",
    "PySide6.Qt3DLogic",
    "PySide6.Qt3DExtras",
    "PySide6.QtQuick3D",
    "PySide6.QtQuick3DAssetImport",
    "PySide6.QtQuick3DHelpers",
    "PySide6.QtQuick3DParticleSystems",
    "PySide6.QtQuick3DRuntimeRender",
    "PySide6.QtQuick3DUtils",
    "PySide6.QtMultimedia",
    "PySide6.QtMultimediaWidgets",
]

analysis = Analysis(
    [str(source_root / "sniffplay" / "__main__.py")],
    pathex=[str(source_root)],
    binaries=runtime_binaries,
    datas=qml_data,
    hiddenimports=["mpv"],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=excluded_qt_modules,
    noarchive=False,
    optimize=0,
)
pyz = PYZ(analysis.pure)

executable = EXE(
    pyz,
    analysis.scripts,
    [],
    exclude_binaries=True,
    name="SniffPlay",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=str(icon_path),
)

collection = COLLECT(
    executable,
    analysis.binaries,
    analysis.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="SniffPlay",
)
