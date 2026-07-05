import asyncio
import json
import os
import sys
import argparse
from contextlib import asynccontextmanager
from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel
from playwright.async_api import async_playwright
import socket
import httpx 
from datetime import datetime

# ==================== 🌐 极轻量全球多语言基础设施 ====================
try:
    import locale
    # 优先使用现代且兼容的 getlocale 抓取
    sys_lang = locale.getlocale()[0]
    if not sys_lang:
        # 针对部分终端环境的健壮性兜底
        sys_lang = locale.getencoding()
        
    if sys_lang and "zh" in sys_lang.lower():
        CURRENT_LANG = "zh"
    else:
        CURRENT_LANG = "en"
except Exception:
    CURRENT_LANG = "en"

# 读取 i18n 字典包
I18N_DATA = {}
i18n_path = "config/i18n.json"
if os.path.exists(i18n_path):
    try:
        with open(i18n_path, "r", encoding="utf-8") as f:
            I18N_DATA = json.load(f)
    except Exception as e:
        print(f"[I18N WARN] Load i18n.json failed: {e}")

def _(key: str, *args) -> str:
    """ 🚀 全局万能多语言骨架包装器 """
    lang_dict = I18N_DATA.get(CURRENT_LANG, I18N_DATA.get("en", {}))
    text = lang_dict.get(key, I18N_DATA.get("en", {}).get(key, key))
    if args:
        try:
            return text.format(*args)
        except Exception:
            return text
    return text

# ---- 下游广播配置 ----
async def broadcast_stream(node_type: str, label: str, text_chunk: str, is_finished: bool = False):
    webhooks_path = "config/webhooks.json"
    urls = []
    if os.path.exists(webhooks_path):
        try:
            with open(webhooks_path, "r", encoding="utf-8") as f:
                urls = json.load(f).get("downstream_webhooks", [])
        except Exception as e:
            print(_("warn_read_webhook_failed", e))
            
    if not urls:
        return

    payload = {
        "site": current_global_site,
        "type": node_type,
        "label": label,
        "chunk": text_chunk,
        "is_finished": is_finished
    }
    
    async with httpx.AsyncClient() as client:
        tasks = [client.post(url, json=payload, timeout=1.0) for url in urls]
        await asyncio.gather(*tasks, return_exceptions=True)

# ---- 自动寻找可用端口的函数 ----
def find_available_port(start_port: int = 8000, max_tries: int = 20) -> int:
    for port in range(start_port, start_port + max_tries):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except socket.error:
                print(_("info_port_occupied", port))
                continue
    raise RuntimeError(_("err_all_ports_occupied", start_port, max_tries))

