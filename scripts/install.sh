#!/usr/bin/env bash
# =============================================================================
# scripts/install.sh — One-line web installer for openclaw-workspace
# -----------------------------------------------------------------------------
# Usage (end users):
#   curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash
#
# What this does:
#   1) Verifies macOS + arm64/x86_64.
#   2) git clone into ~/DEV/openclaw-workspace (or OPENCLAW_PREFIX) and symlinks
#      openclaw → ~/.local/bin/openclaw.   ← DEFAULT — no Homebrew required.
#   3) If Homebrew is already present AND --brew flag is passed, installs via
#      the GoGoComputer tap instead (managed updates via brew upgrade).
#
# Re-running is safe: git path uses `git pull --ff-only` on existing clones.
#
# Flags:
#   --brew      Use Homebrew tap (gogocomputer/openclaw) if brew is installed.
#   -h|--help   Print this help.
#
# Environment overrides:
#   OPENCLAW_REPO_URL   default: https://github.com/GoGoComputer/openclaw-workspace.git
#   OPENCLAW_PREFIX     default: $HOME/DEV/openclaw-workspace
#   OPENCLAW_BIN_DIR    default: $HOME/.local/bin
#   OPENCLAW_TAP        default: gogocomputer/openclaw  (--brew mode only)
#
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

OPENCLAW_REPO_URL="${OPENCLAW_REPO_URL:-https://github.com/GoGoComputer/openclaw-workspace.git}"
OPENCLAW_PREFIX="${OPENCLAW_PREFIX:-$HOME/DEV/openclaw-workspace}"
OPENCLAW_BIN_DIR="${OPENCLAW_BIN_DIR:-$HOME/.local/bin}"
OPENCLAW_TAP="${OPENCLAW_TAP:-gogocomputer/openclaw}"
OPENCLAW_FORMULA="openclaw-workspace"

USE_BREW=0
for arg in "$@"; do
  case "$arg" in
    --brew)    USE_BREW=1 ;;
    -h|--help) sed -n '2,35p' "$0"; exit 0 ;;
  esac
done

# ----- pretty output ---------------------------------------------------------
if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_Y=$'\033[0;33m'; C_R=$'\033[0;31m'
  C_B=$'\033[0;34m'; C_BOLD=$'\033[1m';  C_OFF=$'\033[0m'
else
  C_G=""; C_Y=""; C_R=""; C_B=""; C_BOLD=""; C_OFF=""
fi
say()  { printf '%s\n' "${C_B}▸${C_OFF} $*"; }
ok()   { printf '%s\n' "${C_G}✔${C_OFF} $*"; }
warn() { printf '%s\n' "${C_Y}⚠${C_OFF} $*" >&2; }
die()  { printf '%s\n' "${C_R}✘${C_OFF} $*" >&2; exit 1; }

cat <<'BANNER'

  ╔══════════════════════════════════════════════════════════════╗
  ║   🦞  openclaw-workspace — one-line installer (macOS)        ║
  ║      한 줄 웹 설치: curl … | bash                             ║
  ╚══════════════════════════════════════════════════════════════╝

BANNER

# ----- platform check --------------------------------------------------------
case "$(uname -s)" in
  Darwin) ok "macOS detected: $(sw_vers -productVersion 2>/dev/null || echo unknown)" ;;
  *)      die "macOS only. Detected: $(uname -s)" ;;
esac

case "$(uname -m)" in
  arm64|x86_64) ok "Arch: $(uname -m)" ;;
  *) warn "Untested arch: $(uname -m) — proceeding anyway" ;;
esac

