#!/usr/bin/env bash
# =============================================================================
# cmd/doctor.sh — 현재 상태 진단
# 출력: ✓/✗/⚠ 표 + 권장 조치
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/detect.sh"

# detect 결과를 지역 변수로 eval.
eval "$(detect_all)"
eval "$(detect_schedule)"
eval "$(detect_korea_ai)"

_row() {
  # _row "라벨" "상태(yes/no/warn)" "현재값" "권장조치"
  local label="$1" status="$2" value="$3" hint="$4"
  local mark color
  case "$status" in
    yes|ok|good) mark="✓"; color="$C_GREEN" ;;
    no|bad)      mark="✗"; color="$C_RED" ;;
    *)           mark="⚠"; color="$C_YELLOW" ;;
  esac
  printf '  %s%s%s  %-22s %s%s%s\n' \
    "$color" "$mark" "$C_RESET" \
    "$label" \
    "$C_DIM" "${value:-—}" "$C_RESET"
  [ -n "$hint" ] && printf '       %s↳ %s%s\n' "$C_DIM" "$hint" "$C_RESET"
}

title "OpenClaw 시스템 진단"
hr

# 하드웨어 / OS
_row "OS"             "$( [ "$os_name" = "Darwin" ] && echo yes || echo no )" \
     "$os_name $macos_version $os_arch" "macOS 전용입니다"
_row "CPU"            "yes" "$cpu_brand" ""

ram_status="yes"
ram_hint=""
if [ "${ram_gb:-0}" -lt 16 ] 2>/dev/null; then
  ram_status="no"; ram_hint="16GB 이상 권장 (24GB 권장)"
elif [ "${ram_gb:-0}" -lt 24 ] 2>/dev/null; then
  ram_status="warn"; ram_hint="24GB 권장 — 7B 모델은 동작하나 여유 부족"
fi
_row "RAM"            "$ram_status" "${ram_gb}GB" "$ram_hint"

disk_status="yes"; disk_hint=""
if [ "${disk_free_gb:-0}" -lt 20 ] 2>/dev/null; then
  disk_status="no"; disk_hint="여유 공간 20GB 이상 필요 (이미지+모델)"
elif [ "${disk_free_gb:-0}" -lt 50 ] 2>/dev/null; then
  disk_status="warn"; disk_hint="50GB 이상 권장"
fi
_row "디스크 여유"    "$disk_status" "${disk_free_gb}GB" "$disk_hint"

hr
# 도구 설치
_row "Xcode CLT"      "$xcode_clt_installed" "" "없으면 install 이 자동 설치"
_row "Homebrew"       "$brew_installed"      "$brew_prefix" "없으면 install 이 자동 설치"
_row "Docker"         "$docker_installed"    "" "Docker Desktop 필요"

drun_status="$docker_running"
drun_hint=""
[ "$docker_running" = "no" ] && drun_hint="Docker Desktop 앱을 실행하세요"
_row "Docker 데몬"    "$drun_status" "" "$drun_hint"
_row "Compose v2"     "$compose_v2"  "" "Docker Desktop에 기본 포함"

ENABLE_OLLAMA="${ENABLE_OLLAMA:-1}"
if [ "$ENABLE_OLLAMA" = "1" ]; then
  _row "Ollama"         "$ollama_installed" "" "없으면 install 이 자동 설치"
  _row "Ollama 데몬"    "$ollama_running"   "127.0.0.1:11434" \
       "$( [ "$ollama_running" = no ] && echo 'brew services start ollama' || echo '' )"
  _row "Ollama 모델"    "$( [ -n "$ollama_models" ] && echo yes || echo warn )" \
       "${ollama_models:-(없음)}" \
       "$( [ -z "$ollama_models" ] && echo 'install 시 OLLAMA_MODELS 자동 pull' || echo '')"
else
  _row "Ollama"         "warn" "비활성 (ENABLE_OLLAMA=0)" "외부 API 사용 모드"
fi

hr
# OpenClaw 저장소
_row "OpenClaw 저장소" "$repo_cloned" "$repo_dir" \
     "$( [ "$repo_cloned" = no ] && echo '.env 의 OPENCLAW_REPO 를 먼저 채우세요' || echo '')"
[ "$repo_cloned" = "yes" ] && _row "  ↳ 브랜치"     "yes" "$repo_branch" ""
[ "$repo_cloned" = "yes" ] && [ "$repo_dirty" = "yes" ] && \
  _row "  ↳ 변경사항"   "warn" "dirty" "커밋 안 된 변경사항 있음 — update 차단됨"

hr
# 컨테이너 상태
_row "컨테이너 실행"  "$compose_up" "${compose_container_count}개" \
     "$( [ "$compose_up" = no ] && echo './openclaw start' || echo '' )"

# 포트 충돌
if [ -n "${port_conflicts:-}" ]; then
  _row "포트 충돌"      "warn" "$port_conflicts" "다른 프로세스가 포트를 사용 중"
else
  _row "포트"           "yes" "11434, ${OPENCLAW_PORT:-8000} 사용 가능" ""
fi

hr
# 자동 스케줄
_row "자동 업데이트"  "$( [ "$schedule_enabled" = yes ] && echo yes || echo warn )" \
     "$( [ "$schedule_enabled" = yes ] && echo 'launchd 등록됨' || echo '미설정' )" \
     "$( [ "$schedule_enabled" = no ] && echo './openclaw schedule enable' || echo '' )"

hr
# 네트워크 격리 모드 (보안 핵심)
_net_file="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/network-mode"
_net_mode="$( [ -f "$_net_file" ] && cat "$_net_file" || echo isolated )"
if [ "$_net_mode" = "isolated" ]; then
  _row "네트워크 격리"   "yes" "isolated (외부 차단)" \
       "최고 보안 — 설치/업데이트 시 ./openclaw network online --restart"
else
  _row "네트워크 격리"   "warn" "online (인터넷 허용)" \
       "끝나면 복귀: ./openclaw network isolated --restart"
fi

hr
# korea-sovereign-ai (자매 프로젝트) 자연 호환 안내
if [ "$korea_ai_detected" = "yes" ]; then
  _row "한국 소버린 AI"  "yes" "${korea_ai_models:-(repo only)}" \
       "감지됨 — OpenClaw 가 그대로 사용 가능"
  [ -n "$korea_ai_dir" ] && _row "  ↳ repo" "yes" "$korea_ai_dir" ""
else
  _row "한국 소버린 AI"  "warn" "(미감지)" \
       "원하면: github.com/GoGoComputer/korea-sovereign-ai (EXAONE/A.X/Solar)"
fi

hr

# 종합 요약
issues=0
[ "$docker_installed" = "no" ] && issues=$((issues+1))
[ "$docker_running" = "no" ] && issues=$((issues+1))
[ "$repo_cloned" = "no" ] && issues=$((issues+1))
[ "$compose_up" = "no" ] && issues=$((issues+1))

if [ "$issues" -eq 0 ]; then
  ok "모두 정상입니다 🎉"
else
  warn "$issues 개 항목이 미설정입니다 — './openclaw install' 로 자동 해결됩니다"
fi
