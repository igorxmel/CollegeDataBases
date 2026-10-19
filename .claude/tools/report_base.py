"""Общая обвязка для сборки отчётов курса в .docx.

Титульный лист, параметры страницы, абзацы, листинги и таблицы вынесены сюда, чтобы
генераторы отдельных работ содержали только текст. Скрипт ПР №5 живёт со своей копией
этих функций, его трогать не нужно: он уже собрал сданный отчёт.
"""

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

FONT = "Times New Roman"
MONO = "Courier New"
SIZE = Pt(14)
CODE_SIZE = Pt(10)
TABLE_SIZE = Pt(12)
INDENT = Cm(1.25)
TEXT_WIDTH = 16.5

LINES_PER_PAGE = 30
GAP_AFTER_HEADER = 3
GAP_BEFORE_SIGN = 4
GAP_BEFORE_CITY = 2

TITLE = [
    "Министерство общего и профессионального образования",
    "Ростовской области",
    "Государственное бюджетное профессиональное образовательное",
    "учреждение Ростовской области",
    "«Ростовский-на-Дону колледж связи и информатики»",
]
SIGN_LEFT = ["Выполнил: студент 4 курса", "группы ИС-42", "Холкин Егор"]
SIGN_RIGHT = ["Проверил: преподаватель", "Кротенко Е. М."]
CITY = "Ростов-на-Дону"
YEAR = "2026"


def new_document():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Cm(21)
    section.page_height = Cm(29.7)
    section.left_margin = Cm(3)
    section.right_margin = Cm(1.5)
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)

    normal = doc.styles["Normal"]
    normal.font.name = FONT
    normal.font.size = SIZE
    normal.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
    pf = normal.paragraph_format
    pf.line_spacing = 1.5
    pf.space_before = Pt(0)
    pf.space_after = Pt(0)
    pf.first_line_indent = INDENT
    pf.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    return doc


def para(doc, text="", *, indent=INDENT, align=WD_ALIGN_PARAGRAPH.JUSTIFY, bold=False):
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = indent
    p.paragraph_format.alignment = align
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    if text:
        run = p.add_run(text)
        run.font.name = FONT
        run.font.size = SIZE
        run.bold = bold
    return p


def code(doc, text):
    for line in text.splitlines():
        p = doc.add_paragraph()
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(line)
        run.font.name = MONO
        run.font.size = CODE_SIZE
        run.element.rPr.rFonts.set(qn("w:eastAsia"), MONO)


def listing(doc, path, caption_text=None):
    para(doc, caption_text or f"Листинг файла {path.name}:", indent=Cm(0))
    code(doc, path.read_text(encoding="utf-8").rstrip())
    blank(doc)


def blank(doc, n=1):
    for _ in range(n):
        para(doc)


def heading(doc, number, title, *, new_page=True):
    if new_page:
        para(doc).add_run().add_break(WD_BREAK.PAGE)
    para(doc, f"{number} {title}", align=WD_ALIGN_PARAGRAPH.LEFT, bold=True)
    blank(doc)


def subheading(doc, number, title):
    para(doc, f"{number} {title}", align=WD_ALIGN_PARAGRAPH.LEFT, bold=True)
    blank(doc)


def caption(doc, text):
    para(doc, text, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER)


def table(doc, header, rows, widths):
    if abs(sum(widths) - TEXT_WIDTH) > 0.05:
        raise SystemExit(f"ширина таблицы {sum(widths):.2f} см вместо {TEXT_WIDTH}")

    t = doc.add_table(rows=1, cols=len(header))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False

    def fill(cells, values, bold):
        for cell, value, width in zip(cells, values, widths):
            cell.width = Cm(width)
            cell.text = ""
            for i, line in enumerate(str(value).split("\n")):
                p = cell.paragraphs[0] if i == 0 else cell.add_paragraph()
                p.paragraph_format.first_line_indent = Cm(0)
                p.paragraph_format.line_spacing = 1.0
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(0)
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER if bold else WD_ALIGN_PARAGRAPH.LEFT
                run = p.add_run(line)
                run.font.name = FONT
                run.font.size = TABLE_SIZE
                run.bold = bold

    fill(t.rows[0].cells, header, True)
    for row in rows:
        fill(t.add_row().cells, row, False)
    return t


def title_page(doc, number, topic):
    lines = 0
    for line in TITLE:
        para(doc, line, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER)
    lines += len(TITLE)

    blank(doc, GAP_AFTER_HEADER)
    lines += GAP_AFTER_HEADER

    para(doc, "ОТЧЁТ", indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER, bold=True)
    para(doc, f"по практической работе № {number}", indent=Cm(0),
         align=WD_ALIGN_PARAGRAPH.CENTER, bold=True)
    blank(doc)
    para(doc, topic, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER)
    lines += 2 + 1 + max(1, -(-len(topic) // 67))

    blank(doc, GAP_BEFORE_SIGN)
    lines += GAP_BEFORE_SIGN

    for line in SIGN_LEFT:
        para(doc, line, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.RIGHT)
    blank(doc)
    for line in SIGN_RIGHT:
        para(doc, line, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.RIGHT)
    lines += len(SIGN_LEFT) + 1 + len(SIGN_RIGHT)

    blank(doc, GAP_BEFORE_CITY)
    lines += GAP_BEFORE_CITY

    para(doc, CITY, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER)
    para(doc, YEAR, indent=Cm(0), align=WD_ALIGN_PARAGRAPH.CENTER)
    lines += 2

    if lines > LINES_PER_PAGE:
        raise SystemExit(f"титульный лист занял {lines} строк при лимите {LINES_PER_PAGE}")


def save(doc, path):
    try:
        doc.save(path)
    except PermissionError:
        raise SystemExit(f"{path.name} открыт в Word, закрой его и повтори")
    print(f"saved: {path.name}")
