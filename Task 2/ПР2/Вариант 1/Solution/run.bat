@echo off
rem Запуск приложения учёта материалов компании «Мозаика»
chcp 65001 > nul
cd /d "%~dp0app"
python main.py
if errorlevel 1 pause
