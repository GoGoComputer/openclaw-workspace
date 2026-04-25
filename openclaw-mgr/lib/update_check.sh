#!/usr/bin/env bash
# =============================================================================
# lib/update_check.sh — Check GitHub for a newer release of openclaw-workspace
# -----------------------------------------------------------------------------
# Provides:
#   update_check_should_run    -> true if cache is stale (>24h) or missing
#   update_check_fetch         -> hits the GitHub API, writes cache
#   update_check_latest        -> echo cached latest tag (e.g. "v0.1.1") or empty
#   update_check_is_newer A B  -> true if B > A using sort -V
#   update_check_banner        -> print 1-line banner if newer is available
#
# Cache file: $OPENCLAW_MGR_HOME/update-check
#   line 1: epoch of last successful check
#   line 2: latest tag (e.g. v0.1.2)
#
# Failures are silent — never block the launcher when offline.
# Set OPENCLAW_NO_UPDATE_CHECK=1 to disable entirely.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================

OPENCLAW_UPDATE_REPO="${OPENCLAW_UPDATE_REPO:-GoGoComputer/openclaw-workspace}"
OPENCLAW_UPDATE_CACHE="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/update-check"
OPENCLAW_UPDATE_TTL="${OPENCLAW_UPDATE_TTL:-86400}"   # 24h

update_check_should_run() {
  [ "${OPENCLAW_NO_UPDATE_CHECK:-0}" = "1" ] && return 1
  command -v curl >/dev/null 2>&1 || return 1
  if [ ! -f "$OPENCLAW_UPDATE_CACHE" ]; then return 0; fi
  local last now age
  last="$(sed -n '1p' "$OPENCLAW_UPDATE_CACHE" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  now="$(date +%s)"
  age=$(( now - last ))
  [ "$age" -ge "$OPENCLAW_UPDATE_TTL" ]
}

update_check_fetch() {
  local url="https://api.github.com/repos/${OPENCLAW_UPDATE_REPO}/releases/latest"
  local body tag
  body="$(curl -fsSL --max-time 4 "$url" 2>/dev/null)" || return 0
  # Tiny grep-based parse (avoid jq dependency).
  tag="$(printf '%s\n' "$body" \
        | grep -m1 -E '"tag_name"[[:space:]]*:' \
        | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  [ -n "$tag" ] || return 0
  mkdir -p -- "$(dirname "$OPENCLAW_UPDATE_CACHE")"
  printf '%s\n%s\n' "$(date +%s)" "$tag" > "$OPENCLAW_UPDATE_CACHE"
  chmod 600 "$OPENCLAW_UPDATE_CACHE" 2>/dev/null || true
}

update_check_latest() {
  [ -f "$OPENCLAW_UPDATE_CACHE" ] || return 0
  sed -n '2p' "$OPENCLAW_UPDATE_CACHE" 2>/dev/null
}

# Returns 0 if $2 (latest) is strictly greater than $1 (current); else 1.
update_check_is_newer() {
  local cur="${1#v}" lat="${2#v}"
  [ -n "$cur" ] && [ -n "$lat" ] || return 1
  [ "$cur" = "$lat" ] && return 1
  local top
  top="$(printf '%s\n%s\n' "$cur" "$lat" | sort -V | tail -n1)"
  [ "$top" = "$lat" ]
}

# Print a one-line banner if a newer version is detected. Safe to call always.
# Args:  CURRENT_VERSION  [LANG_PREF=ko|en]
update_check_banner() {
  local cur="$1" lang="${2:-en}" latest msg
  # Fire async-ish refresh: fetch in background, but only if stale & on TTY.
  if update_check_should_run && [ -t 1 ]; then
    ( update_check_fetch >/dev/null 2>&1 & ) >/dev/null 2>&1 || true
  fi
  latest="$(update_check_latest)"
  [ -n "$latest" ] || return 0
  update_check_is_newer "$cur" "$latest" || return 0
  if [ "$lang" = "ko" ]; then
    msg="새 버전 ${latest} 가 있습니다 (현재 v${cur}). 업데이트: openclaw self-update"
  else
    msg="A newer version ${latest} is available (current v${cur}). Update: openclaw self-update"
  fi
  printf '\n  \033[1;33m⬆ %s\033[0m\n' "$msg"
}
