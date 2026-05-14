#!/usr/bin/env bash
# =============================================================================
# cmd/setup.sh — OpenClaw 첫 설정 / 재설정 마법사
# -----------------------------------------------------------------------------
# 사용법 / Usage:
#   ./openclaw setup            # 대화형 마법사 (`openclaw onboard` 를 Docker 안에서)
#   ./openclaw setup status     # 현재 설정 상태만 확인 (변경 없음)
#   ./openclaw setup --skip-confirm   # 기존 설정 있어도 확인 없이 바로 마법사
#
# 동작 / How it works:
#   1) OpenClaw 본체의 `openclaw onboard` 를 격리된 Docker 컨테이너 안에서
#      `docker compose run --rm openclaw-cli onboard` 로 실행.
#   2) 마법사는 게이트웨이·인증·워크스페이스·모델·플러그인 등을 차례로 묻고
#      결과를 $OPENCLAW_CONFIG_DIR (기본 ~/.openclaw) 에 영구 저장.
#   3) 호스트에는 아무것도 직접 설치하지 않음. Ctrl+C 로 안전하게 빠져나올 수 있음.
#   4) 멱등 — 언제든지 다시 실행하면 기존 답은 기본값으로 미리 채워짐. 답하기
#      싫은 항목은 Enter 로 기본값 유지.
#
# Tip: 모델만 빠르게 바꾸려면 `./openclaw models add <name>` 또는
#      `./openclaw chat` 의 인터랙티브 모델 picker 가 더 편합니다.
#
# Copyright 2026 박성모 Park Sungmo — MIT License
# =============================================================================
set -euo pipefail
# shellcheck disable=SC1091
. "${OPENCLAW_MGR_DIR}/lib/common.sh"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/DEV/openclaw}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"

skip_confirm=0
action="wizard"

while [ $# -gt 0 ]; do
  case "$1" in
    status)         action="status"; shift ;;
    wizard|"")      action="wizard"; shift ;;
    --skip-confirm) skip_confirm=1; shift ;;
    -h|--help|help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)              die "알 수 없는 인자: $1  (사용: setup [status] [--skip-confirm])" ;;
  esac
done

# ── status: 현재 상태만 ──────────────────────────────────────────────────────
if [ "$action" = "status" ]; then
  printf '\n  %sOpenClaw 설정 상태%s\n' "$C_BOLD$C_CYAN" "$C_RESET" >&2
  printf '  %s──────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET" >&2
  if [ -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ]; then
    ok "설정 파일: $OPENCLAW_CONFIG_DIR/openclaw.json"
    info "  최근 수정: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$OPENCLAW_CONFIG_DIR/openclaw.json" 2>/dev/null || echo 'unknown')"
    info "  최상위 키:"
    python3 -c '
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"    (read error: {e})"); sys.exit(0)
for k in cfg.keys():
    print(f"    - {k}")
' "$OPENCLAW_CONFIG_DIR/openclaw.json" 2>/dev/null || true
  else
    warn "설정 파일 없음: $OPENCLAW_CONFIG_DIR/openclaw.json"
    info "  ./openclaw setup  으로 마법사 실행"
  fi
  printf '\n' >&2
  exit 0
fi

# ── wizard: 사전 점검 ───────────────────────────────────────────────────────
[ -d "$OPENCLAW_DIR/.git" ] \
  || die "OpenClaw 가 설치되지 않았습니다. 먼저 실행:  ./openclaw install"
have docker \
  || die "docker 가 필요합니다. Docker Desktop 실행 중인지 확인하세요."
docker info >/dev/null 2>&1 \
  || die "Docker 데몬이 응답하지 않습니다. Docker Desktop 을 시작한 뒤 다시 시도하세요."

