#!/usr/bin/env bash
# cmd/start.sh — OpenClaw 컨테이너 시작 (compose up -d)
# Copyright 2026 박성모 Park Sungmo — MIT License
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/openclaw}"
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
