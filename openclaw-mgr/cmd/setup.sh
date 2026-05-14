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

# ── 실행 ────────────────────────────────────────────────────────────────────
# `run --rm` 이라 종료 시 컨테이너 자동 삭제. gateway 는 이미 떠 있으면 재사용.
# entrypoint(`node dist/index.js`) 가 'onboard' 를 인자로 받아 본체 마법사 실행.
cd "$OPENCLAW_DIR"
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
fi
exit "$rc"
