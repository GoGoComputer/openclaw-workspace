#!/usr/bin/env bash
# =============================================================================
# cmd/start.sh — OpenClaw 컨테이너 시작 / Start OpenClaw containers
# -----------------------------------------------------------------------------
# 목적   : 현재 네트워크 모드(→ ~/.openclaw-mgr/network-mode)에 따라
#          compose.network.yml 을 동적 생성한 뒤 `docker compose up -d`.
# 사용   : ./openclaw start
# 전제   : install 이 한 번이라도 완료되어 ${OPENCLAW_DIR} 가 있어야 함.
# 관련   : stop.sh, network.sh, doctor.sh
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

# .env 자동 마이그레이션 — 0.2.x 이전 .env 는 OPENCLAW_DIR=$HOME/openclaw 로
# 깔려 있어서 신버전 (기본 $HOME/DEV/openclaw) 와 어긋난다. 실제 디렉터리가
# $HOME/DEV/openclaw 에 있으면 자동 보정.
if [ "${OPENCLAW_DIR:-}" = "$HOME/openclaw" ] && [ ! -d "$HOME/openclaw" ] \
   && [ -d "$HOME/DEV/openclaw" ]; then
  warn ".env 의 OPENCLAW_DIR 가 옛 위치(\$HOME/openclaw) 입니다. \$HOME/DEV/openclaw 로 자동 보정합니다."
  for ef in "$OPENCLAW_MGR_DIR/.env" "${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/.env"; do
    [ -f "$ef" ] || continue
    cp -- "$ef" "$ef.bak.$(date +%s)" 2>/dev/null || true
    # macOS sed 호환: -i ''
    sed -i '' 's|^OPENCLAW_DIR=.*|OPENCLAW_DIR="$HOME/DEV/openclaw"|' "$ef" 2>/dev/null || true
    grep -q '^OPENCLAW_WORKSPACE_DIR=' "$ef" || echo 'OPENCLAW_WORKSPACE_DIR="$HOME/DEV/openclawAgent"' >> "$ef"
    grep -q '^OPENCLAW_CONFIG_DIR=' "$ef"   || echo 'OPENCLAW_CONFIG_DIR="$HOME/.openclaw"'           >> "$ef"
  done
  OPENCLAW_DIR="$HOME/DEV/openclaw"
  export OPENCLAW_DIR
fi

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다. ./openclaw install 먼저 실행하세요."

cd "$OPENCLAW_DIR"
sec="${OPENCLAW_MGR_DIR}/compose.security.yml"
net="${OPENCLAW_MGR_DIR}/compose.network.yml"

# 네트워크 override 가 없으면 isolated 로 자동 생성 (기본 = 최고 보안).
if [ ! -f "$net" ]; then
  bash "$OPENCLAW_MGR_DIR/cmd/network.sh" isolated >/dev/null
fi

mode_file="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/network-mode"
mode="$( [ -f "$mode_file" ] && cat "$mode_file" || echo isolated )"
info "네트워크 모드: $mode (변경: ./openclaw network online|isolated --restart)"

args=(-f docker-compose.yml)
[ -f "$sec" ] && args+=(-f "$sec")
[ -f "$net" ] && args+=(-f "$net")
docker compose "${args[@]}" up -d
ok "컨테이너 시작 완료"
