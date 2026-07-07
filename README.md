# 🌐 FlexiWeb Stream Scraper

[简体中文](./README_zh_cn.md) | English

---

(Note: This version of readme.md was translated from the Chinese version by Gemini)

FlexiWeb Stream Scraper is a lightweight AI chat stream scraping tool built on Playwright and FastAPI, designed to mimic the API services provided by various AI vendors. It automates interactions with major AI chat platforms, extracts the full Chain of Thought (Think) alongside the final output, and broadcasts the results to downstream webhook services in real time.

Whether for data collection, content archiving, or building an AI middleware pipeline, FlexiWeb Stream Scraper offers a stable, efficient automated solution.

---

## ✨ Features

- **🤖 Multi-Platform AI Support**  
  Easily adapt to different AI chat platforms via flexible JSON configurations. Out of the box, it supports ChatGPT, Gemini, DeepSeek, Grok, and Qwen, with fully customizable rule extensions.

- **🧠 Chain-of-Thought (CoT) & Output Separation**  
  Automatically identifies and extracts the AI's "thinking process" vs. the "final answer," facilitating clean subsequent analysis and archiving.

- **📡 Real-Time Stream Broadcasting**  
  Captured stream content can be pushed instantly to downstream Webhooks, unlocking trivial integrations with chat bots, monitoring dashboards, or data lakes.

- **🌍 Global Multi-Language Support**  
  Built-in English and Chinese localized localizations for both the UI and terminal messages, adapting smoothly based on system localizations or explicit boot flags.

- **🔌 1-Click Environment Provisioning**  
  Bundled with a universal cross-platform PowerShell automation script (`universal_setup.ps1`), backed by dedicated platform-native bootstrapper wrappers. It matches target Python versions and constructs isolated, pristine virtual environments natively.

- **📝 Persistent Markdown Logs**  
  Automatically generates structured Markdown log files for every conversation, making troubleshooting, reviewing, and sharing effortless.
---

## 🚀 Quick Start

### 1. Requirements

- Operating System: Windows / Linux / macOS
- PowerShell engine installed (Native on Windows, easily installed on Linux/macOS as `pwsh`)
- Active Internet connection (for remote dependency fetching and browser driver downloads)

### 2. Clone or Download the Project

Click the green "Code" button on the main repository page and select "Download ZIP" from the dropdown menu.

Alternatively, you can clone the repository using the following command:

```bash
git clone https://github.com/Eternal-Wanderer-Vegetable/FlexiWeb_Stream_Scraper.git
cd flexiweb-stream-scraper
```

### 3. One-Click Environment Provisioning

To bypass execution policies seamlessly across different environments, launch the dedicated wrapper script from the repository root:

For Windows Users:Simply double-click win_start.bat in the file explorer, or execute the following bypass command inside PowerShell:

```PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File .\universal_setup.ps1
```

For Linux / macOS Users:Grant execution permissions and execute the native bootstrapper:

```bash
chmod +x ./Linux_start.sh
./Linux_start.sh
```

The background engine handles the following workflows automatically:

* Scans host Python topology, instantly retrieving and installing a standalone temporary execution engine if version mismatch occurs.
* Provisions a completely isolated .venv environment container under the root directory.
* Syncs all dependencies declared in requirements.txt (including cross-platform constraints like restricting colorama natively to Windows execution scopes).
* Automates silent browser binary initialization for Playwright Chromium instances.
* Purges temporary installers to maintain absolute, zero-pollution workspace conditions on host platforms.

💡 Note: If requirements.txt is missing, the framework will gracefully fall back to configuring a pristine virtual container environment, enabling manual installation of required packages later.

### 4. Configure Scraping Rules

In the config/ directory, create or modify {site_name}.json files adhering to the configuration definitions. Below is an example structure for deepseek.json:

```JSON
{
  "site_name": "DeepSeek",
  "base_url": "[https://chat.deepseek.com/](https://chat.deepseek.com/)",
  "selectors": {
    "input_box": "textarea",
    "ai_answer_container": ".ds-message",
    "wait_for_thought_done_selector": ".ds-thought-done",
    "markdown_rules": {
      "div.think": { "prefix": "🧠 **Thinking Process:**\n", "suffix": "\n" },
      "div.final": { "prefix": "✅ **Final Answer:**\n", "suffix": "\n\n" }
    }
  }
}
```

### 5. Run the Application