# ==================== 日志持久化 system ====================
class MarkdownLogger:
    def __init__(self, site_name: str):
        self.site_name = site_name
        self.log_dir = "logs"
        os.makedirs(self.log_dir, exist_ok=True)
        
        date_str = datetime.now().strftime("%Y%m%d")
        safe_site_name = self.site_name.replace(" ", "_")
        self.file_path = os.path.join(self.log_dir, f"{date_str}_{safe_site_name}.md")
        
        self.prompt_text = ""
        self.full_think = ""
        self.full_output = ""
        
        if not os.path.exists(self.file_path):
            with open(self.file_path, "w", encoding="utf-8") as f:
                f.write(f"# 🤖 Global Chat Session Log - {self.site_name}\n")
                f.write(f"> Create Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

    def init_turn(self, prompt: str):
        self.prompt_text = prompt
        self.full_think = ""
        self.full_output = ""

    def append_chunk(self, node_type: str, chunk: str):
        if node_type == "think":
            self.full_think += chunk
        elif node_type == "final_output":
            self.full_output += chunk

    def finalize_turn(self):
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(self.file_path, "a", encoding="utf-8") as f:
            f.write(f"\n---\n\n")
            f.write(f"### 👤 User Prompt ({now_str})\n")
            f.write(f"> {self.prompt_text}\n\n")
            if self.full_think:
                f.write(f"### 🧠 Thought Chain ({now_str})\n```text\n{self.full_think.strip()}\n```\n\n")
            f.write(f"### 🤖 Assistant Output ({now_str})\n{self.full_output.strip()}\n\n")
        print(_("info_turn_appended", self.file_path))

# ==================== 1. 全局浏览器与会话管理器 ====================
class BrowserManager:
    def __init__(self):
        self._pw = None
        self.context = None
        self.page = None
        self.user_data_dir = os.path.abspath("./browser_user_data")
        self.headless = False  

    async def start(self):
        self._pw = await async_playwright().start()
        ghelper_path = os.path.abspath("extensions/ghelper")
        manifest_path = os.path.join(ghelper_path, "manifest.json")
        has_extension = os.path.exists(manifest_path)
        
        launch_args = [
            "--disable-blink-features=AutomationControlled", 
            "--no-sandbox"
        ]
        
        mode_str = _("mode_headless") if self.headless else _("mode_visible")
        print(_("info_browser_loading", mode_str, self.user_data_dir))
        
        if has_extension:
            print(_("info_ghelper_detected"))
            launch_args.extend([
                f"--disable-extensions-except={ghelper_path}",   
                f"--load-extension={ghelper_path}"               
            ])
        else:
            print("\n" + "!"*50)
            print(_("tip_no_ghelper"))
            print("!"*50 + "\n")

        self.context = await self._pw.chromium.launch_persistent_context(
            user_data_dir=self.user_data_dir,
            headless=self.headless,  
            args=launch_args
        )
        self.page = self.context.pages[0] if self.context.pages else await self.context.new_page()
        print(_("info_browser_init_success"))

    async def stop(self):
        if self.context: await self.context.close()
        if self._pw: await self._pw.stop()
        print(_("info_browser_close_success"))

# ==================== 2. 动态网站解析器 ====================
class GenericScraper:
    def __init__(self, config_name: str, browser_page):
        config_name = config_name.replace(".json", "")
        config_path = f"config/{config_name}.json"
        
        if not os.path.exists(config_path):
            raise FileNotFoundError(_("err_config_not_found", config_name))
            
        with open(config_path, "r", encoding="utf-8") as f:
            self.config = json.load(f)
            
        self.page = browser_page
        self.selectors = self.config["selectors"]
        self.logger = MarkdownLogger(self.config['site_name'])

    async def execute(self, prompt_text: str):
        self.logger.init_turn(prompt_text)
        current_url = self.page.url
        if self.config["base_url"] not in current_url:
            print(_("info_navigating", self.config["base_url"]))
            await self.page.goto(self.config["base_url"])
        
        print(_("info_input_box_detect", self.selectors['input_box']))
        await self.page.wait_for_selector(self.selectors["input_box"])
        input_locator = self.page.locator(self.selectors["input_box"])
        
        await input_locator.click()
        await input_locator.focus()
        await input_locator.fill("") 
        await input_locator.press_sequentially(prompt_text, delay=15) 
        await asyncio.sleep(0.3)

        ai_container_selector_pre = self.selectors.get("ai_answer_container", "")
        pre_send_count = 0
        if ai_container_selector_pre:
            try:
                existing = await self.page.query_selector_all(ai_container_selector_pre)
                pre_send_count = len(existing)
            except Exception:
                pass

        if self.selectors.get("enter_to_submit", True):
            await self.page.keyboard.press("Enter")
        else:
            await self.page.click(self.selectors["submit_button"])    
        
        print(_("info_prompt_sent", self.config['site_name'], prompt_text, pre_send_count))

        ai_container_selector = self.selectors.get("ai_answer_container", "")
        if ai_container_selector:
            target_count = pre_send_count + 1
            print(_("info_waiting_new_wrapper", target_count))
            
            new_container_found = False
            start_time = asyncio.get_event_loop().time()
            timeout = 30.0  
            
            while (asyncio.get_event_loop().time() - start_time) < timeout:
                try:
                    current_containers = await self.page.query_selector_all(ai_container_selector)
                    current_count = len(current_containers)
                except Exception:
                    current_count = 0
                    
                if current_count > pre_send_count:
                    new_container_found = True
                    print(_("info_captured_wrapper", current_count))
                    break
                    
                await asyncio.sleep(0.1)  
                
            if not new_container_found:
                print(_("err_wrapper_timeout"))
                return
        await self.track_stream(pre_send_count)

    async def track_stream(self, pre_send_count: int = 0):
        ai_container_selector = self.selectors.get("ai_answer_container")
        markdown_rules = self.selectors.get("markdown_rules", {})
        thought_done_selector = self.selectors.get("wait_for_thought_done_selector")

        if not ai_container_selector:
            print(_("err_missing_container_selector"))
            return

        try:
            all_wrappers = await self.page.query_selector_all(ai_container_selector)
            if not all_wrappers or len(all_wrappers) <= pre_send_count:
                await asyncio.sleep(0.3)
                all_wrappers = await self.page.query_selector_all(ai_container_selector)
                
            if not all_wrappers:
                print(_("err_cannot_locate_container"))
                return
                
            current_wrapper = all_wrappers[-1]  
            print(_("info_target_wrapper_locked"))

            last_length = 0
            stable_count = 0

            if thought_done_selector:
                loop_count = 0
                while loop_count < 150:
                    has_done_node = await current_wrapper.query_selector(thought_done_selector)
                    if not has_done_node:
                        if loop_count % 15 == 0: 
                            print(_("info_ai_thinking"))
                        await asyncio.sleep(0.2)
                        loop_count += 1
                        continue
                    else:
                        print(_("info_thinking_node_captured"))
                        think_node = await current_wrapper.query_selector("div.thinking-container")
                        if think_node:
                            think_text = await think_node.inner_text()
                            self.logger.append_chunk("think", think_text)
                        break

            while True:
                current_text = (await current_wrapper.inner_text()).strip()
                current_length = len(current_text)
    
                if current_length == 0:
                    await asyncio.sleep(0.1)
                    continue
    
                if current_length > last_length:
                    if stable_count > 0:
                        print(_("info_stream_active_tokens"))
                    stable_count = 0  
                    last_length = current_length
                else:
                    stable_count += 1
        
                if stable_count >= 25:
                    print(_("info_text_solidified", stable_count))
                    break
        
                await asyncio.sleep(0.1)

            print(_("info_parsing_final_text"))

        except Exception as e:
            print(_("err_container_bind_failed", e))
            return

        final_markdown = ""
        combined_selector = ", ".join(markdown_rules.keys())
        
        try:
            all_elements = await current_wrapper.query_selector_all(combined_selector)
            
            for element in all_elements:
                raw_text = await element.inner_text()
                raw_text_stripped = raw_text.strip()
                if not raw_text_stripped:
                    continue
                
                if raw_text_stripped in final_markdown:
                    continue
                
                matched_rule = None
                for selector_key, rule in markdown_rules.items():
                    is_match = await element.evaluate(f"(node, sel) => node.matches(sel)", selector_key)
                    if is_match:
                        matched_rule = rule
                        break
                
                if matched_rule:
                    formatted_part = f"{matched_rule.get('prefix', '')}{raw_text_stripped}{matched_rule.get('suffix', '')}"
                    if formatted_part not in final_markdown:
                        final_markdown += formatted_part
                else:
                    final_markdown += f"{raw_text_stripped}\n\n"
            
            final_markdown = final_markdown.replace("\n\n\n", "\n\n")
            
        except Exception as e:
            print(_("err_full_extraction_failed", e))

        if final_markdown:
            self.logger.append_chunk("final_output", final_markdown)
            
            print("\n" + "="*20 + f" {_('title_extracted_result')} " + "="*20)
            print(final_markdown)
            print("="*60 + "\n")
            
            await broadcast_stream(
                node_type="final_output",
                label="text",
                text_chunk=final_markdown,
                is_finished=False
            )

        self.logger.finalize_turn()
        await broadcast_stream(node_type="sys", label="status", text_chunk="", is_finished=True)
        
# ==================== 3. 选单交互逻辑 ====================
def interactive_select_site() -> str:
    config_dir = "config"
    os.makedirs(config_dir, exist_ok=True)
    files = [f for f in os.listdir(config_dir) if f.endswith(".json") and f != "webhooks.json" and f != "i18n.json"]
    
    if not files:
        print(_("err_no_json_strategy"))
        sys.exit(1)

    print("\n" + "="*40)
    print(_("menu_welcome"))
    print(_("menu_subtitle"))
    print("="*40)
    for idx, file in enumerate(files):
        print(f" [{idx + 1}] {file.replace('.json', '')}")
    print("="*40)
    
    while True:
        try:
            choice = input(_("menu_input_hint")).strip()
            num = int(choice) - 1
            if 0 <= num < len(files):
                selected_name = files[num].replace(".json", "")
                print(_("info_selected_strategy", selected_name))
                return selected_name
        except ValueError:
            pass
        print(_("err_invalid_input"))

# ==================== 4. 系统接口与测试驱动 ====================
browser_mgr = BrowserManager()
current_global_site = "deepseek"

@asynccontextmanager
async def lifespan(app: FastAPI):
    await browser_mgr.start()  
    interactive_task = asyncio.create_task(manual_test_loop())
    yield
    interactive_task.cancel()
    await browser_mgr.stop()

app = FastAPI(title="FlexiWeb Stream Scraper", lifespan=lifespan)

class PromptRequest(BaseModel):
    site: str = "deepseek"
    prompt: str

@app.post("/api/ask")
async def ask_ai(request: PromptRequest, background_tasks: BackgroundTasks):
    try:
        scraper = GenericScraper(request.site, browser_mgr.page)
        background_tasks.add_task(scraper.execute, request.prompt)
        return {"status": "processing", "target_site": request.site}
    except FileNotFoundError as e:
        raise HTTPException(status_code=400, detail=str(e))

async def manual_test_loop():
    global current_global_site, CURRENT_LANG
    await asyncio.sleep(1)
    try:
        scraper = GenericScraper(current_global_site, browser_mgr.page)
        await browser_mgr.page.goto(scraper.config["base_url"])
    except Exception:
        pass
    print(_("sys_test_ready"))
    
    while True:
        loop = asyncio.get_running_loop()
        user_input = await loop.run_in_executor(None, input, _("prompt_input_hint", current_global_site))
        
        if user_input.strip().lower() == "exit":
            import os, signal
            os.kill(os.getpid(), signal.SIGINT)
            break
            
        # 🌐 【新增指令】：运行时无缝切换语言
        if user_input.strip() == "/lang":
            CURRENT_LANG = "en" if CURRENT_LANG == "zh" else "zh"
            print(f"\n[*] Language switched to: {CURRENT_LANG.upper()}")
            print(f"[*] 全局语言已成功切换为: {CURRENT_LANG.upper()}\n")
            continue
            
        if user_input.strip() == "/switch":
            new_site = await loop.run_in_executor(None, input, _("prompt_switch_hint"))
            if os.path.exists(f"config/{new_site}.json"):
                current_global_site = new_site
                print(_("info_switch_success", current_global_site))
            else:
                print(_("err_switch_failed"))
            continue
            
        if user_input.strip():
            try:
                scraper = GenericScraper(current_global_site, browser_mgr.page)
                await scraper.execute(user_input)
            except Exception as e:
                print(_("err_execution_failed", e))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=_("cli_desc"),
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("-s", "--site", type=str, default=None, help=_("cli_help_site"))
    parser.add_argument("-p", "--port", type=int, default=None, help=_("cli_help_port"))
    parser.add_argument("-l", "--lang", type=str, default=None, choices=["zh", "en"], help="Force system language (zh/en)")
    parser.add_argument("--headless", action="store_true", help=_("cli_help_headless"))
    
    args = parser.parse_args()

    # 🌐 【新增覆盖】：如果启动命令带有 --lang，则强行覆盖检测
    if args.lang:
        CURRENT_LANG = args.lang

    if args.site:
        if os.path.exists(f"config/{args.site}.json"):
            current_global_site = args.site
            print(_("info_cli_override", current_global_site))
        else:
            print(_("warn_cli_strategy_not_found", args.site))
            current_global_site = interactive_select_site()
    else:
        current_global_site = interactive_select_site()

    if args.headless:
        browser_mgr.headless = True

    if args.port:
        TARGET_PORT = args.port
        print(_("info_manual_port", TARGET_PORT))
    else:
        try:
            TARGET_PORT = find_available_port(start_port=8000)
            print(_("info_auto_port", TARGET_PORT))
        except RuntimeError as e:
            print(e)
            sys.exit(1)
        
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=TARGET_PORT, log_level="warning")