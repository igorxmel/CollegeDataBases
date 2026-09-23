"""Форма списка поставщиков выбранного материала (модуль № 4)."""

from datetime import date
import tkinter as tk
from tkinter import ttk

import config
from ui import style
from ui.application import Page

COLUMNS = (
    ("supplier_name", "Наименование поставщика", 320, "w"),
    ("rating", "Рейтинг", 120, "center"),
    ("work_start_date", "Дата начала работы", 200, "center"),
)


def format_date(iso_date):
    """Дата из базы данных (YYYY-MM-DD) в привычном виде ДД.ММ.ГГГГ."""
    return date.fromisoformat(iso_date).strftime("%d.%m.%Y")


class SupplierListPage(Page):
    def __init__(self, app, material_id):
        self.material_id = material_id
        self._material = app.repository.get_material(material_id)
        material_name = self._material["material_name"] if self._material else "—"
        self.window_title = f"{config.APP_TITLE} — поставщики материала"
        self.heading = f"Поставщики материала «{material_name}»"
        super().__init__(app)

    def build(self):
        container = tk.Frame(self, background=config.PRIMARY_BACKGROUND)
        container.pack(fill="both", expand=True, padx=24, pady=20)

        self._summary_label = style.body_label(
            container, "", foreground=config.MUTED_TEXT_COLOR, font=config.FONT_SMALL
        )
        self._summary_label.pack(anchor="w", pady=(0, 10))

        table_frame = tk.Frame(container, background=config.PRIMARY_BACKGROUND)
        table_frame.pack(fill="both", expand=True)

        self._table = ttk.Treeview(
            table_frame,
            columns=[column[0] for column in COLUMNS],
            show="headings",
            style="App.Treeview",
            selectmode="browse",
        )
        for name, title, width, anchor in COLUMNS:
            self._table.heading(name, text=title, anchor=anchor)
            self._table.column(name, width=width, anchor=anchor, stretch=(name == "supplier_name"))

        scrollbar = ttk.Scrollbar(
            table_frame, orient="vertical", command=self._table.yview,
            style="App.Vertical.TScrollbar",
        )
        self._table.configure(yscrollcommand=scrollbar.set)
        self._table.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        self._empty_label = style.body_label(
            container,
            "Для этого материала поставщики в базе данных не указаны.",
            foreground=config.MUTED_TEXT_COLOR,
        )

        style.secondary_button(container, "← Вернуться к списку материалов", self.app.go_back).pack(
            anchor="e", pady=(16, 0)
        )

    def on_show(self):
        for row_id in self._table.get_children():
            self._table.delete(row_id)

        suppliers = self.repository.list_suppliers_for_material(self.material_id)
        for supplier in suppliers:
            self._table.insert(
                "",
                "end",
                values=(
                    supplier["supplier_name"],
                    supplier["rating"],
                    format_date(supplier["work_start_date"]),
                ),
            )

        if suppliers:
            self._empty_label.pack_forget()
        else:
            self._empty_label.pack(anchor="w", pady=(12, 0))

        unit = self._material["unit_name"] if self._material else ""
        self._summary_label.configure(
            text=f"Тип материала: {self._material['material_type_name']}   |   "
                 f"Единица измерения: {unit}   |   "
                 f"Поставщиков: {len(suppliers)}"
            if self._material
            else f"Поставщиков: {len(suppliers)}"
        )
