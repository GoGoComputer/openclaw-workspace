# openclaw-workspace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)](#)
[![Windows (WSL2)](https://img.shields.io/badge/Windows-10%2F11_(WSL2)-0078D6?logo=windows)](#)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-arm64-blue?logo=apple)](#)
[![Shell](https://img.shields.io/badge/shell-bash%203.2%2B%20%C2%B7%20PowerShell%205.1%2B-1f425f?logo=gnu-bash)](#)
[![CI](https://img.shields.io/github/actions/workflow/status/GoGoComputer/openclaw-workspace/ci.yml?branch=main)](https://github.com/GoGoComputer/openclaw-workspace/actions)

> **OpenClaw self-host automation for macOS · Windows (WSL2) — install, maintain, and uninstall with one command.**
>
> One `./openclaw install` on a fresh MacBook sets up Docker, (optionally) Ollama, and the OpenClaw container. On Windows 10/11, run `.\openclaw.ps1 install-bootstrap` once + activate WSL2, then the same flow works identically. Idempotent: if interrupted, just rerun and it picks up where it left off. 100% local sandboxing by default.

> 🇰🇷 한국어 (메인): [README.md](README.md)

## 📖 Contents

- [🚀 5-minute start (non-developer friendly)](#-5-minute-start-non-developer-friendly)
- [🎯 Right after install — first use](#-right-after-install--first-use)
  - [① Browser web UI](#-browser-web-ui)
  - [② Container CLI](#-container-cli)
  - [③ Terminal REPL chat](#-terminal-repl-chat)
  - [Verify](#verify)
  - [🌐 Temporarily opening external network](#-temporarily-opening-external-network)
- [🤖 Automation trio — at a glance](#-automation-trio--at-a-glance)
- [📚 Documentation map](#-documentation-map)
- [🤔 What is this?](#-what-is-this)
- [📋 Command catalog](#-command-catalog)
- [💬 Terminal chat (`chat`)](#-terminal-chat-chat)
- [🤖 Models — use your existing local Ollama models](#-models--use-your-existing-local-ollama-models)
- [⚙️ Configuration (`.env`)](#️-configuration-env)
- [💻 Shell compatibility (zsh / bash)](#-shell-compatibility-zsh--bash)
- [🇰🇷 Use with Korean Sovereign AI](#-use-with-korean-sovereign-ai)
- [🧹 Memory & disk cleanup (for non-developers)](#-memory--disk-cleanup-for-non-developers)
- [🔒 Network isolation modes (explicit outbound kill switch)](#-network-isolation-modes-explicit-outbound-kill-switch)
- [🔒 Security (please read)](#-security-please-read)
- [❓ FAQ](#-faq)
- [🛠 For developers](#-for-developers)
- [📜 License](#-license)

---

## 🚀 5-minute start (non-developer friendly)

> Never used a terminal? See [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md) for a step-by-step walkthrough with example terminal output.

### Option A — Homebrew tap (for managed updates)

```bash
brew tap gogocomputer/openclaw
brew install openclaw-workspace
openclaw
```

Update: `brew update && brew upgrade openclaw-workspace`.

### Option B — git clone (run from source · for developers)

```bash
# 1) Get the code
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace/openclaw-mgr

# 2) Just run the launcher — .env is created automatically (no cp needed)
#    Running with no arguments opens the interactive menu (Korean/English auto-detected)
./openclaw

# Or run subcommands directly:
./openclaw doctor          # check current state
./openclaw install         # auto-install only what's missing
```

You may see system dialogs for Docker Desktop / Xcode CLT — just accept them. When done:

```bash
./openclaw doctor          # everything ✓ (brew install: just `openclaw doctor`)
./openclaw schedule enable # daily auto-update at 3 AM (optional)
```

> ℹ️ **Official OpenClaw repo**: `https://github.com/openclaw/openclaw` — `.env` is **created automatically on first run**. Just run `openclaw install` (or `./openclaw install`) — no manual setup needed.

> 💻 **Windows 10/11 (WSL2) users**
>
> ```powershell
> # 1) PowerShell execution policy (one-time)
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
>
> # 2) Get the code
> git clone https://github.com/GoGoComputer/openclaw-workspace.git
> cd openclaw-workspace\openclaw-mgr
>
> # 3) Bootstrap — winget · WSL2 · Git · Docker Desktop · Ollama probe/install
> .\openclaw.ps1 install-bootstrap
>
> # 4) Windows-side diagnose
> .\openclaw.ps1 doctor
>
> # 5) Install — internally delegates to 'wsl bash openclaw install'
> .\openclaw.ps1 install
> ```
>
> The Windows entry-point is a single `openclaw.ps1`. All everyday commands (`start`/`stop`/`logs`/`update`/`backup`, etc.) are auto-delegated to the bash launcher inside WSL2 and produce identical results. See each step's **"💻 Windows equivalent"** callout in [docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md) for details.

---

## 🎯 Right after install — first use

When `./openclaw install` ends with `✓ install complete!` and `🛡 sandbox active (default)`, two containers are already running:

| Container | Role | Exposed on |
|---|---|---|
| `openclaw-openclaw-gateway-1` | Web UI · REST gateway · healthz | `127.0.0.1:18789` |
| `openclaw-openclaw-cli-1` | In-container shell (where `claude` CLI runs) | (shares gateway's network namespace) |

Pick whichever entry point fits.

### ① Browser web UI

```bash
# Right after install, the network is in 'isolated' — the web UI is unreachable.
# Open it first:
./openclaw network online --restart

open http://127.0.0.1:18789
```

The most visual / approachable path. Safari or Chrome — either works. Do **not** include `open` in the address bar; `open` is a terminal command, not a URL.

> ⚠️ **Web UI is unreachable under `isolated` mode** — Docker's `internal: true` network also disables host → container port publishing (no docker-proxy). That's why `127.0.0.1:18789` shows "Safari Can't Connect" / "Empty reply" right after install. Fix: `./openclaw network online --restart`, then lock back down with `./openclaw network isolated --restart` when done.

> Still "Safari can't connect"? Run `./openclaw doctor` and check `docker ps`. Ports should show `127.0.0.1:18789->18789/tcp`. If you see just `18789/tcp` (no `host:port->` prefix), you're still in `isolated`.

### ② Container CLI (full OpenClaw stack) — `setup` → `chat`

Use the OpenClaw CLI inside an isolated container. Full feature set — channel integrations (WhatsApp / Telegram), plugins, session management. **First-time setup is one command** — `./openclaw setup` wraps OpenClaw's `onboard` wizard and runs it safely inside Docker.

```bash
# 1) First time (or any time you want to re-configure — idempotent)
./openclaw setup

# 2) Inspect current configuration (read-only)
./openclaw setup status

# 3) Once set up, full-stack chat via the container CLI
cd ~/DEV/openclaw
docker compose run --rm openclaw-cli tui            # terminal UI chat
docker compose run --rm openclaw-cli agent --message "hi"   # one-shot
```

Why `./openclaw setup`:
- **Isolated** — runs `docker compose run --rm openclaw-cli onboard`, nothing is installed on the host
- **Re-runnable** — detects existing config, confirms before re-running; Enter keeps any answer
- **Pre-flight** — checks Docker daemon + OpenClaw clone before launching the wizard
- **Hands off afterward** — `./openclaw setup status` to peek, `./openclaw chat` to chat right away

<details>
<summary><b>📋 What the wizard asks, step by step (recommended answers inside)</b></summary>

Exact order/wording depends on the OpenClaw build, but you'll generally see these stages. Enter accepts the default on every prompt; you can re-run `./openclaw setup` anytime to change anything.

| # | Stage | What you see | Recommended |
|---|---|---|---|
| 1 | **Risk acknowledgment** | `I understand this is personal-by-default and shared/multi-user use requires lock-down. Continue?` | **`Yes`** — fine for a single-user laptop. Shared/multi-user machines need additional lock-down (see the security section). |
| 2 | **Flow** | `Onboard flow: quickstart \| advanced \| manual` | **`quickstart`** — recommended. `advanced` adds steps; `manual` makes you enter everything. |
| 3 | **Mode** | `local \| remote` | **`local`** — running on this Mac. Use `remote` only if you're attaching to a gateway on another box. |
| 4 | **Gateway bind** | `loopback \| tailnet \| lan \| auto \| custom` | **`loopback`** — binds only to `127.0.0.1`, safest. Pick something else only if you understand the LAN/public exposure. |
| 5 | **Gateway port** | Defaults to `18789` | **Enter** to keep. Change only if `18789` is taken. |
| 6 | **Gateway auth** | `token \| password` | **`token`** — auto-generates a secret. |
| 7 | **Install daemon (service)** | Register gateway as a background service | **Yes** — auto-starts on reboot. `No` if you only want it inside the container. |
| 8 | **Auth provider (model backend)** | `ollama \| anthropic-api-key \| openai-api-key \| gemini-api-key \| huggingface-api-key \| custom \| skip` ... (50+ options) | **`ollama`** ← the key choice. Uses the local models you've already pulled — no API key needed. Pick a cloud provider only if you want to call hosted models (and have a key). |
| 8a | **Ollama mode** (only when provider=ollama) | `Cloud + Local \| Local only \| Cloud only` | **`Local only`** — uses just the host's local Ollama. `Cloud` requires an Ollama cloud account. |
| 8b | **Ollama base URL** ⚠️ **trap** | Default `http://127.0.0.1:11434` (editable text field) | **Must change to →** `http://host.docker.internal:11434`. Inside the container `127.0.0.1` means the container itself, not the host — so the wizard can't reach your host Ollama. `host.docker.internal` is Docker's special hostname that points back to the host. `./openclaw setup` prints a yellow box about this before launching the wizard. |
| 9 | **Workspace dir** | Where the agent reads/writes files | Default `~/.openclaw/workspace` (mirrored to `~/DEV/openclawAgent` on the host) — just press Enter. |
| 10 | **Search provider** | Web-search backend (Tavily etc.) | **`skip`** or Enter — easy to add later by re-running `setup`. |
| 11 | **Skills / plugins / channels** | Optional extra abilities (image gen, voice, …) + channel integrations (Discord, Telegram, WhatsApp, …) | Defaults or `skip` for the first run. Discord bot integration has its own walkthrough → [💬 GUIDE-DISCORD-BOT](docs/GUIDE-DISCORD-BOT.md) |
| 12 | **UI (Control Panel)** | Use the web Control Panel | **Yes** — it's already running at `127.0.0.1:18789`. |
| 13 | **Tailscale** | `off \| serve \| funnel` | **`off`** unless you actually use Tailscale to share the gateway across machines. |
| 14 | **Health check** | Auto-runs at the end | Just wait for ✓. |

**Three answers that matter most:**
- **#8 (provider)** — `ollama` means "use my local models", no API key. The most common first-time choice.
- **#8b (Ollama base URL) ⚠️ trap** — leaving the default `http://127.0.0.1:11434` makes the wizard exit with `Ollama could not be reached at http://127.0.0.1:11434` → `WizardCancelledError: Ollama not reachable`. **Always change it to** `http://host.docker.internal:11434`. `./openclaw setup` pre-flights this and prints a yellow warning box before launch so you don't forget.
- **#4 (bind)** — `loopback` is safest. Any other choice exposes the gateway to the network; understand the security trade-off first (see [🔒 Security](#-security-please-read)).

**After it finishes:**
- Settings live in `~/.openclaw/openclaw.json` (don't hand-edit — re-run the wizard instead).
- `./openclaw setup status` shows the top-level config keys.
- Chat immediately: `docker compose run --rm openclaw-cli tui` or `./openclaw chat`.

Full surface (50+ providers, advanced-flow extras): [OpenClaw upstream docs `cli/onboard`](https://docs.openclaw.ai/cli/onboard).
</details>

> ⚠️ **`run --rm`, not `exec`** — the `openclaw-cli` container's entrypoint (`node dist/index.js`) prints help and exits immediately on no-arg invocation (`docker ps -a` shows it as `Exited (1)`). `./openclaw setup` handles this internally; if you ever call it manually, always use `docker compose run --rm openclaw-cli <subcommand>`.
>
> Raw shell inside the container? `docker compose run --rm --entrypoint bash openclaw-cli`.

### ③ Terminal REPL chat — `./openclaw chat`

Talk to the agent through host Ollama directly — no container, no web UI. The workspace personality files (`IDENTITY.md` · `SOUL.md` · `USER.md`, …) get auto-loaded into the system prompt.

```bash
./openclaw chat                       # interactive model picker + auto personality
./openclaw chat -m llama3.1:8b        # pick a model directly (skips the picker)
./openclaw chat --no-pick             # skip the picker, use the .env default
./openclaw chat --no-system           # ignore personality, pure model
```

**🎯 Interactive model picker** — without `-m`, the installed Ollama models are numbered and shown:

```
  Pick an installed Ollama model:
     1) gemma4:26b                                              18.0 GB
     2) llama3.1:8b-instruct-q4_K_M                              4.9 GB  ★ default
     3) qwen2.5:3b-instruct                                      1.9 GB
     4) solar-pro:latest                                        13.3 GB
     ...

  Enter number [default: 2]:
```

- Embedding models (`nomic-embed-text`, anything tagged `embed`) are skipped — they don't chat
- Default (★): the first entry in `.env`'s `OLLAMA_MODELS` if it's installed; otherwise the first listed
- Exactly one model installed? Auto-picked. None? Prints recommended `ollama pull` commands and exits.
- Press Enter for the default, type a number, or get rejected for bad input
- Non-interactive shells (`NONINTERACTIVE=1`, piped stdin, `--no-pick`, or `-m`) skip the picker automatically

Slash commands (`/exit` `/reset` `/model` `/history` `/help`) and full details: see [💬 Terminal chat (`chat`)](#-terminal-chat-chat).

### Verify

```bash
./openclaw doctor
# Key rows to check:
#   ✓ OpenClaw repo       /Users/<you>/DEV/openclaw
#   ✓ Containers running  2 (gateway + cli)
#   ✓ Network isolation   isolated (outbound blocked)
#   ✓ Ollama daemon / models (host-side ready)
```

Any ✗? Just rerun `./openclaw install` — [`validate_state`](#idempotency-state-file) detects missing artifacts and re-runs the affected steps automatically.

### 🌐 Temporarily opening external network

Default is `isolated` (outbound blocked). For model downloads / code updates / `pip install` style work, briefly switch to `online`, then close it again — that's the standard cycle.

```bash
./openclaw network online --restart    # open + restart containers
# (do the work — ollama pull · pip install · git clone …)
./openclaw network isolated --restart  # lock it back down
```

| Situation | What to do |
|---|---|
| `./openclaw update` (code · images · models refresh) | **Automatic** — `update` flips to `online` briefly and restores the previous mode. No manual toggle needed. |
| `ollama pull <model>` from the host shell | Keep `isolated` — Ollama runs on the host, unaffected by container networking. |
| `pip install` / `npm install` / `apt-get` / `git clone` **inside** the container | Need `online --restart` for the duration. |
| Container reaching the host Ollama (`host.docker.internal:11434`) | Need `online --restart` — `isolated` blocks this too. |
| Normal chatting / work (no new downloads) | **Stay `isolated`** — no exfil channel exists, which is the whole point. |

For the security rationale and full blocked-actions list, see [🔒 Network isolation modes](#-network-isolation-modes-explicit-outbound-kill-switch).

---

## 🤖 Automation trio — at a glance

> **⚠️ Setup first, then use.** Each command below requires its setup script to be run *once* before first use. Tools that need an account (nano-banana / Figma / Miricanvas / CapCut) also need a one-time `*-login` to capture a session.

| Command | What it does | Setup → login → use | Guide |
|---|---|---|---|
| 🌐 `surf "..."` | Web search → Markdown brief inside a throwaway Docker sandbox | `bash scripts/surf-setup.sh` → (no login) → `surf "..."` | [GUIDE-WEB-FETCH.md §8](docs/GUIDE-WEB-FETCH.md#8--샌드박스-자동-브리프--surf-명령) |
| 🎨 `creative run "..."` | Pinterest → nano-banana (4 parallel windows) → Figma | `bash scripts/creative-pipeline-setup.sh` → `creative banana-login` `creative figma-login` → `creative run "..."` | [GUIDE-CREATIVE-PIPELINE.md](docs/GUIDE-CREATIVE-PIPELINE.md) |
| 🎬 `shorts run "..."` | Pinterest → Miricanvas (1080×1920) → CapCut (9:16 MP4 export) | `bash scripts/shorts-setup.sh` → `shorts miri-login` `shorts capcut-login` → `shorts run "..."` | [GUIDE-SHORTS-PIPELINE.md](docs/GUIDE-SHORTS-PIPELINE.md) |

**Common flow:**

```bash
# 1) Setup (idempotent — safe to re-run)
bash scripts/surf-setup.sh
bash scripts/creative-pipeline-setup.sh
bash scripts/shorts-setup.sh

# 2) One-time login per tool (a window opens, you log in, then close it)
creative banana-login
creative figma-login
shorts miri-login
shorts capcut-login
# (surf needs no login — RSS / public pages only)

# 3) From now on, just:
surf     "today's KOSPI close and turnover"
creative run "southeast asia landscape illustrations"
shorts   run "moody travel landscapes"
```

> All automations run on the host with persistent Chromium profiles — the OpenClaw container stays in `isolated` and never touches `~/.ssh` or the OpenClaw `.env`. See each guide's "Sandbox boundary" section.

## 📚 Documentation map

> Not sure where to start? Pick your row. Korean and English are both available.

| Who you are | Start here | What's inside |
|---|---|---|
| � **Right after install — first chat in 5 min** | [docs/GUIDE-FIRST-USE.md](docs/GUIDE-FIRST-USE.md) | What to type the moment `✓ install complete` shows: health check → UI/CLI access → first prompt → add a model → where files live → daily ops → web fetch → first-use troubleshooting. KO+EN |
| �🌱 **Truly from zero (`mkdir`, `cd`, opening Terminal)** | [docs/GUIDE-FROM-ZERO.md](docs/GUIDE-FROM-ZERO.md) | **Step −1: click vs double-click vs right-click, GUI vs CLI, window·menu bar·Dock, file·folder·path** → open Terminal → 5 essential commands → git clone install. KO+EN |
| 🦜 **Fully manual install (download from official sites)** | [docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md) | 8 stages, each with command + expected output + recovery: **0** prereq diagnose · **0.5** reuse existing Docker/Ollama · **1** Xcode CLT · **2** Docker Desktop · **3** Ollama + models · **4** git clone · **5** `./openclaw install` (`5b` fully-by-hand, `5c` sandbox) · **6** PATH + start/stop/port cheatsheet · **7** update — what to re-run after `git pull` (per change type). KO+EN |
| 🆕 **First time / never used a terminal** | [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md) | Step-by-step from "open Terminal", with sample output |
| 🇰🇷 **한국어 처음 사용자** | [docs/QUICKSTART-ko.md](docs/QUICKSTART-ko.md) | 한국어 버전 |
| 📖 **Unfamiliar with the terms (Ollama · Docker · OpenClaw)** | [docs/GUIDE-OLLAMA.md](docs/GUIDE-OLLAMA.md) · [docs/GUIDE-DOCKER.md](docs/GUIDE-DOCKER.md) · [docs/GUIDE-OPENCLAW.md](docs/GUIDE-OPENCLAW.md) | Three 3-minute primers (concepts, vocabulary, philosophy) — KO+EN |
| 🌐 **Pulling stocks · news · FX from the web** | [docs/GUIDE-WEB-FETCH.md](docs/GUIDE-WEB-FETCH.md) | Network toggle cycle, real-world prompts, official APIs, automation, troubleshooting. **Includes `surf` command — sandboxed Docker fetch → Markdown brief**. KO+EN |
| 🎨 **Designer workflow automation (Pinterest → nano-banana → Figma)** | [docs/GUIDE-CREATIVE-PIPELINE.md](docs/GUIDE-CREATIVE-PIPELINE.md) | 4-step manual → one command. 4 parallel nano-banana windows for ~3.7× speedup. KO+EN |
| 🎬 **Shorts automation (Pinterest → Miricanvas → CapCut)** | [docs/GUIDE-SHORTS-PIPELINE.md](docs/GUIDE-SHORTS-PIPELINE.md) | `shorts run "keyword"` for refs · 1080×1920 design · 9:16 MP4 export. Sandbox boundary kept; install instructions included. KO+EN |
| 💬 **Run OpenClaw as a Discord bot** | [docs/GUIDE-DISCORD-BOT.md](docs/GUIDE-DISCORD-BOT.md) | Stand up the agent as a Discord bot — mention/DM/slash commands. Create app → Message Content Intent → OAuth2 invite → token paste → first test → security + troubleshooting. Mirrors the setup wizard's Discord stage. |
| 👤 **General user** | [README.en.md](README.en.md) (this file) | Command catalog · `.env` · network isolation · FAQ |
| 🇰🇷 **일반 사용자 (KO)** | [README.md](README.md) | Korean main README |
| 🛡 **Security-minded** | [SECURITY.md](SECURITY.md) · [🔒 Security section](#-security-please-read) · [🔒 Network isolation](#-network-isolation-modes-explicit-outbound-kill-switch) | Threat model, vulnerability reporting |
| 🧠 **Want to know how it works** | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Dispatcher, idempotent design, compose overrides (bilingual) |
| 🚑 **When things break** | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common errors and fixes (bilingual) |
| 🤝 **Want to contribute (first time)** | [docs/GUIDE-CONTRIBUTING.md](docs/GUIDE-CONTRIBUTING.md) | Non-developers welcome — typos, translation, beta-testing |
| 🐙 **Want to contribute (code)** | [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Code style, PR process (bilingual) |
| 📦 **Release notes** | [docs/RELEASE_NOTES_v0.1.0.md](docs/RELEASE_NOTES_v0.1.0.md) | What changed (bilingual) |
| 🍺 **Homebrew tap** | [github.com/GoGoComputer/homebrew-openclaw](https://github.com/GoGoComputer/homebrew-openclaw) | brew formula repo |

---

## 🤔 What is this?

[**OpenClaw**](https://clawbro.ai) is a powerful open-source AI agent that can run shell commands, touch files, and browse the web on your behalf. Because of that power, you must run it inside a Docker sandbox. This project automates the setup on a brand-new macOS or Windows (WSL2) machine.

| What this tool does | What it doesn't |
|---|---|
| Auto-installs Homebrew · Docker · Ollama | Develop OpenClaw itself |
| Clones the OpenClaw repo & boots containers | Cloud hosting (see [ClawBro.ai](https://clawbro.ai)) |
| Daily auto-update (launchd · Windows Task Scheduler) | Native Linux auto-install (outside WSL) |
| Windows 10/11 (WSL2 delegation + PowerShell entry-point) | Multi-instance |
| Backup · restore · clean uninstall | |
| Security hardening (read-only, cap_drop, 127.0.0.1-only, ...) | Channel integrations (Telegram, etc.) |

---

## 📋 Command catalog

| Command | Description |
|---|---|
| `./openclaw` (or `menu`) | Interactive menu (auto KO/EN) — pick a number to do anything |
| `./openclaw setup [status]` | First-time / re-run OpenClaw onboard wizard, safely inside Docker (idempotent — re-runnable anytime) |
| `./openclaw chat [-m MODEL]` | Terminal REPL chat with the agent (interactive model picker + auto-loads `IDENTITY`/`SOUL`/`USER`) |
| `./openclaw doctor` | Diagnose installed/running state (✓/✗/⚠ table) |
| `./openclaw install` | Idempotent install. Resumes after interruption |
| `./openclaw start` | Start container |
| `./openclaw stop` | Stop container (data preserved) |
| `./openclaw logs [service]` | Tail container logs (auto secret masking) |
| `./openclaw update` | `git pull --ff-only` + image refresh + Ollama models |
| `./openclaw backup [--name N]` | Volumes + `.env` (sha256, optional GPG encryption) |
| `./openclaw restore <file>` | Verified safe restore (checksum + traversal check) |
| `./openclaw schedule enable\|disable\|status` | Daily auto-update via launchd |
| `./openclaw network status\|isolated\|online` | Toggle outbound internet (default: isolated) |
| `./openclaw models list\|add\|remove\|pull\|suggest` | Manage local Ollama models (auto-edits `.env`) |
| `./openclaw clean [--light\|--all\|--status]` | Memory & disk cleanup (interactive, non-developer friendly) |
| `./openclaw uninstall [--purge]` | Remove. `--purge` also removes Docker/Ollama |

---

## 💬 Terminal chat (`chat`)

Talk to the agent directly via the host Ollama — **no container, no web UI** required. Pull a model and say "hi" immediately.

```bash
./openclaw chat                          # interactive model picker + auto personality
./openclaw chat -m llama3.1:8b           # pick a model directly (skips the picker)
./openclaw chat --no-pick                # skip the picker, use the .env default
./openclaw chat --no-system              # ignore personality files, pure model
./openclaw chat --host http://127.0.0.1:11434   # custom Ollama host
```

**🎯 Interactive model picker** — without `-m`, the script queries `ollama list` and shows a numbered menu:

- Embedding models (`*-embed-*`) are filtered out — they can't chat
- Default star (★): the first entry in `.env`'s `OLLAMA_MODELS` if it's installed
- One installed model → auto-picked; zero installed → prints recommended `ollama pull` commands and exits
- Press Enter for the default, type a number, or get rejected on bad input
- Non-interactive contexts (`NONINTERACTIVE=1`, piped stdin, `--no-pick`, `-m`) skip the picker

**Slash commands inside the REPL**

| Command | Effect |
|---|---|
| `/exit` · `/quit` · `/q` | Quit |
| `/reset` | Clear conversation context (system prompt is preserved) |
| `/model <name>` | Switch model on the fly |
| `/history` | Show current system/user/assistant message counts |
| `/help` · `/?` | Show help |

**Auto-loaded personality** — if `$OPENCLAW_WORKSPACE_DIR` (default `~/DEV/openclawAgent`) contains any of the following, they are concatenated into the system prompt:

- `IDENTITY.md` — the agent's name, kind, voice
- `SOUL.md` — values, attitude, red lines
- `USER.md` — notes about you (the human)
- `AGENTS.md` — workspace operating rules
- `MEMORY.md` — long-term memory (when present)

The agent remembers its name and what it knows about you across sessions. If none of these exist, it behaves like a generic assistant.

**Requirements** — host Ollama running + the chosen model pulled locally.

```bash
./openclaw doctor                                  # check state
./openclaw models add qwen2.5-coder:7b             # pull a model if needed
./openclaw chat                                    # start chatting
```

> ℹ️ Works regardless of `network isolated` mode — chat talks to **host Ollama** directly, not via the container.

---

## 🤖 Models — use your existing local Ollama models

> **Key fact**: the OpenClaw container shares your host's Ollama (`host.docker.internal:11434`). **Models you already pulled with `ollama pull` are reused as-is** — nothing to re-download. The list below just illustrates the wiring.

```
Your Mac                                       OpenClaw container
┌──────────────────────────────┐                  ┌──────────────────────┐
│ ollama list                  │ <─── same ───> │ host.docker.internal │
│  • solar-pro                 │    Ollama        │      :11434          │
│  • exaone4.0                 │    daemon        │  (these are usable   │
│  • qwen2.5-coder:7b          │                  │   inside OpenClaw)   │
└──────────────────────────────┘                  └──────────────────────┘
```

### Non-developer mode (one-line commands)

```bash
openclaw models                  # show .env entries + every model on your host
openclaw models suggest          # curated picks for 24GB Apple Silicon
openclaw models add llama3.1:8b  # append to .env + auto `ollama pull`
openclaw models remove llama3.1:8b           # remove from .env (model file kept)
openclaw models remove llama3.1:8b --purge   # also `ollama rm`
openclaw models pull llava:7b    # pull only — no .env change
```

In the interactive menu, choose **option 14** — "List / add models". You never need to open `.env` by hand.

### Developer mode (edit directly or use the host)

Any of these works:

1. **Edit `.env` and run update** (containers refresh too):
   ```bash
   $EDITOR ~/.openclaw-mgr/.env   # OLLAMA_MODELS="qwen2.5-coder:7b,llama3.1:8b"
   openclaw update
   ```
2. **Just `ollama pull` on the host** — OpenClaw picks it up immediately (selectable in the UI):
   ```bash
   ollama pull qwen2.5:14b
   ```
3. **`openclaw models add ... --no-pull`** — register the name now, fetch on next update.

### ⚠️ Caveat: `isolated` mode blocks the host Ollama too

In the default `isolated` mode the container has **no network at all**, including to your host's Ollama. To use local LLMs:

```bash
openclaw network online --restart    # temporarily allow
# … work …
openclaw network isolated --restart   # lock back down (recommended default)
```

> 💡 `openclaw update` flips the mode to `online` **automatically** for the duration, then restores it. `openclaw models add` runs `ollama pull` on the host (not inside the container), so it works regardless of the container's network mode — it only needs host internet.

---

## ⚙️ Configuration (`.env`)

Every variable in `.env.example` is commented. Highlights:

```bash
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"  # official URL
OPENCLAW_DIR="$HOME/openclaw"                             # clone target
OPENCLAW_PORT="8000"                                      # always bound to 127.0.0.1
ENABLE_OLLAMA="1"                                         # 0 = external API only
OLLAMA_MODELS="qwen2.5-coder:7b"                          # comma-separated
OPENCLAW_PIN_COMMIT=""                                    # security: pin a commit
SCHEDULE_TIME="03:00"                                     # daily auto-update
BACKUP_DIR="$HOME/openclaw-backups"
BACKUP_KEEP="7"                                           # rotate old backups
BACKUP_ENCRYPT="1"                                        # GPG-encrypt .env
```

---

## 💻 Shell compatibility (zsh / bash)

macOS uses **zsh** by default. All scripts here start with `#!/usr/bin/env bash`, so they always run under bash regardless of the user's shell. **zsh users can use this tool directly with no changes.**

```zsh
# Works the same in zsh:
./openclaw doctor
./openclaw install
```

You never `source` these scripts, so `source`/`.` compatibility is a non-issue.

---

## 🇰🇷 Use with Korean Sovereign AI

Sister project [**korea-sovereign-ai**](https://github.com/GoGoComputer/korea-sovereign-ai) (LG EXAONE / SKT A.X / Upstage Solar) by the same maintainer is **naturally compatible**. Both share the host Ollama, so once Korean models are installed, OpenClaw can use them as-is.

```bash
# Optionally install Korean Sovereign AI first
git clone https://github.com/GoGoComputer/korea-sovereign-ai.git ~/DEV/llmDev/korea-ai
cd ~/DEV/llmDev/korea-ai && ./install.sh --minimal     # EXAONE + A.X (~5GB)

# Then register them in OpenClaw with one command (auto-edits .env):
openclaw models add exaone3.5:7.8b solar-pro:22b
```

`./openclaw doctor` auto-detects Korean models and shows them in the report. With 24GB RAM, keep only one model loaded at a time (use `./openclaw clean` to unload others).

---

## 🧹 Memory & disk cleanup (for non-developers)

Docker and Ollama accumulate caches and unused images over time. One command to clean up:

```bash
./openclaw clean --status   # report only
./openclaw clean            # interactive — asks y/n at each step (safe)
./openclaw clean --light    # caches + stopped containers only (fast, safe)
./openclaw clean --all      # aggressive: unused images/models + macOS purge
```

`--all` only asks for `sudo` once (for `sudo purge` — macOS unified memory compression). Your data (volumes, `.env`, backups) is never touched.

---

## 🔒 Network isolation modes (explicit outbound kill switch)

**Outbound traffic is fully blocked by default.** Only open it briefly for installs/updates.

```bash
./openclaw network status                  # current mode
./openclaw network online --restart        # open temporarily (install/update)
./openclaw network isolated --restart      # close again ← keep this as the steady state
```

| Mode | Outbound (container→internet) | Web UI (127.0.0.1:18789) | host Ollama | When to use |
|---|---|---|---|---|
| **`isolated`** 🔒 (default) | Fully blocked | **Not reachable** ✗ | Blocked | Terminal-only workflow — maximum security |
| **`online`** 🌐 | Allowed | ✓ | ✓ | **Web UI / install / update / model pulls** |

> ⚠️ **Docker caveat**: when a container is connected only to an `internal: true` network, Docker also disables port publishing (no docker-proxy). So under `isolated` there's no path from the host to `127.0.0.1:18789` either. **If you want the web UI, flip to `online` first**: `./openclaw network online --restart`. Lock back down with `./openclaw network isolated --restart` once done.

### What `isolated` (default) **blocks**
- All outbound DNS and IP traffic from inside the container.
- **Host → container inbound (web UI ports)** — Docker also disables port publishing.
- Therefore the following are blocked (flip to `online` if needed):
  - **Browser web UI** (`http://127.0.0.1:18789`) — inbound also dropped
  - `pip install <pkg>`, `npm install`, `apt-get update`
  - `git clone https://github.com/...` and other GitHub/GitLab pulls
  - Hugging Face / pypi / docker registry downloads
  - **host Ollama** (`host.docker.internal:11434`)
  - **Any data exfiltration attempt** (malicious prompt-injection "upload my files to X" is physically impossible)

### What still **works** under `isolated`
- `./openclaw chat` — talks to host Ollama directly (bypasses the container)
- `docker compose run --rm openclaw-cli tui` — CLI inside the container (independent of port publishing)
- Workspace file read/write
- Models and code already inside the container

### When this matters
- **High-stakes security**: when an AI agent browses the web, downloads code, or installs packages, the entire fetch path is removed — nothing malicious can be pulled in.
- **Defense against exfil**: even if a prompt instructs "send my file to attacker.com", there's no network path out.
- **Public Wi-Fi**: cafes, airports — outside↔container traffic is fully cut, so safe.

### Standard install/update workflow
```bash
./openclaw network online --restart    # briefly open
./openclaw update                       # update
./openclaw network isolated --restart   # close again immediately
```

> `./openclaw update` automates this (auto-flip to online → update → restore previous mode).

---

## 🔒 Security (please read)

OpenClaw agents have direct shell + filesystem access. To use it safely:

1. **Never bypass the Docker sandbox** — installing OpenClaw on the host directly is unsafe.
2. **Do not mount sensitive folders.** Especially: `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.config`, `~/Library`, `/etc`, `/var`, `/usr`.
3. **Never commit `.env`.** Already in `.gitignore`. If accidentally pushed, rotate keys immediately.
4. **Don't set `OLLAMA_HOST=0.0.0.0`** — `host.docker.internal` is sufficient on Mac. `0.0.0.0` exposes models on LAN/public Wi-Fi.
5. **Use `OPENCLAW_PIN_COMMIT`** — pinning to a verified commit hardens against supply-chain attacks.
6. **All ports bind to `127.0.0.1`** — enforced by `compose.security.yml`.
7. **`.env` in backups** is GPG-encrypted by default (`BACKUP_ENCRYPT=1`).
8. **Vulnerability reports** — please follow [SECURITY.md](SECURITY.md), not public issues.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the threat model and container hardening details.

---

## ❓ FAQ

<details>
<summary><b>Docker Desktop won't start</b></summary>

`./openclaw install` runs `open -a Docker` automatically, but the first launch requires accepting the EULA. After that, rerun `./openclaw install` and it resumes.
</details>

<details>
<summary><b>Port 11434 is already in use</b></summary>

Another Ollama instance may be running.
```bash
lsof -nP -iTCP:11434 -sTCP:LISTEN
brew services restart ollama
```
</details>

<details>
<summary><b>How do I switch Ollama models?</b></summary>

Easiest: `openclaw models add <name>` (auto-edits `.env` + pulls). To see what you already have locally and what's configured, run `openclaw models`. For a curated list: `openclaw models suggest`. The manual route still works — edit `OLLAMA_MODELS` in `.env`, then `./openclaw update`. With 24GB RAM, 7–8B models are recommended; 13B+ triggers a confirmation prompt.
</details>

<details>
<summary><b>Where are backups stored?</b></summary>

`~/openclaw-backups/openclaw-YYYYmmdd-HHMMSS-<name>.tar.gz` (with `.sha256`). Override via `BACKUP_DIR` in `.env`. Retention via `BACKUP_KEEP` (default 7).
</details>

<details>
<summary><b>How do I uninstall completely?</b></summary>

```bash
./openclaw backup --name before-uninstall   # safety
./openclaw uninstall --purge                # also removes Docker/Ollama
```
</details>

<details>
<summary><b>I interrupted the install. What now?</b></summary>

Just rerun `./openclaw install`. Already-completed steps are marked `[skip]` and only the rest runs. State file: `~/.openclaw-mgr/state`.
</details>

<details>
<summary><b>Setup wizard exits with <code>Ollama not reachable</code> — but my host Ollama is running fine</b></summary>

When the wizard reaches **"Ollama base URL"** and you accept the default `http://127.0.0.1:11434`, it dies with `Ollama could not be reached at http://127.0.0.1:11434` → `WizardCancelledError: Ollama not reachable`.

Why: the wizard runs **inside a container**, where `127.0.0.1` resolves to the container itself, not the host. From inside the container, the host Ollama is reachable at `host.docker.internal:11434`.

Fix — at that prompt, replace the default with **`http://host.docker.internal:11434`**:

```
Ollama base URL
> http://host.docker.internal:11434       ← clear the 127.0.0.1 default and type this
```

`./openclaw setup` (v0.2.8+) pre-flights this and prints a yellow warning box about the trap before launching the wizard. If you missed it, just rerun `./openclaw setup` — it's idempotent.

Verify:
```bash
# Can the container see the host Ollama?
cd ~/DEV/openclaw
docker compose run --rm --entrypoint sh openclaw-cli \
  -c 'curl -sf http://host.docker.internal:11434/api/tags | head -c 80'
# {"models":[...  ← OK if you see this
```

> Note: OpenClaw upstream doesn't honor any env var or CLI flag for this URL — it can only be entered via the wizard prompt. So `setup.sh` can't inject the right value; clear pre-flight guidance is the best we can do.

<details>
<summary>🔬 Technical background — reachability proof + why we can't auto-fix it</summary>

**Direct `curl` from inside the cli container:**

| URL | Reachable? | Why |
|---|---|---|
| `http://127.0.0.1:11434` (wizard default) | **✗ NOT REACHABLE** | Loopback inside the container points to the container itself |
| `http://host.docker.internal:11434` (correct) | **✓ REACHABLE** | Docker Desktop's special hostname injected into containers; points back to the host machine |

Reproduce:
```bash
cd ~/DEV/openclaw
docker compose run --rm --entrypoint sh openclaw-cli -c '
  curl -sf --max-time 3 http://127.0.0.1:11434/api/tags && echo OK_127 || echo FAIL_127;
  curl -sf --max-time 3 http://host.docker.internal:11434/api/tags >/dev/null && echo OK_HDI || echo FAIL_HDI
'
# → FAIL_127
#   OK_HDI
```

**No upstream escape hatch — evidence:**

1. **No env var lookup** — grep `/app/dist` for `process.env.OLLAMA*`:
   ```bash
   docker compose run --rm --entrypoint sh openclaw-cli -c \
     'grep -hroE "process\.env\.[A-Z_]*OLLAMA[A-Z_]*" /app/dist | sort -u'
   # → (no output. No OLLAMA URL env lookup at all)
   ```
   `OLLAMA_API_KEY` is read but only for auth, not for the URL.

2. **No CLI flag** — `onboard --help` doesn't include `--ollama-base-url`:
   ```
   --custom-base-url <url>    # only for the 'custom' provider, not ollama
   --auth-choice ... ollama   # this picks ollama as the provider; doesn't set the URL
   ```

3. **Hardcoded prompt** — wizard source (`/app/dist/setup-CtbggUuv.js`):
   ```js
   async function promptForOllamaBaseUrl(prompter) {
     return resolveOllamaApiBase((await prompter.text({
       message: "Ollama base URL",
       initialValue: "http://127.0.0.1:11434",   // ← hardcoded
       placeholder: "http://127.0.0.1:11434",
       validate: (value) => value?.trim() ? void 0 : "Required"
     }) ?? "").trim().replace(/\/+$/, ""));
   }
   ```
   The `OLLAMA_DEFAULT_BASE_URL` is also a plain constant (`/app/dist/defaults-JS7ic3Yx.js`):
   ```js
   const OLLAMA_DEFAULT_BASE_URL = "http://127.0.0.1:11434";
   ```

**Conclusion**: no env var, no CLI flag, and the prompt's `initialValue` is hardcoded — so `setup.sh` has no way to inject the correct URL before the wizard launches. v0.2.8's fix is the best alternative: **pre-flight reachability check + a loud yellow warning box** telling the user the exact value to type.

**What `setup.sh` actually does before launching the wizard** (`cmd/setup.sh` v0.2.8):

```
1) docker compose run --rm --no-deps openclaw-cli curl http://host.docker.internal:11434/api/tags
   → response OK  → host_ollama_ok=1
   → response NOK → host_ollama_ok=0
2) If OK, print a yellow box:
   ┌─────────────────────────────────────────────────────────────┐
   │ ⚠  When the wizard reaches "Ollama base URL", enter:        │
   │    http://host.docker.internal:11434                         │
   │ The default http://127.0.0.1:11434 points at the container  │
   │ itself, not the host — so it can't reach your local Ollama. │
   └─────────────────────────────────────────────────────────────┘
3) If NOK, warn + confirm (Ollama down, or network is in isolated mode)
4) docker compose run --rm openclaw-cli onboard
5) If the wizard exits non-zero, the closing banner explicitly suggests
   the URL fix in addition to the generic "rerun to resume" hint.
```
</details>
</details>

<details>
<summary><b>Web UI page loads but the body is a black/empty screen — no chat panel</b></summary>

If `http://127.0.0.1:18789` loads and the browser tab says `OpenClaw Control` but the page body is just a black empty screen — **this is not a bug**. This build's web UI is the **admin Control Panel**; it may not bundle a chat interface at all. GUIDE-FIRST-USE.md notes: "Depending on the OpenClaw build, the UI may be embedded or it may be API-only".

**Three ways to actually chat:**

```bash
# ① Fastest — talks to host Ollama directly, no setup required
./openclaw chat

# ② Full OpenClaw stack — TUI chat after one-time onboard
cd ~/DEV/openclaw
docker compose run --rm openclaw-cli onboard      # one-time
docker compose run --rm openclaw-cli tui          # every time

# ③ One-shot
docker compose run --rm openclaw-cli agent --message "hi"
```

⚠️ **`docker compose exec openclaw-cli bash` does not work** — the container's entrypoint (`node dist/index.js`) prints help and exits immediately, so `exec`'s target is never alive (`docker ps -a` shows `Exited (1)`). Always use **`run --rm`**.
</details>

<details>
<summary><b>Web UI (<code>http://127.0.0.1:18789</code>) shows "Safari Can't Connect" even though containers are healthy</b></summary>

If `./openclaw doctor` is all ✓ and `docker ps` shows the gateway as `(healthy)` but the browser can't reach it — almost always **isolated mode**. Docker's `internal: true` network also disables host → container port publishing, so `127.0.0.1:18789` is unreachable from the host.

Diagnose:
```bash
docker ps --format '{{.Names}}\t{{.Ports}}' | grep gateway
# Expected (online):    127.0.0.1:18789-18790->18789-18790/tcp
# Broken (isolated):    18789-18790/tcp        ← not published
```

Fix — briefly flip to online:
```bash
./openclaw network online --restart
open http://127.0.0.1:18789
# (when done)
./openclaw network isolated --restart
```

Don't need the web UI? Then `isolated` is fine — `./openclaw chat` and `docker compose run --rm openclaw-cli tui` both work regardless of port publishing.
</details>

<details>
<summary><b>Install keeps printing <code>[skip]</code> for every step and ends with a "sandbox not configured" warning</b></summary>

The state file claims "done" but the actual artifacts (clone dir / `.env` / sandbox compose overlay) have disappeared. Common causes:

- You manually deleted `~/DEV/openclaw`
- The very first install ran while Docker Desktop was still booting; `docker.sock` wasn't ready, so `step_sandbox` exited early and the marker got stuck at `done`

**Auto-recovery:** `./openclaw install` runs `validate_state` at startup and clears stale markers whose artifacts are missing — so just rerun:

```bash
cd ~/DEV/openclawAgent/openclaw-workspace
git pull --ff-only origin main   # pull in the validate_state patch
./openclaw install               # re-runs only the steps that were faked
./openclaw doctor                # verify
```

To wipe and start clean: `rm ~/.openclaw-mgr/state && ./openclaw install`.
</details>

<details>
<summary><b>My Mac feels slow / memory is full</b></summary>

```bash
./openclaw clean --status   # see what's using space
./openclaw clean            # safe step-by-step cleanup
```
Docker and Ollama accumulate caches and unused images over time. These commands never touch your data (volumes, `.env`, backups) — they only clear caches and unused images.
</details>

<details>
<summary><b>Can I use Korean LLMs (EXAONE/A.X/Solar) too?</b></summary>

Yes. Install [korea-sovereign-ai](https://github.com/GoGoComputer/korea-sovereign-ai) first; OpenClaw will pick up host Ollama models via `host.docker.internal:11434`. `./openclaw doctor` auto-detects them.

⚠ Note: under the default `isolated` network mode, host Ollama is also blocked. To use Korean models, briefly switch to `./openclaw network online --restart`.
</details>

<details>
<summary><b>How much of my computer can OpenClaw access? Is it folder-scoped?</b></summary>

By default, **OpenClaw only operates inside its Docker container** — it cannot touch host (Mac) files directly.

| Resource | Accessible? |
|---|---|
| Container filesystem | ✅ (read-only root + `/tmp` tmpfs) |
| Docker volumes (backup/session data) | ✅ |
| Host `~/Documents`, `~/.ssh`, `~/Library`, etc. | ❌ (not mounted) |
| Host USB / external drives | ❌ |
| Other host apps (browser cookies, etc.) | ❌ |
| Outbound internet | ❌ (`isolated` — default) / ✅ (`online`) |

Unless you explicitly mount a folder, **OpenClaw stays inside its container box.** To share a folder, edit OpenClaw's base `docker-compose.yml` and add a `volumes:` entry. We recommend a dedicated folder like `~/Desktop/openclaw-share`.
</details>

<details>
<summary><b>Can the AI download and execute malicious code from the internet?</b></summary>

**Not under the default `isolated` mode.** The Docker network is created with `internal: true`, blocking all outbound packets. DNS is also blocked, so even domain resolution fails.

`pip install`, `npm install`, `git clone https://...`, Hugging Face downloads — all blocked. Open `online` only briefly when you need them.
</details>

<details>
<summary><b>Can the AI exfiltrate my data?</b></summary>

**Not under the default `isolated` mode.** There's no outbound path, so even if a prompt-injection attack instructs "upload this file to X", it physically cannot run.

Additional defenses:
- Auto secret-masking on log output (`./openclaw logs`)
- `.env` in backups is GPG-encrypted
- All ports bind to `127.0.0.1` (no LAN exposure)
</details>

<details>
<summary><b>Can the AI delete or modify my files?</b></summary>

It cannot touch host files (see folder access table). It can only write inside the container, whose root filesystem is `read_only: true` — only `/tmp` (tmpfs, wiped on restart) is writable.

Persistent data lives in Docker volumes, which `./openclaw backup` snapshots safely.
</details>

<details>
<summary><b>Does the script change my system arbitrarily? Is it safe?</b></summary>

All install/uninstall actions go through user confirmation. The scripts:
- Install Homebrew, Docker Desktop, Ollama (official channels only)
- Clone OpenClaw to `~/DEV/openclaw`
- Register a daily update job in launchd (only if you opt in)
- Keep state under `~/.openclaw-mgr/`

`sudo` is used in exactly one place: `clean --all` calls `sudo purge` (a standard macOS memory-compression command). All source is open and densely commented — you can read it.
</details>

<details>
<summary><b>Are Docker Desktop / Ollama auto-started?</b></summary>

`./openclaw start` launches Docker Desktop (`open -a Docker`). Ollama is registered as a Homebrew service and starts at boot (`brew services start ollama`).
</details>

<details>
<summary><b>Does OpenClaw work offline (no Wi-Fi)?</b></summary>

In `isolated` mode it doesn't use the internet anyway, so **everything runs normally** (uses already-installed models/code). In `online` mode, only external API calls would fail; everything else still works.
</details>

<details>
<summary><b>Can multiple users share one Mac?</b></summary>

Use separate macOS user accounts (each gets their own `OPENCLAW_DIR`, `BACKUP_DIR` under `$HOME`). Multiple instances under one account is not currently supported.
</details>

<details>
<summary><b>What if an upgrade breaks something?</b></summary>

```bash
./openclaw backup --name before-upgrade   # always back up first
./openclaw update
# if something goes wrong:
./openclaw restore ~/openclaw-backups/openclaw-...-before-upgrade.tar.gz
```
`update` uses `git pull --ff-only` — no force merges — and data volumes are preserved on failure.
</details>

<details>
<summary><b>Does it work behind a corporate proxy / restricted network?</b></summary>

`isolated` mode doesn't talk to the internet anyway, so it's fine. Only `install` / `update` need internet; if you're behind a proxy, set shell env `HTTPS_PROXY` / `HTTP_PROXY` and they propagate to docker / git / brew. For self-signed CAs, register them in macOS Keychain.
</details>

---

## 🛠 For developers

### Directory layout

```
openclaw-mgr/
├── openclaw                # macOS/Linux entry dispatcher (bash)
├── openclaw.ps1            # Windows entry dispatcher (PowerShell) — WSL2 delegation + native helpers
├── .env.example            # configuration template
├── compose.security.yml    # security override
├── lib/                    # bash common (macOS/WSL2): common.sh / sec.sh / detect.sh / prompt.sh
├── lib-win/                # PowerShell common (Windows): common.ps1 (logging, idempotent steps, UTF-8 no-BOM writer)
├── cmd/                    # bash subcommands (macOS/WSL2):
│                           # doctor / install / start / stop / logs / update /
│                           # backup / restore / uninstall / schedule / clean
├── cmd-win/                # PowerShell subcommands (Windows-native):
│                           # install-bootstrap (winget · WSL2 · Git · Docker Desktop · Ollama)
│                           # doctor (WSL2 / Docker Desktop / port / path-pitfalls)
│                           # schedule (Register-ScheduledTask)
├── etc/pre-commit.tmpl     # gitleaks hook
└── docs/                   # QUICKSTART / ARCHITECTURE / TROUBLESHOOTING / CONTRIBUTING
```

### Idempotency (`state` file)

`~/.openclaw-mgr/state` accumulates `KEY=done` lines per completed step. `./openclaw install` checks each key and skips done steps. To rerun a single step, delete its line.

#### 🔄 Artifact verification (`validate_state`)

If the state file claims "done" but the **actual artifacts have vanished**, install clears those markers at startup. This prevents the classic trap: user deletes a folder or cleans up containers → reruns install → it forever reports `[skip]` because the markers say "done" without checking reality.

| Detected condition | Markers auto-cleared |
|---|---|
| `OPENCLAW_DIR/.git` missing (clone gone) | `repo_clone` · `compose_scan` · `env_merge` · `compose_up` · `health` · `lockdown` · `sandbox` |
| `OPENCLAW_DIR/.env` missing | `env_merge` · `compose_up` · `health` · `lockdown` · `sandbox` |
| `docker-compose.sandbox.yml` missing while `docker.sock` is ready | `sandbox` |

Additionally, when `step_sandbox` is deferred because `docker.sock` wasn't ready (`SANDBOX_DEFERRED=1`), the marker is cleared after `run_step` so the next install retries — preventing the previous bug where a marker got stuck at `done` if Docker Desktop was still booting on the first install.

The real idempotency contract is **"counts as done only while the artifact still exists"**, not "ran it once and forgot".

### Static checks

```bash
find openclaw-mgr -name '*.sh' -exec bash -n {} \;
shellcheck -S style openclaw-mgr/openclaw openclaw-mgr/lib/*.sh openclaw-mgr/cmd/*.sh
shfmt -d -i 2 openclaw-mgr
```

### Contributing

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

### Publishing your own fork

```bash
brew install gh
gh auth login
./scripts/publish.sh        # creates main repo, pushes, sets topics, makes v0.1.0 release
./scripts/publish-tap.sh    # creates Homebrew tap repo (homebrew-openclaw) automatically
```

`publish-tap.sh` auto-computes the `v0.1.0` tarball SHA256 and creates/updates
`<owner>/homebrew-openclaw`. Override owner with `GH_OWNER=myorg ./scripts/publish-tap.sh`.
After a new release (e.g. v0.1.1), rerun with `TAG=v0.1.1 ./scripts/publish-tap.sh`.

---

## 📜 License

[MIT](LICENSE) © 2026 박성모 Park Sungmo

ClawBro / OpenClaw trademarks and code belong to their respective owners. This project is independent and unaffiliated.
