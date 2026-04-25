#!/usr/bin/env bash
# =============================================================================
# cmd/update.sh — git pull + 이미지 갱신 + Ollama 모델 갱신
# 안전 옵션: pull 은 --ff-only 만 (충돌 자동 머지 금지). PIN 모드면 건너뜀.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR/.git" ] || die "저장소가 없습니다. ./openclaw install 먼저."

title "OpenClaw 업데이트"

# 1) git pull (PIN 모드면 스킵)
if [ -n "${OPENCLAW_PIN_COMMIT:-}" ]; then
  warn "OPENCLAW_PIN_COMMIT 설정됨 — 코드 업데이트 스킵"
else
  if [ -n "$(git -C "$OPENCLAW_DIR" status --porcelain)" ]; then
    err "저장소에 커밋되지 않은 변경사항이 있어 업데이트를 중단합니다."
    err "다음으로 확인: git -C $OPENCLAW_DIR status"
    exit 1
  fi
  info "git pull --ff-only"
  git -C "$OPENCLAW_DIR" pull --ff-only
fi

# 2) compose pull + build + up
cd "$OPENCLAW_DIR"
sec="${OPENCLAW_MGR_DIR}/compose.security.yml"
net="${OPENCLAW_MGR_DIR}/compose.network.yml"
files="-f docker-compose.yml"
[ -f compose.yml ] && files="-f compose.yml"
[ -f "$sec" ] && files="$files -f $sec"

# 업데이트 동안만 잠깐 online 으로 전환 (pull/build 에는 인터넷 필요).
prev_mode_file="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/network-mode"
prev_mode="$( [ -f "$prev_mode_file" ] && cat "$prev_mode_file" || echo isolated )"
info "업데이트 중 임시 online 전환 (이전 모드: $prev_mode)"
bash "$OPENCLAW_MGR_DIR/cmd/network.sh" online >/dev/null
[ -f "$net" ] && files="$files -f $net"

# 종료/실패 시에도 원래 모드로 되돌리기.
restore_net() {
  bash "$OPENCLAW_MGR_DIR/cmd/network.sh" "$prev_mode" >/dev/null || true
  # 마지막에 한 번 더 적용해 컨테이너에 반영.
  cd "$OPENCLAW_DIR"
  local f2="-f docker-compose.yml"
  [ -f compose.yml ] && f2="-f compose.yml"
  [ -f "$sec" ] && f2="$f2 -f $sec"
  [ -f "$net" ] && f2="$f2 -f $net"
  # shellcheck disable=SC2086
  docker compose $f2 up -d || true
  info "네트워크 모드 복귀: $prev_mode"
}
trap restore_net EXIT

info "docker compose pull"
# shellcheck disable=SC2086
docker compose $files pull || warn "pull 실패한 이미지 있음 (빌드로 대체 가능)"

info "docker compose build --pull"
# shellcheck disable=SC2086
docker compose $files build --pull || true

info "docker compose up -d"
# shellcheck disable=SC2086
docker compose $files up -d

# 3) Ollama 모델 갱신
if [ "${ENABLE_OLLAMA:-1}" = "1" ] && [ -n "${OLLAMA_MODELS:-}" ]; then
  if ! sec_validate_models "$OLLAMA_MODELS"; then
    warn "OLLAMA_MODELS 형식 오류 — 스킵"
  else
    IFS=','
    for m in $OLLAMA_MODELS; do
      m="$(printf '%s' "$m" | tr -d '[:space:]')"
      [ -z "$m" ] && continue
      info "ollama pull $m"
      ollama pull "$m" || warn "$m pull 실패"
    done
    unset IFS
  fi
fi

ok "업데이트 완료"
