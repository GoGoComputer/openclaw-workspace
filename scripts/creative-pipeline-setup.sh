#!/usr/bin/env bash
# =============================================================================
# scripts/creative-pipeline-setup.sh — Pinterest → LLM → Nano Banana → Figma
# -----------------------------------------------------------------------------
# 목적: 1회성 환경 세팅 — Homebrew 의존성, Python venv, Playwright Chromium,
#       작업 디렉터리, 영구 브라우저 프로필 4개, ~/bin/creative 런처 설치.
# 사용: ./scripts/creative-pipeline-setup.sh
# 다시 돌려도 멱등 (이미 있는 건 건너뜀).
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREATIVE_HOME="${CREATIVE_HOME:-$HOME/openclaw-creative}"

c_bold() { printf '\033[1m%s\033[0m\n' "$*"; }
c_ok()   { printf '\033[0;32m✔\033[0m %s\n' "$*"; }
c_info() { printf '\033[0;36m▸\033[0m %s\n' "$*"; }
c_warn() { printf '\033[0;33m!\033[0m %s\n' "$*"; }
c_die()  { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

c_bold "🎨 Creative pipeline setup"
c_info "CREATIVE_HOME = $CREATIVE_HOME"

# ── 1. Homebrew 의존성 ───────────────────────────────────────────────────────
command -v brew >/dev/null || c_die "Homebrew 가 필요합니다. https://brew.sh"
for pkg in gallery-dl python@3.12 jq imagemagick; do
  if brew list --versions "$pkg" >/dev/null 2>&1; then
    c_ok "$pkg 이미 설치됨"
  else
    c_info "brew install $pkg"
    brew install "$pkg"
  fi
done

# ── 2. 디렉터리 ──────────────────────────────────────────────────────────────
mkdir -p "$CREATIVE_HOME"/{refs,prompts,out,logs}
mkdir -p "$CREATIVE_HOME"/profiles/banana-{1,2,3,4}
chmod 700 "$CREATIVE_HOME" "$CREATIVE_HOME/profiles"
c_ok "디렉터리 준비: $CREATIVE_HOME"

# ── 3. .env (자리만, 채우는 건 사용자가) ─────────────────────────────────────
if [ ! -f "$CREATIVE_HOME/.env" ]; then
  cat > "$CREATIVE_HOME/.env" <<'ENVEOF'
# Figma (선택). 토큰은 https://www.figma.com/developers/api 에서 발급.
# FIGMA_TOKEN=figd_xxx
# FIGMA_FILE_KEY=xxxxxxxxxxxxxxxx

# Ollama 모델 기본값 (변경 가능)
OLLAMA_VLM_MODEL=qwen2.5vl:7b
OLLAMA_TEXT_MODEL=qwen2.5-coder:7b

# 나노바나나(Gemini 웹) 동작
BANANA_URL=https://gemini.google.com/app
BANANA_RATE_LIMIT_SEC=25
BANANA_TIMEOUT_SEC=90
ENVEOF
  chmod 600 "$CREATIVE_HOME/.env"
  c_ok ".env 템플릿 생성 (필요 시 FIGMA_TOKEN 채우기)"
else
  c_ok ".env 이미 있음 — 보존"
fi

# ── 4. Python venv + 의존성 ──────────────────────────────────────────────────
PY="$(brew --prefix python@3.12)/bin/python3.12"
[ -x "$PY" ] || PY=python3
if [ ! -d "$CREATIVE_HOME/.venv" ]; then
  c_info "venv 생성 ($PY)"
  "$PY" -m venv "$CREATIVE_HOME/.venv"
fi
# shellcheck disable=SC1091
. "$CREATIVE_HOME/.venv/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet \
  "playwright>=1.46" \
  "pillow>=10" \
  "requests>=2.31" \
  "imagehash>=4.3"
c_ok "Python 패키지 설치"

# ── 5. Playwright Chromium ───────────────────────────────────────────────────
if [ ! -d "$HOME/Library/Caches/ms-playwright/chromium" ] \
&& [ ! -d "$HOME/Library/Caches/ms-playwright" ]; then
  c_info "playwright install chromium (~150MB)"
  python -m playwright install chromium
else
  c_ok "Playwright Chromium 이미 설치됨"
fi
deactivate

# ── 6. ~/bin/creative 런처 ───────────────────────────────────────────────────
mkdir -p "$HOME/bin"
ln -snf "$REPO_DIR/scripts/creative" "$HOME/bin/creative"
c_ok "런처: ~/bin/creative → $REPO_DIR/scripts/creative"

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) c_warn "~/bin 이 PATH 에 없습니다. ~/.zshrc 에 추가하세요:"
     echo '    export PATH="$HOME/bin:$PATH"' ;;
esac

# ── 7. 안내 ──────────────────────────────────────────────────────────────────
cat <<EOF

$(c_bold '다음 단계:')

  1) Gemini 4창 1회 로그인:
       creative banana-login

  2) Figma 토큰 채우기 (선택):
       \$EDITOR $CREATIVE_HOME/.env

  3) 첫 작업:
       creative run "cyberpunk cafe interior" --refs 8 --variations 12 --windows 4

상세: docs/GUIDE-CREATIVE-PIPELINE.md
EOF
