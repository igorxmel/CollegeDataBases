"""Собрать входные файлы для импорта в ПР № 9: postavki.xlsx, postavki.csv, vozvraty.txt.

Файлы делаются так же, как их делал бы человек в Excel. Таблица с поставками собирается
в .xlsx, потом настоящий Excel выполняет «Сохранить как CSV». Таблица с возвратами
сохраняется как «Текстовый файл (с разделителями табуляции)». Поэтому в файлах всё как у
русского Excel: кодировка cp1251, разделитель столбцов, десятичная запятая, даты ДД.ММ.ГГГГ.

Результат кладётся в exchange/, эту папку Docker подключает как каталог, из которого MySQL
разрешает читать и писать файлы (secure_file_priv).

Usage:
    python .claude/tools/build_import_data.py
"""

import sys
import tempfile
from datetime import date
from pathlib import Path

import win32com.client
from openpyxl import Workbook
from openpyxl.styles import Font

ROOT = Path(__file__).resolve().parents[2]
EXCHANGE = ROOT / "exchange"

XL_CSV = 6
XL_TEXT_TABS = -4158

POSTAVKI_HEADER = ["Дата поставки", "Поставщик", "Категория", "Количество", "Закупочная цена"]
POSTAVKI = [
    (date(2026, 9, 1),  "Южный опт",       "Беговые",       40, 8450.50),
    (date(2026, 9, 3),  "СпортСнаб",       "Повседневные",  60, 5120.00),
    (date(2026, 9, 8),  "Донская обувь",   "Баскетбольные", 18, 11980.00),
    (date(2026, 9, 15), "Южный опт",       "Повседневные",  45, 5340.25),
    (date(2026, 9, 17), "Альфа Трейд",     "Беговые",       32, 8790.00),
    (date(2026, 9, 24), "СпортСнаб",       "Беговые",       50, 8260.75),
    (date(2026, 10, 2), "Донская обувь",   "Повседневные",  70, 4980.00),
    (date(2026, 10, 6), "Альфа Трейд",     "Баскетбольные", 22, 12150.50),
    (date(2026, 10, 13), "Южный опт",      "Беговые",       28, 8610.00),
    (date(2026, 10, 20), "СпортСнаб",      "Баскетбольные", 16, 11700.00),
]

VOZVRATY_HEADER = ["Дата возврата", "Магазин", "Причина", "Количество", "Сумма возврата"]
VOZVRATY = [
    (date(2026, 9, 2),  "ТЦ Горизонт",        "не подошёл размер",     1, 8990.00),
    (date(2026, 9, 5),  "Магазин на проспекте", "заводской брак",       1, 12490.50),
    (date(2026, 9, 9),  "ТЦ Мега Юг",         "не понравился цвет",    2, 15980.00),
    (date(2026, 9, 14), "ТЦ Горизонт",        "не подошёл размер",     1, 7490.00),
    (date(2026, 9, 21), "ТЦ Мега Юг",         "повреждена коробка",    1, 9990.25),
    (date(2026, 9, 27), "Магазин на проспекте", "передумал покупатель", 1, 6590.00),
    (date(2026, 10, 3), "ТЦ Горизонт",        "заводской брак",        1, 13200.00),
    (date(2026, 10, 8), "ТЦ Мега Юг",         "не подошёл размер",     3, 25470.75),
    (date(2026, 10, 15), "Магазин на проспекте", "не понравился цвет",  1, 8190.00),
    (date(2026, 10, 22), "ТЦ Горизонт",       "передумал покупатель",  2, 17980.00),
]


def make_workbook(path, header, rows):
    wb = Workbook()
    ws = wb.active
    ws.append(header)
    for cell in ws[1]:
        cell.font = Font(bold=True)
    for row in rows:
        ws.append(list(row))
    # формат ячеек задаёт то, как значение попадёт в CSV: Excel пишет показанное
    for r in range(2, len(rows) + 2):
        ws.cell(r, 1).number_format = "DD.MM.YYYY"
        ws.cell(r, 5).number_format = "0.00"
    for col, width in zip("ABCDE", (16, 22, 24, 12, 18)):
        ws.column_dimensions[col].width = width
    wb.save(path)


def excel_save(source, target, file_format):
    # DispatchEx поднимает отдельный процесс и не трогает Excel, уже открытый пользователем
    xl = win32com.client.DispatchEx("Excel.Application")
    xl.Visible = False
    xl.DisplayAlerts = False
    try:
        wb = xl.Workbooks.Open(str(source))
        wb.SaveAs(str(target), FileFormat=file_format)
        wb.Close(False)
    finally:
        xl.Quit()


def main():
    EXCHANGE.mkdir(exist_ok=True)

    xlsx = EXCHANGE / "postavki.xlsx"
    make_workbook(xlsx, POSTAVKI_HEADER, POSTAVKI)
    excel_save(xlsx, EXCHANGE / "postavki.csv", XL_CSV)
    print("готово: postavki.xlsx, postavki.csv")

    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "vozvraty.xlsx"
        make_workbook(src, VOZVRATY_HEADER, VOZVRATY)
        excel_save(src, EXCHANGE / "vozvraty.txt", XL_TEXT_TABS)
    print("готово: vozvraty.txt")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
