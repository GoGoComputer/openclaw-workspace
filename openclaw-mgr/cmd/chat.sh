#!/usr/bin/env bash
# =============================================================================
# cmd/chat.sh — Terminal REPL chat with the openclaw agent (via host Ollama)
# -----------------------------------------------------------------------------
# 사용법 / Usage:
#   ./openclaw chat                       # 기본 모델 + 인격 파일 자동 로드
#   ./openclaw chat -m llama3.1:8b        # 모델 지정
#   ./openclaw chat --no-system           # 인격(IDENTITY/SOUL/USER/...) 비활성
#   ./openclaw chat --host http://...     # Ollama 호스트 지정
#
# REPL 슬래시 커맨드 / Slash commands:
#   /exit  /quit  /q     채팅 종료
#   /reset               대화 컨텍스트 초기화 (시스템 프롬프트는 유지)
#   /model <name>        모델 전환
#   /history             현재 컨텍스트의 메시지 수
#   /help  /?            도움말
#
# 동작 / How it works:
#   1) 워크스페이스($OPENCLAW_WORKSPACE_DIR)의 IDENTITY.md, SOUL.md, USER.md,
#      AGENTS.md, MEMORY.md 를 system prompt 로 묶어 자동 로드.
#   2) Ollama HTTP API(/api/chat) 를 stream=true 로 호출해 토큰 단위 출력.
#   3) 메시지는 임시 JSON 파일에 누적 — 종료 시 자동 삭제.
#
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

# ── 기본값 ───────────────────────────────────────────────────────────────────
OLLAMA_HOST_DEFAULT="${OLLAMA_HOST:-http://localhost:11434}"
WS_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/DEV/openclawAgent}"
MODELS_CSV="${OLLAMA_MODELS:-qwen2.5-coder:7b}"
DEFAULT_MODEL="${MODELS_CSV%%,*}"

ollama_host="$OLLAMA_HOST_DEFAULT"
model="$DEFAULT_MODEL"
load_system=1

usage() {
  sed -n '2,18p' "$0" >&2
}

# ── CLI 파싱 ────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--model)
      [ $# -ge 2 ] || die "사용법: --model <name>"
      model="$2"; shift 2 ;;
    --host)
      [ $# -ge 2 ] || die "사용법: --host <url>"
      ollama_host="$2"; shift 2 ;;
    --no-system|--no-personality)
      load_system=0; shift ;;
    -h|--help|help)
      usage; exit 0 ;;
    *)
      err "알 수 없는 옵션: $1"; usage; exit 2 ;;
  esac
done

# ── 사전 점검 ────────────────────────────────────────────────────────────────
have curl    || die "curl 이 필요합니다."
have python3 || die "python3 이 필요합니다. (macOS 기본 제공)"

if ! curl -sf --max-time 3 "${ollama_host}/api/tags" >/dev/null 2>&1; then
  err "Ollama 가 응답하지 않습니다: ${ollama_host}"
  info "다음 중 하나를 시도하세요:"
  info "  • macOS Ollama 앱 실행 (메뉴바 아이콘 확인)"
  info "  • 터미널에서: ollama serve"
  info "  • 모델 설치:  ./openclaw models add ${model}"
  exit 1
fi

# 모델이 로컬에 있는지 확인 (없으면 안내만 — pull 은 사용자 결정)
if ! curl -sf --max-time 5 "${ollama_host}/api/tags" \
   | python3 -c 'import json,sys; t=json.load(sys.stdin); names={m.get("name","") for m in t.get("models",[])}; sys.exit(0 if sys.argv[1] in names else 1)' \
   "$model" >/dev/null 2>&1; then
  warn "모델 '${model}' 이 로컬에 없을 수 있습니다."
  warn "  설치:  ./openclaw models add ${model}"
  warn "  또는:  ollama pull ${model}"
  if [ -t 0 ] && [ "${NONINTERACTIVE:-0}" != "1" ]; then
    confirm "그래도 계속할까요?" n || exit 1
  fi
fi

# ── 임시 상태 파일 ──────────────────────────────────────────────────────────
HISTORY_FILE="$(mktemp "${TMPDIR:-/tmp}/openclaw-chat-hist.XXXXXX.json")"
SYSPROMPT_FILE="$(mktemp "${TMPDIR:-/tmp}/openclaw-chat-sys.XXXXXX.txt")"
cleanup_chat() { rm -f -- "$HISTORY_FILE" "$SYSPROMPT_FILE" 2>/dev/null || true; }
trap cleanup_chat EXIT INT TERM

# ── 시스템 프롬프트 빌드 ────────────────────────────────────────────────────
build_system_prompt() {
  : > "$SYSPROMPT_FILE"
  [ "$load_system" = "1" ] || return 0
  [ -d "$WS_DIR" ] || { warn "워크스페이스 디렉터리 없음: $WS_DIR"; return 0; }
  local f loaded=0
  for f in IDENTITY.md SOUL.md USER.md AGENTS.md MEMORY.md; do
    [ -f "$WS_DIR/$f" ] || continue
    {
      printf '# === %s ===\n' "$f"
      cat "$WS_DIR/$f"
      printf '\n\n'
    } >> "$SYSPROMPT_FILE"
    loaded=$((loaded + 1))
  done
  if [ "$loaded" -gt 0 ]; then
    info "인격 파일 ${loaded}개 로드 (IDENTITY/SOUL/USER/AGENTS/MEMORY 중)"
  else
    info "인격 파일 없음 — 일반 어시스턴트로 시작합니다."
  fi
}

