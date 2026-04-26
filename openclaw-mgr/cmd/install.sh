#!/usr/bin/env bash
# =============================================================================
# cmd/install.sh — 부족한 부분만 자동 설치 (멱등, 이어서 세팅 가능)
# 단계: Xcode CLT → Homebrew → Docker → (Ollama+모델) → 저장소 clone →
#       .env 머지 → compose up → 헬스체크
# 각 단계는 state 에 마킹되어 다음 실행 시 자동 스킵.
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail

# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/detect.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/prompt.sh"

require_macos
trap cleanup_tmp EXIT

# ── 0. 사전 점검 ─────────────────────────────────────────────────────────────
title "OpenClaw 설치 시작"
info "상태 파일: $STATE_FILE  (이미 끝난 단계는 자동 스킵됩니다)"
info "재시작/중단 후 다시 실행해도 안전합니다."

# 디렉토리 안내 (설치 전 사용자에게 미리 고지)
hr
printf '%s📂 설치 위치 안내%s\n' "$C_BOLD" "$C_RESET" >&2
printf '  %-32s %s\n' "OpenClaw 본체 코드:" "${OPENCLAW_DIR:-$HOME/DEV/openclaw}" >&2
printf '  %-32s %s\n' "에이전트 작업 파일 (Finder 확인):" "${OPENCLAW_WORKSPACE_DIR:-$HOME/DEV/openclawAgent}" >&2
printf '  %-32s %s\n' "설정·토큰 (숨김, 자동 관리):" "${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}" >&2
printf '  %-32s %s\n' "이 관리 도구:" "$OPENCLAW_MGR_DIR" >&2
printf '\n  %s⚠  이 레포는 로컬에 아무것도 직접 설치하지 않습니다.%s\n' "$C_YELLOW" "$C_RESET" >&2
printf '     Docker/Ollama/OpenClaw 는 각 공식 사이트에서 받고,\n' >&2
printf '     에이전트 실행은 Docker 컨테이너 안에서만 이루어집니다.\n' >&2
hr

# ── 1. Xcode Command Line Tools ──────────────────────────────────────────────
step_xcode() {
  if xcode-select -p >/dev/null 2>&1; then
    info "이미 설치됨: $(xcode-select -p)"
    return 0
  fi
  warn "Xcode Command Line Tools 가 필요합니다."
  info "GUI 다이얼로그가 뜹니다. 설치 완료 후 이 스크립트를 다시 실행하세요."
  xcode-select --install || true
  return 1
}
run_step xcode_clt "Xcode CLT 설치 확인" -- step_xcode

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step_brew() {
  if command -v brew >/dev/null 2>&1; then
    info "이미 설치됨: $(brew --prefix)"
    return 0
  fi
  info "Homebrew 는 선택 사항입니다. Docker/Ollama 는 공식 사이트에서 직접 설치합니다."
  info "원하면 https://brew.sh 에서 직접 설치할 수 있습니다."
  return 0   # Homebrew 없어도 진행
}
run_step brew "Homebrew 확인 (선택)" -- step_brew

# ── 3. Docker Desktop ────────────────────────────────────────────────────────
step_docker_install() {
  if command -v docker >/dev/null 2>&1; then
    info "이미 설치됨"
    return 0
  fi
  warn "Docker Desktop 이 없습니다. 공식 사이트에서 직접 다운로드 후 설치하세요:"
  info "  홈페이지: https://www.docker.com/products/docker-desktop/"
  info "  Apple Silicon: 'Download for Mac – Apple Silicon'"
  info "  Intel:         'Download for Mac – Intel Chip'"
  info "  .dmg 더블클릭 → Docker 아이콘을 Applications 폴더로 드래그 → Docker.app 실행"
  info "설치 후 이 명령을 다시 실행하세요: ./openclaw install"
  return 1
}
run_step docker_install "Docker Desktop 설치 확인" -- step_docker_install

