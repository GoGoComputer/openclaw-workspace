import os, re

files = [
    "openclaw-mgr/cmd/logs.sh",
    "openclaw-mgr/cmd/uninstall.sh",
    "openclaw-mgr/cmd/restore.sh",
    "openclaw-mgr/cmd/backup.sh",
    "openclaw-mgr/cmd/update.sh",
    "openclaw-mgr/cmd/stop.sh",
    "openclaw-mgr/cmd/start.sh",
    "openclaw-mgr/lib/detect.sh",
]

for fpath in files:
    if not os.path.exists(fpath):
        print(f"SKIP: {fpath}")
        continue
    with open(fpath, encoding="utf-8") as f:
        content = f.read()
    orig = content
    # Fix OPENCLAW_DIR default
    content = content.replace(
        'OPENCLAW_DIR:-$HOME/openclaw}',
        'OPENCLAW_DIR:-$HOME/DEV/openclaw}'
    )
    # Also fix local dir references in detect.sh
    content = content.replace(
        'OPENCLAW_DIR:-$HOME/openclaw"',
        'OPENCLAW_DIR:-$HOME/DEV/openclaw"'
    )
    if content != orig:
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Fixed: {fpath}")
    else:
        print(f"No change: {fpath}")
