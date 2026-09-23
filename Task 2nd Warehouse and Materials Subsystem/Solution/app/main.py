"""Точка входа приложения учёта материалов компании «Мозаика».

Запуск: python main.py
"""

import sqlite3
import sys
import tkinter as tk
from tkinter import messagebox

import config
from repository import MaterialRepository
from ui.application import Application
from ui.material_list_page import MaterialListPage


def show_startup_error(message):
    """Сообщить об ошибке запуска, когда основное окно ещё не создано."""
    root = tk.Tk()
    root.withdraw()
    messagebox.showerror("Не удалось запустить приложение", message, parent=root)
    root.destroy()


def main():
    if not config.DATABASE_PATH.exists():
        show_startup_error(
            f"Файл базы данных не найден:\n{config.DATABASE_PATH}\n\n"
            "Выполните скрипт database/build_database.py, чтобы создать базу данных "
            "и загрузить в неё данные заказчика."
        )
        return 1

    try:
        repository = MaterialRepository(config.DATABASE_PATH)
    except sqlite3.Error as error:
        show_startup_error(
            f"База данных недоступна: {error}\n\n"
            "Убедитесь, что файл mosaic.db не открыт другой программой, и повторите запуск."
        )
        return 1

    application = Application(repository)
    application.open_page(MaterialListPage)
    try:
        application.mainloop()
    finally:
        repository.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
