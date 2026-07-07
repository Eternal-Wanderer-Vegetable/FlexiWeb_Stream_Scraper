# =====================================================================
#  Universal Python Environment Provisioning Framework (Fixed Syntax)
# =====================================================================
param (
    [string]$TargetVenvDir = ""
)

$OutputEncoding = [System.Text.Encoding]::UTF8

# ---- ⚙️ 1. Configuration & Parameter Definition ----
$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VERSION_FILE = Join-Path $PROJECT_ROOT "python_version.txt"
$REQUIREMENTS = Join-Path $PROJECT_ROOT "requirements.txt"

if ([string]::IsNullOrEmpty($TargetVenvDir)) {
    $TargetVenvDir = Join-Path $PROJECT_ROOT ".venv"
}

$TARGET_VERSION = "3.11.9" 
if (Test-Path $VERSION_FILE) {
    $TARGET_VERSION = (Get-Content $VERSION_FILE).Trim()
}

# ---- 🌐 2. English Localization Dictionary ----
$I18N = @{
    "en" = @{
        "start"            = "[*] Launching Universal Automated Provisioning Engine..."
        "check_py"         = "[*] Scanning system Python topology..."
        "py_match"         = "[√] Successfully matched system Python version: {0}"
        "py_mismatch"      = "[!] System Python version ({0}) mismatches targeted version ({1})."
        "py_missing"       = "[!] No Python installation detected in the global scope."
        "download_py"      = "[*] Pulling standalone temporary Python package [{0}] from upstream..."
        "install_py"       = "[*] Executing silent automated deployment (Please wait 1-2 minutes)..."
        "create_venv"      = "[*] Constructing pristine virtual environment at -> [{0}]..."
        "venv_success"     = "[√] Virtual environment created successfully."
        "sync_deps"        = "[*] Synchronizing third-party dependencies via isolated pipeline (requirements.txt)..."
        "clean_up"         = "[*] Core framework synchronized. Uninstalling temporary Python to prevent host pollution..."
        "clean_success"    = "[√] Temporary compiler purged. Global workspace restored to clean state."
        "success_banner"   = "[√] Environment deployment completed successfully!"
        "run_hint"         = "Hint: You can now boot your application by executing:"
        "warn_req_missing" = "[!_!] 'requirements.txt' not found. Standalone mode activated: A pristine, clean .venv environment will be provisioned."
        "err_fatal"        = "[ERROR] Fatal Error: {0}"
    }
}

function _($key, $args_list) {
    $lang = $I18N["en"]
    $text = $lang[$key]
    if (-not $text) { $text = $key }
    if ($args_list) { return $text -f $args_list }
    return $text
}

Write-Host (_ "start") -ForegroundColor Cyan

$HasRequirements = $true
if (-not (Test-Path $REQUIREMENTS)) {
    Write-Host (_ "warn_req_missing") -ForegroundColor Yellow
    $HasRequirements = $false
}

# ---- 🔍 3. Check System Python Version ----
Write-Host (_ "check_py") -ForegroundColor Gray
$PythonCmd = if ($IsWindows) { "python" } else { "python3" }
$HasPython = Get-Command $PythonCmd -ErrorAction SilentlyContinue
$NeedTemporaryInstall = $true
$GlobalPythonPath = ""

if ($HasPython) {
    $CurrentVersionStr = (& $PythonCmd --version 2>&1)
    if ($CurrentVersionStr -match "Python\s+(\d+\.\d+\.\d+)") {
        $CurrentVersion = $Matches[1]
        $TargetMajorMinor = ($TARGET_VERSION -split "\.")[0..1] -join "."
        $CurrentMajorMinor = ($CurrentVersion -split "\.")[0..1] -join "."
        
        if ($CurrentMajorMinor -eq $TargetMajorMinor) {
            Write-Host (_ "py_match" @($CurrentVersion)) -ForegroundColor Green
            $NeedTemporaryInstall = $false
            $GlobalPythonPath = (Get-Command $PythonCmd).Source
        } else {
            Write-Host (_ "py_mismatch" @($CurrentVersion, $TARGET_VERSION)) -ForegroundColor Yellow
        }
    }
} else {
    Write-Host (_ "py_missing") -ForegroundColor Yellow
}

