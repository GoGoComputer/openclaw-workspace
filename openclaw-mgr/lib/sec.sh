#!/usr/bin/env bash
# =============================================================================
# lib/sec.sh — 보안 헬퍼 (입력 검증·시크릿 마스킹·위험 마운트 검사)
# -----------------------------------------------------------------------------
# 목적   : 사용자 입력과 환경 설정을 검증해 셸 인젝션·위험 마운트·시크릿 누출 차단
# 입력   : (라이브러리)
# 출력   : 함수 반환값 / 마스킹된 문자열
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================

# ── 입력 정규식 화이트리스트 ────────────────────────────────────────────────
# git 저장소 URL 검증: GitHub https / ssh 형태만 허용.
sec_validate_repo_url() {
  local url="${1:-}"
  case "$url" in
    https://github.com/*.git) ;;
    git@github.com:*.git) ;;
    https://github.com/*) ;;  # .git 생략 허용
    *) return 1 ;;
  esac
  # 위험 문자 차단 (백쿼터, 세미콜론, $, |, &, 공백, 줄바꿈)
  case "$url" in
    *' '*|*'	'*|*';'*|*'|'*|*'&'*|*'$'*|*'`'*|*'\'*) return 1 ;;
  esac
  return 0
}

# Ollama 모델 목록 검증: 콤마로 구분, 모델명 화이트리스트.
sec_validate_models() {
  local list="${1:-}"
  [ -z "$list" ] && return 0  # 비어 있어도 OK
  printf '%s' "$list" | grep -Eq '^[A-Za-z0-9._:/,-]+$'
}

# 절대경로(또는 ~) 검증 + 위험 디렉터리 블랙리스트.
# 작업 디렉터리로 마운트할 호스트 경로를 검사한다.
SEC_MOUNT_BLACKLIST="
$HOME
$HOME/.ssh
$HOME/.aws
$HOME/.config
$HOME/.gnupg
$HOME/Library
/etc
/var
/usr
/System
/private
/
"
sec_validate_workdir() {
  local p="${1:-}" b
  [ -n "$p" ] || return 1
  # ~ 확장
  case "$p" in
    "~"|"~/"*) p="$HOME${p#~}" ;;
  esac
  # 절대경로여야 함
  case "$p" in /*) ;; *) return 1 ;; esac
  # 블랙리스트 정확 일치 차단
  for b in $SEC_MOUNT_BLACKLIST; do
    [ "$p" = "$b" ] && return 1
  done
  return 0
}

# ── compose 파일에서 위험 마운트 검출 ────────────────────────────────────────
# /var/run/docker.sock 마운트는 컨테이너 탈출의 지름길.
# 단, 다음은 의도적으로 제외:
#   - docker-compose.sandbox.yml (샌드박스 overlay)
#   - 주석 처리된 라인 (#, ##, 들여쓰기된 주석 포함)
#   - 문서 설명·예시 안내 라인
# 즉, "실제로 활성화된 volumes 마운트 항목"만 위험으로 간주한다.
# 발견 시 비-0 반환, 파일명 출력.
sec_scan_compose() {
  local dir="${1:-.}"
  local files file
  files="$(find "$dir" -maxdepth 3 -type f \
    \( -name 'docker-compose*.y*ml' -o -name 'compose*.y*ml' \) \
    ! -name 'docker-compose.sandbox.yml' \
    2>/dev/null)"
  [ -z "$files" ] && return 0
  local found=0
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    # 주석(#, ##, 앞공백+#) 라인을 제거한 뒤에 docker.sock 마운트 패턴을 검사한다.
    # YAML 의 활성 volumes 항목은 보통 "- /var/run/docker.sock:/var/run/docker.sock"
    # 형태로 적힌다. 따옴표를 두른 변형도 같이 잡는다.
    if sed -E 's/[[:space:]]*#.*$//' "$file" \
        | grep -Eq '(^|[[:space:]])-[[:space:]]+["'"'"']?/var/run/docker\.sock'; then
      printf '%s\n' "$file"
      found=1
    fi
  done <<EOF
$files
EOF
  [ "$found" -eq 0 ]
}

# ── 시크릿 마스킹 ─────────────────────────────────────────────────────────────
# stdin 의 텍스트에서 KEY/TOKEN/SECRET/PASSWORD 류를 마스킹.
sec_mask() {
  sed -E \
    -e 's/(([A-Za-z0-9_]*(KEY|TOKEN|SECRET|PASSWORD|PASS|API)[A-Za-z0-9_]*)[[:space:]]*[:=][[:space:]]*)[^[:space:]"'"'"']+/\1***REDACTED***/g' \
    -e 's/(Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1***REDACTED***/g'
}

# ── .env 권한·git ignore 검증 ────────────────────────────────────────────────
# .env 가 600 이 아니면 보정. git 저장소 안이고 ignore 안되어 있으면 경고.
sec_check_env_file() {
  local f="${1:?env file path required}"
  [ -f "$f" ] || return 0
  chmod 600 "$f" 2>/dev/null || true
  if git -C "$(dirname "$f")" rev-parse --git-dir >/dev/null 2>&1; then
    if ! git -C "$(dirname "$f")" check-ignore -q "$(basename "$f")"; then
      printf '%s\n' "WARN: $f is NOT git-ignored. Add to .gitignore!" >&2
      return 2
    fi
  fi
  return 0
}

# ── plist 권한 검증 ──────────────────────────────────────────────────────────
sec_check_plist() {
  local p="${1:?plist path required}"
  [ -f "$p" ] || return 1
  # 소유자 = 현재 사용자
  local owner; owner="$(stat -f '%Su' "$p" 2>/dev/null || echo '?')"
  [ "$owner" = "$(id -un)" ] || return 2
  # 644 권한
  local mode; mode="$(stat -f '%Lp' "$p" 2>/dev/null || echo '000')"
  [ "$mode" = "644" ] || chmod 644 "$p"
  return 0
}
