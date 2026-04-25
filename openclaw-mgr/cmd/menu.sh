#!/usr/bin/env bash
# =============================================================================
# cmd/menu.sh — 대화형 메뉴 (비개발자용 런처)
#               Interactive menu launcher for non-developers
# -----------------------------------------------------------------------------
# 사용 / Usage:
#   ./openclaw menu          # 또는 / or just  ./openclaw
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/update_check.sh"

# Current launcher version (read from the dispatcher).
MGR_VERSION="$(awk -F'"' '/^VERSION=/{print $2; exit}' "${OPENCLAW_MGR_DIR}/openclaw" 2>/dev/null || echo 0.0.0)"

# 언어 자동 감지: LANG 이 한국어면 KO, 아니면 EN.
# Auto language detection: Korean if LANG starts with ko, else English.
LANG_PREF="en"
case "${LANG:-}" in ko*|*KR*) LANG_PREF="ko" ;; esac
[ "${OPENCLAW_LANG:-}" = "ko" ] && LANG_PREF="ko"
[ "${OPENCLAW_LANG:-}" = "en" ] && LANG_PREF="en"

t() {
  # bilingual text helper:  t "한국어" "English"
  if [ "$LANG_PREF" = "ko" ]; then printf '%s' "$1"; else printf '%s' "$2"; fi
}

show_menu() {
  clear 2>/dev/null || true
  local mode_file="${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/network-mode"
  local mode; mode="$( [ -f "$mode_file" ] && cat "$mode_file" || echo isolated )"
  local mode_icon
  case "$mode" in isolated) mode_icon="🔒 isolated" ;; *) mode_icon="🌐 online" ;; esac

  cat <<EOF

  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║   $(t "OpenClaw 관리 런처                                       " "OpenClaw Management Launcher                          ")║
  ║   $(t "한 화면에서 모든 관리·유지보수                              " "All management & maintenance in one place             ")║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

  $(t "현재 네트워크 모드" "Current network mode") : ${mode_icon}

  ─── $(t "진단 / Diagnose" "Diagnose") ─────────────────────────────────────────
   1) $(t "현재 상태 점검 (doctor)" "Check current state (doctor)")

  ─── $(t "설치 / Install" "Install") ─────────────────────────────────────────
   2) $(t "자동 설치 (이미 된 부분은 건너뜀)" "Auto-install (skip already-done parts)")

  ─── $(t "실행 / Run" "Run") ─────────────────────────────────────────────────
   3) $(t "컨테이너 시작 (start)" "Start container (start)")
   4) $(t "컨테이너 정지 (stop)" "Stop container (stop)")
   5) $(t "로그 보기 (logs)" "View logs (logs)")

  ─── $(t "유지보수 / Maintenance" "Maintenance") ──────────────────────────────
   6) $(t "업데이트 (update)" "Update (update)")
   7) $(t "백업 (backup)" "Backup (backup)")
   8) $(t "복원 (restore)" "Restore (restore)")
   9) $(t "메모리·디스크 정리 (clean)" "Memory/disk cleanup (clean)")
  10) $(t "매일 자동 업데이트 켜기/끄기 (schedule)" "Toggle daily auto-update (schedule)")

  ─── $(t "보안 / Security" "Security") ───────────────────────────────────────
  11) $(t "네트워크 격리 토글 (network)" "Toggle network isolation (network)")

  ─── $(t "삭제 / Uninstall" "Uninstall") ────────────────────────────────────
  12) $(t "OpenClaw 제거 (uninstall)" "Remove OpenClaw (uninstall)")

  ─── $(t "매니저 / Manager" "Manager") ──────────────────────────────────────
  13) $(t "매니저 자체 업데이트 (self-update)" "Update this launcher (self-update)")

   q) $(t "종료" "Quit")

EOF
  # Show "new version available" banner if applicable. Safe / silent on errors.
  update_check_banner "$MGR_VERSION" "$LANG_PREF" || true
  printf '  %s ' "$(t '번호 선택:' 'Select number:')"
}

run_cmd() { bash "$OPENCLAW_MGR_DIR/cmd/$1.sh" "${@:2}"; }
pause()   { printf '\n  %s ' "$(t 'Enter 키로 메뉴로 돌아가기...' 'Press Enter to return to menu...')"; read -r _; }

while true; do
  show_menu
  read -r choice || break
  case "${choice:-}" in
    1)  run_cmd doctor   || true; pause ;;
    2)  run_cmd install  || true; pause ;;
    3)  run_cmd start    || true; pause ;;
    4)  run_cmd stop     || true; pause ;;
    5)
      printf '  %s ' "$(t '서비스 이름 (없으면 Enter):' 'Service name (Enter for all):')"
      read -r svc || true
      run_cmd logs $svc || true; pause ;;
    6)  run_cmd update   || true; pause ;;
    7)
      printf '  %s ' "$(t '백업 이름 (선택, Enter 가능):' 'Backup name (optional, Enter to skip):')"
      read -r name || true
      if [ -n "${name:-}" ]; then run_cmd backup --name "$name" || true
      else                         run_cmd backup              || true; fi
      pause ;;
    8)
      printf '  %s ' "$(t '복원할 .tar.gz 경로:' 'Path to .tar.gz to restore:')"
      read -r f || true
      [ -n "${f:-}" ] && run_cmd restore "$f" || true; pause ;;
    9)
      printf '  %s [s=status, l=light, a=all, i=interactive]: ' \
        "$(t '청소 모드' 'Clean mode')"
      read -r m || true
      case "${m:-i}" in
        s) run_cmd clean --status ;;
        l) run_cmd clean --light  ;;
        a) run_cmd clean --all    ;;
        *) run_cmd clean          ;;
      esac
      pause ;;
    10)
      printf '  %s [e=enable, d=disable, s=status]: ' \
        "$(t '스케줄' 'Schedule')"
      read -r m || true
      case "${m:-s}" in
        e) run_cmd schedule enable  ;;
        d) run_cmd schedule disable ;;
        *) run_cmd schedule status  ;;
      esac
      pause ;;
    11)
      printf '  %s [i=isolated, o=online, s=status]: ' \
        "$(t '네트워크' 'Network')"
      read -r m || true
      case "${m:-s}" in
        i) run_cmd network isolated --restart ;;
        o) run_cmd network online   --restart ;;
        *) run_cmd network status             ;;
      esac
      pause ;;
    12)
      printf '  %s [Y/n]: ' "$(t '정말 제거할까요?' 'Really uninstall?')"
      read -r yn || true
      case "${yn:-Y}" in
        Y|y|yes|네|예)
          printf '  %s [y/N]: ' "$(t 'Docker/Ollama 까지 제거(--purge)?' 'Also remove Docker/Ollama (--purge)?')"
          read -r purge || true
          case "${purge:-N}" in
            y|Y) run_cmd uninstall --purge || true ;;
            *)   run_cmd uninstall          || true ;;
          esac
          pause ;;
      esac ;;
    13) run_cmd self-update || true; pause ;;
    q|Q|"") clear 2>/dev/null || true; exit 0 ;;
    *)
      printf '  %s\n' "$(t '알 수 없는 선택입니다.' 'Unknown selection.')"; pause ;;
  esac
done
