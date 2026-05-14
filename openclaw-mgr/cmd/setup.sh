#!/usr/bin/env bash
# =============================================================================
# cmd/setup.sh — OpenClaw 첫 설정 / 재설정 마법사
# -----------------------------------------------------------------------------
# 사용법 / Usage:
#   ./openclaw setup            # 대화형 마법사 (`openclaw onboard` 를 Docker 안에서)
#   ./openclaw setup status     # 현재 설정 상태만 확인 (변경 없음)
#   ./openclaw setup --skip-confirm   # 기존 설정 있어도 확인 없이 바로 마법사
#
# 동작 / How it works:
#   1) OpenClaw 본체의 `openclaw onboard` 를 격리된 Docker 컨테이너 안에서
#      `docker compose run --rm openclaw-cli onboard` 로 실행.
#   2) 마법사는 게이트웨이·인증·워크스페이스·모델·플러그인 등을 차례로 묻고
#      결과를 $OPENCLAW_CONFIG_DIR (기본 ~/.openclaw) 에 영구 저장.
#   3) 호스트에는 아무것도 직접 설치하지 않음. Ctrl+C 로 안전하게 빠져나올 수 있음.
#   4) 멱등 — 언제든지 다시 실행하면 기존 답은 기본값으로 미리 채워짐. 답하기
#      싫은 항목은 Enter 로 기본값 유지.
#
# Tip: 모델만 빠르게 바꾸려면 `./openclaw models add <name>` 또는
#      `./openclaw chat` 의 인터랙티브 모델 picker 가 더 편합니다.
#
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"

skip_confirm=0
action="wizard"

while [ $# -gt 0 ]; do
  case "$1" in
    status)         action="status"; shift ;;
    wizard|"")      action="wizard"; shift ;;
    --skip-confirm) skip_confirm=1; shift ;;
    -h|--help|help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)              die "알 수 없는 인자: $1  (사용: setup [status] [--skip-confirm])" ;;
  esac
done

# ── status: 현재 상태만 ──────────────────────────────────────────────────────
if [ "$action" = "status" ]; then
  printf '\n  %sOpenClaw 설정 상태%s\n' "$C_BOLD$C_CYAN" "$C_RESET" >&2
  printf '  %s──────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET" >&2
  if [ -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ]; then
    ok "설정 파일: $OPENCLAW_CONFIG_DIR/openclaw.json"
    info "  최근 수정: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$OPENCLAW_CONFIG_DIR/openclaw.json" 2>/dev/null || echo 'unknown')"
    info "  최상위 키:"
    python3 -c '
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"    (read error: {e})"); sys.exit(0)
for k in cfg.keys():
    print(f"    - {k}")
' "$OPENCLAW_CONFIG_DIR/openclaw.json" 2>/dev/null || true
  else
    warn "설정 파일 없음: $OPENCLAW_CONFIG_DIR/openclaw.json"
    info "  ./openclaw setup  으로 마법사 실행"
  fi
  printf '\n' >&2
  exit 0
fi

# ── wizard: 사전 점검 ───────────────────────────────────────────────────────
[ -d "$OPENCLAW_DIR/.git" ] \
  || die "OpenClaw 가 설치되지 않았습니다. 먼저 실행:  ./openclaw install"
have docker \
  || die "docker 가 필요합니다. Docker Desktop 실행 중인지 확인하세요."
docker info >/dev/null 2>&1 \
  || die "Docker 데몬이 응답하지 않습니다. Docker Desktop 을 시작한 뒤 다시 시도하세요."

# ── 기존 설정 감지 → 재실행 확인 ────────────────────────────────────────────
if [ -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ] && [ "$skip_confirm" != "1" ]; then
  title "기존 OpenClaw 설정이 있어요"
  info "  위치: $OPENCLAW_CONFIG_DIR/openclaw.json"
  info "  다시 실행해도 안전합니다 — 마법사는 기존 답을 기본값으로 채워주고,"
  info "  답하기 싫은 항목은 Enter 로 그대로 유지할 수 있어요."
  if ! confirm "재설정 마법사를 시작할까요?" n; then
    info "취소됨. 기존 설정 유지."
    exit 0
  fi
