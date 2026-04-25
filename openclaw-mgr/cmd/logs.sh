#!/usr/bin/env bash
# =============================================================================
# cmd/logs.sh — 컨테이너 로그 실시간 출력 / Stream container logs
# -----------------------------------------------------------------------------
# 목적   : Docker Compose 로그를 tail -f 하되, 시크릿을 마스킹해 터미널에
#          노출되지 않도록 한다 (lib/sec.sh 의 mask_secrets).
# 사용   : ./openclaw logs [service]
#          - service 생략 시 전체 스택의 로그
#          - service 지정 시 해당 서비스 만 (예: openclaw, ollama)
# 종료   : Ctrl-C 로 나가면 docker compose 는 계속 돌아갑니다.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
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
