@echo off
title FlexiWeb Bootstrapper

cd /d "%~dp0"

if exist .venv\ (
    ".venv\Scripts\python.exe" "main.py" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "universal_setup.ps1"
    ".venv\Scripts\python.exe" "main.py" %*
)

if %errorlevel% neq 0 pause