#!/usr/bin/env bash
# =============================================================================
# cmd/clean.sh — 메모리·디스크 정리 (비개발자 친화)
# 사용:
#   ./openclaw clean              대화형 (단계별 확인)
#   ./openclaw clean --light      안전한 부분만 (캐시·중지된 컨테이너)
#   ./openclaw clean --all        모두 (이미지·모델·통합메모리 압축까지)
#   ./openclaw clean --status     현재 사용량만 보고 종료
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

MODE="interactive"
while [ $# -gt 0 ]; do
  case "$1" in
    --light) MODE="light"; shift ;;
    --all)   MODE="all"; shift ;;
    --status) MODE="status"; shift ;;
    *) die "알 수 없는 옵션: $1 (사용법: clean [--light|--all|--status])" ;;
  esac
done

# ── 현재 사용량 표시 ─────────────────────────────────────────────────────────
show_status() {
  title "현재 사용량"
  # macOS RAM
  if command -v vm_stat >/dev/null 2>&1; then
    local pages_free pages_total page_size
    page_size="$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)"
    pages_free="$(vm_stat | awk '/Pages free/ {gsub(/\.$/,"",$3); print $3}')"
    pages_total="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    pages_total=$(( pages_total / page_size ))
    if [ "${pages_total:-0}" -gt 0 ] && [ -n "${pages_free:-}" ]; then
      local used_pct=$(( 100 - (pages_free * 100 / pages_total) ))
      info "RAM 사용률: 약 ${used_pct}%"
    fi
  fi

  # Docker
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    info "Docker 디스크 사용:"
    docker system df 2>/dev/null | sed 's/^/    /'
    info "실행 중 컨테이너 메모리:"
    docker stats --no-stream --format '    {{.Name}}: {{.MemUsage}} (CPU {{.CPUPerc}})' 2>/dev/null || true
  else
    warn "Docker 미실행 — Docker 항목 스킵"
  fi

  # Ollama
  if command -v ollama >/dev/null 2>&1; then
    info "Ollama 모델 (디스크):"
    ollama list 2>/dev/null | sed 's/^/    /' || true
    info "Ollama 활성 모델 (메모리):"
    ollama ps 2>/dev/null | sed 's/^/    /' || true
  fi

  # 디스크 여유
  info "홈 디스크 여유:"
  df -h "$HOME" 2>/dev/null | sed 's/^/    /'
}

# ── 정리 액션들 (각자 멱등) ───────────────────────────────────────────────────
clean_docker_stopped() {
  info "정지된 컨테이너 제거"
  docker container prune -f >/dev/null
  ok "정지 컨테이너 정리 완료"
}

clean_docker_dangling() {
  info "이름 없는(dangling) 이미지 제거"
  docker image prune -f >/dev/null
  ok "dangling 이미지 정리 완료"
}

clean_docker_buildcache() {
  info "Docker 빌드 캐시 정리"
  docker builder prune -f >/dev/null 2>&1 || true
  ok "빌드 캐시 정리 완료"
}

clean_docker_all_images() {
  info "사용하지 않는 이미지 모두 제거 (실행 중 컨테이너가 쓰는 것은 보존)"
  docker image prune -a -f >/dev/null
  ok "전체 이미지 정리 완료"
}

clean_logs() {
  info "오래된 로그 회전 (7일 초과)"
  if [ -d "$LOG_DIR" ]; then
    find "$LOG_DIR" -type f -name '*.log' -mtime +7 -print -delete 2>/dev/null | sed 's/^/    삭제: /' || true
  fi
  ok "로그 정리 완료"
}

clean_old_backups() {
  local keep="${BACKUP_KEEP:-7}"
  local dir="${BACKUP_DIR:-$HOME/openclaw-backups}"
  [ -d "$dir" ] || return 0
  info "오래된 백업 정리 (최근 ${keep}개 유지)"
  ls -1t "$dir"/openclaw-*.tar.gz 2>/dev/null | tail -n +"$((keep + 1))" | while IFS= read -r old; do
    rm -f -- "$old" "${old}.sha256"
    info "    삭제: $old"
  done
  ok "백업 정리 완료"
}

