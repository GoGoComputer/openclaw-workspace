#!/usr/bin/env bash
# =============================================================================
# cmd/network.sh — OpenClaw 네트워크 모드 토글 (런처)
# -----------------------------------------------------------------------------
# 사용:
#   ./openclaw network status                 # 현재 모드 확인
#   ./openclaw network isolated               # 외부 인터넷 완전 차단 (기본)
#   ./openclaw network online                 # 인터넷 허용 (설치·업데이트 시)
#   ./openclaw network isolated --restart     # 모드 변경 후 자동 재기동
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

STATE_DIR="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}"
mkdir -p "$STATE_DIR"
NET_FILE="$STATE_DIR/network-mode"
OVERRIDE="${OPENCLAW_MGR_DIR}/compose.network.yml"

current_mode() {
  if [ -f "$NET_FILE" ]; then cat "$NET_FILE"; else echo "isolated"; fi
}

write_override() {
  local mode="$1"
  case "$mode" in
    isolated)
      cat >"$OVERRIDE" <<'YAML'
# 자동 생성 — ./openclaw network isolated 로 토글됩니다. 직접 수정 금지.
# isolated: 인터넷 완전 차단 (pip/git/Ollama 모두 불가). 인바운드 웹UI 만 동작.
networks:
  openclaw_isolated:
    driver: bridge
    internal: true            # ← 외부 라우팅 차단 (NAT 없음)
services:
  openclaw-gateway:
    networks:
      - openclaw_isolated
    # DNS 조차 차단해 도메인 해석을 막습니다.
    dns: ["127.0.0.1"]
  openclaw-cli:
    networks:
      - openclaw_isolated
    dns: ["127.0.0.1"]
YAML
      ;;
    online)
      cat >"$OVERRIDE" <<'YAML'
# 자동 생성 — ./openclaw network online 로 토글됨.
# online: 기본 Docker 브리지 네트워크 (인터넷 허용). 설치/업데이트용.
services:
  openclaw-gateway: {}
  openclaw-cli: {}
YAML
      ;;
    *)
      die "알 수 없는 모드: $mode (isolated 또는 online)"
      ;;
  esac
}

apply_mode() {
  local mode="$1" do_restart="${2:-no}"
  write_override "$mode"
  echo "$mode" >"$NET_FILE"
  ok "네트워크 모드 → ${mode}"
  case "$mode" in
    isolated)
      cat <<'TXT'

🔒 isolated 모드 (최고 보안 — 기본):
  • 컨테이너에서 외부 인터넷으로 나가는 모든 통신이 차단됩니다.
  • 막히는 것: pip install, npm install, git clone, GitHub API,
    Hugging Face 다운로드, 호스트 Ollama (host.docker.internal),
    악성 패키지 다운로드, 외부로의 데이터 유출 시도.
  • 가능한 것: 웹UI (127.0.0.1:PORT) 접속, 컨테이너 안에 이미
    설치된 모델/코드 사용, 로컬 파일 작업.
  • 설치·업데이트 잠깐 필요할 때:  ./openclaw network online --restart
TXT
      ;;
    online)
      cat <<'TXT'

🌐 online 모드:
  • 컨테이너에서 인터넷으로 자유롭게 나갈 수 있습니다.
  • 설치/업데이트/Ollama 모델 다운로드 등에 필요합니다.
  • 끝나면 반드시 다시 isolated 로 돌리세요:
      ./openclaw network isolated --restart
TXT
      ;;
  esac
  if [ "$do_restart" = "yes" ]; then
    info "컨테이너 재시작 중..."
    bash "$OPENCLAW_MGR_DIR/cmd/stop.sh" 2>/dev/null || true
    bash "$OPENCLAW_MGR_DIR/cmd/start.sh"
  else
    info "변경 적용에는 컨테이너 재시작이 필요합니다:"
    info "  ./openclaw stop && ./openclaw start"
    info "또는 다음에 같은 명령에 --restart 를 붙이세요."
  fi
}

show_status() {
  local mode; mode="$(current_mode)"
  printf '\n현재 네트워크 모드: \033[1m%s\033[0m\n\n' "$mode"
  case "$mode" in
    isolated) printf '  🔒 인터넷 차단됨 — 가장 안전\n' ;;
    online)   printf '  🌐 인터넷 허용됨 — 필요할 때만 사용 권장\n' ;;
  esac
  printf '\n토글: ./openclaw network isolated|online [--restart]\n\n'
}

action="${1:-status}"
flag="${2:-}"
restart="no"
[ "$flag" = "--restart" ] && restart="yes"

case "$action" in
  status|"")           show_status ;;
  isolated|offline)    apply_mode isolated "$restart" ;;
  online|open)         apply_mode online   "$restart" ;;
  -h|--help|help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)
    die "알 수 없는 동작: $action (status | isolated | online)" ;;
esac
