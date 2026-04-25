#!/usr/bin/env bash
# =============================================================================
# cmd/stop.sh — OpenClaw 컨테이너 정지 / Stop OpenClaw containers
# -----------------------------------------------------------------------------
# 목적   : `docker compose stop` 호출 — 컨테이너는 정지되지만
#          볼륨·네트워크·.env 는 그대로 남아 `start` 로 재개 가능.
# 사용   : ./openclaw stop
# 관련   : start.sh (재시작), uninstall.sh (완전 제거)
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다."
cd "$OPENCLAW_DIR"
docker compose stop
ok "컨테이너 정지 완료 (데이터는 보존됨)"
