"""Построение ER-диаграммы базы данных «Мозаика» в формате PDF.

Структура таблиц, полей и связей не задаётся вручную, а читается из готовой
базы данных mosaic.db через служебные таблицы SQLite (PRAGMA table_info и
PRAGMA foreign_key_list), поэтому диаграмма всегда соответствует схеме.
Вручную задаётся только распределение таблиц по колонкам и подсистемам:
координаты блоков и линии связей рассчитываются автоматически.

Запуск: python make_er_diagram.py
"""

from pathlib import Path
import sqlite3

from reportlab.lib.colors import HexColor
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
RELATION_COLOR = HexColor("#8A9BB0")

BOX_WIDTH = 180
HEADER_HEIGHT = 20
ROW_HEIGHT = 13
BODY_PADDING = 6
CORNER_RADIUS = 4

LEFT_MARGIN = 45
COLUMN_GAP = 42
BOX_GAP = 24
# Размер листа подбирается под содержимое: сверху остаётся место для заголовка
# и подписей подсистем, снизу — для легенды.
TOP_AREA = 130
BOTTOM_AREA = 122

FONT_REGULAR = "DiagramRegular"
FONT_BOLD = "DiagramBold"

# Распределение таблиц по колонкам: внутри колонки блоки ставятся стопкой
# сверху вниз, связанные таблицы собраны рядом, чтобы линии были короткими.
COLUMNS = [
    ["unit", "material_type", "organization_type", "supplier"],
    ["material", "material_supplier", "stock_movement"],
    ["product_type", "product", "product_material", "production_batch"],
    ["job_position", "employee"],
    ["partner", "partner_sale"],
    ["request_status", "request", "request_item"],
]

# Подсистемы предметной области: подпись и номера колонок, которые она занимает.
SUBSYSTEMS = [
    ("Склад и материалы (п.7–9)", [0, 1]),
    ("Продукция и производство (п.8, п.10)", [2]),
    ("Сотрудники (п.4–5)", [3]),
    ("Партнёры (п.1–2)", [4]),
    ("Заявки (п.3)", [5]),
]


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


def box_height(columns):
    return HEADER_HEIGHT + ROW_HEIGHT * len(columns) + BODY_PADDING


def page_width():
    return 2 * LEFT_MARGIN + len(COLUMNS) * BOX_WIDTH + (len(COLUMNS) - 1) * COLUMN_GAP


def layout_boxes(tables):
    """Разложить таблицы по колонкам и вернуть геометрию блоков и размер листа.

    Блоки сначала расставляются по глубине от верхнего края, затем, когда
    известна высота самой длинной колонки, координаты переводятся в систему
    PDF, где ось Y направлена вверх от нижнего края листа.
    """
    placed = {}
    max_depth = 0
    for column_index, column_tables in enumerate(COLUMNS):
        left = LEFT_MARGIN + column_index * (BOX_WIDTH + COLUMN_GAP)
        depth = 0
        for table_name in column_tables:
            height = box_height(tables[table_name])
            placed[table_name] = (left, depth, height, column_index)
            depth += height + BOX_GAP
        max_depth = max(max_depth, depth - BOX_GAP)

    height_of_page = TOP_AREA + max_depth + BOTTOM_AREA
    top_y = height_of_page - TOP_AREA

    boxes = {}
    for table_name, (left, depth, height, column_index) in placed.items():
        top = top_y - depth
        boxes[table_name] = {
            "left": left,
            "right": left + BOX_WIDTH,
            "top": top,
            "bottom": top - height,
            "height": height,
            "center_x": left + BOX_WIDTH / 2,
            "center_y": top - height / 2,
            "column": column_index,
        }
    return boxes, (page_width(), height_of_page), top_y


def draw_subsystem_zones(pdf, boxes, top_y):
    """Подсветить зоны подсистем предметной области и подписать их."""
    for title, column_indexes in SUBSYSTEMS:
        zone_tables = [
            name for name, box in boxes.items() if box["column"] in column_indexes
        ]
        left = min(boxes[name]["left"] for name in zone_tables) - 14
        right = max(boxes[name]["right"] for name in zone_tables) + 14
        bottom = min(boxes[name]["bottom"] for name in zone_tables) - 16

        pdf.setFillColor(SECONDARY_COLOR)
        pdf.setFillAlpha(0.22)
        pdf.roundRect(left, bottom, right - left, top_y + 26 - bottom, 8, stroke=0, fill=1)
        pdf.setFillAlpha(1)

        pdf.setFillColor(ACCENT_COLOR)
        pdf.setFont(FONT_BOLD, 10)
        pdf.drawString(left + 10, top_y + 32, title)


def draw_table(pdf, table_name, columns, box):
    """Нарисовать блок одной таблицы: заголовок и список атрибутов."""
    left, top = box["left"], box["top"]
    total_height = box["height"]

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


