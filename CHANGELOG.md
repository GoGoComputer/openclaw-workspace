# Changelog

## 📖 목차 / Contents

- [v0.2.16 — 2026-05-14](#v0216--2026-05-14)
- [v0.2.15 — 2026-05-14](#v0215--2026-05-14)
- [v0.2.14 — 2026-05-14](#v0214--2026-05-14)
- [v0.2.13 — 2026-05-14](#v0213--2026-05-14)
- [v0.2.12 — 2026-05-14](#v0212--2026-05-14)
- [v0.2.11 — 2026-05-14](#v0211--2026-05-14)
- [v0.2.10 — 2026-05-14](#v0210--2026-05-14)
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

## v0.2.16 — 2026-05-14

### GUIDE-DAILY-USE TL;DR — Discord prompt cheat sheet alongside host commands
User pointed out the TL;DR section had six host-side commands (`start` / `chat` / `tui` / `stop` / `doctor`) but no parallel "what do you actually type in Discord" reference, even though Discord is one of the primary interaction modes.

Added a **💬 Discord 에서 자주 쓰는 프롬프트** block right below the host cheat sheet:

  ① Bot alive check (`@bot 살아있어?`)
  ② Quick question in a channel
  ③ DM (plain text, no mention)
  ④ Workspace file write (with concrete path example, mobile-friendly)
  ⑤ `/reset` context clear
  ⑥ `/agent model <name>` switch

Plus a compact trigger-comparison table (mention / DM / slash / auto-respond channel) with "when to use" and "context length" columns. Closes with a direct link into GUIDE-DISCORD-BOT §12 ⓪ integrated scenario for the full Discord-only day walkthrough.

No code change; docs and CHANGELOG only.

VERSION 0.2.15 → 0.2.16.

---

## v0.2.15 — 2026-05-14

### Stitching cold-boot ↔ Discord into one end-to-end story
v0.2.13 covered "laptop off → on" in GUIDE-DAILY-USE. v0.2.14 covered "from Discord, what do you type in each situation" in GUIDE-DISCORD-BOT §12. Both were thorough, but the user had to manually stitch the two together — there was no single place that showed the actual hour-by-hour flow of *laptop off → power on → Discord all day → power off*.

**New `GUIDE-DISCORD-BOT §12 ⓪ — 통합 시나리오`** — a 9-station timeline (09:00 cold boot → 09:01 bot availability ping → 09:15 mobile away → 11:00 team channel → 13:00 lunch stop → 14:30 workspace file ops → 16:00 long task → 18:00 ops check → 22:00 shutdown) where each station carries:

- The host-side action (`./openclaw doctor`, `network online --restart`, `stop`, etc.)
- The Discord-side action (DM / mention / channel / slash command)
- Links into both GUIDE-DAILY-USE scenarios and the ①~⑧ detail cards in this same §12

Two reference tables under the timeline:
- **One-line matrix** (시간 / 상황 / 노트북 / Discord / 자세히 링크) for at-a-glance scanning
- **Common stuck-points** (7 hour-keyed gotchas) — bot offline despite host OK / mac sleep dropping container / wrong channel responding / file path off-workspace / OOM during long task / no host-shell perms / Docker auto-start not configured

### Cross-linking
- GUIDE-DAILY-USE Scenario 0 step 5: explicit callout linking the integrated scenario right where users finish cold-boot verification.
- GUIDE-DISCORD-BOT §12 prelude + TOC: ⓪ surfaces as the recommended entry point before drilling into ①~⑧.
- README (KO + EN) Documentation Map: 💬 row description now mentions ⓪ as a flagship "9-hour timeline" so the map signals the integrated walkthrough exists.

VERSION 0.2.14 → 0.2.15 (docs-only).

---

## v0.2.14 — 2026-05-14

### GUIDE-DISCORD-BOT §12 — situation-based Discord workflow catalog
v0.2.12 added "how the bot works"; this release adds "in every situation, what do you actually type into Discord to make it do the thing". Eight scenario cards covering the bot-as-primary-interface modes — same format as GUIDE-DAILY-USE's scenario cards, but oriented around the Discord side.

Each card has four parts: **when** · **what to type in Discord** · **what happens** · **limits**.

  ① At the laptop — quick @mention vs TUI/chat trade-off (channel
     history + team-shareable vs response speed + token cost).
  ② Mobile-only — DM with file-write prompts ("create
     ~/DEV/openclawAgent/daily-notes/2026-05-14.md and write …"),
     with a "before you leave" 30-second host check.
  ③ Team collaboration — public-channel summarization / code review
     with fenced diffs; "use threads" recommendation; DM-vs-channel
     privacy guidance.
  ④ Workspace file ops — read/edit/append over the mounted
     workspace; reminder that ~/Documents and friends are off-limits
     by isolation design; large-file context-window caveat.
  ⑤ System ops / DevOps — `doctor` results / log filtering / status
     queries via the bot. Calls out the security trade-off of giving
     the bot host-shell powers; recommends DM or a dedicated
     `#ops-alerts` whitelist channel.
  ⑥ Long-running task + completion ping — kick off, get pinged when
     done; 2000-char limit caveat with auto-attach fallback.
  ⑦ Scheduled / recurring — "every weekday 9am summarize yesterday's
     daily-notes to #notes"; notes that scheduler support depends on
     OpenClaw build, with a host-side cron fallback example.
  ⑧ Cold-boot recovery — Discord-side test (`@bot 살아있어?`), the
     fix sequence to run on the laptop, and a callout that "mobile
     SSH (Tailscale + iSH/Termius) is the only escape if the laptop
     itself is unreachable."

Plus a one-screen **상황별 빠른 매칭 표** mapping (where/when) → (recommended trigger / channel / caveat) for instant lookup.

### Cross-linking
- GUIDE-DAILY-USE TL;DR: explicit pointer to §12 for users who want Discord as their primary interface.
- README (KO + EN) Documentation Map: Discord row description now mentions the §12 8-case catalog so people scanning the map can tell that the guide goes well beyond setup.

No code change.

---

## v0.2.13 — 2026-05-14

### GUIDE-DAILY-USE.md — full cold-boot walkthrough
The previous "Scenario 1" treated everything as if Docker, Ollama, and the containers were already running. After a real power-off → power-on, none of that is guaranteed. This release adds:

- **Scenario 0 — Cold boot** (new). Detailed step-by-step for the case where the Mac was completely shut down:
  - **Auto-vs-manual matrix** — for each component (Docker Desktop, Ollama menu bar, host models, OpenClaw containers, network mode, config files, workspace, Discord bot, web UI, TUI sessions) lists whether it auto-resumes, and what to do otherwise.
  - **5-step procedure** with timing — Docker daemon (30–60s wait loop one-liner) → Ollama probe → OpenClaw container auto-recovery check → network-mode review → start chatting (chat / TUI / web UI / Discord).
  - **1-minute verification checklist** — four ✓/✗ probes that confirm each layer, plus a one-liner condensation: `docker info && curl ollama && docker ps | grep openclaw && echo ALL OK`.
  - **Common cold-boot gotchas table** — Docker still updating, Exited containers, Ollama app not up yet, last mode was isolated → web UI broken, Discord bot still reconnecting, fetch-failed model mismatch.
- **Scenario 1 — refactored** to the "warm" case (Mac woke from sleep, everything still up). Now points at Scenario 0 when starting from a true cold state.
- **Scenario 3 — expanded into 3 shutdown levels**: Level 1 (just macOS shutdown, 90% case), Level 2 (`./openclaw stop` then shutdown — multi-day idle), Level 3 (`stop` + `quit Docker` — long-term + RAM reclaim). Each with explicit commands and the matching restart cost. Includes pre-shutdown checklist (Discord activity, network mode persistence, backup) and a direct link back to Scenario 0.

### Documentation map
- README (KO + EN): the 🔄 row description now enumerates the scenario list (cold boot, warm start, three shutdown levels, etc.) instead of a vague "morning start, shutdown".

VERSION 0.2.12 → 0.2.13 (docs-only).

---

## v0.2.12 — 2026-05-14

### GUIDE-DISCORD-BOT.md — major expansion (setup-only → setup + daily-use)
The original guide stopped at "your bot is online and replied once". This release adds five new sections covering everyday operation, plus a one-screen cheat sheet:

- **§7 봇과 대화하는 4가지 방법** — @mention / DM / slash commands (`/agent ask`, `/agent reset`, etc.) / channel whitelist auto-respond. Per-trigger semantics: context length, when threads are useful, DM privacy.
- **§8 자주 쓰는 프롬프트 패턴** — one-liners, long-text summarization (with Discord's 2000-char limit caveat), code review with fenced diffs, workspace-aware prompts ("read MEMORY.md and …"), thread-based continued conversation, `/reset`, in-Discord model switching.
- **§9 채널·서버별 동작 조정** — table of six tuning knobs (autoChannels / muteChannels / channelModels / channelPersonas / allowedGuilds / maxInputChars) with a concrete JSON example showing per-channel model assignment. Includes the "Copy Channel ID" walkthrough.
- **§10 워크스페이스·인격을 봇으로 끌어오기** — how IDENTITY/SOUL/USER/AGENTS/MEMORY auto-load into the bot's system prompt (same as `./openclaw chat`); editing those files reflects on the next message without restart; using the bot itself to append to MEMORY.md mid-conversation; multimodal attachments.
- **§11 봇 행동 관리** — temporary mute (Discord-side vs `./openclaw stop`), permanent kick/ban, multi-server operation (same token vs separate bots), daily on/off pattern linked to GUIDE-DAILY-USE, disabling Discord while keeping the rest of OpenClaw.
- **🎯 명령·인터랙션 cheat sheet** — two compact tables (Discord-side actions, host-side commands) so users don't have to scroll the guide for everyday lookups.

### Cross-linking
- README (KO + EN) Documentation Map: the 💬 row description now lists what's actually inside (setup + daily-use sections + cheat sheet + troubleshooting cases) instead of just "create bot, invite, paste token".
- `docs/GUIDE-DAILY-USE.md` related-docs entry expands the description to point at the new §7–§11.

No code change.

---

## v0.2.11 — 2026-05-14

### Bug fix — TUI/Discord `fetch failed` after fresh setup (`OLLAMA_DEFAULT_MODEL` trap)
OpenClaw upstream injects a hardcoded `OLLAMA_DEFAULT_MODEL = "gemma4"` (no tag) into the configured models list during `onboard`, even when the user's actual installed model is `gemma4:26b`. The TUI then picks the no-tag entry as default → Ollama treats it as `gemma4:latest` (which doesn't exist) → every request fails with `fetch failed` / `LLM request failed: network connection error`. Network reachability (host.docker.internal, online mode) is irrelevant — the call dies at HTTP 404 from Ollama itself.

- **`./openclaw setup` now post-prunes** — after `onboard` returns rc=0, setup.sh queries the host Ollama `/api/tags` and removes any `models.providers.ollama.models[].id` that isn't an actual installed tag. The pre-prune config is backed up to `~/.openclaw/openclaw.json.bak-<timestamp>` (perms 600). Skips silently if Ollama is unreachable (no destructive change when we can't verify). Prints `PRUNE_OK_DROPPED::<list>::<backup-path>` outcome with a friendly summary.
- Same mechanism shape as v0.2.8's Ollama URL pre-flight: upstream offers no env/flag to disable the bogus default, so the wrapper detects and corrects after the fact rather than fighting the wizard mid-flow.

### Documentation
- **GUIDE-DAILY-USE.md** — troubleshooting table gets a `fetch failed` / `LLM request failed: network connection error` row. New subsection **"🔬 현재 어떤 모델을 쓰는지 — openclaw.json 점검"** with: 2-step diagnostic (`ollama list` vs config models), and three fixes ranked by preference — (A) rerun `./openclaw setup --skip-confirm` to trigger the auto-prune, (B) `ollama pull <name>` to make the bogus name actually exist, (C) manual JSON edit for emergencies.
- **GUIDE-DISCORD-BOT.md** — troubleshooting gets "Bot Online but never replies / TUI says `fetch failed`" entry that cross-links the daily-use diagnostic (same root cause).
- **README (KO) FAQ** — new entry "TUI/Discord 봇이 메시지에 답 안 함 — `fetch failed`" with the diagnostic one-liner, v0.2.11 quick fix, and link into the daily-use guide.
- VERSION 0.2.8 → 0.2.11 (catching up to match prior unreleased doc-only bumps 0.2.9 / 0.2.10).

---

## v0.2.10 — 2026-05-14

### New guide
- **`docs/GUIDE-DAILY-USE.md`** — the daily on/off loop that comes *after* install + setup. Six scenario-driven sections (morning start, stepping away, shutting down for the night, resuming a saved session, "something looks wrong", weekly/monthly maintenance), plus a "what gets persisted across stop/shutdown" table, plus a side-by-side comparison of every shutdown variant (`./openclaw stop` vs in-TUI `Ctrl+D` vs `docker compose down` vs `down -v` vs `uninstall` vs `uninstall --purge`) with what each preserves and the matching restart command. Bilingual TLDR + KO body.

### Cross-linking
- README (KO + EN) Documentation Map: new 🔄 row pointing to the guide.
- README (KO) pipeline table row 4 (Maintain): now links the daily-use guide alongside the existing command catalog and cleanup references.
- `docs/GUIDE-FIRST-USE.md` "5단계 — 일상 운영" section: callout banner directing readers to the deeper GUIDE-DAILY-USE.
- `docs/GUIDE-DISCORD-BOT.md` and `docs/GUIDE-WEB-FETCH.md` related-docs tables: include the daily-use guide so users navigating between integration/operations guides find it.
- The daily-use guide's own related-docs table back-links FIRST-USE, DISCORD-BOT, WEB-FETCH, TROUBLESHOOTING, OPENCLAW, and the README's command catalog + idempotency + network-toggle sections.

No code change.

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
