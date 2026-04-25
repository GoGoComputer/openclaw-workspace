#!/usr/bin/env bash
# =============================================================================
# cmd/backup.sh — Docker 볼륨 + .env 백업 (sha256 + 선택적 GPG 암호화)
# 사용: ./openclaw backup [--name NAME]
# 출력: $BACKUP_DIR/openclaw-YYYYmmdd-HHMMSS-<NAME>.tar.gz (+ .sha256, .env.gpg)
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

trap cleanup_tmp EXIT

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/openclaw}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/openclaw-backups}"
BACKUP_KEEP="${BACKUP_KEEP:-7}"
BACKUP_ENCRYPT="${BACKUP_ENCRYPT:-1}"

[ -d "$OPENCLAW_DIR" ] || die "OpenClaw 가 설치돼 있지 않습니다."

NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    --no-stop) NO_STOP=1; shift ;;
    *) die "알 수 없는 옵션: $1" ;;
  esac
done
NAME="${NAME:-manual}"
case "$NAME" in
  *[!A-Za-z0-9._-]*) die "백업 이름에 영문/숫자/._- 만 허용됩니다: $NAME" ;;
esac

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/openclaw-${TS}-${NAME}.tar.gz"
TMP="$(mktempd)"
register_tmp "$TMP"

cd "$OPENCLAW_DIR"

title "OpenClaw 백업 → $ARCHIVE"

# 1) 일관성 위해 컨테이너 정지 (옵션 끄려면 --no-stop)
WAS_RUNNING=no
if [ "${NO_STOP:-0}" != "1" ] && [ "$(docker compose ps -q | wc -l | tr -d ' ')" -gt 0 ]; then
  WAS_RUNNING=yes
  info "컨테이너 정지 (백업 일관성)"
  docker compose stop
fi

# 2) 명명된 볼륨 목록 추출 (compose 가 만든 볼륨)
VOLS="$(docker compose config --volumes 2>/dev/null || true)"
PROJECT="$(basename "$OPENCLAW_DIR" | tr '[:upper:]' '[:lower:]')"
mkdir -p "$TMP/volumes"

if [ -n "$VOLS" ]; then
  for v in $VOLS; do
    full="${PROJECT}_${v}"
    if docker volume inspect "$full" >/dev/null 2>&1; then
      info "볼륨 백업: $full"
      docker run --rm \
        -v "${full}:/src:ro" \
        -v "$TMP/volumes:/dst" \
        --user "$(id -u):$(id -g)" \
        alpine:3 \
        sh -c "cd /src && tar czf /dst/${full}.tgz ."
    fi
  done
else
  warn "compose 볼륨 목록 비어 있음"
fi

# 3) .env 처리 (암호화)
if [ -f "$OPENCLAW_DIR/.env" ]; then
  if [ "$BACKUP_ENCRYPT" = "1" ] && command -v gpg >/dev/null 2>&1; then
    info ".env GPG 대칭 암호화 (passphrase 입력)"
    gpg --batch --yes --symmetric --cipher-algo AES256 \
      -o "$TMP/env.gpg" "$OPENCLAW_DIR/.env"
  else
    [ "$BACKUP_ENCRYPT" = "1" ] && warn "gpg 미설치 — .env 평문 백업"
    cp -- "$OPENCLAW_DIR/.env" "$TMP/env.plain"
    chmod 600 "$TMP/env.plain"
  fi
fi

# 4) 메타데이터
{
  printf 'created=%s\n' "$(date -u +%FT%TZ)"
  printf 'host=%s\n' "$(hostname)"
  printf 'openclaw_dir=%s\n' "$OPENCLAW_DIR"
  printf 'git_commit=%s\n' "$(git -C "$OPENCLAW_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
  printf 'mgr_version=0.1.0\n'
} > "$TMP/META"

# 5) 묶기 + sha256
( cd "$TMP" && tar czf "$ARCHIVE" . )
chmod 600 "$ARCHIVE"
( cd "$BACKUP_DIR" && shasum -a 256 "$(basename "$ARCHIVE")" > "${ARCHIVE}.sha256" )
ok "백업 완료: $ARCHIVE"
ok "체크섬:   ${ARCHIVE}.sha256"

# 6) 컨테이너 재시작
if [ "$WAS_RUNNING" = "yes" ]; then
  info "컨테이너 재시작"
  docker compose start
fi

# 7) 보관 정책 (오래된 N+ 자동 삭제)
if [ "$BACKUP_KEEP" -gt 0 ] 2>/dev/null; then
  # 정렬: 파일명에 타임스탬프 들어 있으므로 ls -1 정렬로 충분
  ls -1t "$BACKUP_DIR"/openclaw-*.tar.gz 2>/dev/null | tail -n +"$((BACKUP_KEEP + 1))" | while IFS= read -r old; do
    info "오래된 백업 삭제: $old"
    rm -f -- "$old" "${old}.sha256"
  done
fi