# ---- 📥 4. Install Temporary Python If Needed ----
$InstallerPath = ""
if ($NeedTemporaryInstall) {
    if ($IsWindows) {
        $DownloadUrl = "https://www.python.org/ftp/python/$TARGET_VERSION/python-$TARGET_VERSION-amd64.exe"
        $InstallerPath = Join-Path $env:TEMP "temp_python_installer.exe"
        
        Write-Host (_ "download_py" @($TARGET_VERSION)) -ForegroundColor Gray
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath
        
        Write-Host (_ "install_py") -ForegroundColor Gray
        Start-Process -FilePath $InstallerPath -ArgumentList "/passive InstallAllUsers=0 Include_pip=1 PrependPath=0 AssociateFiles=0 ShortCuts=0" -Wait
        
        $MajorMinorShort = ($TARGET_VERSION -split "\.")[0..1] -join ""
        $GlobalPythonPath = "$env:USERPROFILE\AppData\Local\Programs\Python\Python$MajorMinorShort\python.exe"
    }
    elseif ($IsLinux) {
        Write-Host (_ "install_py") -ForegroundColor Gray
        if (Get-Command apt-get -ErrorAction SilentlyContinue) {
            Start-Process "sudo" -ArgumentList "apt-get update -y" -Wait
            Start-Process "sudo" -ArgumentList "apt-get install -y python3 python3-pip python3-venv" -Wait
        } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
            Start-Process "sudo" -ArgumentList "yum install -y python3 python3-pip" -Wait
        }
        $GlobalPythonPath = (Get-Command "python3").Source
    }
}

# ---- 🏗️ 5. Create Virtual Environment ----
Write-Host (_ "create_venv" @($TargetVenvDir)) -ForegroundColor Gray

# 【绝杀 Bug 2】：增加空值判断保护机制
if ([string]::IsNullOrEmpty($GlobalPythonPath) -or -not (Test-Path $GlobalPythonPath)) {
    Write-Host (_ "err_fatal" @("Python executable path is invalid or empty.")) -ForegroundColor Red
    Exit 1
}

Start-Process $GlobalPythonPath -ArgumentList "-m venv `"$TargetVenvDir`" --with-pip" -Wait
if (-not (Test-Path $TargetVenvDir)) {
    Write-Host (_ "err_fatal" @("Failed to construct VENV container.")) -ForegroundColor Red
    Exit 1
}
Write-Host (_ "venv_success") -ForegroundColor Green

if ($IsWindows) {
    $VENV_PYTHON = Join-Path $TargetVenvDir "Scripts\python.exe"
    $VENV_PIP    = Join-Path $TargetVenvDir "Scripts\pip.exe"
} else {
    $VENV_PYTHON = Join-Path $TargetVenvDir "bin/python"
    $VENV_PIP    = Join-Path $TargetVenvDir "bin/pip"
}

# ---- 📦 6. Install Dependencies ----
if ($HasRequirements) {
    Write-Host (_ "sync_deps") -ForegroundColor Gray
    Start-Process $VENV_PYTHON -ArgumentList "-m pip install --upgrade pip -q" -Wait
    Start-Process $VENV_PIP -ArgumentList "install -r `"$REQUIREMENTS`"" -Wait

    if (Get-Content $REQUIREMENTS | Select-String "playwright" -Quiet) {
        Start-Process $VENV_PYTHON -ArgumentList "-m playwright install chromium" -Wait
    }
}

# ---- 🧹 7. Uninstall Temporary Python to Prevent Host Pollution ----
if ($NeedTemporaryInstall -and $IsWindows -and (Test-Path $InstallerPath)) {
    Write-Host (_ "clean_up") -ForegroundColor Yellow
    Start-Process -FilePath $InstallerPath -ArgumentList "/passive /uninstall" -Wait
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    Write-Host (_ "clean_success") -ForegroundColor Green
}

# ---- 🎉 8. Success Banner ----
Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host (_ "success_banner") -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host (_ "run_hint")
Write-Host "    $VENV_PYTHON main.py`n" -ForegroundColor Yellow