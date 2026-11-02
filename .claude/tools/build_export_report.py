"""Собрать отчёт по ПР № 8 (экспорт данных в файлы) в .docx.

Методичка просит текст задания и запрос, который его выполняет, поэтому в отчёте только
они. Запросы читаются из файла решения.

Usage:
    python .claude/tools/build_export_report.py
"""

import re
from pathlib import Path

import report_base as rb

TASK = Path(__file__).resolve().parents[2] / "Task 8th Data Export to Files"
SOLUTION = TASK / "Solution"
SCRIPT = SOLUTION / "8_export.sql"
OUT = SOLUTION / "Отчёт по ПР №8.docx"

TOPIC = "Тема: Экспорт данных базы в документы пользователя"

GOAL = (
    "Научиться выгружать данные таблиц базы данных в файлы пользовательских форматов "
    "средствами MySQL: оператором SELECT с предложением INTO OUTFILE."
)

TASKS = [
    "Произвести экспорт данных таблицы «Заказы» в .xlsx файл.",
    "Произвести экспорт данных таблицы «Заказчики юр.лица» в .txt файл.",
]

NOTES = [
    "Оператор INTO OUTFILE записывает текстовый файл, а не книгу Excel, поэтому выгрузка "
    "выполнена в .csv. Затем файл открыт в Excel и сохранён как .xlsx.",
    "",
]

CONCLUSION = [
    "В работе данные двух таблиц базы torgash_Холкин были выгружены в файлы: заказы в "
    "формат .xlsx через промежуточный .csv, заказчики юр.лица в .txt. Файлы записываются "
    "на стороне сервера и только в каталог, разрешённый параметром secure_file_priv, "
    "кодировка выгрузки задана явно как cp1251, чтобы кириллица открывалась в Excel без "
    "искажений. Оператор не перезаписывает существующий файл, поэтому повторный запуск "
    "возможен только после удаления прежнего.",
]


def read_statements():
    text = SCRIPT.read_text(encoding="utf-8")
    found = re.findall(r"^SELECT \* FROM .*?;$", text, re.M | re.S)
    return [s.strip() for s in found]


def build():
    queries = read_statements()
    if len(queries) != len(TASKS):
        raise SystemExit(f"запросов {len(queries)}, пунктов задания {len(TASKS)}")

    doc = rb.new_document()
    rb.title_page(doc, 8, TOPIC)

    rb.heading(doc, "1", "Цель работы")
    rb.para(doc, GOAL)

    rb.heading(doc, "2", "Задание")
    for i, text in enumerate(TASKS, start=1):
        rb.para(doc, f"{i}. {text}")

    rb.heading(doc, "3", "Ход работы")
    for i, (task, query) in enumerate(zip(TASKS, queries), start=1):
        rb.para(doc, f"{i}. {task}")
        if NOTES[i - 1]:
            rb.blank(doc)
            rb.para(doc, NOTES[i - 1])
        rb.blank(doc)
        rb.code(doc, query)
        rb.blank(doc)

    rb.heading(doc, "4", "Вывод")
    for text in CONCLUSION:
        rb.para(doc, text)

    rb.save(doc, OUT)


if __name__ == "__main__":
    build()
