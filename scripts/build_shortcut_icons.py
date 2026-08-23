from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QRectF, Qt
from PySide6.QtGui import QColor, QFont, QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer

from build_icon import ICO_SIZES, png_bytes, render, write_ico


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "shortcut-icon-variants"
VARIANTS = (
    ("01-dark-brand", "01  深色品牌"),
    ("02-mint-tile", "02  薄荷高亮"),
    ("03-light-contrast", "03  浅色高对比"),
    ("04-round-badge", "04  圆形徽章"),
    ("05-player-window", "05  播放器窗口"),
    ("06-launch-signal", "06  启动声波"),
)


def build_variant(name: str) -> QImage:
    source = OUTPUT_DIR / f"{name}.svg"
    renderer = QSvgRenderer(str(source))
    if not renderer.isValid():
        raise RuntimeError(f"Invalid SVG source: {source}")

    master = render(renderer, 1024)
    png_path = OUTPUT_DIR / f"{name}.png"
    ico_path = OUTPUT_DIR / f"{name}.ico"
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
    path = OUTPUT_DIR / "contact-sheet.png"
    if not sheet.save(str(path), "PNG"):
        raise RuntimeError(f"Could not write contact sheet: {path}")
    return path


def main() -> None:
    app = QGuiApplication.instance() or QGuiApplication([])
    icons = [(label, build_variant(name)) for name, label in VARIANTS]
    print(write_contact_sheet(icons))
    assert app is not None


if __name__ == "__main__":
    main()
