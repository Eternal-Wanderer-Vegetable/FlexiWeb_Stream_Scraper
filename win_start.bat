@echo off
title FlexiWeb Bootstrapper

cd /d "%~dp0"

set "TARGET_VERSION=3.13.12"
if exist python_version.txt (
    for /f "usebackq delims=" %%i in ("python_version.txt") do set "TARGET_VERSION=%%i"
)

set "TARGET_VERSION=%TARGET_VERSION: =%"

if exist .venv\ (
    ".venv\Scripts\python.exe" "main.py" %*
    goto :END
)

echo [!] Virtual environment not found. Starting automatic setup...
echo ------------------------------------------------------------

set "PY_CMD="
where python >nul 2>nul
set "WHERE_PY_ERR=%errorlevel%"
if "%WHERE_PY_ERR%"=="0" (
    set "PY_CMD=python"
)

if "%PY_CMD%"=="" (
    echo [*] Downloading specified Python package [%TARGET_VERSION%]...
    
    curl -L -o "%TEMP%\temp_py.exe" "https://www.python.org/ftp/python/%TARGET_VERSION%/python-%TARGET_VERSION%-amd64.exe"
    
    if not exist "%TEMP%\temp_py.exe" (
        echo [ERROR] Download failed! Please check your network connection.
        goto :ERROR_EXIT
    )
    
    echo [*] Executing silent automated deployment ^(Please wait 1-2 minutes)...
    start /wait "" "%TEMP%\temp_py.exe" /passive InstallAllUsers=0 Include_pip=1 PrependPath=0 AssociateFiles=0 ShortCuts=0
    
    set "VER_SHORT=%TARGET_VERSION:.=%"
    set "VER_SHORT=%VER_SHORT:~0,3%"
    call set "PY_CMD=%%USERPROFILE%%\AppData\Local\Programs\Python\Python%%VER_SHORT%%\python.exe"
)

echo [*] Using Python compiler: "%PY_CMD%"
echo [*] Constructing pristine virtual environment (.venv)...

"%PY_CMD%" -m venv .venv

if not exist .venv\ (
    echo [ERROR] Failed to create virtual environment container.
    goto :ERROR_EXIT
)

set "PIP_INDEX_OPT="
if exist requirements.txt (
    echo.
    echo ============================================================
    echo   Select Pip Dependency Mirror Source 
    echo ============================================================
    echo   [1] Tsinghua University Mirror 
    echo   [2] Default Official Upstream Source 
    echo ============================================================
    set /p "CHOICE=Please enter your choice [1 or 2] (Default is 1): "
    
    if "%CHOICE%"=="" set "CHOICE=1"
    if "%CHOICE%"=="1" (
        echo [*] Mirror activated: Tsinghua University Source.
        set "PIP_INDEX_OPT=-i https://pypi.tuna.tsinghua.edu.cn/simple"
    ) else (
        echo [*] Keeping official default upstream source.
    )
    echo ============================================================
)
if exist requirements.txt (
    echo [*] Synchronizing third-party dependencies...
    ".venv\Scripts\python.exe" -m pip install --upgrade pip -q
    ".venv\Scripts\pip.exe" install -r requirements.txt
    
    findstr /C:"playwright" requirements.txt >nul
    if not errorlevel 1 (
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