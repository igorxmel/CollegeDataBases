"""Форма добавления и редактирования материала."""

from decimal import Decimal, InvalidOperation
import tkinter as tk
from tkinter import messagebox, ttk

import calculations
import config
from repository import DuplicateMaterialError
from ui import style
from ui.application import Page


class ValidationError(Exception):
    """Пользователь ввёл значение, которое нельзя сохранить в базу данных."""

    def __init__(self, message, widget=None):
        super().__init__(message)
        self.message = message
        self.widget = widget


def parse_number(text, field_name, widget, minimum=None, positive=False, max_decimals=None):
    """Разобрать введённое число, допуская запятую в роли десятичного разделителя."""
    text = text.strip().replace(" ", "").replace(",", ".")
    if not text:
        raise ValidationError(f"Поле «{field_name}» не заполнено. Введите числовое значение.", widget)
    try:
        value = Decimal(text)
    except InvalidOperation:
        raise ValidationError(
            f"Поле «{field_name}» содержит недопустимое значение: «{text}».\n"
            "Введите число, например 12,5. Буквы и лишние символы не допускаются.",
            widget,
        ) from None
    if not value.is_finite():
        raise ValidationError(f"Поле «{field_name}» содержит недопустимое число.", widget)
    if positive and value <= 0:
        raise ValidationError(
            f"Поле «{field_name}» должно быть больше нуля. Сейчас указано: {text}.", widget
        )
    if minimum is not None and value < minimum:
        raise ValidationError(
            f"Поле «{field_name}» не может быть меньше {minimum}. Сейчас указано: {text}.\n"
            "Отрицательные значения недопустимы.",
            widget,
        )
    if max_decimals is not None and -value.as_tuple().exponent > max_decimals:
        raise ValidationError(
            f"Поле «{field_name}» может содержать не более {max_decimals} знаков после запятой.\n"
            f"Округлите значение, например до {value:.{max_decimals}f}.",
            widget,
        )
    return float(value)