# ----- install: git clone (default) or brew (opt-in) -------------------------
install_via_git() {
  command -v git >/dev/null 2>&1 || \
    die "git is required. Install Xcode CLT first: xcode-select --install"

  if [ -d "${OPENCLAW_PREFIX}/.git" ]; then
    say "Updating existing clone at ${OPENCLAW_PREFIX}"
    git -C "${OPENCLAW_PREFIX}" pull --ff-only
  else
    say "git clone → ${OPENCLAW_PREFIX}"
    mkdir -p "$(dirname "${OPENCLAW_PREFIX}")"
    git clone --depth 1 "${OPENCLAW_REPO_URL}" "${OPENCLAW_PREFIX}"
  fi

  mkdir -p "${OPENCLAW_BIN_DIR}"
  ln -sf "${OPENCLAW_PREFIX}/openclaw-mgr/openclaw" "${OPENCLAW_BIN_DIR}/openclaw"
  chmod +x "${OPENCLAW_PREFIX}/openclaw-mgr/openclaw"
  ok "Linked: ${OPENCLAW_BIN_DIR}/openclaw → ${OPENCLAW_PREFIX}/openclaw-mgr/openclaw"

  # PATH hint (only if not already in PATH)
  case ":${PATH}:" in
    *":${OPENCLAW_BIN_DIR}:"*) : ;;
    *)
      say "Adding ${OPENCLAW_BIN_DIR} to PATH in ~/.zshrc"
      printf '\nexport PATH="%s:$PATH"\n' "${OPENCLAW_BIN_DIR}" >> "${HOME}/.zshrc"
      export PATH="${OPENCLAW_BIN_DIR}:${PATH}"
      warn "Run: source ~/.zshrc   (or open a new terminal)"
      ;;
  esac
}

install_via_brew() {
  command -v brew >/dev/null 2>&1 || \
    die "Homebrew not found. Install it from https://brew.sh or run without --brew."

  say "brew tap ${OPENCLAW_TAP}"
  brew tap "${OPENCLAW_TAP}" >/dev/null

  if brew list --formula 2>/dev/null | grep -qx "${OPENCLAW_FORMULA}"; then
    say "Already installed — upgrading…"
    brew update && brew upgrade "${OPENCLAW_FORMULA}" || ok "Already at the latest version."
  else
    say "brew install ${OPENCLAW_FORMULA}"
    brew install "${OPENCLAW_FORMULA}"
  fi
  ok "Installed via Homebrew."
}

if [ "$USE_BREW" -eq 1 ]; then
  say "Mode: Homebrew tap (--brew)"
  install_via_brew
else
  say "Mode: git clone (default — no Homebrew required)"
  install_via_git
fi

# ----- verify ----------------------------------------------------------------
if command -v openclaw >/dev/null 2>&1; then
  ok "openclaw on PATH: $(command -v openclaw)"
  openclaw version 2>/dev/null || true
else
  warn "openclaw not on PATH yet — run: source ~/.zshrc  or open a new terminal."
fi

cat <<EOF

${C_G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_OFF}
${C_BOLD}🎉  openclaw-workspace installed!${C_OFF}

  ${C_BOLD}📂 설치 위치 / Installed locations:${C_OFF}
    관리 도구 / Tool:       ${OPENCLAW_PREFIX}
    명령어 링크 / Command:  ${OPENCLAW_BIN_DIR}/openclaw → ${OPENCLAW_PREFIX}/openclaw-mgr/openclaw

  ${C_BOLD}설치 후 생성될 위치 / Created by 'openclaw install':${C_OFF}
    OpenClaw 본체 / Engine: ~/DEV/openclaw            (공식 clone — 직접 수정 X)
    에이전트 파일 / Agent:  ~/DEV/openclawAgent       (Finder 에서 확인 가능)
    설정·토큰 / Config:    ~/.openclaw                (숨김, 자동 관리)
    백업 / Backups:         ~/openclaw-backups

  ⚠  이 레포는 로컬에 아무것도 직접 설치하지 않습니다.
     에이전트 실행은 Docker 컨테이너 안에서만 이루어집니다.

  ${C_BOLD}Next — install dependencies from official sites:${C_OFF}
    Docker Desktop  https://www.docker.com/products/docker-desktop/
    Ollama          https://ollama.com/download    (optional — local LLMs, M5 Pro GPU)

  ${C_BOLD}Then run:${C_OFF}
    openclaw doctor                   # verify everything is ready
    OPENCLAW_SANDBOX=1 openclaw install  # setup with sandbox isolation (recommended)

  ${C_BOLD}Docs:${C_OFF}
    https://github.com/GoGoComputer/openclaw-workspace/blob/main/docs/GUIDE-MANUAL-INSTALL.md
${C_G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_OFF}

EOF
