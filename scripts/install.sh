#!/usr/bin/env bash
# =============================================================================
# scripts/install.sh — One-line web installer for openclaw-workspace
# -----------------------------------------------------------------------------
# Usage (end users):
#   curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash
#
# What this does:
#   1) Verifies macOS + arm64/x86_64.
#   2) If Homebrew is present  -> taps gogocomputer/openclaw and installs the
#      openclaw-workspace formula (cleanest path).
#   3) If Homebrew is missing  -> offers to install Homebrew, then proceeds
#      with the brew install path.
#   4) Falls back to a git clone into ~/.openclaw-workspace and a symlink
#      to ~/.local/bin/openclaw (PATH hint printed) only when --no-brew is set
#      or Homebrew install was declined.
#
# Re-running is safe: brew install is idempotent; the git fallback uses
# `git pull --ff-only` if the directory already exists.
#
# Environment overrides:
#   OPENCLAW_TAP        default: gogocomputer/openclaw
#   OPENCLAW_REPO_URL   default: https://github.com/GoGoComputer/openclaw-workspace.git
#   OPENCLAW_PREFIX     default: $HOME/.openclaw-workspace  (git fallback)
#   OPENCLAW_BIN_DIR    default: $HOME/.local/bin           (git fallback symlink)
#
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

OPENCLAW_TAP="${OPENCLAW_TAP:-gogocomputer/openclaw}"
OPENCLAW_FORMULA="openclaw-workspace"
OPENCLAW_REPO_URL="${OPENCLAW_REPO_URL:-https://github.com/GoGoComputer/openclaw-workspace.git}"
OPENCLAW_PREFIX="${OPENCLAW_PREFIX:-$HOME/.openclaw-workspace}"
OPENCLAW_BIN_DIR="${OPENCLAW_BIN_DIR:-$HOME/.local/bin}"

NO_BREW=0
for arg in "$@"; do
  case "$arg" in
    --no-brew) NO_BREW=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
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

# ----- choose path: brew (preferred) or git fallback -------------------------
need_brew_install=0
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew found: $(brew --version | head -n1)"
elif [ "$NO_BREW" -eq 1 ]; then
  warn "Skipping Homebrew (--no-brew). Will use git fallback."
else
  warn "Homebrew is not installed."
  if [ -t 0 ]; then
    printf '%s ' "${C_BOLD}Install Homebrew now? [Y/n]:${C_OFF}"
    read -r ans || ans=""
    case "${ans:-Y}" in
      n|N|no|NO) need_brew_install=0; NO_BREW=1 ;;
      *)         need_brew_install=1 ;;
    esac
  else
    # Non-interactive (curl|bash) — auto-install brew, since user clearly wants
    # the one-line path. They can opt out with --no-brew via env piping.
    say "Non-interactive run — auto-installing Homebrew."
    need_brew_install=1
  fi
fi

if [ "$need_brew_install" -eq 1 ]; then
  say "Installing Homebrew (official script)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this shell.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || die "Homebrew install seems to have failed."
  ok "Homebrew installed."
fi

install_via_brew() {
  say "brew tap ${OPENCLAW_TAP}"
  brew tap "${OPENCLAW_TAP}" >/dev/null

  if brew list --formula | grep -qx "${OPENCLAW_FORMULA}"; then
    say "Already installed — running brew upgrade…"
    brew update
    brew upgrade "${OPENCLAW_FORMULA}" || ok "Already at the latest version."
  else
    say "brew install ${OPENCLAW_FORMULA}"
    brew install "${OPENCLAW_FORMULA}"
  fi
  ok "Installed via Homebrew."
}

install_via_git() {
  command -v git >/dev/null 2>&1 || die "git is required for the fallback install."
  if [ -d "${OPENCLAW_PREFIX}/.git" ]; then
    say "Updating existing clone at ${OPENCLAW_PREFIX}"
    git -C "${OPENCLAW_PREFIX}" pull --ff-only
  else
    say "Cloning into ${OPENCLAW_PREFIX}"
    git clone --depth 1 "${OPENCLAW_REPO_URL}" "${OPENCLAW_PREFIX}"
  fi
  mkdir -p "${OPENCLAW_BIN_DIR}"
  ln -sf "${OPENCLAW_PREFIX}/openclaw-mgr/openclaw" "${OPENCLAW_BIN_DIR}/openclaw"
  chmod +x "${OPENCLAW_PREFIX}/openclaw-mgr/openclaw"
  ok "Linked: ${OPENCLAW_BIN_DIR}/openclaw  →  ${OPENCLAW_PREFIX}/openclaw-mgr/openclaw"

  case ":$PATH:" in
    *":${OPENCLAW_BIN_DIR}:"*) : ;;
    *)
      warn "Add this to your shell profile (~/.zshrc or ~/.bash_profile):"
      printf '       %sexport PATH="%s:$PATH"%s\n' "${C_BOLD}" "${OPENCLAW_BIN_DIR}" "${C_OFF}"
      ;;
  esac
}

if [ "$NO_BREW" -eq 1 ]; then
  install_via_git
else
  install_via_brew
fi

# ----- verify ----------------------------------------------------------------
if command -v openclaw >/dev/null 2>&1; then
  ok "openclaw is on PATH: $(command -v openclaw)"
  openclaw version || true
else
  warn "openclaw not on PATH yet — open a new terminal or update your PATH."
fi

cat <<EOF

${C_G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_OFF}
${C_BOLD}🎉  Installed!${C_OFF}

  ${C_BOLD}Next steps:${C_OFF}
    openclaw                # interactive menu (Korean/English auto)
    openclaw doctor         # check current state
    openclaw install        # install Docker / Ollama / OpenClaw
    openclaw self-update    # update openclaw-workspace itself

  ${C_BOLD}Docs:${C_OFF}
    https://github.com/GoGoComputer/openclaw-workspace
${C_G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_OFF}

EOF
