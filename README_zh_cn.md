# 🌐 FlexiWeb Stream Scraper

简体中文 | [English](./README.md)

---

FlexiWeb Stream Scraper 是一个仿照各个AI企业提供的API服务，基于 **Playwright** 和 **FastAPI** 的轻量级 AI 对话流式抓取工具。它能够模仿API的功能，自动化地与各大 AI 对话网站交互，提取完整的思维链（Think）和最终输出（Final Output），并将结果实时广播到下游 Webhook 服务。

无论是用于数据收集、内容归档，还是构建 AI 中间件，FlexiWeb Stream Scraper 都能提供稳定、高效的自动化解决方案。

---

## ✨ 核心特性

- **🤖 多 AI 平台支持**  
  通过 JSON 配置文件灵活适配不同的 AI 对话网站（目前支持ChatGPT,Gemini，Deepseek，Grok，Qwen且支持自定义配置）。

- **🧠 思维链与最终输出分离**  
  自动区分并抓取 AI 的“思考过程”和“最终答案”，便于后续分析或归档。

- **📡 实时流式广播**  
  提取的内容可实时推送到下游 Webhook，方便集成到聊天机器人、监控面板或数据管道中。

- **🌍 全球多语言支持**  
  内置中英文双语界面和提示信息，可根据系统语言或启动参数自动切换。

- **🔌 一键式环境部署**  
  根据对应系统配备了一键启动的入口脚本（win_start.bat,linux_start.sh），自动匹配 Python 版本并创建干净的虚拟环境。

- **📝 Markdown 日志持久化**  
  每次对话自动生成结构化的 Markdown 日志文件，方便排查问题，查阅和分享。

---

## 🚀 快速开始

### 1. 环境准备

- 操作系统：Windows / Linux / macOS
- 已安装 PowerShell（Windows 自带，Linux/macOS 可安装）
- 网络连接（用于下载依赖和浏览器驱动）

### 2. 克隆或下载项目

点击主界面上的绿色"Code"按钮，在下拉式菜单中点击"Download ZIP"即可下载。

也可以采用如下命令，克隆git仓库：

```bash
git clone https://github.com/Eternal-Wanderer-Vegetable/FlexiWeb_Stream_Scraper.git
cd flexiweb-stream-scraper
```

### 3. 一键部署环境

为了绕过系统的脚本执行策略限制，请根据你的操作系统在项目根目录下运行对应的自动化脚本：

Windows 用户：直接双击根目录下的 win_start.bat（或在 PowerShell 中执行以下命令）
```PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File .\universal_setup.ps1
```

Linux / macOS 用户：
```bash
chmod +x ./Linux_start.sh
./Linux_start.sh
```

脚本会自动完成以下工作：

* 检测系统 Python 版本，若不匹配则自动下载安装临时Python
* 在项目目录下创建 .venv 虚拟环境
* 安装 requirements.txt 中声明的所有依赖（已对 colorama 等平台特有库做了环境隔离约束）。
* 自动安装 Playwright 的 Chromium 浏览器驱动
* 清理临时文件，不污染宿主机环境

💡 提示：若没有 requirements.txt，脚本仍会创建绝对纯净的虚拟环境，你可以后续手动安装所需包。

### 4. 配置 AI 网站策略

在 config/ 目录下，按模板创建或修改 {site_name}.json 文件。例如 deepseek.json：

```JSON
{
  "site_name": "DeepSeek",
  "base_url": "https://chat.deepseek.com/",
  "selectors": {
    "input_box": "textarea",
    "ai_answer_container": ".ds-message",
    "wait_for_thought_done_selector": ".ds-thought-done",
    "markdown_rules": {
      "div.think": { "prefix": "🧠 **思考过程:**\n", "suffix": "\n" },
      "div.final": { "prefix": "✅ **最终答案:**\n", "suffix": "\n\n" }
    }
  }
}
```

### 5. 启动服务

无需手动翻阅目录执行激活脚本，直接利用一键启动入口运行程序，或通过虚拟环境内部的编译器管道拉起，彻底杜绝系统自带的微软商店应用劫持：

