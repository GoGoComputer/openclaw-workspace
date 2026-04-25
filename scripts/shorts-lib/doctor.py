"""shorts doctor — 환경 점검."""
import os, sys, shutil, subprocess
from pathlib import Path

H = Path(os.environ["SHORTS_HOME"])
ok = True

def chk(label, cond, hint=""):
    global ok
    if cond: print(f"  \033[0;32m✔\033[0m {label}")
    else:
        ok = False
        print(f"  \033[0;31m✗\033[0m {label}" + (f"  → {hint}" if hint else ""))

print(f"== shorts doctor ({H}) ==")
chk(f"SHORTS_HOME 존재", H.exists())
for d in ["refs", "out", "logs", "profiles/miri-1", "profiles/capcut-1"]:
    chk(f"  {d}/", (H / d).exists(), "shorts setup 다시 실행")
chk(".env", (H / ".env").exists(), "shorts setup")
chk("venv", (H / ".venv" / "bin" / "python").exists(), "shorts setup")

for cmd in ["gallery-dl", "ffmpeg", "jq", "docker"]:
    chk(f"brew {cmd}", shutil.which(cmd) is not None, f"brew install {cmd}")

# ollama
import urllib.request
try:
    urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=2)
    chk("Ollama 데몬", True)
except Exception as e:
    chk("Ollama 데몬", False, "Ollama.app 실행")

print()
sys.exit(0 if ok else 1)
