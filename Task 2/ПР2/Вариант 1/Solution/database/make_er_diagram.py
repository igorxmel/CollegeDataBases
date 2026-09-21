"""Построение ER-диаграммы базы данных «Мозаика» в формате PDF.

Структура таблиц, полей и связей не задаётся вручную, а читается из готовой
базы данных mosaic.db через служебные таблицы SQLite (PRAGMA table_info и
PRAGMA foreign_key_list), поэтому диаграмма всегда соответствует схеме.
Вручную задаётся только расположение блоков и маршруты линий связи.

Запуск: python make_er_diagram.py
"""

from pathlib import Path
import sqlite3

from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

DATABASE_DIR = Path(__file__).resolve().parent
DATABASE_PATH = DATABASE_DIR / "mosaic.db"
DIAGRAM_PATH = DATABASE_DIR / "er_diagram.pdf"

ACCENT_COLOR = HexColor("#546F94")
SECONDARY_COLOR = HexColor("#ABCFCE")
BACKGROUND_COLOR = HexColor("#FFFFFF")
TEXT_COLOR = HexColor("#1B1B1B")
FOREIGN_KEY_COLOR = HexColor("#7A5230")

PAGE_SIZE = landscape(A4)
BOX_WIDTH = 168
HEADER_HEIGHT = 20
ROW_HEIGHT = 13
BODY_PADDING = 6
CORNER_RADIUS = 4

FONT_REGULAR = "DiagramRegular"
FONT_BOLD = "DiagramBold"

# Расположение таблиц на листе: левый верхний угол блока в точках PDF.
TABLE_POSITIONS = {
    "unit": (40, 500),
    "material_type": (40, 390),
    "product_type": (40, 190),
    "material": (300, 500),
    "material_supplier": (300, 250),
    "supplier": (560, 500),
    "supplier_type": (560, 190),
}

# Маршрут линии связи «дочерняя таблица -> родительская таблица».
# start и end — сторона блока и доля её длины, bend — координата излома линии.
RELATION_ROUTES = {
    ("material", "unit"): {
        "start": ("left", 0.65),
        "end": ("right", 0.5),
        "bend": 272,
    },
    ("material", "material_type"): {
        "start": ("left", 0.9),
        "end": ("right", 0.5),
        "bend": 250,
    },
    ("material_supplier", "material"): {
        "start": ("top", 0.5),
        "end": ("bottom", 0.5),
        "bend": 316,
    },
    ("material_supplier", "supplier"): {
        "start": ("right", 0.5),
        "end": ("bottom", 0.25),
    },
    ("supplier", "supplier_type"): {
        "start": ("bottom", 0.75),
        "end": ("top", 0.75),
        "bend": 293,
    },
}

# Смещение подписи кардинальности относительно точки присоединения линии.
LABEL_OFFSETS = {
    "left": (-13, 2),
    "right": (5, 2),
    "top": (4, 3),
    "bottom": (4, -10),
}


def register_fonts():
    """Подключить шрифты с поддержкой кириллицы из системной папки Windows."""
    fonts_dir = Path("C:/Windows/Fonts")
    pdfmetrics.registerFont(TTFont(FONT_REGULAR, fonts_dir / "comic.ttf"))
    pdfmetrics.registerFont(TTFont(FONT_BOLD, fonts_dir / "comicbd.ttf"))


def read_schema(connection):
    """Собрать описание таблиц, ключей и связей из служебных таблиц SQLite."""
    table_names = [
        row[0]
        for row in connection.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
    ]

    tables = {}
    relations = []
    for table_name in table_names:
        foreign_keys = list(connection.execute(f"PRAGMA foreign_key_list({table_name})"))
        foreign_key_columns = {row[3] for row in foreign_keys}
        for row in foreign_keys:
            relations.append((table_name, row[2]))

        tables[table_name] = [
            {
                "name": row[1],
                "primary_key": bool(row[5]),
                "foreign_key": row[1] in foreign_key_columns,
            }
            for row in connection.execute(f"PRAGMA table_info({table_name})")
        ]
    return tables, relations


def draw_table(pdf, table_name, columns, position):
    """Нарисовать блок одной таблицы: заголовок и список атрибутов."""
    left, top = position
    total_height = HEADER_HEIGHT + ROW_HEIGHT * len(columns) + BODY_PADDING

    pdf.setFillColor(BACKGROUND_COLOR)
    pdf.setStrokeColor(ACCENT_COLOR)
    pdf.setLineWidth(1)
    pdf.roundRect(left, top - total_height, BOX_WIDTH, total_height, CORNER_RADIUS, stroke=1, fill=1)

    pdf.setFillColor(ACCENT_COLOR)
    pdf.roundRect(left, top - HEADER_HEIGHT, BOX_WIDTH, HEADER_HEIGHT, CORNER_RADIUS, stroke=0, fill=1)
    pdf.rect(left, top - HEADER_HEIGHT, BOX_WIDTH, CORNER_RADIUS, stroke=0, fill=1)

    pdf.setFillColor(BACKGROUND_COLOR)
    pdf.setFont(FONT_BOLD, 9)
    pdf.drawCentredString(left + BOX_WIDTH / 2, top - HEADER_HEIGHT + 6, table_name)

    text_y = top - HEADER_HEIGHT - ROW_HEIGHT + 3
    for column in columns:
        if column["primary_key"]:
            marker, marker_color = "PK", ACCENT_COLOR
        elif column["foreign_key"]:
            marker, marker_color = "FK", FOREIGN_KEY_COLOR
        else:
            marker, marker_color = "", TEXT_COLOR

        if marker:
            pdf.setFillColor(SECONDARY_COLOR)
            pdf.rect(left + 4, text_y - 2.5, BOX_WIDTH - 8, ROW_HEIGHT - 2, stroke=0, fill=1)
            pdf.setFillColor(marker_color)
            pdf.setFont(FONT_BOLD, 6.5)
            pdf.drawString(left + 6, text_y, marker)

        pdf.setFillColor(TEXT_COLOR)
        pdf.setFont(FONT_BOLD if marker else FONT_REGULAR, 7)
        pdf.drawString(left + 22, text_y, column["name"])
        text_y -= ROW_HEIGHT

    return {
        "left": left,
        "right": left + BOX_WIDTH,
        "top": top,
        "bottom": top - total_height,
        "height": total_height,
    }


