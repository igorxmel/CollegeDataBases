"""Собрать отчёт по ПР № 9 (импорт и экспорт данных) в .docx.

Методичка просит текст задания и запрос, который его выполняет. Запросы читаются из
файлов решения: импорт из 9.1_import.sql, экспорт из 9.2_export.sql.

Usage:
    python .claude/tools/build_import_report.py
"""

import re
from pathlib import Path

import report_base as rb

TASK = Path(__file__).resolve().parents[2] / "Task 9th Data Import and Export"
SOLUTION = TASK / "Solution"
OUT = SOLUTION / "Отчёт по ПР №9.docx"

TOPIC = "Тема: Импорт и экспорт данных пользователя"

GOAL = (
    "Научиться загружать данные из файлов пользователя в таблицы MySQL оператором LOAD "
    "DATA INFILE и выгружать данные таблиц в файлы оператором SELECT с предложением INTO "
    "OUTFILE."
)

TASKS = [
    "Произвести импорт данных из .xlsx файла в таблицу MySQL (таблицу создать "
    "самостоятельно, она должна содержать не менее 5 столбцов с типами данных даты, "
    "числового целого, числового дробного, символьного, содержимое таблицы должно быть на "
    "русском языке).",
    "Произвести импорт данных из .txt файла в таблицу MySQL (таблицу создать "
    "самостоятельно, она должна содержать не менее 5 столбцов с типами данных даты, "
    "числового целого, числового дробного, символьного, содержимое таблицы должно быть на "
    "русском языке).",
    "Произвести экспорт данных таблицы «Заказы» в .xlsx файл.",
    "Произвести экспорт данных таблицы «Заказчики юр.лица» в .txt файл.",
]

NOTES = [
    "Файл .xlsx предварительно сохранён из Excel как .csv. Русский Excel записывает даты "
    "в формате ДД.ММ.ГГГГ и десятичные дроби через запятую, поэтому эти значения "
    "принимаются в переменные и приводятся к формату MySQL в разделе SET.",
    "Файл .txt сохранён из Excel как текст с разделителями табуляции, значения приводятся "
    "к формату MySQL так же, как в первом пункте.",
    "Оператор INTO OUTFILE записывает текстовый файл, поэтому выгрузка выполнена в .csv, "
    "после чего файл открыт в Excel и сохранён как .xlsx.",
    "",
]

CONCLUSION = [
    "В работе были выполнены импорт данных из .xlsx и .txt файлов в две новые таблицы и "
    "экспорт двух существующих таблиц в файлы. Основная трудность импорта состояла в том, "
    "что формат файлов русского Excel не совпадает с форматом MySQL: файл записан в "
    "кодировке cp1251, даты имеют вид ДД.ММ.ГГГГ, а дроби записаны через запятую. Без "
    "указания кодировки и без преобразования значений в разделе SET загрузка завершается "
    "ошибкой.",
]


def split_import(text):
    """Вернуть два блока импорта: от CREATE TABLE до последнего SELECT таблицы."""
    blocks = []
    for table in ("postavki", "vozvraty"):
        m = re.search(
            rf"(CREATE TABLE {table} \(.*?SELECT \* FROM {table};)", text, re.S)
        if not m:
            raise SystemExit(f"в 9.1_import.sql не найден блок для {table}")
        blocks.append(m.group(1).strip())
    return blocks


def split_export(text):
    found = re.findall(r"^SELECT \* FROM .*?;$", text, re.M | re.S)
    return [s.strip() for s in found]


def build():
    imports = split_import((SOLUTION / "9.1_import.sql").read_text(encoding="utf-8"))
    exports = split_export((SOLUTION / "9.2_export.sql").read_text(encoding="utf-8"))
    queries = imports + exports
    if len(queries) != len(TASKS):
        raise SystemExit(f"запросов {len(queries)}, пунктов задания {len(TASKS)}")

    doc = rb.new_document()
    rb.title_page(doc, 9, TOPIC)

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
