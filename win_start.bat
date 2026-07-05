@echo off
chcp 65001 >nul
title FlexiWeb Stream Scraper - 1-Click Bootstrapper

echo ============================================================
echo   🌐 FlexiWeb Stream Scraper - 1-Click Bootstrapper
echo ============================================================
echo.

:: Verify existence of the virtual environment container
if not exist "%~dp0.venv\" (
    echo [!] Target virtual environment ^(.venv^) not found. Initializing setup script...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0universal_setup.ps1"
    if %errorlevel% neq 0 (
        echo.
        echo [ERROR] Environment provisioning failed. Please check network connection and retry.
        pause
        exit /b 1
    )
    echo.
)

echo [*] Launching FlexiWeb Stream Scraper...
echo [*] Hint: Press Ctrl+C at any time to safely terminate the process.
echo.

:: [修复点 1]: 放弃使用 call activate 并直接采用 .venv 绝对路径调用。
:: 彻底防止在全局 Python 被干净卸载后，系统默认去劫持并弹窗微软应用商店。
"%~dp0.venv\Scripts\python.exe" "%~dp0main.py" %*

:: [修复点 2]: 将 'if errorlevel 1' 替换为 '%errorlevel% neq 0' 健壮判断。
:: 完美捕获可能由某些底层 C++ 组件抛出的负数崩溃码（如 -1），防止窗口闪退。
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Process terminated abnormally with Exit Code: %errorlevel%
    pause
)