"""Единое оформление интерфейса по руководству по стилю (Приложение 2)."""

import tkinter as tk
from tkinter import ttk

import config


def apply_theme(root):
    """Настроить шрифты и цвета виджетов для всех форм приложения."""
    root.configure(background=config.PRIMARY_BACKGROUND)
    root.option_add("*Font", config.FONT_BODY)
    # Диалоговые окна tkinter (messagebox) наследуют цвета от этих ресурсов.
    root.option_add("*Dialog.msg.font", config.FONT_BODY)

    style = ttk.Style(root)
    style.theme_use("clam")

    style.configure(
        "App.TCombobox",
        fieldbackground=config.PRIMARY_BACKGROUND,
        background=config.SECONDARY_BACKGROUND,
        foreground=config.TEXT_COLOR,
        bordercolor=config.BORDER_COLOR,
        arrowcolor=config.ACCENT_COLOR,
        padding=4,
    )
    style.map(
        "App.TCombobox",
        fieldbackground=[("readonly", config.PRIMARY_BACKGROUND)],
        bordercolor=[("focus", config.ACCENT_COLOR)],
    )

    style.configure(
        "App.Vertical.TScrollbar",
        background=config.SECONDARY_BACKGROUND,
        troughcolor=config.PRIMARY_BACKGROUND,
        bordercolor=config.PRIMARY_BACKGROUND,
        arrowcolor=config.ACCENT_COLOR,
    )

    style.configure(
        "App.Treeview",
        background=config.PRIMARY_BACKGROUND,
        fieldbackground=config.PRIMARY_BACKGROUND,
        foreground=config.TEXT_COLOR,
        bordercolor=config.BORDER_COLOR,
        font=config.FONT_BODY,
        rowheight=30,
    )
    style.configure(
        "App.Treeview.Heading",
        background=config.ACCENT_COLOR,
        foreground=config.PRIMARY_BACKGROUND,
        font=config.FONT_HEADING,
        relief="flat",
        padding=6,
    )
    style.map(
        "App.Treeview.Heading",
        background=[("active", config.ACCENT_ACTIVE_COLOR)],
    )
    style.map(
        "App.Treeview",
        background=[("selected", config.SECONDARY_BACKGROUND)],
        foreground=[("selected", config.TEXT_COLOR)],
    )


def accent_button(parent, text, command, **options):
    """Кнопка целевого действия — акцентный цвет #546F94."""
    return tk.Button(
        parent,
        text=text,
        command=command,
        font=config.FONT_HEADING,
        background=config.ACCENT_COLOR,
        foreground=config.PRIMARY_BACKGROUND,
        activebackground=config.ACCENT_ACTIVE_COLOR,
        activeforeground=config.PRIMARY_BACKGROUND,
        relief="flat",
        cursor="hand2",
        padx=18,
        pady=8,
        **options,
    )


def secondary_button(parent, text, command, **options):
    """Вспомогательная кнопка — дополнительный фон #ABCFCE."""
    return tk.Button(
        parent,
        text=text,
        command=command,
        font=config.FONT_BODY,
        background=config.SECONDARY_BACKGROUND,
        foreground=config.TEXT_COLOR,
        activebackground=config.BORDER_COLOR,
        activeforeground=config.TEXT_COLOR,
        relief="flat",
        cursor="hand2",
        padx=14,
        pady=6,
        **options,
    )


def entry(parent, textvariable, **options):
    return tk.Entry(
        parent,
        textvariable=textvariable,
        font=config.FONT_BODY,
        background=config.PRIMARY_BACKGROUND,
        foreground=config.TEXT_COLOR,
        relief="solid",
        borderwidth=1,
        highlightthickness=1,
        highlightbackground=config.BORDER_COLOR,
        highlightcolor=config.ACCENT_COLOR,
        insertbackground=config.TEXT_COLOR,
        **options,
    )


def body_label(parent, text, **options):
    options.setdefault("font", config.FONT_BODY)
    options.setdefault("foreground", config.TEXT_COLOR)
    return tk.Label(parent, text=text, background=config.PRIMARY_BACKGROUND, **options)