# ── 기존 설정 감지 → 재실행 확인 ────────────────────────────────────────────
if [ -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ] && [ "$skip_confirm" != "1" ]; then
  title "기존 OpenClaw 설정이 있어요"
  info "  위치: $OPENCLAW_CONFIG_DIR/openclaw.json"
  info "  다시 실행해도 안전합니다 — 마법사는 기존 답을 기본값으로 채워주고,"
  info "  답하기 싫은 항목은 Enter 로 그대로 유지할 수 있어요."
  if ! confirm "재설정 마법사를 시작할까요?" n; then
    info "취소됨. 기존 설정 유지."
    exit 0
  fi
fi

title "OpenClaw 설정 마법사"
info "  컨테이너 안에서 'openclaw onboard' 를 격리 실행합니다."
info "  설정·토큰은 ${OPENCLAW_CONFIG_DIR} 에 저장됩니다 (호스트에는 직접 설치 안 함)."
info "  중간에 Ctrl+C 로 안전하게 빠져나올 수 있고, 다시 실행하면 이어서 됩니다."
hr

# ── 사전 점검: 컨테이너에서 호스트 Ollama 에 닿는지 ─────────────────────────
# 마법사는 'Ollama base URL' 단계에서 'http://127.0.0.1:11434' 를 기본값으로
# 보여주지만, 컨테이너 안의 127.0.0.1 은 컨테이너 자신이라 호스트 Ollama 에
# 닿지 않습니다. 호스트 Ollama 는 컨테이너 입장에선 'host.docker.internal'.
# (OpenClaw 본체는 이 URL 을 env/CLI 로 받지 않고 사용자 입력만 받음 —
#  따라서 우리가 해줄 수 있는 건 명확한 사전 안내.)
ollama_in_container_url="http://host.docker.internal:11434"
host_ollama_ok=0
cd "$OPENCLAW_DIR"
if docker compose run --rm --entrypoint="" --no-deps openclaw-cli \
     sh -c "curl -sf --max-time 3 ${ollama_in_container_url}/api/tags >/dev/null" \
     >/dev/null 2>&1; then
  host_ollama_ok=1
fi

if [ "$host_ollama_ok" = "1" ]; then
  printf '\n%s┌─────────────────────────────────────────────────────────────┐%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ ⚠  마법사 안에서 "Ollama base URL" 단계가 나오면 다음을 입력 │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│                                                             │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│    %shttp://host.docker.internal:11434%s%s                    │%s\n' "$C_BOLD$C_YELLOW" "$C_BOLD$C_GREEN" "$C_RESET" "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│                                                             │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ 기본값으로 보이는 http://127.0.0.1:11434 는                  │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s│ 컨테이너 자신을 가리켜서 호스트 Ollama 에 닿지 못합니다.    │%s\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  printf '%s└─────────────────────────────────────────────────────────────┘%s\n\n' "$C_BOLD$C_YELLOW" "$C_RESET" >&2
  info "사전 점검: 컨테이너 → ${ollama_in_container_url}  ${C_GREEN}REACHABLE${C_RESET}"
else
  warn "사전 점검: 컨테이너에서 호스트 Ollama 가 응답 안 함."
  warn "  • Ollama 앱이 실행 중인가요?  (메뉴바 또는: ollama serve)"
  warn "  • 네트워크 모드가 isolated 면 host.docker.internal 도 차단됩니다."
  warn "    → ./openclaw network online --restart  후 다시 시도"
  if [ -t 0 ] && [ "${NONINTERACTIVE:-0}" != "1" ]; then
    confirm "그래도 마법사를 계속 실행할까요? (마법사가 중간에 실패할 수 있음)" n || exit 1
  fi
fi
hr

# ── 실행 ────────────────────────────────────────────────────────────────────
# `run --rm` 이라 종료 시 컨테이너 자동 삭제. gateway 는 이미 떠 있으면 재사용.
# entrypoint(`node dist/index.js`) 가 'onboard' 를 인자로 받아 본체 마법사 실행.
docker compose run --rm openclaw-cli onboard
rc=$?

