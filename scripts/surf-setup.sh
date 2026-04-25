#!/usr/bin/env bash
# =============================================================================
# scripts/surf-setup.sh — 웹서핑 샌드박스 1회성 세팅
# -----------------------------------------------------------------------------
# 사용: ./scripts/surf-setup.sh
# - SURF_HOME (기본 ~/openclaw-surf) 디렉터리 생성
# - Playwright Docker 이미지 사전 pull (~700MB, 한 번만)
# - ~/bin/surf 런처 심볼릭 링크
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SURF_HOME="${SURF_HOME:-$HOME/openclaw-surf}"
IMAGE="mcr.microsoft.com/playwright/python:v1.46.0-jammy"

c_ok()   { printf '\033[0;32m✔\033[0m %s\n' "$*"; }
c_info() { printf '\033[0;36m▸\033[0m %s\n' "$*"; }
c_die()  { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

c_info "SURF_HOME = $SURF_HOME"
mkdir -p "$SURF_HOME/out"
chmod 700 "$SURF_HOME"
c_ok "디렉터리 준비"

command -v docker >/dev/null || c_die "Docker 가 필요합니다 (Docker Desktop 설치)"
docker info >/dev/null 2>&1 || c_die "Docker 가 실행 중이 아닙니다 — Docker Desktop 실행"

c_info "Playwright 이미지 사전 pull (~700MB, 한 번만)"
docker pull "$IMAGE"
c_ok "이미지 준비: $IMAGE"

mkdir -p "$HOME/bin"
ln -snf "$REPO_DIR/scripts/surf" "$HOME/bin/surf"
c_ok "런처: ~/bin/surf"

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) printf '\033[0;33m!\033[0m ~/bin 이 PATH 에 없습니다. ~/.zshrc 에 추가:\n    export PATH="$HOME/bin:$PATH"\n' ;;
esac

cat <<EOF

다음 단계:

  surf "오늘 코스피 종가와 거래대금"
  surf "이번 주 IT 빅뉴스" --max 8
  surf "S&P 500 weekly recap" --lang en

상세: docs/GUIDE-WEB-FETCH.md (샌드박스 자동 브리프 섹션)
EOF
