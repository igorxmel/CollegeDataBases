"""Главная форма: список материалов со стоимостью минимальной партии."""

import tkinter as tk
from tkinter import ttk

import calculations
import config
from ui import style
from ui.application import Page
from ui.material_form_page import MaterialFormPage
from ui.supplier_list_page import SupplierListPage


class MaterialListPage(Page):
    window_title = f"{config.APP_TITLE} — список материалов"
    heading = "Материалы на складе"
    show_logo = True

    def build(self):
        self._build_toolbar()
        self._build_scrollable_area()

    def _build_toolbar(self):
        toolbar = tk.Frame(self, background=config.PRIMARY_BACKGROUND)
        toolbar.pack(fill="x", padx=20, pady=(16, 8))

        style.accent_button(toolbar, "Добавить материал", self._open_add_form).pack(side="left")
        self._summary_label = style.body_label(toolbar, "", foreground=config.MUTED_TEXT_COLOR)
        self._summary_label.pack(side="right")

    def _build_scrollable_area(self):
        area = tk.Frame(self, background=config.PRIMARY_BACKGROUND)
        area.pack(fill="both", expand=True, padx=20, pady=(0, 16))

        self._canvas = tk.Canvas(
            area,
            background=config.PRIMARY_BACKGROUND,
            highlightthickness=0,
        )
        scrollbar = ttk.Scrollbar(
            area,
            orient="vertical",
            command=self._canvas.yview,
            style="App.Vertical.TScrollbar",
        )
        self._canvas.configure(yscrollcommand=scrollbar.set)
        self._canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        self._cards_frame = tk.Frame(self._canvas, background=config.PRIMARY_BACKGROUND)
        self._cards_window = self._canvas.create_window(
            (0, 0), window=self._cards_frame, anchor="nw"
        )
        self._cards_frame.bind(
            "<Configure>",
            lambda event: self._canvas.configure(scrollregion=self._canvas.bbox("all")),
        )
        self._canvas.bind(
            "<Configure>",
            lambda event: self._canvas.itemconfigure(self._cards_window, width=event.width),
        )
        # Колесо мыши работает, пока указатель находится над списком материалов.
        self._canvas.bind("<Enter>", lambda event: self._canvas.bind_all("<MouseWheel>", self._on_mouse_wheel))
        self._canvas.bind("<Leave>", lambda event: self._canvas.unbind_all("<MouseWheel>"))

    def _on_mouse_wheel(self, event):
        self._canvas.yview_scroll(-event.delta // 120, "units")

    # ------------------------------------------------------------------ данные

    def on_show(self):
        self.refresh()

    def refresh(self):
        for card in self._cards_frame.winfo_children():
            card.destroy()

        materials = self.repository.list_materials()
        for material in materials:
            self._build_card(material)

        below_minimum = sum(
            1 for material in materials
            if material["stock_quantity"] < material["min_quantity"]
        )
        self._summary_label.configure(
            text=f"Всего материалов: {len(materials)}   |   "
                 f"Требуется закупка: {below_minimum}"
        )
        self._canvas.yview_moveto(0)

    def _build_card(self, material):
        card = tk.Frame(
            self._cards_frame,
            background=config.PRIMARY_BACKGROUND,
            highlightbackground=config.BORDER_COLOR,
            highlightcolor=config.BORDER_COLOR,
            highlightthickness=1,
            cursor="hand2",
        )
        card.pack(fill="x", pady=6, padx=2)
        card.columnconfigure(0, weight=1)

        details = tk.Frame(card, background=config.PRIMARY_BACKGROUND)
        details.grid(row=0, column=0, sticky="w", padx=18, pady=14)

        unit = material["unit_name"]
        lines = [
            (
                f"{material['material_type_name']} | {material['material_name']}",
                config.FONT_CARD_TITLE,
            ),
            (
                f"Минимальное количество: "
                f"{calculations.format_quantity(material['min_quantity'])} {unit}",
                config.FONT_BODY,
            ),
            (
                f"Количество на складе: "
                f"{calculations.format_quantity(material['stock_quantity'])} {unit}",
                config.FONT_BODY,
            ),
            (
                f"Цена: {calculations.format_money(material['unit_price'])} / "
                f"Единица измерения: {unit}",
                config.FONT_BODY,
            ),
        ]
        for text, font in lines:
            style.body_label(details, text, font=font).pack(anchor="w")

        actions = tk.Frame(card, background=config.PRIMARY_BACKGROUND)
        actions.grid(row=0, column=1, sticky="e", padx=18, pady=14)

        batch_cost = calculations.calculate_batch_cost(
            material["stock_quantity"],
            material["min_quantity"],
            material["package_quantity"],
            material["unit_price"],
        )
        style.body_label(
            actions,
            f"Стоимость партии: {calculations.format_money(batch_cost)}",
            font=config.FONT_CARD_TITLE,
        ).pack(anchor="e")
        style.secondary_button(
            actions,
            "Поставщики материала",
            lambda material_id=material["material_id"]: self._open_suppliers(material_id),
        ).pack(anchor="e", pady=(10, 0))

        self._bind_card_click(card, material["material_id"])

    def _bind_card_click(self, card, material_id):
        """Нажатие на карточку открывает форму редактирования материала."""
        def open_edit_form(event):
            self._open_edit_form(material_id)

        card.bind("<Button-1>", open_edit_form)
        for widget in self._iterate_children(card):
            if isinstance(widget, tk.Button):
                continue
            widget.configure(cursor="hand2")
            widget.bind("<Button-1>", open_edit_form)

    def _iterate_children(self, widget):
        for child in widget.winfo_children():
            yield child
            yield from self._iterate_children(child)

    # --------------------------------------------------------------- переходы

    def _open_add_form(self):
        self.app.open_page(MaterialFormPage, material_id=None)

    def _open_edit_form(self, material_id):
        self.app.open_page(MaterialFormPage, material_id=material_id)

    def _open_suppliers(self, material_id):
        self.app.open_page(SupplierListPage, material_id=material_id)
