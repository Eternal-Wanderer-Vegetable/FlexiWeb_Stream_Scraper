#!/bin/bash

# 获取当前脚本所在的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "============================================================"
echo "  🌐 FlexiWeb Stream Scraper - Linux Bootstrapper"
echo "============================================================"
echo ""

# 1. 如果存在虚拟环境，直接启动程序
if [ -d ".venv" ]; then
    echo "[*] Launching FlexiWeb Stream Scraper..."
    ./.venv/bin/python3 main.py "$@"
    exit $?
fi

# 2. 如果不存在，开始自动化环境供给
echo "[!] Virtual environment not found. Initializing setup..."

# 探测系统全局 Python3
if ! command -v python3 &> /dev/null; then
    echo "[*] No python3 found. Attempting to install via package manager..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip
    else
        echo "[ERROR] Unsupported Linux distribution. Please install python3 manually."
        exit 1
    fi
fi

# 3. 构建虚拟环境
echo "[*] Constructing pristine virtual environment..."
python3 -m venv .venv

# 4. 同步依赖
if [ -f "requirements.txt" ]; then
    echo "[*] Synchronizing third-party dependencies..."
    ./.venv/bin/pip install --upgrade pip -q
    ./.venv/bin/pip install -r requirements.txt
    
    # 自动扫描并激活 playwright 浏览器内核
    if grep -q "playwright" requirements.txt; then
        echo "[*] Installing Chromium browser kernel..."
        ./.venv/bin/python3 -m playwright install chromium
    fi
fi

echo ""
echo "[√] Environment deployment completed successfully!"
echo "[*] Launching FlexiWeb Stream Scraper..."
echo ""

# 5. 启动主程序
./.venv/bin/python3 main.py "$@"