step_docker_start() {
  if docker info >/dev/null 2>&1; then
    info "Docker 데몬 이미 실행 중"
    return 0
  fi
  info "Docker Desktop 앱 실행"
  open -a "Docker" || die "Docker.app 을 열 수 없습니다. 수동 실행 후 재시도하세요."
  info "데몬 기동을 기다립니다 (최대 90초)..."
  local i
  for i in $(seq 1 90); do
    if docker info >/dev/null 2>&1; then
      ok "Docker 데몬 준비 완료 (${i}s)"
      return 0
    fi
    sleep 1
  done
  err "Docker 데몬이 시간 내 기동하지 않았습니다."
  err "Docker Desktop 첫 실행 시 약관 동의가 필요할 수 있습니다."
  return 1
}
run_step docker_start "Docker 데몬 시작" -- step_docker_start

# ── 4. Ollama (선택) ─────────────────────────────────────────────────────────
ENABLE_OLLAMA="${ENABLE_OLLAMA:-1}"
if [ "$ENABLE_OLLAMA" = "1" ]; then
  step_ollama_install() {
    command -v ollama >/dev/null 2>&1 && { info "이미 설치됨"; return 0; }
    warn "Ollama 가 없습니다."
    info "공식 사이트에서 직접 다운로드 후 설치하세요:"
    info "  https://ollama.com/download"
    info "  'Download for macOS' → .dmg/.zip → Applications 로 드래그 → 실행"
    info "설치 후 이 명령을 다시 실행하세요: ./openclaw install"
    return 1
  }
  run_step ollama_install "Ollama 설치 확인" -- step_ollama_install

  step_ollama_start() {
    if curl -sS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      info "Ollama 이미 실행 중"
      return 0
    fi
    # Ollama.app 실행 (뮨뉴바 데몬 시작)
    if open -a Ollama 2>/dev/null; then
      info "Ollama 앱 실행 중 — 데몬 시동대기 (30초)..."
      local i
      for i in $(seq 1 30); do
        if curl -sS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
          ok "Ollama 데몬 준비 완료 (${i}s)"
          return 0
        fi
        sleep 1
      done
    fi
    warn "Ollama 데몬이 응답하지 않습니다 — Applications → Ollama 를 직접 실행하세요."
    warn "https://ollama.com/download 에서 설치 확인"
    return 1
  }
  run_step ollama_start "Ollama 데몬 시작" -- step_ollama_start

  step_ollama_check() {
    # 이미 설치된 모델 목록 표시 (자동 다운로드 하지 않음)
    local list
    list="$(ollama list 2>/dev/null | tail -n +2 | awk 'NF{print $1}' || true)"
    if [ -n "$list" ]; then
      ok "이미 설치된 Ollama 모델:"
      printf '%s\n' "$list" | while IFS= read -r m; do
        printf '    ✔ %s\n' "$m"
      done
    else
      info "설치된 Ollama 모델이 없습니다."
      info "원하는 모델은 수동으로 추가하세요:  ollama pull <모델명>"
      info "M5 Pro 24GB 추천: ollama pull qwen2.5-coder:14b"
    fi
  }
  run_step ollama_check "설치된 Ollama 모델 확인" -- step_ollama_check
else
  info "ENABLE_OLLAMA=0 — Ollama 단계 스킵"
fi

# ── 5. OpenClaw 저장소 ───────────────────────────────────────────────────────
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
# 에이전트 파일 저장 폴더 (Docker 볼륨 마운트 — 로컬에는 아무것도 설치 안 됨)
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/DEV/openclawAgent}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
# 폴더가 없으면 미리 생성 (Docker 마운트 전 필요)
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
mkdir -p "$OPENCLAW_CONFIG_DIR"
export OPENCLAW_WORKSPACE_DIR OPENCLAW_CONFIG_DIR

