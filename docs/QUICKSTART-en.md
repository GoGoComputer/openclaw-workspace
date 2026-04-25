# 🚀 Quick Start for Non-Developers (English)

> This guide assumes you have **never used a terminal**. Just copy each command line by line and paste it.

## 📖 Contents

- [Prerequisites](#prerequisites)
- [1. Open Terminal](#1-open-terminal)
- [2. Get the code](#2-get-the-code)
- [3. Move into the folder](#3-move-into-the-folder)
- [4. Settings file (auto-created — nothing to do)](#4-settings-file-auto-created--nothing-to-do)
- [5. Check current state](#5-check-current-state)
- [6. Run the install](#6-run-the-install)
- [7. Verify](#7-verify)
- [8. Daily auto-update](#8-daily-auto-update)
- [9. Safe backup](#9-safe-backup)
- [Or just use the menu](#or-just-use-the-menu)
- [When something goes wrong](#when-something-goes-wrong)

---

## Prerequisites

- A **MacBook** (Apple Silicon M1 or later — reference: MacBook Pro 16" M5 Pro / 24GB RAM)
- An **internet connection**
- **At least 50GB of free disk space**
- About **30 minutes** (mostly waiting for downloads)

## 1. Open Terminal

1. Press `⌘ + Space` (Command + Spacebar)
2. Type **Terminal** and press Enter
3. A black (or white) window appears — that's your terminal

When you open Terminal you'll see something like:

```
Last login: Sat Apr 25 10:30:12 on ttys000
yourname@MacBook-Pro ~ %
```

You type commands after the `%` prompt.

## 2. Get the code

Copy this single line, paste it into Terminal, and press Enter:

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/openclaw-workspace
```

> 💡 If you don't have `git` yet, macOS pops up a dialog to install **Xcode Command Line Tools**. Click **Install** and wait (~5 min).

## 3. Move into the folder

```bash
cd ~/openclaw-workspace/openclaw-mgr
```

## 4. Settings file (auto-created — nothing to do)

When you run `./openclaw` for the first time, the `.env` settings file is created automatically. The official OpenClaw repo URL is already pre-filled.

```
✔ .env 자동 생성됨 (.env.example 기본값 적용)
```

When you see that message, you're good. **No editing required — just move straight to install.**

> 💡 If you later want to change the model, backup path, or other settings, open `openclaw-mgr/.env` in any text editor. You don't need to do this now.

## 5. Check current state

```bash
./openclaw doctor
```

You'll see red ✗ and yellow ⚠ marks — that's normal. The next step fixes them.

Example output (before install — most things missing):

```
━━━━━━━━ OpenClaw System Diagnosis ━━━━━━━━
  ✓  OS                     Darwin 15.4 arm64
  ✓  CPU                    Apple M5 Pro
  ✓  RAM                    24GB
  ✓  Disk free              142GB
  ─────────────────────────────────────────
  ✗  Xcode CLT              —
       ↳ install will set this up
  ✗  Homebrew               —
       ↳ install will set this up
  ✗  Docker                 —
       ↳ Docker Desktop required
  ⚠  Docker daemon          —
       ↳ Launch Docker Desktop
  ✗  Ollama                 —
  ─────────────────────────────────────────
  ⚠  OpenClaw repo          —
       ↳ Set OPENCLAW_REPO in .env first
  ⚠  Containers running     0
       ↳ ./openclaw start
  ─────────────────────────────────────────
  🔒 Network isolation       isolated (outbound blocked)
       ↳ Top security — flip to online during install/update
```

Colors in your real terminal: red (✗) / yellow (⚠) / green (✓).

## 6. Run the install

```bash
./openclaw install
```

What happens — just go along with it:

| Step | Action | ETA |
|---|---|---|
| Xcode CLT | System dialog appears → click **Install** | 5 min |
| Homebrew | If `Press RETURN to continue` shows, press Enter; enter password if prompted | 2 min |
| Docker Desktop | First launch shows EULA → **Accept** | 3 min |
| Install Ollama | Automatic | 1 min |
| Pull model (`qwen2.5-coder:7b`, ~4.7GB) | Automatic | 5–10 min |
| Clone OpenClaw repo | Automatic | 1 min |
| Build/start container | Automatic | 5–15 min |

Total ~**20–40 min** (mostly waiting). You can close the laptop mid-way — just rerun the same command later and it resumes from where it stopped.

## 7. Verify

```bash
./openclaw doctor
```

If everything is ✓ (green check), you're good 🎉

```bash
./openclaw logs
```

Live container logs. Stop with `Ctrl + C`.

## 8. Daily auto-update

```bash
./openclaw schedule enable
```

Updates run automatically every day at 3 AM. Disable with `./openclaw schedule disable`.

## 9. Safe backup

```bash
./openclaw backup --name fresh-install
```

A `.tar.gz` file appears in `~/openclaw-backups/`. Copy it to an external drive or cloud (after secret review).

## Or just use the menu

If you don't want to remember commands, run:

```bash
./openclaw
```

This opens an interactive menu (Korean/English auto-detected) where you pick numbers to do everything above.

## When something goes wrong

1. `./openclaw doctor` — tells you exactly what's wrong
2. [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) — common error fixes
3. Still stuck? Open a [GitHub Issue](https://github.com/GoGoComputer/openclaw-workspace/issues) with the `./openclaw doctor` output. (Secrets are auto-masked.)
