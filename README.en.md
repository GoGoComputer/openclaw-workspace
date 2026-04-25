# openclaw-workspace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)](#)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-arm64-blue?logo=apple)](#)
[![Shell](https://img.shields.io/badge/shell-bash%203.2%2B-1f425f?logo=gnu-bash)](#)
[![CI](https://img.shields.io/github/actions/workflow/status/GoGoComputer/openclaw-workspace/ci.yml?branch=main)](https://github.com/GoGoComputer/openclaw-workspace/actions)

> **OpenClaw self-host automation for macOS — install, maintain, and uninstall with one command.**
>
> One `./openclaw install` on a fresh MacBook sets up Docker, (optionally) Ollama, and the OpenClaw container. Idempotent: if interrupted, just rerun and it picks up where it left off. 100% local sandboxing by default.

> 🇰🇷 한국어 (메인): [README.md](README.md)

## ⚡ 30-second install (paste into Terminal)

```bash
curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash
```

Update any time — the menu also shows a banner when a new version is out:

```bash
openclaw self-update            # alias: openclaw ai-update
```

---

## 🚀 5-minute start (non-developer friendly)

> Never used a terminal? See [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md) for a step-by-step walkthrough with example terminal output.

### Option A — one-line web install (easiest)

```bash
curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash
openclaw                        # interactive menu (Korean/English auto-detected)
```

The script installs Homebrew if missing, then taps and installs the formula. Safe to re-run.

### Option B — Homebrew directly

```bash
brew tap gogocomputer/openclaw
brew install openclaw-workspace
openclaw
```

Update: `openclaw self-update` (or `brew update && brew upgrade openclaw-workspace`).

### Option C — git clone (run from source · for developers)

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

---

## 📚 Documentation map

> Not sure where to start? Pick your row. Korean and English are both available.

| Who you are | Start here | What's inside |
|---|---|---|
| � **Truly from zero (`mkdir`, `cd`, opening Terminal)** | [docs/GUIDE-FROM-ZERO.md](docs/GUIDE-FROM-ZERO.md) | Open Terminal → 5 essential commands → one-line install. KO+EN || 🪜 **Fully manual install (download from official sites)** | [docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md) | No brew, no install scripts — download Docker / Ollama / source by hand. For corp IT review, GitHub-502 fallback, or hands-on learners. KO+EN || �🆕 **First time / never used a terminal** | [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md) | Step-by-step from "open Terminal", with sample output |
| 🇰🇷 **한국어 처음 사용자** | [docs/QUICKSTART-ko.md](docs/QUICKSTART-ko.md) | 한국어 버전 |
| 📖 **Unfamiliar with the terms (Ollama · Docker · OpenClaw)** | [docs/GUIDE-OLLAMA.md](docs/GUIDE-OLLAMA.md) · [docs/GUIDE-DOCKER.md](docs/GUIDE-DOCKER.md) · [docs/GUIDE-OPENCLAW.md](docs/GUIDE-OPENCLAW.md) | Three 3-minute primers (concepts, vocabulary, philosophy) — KO+EN |
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

[**OpenClaw**](https://clawbro.ai) is a powerful open-source AI agent that can run shell commands, touch files, and browse the web on your behalf. Because of that power, you must run it inside a Docker sandbox. This project automates the setup on a brand-new macOS machine.

| What this tool does | What it doesn't |
|---|---|
| Auto-installs Homebrew · Docker · Ollama | Develop OpenClaw itself |
| Clones the OpenClaw repo & boots containers | Cloud hosting (see [ClawBro.ai](https://clawbro.ai)) |
| Daily auto-update via launchd | Windows / Linux |
| Backup · restore · clean uninstall | Multi-instance |
| Security hardening (read-only, cap_drop, 127.0.0.1-only, ...) | Channel integrations (Telegram, etc.) |

---

## 📋 Command catalog

| Command | Description |
|---|---|
| `./openclaw` (or `menu`) | Interactive menu (auto KO/EN) — pick a number to do anything |
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

| Mode | Outbound (container→internet) | Web UI (127.0.0.1) | host Ollama | When to use |
|---|---|---|---|---|
| **`isolated`** 🔒 (default) | Fully blocked | ✓ | Blocked | Always — safe even if AI goes rogue |
| **`online`** 🌐 | Allowed | ✓ | ✓ | Only briefly for install/update/model pulls |

### What `isolated` (default) **blocks**
- All outbound DNS and IP traffic from inside the container.
- Therefore the following are blocked (flip to `online` if needed):
  - `pip install <pkg>`, `npm install`, `apt-get update`
  - `git clone https://github.com/...` and other GitHub/GitLab pulls
  - Hugging Face / pypi / docker registry downloads
  - **host Ollama** (`host.docker.internal:11434`) — also blocked under isolated
  - **Any data exfiltration attempt** (malicious prompt-injection "upload my files to X" is physically impossible)

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
- Clone OpenClaw to `~/openclaw`
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
├── openclaw                # single entry dispatcher
├── .env.example            # configuration template
├── compose.security.yml    # security override
├── lib/                    # common.sh / sec.sh / detect.sh / prompt.sh
├── cmd/                    # doctor / install / start / stop / logs / update /
│                           # backup / restore / uninstall / schedule / clean
├── etc/pre-commit.tmpl     # gitleaks hook
└── docs/                   # QUICKSTART / ARCHITECTURE / TROUBLESHOOTING / CONTRIBUTING
```

### Idempotency (`state` file)

`~/.openclaw-mgr/state` accumulates `KEY=done` lines per completed step. `./openclaw install` checks each key and skips done steps. To rerun a single step, delete its line.

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