step_repo() {
  local repo="${OPENCLAW_REPO:-}"
  if [ -z "$repo" ]; then
    warn ".env 의 OPENCLAW_REPO 가 비어 있습니다."
    info "OpenClaw 공식 저장소 URL을 입력하세요 (https://github.com/<owner>/<repo>.git)"
    info "URL을 모르면 빈 값으로 두고 Enter — 이 단계는 다음 실행에서 다시 시도합니다."
    repo="$(ask_value "OPENCLAW_REPO" "" sec_validate_repo_url || true)"
    if [ -z "$repo" ]; then
      err "저장소 URL 없이는 진행할 수 없습니다. .env 에 OPENCLAW_REPO 를 설정하고 다시 실행하세요."
      return 1
    fi
  fi
  if ! sec_validate_repo_url "$repo"; then
    err "안전하지 않은 저장소 URL: $repo"
    return 1
  fi
  if [ -d "$OPENCLAW_DIR/.git" ]; then
    info "이미 클론됨: $OPENCLAW_DIR"
    git -C "$OPENCLAW_DIR" fetch --tags --prune || warn "git fetch 실패"
  else
    info "git clone --depth 1 $repo → $OPENCLAW_DIR"
    git clone --depth 1 -- "$repo" "$OPENCLAW_DIR"
  fi
  # 핀 모드: 특정 커밋 체크아웃
  if [ -n "${OPENCLAW_PIN_COMMIT:-}" ]; then
    info "핀 적용: $OPENCLAW_PIN_COMMIT"
    git -C "$OPENCLAW_DIR" fetch origin "$OPENCLAW_PIN_COMMIT" --depth 1 || true
    git -C "$OPENCLAW_DIR" checkout --detach "$OPENCLAW_PIN_COMMIT"
  fi
}
run_step repo_clone "OpenClaw 저장소 준비" -- step_repo

# ── 5b. compose 보안 사전 검사 (소켓 마운트 차단) ─────────────────────────────
step_compose_scan() {
  if ! sec_scan_compose "$OPENCLAW_DIR" >/dev/null 2>&1; then
    err "위험: compose 파일에 /var/run/docker.sock 마운트가 발견되었습니다."
    err "이 마운트는 컨테이너에서 호스트를 완전히 장악할 수 있는 권한입니다."
    err "해당 줄을 제거하거나, 신뢰 가능한 fork 를 사용하세요."
    return 1
  fi
  ok "compose 파일에 위험 마운트 없음"
}
run_step compose_scan "compose 보안 검사" -- step_compose_scan

# ── 6. .env 머지 ─────────────────────────────────────────────────────────────
step_env_merge() {
  local target="$OPENCLAW_DIR/.env" example="$OPENCLAW_DIR/.env.example"
  if [ ! -f "$example" ]; then
    info "저장소에 .env.example 없음 — 단계 스킵"
    return 0
  fi
  if [ ! -f "$target" ]; then
    cp -- "$example" "$target"
    ok "$target 생성"
  else
    # 누락 키만 추가 (덮어쓰지 않음)
    local key
    while IFS= read -r line; do
      case "$line" in
        ''|'#'*) continue ;;
        *=*)
          key="${line%%=*}"
          if ! grep -qE "^${key}=" "$target" 2>/dev/null; then
            printf '%s\n' "$line" >> "$target"
            info "키 추가: $key"
          fi
          ;;
      esac
    done < "$example"
  fi
  chmod 600 "$target" 2>/dev/null || true
  sec_check_env_file "$target" || true
}
run_step env_merge ".env 머지" -- step_env_merge

