#!/usr/bin/env bash
# cmd/stop.sh — OpenClaw 컨테이너 정지 (compose stop, 데이터 보존)
# Copyright 2026 박성모 Park Sungmo — MIT License
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다."
cd "$OPENCLAW_DIR"
docker compose stop
ok "컨테이너 정지 완료 (데이터는 보존됨)"