# ── 후처리: 깨진 Ollama 모델 항목 자동 정리 ─────────────────────────────────
# OpenClaw 본체가 onboard 중 OLLAMA_DEFAULT_MODEL("gemma4") 같은 하드코딩
# 기본값을 모델 목록에 끼워 넣습니다. 사용자가 실제로 깐 모델은 'gemma4:26b'
# 같은 태그 형태이므로 'gemma4' (태그 없음) 호출은 LLM request failed 로 떨어집니다.
# 마법사가 끝난 뒤 openclaw.json 의 models[].id 중 실제 Ollama tag 목록에
# 없는 것들을 제거합니다. 산출물 무결성 검증의 일반화된 형태.
prune_bogus_ollama_models() {
  local cfg="$OPENCLAW_CONFIG_DIR/openclaw.json"
  [ -f "$cfg" ] || return 0

  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  python3 - "$cfg" "$stamp" <<'PY'
import json, os, sys, urllib.request, urllib.error
cfg_path, stamp = sys.argv[1], sys.argv[2]

# Fetch live ollama tags. If unreachable, skip silently — don't damage config.
real = None
for url in ("http://127.0.0.1:11434/api/tags", "http://host.docker.internal:11434/api/tags"):
    try:
        with urllib.request.urlopen(url, timeout=3) as r:
            real = {m.get("name","") for m in json.load(r).get("models", [])}
        break
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError):
        continue
if real is None:
    print("PRUNE_SKIP_OLLAMA_UNREACHABLE")
    sys.exit(0)

with open(cfg_path) as f:
    cfg = json.load(f)
try:
    models_arr = cfg["models"]["providers"]["ollama"]["models"]
except (KeyError, TypeError):
    print("PRUNE_SKIP_NO_OLLAMA_PROVIDER")
    sys.exit(0)

keep, dropped = [], []
for m in models_arr:
    mid = m.get("id", "")
    if mid in real:
        keep.append(m)
    else:
        dropped.append(mid)

if not dropped:
    print("PRUNE_OK_NOTHING_TO_PRUNE")
    sys.exit(0)

# Backup
bak = f"{cfg_path}.bak-{stamp}"
with open(bak, "w") as f:
    json.dump(cfg, f, indent=2)
os.chmod(bak, 0o600)

cfg["models"]["providers"]["ollama"]["models"] = keep
with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2)
os.chmod(cfg_path, 0o600)

print(f"PRUNE_OK_DROPPED::{','.join(dropped)}::{bak}")
PY
}

# ── 자동 default 모델 최적화 ──────────────────────────────────────────────────
# Why this exists (v0.2.22 → v0.2.23):
# OpenClaw 의 onboard 마법사는 사용자가 마지막으로 선택한 모델을 그대로 [0] 에
# 두는데, 그게 24GB RAM 노트북에선 너무 무거운 (예: gemma4:26b, llama3.1:70b)
# 경우가 흔합니다. 첫 메시지에 모델 로딩 55+초 → OpenClaw idle watchdog 2분
# 트리거 → Discord 봇이 timeout. 사용자 입장에선 "왜 응답 안 함" 으로 보임.
#
# 이 함수는 prune 직후 실행되며:
#   1) $OPENCLAW_FORCE_DEFAULT_MODEL 이 set 됐고 그 모델이 등록돼 있으면
#      → 그걸 [0] 으로 강제. 자동 정렬 스킵 (v0.2.23+).
#      예: OPENCLAW_FORCE_DEFAULT_MODEL=gemma4:latest 하면 setup 다시 실행해도
#      안 흔들림. 사용자 명시 선택 영구 lock.
#   2) 강제가 없으면 → Ollama /api/show 로 각 모델의 capabilities·size 조회
#   3) 현재 models[0] 이 이미 tools-capable 이면 그대로 둠 — 명시적 선택 존중
#      (v0.2.23 회귀 fix: 사용자가 골라둔 모델을 size 만 보고 갈아치우지 않음)
#   4) 현재 models[0] 이 tools 못 쓰는 경우에만 가장 작은 tools-capable 로 교체
#   5) 모든 tool-capable 후보의 compat.supportsTools = true 박기 (defensive)
#
# embedding 전용 모델(`nomic-embed-text` 등)·tools 미지원 모델 (`tinyllama` 등)
# 은 후보 풀에서 자동 제외.
optimize_default_ollama_model() {
  local cfg="$OPENCLAW_CONFIG_DIR/openclaw.json"
  [ -f "$cfg" ] || return 0

  python3 - "$cfg" "${OPENCLAW_FORCE_DEFAULT_MODEL:-}" <<'PY'
import json, sys, urllib.request, urllib.error

cfg_path = sys.argv[1]
forced   = sys.argv[2] if len(sys.argv) > 2 else ""

def probe(url, body=None):
    req = urllib.request.Request(
        url,
        data=(json.dumps(body).encode() if body else None),
        headers={"Content-Type": "application/json"} if body else {},
    )
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            return json.load(r)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError):
        return None

