from __future__ import annotations

import shutil
import struct
from pathlib import Path

from PySide6.QtCore import QByteArray, QBuffer, QIODevice, QRectF, Qt
from PySide6.QtGui import QColor, QFont, QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer


ROOT = Path(__file__).resolve().parents[1]
SVG_PATH = ROOT / "assets" / "sniffplay-icon.svg"
PNG_PATH = ROOT / "assets" / "sniffplay-icon.png"
ICO_PATH = ROOT / "assets" / "sniffplay.ico"
TASKBAR_SVG_PATH = ROOT / "assets" / "sniffplay-taskbar-icon.svg"
TASKBAR_PNG_PATH = ROOT / "assets" / "sniffplay-taskbar-icon.png"
TASKBAR_ICO_PATH = ROOT / "assets" / "sniffplay-taskbar.ico"
UI_ASSETS_DIR = ROOT / "src" / "sniffplay_ui" / "assets"
VARIANTS_DIR = ROOT / "assets" / "icon-variants"
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)
VARIANTS = (
    ("01-s-play", "01  S形播放", SVG_PATH),
    ("02-vinyl-play", "02  唱片播放", VARIANTS_DIR / "02-vinyl-play.svg"),
    ("03-waveform", "03  音频波形", VARIANTS_DIR / "03-waveform.svg"),
    ("04-headphones", "04  耳机播放", VARIANTS_DIR / "04-headphones.svg"),
    ("05-sonic-scan", "05  声波扫描", VARIANTS_DIR / "05-sonic-scan.svg"),
    ("06-music-note", "06  音符播放", VARIANTS_DIR / "06-music-note.svg"),
)


def render(renderer: QSvgRenderer, size: int) -> QImage:
    image = QImage(size, size, QImage.Format.Format_ARGB32)
    image.fill(QColor(0, 0, 0, 0))
    painter = QPainter(image)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
    renderer.render(painter, QRectF(0, 0, size, size))
    painter.end()
    return image


def png_bytes(image: QImage) -> bytes:
    payload = QByteArray()
    buffer = QBuffer(payload)
    buffer.open(QIODevice.OpenModeFlag.WriteOnly)
    if not image.save(buffer, "PNG"):
        raise RuntimeError("Could not encode icon image as PNG")
    return bytes(payload)


def write_ico(path: Path, images: list[tuple[int, bytes]]) -> None:
    header_size = 6 + 16 * len(images)
    offset = header_size
    entries = []
    for size, payload in images:
        dimension = 0 if size >= 256 else size
        entries.append(
            struct.pack(
                "<BBBBHHII",
                dimension,
                dimension,
                0,
                0,
                1,
                32,
                len(payload),
                offset,
            )
        )
        offset += len(payload)

    with path.open("wb") as output:
        output.write(struct.pack("<HHH", 0, 1, len(images)))
        output.writelines(entries)
        for _, payload in images:
            output.write(payload)


def build_variant(name: str, source: Path) -> QImage:
    renderer = QSvgRenderer(str(source))
    if not renderer.isValid():
        raise RuntimeError(f"Invalid SVG source: {source}")

    master = render(renderer, 1024)
    png_path = VARIANTS_DIR / f"{name}.png"
    ico_path = VARIANTS_DIR / f"{name}.ico"
    if not master.save(str(png_path), "PNG"):
        raise RuntimeError(f"Could not write PNG icon: {png_path}")

    write_ico(
        ico_path,
        [(size, png_bytes(render(renderer, size))) for size in ICO_SIZES],
    )
    return master


def write_contact_sheet(icons: list[tuple[str, QImage]]) -> Path:
    sheet = QImage(1200, 820, QImage.Format.Format_ARGB32)
    sheet.fill(QColor("#101311"))
    painter = QPainter(sheet)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
    painter.setPen(QColor("#eef3ef"))
    painter.setFont(QFont("Microsoft YaHei UI", 18, QFont.Weight.DemiBold))

    for index, (label, icon) in enumerate(icons):
        column = index % 3
        row = index // 3
        x = 90 + column * 380
        y = 45 + row * 395
        painter.drawImage(QRectF(x, y, 260, 260), icon)
        painter.drawText(
            QRectF(x - 25, y + 280, 310, 52),
            Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop,
            label,
        )

    painter.end()
    path = VARIANTS_DIR / "contact-sheet.png"
    if not sheet.save(str(path), "PNG"):
        raise RuntimeError(f"Could not write contact sheet: {path}")
    return path


def main() -> None:
    app = QGuiApplication.instance() or QGuiApplication([])
    VARIANTS_DIR.mkdir(parents=True, exist_ok=True)
    icons = [(label, build_variant(name, source)) for name, label, source in VARIANTS]

    primary = icons[0][1]
    if not primary.save(str(PNG_PATH), "PNG"):
        raise RuntimeError(f"Could not write PNG icon: {PNG_PATH}")
    primary_renderer = QSvgRenderer(str(SVG_PATH))
    write_ico(
        ICO_PATH,
        [(size, png_bytes(render(primary_renderer, size))) for size in ICO_SIZES],
    )

    taskbar_renderer = QSvgRenderer(str(TASKBAR_SVG_PATH))
    if not taskbar_renderer.isValid():
        raise RuntimeError(f"Invalid SVG source: {TASKBAR_SVG_PATH}")
    taskbar = render(taskbar_renderer, 1024)
    if not taskbar.save(str(TASKBAR_PNG_PATH), "PNG"):
        raise RuntimeError(f"Could not write PNG icon: {TASKBAR_PNG_PATH}")
    write_ico(
        TASKBAR_ICO_PATH,
        [(size, png_bytes(render(taskbar_renderer, size))) for size in ICO_SIZES],
    )
    UI_ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    packaged_taskbar_path = UI_ASSETS_DIR / TASKBAR_PNG_PATH.name
    packaged_taskbar_ico_path = UI_ASSETS_DIR / TASKBAR_ICO_PATH.name
    if not taskbar.save(str(packaged_taskbar_path), "PNG"):
        raise RuntimeError(f"Could not write packaged icon: {packaged_taskbar_path}")
    shutil.copy2(TASKBAR_ICO_PATH, packaged_taskbar_ico_path)

    print(PNG_PATH)
    print(ICO_PATH)
    print(TASKBAR_PNG_PATH)
    print(TASKBAR_ICO_PATH)
    print(packaged_taskbar_path)
    print(packaged_taskbar_ico_path)
    print(write_contact_sheet(icons))
    assert app is not None


if __name__ == "__main__":
    main()
