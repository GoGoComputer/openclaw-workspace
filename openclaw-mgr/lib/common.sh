#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — 공통 유틸리티 (로깅·확인·멱등 단계 관리)
# -----------------------------------------------------------------------------
# 목적   : 모든 cmd/*.sh 가 공유하는 헬퍼 함수 모음
# 입력   : (라이브러리 — source 로 불러서 사용)
# 출력   : 없음 (함수 정의만)
# 사이드 : OPENCLAW_MGR_HOME(상태 디렉터리) 자동 생성, umask 077
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================

# Bash 3.2 호환 (macOS 기본). 강한 안전 옵션.
set -o pipefail
umask 077

# ── 색상 (TTY 일 때만 ANSI) ──────────────────────────────────────────────────
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_RED="$(printf '\033[31m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_BLUE="$(printf '\033[34m')"
  C_CYAN="$(printf '\033[36m')"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

# ── 경로 ─────────────────────────────────────────────────────────────────────
# 사용자별 상태/로그 디렉터리. 모든 진행 상황·로그가 여기로 모인다.
OPENCLAW_MGR_HOME="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}"
STATE_FILE="$OPENCLAW_MGR_HOME/state"
LOG_DIR="$OPENCLAW_MGR_HOME/logs"
mkdir -p "$LOG_DIR"
[ -f "$STATE_FILE" ] || : > "$STATE_FILE"
chmod 700 "$OPENCLAW_MGR_HOME" 2>/dev/null || true
chmod 600 "$STATE_FILE" 2>/dev/null || true

# ── 로깅 ─────────────────────────────────────────────────────────────────────
# 모든 로그는 stderr 로 — stdout 은 데이터(파이프)용으로 깨끗하게 둔다.
_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log()  { printf '%s%s%s\n' "$C_DIM" "[$(_ts)] $*" "$C_RESET" >&2; }
info() { printf '%s•%s %s\n' "$C_BLUE" "$C_RESET" "$*" >&2; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
warn() { printf '%s⚠%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }
hr()   { printf '%s%s%s\n' "$C_DIM" "────────────────────────────────────────" "$C_RESET" >&2; }
title(){ printf '\n%s%s%s\n' "$C_BOLD$C_CYAN" "» $*" "$C_RESET" >&2; }

# ── 확인 프롬프트 ─────────────────────────────────────────────────────────────
# confirm "메시지" [기본값 y|n]  →  Yes 면 0, No 면 1
# 비대화형(NO TTY) 환경에서는 NONINTERACTIVE=1 면 기본값 채택.
confirm() {
  local prompt="$1" default="${2:-n}" reply hint
  case "$default" in
    y|Y) hint="[Y/n]" ;;
    *)   hint="[y/N]" ;;
  esac
  if [ "${NONINTERACTIVE:-0}" = "1" ] || [ ! -t 0 ]; then
    [ "$default" = "y" ] || [ "$default" = "Y" ]
    return $?
  fi
  printf '%s? %s %s ' "$C_YELLOW" "$prompt" "$hint$C_RESET" >&2
  read -r reply || reply=""
  reply="${reply:-$default}"
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── 멱등 단계 관리 ────────────────────────────────────────────────────────────
# state 파일에 "STEP_KEY=done" 한 줄씩 기록한다. 이미 done 이면 건너뛴다.
state_has() { grep -qx "$1=done" "$STATE_FILE" 2>/dev/null; }
state_mark(){ state_has "$1" || printf '%s=done\n' "$1" >> "$STATE_FILE"; }
state_clear(){ : > "$STATE_FILE"; }
state_unmark(){
  # 단일 키 제거. macOS 의 BSD sed 호환을 위해 임시파일 사용.
  local tmp; tmp="$(mktemp)"
  grep -vx "$1=done" "$STATE_FILE" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$STATE_FILE"
}

# run_step KEY "사람이 읽는 설명" -- command args...
# 이미 완료된 단계면 스킵. 성공 시 자동 마킹.
run_step() {
  local key="$1" desc="$2"; shift 2
  if [ "${1:-}" = "--" ]; then shift; fi
  if state_has "$key"; then
    info "[skip] $desc  (이미 완료: $key)"
    return 0
  fi
  title "$desc"
  if "$@"; then
    state_mark "$key"
    ok "완료: $key"
    return 0
  else
    local rc=$?
    err "단계 실패: $key (rc=$rc)"
    return $rc
  fi
}

# ── OS 검증 ──────────────────────────────────────────────────────────────────
require_macos() {
  [ "$(uname -s)" = "Darwin" ] || die "이 도구는 macOS 전용입니다. (감지: $(uname -s))"
}

# ── 명령 존재 확인 ────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

# ── 임시파일 안전 생성 + 정리 ────────────────────────────────────────────────
mktempd() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/openclaw-mgr.XXXXXX")"
  printf '%s\n' "$d"
}

# 호출자가 trap 'cleanup_tmp' EXIT 로 등록할 수 있도록 배열 대신 변수 누적.
_TMP_DIRS=""
register_tmp() { _TMP_DIRS="$_TMP_DIRS $1"; }
cleanup_tmp() {
  local d
  for d in $_TMP_DIRS; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf -- "$d"
  done
}

# ── 진입 디렉터리(스크립트 위치) ──────────────────────────────────────────────
# OPENCLAW_MGR_DIR 은 dispatcher 가 export 한다. 안전하게 fallback.
: "${OPENCLAW_MGR_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"
export OPENCLAW_MGR_DIR