def boundary_point(box, direction_x, direction_y):
    """Точка на границе блока по лучу из его центра в заданном направлении."""
    half_width = BOX_WIDTH / 2
    half_height = box["height"] / 2

    scale_x = half_width / abs(direction_x) if direction_x else float("inf")
    scale_y = half_height / abs(direction_y) if direction_y else float("inf")
    scale = min(scale_x, scale_y)
    return box["center_x"] + direction_x * scale, box["center_y"] + direction_y * scale


def relation_endpoints(child_box, parent_box):
    """Отрезок между границами двух блоков по линии их центров."""
    direction_x = parent_box["center_x"] - child_box["center_x"]
    direction_y = parent_box["center_y"] - child_box["center_y"]
    if not direction_x and not direction_y:
        return None

    start = boundary_point(child_box, direction_x, direction_y)
    end = boundary_point(parent_box, -direction_x, -direction_y)
    return start, end


def draw_relation_line(pdf, start, end):
    pdf.setStrokeColor(RELATION_COLOR)
    pdf.setLineWidth(0.9)
    pdf.line(start[0], start[1], end[0], end[1])


def draw_cardinality(pdf, start, end):
    """Подписать концы связи: «∞» у дочерней таблицы, «1» у родительской."""
    length = ((end[0] - start[0]) ** 2 + (end[1] - start[1]) ** 2) ** 0.5
    if not length:
        return
    step_x = (end[0] - start[0]) / length
    step_y = (end[1] - start[1]) / length

    pdf.setFillColor(ACCENT_COLOR)
    pdf.setFont(FONT_BOLD, 9)
    # Подпись сдвинута вдоль линии внутрь и немного вбок, чтобы не лежать на ней.
    pdf.drawCentredString(start[0] + step_x * 12 - step_y * 5,
                          start[1] + step_y * 12 + step_x * 5 - 3, "∞")
    pdf.drawCentredString(end[0] - step_x * 12 - step_y * 5,
                          end[1] - step_y * 12 + step_x * 5 - 3, "1")


def draw_legend(pdf, table_count, relation_count):
    pdf.setFillColor(TEXT_COLOR)
    pdf.setFont(FONT_REGULAR, 9)
    lines = [
        "PK — первичный ключ        FK — внешний ключ        1 : ∞ — связь «один ко многим»",
        f"Всего таблиц: {table_count}, связей по внешним ключам: {relation_count}. "
        "Схема охватывает все подсистемы описания предметной области (Приложение 1).",
        "Таблицы material_supplier и product_material реализуют связи «многие ко многим».",
        "Подсистема «Склад и материалы» заполнена данными заказчика из файлов с пометкой import.",
    ]
    text_y = 92
    for line in lines:
        pdf.drawString(LEFT_MARGIN, text_y, line)
        text_y -= 16


def main():
    register_fonts()
    connection = sqlite3.connect(DATABASE_PATH)
    tables, relations = read_schema(connection)
    connection.close()

    missing = set(tables) - {name for column in COLUMNS for name in column}
    if missing:
        raise ValueError("Таблицы не размещены на диаграмме: " + ", ".join(sorted(missing)))

    boxes, page_size, top_y = layout_boxes(tables)
    page_height = page_size[1]

    pdf = canvas.Canvas(str(DIAGRAM_PATH), pagesize=page_size)
    pdf.setTitle("ER-диаграмма базы данных «Мозаика»")
    pdf.setAuthor("Производственная компания «Мозаика»")

    pdf.setFillColor(ACCENT_COLOR)
    pdf.setFont(FONT_BOLD, 18)
    pdf.drawString(LEFT_MARGIN, page_height - 52, "ER-диаграмма базы данных «Мозаика»")
    pdf.setFillColor(TEXT_COLOR)
    pdf.setFont(FONT_REGULAR, 10)
    pdf.drawString(LEFT_MARGIN, page_height - 72,
                   "Производственная компания «Мозаика», третья нормальная форма, СУБД SQLite")

    draw_subsystem_zones(pdf, boxes, top_y)

    # Линии рисуются до блоков: блоки непрозрачные и перекрывают те линии,
    # которые проходят под ними, поэтому диаграмма остаётся читаемой.
    endpoints = []
    for child_table, parent_table in relations:
        segment = relation_endpoints(boxes[child_table], boxes[parent_table])
        if segment is None:
            continue
        draw_relation_line(pdf, *segment)
        endpoints.append(segment)

    for table_name, box in boxes.items():
        draw_table(pdf, table_name, tables[table_name], box)

    for start, end in endpoints:
        draw_cardinality(pdf, start, end)

    draw_legend(pdf, len(tables), len(relations))
    pdf.showPage()
    pdf.save()
    print(f"ER-диаграмма сохранена: {DIAGRAM_PATH}")
    print(f"  таблиц: {len(tables)}, связей: {len(relations)}")


if __name__ == "__main__":
    main()