```Bash
# Windows 平台
.venv\Scripts\python.exe main.py --lang zh

# Linux / macOS 平台
./.venv/bin/python main.py --lang zh
```

启动后，你将看到交互式菜单，可选择已配置的 AI 网站，并进入命令行交互界面。

### 6. 通过 API 调用

程序启动后会在本地启动 FastAPI 服务（默认端口 8000），你可以通过 HTTP POST 请求调用：

```Bash
curl -X POST "[http://127.0.0.1:8000/api/ask](http://127.0.0.1:8000/api/ask)" \
     -H "Content-Type: application/json" \
     -d '{"site": "deepseek", "prompt": "请解释一下量子计算的基本原理"}'
```

## 🛠️ 高级用法

### 命令行参数

```Bash
# Windows
.venv\Scripts\python.exe main.py [--site SITE] [--port PORT] [--lang zh|en] [--headless]

# Linux
./.venv/bin/python main.py [--site SITE] [--port PORT] [--lang zh|en] [--headless]
```

* --site：直接指定要使用的配置名称（如 deepseek），跳过交互选单。
* --port：手动指定服务端口（默认自动寻找空闲端口）。
* --lang：强制设定界面语言（zh 或 en）。
* --headless：以无头模式运行浏览器（适合服务器部署）。

### 运行时命令

在交互式提示符下，你可以输入以下特殊命令：

* exit：退出程序。
* /lang：在中文和英文界面间即时切换。
* /switch：切换当前使用的 AI 网站配置。

### 下游 Webhook 广播

若需将抓取结果推送到其他服务，请在 config/webhooks.json 中配置：

```JSON
{
  "downstream_webhooks": [
    "http://your-service.com/webhook",
    "http://another-service.com/endpoint"
  ]
}
```

每次对话完成后，系统会以 JSON 格式向所有配置的 Webhook 发送数据，包含 site、type（think/final_output）、chunk 等字段。

## 📁 项目结构

```Plaintext
flexiweb-stream-scraper/
├── main.py                      # 核心程序入口 (FastAPI + CLI Loop)
├── win_start.bat                # Windows 用户一键启动/部署入口
├── Linux_start.sh               # Linux 用户一键启动/部署入口
├── universal_setup.ps1          # 核心跨平台全自动环境构建脚本
├── requirements.txt             # 跨平台轻量化依赖清单
├── python_version.txt           # 预设期望的 Python 版本号 (如 3.11.9)
├── config/
    ├── chatgpt.json             # 内置AI网站聊天文本HTML提取配置
│   ├── deepseek.json            
    ├── ... 
│   ├── webhooks.json            # 下游 Webhook 广播配置
│   └── i18n.json                # 核心多语言本地化字典
├── extensions/                  # 浏览器扩展目录（如 GHelper）
├── logs/                        # 结构化 Markdown 日志自动输出目录
└── browser_user_data/           # 浏览器持久化用户数据上下文
```

## 🤝 贡献指南

欢迎任何形式的贡献！无论是报告 Bug、提交 Pull Request，还是完善文档，我们都非常感激。

* Fork 本仓库
* 创建你的特性分支 (git checkout -b feature/amazing-feature)
* 提交你的改动 (git commit -m 'Add some amazing feature')
* 推送到分支 (git push origin feature/amazing-feature)
* 开启一个 Pull Request

## 📄 开源协议

本项目采用 MIT License 开源协议，你可以自由使用、修改和分发。

## 🌟 致谢

感谢与@t1mb2rg交流得到的灵感，Gemini、Deepseek等优秀模型以及 Playwright 、 FastAPI 等优秀开源社区的支持。

感谢superuika！，@Skittle-Neko参与了测试工作并提交了错误报告。

感谢@Skittle-Neko对win_start.bat提出的修改意见。

本项目仍在持续开发与改进中。如果这个工具对你有帮助，别忘了点个 ⭐ 支持！如果有任何问题或建议，请提交 Issue，也可以发送邮件至1694717255@qq.com。