@echo off
title FlexiWeb Bootstrapper
cd /d "%~dp0"
if exist .venv\ (
    ".venv\Scripts\python.exe" "main.py" %*
    goto :END
)
echo [!] Virtual environment not found. Starting automatic setup...
set "PY_CMD="
where python >nul 2>nul
if %errorlevel% eq 0 set "PY_CMD=python"
if "%PY_CMD%"=="" (
    echo [*] Downloading standalone temporary Python package...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%TEMP%\temp_py.exe'"
    
    echo [*] Executing silent automated deployment (Please wait 1-2 minutes)...
    start /wait "" "%TEMP%\temp_py.exe" /passive InstallAllUsers=0 Include_pip=1 PrependPath=0 AssociateFiles=0 ShortCuts=0
    
    set "PY_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe"
)
echo [*] Constructing pristine virtual environment...
"%PY_CMD%" -m venv .venv --with-pip
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
echo.
echo [V] Environment deployment completed successfully!
echo [*] Launching FlexiWeb Stream Scraper...
echo.
".venv\Scripts\python.exe" "main.py" %*
:END
if %errorlevel% neq 0 pause