class MaterialFormPage(Page):
    def __init__(self, app, material_id=None):
        self.material_id = material_id
        self.is_edit_mode = material_id is not None
        self.window_title = (
            f"{config.APP_TITLE} — редактирование материала"
            if self.is_edit_mode
            else f"{config.APP_TITLE} — добавление материала"
        )
        self.heading = "Редактирование материала" if self.is_edit_mode else "Новый материал"
        super().__init__(app)

    # ---------------------------------------------------------------- виджеты

    def build(self):
        self._material_types = self.repository.list_material_types()
        self._type_names = [row["material_type_name"] for row in self._material_types]

        form = tk.Frame(self, background=config.PRIMARY_BACKGROUND)
        form.pack(fill="both", expand=True, padx=32, pady=24)
        form.columnconfigure(1, weight=1)

        self._name_variable = tk.StringVar()
        self._type_variable = tk.StringVar()
        self._stock_variable = tk.StringVar()
        self._unit_variable = tk.StringVar()
        self._package_variable = tk.StringVar()
        self._minimum_variable = tk.StringVar()
        self._price_variable = tk.StringVar()

        self._name_entry = self._add_entry_row(
            form, 0, "Наименование", self._name_variable,
            "Например: Глина. Наименование должно быть уникальным.",
        )
        self._type_combobox = self._add_combobox_row(
            form, 1, "Тип материала", self._type_variable, self._type_names, readonly=True,
            hint="Выберите тип из справочника типов материалов.",
        )
        self._stock_entry = self._add_entry_row(
            form, 2, "Количество на складе", self._stock_variable,
            "Текущий остаток на складе, не может быть отрицательным.",
        )
        self._unit_combobox = self._add_combobox_row(
            form, 3, "Единица измерения", self._unit_variable, self.repository.list_units(),
            readonly=False, hint="Выберите из списка или введите новую единицу, например: кг, л.",
        )
        self._package_entry = self._add_entry_row(
            form, 4, "Количество в упаковке", self._package_variable,
            "Материалы закупаются упаковками, значение должно быть больше нуля.",
        )
        self._minimum_entry = self._add_entry_row(
            form, 5, "Минимальное количество", self._minimum_variable,
            "Минимально допустимый остаток на складе, не может быть отрицательным.",
        )
        self._price_entry = self._add_entry_row(
            form, 6, "Цена единицы материала", self._price_variable,
            "Цена в рублях, не более двух знаков после запятой, например 15,29.",
        )

        self._build_buttons(form, row=7)
        self._initial_state = self._current_state()

    def _add_entry_row(self, form, row, title, variable, hint):
        style.body_label(form, f"{title}:", font=config.FONT_HEADING).grid(
            row=row * 2, column=0, sticky="w", pady=(8, 0)
        )
        widget = style.entry(form, variable)
        widget.grid(row=row * 2, column=1, sticky="ew", padx=(16, 0), pady=(8, 0), ipady=3)
        style.body_label(
            form, hint, font=config.FONT_SMALL, foreground=config.MUTED_TEXT_COLOR
        ).grid(row=row * 2 + 1, column=1, sticky="w", padx=(16, 0))
        return widget

    def _add_combobox_row(self, form, row, title, variable, values, readonly, hint):
        style.body_label(form, f"{title}:", font=config.FONT_HEADING).grid(
            row=row * 2, column=0, sticky="w", pady=(8, 0)
        )
        widget = ttk.Combobox(
            form,
            textvariable=variable,
            values=values,
            state="readonly" if readonly else "normal",
            font=config.FONT_BODY,
            style="App.TCombobox",
        )
        widget.grid(row=row * 2, column=1, sticky="ew", padx=(16, 0), pady=(8, 0))
        style.body_label(
            form, hint, font=config.FONT_SMALL, foreground=config.MUTED_TEXT_COLOR
        ).grid(row=row * 2 + 1, column=1, sticky="w", padx=(16, 0))
        return widget

    def _build_buttons(self, form, row):
        buttons = tk.Frame(form, background=config.PRIMARY_BACKGROUND)
        buttons.grid(row=row * 2, column=0, columnspan=2, sticky="e", pady=(28, 0))
        style.secondary_button(buttons, "Отмена", self.app.go_back).pack(side="left", padx=(0, 12))
        style.accent_button(buttons, "Сохранить", self._save).pack(side="left")

    # ---------------------------------------------------------------- данные

    def on_show(self):
        if self.is_edit_mode:
            self._load_material()
        else:
            self._type_variable.set(self._type_names[0] if self._type_names else "")
        self._initial_state = self._current_state()
        self._name_entry.focus_set()

    def _load_material(self):
        """Подгрузить в поля формы значения выбранного материала из базы данных."""
        material = self.repository.get_material(self.material_id)
        if material is None:
            messagebox.showerror(
                "Материал не найден",
                "Выбранный материал отсутствует в базе данных: возможно, он был удалён.\n\n"
                "Вернитесь к списку материалов и обновите его.",
                parent=self.app,
            )
            self.app.go_back()
            return

        self._name_variable.set(material["material_name"])
        self._type_variable.set(material["material_type_name"])
        self._unit_variable.set(material["unit_name"])
        self._stock_variable.set(calculations.format_quantity(material["stock_quantity"]))
        self._package_variable.set(calculations.format_quantity(material["package_quantity"]))
        self._minimum_variable.set(calculations.format_quantity(material["min_quantity"]))
        self._price_variable.set(f"{float(material['unit_price']):.2f}".replace(".", ","))

    def _current_state(self):
        return (
            self._name_variable.get(),
            self._type_variable.get(),
            self._stock_variable.get(),
            self._unit_variable.get(),
            self._package_variable.get(),
            self._minimum_variable.get(),
            self._price_variable.get(),
        )

    def confirm_leave(self):
        """Предупредить о потере введённых данных при выходе с формы."""
        if self._current_state() == self._initial_state:
            return True
        return messagebox.askyesno(
            "Несохранённые изменения",
            "Данные материала изменены, но не сохранены.\n\n"
            "Выйти с формы и отменить изменения?",
            icon="warning",
            parent=self.app,
        )

    def _collect_values(self):
        """Проверить введённые данные и собрать их для записи в базу данных."""
        material_name = self._name_variable.get().strip()
        if not material_name:
            raise ValidationError(
                "Поле «Наименование» не заполнено.\nВведите наименование материала, например «Глина».",
                self._name_entry,
            )
        if len(material_name) > 100:
            raise ValidationError(
                "Наименование материала не должно быть длиннее 100 символов.\n"
                f"Сейчас введено символов: {len(material_name)}.",
                self._name_entry,
            )

        type_name = self._type_variable.get()
        material_type = next(
            (row for row in self._material_types if row["material_type_name"] == type_name), None
        )
        if material_type is None:
            raise ValidationError(
                "Тип материала не выбран.\nВыберите значение из выпадающего списка «Тип материала».",
                self._type_combobox,
            )

        unit_name = self._unit_variable.get().strip()
        if not unit_name:
            raise ValidationError(
                "Поле «Единица измерения» не заполнено.\n"
                "Выберите единицу измерения из списка или введите свою, например «кг».",
                self._unit_combobox,
            )

        return {
            "material_name": material_name,
            "material_type_id": material_type["material_type_id"],
            "unit_name": unit_name,
            "stock_quantity": parse_number(
                self._stock_variable.get(), "Количество на складе", self._stock_entry, minimum=0
            ),
            "package_quantity": parse_number(
                self._package_variable.get(), "Количество в упаковке", self._package_entry,
                positive=True,
            ),
            "min_quantity": parse_number(
                self._minimum_variable.get(), "Минимальное количество", self._minimum_entry,
                minimum=0,
            ),
            "unit_price": parse_number(
                self._price_variable.get(), "Цена единицы материала", self._price_entry,
                minimum=0, max_decimals=2,
            ),
        }

    def _save(self):
        try:
            values = self._collect_values()
        except ValidationError as error:
            messagebox.showwarning("Проверьте введённые данные", error.message, parent=self.app)
            if error.widget is not None:
                error.widget.focus_set()
            return

        try:
            if self.is_edit_mode:
                self.repository.update_material(self.material_id, values)
                message = f"Данные материала «{values['material_name']}» сохранены."
            else:
                self.repository.add_material(values)
                message = f"Материал «{values['material_name']}» добавлен в базу данных."
        except DuplicateMaterialError:
            messagebox.showerror(
                "Материал уже существует",
                f"Материал с наименованием «{values['material_name']}» уже есть в базе данных.\n\n"
                "Укажите другое наименование или отредактируйте существующий материал.",
                parent=self.app,
            )
            self._name_entry.focus_set()
            return

        messagebox.showinfo("Данные сохранены", message, parent=self.app)
        self._initial_state = self._current_state()
        self.app.go_back()
