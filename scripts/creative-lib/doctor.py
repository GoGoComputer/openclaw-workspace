"""doctor.py — 크리에이티브 파이프라인 환경 진단."""
from __future__ import annotations
import argparse, os, shutil, sys
from pathlib import Path


def check(label: str, ok: bool, detail: str = "") -> bool:
    mark = "✓" if ok else "✗"
    color = "\033[0;32m" if ok else "\033[0;31m"
    print(f"  {color}{mark}\033[0m {label:<30}  {detail}")
    return ok


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--home", required=True)
    args = ap.parse_args()
    home = Path(args.home)

    print("== Creative pipeline doctor ==")
    fails = 0

    fails += not check("CREATIVE_HOME 존재", home.is_dir(), str(home))
    for d in ("refs", "prompts", "out", "profiles", "logs"):
        fails += not check(f"{d}/", (home / d).is_dir())
    fails += not check(".env", (home / ".env").is_file())
    venv = home / ".venv"
    fails += not check("venv", (venv / "bin" / "python").is_file())

    for p in ("banana-1", "banana-2", "banana-3", "banana-4"):
        path = home / "profiles" / p
        has_state = path.is_dir() and any(path.iterdir())
        check(f"profile {p}", has_state, "logged-in" if has_state else "empty — `creative banana-login`")

    fails += not check("gallery-dl", shutil.which("gallery-dl") is not None)
    fails += not check("imagemagick (mogrify)", shutil.which("mogrify") is not None)
    fails += not check("jq", shutil.which("jq") is not None)

    # Ollama daemon
    try:
        import requests
        r = requests.get("http://127.0.0.1:11434/api/tags", timeout=2)
        models = [m["name"] for m in r.json().get("models", [])]
        check("Ollama daemon", True, f"{len(models)} models")
        env_text = (home / ".env").read_text() if (home / ".env").exists() else ""
        for needle in ("qwen2.5vl", "qwen2.5-coder"):
            present = any(needle in m for m in models)
            check(f"  model with '{needle}'", present,
                  "" if present else f"`ollama pull {needle}:7b`")
    except Exception as e:
        check("Ollama daemon", False, str(e))
        fails += 1

    print("\n결과:", "OK" if fails == 0 else f"{fails} 항목 미흡")
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