# Find a working Ollama base URL.
base = None
for u in ("http://127.0.0.1:11434", "http://host.docker.internal:11434"):
    if probe(u + "/api/tags") is not None:
        base = u
        break
if base is None:
    print("OPT_SKIP_OLLAMA_UNREACHABLE")
    sys.exit(0)

with open(cfg_path) as f:
    cfg = json.load(f)
try:
    arr = cfg["models"]["providers"]["ollama"]["models"]
except (KeyError, TypeError):
    print("OPT_SKIP_NO_OLLAMA_PROVIDER")
    sys.exit(0)
if len(arr) <= 1:
    print("OPT_SKIP_TRIVIAL")
    sys.exit(0)

# Get size + capabilities for each entry.
tags = {m["name"]: m for m in probe(base + "/api/tags").get("models", [])}
enriched = []
for m in arr:
    mid = m.get("id", "")
    info = probe(base + "/api/show", {"name": mid}) or {}
    caps = set(info.get("capabilities", []))
    size = tags.get(mid, {}).get("size", 1 << 62)  # unknown → sort last
    enriched.append((m, mid, caps, size))

# Stamp compat.supportsTools on every tool-capable entry (defensive, idempotent).
def stamp_compat(enriched):
    changed = False
    for (m, mid, caps, sz) in enriched:
        if "tools" in caps:
            if m.setdefault("compat", {}).get("supportsTools") is not True:
                m["compat"]["supportsTools"] = True
                changed = True
    return changed

def gb_of(mid):
    return tags.get(mid, {}).get("size", 0) / 1024**3

old_first = arr[0].get("id", "")

# ── Policy 1 (v0.2.23): if user set OPENCLAW_FORCE_DEFAULT_MODEL, lock it. ──
if forced:
    forced_entry = next((m for m in arr if m.get("id") == forced), None)
    if forced_entry is None:
        # Forced model not registered — leave config alone and report.
        print(f"OPT_SKIP_FORCED_NOT_REGISTERED::{forced}")
        sys.exit(0)
    forced_caps = next((c for (m, mid, c, sz) in enriched if mid == forced), set())
    if "tools" not in forced_caps:
        print(f"OPT_WARN_FORCED_NO_TOOLS::{forced}")
        # still honor the user's choice, just warn.
    if old_first != forced:
        others = [m for m in arr if m.get("id") != forced]
        cfg["models"]["providers"]["ollama"]["models"] = [forced_entry] + others
        stamp_compat(enriched)
        with open(cfg_path, "w") as f:
            json.dump(cfg, f, indent=2)
        print(f"OPT_OK_FORCED::{old_first}::{gb_of(old_first):.1f}::{forced}::{gb_of(forced):.1f}")
        sys.exit(0)
    if stamp_compat(enriched):
        with open(cfg_path, "w") as f:
            json.dump(cfg, f, indent=2)
    print(f"OPT_OK_FORCED_ALREADY::{forced}")
    sys.exit(0)