# ── 7. compose up ────────────────────────────────────────────────────────────
step_compose_up() {
  cd "$OPENCLAW_DIR"

  # ── Docker 데몬 라이브니스 재확인 (마커가 있어도 매번 검사) ──────────────
  # docker_start=done 이라도 그 이후 사용자가 Docker Desktop 을 끌 수 있다.
  # compose_up 직전에 데몬이 죽어 있으면 자동으로 다시 띄운다.
  if ! docker info >/dev/null 2>&1; then
    warn "Docker 데몬이 응답하지 않습니다 — 자동 재기동 시도"
    open -a "Docker" 2>/dev/null || die "Docker.app 을 열 수 없습니다. Docker Desktop 을 직접 실행 후 './openclaw install' 재시도하세요."
    info "데몬 기동 대기 (최대 90초)..."
    local i
    for i in $(seq 1 90); do
      if docker info >/dev/null 2>&1; then
        ok "Docker 데몬 재기동 완료 (${i}s)"
        break
      fi
      sleep 1
    done
    if ! docker info >/dev/null 2>&1; then
      err "Docker 데몬이 시간 내 기동하지 않았습니다. Docker Desktop 첫 실행 시 약관 동의가 필요할 수 있습니다."
      return 1
    fi
  fi

  # ── 기존 이미지·컨테이너 사전 감지 ────────────────────────────────────────
  local existing_images
  existing_images="$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
    | grep -iE 'openclaw|anthropic|claude' || true)"
  if [ -n "$existing_images" ]; then
    info "기존 Docker 이미지 발견 — 재사용합니다:"
    printf '%s\n' "$existing_images" | while IFS= read -r img; do
      printf '    ✔ %s\n' "$img"
    done
  else
    info "OpenClaw Docker 이미지 없음 — 처음 실행 시 pull 됩니다."
  fi

  # ── openclaw:local 자동 빌드 ──────────────────────────────────────────────
  # docker-compose.yml 의 기본 이미지 태그는 'openclaw:local' 인데, 이건
  # 레지스트리에 없고 로컬에서 'docker build' 로 만들어야 한다. 사용자가
  # 다른 이미지(${OPENCLAW_IMAGE})를 지정하지 않은 경우 자동으로 빌드한다.
  local target_image="${OPENCLAW_IMAGE:-openclaw:local}"
  if [ "$target_image" = "openclaw:local" ]; then
    if ! docker image inspect "$target_image" >/dev/null 2>&1; then
      if [ -f "$OPENCLAW_DIR/Dockerfile" ]; then
        info "openclaw:local 이미지가 없습니다 — 로컬에서 빌드합니다 (몇 분 소요)"
        ( cd "$OPENCLAW_DIR" \
          && DOCKER_BUILDKIT=1 docker build -t openclaw:local . ) \
          || { err "openclaw:local 이미지 빌드 실패"; return 1; }
        ok "이미지 빌드 완료: openclaw:local"
      else
        err "이미지 'openclaw:local' 도 Dockerfile 도 찾을 수 없습니다."
        err "  - $OPENCLAW_DIR/Dockerfile 가 존재해야 합니다."
        err "  - 또는 .env 에 OPENCLAW_IMAGE=<레지스트리 이미지> 를 지정하세요."
        return 1
      fi
    fi
  fi

  local existing_containers
  existing_containers="$(docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null \
    | grep -iE 'openclaw' || true)"
  if [ -n "$existing_containers" ]; then
    info "기존 컨테이너 발견:"
    printf '%s\n' "$existing_containers" | while IFS= read -r ctr; do
      printf '    ✔ %s\n' "$ctr"
    done
  fi
  # ───────────────────────────────────────────────────────────────────────────

  local files="-f docker-compose.yml"
  [ -f compose.yml ] && files="-f compose.yml"
  # 보안 override (서비스명 openclaw-gateway/openclaw-cli 에 맞게 수정됨)
  local sec="$OPENCLAW_MGR_DIR/compose.security.yml"
  [ -f "$sec" ] && files="$files -f $sec"
  # Ollama-in-Docker 모드 (OLLAMA_MODE=docker)
  if [ "${OLLAMA_MODE:-host}" = "docker" ]; then
    local ollama_f="$OPENCLAW_MGR_DIR/compose.ollama.yml"
    [ -f "$ollama_f" ] && files="$files -f $ollama_f" && info "Ollama-in-Docker 모드 활성화"
  fi
  # 첫 실행 시 컨테이너가 의존성을 받아야 할 수도 있으므로 install 단계에서는
  # online 으로 시작합니다. 끝나고 자동으로 isolated 로 전환합니다.
  bash "$OPENCLAW_MGR_DIR/cmd/network.sh" online >/dev/null
  local net="$OPENCLAW_MGR_DIR/compose.network.yml"
  [ -f "$net" ] && files="$files -f $net"

  # ── 이전 실패 실행의 잔여 컨테이너 정리 ─────────────────────────────────
  # 설치 재시도 시 이전 실행에서 반쯤 기동된 컨테이너가 남아 포트를 점유하면
  #   "failed to bind host port: address already in use"
  # 오류가 난다. compose down --remove-orphans 로 이 프로젝트의 컨테이너를
  # 먼저 정리하고 새로 띄운다. 볼륨(데이터)은 보존된다.
  info "이전 컨테이너 잔재 정리 (포트 충돌 방지)..."
  # shellcheck disable=SC2086
  docker compose $files down --remove-orphans 2>/dev/null || true

  # shellcheck disable=SC2086
  # --pull missing: 이미 받은 이미지는 재다운로드 안 함
  docker compose $files up -d --pull missing
}
run_step compose_up "OpenClaw 컨테이너 시작" -- step_compose_up

