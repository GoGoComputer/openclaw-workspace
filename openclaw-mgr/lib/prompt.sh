#!/usr/bin/env bash
# =============================================================================
# lib/prompt.sh — 대화형 입력 헬퍼
# -----------------------------------------------------------------------------
# 목적   : 비어 있는 환경변수를 사용자에게 물어 채운다 (검증 콜백 지원)
# 입력   : (라이브러리)
# 출력   : 입력값을 stdout 으로
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================

# ask_value "메시지" "기본값" [검증함수] → echo 입력값
ask_value() {
  local prompt="$1" default="${2:-}" validator="${3:-}"
  local val
  if [ "${NONINTERACTIVE:-0}" = "1" ] || [ ! -t 0 ]; then
    printf '%s' "$default"
    return 0
  fi
  while :; do
    if [ -n "$default" ]; then
      printf '%s? %s [%s]: %s' "$C_YELLOW" "$prompt" "$default" "$C_RESET" >&2
    else
      printf '%s? %s: %s' "$C_YELLOW" "$prompt" "$C_RESET" >&2
    fi
    IFS= read -r val || val=""
    val="${val:-$default}"
    if [ -n "$validator" ]; then
      if "$validator" "$val"; then
        printf '%s' "$val"
        return 0
      else
        err "값이 유효하지 않습니다. 다시 입력해 주세요."
        continue
      fi
    fi
    printf '%s' "$val"
    return 0
  done
}

# ask_secret "메시지" → echo (입력 시 화면 표시 없음)
ask_secret() {
  local prompt="$1" val
  if [ "${NONINTERACTIVE:-0}" = "1" ] || [ ! -t 0 ]; then
    printf ''
    return 0
  fi
  printf '%s? %s: %s' "$C_YELLOW" "$prompt" "$C_RESET" >&2
  stty -echo 2>/dev/null
  IFS= read -r val || val=""
  stty echo 2>/dev/null
  printf '\n' >&2
  printf '%s' "$val"
}
