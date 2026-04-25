# Changelog

## v0.2.4 — 2026-04-25
- `openclaw install`: removed bulk Ollama model auto-download (`step_ollama_models` deleted)
- `openclaw install`: new `step_ollama_check` — detects and displays already-installed Ollama models before proceeding
- `step_compose_up` / `step_lockdown`: pre-detect existing OpenClaw Docker images and containers, display them; use `--pull missing` to avoid re-downloading

## v0.2.3 — 2026-04-25
- `openclaw install`: added directory banner at start (shows exact paths before installing) and at completion (confirms actual paths created)
- `scripts/install.sh`: added directory summary in completion banner (tool path, future agent/config/backup locations)

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
- `scripts/install.sh`: git clone is now the default (no Homebrew required); `--brew` is opt-in
- `openclaw install`: removed auto-install of Homebrew and Docker via brew; now points to official sites (brew.sh, docker.com)
- `README.md`, `README.en.md`: updated to reflect new install options

## v0.1.7
- Previous release
