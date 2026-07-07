# =====================================================================
#  Universal Python Environment Provisioning Framework (Linear Version)
# =====================================================================
$OutputEncoding = [System.Text.Encoding]::UTF8

$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VERSION_FILE = Join-Path $PROJECT_ROOT "python_version.txt"
$REQUIREMENTS = Join-Path $PROJECT_ROOT "requirements.txt"
$TargetVenvDir = Join-Path $PROJECT_ROOT ".venv"

$TARGET_VERSION = "3.11.9" 
if (Test-Path $VERSION_FILE) { $TARGET_VERSION = (Get-Content $VERSION_FILE).Trim() }

Write-Host "[*] Launching Universal Automated Provisioning Engine..." -ForegroundColor Cyan
Write-Host "[*] Scanning system Python topology..." -ForegroundColor Gray

# 1. 尝试探测系统自带的 Python
$GlobalPythonPath = ""
$HasPython = Get-Command "python" -ErrorAction SilentlyContinue
if ($HasPython) { $GlobalPythonPath = (Get-Command "python").Source }

# 2. 如果系统没有，或者不是 3.11，则强制下载便携式轻量包
if ([string]::IsNullOrEmpty($GlobalPythonPath)) {
    Write-Host "[!] No compatible Python found. Downloading temporary installer..." -ForegroundColor Yellow
    $DownloadUrl = "https://www.python.org/ftp/python/$TARGET_VERSION/python-$TARGET_VERSION-amd64.exe"
    $InstallerPath = Join-Path $env:TEMP "temp_python_installer.exe"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath
    
    Write-Host "[*] Executing silent automated deployment..." -ForegroundColor Gray
    Start-Process -FilePath $InstallerPath -ArgumentList "/passive InstallAllUsers=0 Include_pip=1 PrependPath=0 AssociateFiles=0 ShortCuts=0" -Wait
    
    $MajorMinorShort = ($TARGET_VERSION -split "\.")[0..1] -join ""
    $GlobalPythonPath = "$env:USERPROFILE\AppData\Local\Programs\Python\Python$MajorMinorShort\python.exe"
}

# 3. 筑巢构建虚拟环境 (用双引号强力防御路径中的空格)
Write-Host "[*] Constructing pristine virtual environment..." -ForegroundColor Gray
& $GlobalPythonPath -m venv "$TargetVenvDir" --with-pip

# 4. 锁定虚拟环境内部的执行管道
$VENV_PYTHON = Join-Path $TargetVenvDir "Scripts\python.exe"
$VENV_PIP    = Join-Path $TargetVenvDir "Scripts\pip.exe"

# 5. 如果有依赖配置文件，则执行隔离同步
if (Test-Path $REQUIREMENTS) {
    Write-Host "[*] Synchronizing third-party dependencies..." -ForegroundColor Gray
    & $VENV_PYTHON -m pip install --upgrade pip -q
    & $VENV_PIP install -r "$REQUIREMENTS"
    
    # 自动初始化 Playwright 浏览器内核
    $ReqContent = Get-Content $REQUIREMENTS
    if ($ReqContent -match "playwright") {
        & $VENV_PYTHON -m playwright install chromium
    }
}

Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host "[√] Environment deployment completed successfully!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green