"""Сборка исполняемого файла приложения учёта материалов.

Собирает один exe-файл с иконкой компании и встроенными ресурсами.
База данных mosaic.db рядом с exe-файлом не упаковывается: она должна
оставаться внешним файлом, чтобы изменения материалов сохранялись.

Запуск: python build_exe.py   (требуется пакет pyinstaller)
"""

from pathlib import Path
import shutil
import subprocess
import sys

SOLUTION_DIR = Path(__file__).resolve().parent
APP_DIR = SOLUTION_DIR / "app"
BUILD_DIR = SOLUTION_DIR / "build"
DIST_DIR = SOLUTION_DIR / "dist"
EXECUTABLE_NAME = "Мозаика — учёт материалов"


def main():
    arguments = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--clean",
        "--onefile",
        "--windowed",
        f"--name={EXECUTABLE_NAME}",
        f"--icon={APP_DIR / 'resources' / 'Мозаика.ico'}",
        f"--add-data={APP_DIR / 'resources'}{';' if sys.platform == 'win32' else ':'}resources",
        f"--paths={APP_DIR}",
        f"--distpath={DIST_DIR}",
        f"--workpath={BUILD_DIR}",
        f"--specpath={BUILD_DIR}",
        str(APP_DIR / "main.py"),
    ]
    result = subprocess.run(arguments, check=False)
    if result.returncode != 0:
        return result.returncode

    # Приложение ищет базу данных рядом с исполняемым файлом.
    shutil.copy(SOLUTION_DIR / "database" / "mosaic.db", DIST_DIR / "mosaic.db")
    print(f"\nИсполняемый файл собран: {DIST_DIR / (EXECUTABLE_NAME + '.exe')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