build_system_prompt
init_history() {
  python3 - "$HISTORY_FILE" "$SYSPROMPT_FILE" <<'PY'
import json, sys, os
hist_fp, sys_fp = sys.argv[1], sys.argv[2]
msgs = []
if os.path.exists(sys_fp) and os.path.getsize(sys_fp) > 0:
    with open(sys_fp, "r", encoding="utf-8") as f:
        sp = f.read().strip()
    if sp:
        msgs.append({"role": "system", "content": sp})
with open(hist_fp, "w", encoding="utf-8") as f:
    json.dump(msgs, f)
PY
}
init_history

# ── Ollama 호출(스트리밍) ───────────────────────────────────────────────────
send_message() {
  local user_msg="$1"
  python3 - "$HISTORY_FILE" "$ollama_host" "$model" "$user_msg" <<'PY'
import json, sys
import urllib.request, urllib.error

hist_fp, host, model, user_msg = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(hist_fp, "r", encoding="utf-8") as f:
    messages = json.load(f)

messages.append({"role": "user", "content": user_msg})

payload = json.dumps({
    "model": model,
    "messages": messages,
    "stream": True,
}).encode("utf-8")

req = urllib.request.Request(
    f"{host}/api/chat",
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST",
)

collected = []
try:
    with urllib.request.urlopen(req, timeout=600) as resp:
        for raw in resp:
            line = raw.decode("utf-8", errors="replace").strip()
            if not line:
                continue
            try:
                chunk = json.loads(line)
            except json.JSONDecodeError:
                continue
            if "error" in chunk:
                sys.stderr.write(f"\n[ollama error] {chunk['error']}\n")
                sys.exit(2)
            tok = chunk.get("message", {}).get("content", "")
            if tok:
                sys.stdout.write(tok)
                sys.stdout.flush()
                collected.append(tok)
            if chunk.get("done"):
                break
except urllib.error.HTTPError as e:
    body = ""
    try:
        body = e.read().decode("utf-8", errors="replace")
    except Exception:
        pass
    sys.stderr.write(f"\n[http {e.code}] {body or e.reason}\n")
    sys.exit(2)
except urllib.error.URLError as e:
    sys.stderr.write(f"\n[connection error] {e.reason}\n")
    sys.exit(2)
except KeyboardInterrupt:
    sys.stderr.write("\n[interrupted]\n")
    # 부분 응답이라도 컨텍스트에 남겨 일관성 유지
    messages.append({"role": "assistant", "content": "".join(collected)})
    with open(hist_fp, "w", encoding="utf-8") as f:
        json.dump(messages, f)
    sys.exit(130)

print()  # 토큰 스트림 종료 후 줄바꿈
messages.append({"role": "assistant", "content": "".join(collected)})
with open(hist_fp, "w", encoding="utf-8") as f:
    json.dump(messages, f)
PY
}

show_history() {
  python3 - "$HISTORY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    msgs = json.load(f)
counts = {"system":0, "user":0, "assistant":0}
for m in msgs:
    counts[m.get("role","?")] = counts.get(m.get("role","?"),0) + 1
print(f"  system={counts.get('system',0)}  user={counts.get('user',0)}  assistant={counts.get('assistant',0)}  (total={len(msgs)})")
PY
}

# ── REPL ────────────────────────────────────────────────────────────────────
printf '\n  %s%s openclaw chat%s  ·  model=%s%s%s  ·  host=%s%s%s\n' \
  "$C_BOLD" "$C_CYAN" "$C_RESET" \
  "$C_BOLD" "$model" "$C_RESET" \
  "$C_DIM" "$ollama_host" "$C_RESET" >&2
printf '  %s/exit · /reset · /model <name> · /history · /help%s\n\n' "$C_DIM" "$C_RESET" >&2

while :; do
  printf '%syou ›%s ' "$C_BOLD$C_BLUE" "$C_RESET"
  if ! IFS= read -r line; then
    printf '\n' >&2
    ok "bye"
    break
  fi
  # trim
  line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$line" ] || continue

  case "$line" in
    /exit|/quit|/q)
      ok "bye"; break ;;
    /reset)
      init_history; ok "context cleared (system prompt 유지)"; continue ;;
    /model)
      warn "사용법: /model <name>"; continue ;;
    /model\ *)
      newmod="${line#/model }"
      newmod="$(printf '%s' "$newmod" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      if [ -z "$newmod" ]; then
        warn "사용법: /model <name>"
      else
        model="$newmod"
        ok "model → $model"
      fi
      continue ;;
    /history)
      show_history; continue ;;
    /help|/\?)
      printf '  %s/exit /quit /q%s        채팅 종료\n' "$C_BOLD" "$C_RESET" >&2
      printf '  %s/reset%s                대화 컨텍스트 초기화\n' "$C_BOLD" "$C_RESET" >&2
      printf '  %s/model <name>%s         모델 전환\n' "$C_BOLD" "$C_RESET" >&2
      printf '  %s/history%s              메시지 수 표시\n' "$C_BOLD" "$C_RESET" >&2
      printf '  %s/help /?%s              도움말\n' "$C_BOLD" "$C_RESET" >&2
      continue ;;
    /*)
      warn "알 수 없는 명령: $line  (/help)"; continue ;;
  esac

  printf '%s%s ›%s ' "$C_BOLD$C_GREEN" "$model" "$C_RESET"
  if ! send_message "$line"; then
    rc=$?
    if [ "$rc" -ne 130 ]; then
      warn "응답 실패 (rc=$rc)"
    fi
  fi
done
