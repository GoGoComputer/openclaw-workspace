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
# install 의 step_sandbox 가 생성한 docker.sock 마운트 오버레이.
# 없으면 (샌드박스 비활성 또는 사용자가 OPENCLAW_SANDBOX=0 으로 설정) 그냥 스킵.
sandbox="$OPENCLAW_DIR/docker-compose.sandbox.yml"
# 호스트 경로 일치 오버레이 (v0.2.20 에서 실험했다가 회귀 발견하고 일시 비활성화).
# OpenClaw 본체의 config-loader 가 startup 단계에서 hang 하는 부작용이 있어
# 안전한 default 가 확정되기 전까지는 포함하지 않는다.
# host_paths="${OPENCLAW_MGR_DIR}/compose.host-paths.yml"
host_paths=""

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
# 🛡 샌드박스 오버레이 포함 — 없으면 gateway 컨테이너 안에 /var/run/docker.sock
# 마운트가 빠져, 봇이 도구 실행할 때 "Failed to inspect sandbox image: dial
# unix /var/run/docker.sock: no such file or directory" 로 떨어진다. install
# 의 step_sandbox 가 이 파일을 만들지만 그 직후 ./openclaw stop && start 만
# 해도 이 오버레이가 빠지는 게 v0.2.16 까지의 회귀였다.
[ -f "$sandbox" ] && args+=(-f "$sandbox")
# 🌐 호스트 경로 일치 오버레이 — sandbox sub-container 의 mount 인자가
# `/home/node/...` (컨테이너 내부 경로) 로 가서 Docker daemon 이 "mounts
# denied: not shared from the host" 로 거절하던 v0.2.19 의 잔여 회귀를 막음.
# OpenClaw 가 envHomedir() 로 보는 모든 경로 변수를 호스트 기준 절대경로로
# 강제하고, 그 경로를 컨테이너에 그대로 마운트 (호스트 경로 = 컨테이너 경로).
[ -f "$host_paths" ] && args+=(-f "$host_paths")
docker compose "${args[@]}" up -d
ok "컨테이너 시작 완료"

# ─────────────────────────────────────────────────────────────────────────────
# 게이트웨이 자동 복구 (회귀 방어)
# 2026-04 무렵의 OpenClaw 본체는 첫 부팅에서 토큰만 쓰고 `gateway.mode` 를
# 안 채워, 두 번째 부팅부터 "Gateway start blocked: existing config is
# missing gateway.mode" 로 무한 재시작 루프에 빠진다. 사용자 입장에선
# `open http://127.0.0.1:18789` 가 항상 "can't connect" 가 된다.
# 우리가 할 수 있는 가장 안전한 회복은: 컨피그가 있는데 `gateway.mode` 만
# 비어 있을 때 `local` 로 채워주는 것 (= 메시지가 권하는 수동 조치와 동일).
# ─────────────────────────────────────────────────────────────────────────────
cfg_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
cfg_file="$cfg_dir/openclaw.json"
if [ -f "$cfg_file" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$cfg_file" <<'PY' || true
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
try:
    cfg = json.loads(p.read_text())
except Exception:
    sys.exit(0)
gw = cfg.setdefault("gateway", {})
if "mode" not in gw:
    gw["mode"] = "local"
    p.write_text(json.dumps(cfg, indent=2))
    print("✓ gateway.mode 자동 설정 (local) — 회귀 회복")
PY
fi
