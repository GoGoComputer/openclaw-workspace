#!/usr/bin/env bash
# =============================================================================
# cmd/restore.sh — 백업 파일에서 복원
# 사용: ./openclaw restore <archive.tar.gz>
# 안전장치: sha256 검증 → tar 미리보기 → 사용자 확인 → 무권한 추출
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

trap cleanup_tmp EXIT

ARCHIVE="${1:-}"
[ -n "$ARCHIVE" ] || die "사용법: ./openclaw restore <archive.tar.gz>"
[ -f "$ARCHIVE" ] || die "파일 없음: $ARCHIVE"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다."

title "OpenClaw 복원: $ARCHIVE"

# 1) 체크섬 검증
if [ -f "${ARCHIVE}.sha256" ]; then
  info "sha256 검증"
  ( cd "$(dirname "$ARCHIVE")" && shasum -a 256 -c "$(basename "$ARCHIVE").sha256" )
else
  warn "체크섬 파일이 없습니다 — 신뢰 가능한 출처인지 확인하세요."
  confirm "체크섬 없이 진행?" n || exit 1
fi

# 2) 미리보기 + traversal 검사
info "내용 미리보기:"
tar tzf "$ARCHIVE" | head -50 | sed 's/^/    /'
if tar tzf "$ARCHIVE" | grep -E '(^|/)\.\.(/|$)|^/' >/dev/null; then
  die "위험: 아카이브에 절대경로 또는 .. 가 포함돼 있습니다. 복원 거부."
fi

confirm "위 내용으로 $OPENCLAW_DIR 의 데이터를 덮어씁니다. 진행?" n || die "사용자 취소"

# 3) 컨테이너 정지
if [ "$(cd "$OPENCLAW_DIR" && docker compose ps -q | wc -l | tr -d ' ')" -gt 0 ]; then
  info "컨테이너 정지"
  ( cd "$OPENCLAW_DIR" && docker compose down )
fi

# 4) 임시 디렉터리에 안전 추출
TMP="$(mktempd)"; register_tmp "$TMP"
tar xzf "$ARCHIVE" -C "$TMP" --no-same-owner --no-same-permissions

# 5) .env 복원 (평문 또는 GPG)
if [ -f "$TMP/env.gpg" ]; then
  info ".env GPG 복호화"
  gpg --batch --yes --decrypt -o "$OPENCLAW_DIR/.env" "$TMP/env.gpg"
elif [ -f "$TMP/env.plain" ]; then
  cp -- "$TMP/env.plain" "$OPENCLAW_DIR/.env"
fi
[ -f "$OPENCLAW_DIR/.env" ] && chmod 600 "$OPENCLAW_DIR/.env"

# 6) 볼륨 복원
PROJECT="$(basename "$OPENCLAW_DIR" | tr '[:upper:]' '[:lower:]')"
if [ -d "$TMP/volumes" ]; then
  for tgz in "$TMP/volumes"/*.tgz; do
    [ -f "$tgz" ] || continue
    full="$(basename "$tgz" .tgz)"
    info "볼륨 복원: $full"
    docker volume create "$full" >/dev/null
    docker run --rm \
      -v "${full}:/dst" \
      -v "$TMP/volumes:/src:ro" \
      --user "$(id -u):$(id -g)" \
      alpine:3 \
      sh -c "cd /dst && tar xzf /src/$(basename "$tgz")"
  done
fi

# 7) 컨테이너 재시작
info "컨테이너 시작"
( cd "$OPENCLAW_DIR" && docker compose up -d )

ok "복원 완료"