# ── 8. 헬스체크 ──────────────────────────────────────────────────────────────
step_health() {
  cd "$OPENCLAW_DIR"
  info "컨테이너 기동 대기 (최대 120초) — 처음 실행은 의존성 초기화로 1~2분 걸립니다"
  local i n_total n_running prev_running=-1
  for i in $(seq 1 60); do
    n_total="$(docker compose ps -q 2>/dev/null | wc -l | tr -d ' ')"
    n_running="$(docker compose ps --status running -q 2>/dev/null | wc -l | tr -d ' ')"
    # 진행 변화가 있을 때마다 한 줄 출력 (멈춰 보이지 않게)
    if [ "$n_running" != "$prev_running" ]; then
      info "  [${i}/60]  실행 ${n_running}/${n_total}"
      prev_running="$n_running"
    fi
    if [ "$n_total" -gt 0 ] && [ "$n_running" -ge "$n_total" ]; then
      ok "모든 컨테이너 실행 중 ($n_running/$n_total)"
      # gateway healthz 응답 확인 (실제 서비스 ready 신호)
      local j
      for j in $(seq 1 30); do
        if curl -sS --max-time 2 http://127.0.0.1:18789/healthz >/dev/null 2>&1; then
          ok "Gateway healthz 응답 OK (http://127.0.0.1:18789)"
          break
        fi
        [ "$j" -eq 1 ] && info "  Gateway healthz 응답 대기 (최대 60초)..."
        sleep 2
      done
      # Ollama 연결 확인 (옵션)
      if [ "${ENABLE_OLLAMA:-1}" = "1" ]; then
        if curl -sS --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
          ok "Ollama 호스트 연결 OK"
        else
          warn "Ollama 호스트 응답 없음 — 컨테이너에서 host.docker.internal 로 연결 필요"
        fi
      fi
      return 0
    fi
    sleep 2
  done
  warn "헬스체크 타임아웃 (120초)"
  warn "  진단: ./openclaw logs           (실시간 로그)"
  warn "  진단: docker compose ps         (각 컨테이너 상태)"
  warn "  컨테이너 자체는 떠 있을 수 있습니다 — './openclaw doctor' 로 재확인"
  return 0
}
run_step health "헬스체크" -- step_health

# ── 9. 보안 기본값: isolated 로 자동 전환 ────────────────────────────────────
step_lockdown() {
  bash "$OPENCLAW_MGR_DIR/cmd/network.sh" isolated >/dev/null
  info "재기동 후 isolated 모드 적용"
  cd "$OPENCLAW_DIR"
  local files="-f docker-compose.yml"
  [ -f compose.yml ] && files="-f compose.yml"
  local sec="$OPENCLAW_MGR_DIR/compose.security.yml"
  local net="$OPENCLAW_MGR_DIR/compose.network.yml"
  [ -f "$sec" ] && files="$files -f $sec"
  [ -f "$net" ] && files="$files -f $net"
  # shellcheck disable=SC2086
  docker compose $files up -d --pull missing
}
run_step lockdown "네트워크 격리(isolated) 적용" -- step_lockdown

