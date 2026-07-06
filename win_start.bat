@echo off
:: 放弃强推 65001，直接用系统默认编码，防止断行
title FlexiWeb Stream Scraper - 1-Click Bootstrapper

echo ============================================================
echo   FlexiWeb Stream Scraper - 1-Click Bootstrapper
echo ============================================================
echo.

cd /d "%~dp0"

:: [终极防线 1]：把 if 后面容易导致编码错乱的英文括号 ^(.venv^) 彻底删掉，改用纯英文
if exist .venv\ goto :LAUNCH_APP

echo [!] Target virtual environment venv not found. Initializing setup script...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "universal_setup.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Environment provisioning failed. Please check network connection and retry.
    pause
    exit /b 1
)
echo.

:LAUNCH_APP
echo [*] Launching FlexiWeb Stream Scraper...
echo [*] Hint: Press Ctrl+C at any time to safely terminate the process.
echo.

:: [终极防线 2]：直接调用，不再嵌套在 if 括号内部，彻底断绝乱码引起的语法崩溃
".venv\Scripts\python.exe" "main.py" %*

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Process terminated abnormally with Exit Code: %errorlevel%
    pause
)