fi

title "OpenClaw 설정 마법사"
info "  컨테이너 안에서 'openclaw onboard' 를 격리 실행합니다."
info "  설정·토큰은 ${OPENCLAW_CONFIG_DIR} 에 저장됩니다 (호스트에는 직접 설치 안 함)."
info "  중간에 Ctrl+C 로 안전하게 빠져나올 수 있고, 다시 실행하면 이어서 됩니다."
hr

# ── 사전 점검: 컨테이너에서 호스트 Ollama 에 닿는지 ─────────────────────────
# 마법사는 'Ollama base URL' 단계에서 'http://127.0.0.1:11434' 를 기본값으로
# 보여주지만, 컨테이너 안의 127.0.0.1 은 컨테이너 자신이라 호스트 Ollama 에
# 닿지 않습니다. 호스트 Ollama 는 컨테이너 입장에선 'host.docker.internal'.
# (OpenClaw 본체는 이 URL 을 env/CLI 로 받지 않고 사용자 입력만 받음 —
#  따라서 우리가 해줄 수 있는 건 명확한 사전 안내.)
ollama_in_container_url="http://host.docker.internal:11434"
host_ollama_ok=0
cd "$OPENCLAW_DIR"
if docker compose run --rm --entrypoint="" --no-deps openclaw-cli \
     sh -c "curl -sf --max-time 3 ${ollama_in_container_url}/api/tags >/dev/null" \
     >/dev/null 2>&1; then
  host_ollama_ok=1
fi

if [ "$host_ollama_ok" = "1" ]; then
  printf '\n%s┌─────────────────────────────────────────────────────────────┐%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ ⚠  마법사 안에서 "Ollama base URL" 단계가 나오면 다음을 입력 │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│                                                             │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│    %shttp://host.docker.internal:11434%s%s                    │%s\n' "$C_BOLD$C_YELLOW" "$C_BOLD$C_GREEN" "$C_RESET" "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│                                                             │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ 기본값으로 보이는 http://127.0.0.1:11434 는                  │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ 컨테이너 자신을 가리켜서 호스트 Ollama 에 닿지 못합니다.    │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s└─────────────────────────────────────────────────────────────┘%s\n\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  info "사전 점검: 컨테이너 → ${ollama_in_container_url}  ${C_GREEN}REACHABLE${C_RESET}"
else
  warn "사전 점검: 컨테이너에서 호스트 Ollama 가 응답 안 함."
  warn "  • Ollama 앱이 실행 중인가요?  (메뉴바 또는: ollama serve)"
  warn "  • 네트워크 모드가 isolated 면 host.docker.internal 도 차단됩니다."
  warn "    → ./openclaw network online --restart  후 다시 시도"
  if [ -t 0 ] && [ "${NONINTERACTIVE:-0}" != "1" ]; then
    confirm "그래도 마법사를 계속 실행할까요? (마법사가 중간에 실패할 수 있음)" n || exit 1
  fi
fi
hr

# ── 실행 ────────────────────────────────────────────────────────────────────
# `run --rm` 이라 종료 시 컨테이너 자동 삭제. gateway 는 이미 떠 있으면 재사용.
# entrypoint(`node dist/index.js`) 가 'onboard' 를 인자로 받아 본체 마법사 실행.
docker compose run --rm openclaw-cli onboard
rc=$?

hr
if [ "$rc" = "0" ]; then
  ok "설정 마법사 완료."
  info "  설정 확인:  ./openclaw setup status"
  info "  채팅 시작:  ./openclaw chat   (또는 docker compose run --rm openclaw-cli tui)"
else
  warn "마법사가 정상 종료되지 않았습니다 (rc=$rc)."
  info "  중간에 빠져나왔다면 같은 명령으로 이어서 진행:  ./openclaw setup"
  info "  'Ollama not reachable' 로 끊겼다면 — 'Ollama base URL' 단계에서"
  info "    http://127.0.0.1:11434  대신  ${C_BOLD}http://host.docker.internal:11434${C_RESET}  을 입력하세요."
fi
exit "$rc"