# ── 10. 샌드박스 설정 (기본 ON, OPENCLAW_SANDBOX=0 으로만 끌 수 있음) ────────────────────────
step_sandbox() {
  if [ "${OPENCLAW_SANDBOX:-1}" != "1" ]; then
    info "샌드박스 명시적 비활성 (.env 의 OPENCLAW_SANDBOX=0)"
    info "  ⚠ 보안 하락 — 개인 일상용이 아닌 경우 1 로 되돌리고 './openclaw install' 재실행 권장"
    return 0
  fi

  cd "$OPENCLAW_DIR"

  # 10-A. Docker CLI 포함 이미지 재빌드
  info "샌드박스: Docker CLI 포함 이미지 재빌드 중..."
  DOCKER_BUILDKIT=1 docker build \
    --build-arg OPENCLAW_INSTALL_DOCKER_CLI=1 \
    -t openclaw:local .

  # 10-B. 샌드박스 전용 이미지 빌드
  if [ -f "Dockerfile.sandbox" ]; then
    info "샌드박스 이미지 빌드 중: openclaw-sandbox:bookworm-slim"
    DOCKER_BUILDKIT=1 docker build \
      -t openclaw-sandbox:bookworm-slim \
      -f Dockerfile.sandbox .
  else
    warn "Dockerfile.sandbox 를 찾을 수 없습니다 — 샌드박스 기능이 제한될 수 있습니다."
  fi

  # 10-C. docker.sock GID 감지 + compose overlay 생성
  local sock="/var/run/docker.sock"
  if [ ! -S "$sock" ]; then
    warn "docker.sock 이 없습니다 ($sock) — 샌드박스 건너뛰기."
    warn "  Docker Desktop 이 켜진 뒤 './openclaw install' 재실행하면 샌드박스가 설정됩니다."
    return 0
  fi
  local gid
  gid=$(stat -f '%g' "$sock" 2>/dev/null || stat -c '%g' "$sock" 2>/dev/null || echo "")
  local sandbox_compose="$OPENCLAW_DIR/docker-compose.sandbox.yml"
  printf 'services:\n  openclaw-gateway:\n    volumes:\n      - %s:/var/run/docker.sock\n' "$sock" > "$sandbox_compose"
  if [ -n "$gid" ]; then
    printf '    group_add:\n      - "%s"\n' "$gid" >> "$sandbox_compose"
  fi

  # 10-D. 샌드박스 포함 gateway 재기동
  local files="-f docker-compose.yml -f $sandbox_compose"
  [ -f "$OPENCLAW_MGR_DIR/compose.security.yml" ] && files="$files -f $OPENCLAW_MGR_DIR/compose.security.yml"
  [ -f "$OPENCLAW_MGR_DIR/compose.network.yml"  ] && files="$files -f $OPENCLAW_MGR_DIR/compose.network.yml"
  # shellcheck disable=SC2086
  docker compose $files up -d openclaw-gateway

  # 10-E. 샌드박스 config 설정
  local cfg_ok=1
  docker compose $files exec -T openclaw-gateway \
    node dist/index.js config set agents.defaults.sandbox.mode non-main \
    >/dev/null 2>&1 || cfg_ok=0
  docker compose $files exec -T openclaw-gateway \
    node dist/index.js config set agents.defaults.sandbox.scope agent \
    >/dev/null 2>&1 || cfg_ok=0
  docker compose $files exec -T openclaw-gateway \
    node dist/index.js config set agents.defaults.sandbox.workspaceAccess none \
    >/dev/null 2>&1 || cfg_ok=0

  if [ "$cfg_ok" = "1" ]; then
    ok "샌드박스 활성화: mode=non-main, scope=agent, workspaceAccess=none"
    info "자세한 내용: https://docs.openclaw.ai/gateway/sandboxing"
  else
    warn "샌드박스 설정 일부 실패 — 'openclaw doctor' 로 상태 확인 후 수동으로 재설정하세요."
    warn "수동 명령:  cd ~/DEV/openclaw && OPENCLAW_SANDBOX=1 ./docker-setup.sh"
  fi
}
run_step sandbox "샌드박스 설정 (기본 ON)" -- step_sandbox


