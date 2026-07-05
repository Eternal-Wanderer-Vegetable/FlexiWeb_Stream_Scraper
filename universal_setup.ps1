# =====================================================================
# 🚀 Universal Python Environment Provisioning Framework (Cross-Platform)
# =====================================================================
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---- 🌐 1. 全球多语言本地化字典 ----
$CURRENT_LANG = "en"
if ($PSCulture -match "zh") { $CURRENT_LANG = "zh" }

$I18N = @{
    "zh" = @{
        "start"            = "[*] 启动通用自动化环境构建引擎..."
        "check_py"         = "[*] 正在扫描系统 Python 拓扑结构..."
        "py_match"         = "[√] 成功命中匹配的系统 Python 版本: {0}"
        "py_mismatch"      = "[!] 系统 Python 版本 ({0}) 与预期目标 ({1}) 不符。"
        "py_missing"       = "[!] 系统未检测到任何 Python 动力源。"
        "download_py"      = "[*] 正在从官方镜像安全拉取临时 Python 安装包 [{0}]..."
        "install_py"       = "[*] 正在执行全自动化静默供给 (请稍候 1-2 分钟)..."
        "create_venv"      = "[*] 正在目标路径下筑巢原生虚拟环境 venv -> [{0}]..."
        "venv_success"     = "[√] 虚拟环境底层构建成功。"
        "sync_deps"        = "[*] 正在通过隔离管道同步第三方依赖库 (requirements.txt)..."
        "clean_up"         = "[*] 核心构建完毕。正在物理卸载临时托管的 Python，防止污染宿主环境..."
        "clean_success"    = "[√] 临时环境释放完毕，全局空间已恢复纯净。"
        "success_banner"   = "[√] 自动化环境部署完美收官！"
        "run_hint"         = "提示：你现在可以随时在终端执行以下命令直接启动程序："
        "warn_req_missing" = "[!_!] 未检测到 requirements.txt 配置文件。脚本将自动降级：为你构建一个绝对纯净的 .venv 环境。"
        "err_fatal"        = "[ERROR] 致命错误: {0}"
    }
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
    $lang = $I18N[$CURRENT_LANG]
    if (-not $lang) { $lang = $I18N["en"] }
    $text = $lang[$key]
    if (-not $text) { $text = $key }
    if ($args_list) { return $text -f $args_list }
    return $text
}

# ---- ⚙️ 2. 通用动态参数配置定义 ----
$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VERSION_FILE = Join-Path $PROJECT_ROOT "python_version.txt"
$REQUIREMENTS = Join-Path $PROJECT_ROOT "requirements.txt"

# 动态读取预设版本
$TARGET_VERSION = "3.11.9" 
if (Test-Path $VERSION_FILE) {
    $TARGET_VERSION = (Get-Content $VERSION_FILE).Trim()
}

param (
    [string]$TargetVenvDir = (Join-Path $PROJECT_ROOT ".venv")
)

Write-Host (_ "start") -ForegroundColor Cyan

# 🛠️ 【改造点 1】：解绑硬性中断，若缺失文件则打印警告并标记状态
$HasRequirements = $true
if (-not (Test-Path $REQUIREMENTS)) {
    Write-Host (_ "warn_req_missing") -ForegroundColor Yellow
    $HasRequirements = $false
}

# ---- 🔍 3. 检查系统 Python 版本号拓扑 ----
Write-Host (_ "check_py") -ForegroundColor Gray
$PythonCmd = if ($IsWindows) { "python" } else { "python3" }
$HasPython = Get-Command $PythonCmd -ErrorAction SilentlyContinue
$NeedTemporaryInstall = $true

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

# ---- 📥 4. 跨平台动态静默安装临时 Python ----
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

# ---- 🏗️ 5. 在用户指定目录下创建独立的 Venv 空间 ----
Write-Host (_ "create_venv" @($TargetVenvDir)) -ForegroundColor Gray
Start-Process $GlobalPythonPath -ArgumentList "-m venv $TargetVenvDir --with-pip" -Wait
if (-not (Test-Path $TargetVenvDir)) {
    Write-Host (_ "err_fatal" @("Failed to construct VENV container.")) -ForegroundColor Red
    Exit 1
}
Write-Host (_ "venv_success") -ForegroundColor Green

# 锁闭 Venv 内部的执行管道
if ($IsWindows) {
    $VENV_PYTHON = Join-Path $TargetVenvDir "Scripts\python.exe"
    $VENV_PIP    = Join-Path $TargetVenvDir "Scripts\pip.exe"
} else {
    $VENV_PYTHON = Join-Path $TargetVenvDir "bin/python"
    $VENV_PIP    = Join-Path $TargetVenvDir "bin/pip"
}

# ---- 📦 6. 【改造点 2】：条件判定：仅在存在配置文件时，执行第三方依赖库安装 ----
if ($HasRequirements) {
    Write-Host (_ "sync_deps") -ForegroundColor Gray
    Start-Process $VENV_PYTHON -ArgumentList "-m pip install --upgrade pip -q" -Wait
    Start-Process $VENV_PIP -ArgumentList "install -r $REQUIREMENTS" -Wait

    # 检测并初始化 playwright
    if (Get-Content $REQUIREMENTS | Select-String "playwright" -Quiet) {
        Start-Process $VENV_PYTHON -ArgumentList "-m playwright install chromium" -Wait
    }
}

# ---- 🧹 7. 动态卸载临时 Python，消灭污染 ----
if ($NeedTemporaryInstall -and $IsWindows -and (Test-Path $InstallerPath)) {
    Write-Host (_ "clean_up") -ForegroundColor Yellow
    Start-Process -FilePath $InstallerPath -ArgumentList "/passive /uninstall" -Wait
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    Write-Host (_ "clean_success") -ForegroundColor Green
}

# ---- 🎉 8. 完美收官 ----
Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host (_ "success_banner") -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host (_ "run_hint")
Write-Host "    $VENV_PYTHON your_script.py`n" -ForegroundColor Yellow