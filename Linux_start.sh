#!/bin/bash

# ============================================================
#   🌐 FlexiWeb Stream Scraper - 1-Click Bootstrapper
# ============================================================

# Define color codes for cleaner console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================================"
echo -e "${BLUE}  🌐 FlexiWeb Stream Scraper - 1-Click Bootstrapper${NC}"
echo "============================================================"
echo ""

# Lock current working directory to the script's absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if the virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}[!] Target virtual environment (.venv) not found. Initializing setup script...${NC}"
    echo ""
    
    # Cascade check for available PowerShell core engines
    if command -v pwsh &> /dev/null; then
        pwsh -ExecutionPolicy Bypass -File universal_setup.ps1
    elif command -v powershell &> /dev/null; then
        powershell -ExecutionPolicy Bypass -File universal_setup.ps1
    else
        echo -e "${RED}[ERROR] PowerShell engine not found. Please install pwsh or run manually:${NC}"
        echo "    python3 -m venv .venv"
        echo "    source .venv/bin/activate"
        echo "    pip install -r requirements.txt"
        echo "    python -m playwright install chromium"
        exit 1
    fi
    
    # Catch setup initialization failure
    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${RED}[ERROR] Environment provisioning failed. Please check network connection and retry.${NC}"
        exit 1
    fi
    echo ""
fi

echo -e "${BLUE}[*] Launching FlexiWeb Stream Scraper...${NC}"
echo -e "${YELLOW}[*] Hint: Press Ctrl+C at any time to safely terminate the process.${NC}"
echo ""

# Bypass activate script to avoid global path confusion; execute through specific absolute pipeline
"./.venv/bin/python" main.py "$@"
EXIT_CODE=$? # [修复点 1]: 立刻捕获并锁死 Python 的真实退出码，防止其被随后的判断语句覆盖

# Evaluate structural exit codes
if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}[ERROR] Process terminated abnormally with Exit Code: $EXIT_CODE${NC}"
    # [修复点 2]: 增加 TTY 输入流检测，确保在 Headless (无终端) 自动化部署下不无限挂起
    if [ -t 0 ]; then
        read -p "Press [Enter] to exit..."
    fi
    exit $EXIT_CODE
fi