Skip activation routines entirely; run directly through the unified wrappers or pipeline via absolute compiler contexts to eliminate potential Microsoft Store stub hijacking:

```Bash
# Windows Ecosystem
.venv\Scripts\python.exe main.py --lang zh

# Linux / macOS Ecosystem
./.venv/bin/python main.py --lang zh
```

Upon boot, an interactive console menu displays available targets. Select a configured AI target to spin up the command line runtime workspace.

### 6. Querying via API

Upon boot, a standalone backend service spawns locally via FastAPI (listening on port 8000 by default). You can invoke requests directly using HTTP POST primitives:

```Bash
curl -X POST "[http://127.0.0.1:8000/api/ask](http://127.0.0.1:8000/api/ask)" \
     -H "Content-Type: application/json" \
     -d '{"site": "deepseek", "prompt": "Please explain the fundamental principles of quantum computing "}'
```

## 🛠️ Advanced Operations

### Command Line Flags

```Bash
# Windows
.venv\Scripts\python.exe main.py [--site SITE] [--port PORT] [--lang zh|en] [--headless]

# Linux
./.venv/bin/python main.py [--site SITE] [--port PORT] [--lang zh|en] [--headless]
```

* --site：Hardcodes the targeted profile mapping key (e.g., deepseek), skipping the initial interactive setup prompt.
* --port：Overrides default binding targets (picks the next unallocated socket pool naturally if omitted).
* --lang：Locks display parameters manually (zh or en).
* --headless：Runs the automation engine headlessly (ideal for headless VPS setups).

### Live Shell Directives

While navigating the console interface loop, specific quick-slash commands control engine behaviors interactively:

* exit: Gracefully terminates all runtimes and closes open browser context instances.
* /lang: Swaps localized dictionary parameters dynamically on-the-fly.
* /switch: Switches the active scraper engine context mapping live.

### Downstream Webhook Pipelines

To dispatch live extraction outputs downstream, adjust the config/webhooks.json schema layout:

```JSON
{
  "downstream_webhooks": [
    "http://your-service.com/webhook",
    "http://another-service.com/endpoint"
  ]
}
```

As text blocks assemble, structured JSON events propagate outwards encompassing standard tracking objects like site, type (think/final_output), chunk, and termination keys.

## 📁 Project Layout

```Plaintext
flexiweb-stream-scraper/
├── main.py                      # Application Core Lifecycle Entry (FastAPI + CLI Loop)
├── win_start.bat                # Windows One-Click Execution & Provisioning Entry
├── Linux_start.sh               # Linux One-Click Execution & Provisioning Entry
├── universal_setup.ps1          # Core Cross-Platform Provisioning Engine
├── requirements.txt             # Lightweight Cross-Platform Dependency Matrix
├── python_version.txt           # Target System Blueprint Requirements (e.g., 3.11.9)
├── config/
│   ├── deepseek.json            # DeepSeek Scraper Strategy Engine Configuration
│   ├── webhooks.json            # Downstream Webhook Route Matrix Definitions
│   └── i18n.json                # Core Localization Multi-Language Dictionary
├── extensions/                  # Persistent Virtual Browser Extension Layer (e.g., GHelper)
├── logs/                        # Auto-Generated Structured Markdown Logs Target Directory
└── browser_user_data/           # Persistent User Data Storage Container Contexts
```

## 🤝 Contributing

Contributions of any shape or form are highly appreciated! Whether it's reporting bugs, opening Pull Requests, or polishing documentations, we value your feedback.

* Fork the repository
* Spin up your localized feature branch (git checkout -b feature/amazing-feature)
* Commit your modifications (git commit -m 'Add some amazing feature')
* Push upstream (git push origin feature/amazing-feature)
* Create a fresh Pull Request

## 📄 License

This asset is licensed under the terms of the MIT License. Feel free to use, modify, and distribute it globally.

## 🌟 Acknowledgements

Heartfelt thanks to @t1mb2rg for insightful exchanges that inspired core architectural elements, alongside the profound backend infrastructure of Gemini, DeepSeek, and open-source milestones like Playwright and FastAPI.

Special thanks to superuika! for participating in testing and submitting bug reports.

This utility undergoes proactive expansion and optimization. If it facilitates your workflows, drop a ⭐ to show your support! For feedback or feature suggestions, submit an Issue, or reach out directly via 1694717255@qq.com.