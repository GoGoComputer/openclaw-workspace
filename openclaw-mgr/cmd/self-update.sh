#!/usr/bin/env bash
# =============================================================================
# cmd/self-update.sh — Update the openclaw-workspace manager itself
# -----------------------------------------------------------------------------
# This is *not* `update` (which updates the OpenClaw container & models).
# This command updates the launcher / scripts (this repo).
#
# Strategy:
#   • If running from a Homebrew Cellar path -> `brew update && brew upgrade`.
#   • Else if running from a git checkout    -> `git pull --ff-only`.
#   • Else (rare; e.g. tarball)              -> hint to re-run the web installer.
#
# Re-running is safe; both paths are idempotent.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

title "openclaw-workspace 매니저 업데이트 / Self-update"

mgr_dir="${OPENCLAW_MGR_DIR}"
parent_dir="$(cd "$mgr_dir/.." && pwd)"

is_brew_path() {
  case "$mgr_dir" in
    */Cellar/openclaw-workspace/*|*/opt/openclaw-workspace/*) return 0 ;;
  esac
  if command -v brew >/dev/null 2>&1; then
    local cellar
    cellar="$(brew --cellar 2>/dev/null || true)"
    [ -n "$cellar" ] && case "$mgr_dir" in "$cellar"*) return 0 ;; esac
  fi
  return 1
}

if is_brew_path; then
  command -v brew >/dev/null 2>&1 || die "Homebrew install detected but brew is not on PATH."
  info "Homebrew install detected — using brew upgrade."
  info "brew update"
  brew update
  if brew list --formula | grep -qx openclaw-workspace; then
    info "brew upgrade openclaw-workspace"
    if brew upgrade openclaw-workspace; then
      ok "Up to date (or upgraded)."
    else
      ok "Already at the latest version."
    fi
  else
    warn "Formula 'openclaw-workspace' not installed via brew — falling back to tap+install."
    brew tap gogocomputer/openclaw >/dev/null
    brew install openclaw-workspace
  fi
  exit 0
fi

if [ -d "$parent_dir/.git" ]; then
  command -v git >/dev/null 2>&1 || die "git not found."
  info "Git checkout detected: $parent_dir"
  if [ -n "$(git -C "$parent_dir" status --porcelain)" ]; then
    err "로컬 변경사항이 있어 중단합니다 / Uncommitted local changes — aborting."
    err "확인: git -C $parent_dir status"
    exit 1
  fi
  info "git pull --ff-only"
  git -C "$parent_dir" pull --ff-only
  ok "Updated to: $(git -C "$parent_dir" rev-parse --short HEAD)"
  exit 0
fi

warn "Could not detect install method (not Homebrew, not a git checkout)."
warn "Re-clone the repository to refresh:"
printf '\n  git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/DEV/openclaw-workspace\n\n'
exit 1