# ── Policy 2: respect existing models[0] if it's tools-capable. ──────────────
# v0.2.23 회귀 fix: 사용자가 명시적으로 골라둔 모델을 size 만 보고 갈아치우지 않음.
# 한 번 사용자가 결정해서 [0] 으로 옮긴 모델은 그게 tool 호출 가능한 한 그대로 둠.
old_first_caps = next((c for (m, mid, c, sz) in enriched if mid == old_first), set())
if "tools" in old_first_caps:
    if stamp_compat(enriched):
        with open(cfg_path, "w") as f:
            json.dump(cfg, f, indent=2)
    print(f"OPT_OK_RESPECT_USER_CHOICE::{old_first}")
    sys.exit(0)

# ── Policy 3: models[0] can't call tools → auto-pick lightest tool-capable. ──
tool_capable = [(m, mid, caps, sz) for (m, mid, caps, sz) in enriched if "tools" in caps]
if not tool_capable:
    print("OPT_SKIP_NO_TOOL_CAPABLE_MODEL")
    sys.exit(0)

tool_capable.sort(key=lambda t: t[3])
chosen = tool_capable[0]
new_first = chosen[1]
others_in_order = [e[0] for e in enriched if e[1] != new_first]
cfg["models"]["providers"]["ollama"]["models"] = [chosen[0]] + others_in_order
stamp_compat(enriched)
with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2)
print(f"OPT_OK_REORDERED::{old_first}::{gb_of(old_first):.1f}::{new_first}::{gb_of(new_first):.1f}")
PY
}

