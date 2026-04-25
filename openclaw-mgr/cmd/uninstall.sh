#!/usr/bin/env bash
# =============================================================================
# cmd/uninstall.sh — OpenClaw 제거
# 기본: 컨테이너+볼륨+클론 제거. Docker/Ollama 는 보존.
# --purge: brew 패키지(Docker, Ollama)까지 제거.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

PURGE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --purge) PURGE=1; shift ;;
    *) die "알 수 없는 옵션: $1" ;;
  esac
done

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/openclaw}"

title "OpenClaw 제거"
warn "이 작업은 되돌릴 수 없습니다. 먼저 './openclaw backup' 을 권장합니다."
confirm "계속 진행하시겠습니까?" n || die "사용자 취소"

# 1) 자동 스케줄 해제
if launchctl list 2>/dev/null | grep -q com.user.openclaw.update; then
  info "launchd 스케줄 해제"
  bash "$OPENCLAW_MGR_DIR/cmd/schedule.sh" disable || true
fi

# 2) compose down -v
if [ -d "$OPENCLAW_DIR" ]; then
  info "컨테이너+볼륨 제거 (compose down -v)"
  ( cd "$OPENCLAW_DIR" && docker compose down -v --remove-orphans ) || true
fi

# 3) 클론 디렉터리 제거
if [ -d "$OPENCLAW_DIR" ]; then
  if confirm "클론 디렉터리 삭제: $OPENCLAW_DIR ?" y; then
    rm -rf -- "$OPENCLAW_DIR"
    ok "삭제됨: $OPENCLAW_DIR"
  fi
fi

# 4) 상태 파일 초기화
if confirm "$OPENCLAW_MGR_HOME 의 상태/로그 초기화?" y; then
  rm -rf -- "$STATE_FILE" "$LOG_DIR"
  : > "$STATE_FILE" 2>/dev/null || true
  ok "상태 초기화"
fi

# 5) --purge: Docker/Ollama 까지 제거
if [ "$PURGE" = "1" ]; then
  warn "--purge 모드: Docker Desktop / Ollama 까지 제거합니다."
  if confirm "정말 Docker Desktop 를 brew 로 제거?" n; then
    brew uninstall --cask docker || true
  fi
  if confirm "정말 Ollama 를 brew 로 제거?" n; then
    brew services stop ollama 2>/dev/null || true
    brew uninstall ollama || true
    if confirm "Ollama 모델 데이터(~/.ollama)도 삭제?" n; then
      rm -rf -- "$HOME/.ollama"
    fi
  fi
fi

ok "제거 완료"