def anchor_point(box, side, fraction):
    """Точка присоединения линии к стороне блока."""
    if side == "left":
        return box["left"], box["top"] - box["height"] * fraction
    if side == "right":
        return box["right"], box["top"] - box["height"] * fraction
    if side == "top":
        return box["left"] + BOX_WIDTH * fraction, box["top"]
    return box["left"] + BOX_WIDTH * fraction, box["bottom"]


def build_path(start, start_side, end, end_side, bend):
    """Построить ортогональную ломаную между точками присоединения."""
    horizontal_sides = {"left", "right"}
    start_is_horizontal = start_side in horizontal_sides
    end_is_horizontal = end_side in horizontal_sides

    if start_is_horizontal and end_is_horizontal:
        return [start, (bend, start[1]), (bend, end[1]), end]
    if not start_is_horizontal and not end_is_horizontal:
        return [start, (start[0], bend), (end[0], bend), end]
    # Линия выходит из вертикальной стороны одного блока в горизонтальную другого.
    corner = (end[0], start[1]) if start_is_horizontal else (start[0], end[1])
    return [start, corner, end]


def draw_relation(pdf, child_box, parent_box, route, labels):
    """Соединить две таблицы линией и подписать кардинальность связи."""
    start_side, start_fraction = route["start"]
    end_side, end_fraction = route["end"]
    start = anchor_point(child_box, start_side, start_fraction)
    end = anchor_point(parent_box, end_side, end_fraction)

    points = build_path(start, start_side, end, end_side, route.get("bend"))
    pdf.setStrokeColor(ACCENT_COLOR)
    pdf.setLineWidth(0.9)
    path = pdf.beginPath()
    path.moveTo(*points[0])
    for point in points[1:]:
        path.lineTo(*point)
    pdf.drawPath(path)

    pdf.setFillColor(ACCENT_COLOR)
    pdf.setFont(FONT_BOLD, 9)
    for point, side, label in ((start, start_side, labels[0]), (end, end_side, labels[1])):
        offset_x, offset_y = LABEL_OFFSETS[side]
        pdf.drawString(point[0] + offset_x, point[1] + offset_y, label)


def draw_legend(pdf):
    pdf.setFillColor(TEXT_COLOR)
    pdf.setFont(FONT_REGULAR, 8)
    pdf.drawString(40, 84, "PK — первичный ключ        FK — внешний ключ        1 : ∞ — связь «один ко многим»")
    pdf.drawString(
        40, 68,
        "Таблица material_supplier реализует связь «многие ко многим» между материалами и поставщиками.",
    )
    pdf.drawString(
        40, 52,
        "Таблица product_type хранит коэффициенты типов продукции для расчёта количества продукции из сырья.",
    )


def main():
    register_fonts()
    connection = sqlite3.connect(DATABASE_PATH)
    tables, relations = read_schema(connection)
    connection.close()

    pdf = canvas.Canvas(str(DIAGRAM_PATH), pagesize=PAGE_SIZE)
    pdf.setTitle("ER-диаграмма базы данных «Мозаика»")
    pdf.setAuthor("Производственная компания «Мозаика»")

    pdf.setFillColor(ACCENT_COLOR)
    pdf.setFont(FONT_BOLD, 15)
    pdf.drawString(40, PAGE_SIZE[1] - 42, "ER-диаграмма базы данных «Мозаика»")
    pdf.setFillColor(TEXT_COLOR)
    pdf.setFont(FONT_REGULAR, 8.5)
    pdf.drawString(40, PAGE_SIZE[1] - 58, "Подсистема «Склад и материалы», третья нормальная форма")

    boxes = {
        table_name: draw_table(pdf, table_name, tables[table_name], position)
        for table_name, position in TABLE_POSITIONS.items()
    }
    for child_table, parent_table in relations:
        route = RELATION_ROUTES[(child_table, parent_table)]
        draw_relation(pdf, boxes[child_table], boxes[parent_table], route, ("∞", "1"))

    draw_legend(pdf)
    pdf.showPage()
    pdf.save()
    print(f"ER-диаграмма сохранена: {DIAGRAM_PATH}")


if __name__ == "__main__":
    main()