if [ "$rc" = "0" ]; then
  prune_result="$(prune_bogus_ollama_models 2>&1 | tail -1)"
  case "$prune_result" in
    PRUNE_OK_DROPPED::*)
      dropped="${prune_result#PRUNE_OK_DROPPED::}"
      dropped_models="${dropped%%::*}"
      backup_path="${dropped#*::}"
      ok "설정 정리: openclaw.json 에서 실제 설치되지 않은 모델 항목 제거"
      info "  제거됨: ${C_BOLD}${dropped_models}${C_RESET}"
      info "  (OpenClaw 의 OLLAMA_DEFAULT_MODEL 하드코딩 같은 가짜 기본값이 끼어든 흔적)"
      info "  백업:    ${backup_path}"
      ;;
    PRUNE_OK_NOTHING_TO_PRUNE)
      info "설정 정리: 모든 Ollama 모델 항목이 실제 설치된 모델과 일치"
      ;;
    PRUNE_SKIP_OLLAMA_UNREACHABLE)
      warn "설정 정리 스킵: Ollama 가 응답 안 함 → 가짜 항목 검사 불가"
      ;;
    *)
      : # silent on unknown — don't surface noise to user
      ;;
  esac

  # 자동 default 모델 최적화
  #   1) $OPENCLAW_FORCE_DEFAULT_MODEL set 됐으면 그걸 강제
  #   2) 아니면 현재 [0] 이 tools-capable 이면 그대로 존중
  #   3) 아니면 가장 작은 tools-capable 모델로 swap
  opt_result="$(optimize_default_ollama_model 2>&1 | tail -1)"
  case "$opt_result" in
    OPT_OK_FORCED::*)
      payload="${opt_result#OPT_OK_FORCED::}"
      old_id="${payload%%::*}";       rest="${payload#*::}"
      old_gb="${rest%%::*}";          rest="${rest#*::}"
      new_id="${rest%%::*}";          new_gb="${rest#*::}"
      ok "default 모델 강제 (\$OPENCLAW_FORCE_DEFAULT_MODEL): ${C_BOLD}${old_id}${C_RESET} (${old_gb}GB) → ${C_BOLD}${new_id}${C_RESET} (${new_gb}GB)"
      info "  사용자가 .env 또는 셸에서 ${C_BOLD}OPENCLAW_FORCE_DEFAULT_MODEL=${new_id}${C_RESET} 으로 lock 함 — 자동 정렬 스킵."
      ;;
    OPT_OK_FORCED_ALREADY::*)
      info "default 모델: ${C_BOLD}${opt_result#OPT_OK_FORCED_ALREADY::}${C_RESET} (\$OPENCLAW_FORCE_DEFAULT_MODEL 로 lock — 이미 정확)"
      ;;
    OPT_WARN_FORCED_NO_TOOLS::*)
      warn "강제 모델 ${C_BOLD}${opt_result#OPT_WARN_FORCED_NO_TOOLS::}${C_RESET} 은 'tools' capability 없음 — Discord/agent 가 도구 못 씀."
      info "  의도한 거면 그대로 두지만, Discord 봇이 도구 호출 못 함을 알아 두세요."
      ;;
    OPT_SKIP_FORCED_NOT_REGISTERED::*)
      forced_id="${opt_result#OPT_SKIP_FORCED_NOT_REGISTERED::}"
      warn "\$OPENCLAW_FORCE_DEFAULT_MODEL=${C_BOLD}${forced_id}${C_RESET} 인데 openclaw.json 에 등록 안 됨."
      info "  먼저 ${C_BOLD}./openclaw models add ${forced_id}${C_RESET} 또는 onboard 마법사로 추가."
      ;;
    OPT_OK_RESPECT_USER_CHOICE::*)
      info "default 모델: ${C_BOLD}${opt_result#OPT_OK_RESPECT_USER_CHOICE::}${C_RESET} (사용자 선택 유지, tools-capable 확인됨)"
      ;;
    OPT_OK_REORDERED::*)
      payload="${opt_result#OPT_OK_REORDERED::}"
      old_id="${payload%%::*}";       rest="${payload#*::}"
      old_gb="${rest%%::*}";          rest="${rest#*::}"
      new_id="${rest%%::*}";          new_gb="${rest#*::}"
      ok "default 모델 자동 최적화: ${C_BOLD}${old_id}${C_RESET} (${old_gb}GB) → ${C_BOLD}${new_id}${C_RESET} (${new_gb}GB)"
      info "  Why: 현재 default 가 tools 호출 못 함 → Discord/agent 동작 안 함. 가장 작은 tool-capable 모델로 swap."
      info "  특정 모델로 lock 하고 싶으면 ${C_BOLD}OPENCLAW_FORCE_DEFAULT_MODEL=<id>${C_RESET} 을 .env 에."
      ;;
    OPT_SKIP_NO_TOOL_CAPABLE_MODEL)
      warn "Ollama 모델 중 'tools' capability 있는 게 하나도 없음 — Discord/agent 가 도구 못 씀."
      info "  추천: ${C_BOLD}ollama pull gemma4:latest${C_RESET}  (8.9GB, vision/audio/tools/thinking)"
      info "       또는 ${C_BOLD}ollama pull qwen2.5:3b-instruct${C_RESET}  (1.8GB, 가벼움)"
      ;;
    OPT_SKIP_OLLAMA_UNREACHABLE|OPT_SKIP_NO_OLLAMA_PROVIDER|OPT_SKIP_TRIVIAL|*)
      : # silent — 위 prune 가 이미 비슷한 메시지를 띄웠을 것
      ;;
  esac
fi

hr
if [ "$rc" = "0" ]; then
  ok "설정 마법사 완료."
  info "  설정 확인:  ./openclaw setup status"
  info "  채팅 시작:  ./openclaw chat   (또는 docker compose run --rm openclaw-cli tui)"
else
  warn "마법사가 정상 종료되지 않았습니다 (rc=$rc)."
  info "  중간에 빠져나왔다면 같은 명령으로 이어서 진행:  ./openclaw setup"
  info "  'Ollama not reachable' 로 끊겼다면 — 'Ollama base URL' 단계에서"
  info "    http://127.0.0.1:11434  대신  ${C_BOLD}http://host.docker.internal:11434${C_RESET}  을 입력하세요."
fi
exit "$rc"
