# Changelog

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
