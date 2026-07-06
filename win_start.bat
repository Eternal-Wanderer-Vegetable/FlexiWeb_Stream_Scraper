@echo off
chcp 65001 >nul
title FlexiWeb Stream Scraper - 1-Click Bootstrapper

echo ============================================================
echo   🌐 FlexiWeb Stream Scraper - 1-Click Bootstrapper
echo ============================================================
echo.

:: [新增安全防御]：强行切换工作目录到当前脚本所在文件夹，并用引号包裹防止空格防线失守
cd /d "%~dp0"

:: Verify existence of the virtual environment container
:: 这里直接使用当前目录下的相对路径，完美避开 %~dp0 的尾部反斜杠转义漏洞
if not exist ".venv\" (
    echo [!] Target virtual environment ^(.venv^) not found. Initializing setup script...
    echo.
    
    :: 使用相对路径调用 PowerShell 脚本，彻底解决带空格路径下的 -File 传参解析 Bug
    powershell -NoProfile -ExecutionPolicy Bypass -File "universal_setup.ps1"
    
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

:: 既然上面已经用 cd /d 切换了目录，这里调用同样改用相对路径，最稳妥、最抗空格！
".venv\Scripts\python.exe" "main.py" %*

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Process terminated abnormally with Exit Code: %errorlevel%
    pause
)