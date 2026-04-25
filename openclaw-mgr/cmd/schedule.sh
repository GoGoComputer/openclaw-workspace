#!/usr/bin/env bash
# =============================================================================
# cmd/schedule.sh — 매일 자동 update launchd 스케줄
# 사용: ./openclaw schedule enable | disable | status
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

LABEL="com.user.openclaw.update"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/${LABEL}.plist"
SCRIPT_PATH="$OPENCLAW_MGR_DIR/openclaw"
SCHEDULE_TIME="${SCHEDULE_TIME:-03:00}"

action="${1:-status}"

case "$action" in
  enable)
    [ -x "$SCRIPT_PATH" ] || die "스크립트 실행권한 없음: $SCRIPT_PATH"
    case "$SCHEDULE_TIME" in
      [0-9][0-9]:[0-9][0-9]) ;;
      *) die "SCHEDULE_TIME 형식 오류 (HH:MM): $SCHEDULE_TIME" ;;
    esac
    HOUR="${SCHEDULE_TIME%%:*}"
    MIN="${SCHEDULE_TIME##*:}"
    # 절대경로 검증
    case "$SCRIPT_PATH" in /*) ;; *) die "절대경로 아님: $SCRIPT_PATH" ;; esac

    mkdir -p "$PLIST_DIR" "$LOG_DIR"
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${SCRIPT_PATH}</string>
    <string>update</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>${HOUR#0}</integer>
    <key>Minute</key><integer>${MIN#0}</integer>
  </dict>
  <key>StandardOutPath</key><string>${LOG_DIR}/update.out.log</string>
  <key>StandardErrorPath</key><string>${LOG_DIR}/update.err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OPENCLAW_MGR_DIR</key><string>${OPENCLAW_MGR_DIR}</string>
    <key>HOME</key><string>${HOME}</string>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key><false/>
</dict>
</plist>
EOF
    chmod 644 "$PLIST"
    sec_check_plist "$PLIST" || die "plist 보안 검증 실패"

    # 기존 등록 제거 후 재등록
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
    ok "매일 ${SCHEDULE_TIME} 에 자동 업데이트 (label: $LABEL)"
    info "로그: $LOG_DIR/update.{out,err}.log"
    ;;
  disable)
    if [ -f "$PLIST" ]; then
      launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
      rm -f -- "$PLIST"
      ok "스케줄 해제됨"
    else
      info "이미 해제 상태"
    fi
    ;;
  status)
    if launchctl list 2>/dev/null | grep -q "$LABEL"; then
      ok "활성화됨 (label: $LABEL, 매일 ${SCHEDULE_TIME})"
    else
      warn "비활성화됨 — './openclaw schedule enable' 로 활성화"
    fi
    ;;
  *)
    die "사용법: ./openclaw schedule enable|disable|status"
    ;;
esac
