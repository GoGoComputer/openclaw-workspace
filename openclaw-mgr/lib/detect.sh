#!/usr/bin/env bash
# =============================================================================
# lib/detect.sh — 현재 시스템 상태 조사
# -----------------------------------------------------------------------------
# 목적   : 설치/실행/네트워크/하드웨어 상태를 KEY=VALUE 형태로 출력
# 입력   : OPENCLAW_DIR, OPENCLAW_PORT, ENABLE_OLLAMA 환경변수
# 출력   : stdout 으로 detect_* 변수들 (eval 가능한 형태, 값은 %q 셸 안전 인용)
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================

# 한 줄 KV 출력 헬퍼 — 값은 셸 안전(%q)으로 인용해 공백/특수문자 문제 차단.
_kv() { printf '%s=%q\n' "$1" "${2:-}"; }

detect_all() {
  detect_os
  detect_hw
  detect_brew
  detect_xcode
  detect_docker
  detect_ollama
  detect_repo
  detect_compose
  detect_ports
  detect_disk
}

detect_os() {
  _kv os_name        "$(uname -s)"
  _kv os_arch        "$(uname -m)"
  _kv macos_version  "$(sw_vers -productVersion 2>/dev/null || echo unknown)"
}

detect_hw() {
  local brand ram_bytes ram_gb
  brand="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
  ram_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  ram_gb=$(( ram_bytes / 1024 / 1024 / 1024 ))
  _kv cpu_brand "$brand"
  _kv ram_gb    "$ram_gb"
}

detect_brew() {
  if command -v brew >/dev/null 2>&1; then
    _kv brew_installed yes
    _kv brew_prefix    "$(brew --prefix 2>/dev/null || echo '')"
  else
    _kv brew_installed no
    _kv brew_prefix    ""
  fi
}

detect_xcode() {
  if xcode-select -p >/dev/null 2>&1; then
    _kv xcode_clt_installed yes
  else
    _kv xcode_clt_installed no
  fi
}

detect_docker() {
  local installed=no running=no compose=no
  command -v docker >/dev/null 2>&1 && installed=yes
  if [ "$installed" = "yes" ]; then
    docker info >/dev/null 2>&1 && running=yes
    docker compose version >/dev/null 2>&1 && compose=yes
  fi
  _kv docker_installed "$installed"
  _kv docker_running   "$running"
  _kv compose_v2       "$compose"
}

detect_ollama() {
  local installed=no running=no models=""
  command -v ollama >/dev/null 2>&1 && installed=yes
  if [ "$installed" = "yes" ]; then
    if curl -sS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      running=yes
      models="$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | paste -sd, - 2>/dev/null || echo '')"
    fi
  fi
  _kv ollama_installed "$installed"
  _kv ollama_running   "$running"
  _kv ollama_models    "$models"
}

detect_repo() {
  local dir="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
  _kv repo_dir "$dir"
  if [ -d "$dir/.git" ]; then
    _kv repo_cloned yes
    _kv repo_branch "$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
    if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
      _kv repo_dirty yes
    else
      _kv repo_dirty no
    fi
  else
    _kv repo_cloned no
    _kv repo_branch ""
    _kv repo_dirty  no
  fi
}

detect_compose() {
  local dir="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
  local up=no count=0
  if [ -d "$dir" ] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    count="$(cd "$dir" && docker compose ps -q 2>/dev/null | wc -l | tr -d ' ')"
    [ "${count:-0}" -gt 0 ] 2>/dev/null && up=yes
  fi
  _kv compose_up              "$up"
  _kv compose_container_count "$count"
}

detect_ports() {
  local port conflicts="" pid proc
  for port in 11434 "${OPENCLAW_PORT:-8000}"; do
    pid="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | head -1)"
    if [ -n "$pid" ]; then
      proc="$(ps -p "$pid" -o comm= 2>/dev/null)"
      # 11434 + ollama = 정상 (OpenClaw 가 호스트 Ollama 를 공유)
      if [ "$port" = "11434" ] && echo "$proc" | grep -qi ollama; then
        continue
      fi
      conflicts="${conflicts}${conflicts:+,}${port}"
    fi
  done
  _kv port_conflicts "$conflicts"
}

detect_disk() {
  local free_gb
  free_gb="$(df -g "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')"
  _kv disk_free_gb "${free_gb:-0}"
}

detect_schedule() {
  local label="com.user.openclaw.update"
  if launchctl list 2>/dev/null | grep -q "$label"; then
    _kv schedule_enabled yes
  else
    _kv schedule_enabled no
  fi
}

# korea-sovereign-ai (자매 프로젝트) 감지.
# 호스트 Ollama 에 EXAONE/A.X/Solar 같은 한국 모델이 있으면 자동 인식.
detect_korea_ai() {
  local found=no models=""
  if command -v ollama >/dev/null 2>&1; then
    models="$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' \
      | grep -Ei 'exaone|solar|ax-?[0-9]|skt|upstage|kanana|llama-ko' \
      | paste -sd, - 2>/dev/null || echo '')"
    [ -n "$models" ] && found=yes
  fi
  # 같은 사용자가 자매 repo 를 깔아둔 경우의 흔한 경로
  local ksai_dir=""
  for cand in "$HOME/DEV/llmDev/korea-ai" "$HOME/korea-sovereign-ai" "$HOME/DEV/llmDev/korea-sovereign-ai"; do
    if [ -d "$cand/.git" ]; then ksai_dir="$cand"; found=yes; break; fi
  done
  _kv korea_ai_detected "$found"
  _kv korea_ai_models   "$models"
  _kv korea_ai_dir      "$ksai_dir"
}
