#!/usr/bin/env bash
# =============================================================================
# cmd/models.sh — Manage local Ollama models for OpenClaw (low-friction)
# -----------------------------------------------------------------------------
# Subcommands:
#   list            Show currently-installed (host Ollama) + .env-configured models
#                   (default if no subcommand given).
#   add NAME...     Append model(s) to OLLAMA_MODELS in .env (idempotent).
#                   With --pull (default), also `ollama pull` immediately.
#   remove NAME     Remove a model name from OLLAMA_MODELS in .env.
#                   Use --purge to also `ollama rm` the model from Ollama.
#   pull NAME       Direct `ollama pull` (does not touch .env).
#   suggest         Print a curated list of recommended models for 24GB Macs.
#
# Why this exists:
#   Editing `.env` manually scares non-developers. This command is a one-line
#   ergonomic wrapper that validates input (delegates to sec_validate_models),
#   updates `.env` safely, and (optionally) triggers the pull.
#
# `.env` location: prefers $OPENCLAW_MGR_DIR/.env, falls back to
# $OPENCLAW_MGR_HOME/.env (Homebrew install case).
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/sec.sh"

env_file_path() {
  if [ -f "$OPENCLAW_MGR_DIR/.env" ] && [ -w "$OPENCLAW_MGR_DIR/.env" ]; then
    printf '%s\n' "$OPENCLAW_MGR_DIR/.env"
  else
    printf '%s\n' "${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/.env"
  fi
}

read_models_var() {
  local f="$1"
  [ -f "$f" ] || { printf ''; return; }
  awk -F= '
    /^[[:space:]]*OLLAMA_MODELS[[:space:]]*=/ {
      v=$0; sub(/^[^=]*=/,"",v); gsub(/^[ \t"]+|[ \t"]+$/,"",v); print v; exit
    }' "$f"
}

write_models_var() {
  local f="$1" newval="$2" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/openclaw.env.XXXXXX")"
  if [ -f "$f" ] && grep -Eq '^[[:space:]]*OLLAMA_MODELS[[:space:]]*=' "$f"; then
    awk -v v="$newval" '
      BEGIN{done=0}
      /^[[:space:]]*OLLAMA_MODELS[[:space:]]*=/ && !done {
        printf "OLLAMA_MODELS=\"%s\"\n", v; done=1; next
      }
      { print }
    ' "$f" > "$tmp"
  else
    [ -f "$f" ] && cat "$f" > "$tmp"
    printf '\n# Added by `openclaw models`\nOLLAMA_MODELS="%s"\n' "$newval" >> "$tmp"
  fi
  mv -- "$tmp" "$f"
  chmod 600 "$f" 2>/dev/null || true
}

cmd_list() {
  local f cur
  f="$(env_file_path)"
  cur="$(read_models_var "$f")"
  printf '\n  %s%sOpenClaw 모델 / Models%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET" >&2
  printf '  %s──────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET" >&2

  printf '\n  %s.env%s = %s\n' "$C_BOLD" "$C_RESET" "$f"
  if [ -n "$cur" ]; then
    printf '  %sOLLAMA_MODELS%s = %s\n' "$C_BOLD" "$C_RESET" "$cur"
  else
    printf '  %sOLLAMA_MODELS%s = %s(없음 / empty)%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
  fi

  printf '\n  %s호스트 Ollama 에 설치된 모델 / Locally installed (host Ollama):%s\n' "$C_BOLD" "$C_RESET"
  if command -v ollama >/dev/null 2>&1; then
    if ollama list 2>/dev/null | tail -n +2 | awk 'NF{ printf "    • %s  (%s, %s %s)\n", $1, $3, $4, $5 }'; then :; fi
  else
    printf '    %s(ollama 미설치 — `openclaw install` 먼저)%s\n' "$C_DIM" "$C_RESET"
  fi

  printf '\n  %s💡 사용법 / Usage:%s\n' "$C_BOLD" "$C_RESET"
  printf '    openclaw models add <name>      # 추가 + 자동 pull\n'
  printf '    openclaw models add <name> --no-pull\n'
  printf '    openclaw models remove <name>\n'
  printf '    openclaw models pull <name>     # .env 안 건드리고 pull 만\n'
  printf '    openclaw models suggest         # 추천 모델 보기\n\n'
}