clean_ollama_unload() {
  if ! command -v ollama >/dev/null 2>&1; then return 0; fi
  info "Ollama 메모리 해제 (활성 모델 언로드)"
  # ollama 는 idle 시 자동 해제하지만 즉시 비우려면 서비스 재시작이 가장 확실
  if brew services list 2>/dev/null | grep -q '^ollama .* started'; then
    brew services restart ollama >/dev/null
    ok "Ollama 재시작으로 메모리 해제"
  else
    warn "Ollama 가 brew services 로 관리되지 않음 — 수동 재시작 필요"
  fi
}

clean_ollama_remove_model() {
  command -v ollama >/dev/null 2>&1 || return 0
  info "사용하지 않는 Ollama 모델을 골라서 삭제할 수 있습니다."
  ollama list 2>/dev/null | sed 's/^/    /' || return 0
  if ! confirm "위 목록에서 모델을 제거하시겠습니까?" n; then return 0; fi
  printf '제거할 모델 이름 (콤마 구분, Enter=취소): ' >&2
  local names m
  IFS= read -r names || names=""
  [ -z "$names" ] && { info "취소됨"; return 0; }
  IFS=','
  for m in $names; do
    m="$(printf '%s' "$m" | tr -d '[:space:]')"
    [ -z "$m" ] && continue
    case "$m" in
      *[!A-Za-z0-9._:/-]*) warn "스킵(이상한 문자): $m"; continue ;;
    esac
    ollama rm "$m" || warn "$m 제거 실패"
  done
  unset IFS
  ok "Ollama 모델 정리 완료"
}

clean_macos_purge() {
  info "macOS 통합메모리 압축 (sudo purge — 비밀번호 1회 필요)"
  warn "이 명령은 sudo 가 필요하며 5~10초 정도 시스템이 잠시 느려질 수 있습니다."
  if ! confirm "지금 실행?" n; then return 0; fi
  sudo purge && ok "macOS purge 완료"
}

# ── 모드별 실행 ──────────────────────────────────────────────────────────────
case "$MODE" in
  status)
    show_status
    ;;
  light)
    title "가벼운 정리 (안전)"
    show_status
    hr
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      clean_docker_stopped
      clean_docker_dangling
      clean_docker_buildcache
    fi
    clean_logs
    clean_old_backups
    hr
    show_status
    ;;
  all)
    title "전체 정리 (강함)"
    show_status
    hr
    warn "이 모드는 Docker 이미지·Ollama 모델·통합메모리까지 정리합니다."
    confirm "정말 진행?" n || die "사용자 취소"
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      clean_docker_stopped
      clean_docker_dangling
      clean_docker_buildcache
      clean_docker_all_images
    fi
    clean_logs
    clean_old_backups
    clean_ollama_unload
    clean_ollama_remove_model
    clean_macos_purge
    hr
    show_status
    ;;
  interactive)
    title "메모리·디스크 정리 (대화형)"
    show_status
    hr
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      confirm "정지된 컨테이너 제거?" y && clean_docker_stopped
      confirm "dangling 이미지 제거?" y && clean_docker_dangling
      confirm "Docker 빌드 캐시 정리?" y && clean_docker_buildcache
      confirm "사용하지 않는 이미지 모두 제거? (조심)" n && clean_docker_all_images
    fi
    confirm "오래된 로그(7일+) 정리?" y && clean_logs
    confirm "오래된 백업(${BACKUP_KEEP:-7}개 초과) 정리?" y && clean_old_backups
    if command -v ollama >/dev/null 2>&1; then
      confirm "Ollama 메모리 해제(재시작)?" n && clean_ollama_unload
      confirm "Ollama 모델 골라서 삭제?" n && clean_ollama_remove_model
    fi
    confirm "macOS 통합메모리 압축(sudo purge)?" n && clean_macos_purge
    hr
    show_status
    ;;
esac

ok "정리 완료"
