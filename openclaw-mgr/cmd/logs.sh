#!/usr/bin/env bash
# cmd/logs.sh — 컨테이너 로그를 실시간으로 출력 (시크릿 마스킹 적용)
# 사용: ./openclaw logs [service]
# Copyright 2026 박성모 Park Sungmo — MIT License
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다."
cd "$OPENCLAW_DIR"

# 시크릿 패턴은 마스킹 함수로 통과시킨 뒤 출력.
docker compose logs -f --tail=200 "$@" 2>&1 | sec_mask
