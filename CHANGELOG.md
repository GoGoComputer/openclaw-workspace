# Changelog

## 📖 목차 / Contents

- [v0.2.9 — 2026-05-14](#v029--2026-05-14)
- [v0.2.8 — 2026-05-14](#v028--2026-05-14)
- [v0.2.7 — 2026-05-14](#v027--2026-05-14)
- [v0.2.6 — 2026-05-14](#v026--2026-05-14)
- [v0.2.5 — 2026-05-14](#v025--2026-05-14)
- [v0.2.4 — 2026-04-25](#v024--2026-04-25)
- [v0.2.3 — 2026-04-25](#v023--2026-04-25)
- [v0.2.2 — 2026-04-25](#v022--2026-04-25)
- [v0.2.1 — 2026-04-25](#v021--2026-04-25)
- [v0.2.0 — 2026-04-25](#v020--2026-04-25)
- [v0.1.9 — 2025-07-xx](#v019--2025-07-xx)
- [v0.1.8 — 2025-07-xx](#v018--2025-07-xx)
- [v0.1.7](#v017)

---

## v0.2.9 — 2026-05-14

### New guide
- **`docs/GUIDE-DISCORD-BOT.md`** — running OpenClaw as a Discord bot, end-to-end. Mirrors the Discord stage of the setup wizard but in much more depth: app creation, **Message Content Intent** (the most common first-time gotcha), OAuth2 URL Generator with the minimum-viable permission set, token paste vs external secret provider, first message test, and a troubleshooting section covering bot-offline, intent missing, slash commands not appearing, etc. Security section covers what a leaked token means and how to rotate. Bilingual TLDR + KO body with EN-friendly headings.

### Cross-linking
- README (KO + EN) Documentation Map: new 💬 row pointing to the guide.
- README (KO + EN) wizard walkthrough table: stage **11 (Skills / plugins / channels)** now mentions Discord/Telegram/WhatsApp + links the new guide.
- `docs/GUIDE-FIRST-USE.md` (KO + EN): the inline trail under `./openclaw setup` now mentions Discord stage and points at the new doc.
- `docs/GUIDE-WEB-FETCH.md` Related-docs table: adds the Discord guide so users navigating between integration guides find it.

No code change.

---

## v0.2.8 — 2026-05-14

### Bug fix — setup wizard `Ollama not reachable` trap
- The OpenClaw onboard wizard's "Ollama base URL" prompt is hardcoded to default `http://127.0.0.1:11434`. Inside the cli container, that resolves to the container itself — not the host — so the wizard dies with `Ollama could not be reached at http://127.0.0.1:11434` → `WizardCancelledError: Ollama not reachable` even when the host Ollama is fine. OpenClaw upstream reads no env var or CLI flag for this URL (verified by grepping `process.env.OLLAMA*` and the onboard option surface in `/app/dist`); the value can only be entered through the prompt.
- **`./openclaw setup` now pre-flights this** — before launching the wizard, it spins a one-shot `--no-deps` container and curls `http://host.docker.internal:11434/api/tags`. On success it prints a yellow boxed warning telling the user the exact value to type at the prompt:
  ```
  ⚠  마법사 안에서 "Ollama base URL" 단계가 나오면 다음을 입력
       http://host.docker.internal:11434
     기본값으로 보이는 http://127.0.0.1:11434 는 컨테이너 자신을 가리켜서
     호스트 Ollama 에 닿지 못합니다.
  ```
  On failure (Ollama not running on the host, or network is in `isolated` mode), it warns and offers to abort.
- Post-run banner — if the wizard exits non-zero, setup.sh now suggests the URL fix specifically in addition to the generic "rerun to resume".

### Documentation
- README (KO + EN) wizard walkthrough table: added stage **8a (Ollama mode)** and **8b (Ollama base URL ⚠️ trap)** with the required `host.docker.internal` value. Promoted the URL trap to one of the "most important answers" callout.
- README (KO + EN) FAQ: new entry "setup wizard `Ollama not reachable` — but my host Ollama is running" with the diagnosis, the one-line fix, and a verification command.
- CHANGELOG v0.2.8.
- VERSION 0.2.7 → 0.2.8.

### New commands
- **`./openclaw setup`** — first-time / re-run OpenClaw onboard wizard, safely inside Docker. Wraps `docker compose run --rm openclaw-cli onboard` with pre-flight checks (clone exists · Docker daemon up), idempotent re-run confirmation (existing config detected → ask before re-running, Enter keeps any answer), and post-run hand-off to `./openclaw chat` or `tui`.
- **`./openclaw setup status`** — read-only inspector: shows whether `~/.openclaw/openclaw.json` exists, last-modified time, and top-level config keys. Does not modify anything.

### `./openclaw chat` upgrades
- **Interactive model picker** — without `-m`, the script queries `ollama list` and prints a numbered menu of installed models with their sizes. Press Enter for the default (= `.env`'s `OLLAMA_MODELS` first entry if installed), or pick a number.
  - Embedding models (`*-embed-*`, family `embed*`) are filtered out — they can't chat.
  - Exactly one installed model → auto-picked. Zero installed → friendly `ollama pull` recommendations + exit.
  - Non-interactive contexts (`NONINTERACTIVE=1`, piped stdin, `--no-pick`, or `-m`) skip the picker.
- **`--no-pick`** flag — force the legacy "use `.env` default model" behavior.
- Replaces the old "model X may not be installed, continue? [y/N]" warning with a real picker that shows what *is* installed.

### Documentation
- README (KO + EN): command catalog adds `setup`; '첫 사용 / first use' section ② re-flowed around `./openclaw setup` → `./openclaw chat`; ③ documents the picker; dedicated chat section shows a sample picker menu.
- README (KO + EN): new collapsible **"마법사가 차례로 묻는 단계 / What the wizard asks"** table inside the `setup` discussion — 14 stages with recommended answers. Key callouts: stage #8 (`auth-choice = ollama`) lets users keep their already-installed local models without any API key, and stage #4 (`gateway-bind = loopback`) is the safest default. Links to upstream `docs.openclaw.ai/cli/onboard` for the full 50+ provider surface.
- GUIDE-FIRST-USE.md (KO + EN): Option B opens with `./openclaw setup` instead of a raw `docker compose run` chain; Option C documents the picker. Inline stage list references the README walkthrough.
- VERSION bumped 0.2.6 → 0.2.7.

---

## v0.2.6 — 2026-05-14

### Documentation correctness
- **`docker compose exec openclaw-cli bash` → `docker compose run --rm openclaw-cli <subcommand>`** everywhere. The cli container's entrypoint is `node dist/index.js`, which prints help and exits when invoked with no args — so the container is in `Exited (1)` state and `exec` always fails. The correct pattern is `run --rm` per invocation. (README KO + EN, GUIDE-FIRST-USE.md, install.sh post-install banner.)
- **`claude` → `openclaw tui` / `openclaw onboard` / `openclaw agent`**. The actual CLI binary inside the container is `openclaw` (`/usr/local/bin/openclaw` → `/app/openclaw.mjs`); `claude` does not exist on PATH. The previous instructions sent users into a dead end.
- **In-container workspace path**: `/workspace` → `/home/node/.openclaw/workspace` (matches `OPENCLAW_WORKSPACE_DIR` env in `docker-compose.yml` and the actual mount).

### Web UI honesty
- **Isolated mode blocks web UI** — Docker's `internal: true` network also disables host → container port publishing (no docker-proxy spawned). Empirically confirmed via `docker inspect` showing requested but unrealized port bindings. The network-mode table now reports `isolated.WebUI` as ✗ with a callout; both README and `install.sh` post-install banner now lead with `./openclaw network online --restart` for browser access.
- **Empty/black Control Panel page is normal** — this OpenClaw build's web UI is the admin Control Panel, not a chat interface. Added FAQ entries (KO + EN) directing users to `./openclaw chat`, `docker compose run --rm openclaw-cli tui`, or one-shot `agent`.

---

## v0.2.5 — 2026-05-14

### New features
- **`openclaw chat`** — terminal REPL chat with the agent via host Ollama. Streams `/api/chat` token-by-token; auto-loads workspace personality files (`IDENTITY.md` · `SOUL.md` · `USER.md` · `AGENTS.md` · `MEMORY.md`) into the system prompt. Slash commands: `/exit` `/reset` `/model` `/history` `/help`. Pure stdlib (`curl` + `python3`); no extra deps.

### Install reliability
- **`install.sh`: `validate_state()`** — at install start, cascade-unmarks state keys whose underlying artifacts are gone:
  - `OPENCLAW_DIR/.git` missing → unmark `repo_clone` through `sandbox` (7 steps)
  - `OPENCLAW_DIR/.env` missing → unmark `env_merge` through `sandbox` (5 steps)
  - `docker-compose.sandbox.yml` missing + `docker.sock` ready → unmark `sandbox`
  - Fixes "install reports `[skip]` for every step but final summary keeps warning 샌드박스 미설정" when the user manually deleted the clone or ran the first install while Docker Desktop was still booting.
- **`step_sandbox` deferred marker** — when `docker.sock` is absent the step now sets `SANDBOX_DEFERRED=1` and the marker is cleared after `run_step`, so the next install retries instead of staying stuck at `sandbox=done`.
- **`validate_state` always returns 0** — guards against silent `set -e` exit when no markers need clearing (the function's final `[ ] && info` short-circuited to exit code 1).

### Bug fixes
- **`compose.security.yml`**: drop duplicate `security_opt: [no-new-privileges:true]` on `openclaw-gateway`. Base `docker-compose.yml` already declared it, so Compose v2 concatenated the sequences and rejected with `services.openclaw-gateway.security_opt items at 0 and 1 are equal`. (The same fix was previously applied to `openclaw-cli` but the matching change to `openclaw-gateway` was missing.)

### Documentation
- **README** new section: **🎯 install 직후 — 첫 사용 / Right after install — first use** — three entry points (browser web UI · container CLI · `openclaw chat`), how to verify, and a quick-reference for the `network online ↔ isolated` toggle.
- **README** idempotency section: documents `validate_state` artifact verification with a table of detection conditions and the markers that get auto-cleared.
- **README** FAQ: new entry "install keeps printing `[skip]` but nothing works" — explains the cause and the one-line recovery.

---

## v0.2.4 — 2026-04-25
- `openclaw install`: removed bulk Ollama model auto-download (`step_ollama_models` deleted)
- `openclaw install`: new `step_ollama_check` — detects and displays already-installed Ollama models before proceeding
- `step_compose_up` / `step_lockdown`: pre-detect existing OpenClaw Docker images and containers, display them; use `--pull missing` to avoid re-downloading

## v0.2.3 — 2026-04-25
- `openclaw install`: added directory banner at start (shows exact paths before installing) and at completion (confirms actual paths created)
- Installation: added directory summary in completion banner (tool path, future agent/config/backup locations)

## v0.2.2 — 2026-04-25
### Security fixes (audit)
- **BUGFIX**: `network.sh` `isolated`/`online` compose overlays used `app:` → fixed to `openclaw-gateway` + `openclaw-cli` (network isolation was NOT working before this fix)
- `OPENCLAW_DIR` default fixed from `~/openclaw` → `~/DEV/openclaw` in 8 scripts: `start.sh`, `stop.sh`, `logs.sh`, `update.sh`, `backup.sh`, `restore.sh`, `uninstall.sh`, `detect.sh`
- `sec_scan_compose()`: sandbox overlay (`docker-compose.sandbox.yml`) now excluded from docker.sock false-positive check

## v0.2.1 — 2026-04-25
- **BUGFIX**: `compose.security.yml` + `compose.network.yml` service name fixed from `app` → `openclaw-gateway`/`openclaw-cli` (security overlays were NOT being applied before this fix)
- `OPENCLAW_WORKSPACE_DIR` default changed to `~/DEV/openclawAgent` (agent files visible in Finder)
- Added `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_SANDBOX` to `.env.example`
- New `compose.ollama.yml` — Ollama-in-Docker option (fallback, GPU acceleration not available)
- Guide: added security principles section, M5 Pro 24GB model recommendations, no-global-install warnings
- Ollama step: updated with M5 Pro model table, `brew install ollama` warning

## v0.2.0 — 2026-04-25
- `openclaw install`: added Step 10 — sandbox setup (`OPENCLAW_SANDBOX=1`)
- `docs/GUIDE-MANUAL-INSTALL.md`: added Step 5c — Sandbox + Security Hardening (KO + EN)
- Sandbox: `mode=non-main`, `scope=agent`, `workspaceAccess=none` via `docker-setup.sh`
- Install banner now shows sandbox activation hint

## v0.1.9 — 2025-07-xx
- Default `OPENCLAW_DIR` changed from `~/openclaw` to `~/DEV/openclaw` (matches actual install location)
- Updated all docs and `.env.example` to reflect new path

## v0.1.8 — 2025-07-xx
- Installation: git clone is the default (no Homebrew required); `--brew` (Homebrew tap) is opt-in
- `openclaw install`: removed auto-install of Homebrew and Docker via brew; now points to official sites (brew.sh, docker.com)
- `README.md`, `README.en.md`: updated to reflect new install options

## v0.1.7
- Previous release