cmd_suggest() {
  cat <<'EOF'

  💡 추천 모델 / Recommended models (Apple Silicon, 24GB RAM)

  ─── 코딩 / Coding ─────────────────────────────────────────────
    qwen2.5-coder:7b        ~4.7GB · 코딩 추천 / coding pick
    deepseek-coder-v2:16b   ~9.3GB · 강함 / stronger, slower
    codellama:13b           ~7.4GB · 클래식 / classic

  ─── 범용 / General ────────────────────────────────────────────
    llama3.1:8b             ~4.9GB · 균형 / balanced
    mistral:7b              ~4.1GB · 가벼움 / lightweight
    qwen2.5:14b             ~9.0GB · 다국어 강함

  ─── 한국어 (소버린) / Korean models ────────────────────────────
    exaone3.5:7.8b          ~4.8GB · LG EXAONE
    solar-pro:22b           ~13GB  · Upstage Solar (24GB 마지노선)
    hf.co/LGAI-EXAONE/EXAONE-4.0-1.2B-GGUF:Q4_K_M
                            ~0.8GB · 초경량 EXAONE

  ─── 멀티모달·전문 / Specialized ───────────────────────────────
    llava:7b                ~4.7GB · 이미지 입력
    medgemma:27b            ~17GB  · 의료
    translategemma:27b      ~17GB  · 번역

  설치: openclaw models add <name>      (자동 pull)
  목록: openclaw models list

EOF
}

cmd_add() {
  local pull=1 names=""
  for a in "$@"; do
    case "$a" in
      --no-pull) pull=0 ;;
      --pull)    pull=1 ;;
      -*)        die "알 수 없는 옵션: $a" ;;
      *)         names="${names} $a" ;;
    esac
  done
  names="$(printf '%s' "$names" | sed 's/^ *//')"
  [ -n "$names" ] || die "사용법: openclaw models add <name> [<name>...] [--no-pull]"

  local f cur new merged
  f="$(env_file_path)"
  [ -f "$f" ] || die ".env 가 없습니다: $f  (먼저: openclaw install 또는 openclaw)"
  cur="$(read_models_var "$f")"

  # Build merged comma-separated list, dedup, preserve order.
  merged="$cur"
  for n in $names; do
    sec_validate_models "$n" || { warn "잘못된 모델명 형식: $n  (스킵)"; continue; }
    case ",$merged," in
      *",$n,"*) info "이미 있음: $n" ;;
      *)
        if [ -z "$merged" ]; then merged="$n"; else merged="$merged,$n"; fi
        ok "추가: $n"
        ;;
    esac
  done

  if [ "$merged" != "$cur" ]; then
    write_models_var "$f" "$merged"
    ok ".env 갱신: OLLAMA_MODELS=$merged"
  else
    info "변경 없음."
  fi

  if [ "$pull" -eq 1 ]; then
    command -v ollama >/dev/null 2>&1 || { warn "ollama 미설치 — pull 스킵"; return 0; }
    for n in $names; do
      info "ollama pull $n"
      ollama pull "$n" || warn "pull 실패: $n"
    done
  fi
}

cmd_remove() {
  local purge=0 names=""
  for a in "$@"; do
    case "$a" in
      --purge) purge=1 ;;
      -*)      die "알 수 없는 옵션: $a" ;;
      *)       names="${names} $a" ;;
    esac
  done
  names="$(printf '%s' "$names" | sed 's/^ *//')"
  [ -n "$names" ] || die "사용법: openclaw models remove <name> [--purge]"

  local f cur new
  f="$(env_file_path)"
  [ -f "$f" ] || die ".env 가 없습니다: $f"
  cur="$(read_models_var "$f")"
  new="$cur"
  for n in $names; do
    new="$(printf '%s\n' "$new" \
      | tr ',' '\n' | grep -v -x -- "$n" | paste -sd, -)"
  done
  if [ "$new" != "$cur" ]; then
    write_models_var "$f" "$new"
    ok ".env 갱신: OLLAMA_MODELS=${new:-(empty)}"
  else
    info "변경 없음."
  fi
  if [ "$purge" -eq 1 ] && command -v ollama >/dev/null 2>&1; then
    for n in $names; do
      info "ollama rm $n"
      ollama rm "$n" || warn "rm 실패: $n"
    done
  fi
}

cmd_pull() {
  [ "$#" -ge 1 ] || die "사용법: openclaw models pull <name>"
  command -v ollama >/dev/null 2>&1 || die "ollama 미설치 — `openclaw install` 먼저."
  for n in "$@"; do
    info "ollama pull $n"
    sec_validate_models "$n" || { warn "잘못된 모델명: $n"; continue; }
    ollama pull "$n" || warn "pull 실패: $n"
  done
}

sub="${1:-list}"
[ $# -gt 0 ] && shift || true
case "$sub" in
  list|ls|"")    cmd_list "$@" ;;
  add|install)   cmd_add  "$@" ;;
  remove|rm|del) cmd_remove "$@" ;;
  pull)          cmd_pull "$@" ;;
  suggest|recommend) cmd_suggest ;;
  -h|--help|help)
    sed -n '2,18p' "$0"
    exit 0 ;;
  *) die "알 수 없는 서브커맨드: $sub  (list|add|remove|pull|suggest)" ;;
esac
