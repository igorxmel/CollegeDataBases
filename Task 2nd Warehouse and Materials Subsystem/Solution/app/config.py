"""Пути к ресурсам и оформление приложения согласно руководству по стилю."""

from pathlib import Path
import sys

APP_DIR = Path(__file__).resolve().parent

if getattr(sys, "frozen", False):
    # Приложение собрано в исполняемый файл: ресурсы распакованы во временную
    # папку, а база данных лежит рядом с exe-файлом, чтобы изменения сохранялись.
    RESOURCES_DIR = Path(sys._MEIPASS) / "resources"
    DATABASE_PATH = Path(sys.executable).resolve().parent / "mosaic.db"
else:
    RESOURCES_DIR = APP_DIR / "resources"
    DATABASE_PATH = APP_DIR.parent / "database" / "mosaic.db"

ICON_PATH = RESOURCES_DIR / "Мозаика.ico"
LOGO_PATH = RESOURCES_DIR / "Мозаика.png"

COMPANY_NAME = "Мозаика"
APP_TITLE = f"{COMPANY_NAME} — учёт материалов"

# Логотип 1024×1024 уменьшается целым делителем, поэтому пропорции и цвет
# изображения остаются без искажений.
LOGO_SUBSAMPLE = 12

# Палитра из руководства по стилю (Приложение 2).
PRIMARY_BACKGROUND = "#FFFFFF"
SECONDARY_BACKGROUND = "#ABCFCE"
ACCENT_COLOR = "#546F94"
ACCENT_ACTIVE_COLOR = "#42597A"
TEXT_COLOR = "#1B1B1B"
MUTED_TEXT_COLOR = "#4F5B66"
BORDER_COLOR = "#9AB6B5"

FONT_FAMILY = "Comic Sans MS"
FONT_TITLE = (FONT_FAMILY, 16, "bold")
FONT_HEADING = (FONT_FAMILY, 12, "bold")
FONT_CARD_TITLE = (FONT_FAMILY, 12)
FONT_BODY = (FONT_FAMILY, 10)
FONT_SMALL = (FONT_FAMILY, 9)

WINDOW_MIN_WIDTH = 900
WINDOW_MIN_HEIGHT = 620
