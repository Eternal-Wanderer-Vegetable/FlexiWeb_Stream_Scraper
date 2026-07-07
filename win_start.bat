@echo off
title FlexiWeb Bootstrapper
cd /d "%~dp0"
if exist .venv\ (
    echo [*] Found virtual environment. Launching application...
    ".venv\Scripts\python.exe" "main.py" %*
    goto :END
)
echo [!] Virtual environment not found. Starting automatic setup...
echo ------------------------------------------------------------
set "PY_CMD="
where python >nul 2>nul
if %errorlevel% eq 0 set "PY_CMD=python"
if "%PY_CMD%"=="" (
    echo [*] Global Python not found. Downloading temporary Python package...
    
    :: 使用 Windows 自带的 curl 下载，100% 不会被 PowerShell 策略拦截
    curl -L -o "%TEMP%\temp_py.exe" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    
    if not exist "%TEMP%\temp_py.exe" (
        echo [ERROR] Download failed! Please check your internet connection.
        goto :ERROR_EXIT
    )
    
    echo [*] Executing silent automated deployment (Please wait 1-2 minutes)...
    start /wait "" "%TEMP%\temp_py.exe" /passive InstallAllUsers=0 Include_pip=1 PrependPath=0 AssociateFiles=0 ShortCuts=0
    
    set "PY_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe"
)
echo [*] Using Python compiler: "%PY_CMD%"
echo [*] Constructing pristine virtual environment (.venv)...
"%PY_CMD%" -m venv .venv --with-pip
if not exist .venv\ (
    echo [ERROR] Failed to create virtual environment container.
    goto :ERROR_EXIT
)
if exist requirements.txt (
    echo [*] Synchronizing third-party dependencies...
    ".venv\Scripts\python.exe" -m pip install --upgrade pip -q
    ".venv\Scripts\pip.exe" install -r requirements.txt
    findstr /C:"playwright" requirements.txt >nul
    if %errorlevel% eq 0 (
        echo [*] Installing Chromium browser kernel...
        ".venv\Scripts\python.exe" -m playwright install chromium
    )
)
if exist "%TEMP%\temp_py.exe" del /f /q "%TEMP%\temp_py.exe" >nul 2>nul

echo ------------------------------------------------------------
echo [V] Environment deployment completed successfully!
echo [*] Launching FlexiWeb Stream Scraper...
echo.
".venv\Scripts\python.exe" "main.py" %*
goto :END

:ERROR_EXIT
echo.
echo [FATAL] Bootstrapper terminated due to errors above.
pause
exit /b 1

:END
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Application exited abnormally.
    pause
)