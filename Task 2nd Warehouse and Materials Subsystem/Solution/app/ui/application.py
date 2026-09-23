"""Каркас приложения: общая шапка форм и последовательная навигация.

Формы открываются стопкой: кнопка «Назад» возвращает на предыдущую форму
и обновляет её данные. Заголовок окна и заголовок на форме меняются вместе
с открытой страницей.
"""

import tkinter as tk
from tkinter import messagebox
import traceback

import config
from ui import style


class Page(tk.Frame):
    """Базовая экранная форма приложения."""

    window_title = config.APP_TITLE
    heading = ""
    show_logo = False

    def __init__(self, app):
        super().__init__(app.container, background=config.PRIMARY_BACKGROUND)
        self.app = app
        self.repository = app.repository
        self.build()

    def build(self):
        """Создать виджеты формы. Переопределяется наследниками."""

    def on_show(self):
        """Вызывается каждый раз, когда форма становится видимой."""

    def confirm_leave(self):
        """Разрешить уход с формы. Формы с вводом данных спрашивают подтверждение."""
        return True


class Application(tk.Tk):
    def __init__(self, repository):
        super().__init__()
        self.repository = repository
        self._page_stack = []

        self.title(config.APP_TITLE)
        self.minsize(config.WINDOW_MIN_WIDTH, config.WINDOW_MIN_HEIGHT)
        self.geometry(f"{config.WINDOW_MIN_WIDTH}x{config.WINDOW_MIN_HEIGHT}")
        style.apply_theme(self)
        self._set_window_icon()
        self._logo_image = self._load_logo()

        self._build_header()
        self.container = tk.Frame(self, background=config.PRIMARY_BACKGROUND)
        self.container.pack(fill="both", expand=True)

        # Неперехваченная ошибка в обработчике события не должна «ронять» приложение.
        self.report_callback_exception = self._report_unexpected_error
        self.protocol("WM_DELETE_WINDOW", self.confirm_exit)

    # ------------------------------------------------------------------ шапка

    def _set_window_icon(self):
        try:
            self.iconbitmap(default=str(config.ICON_PATH))
        except tk.TclError:
            # Платформа может не поддерживать .ico — приложение работает и без иконки.
            pass

    def _load_logo(self):
        try:
            logo = tk.PhotoImage(file=str(config.LOGO_PATH))
        except tk.TclError:
            return None
        # Уменьшение целым делителем сохраняет пропорции и цвет логотипа.
        return logo.subsample(config.LOGO_SUBSAMPLE, config.LOGO_SUBSAMPLE)

    def _build_header(self):
        header = tk.Frame(self, background=config.SECONDARY_BACKGROUND)
        header.pack(fill="x")

        self._back_button = style.secondary_button(header, "← Назад", self.go_back)
        self._back_button.configure(background=config.PRIMARY_BACKGROUND)

        self._logo_label = tk.Label(
            header,
            image=self._logo_image,
            background=config.SECONDARY_BACKGROUND,
        )
        self._heading_label = tk.Label(
            header,
            text="",
            font=config.FONT_TITLE,
            background=config.SECONDARY_BACKGROUND,
            foreground=config.ACCENT_COLOR,
            anchor="w",
            justify="left",
        )
        self._header = header

    def _render_header(self, page):
        for widget in (self._back_button, self._logo_label, self._heading_label):
            widget.pack_forget()

        if len(self._page_stack) > 1:
            self._back_button.pack(side="left", padx=(16, 8), pady=12)
        if page.show_logo and self._logo_image is not None:
            self._logo_label.pack(side="left", padx=(16, 12), pady=10)
        self._heading_label.configure(text=page.heading)
        self._heading_label.pack(side="left", padx=(4, 16), pady=12, fill="x", expand=True)

    # -------------------------------------------------------------- навигация

    def open_page(self, page_class, **arguments):
        """Открыть новую форму поверх текущей."""
        if self._page_stack:
            self._page_stack[-1].pack_forget()
        page = page_class(self, **arguments)
        self._page_stack.append(page)
        self._show_current_page()

    def go_back(self):
        """Вернуться на предыдущую форму и обновить её данные."""
        if len(self._page_stack) < 2:
            return
        if not self._page_stack[-1].confirm_leave():
            return
        page = self._page_stack.pop()
        page.destroy()
        self._show_current_page()

    def _show_current_page(self):
        page = self._page_stack[-1]
        page.pack(fill="both", expand=True)
        self.title(page.window_title)
        self._render_header(page)
        page.on_show()

    # --------------------------------------------------------------- диалоги

    def confirm_exit(self):
        confirmed = messagebox.askyesno(
            "Завершение работы",
            "Закрыть приложение учёта материалов?\n\n"
            "Несохранённые изменения на открытой форме будут потеряны.",
            icon="warning",
            parent=self,
        )
        if confirmed:
            self.destroy()

    def _report_unexpected_error(self, exception_type, exception_value, exception_traceback):
        traceback.print_exception(exception_type, exception_value, exception_traceback)
        messagebox.showerror(
            "Непредвиденная ошибка",
            "При выполнении операции произошла ошибка, действие не выполнено.\n\n"
            f"Описание: {exception_value}\n\n"
            "Вернитесь на предыдущую форму и повторите действие. "
            "Если ошибка повторяется, обратитесь к администратору системы.",
            parent=self,
        )
