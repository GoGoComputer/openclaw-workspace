# Changelog

## 📖 목차 / Contents

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
