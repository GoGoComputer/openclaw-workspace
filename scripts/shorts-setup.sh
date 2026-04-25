#!/usr/bin/env bash
# =============================================================================
# scripts/shorts-setup.sh — 쇼츠 파이프라인 1회 세팅
# -----------------------------------------------------------------------------
# 설치/생성:
#   - brew: gallery-dl, python@3.12, ffmpeg, jq
#   - SHORTS_HOME (기본 ~/openclaw-shorts) 디렉터리 + 700 권한
#   - Playwright 영구 프로필: profiles/miri-1, profiles/capcut-1
#   - Python venv + playwright/pillow/requests
#   - .env 템플릿
#   - ~/bin/shorts 심볼릭 링크
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHORTS_HOME="${SHORTS_HOME:-$HOME/openclaw-shorts}"

c_ok()   { printf '\033[0;32m✔\033[0m %s\n' "$*"; }
c_info() { printf '\033[0;36m▸\033[0m %s\n' "$*"; }
c_die()  { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

c_info "SHORTS_HOME = $SHORTS_HOME"

command -v brew >/dev/null || c_die "Homebrew 가 필요합니다 (https://brew.sh)"

c_info "brew 의존성 설치 (이미 있으면 skip)"
for pkg in gallery-dl python@3.12 ffmpeg jq imagemagick; do
  brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done
c_ok "brew 의존성 OK"

mkdir -p "$SHORTS_HOME/"{refs,out,logs,profiles/miri-1,profiles/capcut-1}
chmod 700 "$SHORTS_HOME"
chmod 700 "$SHORTS_HOME/profiles/"*
c_ok "디렉터리 준비"

# .env 템플릿
ENV_FILE="$SHORTS_HOME/.env"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'ENVEOF'
# ────────────────────────────────────────────────────────────────
# openclaw-shorts .env — Playwright 자동화 설정 (호스트 전용)
# ────────────────────────────────────────────────────────────────
SHORTS_HOME="${HOME}/openclaw-shorts"

# Pinterest
REFS_PER_QUERY=12

# 미리캔버스
MIRI_URL="https://www.miricanvas.com/ko"
# 1080x1920 = 쇼츠/릴스 비율
MIRI_CANVAS_W=1080
MIRI_CANVAS_H=1920

# CapCut Web (https://www.capcut.com/editor)
CAPCUT_URL="https://www.capcut.com/editor"
CAPCUT_CLIP_DURATION=2.5      # 이미지 1장당 노출 초
CAPCUT_FPS=30
CAPCUT_RES="1080p"

# Ollama (자막/카피 생성용)
OLLAMA_HOST="http://127.0.0.1:11434"
OLLAMA_TEXT_MODEL="qwen2.5-coder:7b"

# 디버깅
SHORTS_HEADED=0               # 1 = 브라우저 창 보이게
SHORTS_TIMEOUT=45000
ENVEOF
  chmod 600 "$ENV_FILE"
  c_ok ".env 생성: $ENV_FILE"
else
  c_ok ".env 이미 존재 — 유지"
fi

# venv
VENV="$SHORTS_HOME/.venv"
if [ ! -d "$VENV" ]; then
  c_info "Python venv 생성"
  /opt/homebrew/bin/python3.12 -m venv "$VENV" 2>/dev/null \
    || python3 -m venv "$VENV"
fi
. "$VENV/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet "playwright>=1.46" pillow requests
python -m playwright install chromium >/dev/null
c_ok "venv 준비 + playwright chromium"

# launcher
mkdir -p "$HOME/bin"
ln -snf "$REPO_DIR/scripts/shorts" "$HOME/bin/shorts"
c_ok "런처: ~/bin/shorts"

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) printf '\033[0;33m!\033[0m ~/bin 이 PATH 에 없습니다. ~/.zshrc 에 추가:\n    export PATH="$HOME/bin:$PATH"\n' ;;
esac

cat <<EOF

다음 단계:

  1) 미리캔버스 / CapCut 한 번만 로그인:
       shorts miri-login
       shorts capcut-login

  2) 핀터레스트 → 미리캔버스 → CapCut → 쇼츠:
       shorts run "여행 감성 풍경"

상세: docs/GUIDE-SHORTS-PIPELINE.md
EOF
