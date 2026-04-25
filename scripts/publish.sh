#!/usr/bin/env bash
# =============================================================================
# scripts/publish.sh — gh 인증 완료 후 GitHub 게시·태그·릴리스 자동화
# 사용:  ./scripts/publish.sh
# 전제:  brew install gh && gh auth login  까지 완료된 상태
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

REPO_SLUG="GoGoComputer/openclaw-workspace"
DESC="OpenClaw self-host automation for macOS — install · maintain · backup · uninstall."
HOMEPAGE="https://clawbro.ai"
TAG="v0.1.0"

cd "$(dirname "$0")/.."

err()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[34m•\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*" >&2; }

command -v gh >/dev/null 2>&1 || err "gh CLI 미설치 — brew install gh"
gh auth status >/dev/null 2>&1 || err "gh 인증 필요 — gh auth login"
git config user.name  >/dev/null 2>&1 || err "git config --global user.name '...' 필요"
git config user.email >/dev/null 2>&1 || err "git config --global user.email '...' 필요"

# 1) 저장소 존재 확인
if gh repo view "$REPO_SLUG" >/dev/null 2>&1; then
  info "원격 저장소 이미 존재 — push 모드"
  git remote get-url origin >/dev/null 2>&1 \
    || git remote add origin "https://github.com/${REPO_SLUG}.git"
  git push -u origin main
else
  info "새 저장소 생성: $REPO_SLUG"
  gh repo create "$REPO_SLUG" --public --source=. --remote=origin --push \
    --description "$DESC" --homepage "$HOMEPAGE"
fi

# 2) 토픽
info "토픽 추가"
gh repo edit "$REPO_SLUG" \
  --add-topic openclaw \
  --add-topic ai-agent \
  --add-topic ollama \
  --add-topic docker \
  --add-topic macos \
  --add-topic bash \
  --add-topic self-hosted || true

# 3) 태그 + 릴리스
if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  git tag -a "$TAG" -m "v0.1.0 — initial release"
fi
git push origin "$TAG"

if ! gh release view "$TAG" --repo "$REPO_SLUG" >/dev/null 2>&1; then
  notes="docs/RELEASE_NOTES_v0.1.0.md"
  if [ -f "$notes" ]; then
    gh release create "$TAG" --repo "$REPO_SLUG" \
      --title "v0.1.0 — initial release" \
      --notes-file "$notes"
  else
    gh release create "$TAG" --repo "$REPO_SLUG" \
      --title "v0.1.0 — initial release" --generate-notes
  fi
fi

ok "게시 완료"
gh repo view "$REPO_SLUG" --json url -q .url