ok "설치 완료! 다음 단계:"
printf '  %s./openclaw doctor%s          현재 상태 확인\n' "$C_BOLD" "$C_RESET"
printf '  %s./openclaw logs%s            컨테이너 로그 보기\n' "$C_BOLD" "$C_RESET"
printf '  %s./openclaw schedule enable%s 매일 자동 업데이트 활성화\n' "$C_BOLD" "$C_RESET"
printf '\n%s💬 첫 대화는 어떻게 하나요?%s\n' "$C_BOLD" "$C_RESET"
printf '  → docs/GUIDE-FIRST-USE.md  (5분 안에 첫 프롬프트까지)\n'
printf '\n  %s빠른 시작 두 가지 — 둘 중 하나를 고르세요%s\n' "$C_BOLD" "$C_RESET"
printf '\n  ① 브라우저로 열기 (그래픽 UI):\n'
printf '       터미널에서:  %sopen http://127.0.0.1:18789%s\n' "$C_BOLD" "$C_RESET"
printf '       또는 Safari/Chrome 주소창에 직접:  %shttp://127.0.0.1:18789%s\n' "$C_BOLD" "$C_RESET"
printf '       ⚠ 주소창에 "open " 까지 같이 붙여넣지 마세요. "open" 은 터미널 명령어입니다.\n'
printf '\n  ② 컨테이너 안 CLI (가장 안정적):\n'
printf '       %scd ~/DEV/openclaw && docker compose exec openclaw-cli bash%s\n' "$C_BOLD" "$C_RESET"
printf '       컨테이너 셸이 뜨면:  %sclaude%s\n' "$C_BOLD" "$C_RESET"
printf '\n  ※ ①번이 "Safari can\047t connect" / "Empty reply" 가 뜨면\n'
printf '       %s./openclaw doctor%s 로 게이트웨이 상태부터 확인하세요.\n' "$C_BOLD" "$C_RESET"
printf '\n%s📁 생성된 디렉토리%s\n' "$C_BOLD" "$C_RESET"
printf '  %-34s %s\n' "OpenClaw 본체:" "$OPENCLAW_DIR"
printf '  %-34s %s\n' "에이전트 파일 (Finder 에서 확인):" "$OPENCLAW_WORKSPACE_DIR"
printf '  %-34s %s\n' "설정·토큰 (자동 관리):" "$OPENCLAW_CONFIG_DIR"
printf '  %-34s %s\n' "백업 위치:" "${BACKUP_DIR:-$HOME/openclaw-backups}"
printf '\n%s🔒 네트워크 모드는 기본 isolated (외부 차단)%s\n' "$C_BOLD" "$C_RESET"
printf '  업데이트가 필요할 때만 잠깐 켜세요:\n'
printf '    %s./openclaw network online --restart%s\n' "$C_BOLD" "$C_RESET"
printf '    %s./openclaw update%s\n' "$C_BOLD" "$C_RESET"
printf '    %s./openclaw network isolated --restart%s\n' "$C_BOLD" "$C_RESET"

# 샌드박스 상태에 따른 안내 — 기본 ON, 명시 또는 docker.sock 부재 시만 OFF
if [ "${OPENCLAW_SANDBOX:-1}" = "1" ] && [ -f "$OPENCLAW_DIR/docker-compose.sandbox.yml" ]; then
  printf '\n%s🛡 샌드박스 활성 (기본) — 에이전트 코드 실행이 별도 격리 컨테이너에서 돌아갑니다.%s\n' "$C_BOLD" "$C_RESET"
elif [ "${OPENCLAW_SANDBOX:-1}" != "1" ]; then
  printf '\n%s⚠ 샌드박스 OFF (.env 에서 OPENCLAW_SANDBOX=0 으로 명시적 비활성화)%s\n' "$C_BOLD" "$C_RESET"
  printf '  켜려면:  %sOPENCLAW_SANDBOX=1 ./openclaw install%s  (또는 사용자 .env 에서 1 로 수정)\n' "$C_BOLD" "$C_RESET"
else
  printf '\n%s⚠ 샌드박스 미설정 — docker.sock 부재로 건너뜀. Docker Desktop 실행 후 재실행하면 자동 설정.%s\n' "$C_BOLD" "$C_RESET"
  printf '    %s./openclaw install%s   ← 다시 실행\n' "$C_BOLD" "$C_RESET"
fi
