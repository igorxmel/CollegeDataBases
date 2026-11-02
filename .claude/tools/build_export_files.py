"""Собрать готовые файлы экспорта для ПР № 8 и ПР № 9 из того, что выгрузил MySQL.

SELECT ... INTO OUTFILE пишет текст, а не книгу Excel. Поэтому выгрузка заказов
получается в zakazy.csv, и дальше человек открывает её в Excel и сохраняет как .xlsx.
Этот скрипт повторяет шаг с Excel: читает zakazy.csv так же, как его прочитал бы Excel
(cp1251, разделитель «;», кавычки), приводит значения к настоящим числам и датам и пишет
zakazy.xlsx. Метка \\N, которой MySQL помечает NULL, превращается в пустую ячейку.

Таблица заказчиков юр.лиц сразу выгружается в .txt, её достаточно скопировать.

Готовые файлы кладутся в Solution обеих работ, потому что каждая работа сдаётся отдельно.

Usage:
    python .claude/tools/build_export_files.py
"""

import csv
import shutil
import sys
from datetime import date
from pathlib import Path

from openpyxl import Workbook

ROOT = Path(__file__).resolve().parents[2]
EXCHANGE = ROOT / "exchange"
TARGETS = [
    ROOT / "Task 8th Data Export to Files" / "Solution",
    ROOT / "Task 9th Data Import and Export" / "Solution",
]

NULL_MARK = chr(92) + "N"

# Порядок и типы столбцов таблицы orders: id_z, amt, dostavka, odate, id_s, id_cf, id_cy
ORDERS_TYPES = ["int", "money", "money", "date", "int", "int", "int"]


def convert(value, kind):
    if value == NULL_MARK:
        return None
    if kind == "int":
        return int(value)
    if kind == "money":
        return float(value)
    if kind == "date":
        return date.fromisoformat(value)
    return value


def orders_to_xlsx(source, target):
    wb = Workbook()
    ws = wb.active
    ws.title = "Заказы"
    with open(source, encoding="cp1251", newline="") as f:
        for row in csv.reader(f, delimiter=";", quotechar='"'):
            ws.append([convert(v, k) for v, k in zip(row, ORDERS_TYPES)])
    for r in range(1, ws.max_row + 1):
        ws.cell(r, 2).number_format = "0.00"
        ws.cell(r, 3).number_format = "0.00"
        ws.cell(r, 4).number_format = "DD.MM.YYYY"
    for col, width in zip("ABCDEFG", (8, 12, 12, 14, 8, 8, 8)):
        ws.column_dimensions[col].width = width
    wb.save(target)
    return ws.max_row


def main():
    csv_path = EXCHANGE / "zakazy.csv"
    txt_path = EXCHANGE / "zakazchiki_yur.txt"
    for p in (csv_path, txt_path):
        if not p.exists():
            raise SystemExit(f"нет {p.name}: сначала выполни экспорт (8_export.sql)")

    for folder in TARGETS:
        rows = orders_to_xlsx(csv_path, folder / "zakazy.xlsx")
        shutil.copyfile(txt_path, folder / "zakazchiki_yur.txt")
        print(f"{folder.parent.name}: zakazy.xlsx ({rows} строк), zakazchiki_yur.txt")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
