# 🔄 일상 사용 가이드 / Daily Use Guide

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)

> **한 줄 요약 / TL;DR.** 첫 설치·setup 이 끝난 후 **매일 켜고 끄는** 사이클 가이드. 자주 쓰는 6개 명령, 시나리오별 정확한 절차, 종료 시 무엇이 보존되는지, 자주 막히는 부분 빠른 해결.

<table>
<tr><td><b>누구에게 좋은가요?</b></td><td>• <code>./openclaw install</code> + <code>./openclaw setup</code> 끝낸 후 "이제 어떻게 다시 시작하지?" 라고 검색하는 사람<br>• 매일 같은 명령 3개만 외우고 싶은 사람<br>• 컴퓨터 종료할 때 OpenClaw 도 깨끗하게 끄고 싶은 사람</td></tr>
<tr><td><b>전제 조건</b></td><td>• <a href="GUIDE-FIRST-USE.md">첫 사용 가이드</a> 완료 — 컨테이너 떠 있고, <code>./openclaw setup</code> 한 번 진행, <code>./openclaw chat</code> 또는 <code>tui</code> 가 동작하는 상태</td></tr>
<tr><td><b>이 가이드에서 안 다루는 것</b></td><td>• 첫 설치 → <a href="../README.md#-5분-시작-비개발자-ok">README 5분 시작</a><br>• OpenClaw 마법사 단계별 → <a href="../README.md#-install-직후--첫-사용">README 마법사 14단계</a><br>• Discord 봇 운영 → <a href="GUIDE-DISCORD-BOT.md">GUIDE-DISCORD-BOT</a></td></tr>
</table>

---

## 📖 목차 / Contents

- [⚡ TL;DR — 가장 자주 쓰는 6개 명령](#-tldr--가장-자주-쓰는-6개-명령)
- [🌅 시나리오 1 — 매일 아침 컴퓨터 켰을 때](#-시나리오-1--매일-아침-컴퓨터-켰을-때)
- [☕ 시나리오 2 — 잠깐 자리 비울 때](#-시나리오-2--잠깐-자리-비울-때)
- [🌙 시나리오 3 — 컴퓨터 끄기 전](#-시나리오-3--컴퓨터-끄기-전)
- [💬 시나리오 4 — 이전 대화 이어가기](#-시나리오-4--이전-대화-이어가기)
- [🐛 시나리오 5 — 뭔가 이상할 때](#-시나리오-5--뭔가-이상할-때)
- [🔧 시나리오 6 — 주기적 유지보수](#-시나리오-6--주기적-유지보수)
- [💾 종료 시 무엇이 보존되나?](#-종료-시-무엇이-보존되나)
- [🚪 종료 방법별 비교](#-종료-방법별-비교)
- [🔗 관련 문서](#-관련-문서)

---

## ⚡ TL;DR — 가장 자주 쓰는 6개 명령

매일 쓰는 거 딱 이만큼:

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

# 켜기
./openclaw start                          # 컨테이너 시작 (이미 떠 있으면 무시)

# 대화 (둘 중 하나)
./openclaw chat                           # 호스트 Ollama 와 즉시 대화 — 가장 빠름
cd ~/DEV/openclaw \
  && docker compose run --rm openclaw-cli tui    # 본체 OpenClaw TUI — 풀 기능

# 끄기
./openclaw stop                           # 컨테이너 정지 (데이터 보존)

# 상태 점검
./openclaw doctor                         # ✓/✗/⚠ 한 화면 진단
```

TUI/chat **안에서** 빠져나오는 법:
- TUI 안에서: `Ctrl+D` 또는 입력창에 `/exit`
- chat REPL 안에서: `/exit`, `/quit`, `/q`, 또는 `Ctrl+D`

---

## 🌅 시나리오 1 — 매일 아침 컴퓨터 켰을 때

```bash
# 1) Docker Desktop 자동 시작 설정이 되어 있으면 1번은 자동
#    아니면 Applications → Docker 더블클릭
open -a Docker
# (30초~1분 대기 — 메뉴바 🐳 아이콘이 안정될 때까지)

# 2) OpenClaw 컨테이너 시작
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw start

# 3) 채팅 시작 (편한 거 선택)
./openclaw chat                                   # 빠른 채팅 (호스트 Ollama 직접)
# 또는
cd ~/DEV/openclaw && docker compose run --rm openclaw-cli tui   # 본체 TUI
```

> 💡 **Docker Desktop 자동 시작**: Docker → Settings → "Start Docker Desktop when you sign in to your computer" 체크. 한 번만 설정하면 매일 1번 단계 생략.
>
> 💡 **컨테이너가 이미 떠 있는 경우**: `./openclaw start` 는 멱등이라 안전. "이미 실행 중" 메시지 후 종료.

---

## ☕ 시나리오 2 — 잠깐 자리 비울 때

| 상황 | 권장 행동 |
|---|---|
| 5분 자리 비움 | 그냥 두기 — TUI/chat 도 떠 있어도 OK |
| 1시간 이상 자리 비움 | TUI/chat 종료 (`Ctrl+D` 또는 `/exit`). 컨테이너는 그대로 |
| 노트북 닫고 외출 (배터리 절약) | TUI/chat 종료 + `./openclaw stop` |

**TUI 종료 후 다시 돌아왔을 때:**
```bash
docker compose run --rm openclaw-cli tui          # 새 세션으로 입장
# 이전 세션 이어가기 (있으면):
docker compose run --rm openclaw-cli sessions list
docker compose run --rm openclaw-cli tui --session <id>
```

---

## 🌙 시나리오 3 — 컴퓨터 끄기 전

```bash
# 1) 진행 중인 TUI/chat 종료
#    - TUI:   Ctrl+D 또는 /exit
#    - chat:  /exit

# 2) (선택) 컨테이너 정지 — 데이터는 그대로 보존됨
./openclaw stop

# 3) macOS 종료
```

**`./openclaw stop` 을 꼭 해야 하나요?**
- **아니요.** macOS 종료/재시작 시 Docker Desktop 이 컨테이너를 안전하게 정리합니다. `docker-compose.yml` 의 `restart: unless-stopped` 정책 때문에 부팅 후 자동 복구됨.
- **그래도 권장하는 경우**: 며칠 안 쓸 예정 / RAM 여유 만들기 / 정리된 상태로 두고 싶을 때.

---

## 💬 시나리오 4 — 이전 대화 이어가기

### `./openclaw chat` (호스트 Ollama 직접) 의 경우
- 매번 **새 세션** 시작. 이전 대화 자동 복원 없음. (워크스페이스의 `IDENTITY.md`/`SOUL.md`/`USER.md` 는 항상 자동 로드 — 그래서 "처음 보는 것 같지 않은" 느낌)
- 대화 도중 컨텍스트 초기화: REPL 안에서 `/reset`
- 영구 기억은 에이전트가 직접 `~/DEV/openclawAgent/MEMORY.md` 에 적도록 시키세요 (예: "이거 기억해줘 → 너의 MEMORY.md 에 기록").

### `docker compose run --rm openclaw-cli tui` (본체 OpenClaw TUI) 의 경우
세션 영구 저장됨 (`~/.openclaw/` 안).

```bash
cd ~/DEV/openclaw

# 저장된 세션 목록
docker compose run --rm openclaw-cli sessions list

# 특정 세션 이어가기
docker compose run --rm openclaw-cli tui --session <session-id>

# 또는 그냥 tui 다시 띄우면 가장 최근 세션 자동 이어가는 경우도 있음 (버전에 따라)
docker compose run --rm openclaw-cli tui
```

---

## 🐛 시나리오 5 — 뭔가 이상할 때

순서대로 시도. 보통 1~2번에서 해결됨.

```bash
# 1) 진단 한 줄
./openclaw doctor
# 모든 ✓ 면 컨테이너 측 문제가 아님 — 마법사/채팅 자체 문제일 수 있음

# 2) 컨테이너 상태
docker compose -f ~/DEV/openclaw/docker-compose.yml ps
# 'Up (healthy)' 가 정상. Exited 면 다음 단계.

# 3) 실시간 로그
./openclaw logs
# 또는:
docker compose -f ~/DEV/openclaw/docker-compose.yml logs --tail 50 openclaw-gateway

# 4) 재시작
./openclaw stop && ./openclaw start

# 5) 그래도 안 되면 — 마지막 자가 치유 + 재설치 (멱등)
./openclaw install
# validate_state 가 산출물 부재를 자동 감지해 필요한 단계만 재실행

# 6) 핵폭탄 — state 초기화 후 install (위험: 모든 컨테이너 다시 만들어짐)
rm ~/.openclaw-mgr/state
./openclaw install
```

자주 발생하는 케이스 빠른 매칭:

| 증상 | 원인 짚어보기 |
|---|---|
| 웹UI "Safari Can't Connect" | [isolated 모드 → online 으로](../README.md#-외부-네트워크-잠깐-켜기) |
| TUI 답이 안 옴: **`fetch failed`** / **`LLM request failed: network connection error`** | 컨테이너→Ollama 네트워크 자체는 OK 인데 **모델 이름이 실제 설치된 이름과 다름** (예: `gemma4` vs `gemma4:26b`). 아래 [현재 어떤 모델을 쓰는지 확인](#-현재-어떤-모델을-쓰는지--openclawjson-점검) 참조 |
| TUI 에서 답이 안 옴 / 느림 (메시지는 가긴 감) | 모델이 너무 크다 — `./openclaw chat` 의 picker 로 가벼운 모델 선택 |
| install 이 [skip] 만 띄움 | [state 파일 vs 실제 산출물 어긋남 FAQ](../README.md) |
| chat 에서 "Ollama not reachable" | Ollama 앱 안 켜진 상태 — `open -a Ollama` |
| Discord 봇 Offline 또는 응답 무 | [GUIDE-DISCORD-BOT 트러블슈팅](GUIDE-DISCORD-BOT.md#-트러블슈팅) (네트워크 OK 인데 응답 없으면 위 모델 이름 케이스도 확인) |

### 🔬 현재 어떤 모델을 쓰는지 — openclaw.json 점검

TUI 가 `fetch failed` 만 띄우고 일반 채팅도 Discord 도 응답 없으면, 거의 100% **에이전트가 설정에 적힌 모델 이름으로 Ollama 를 호출했는데 그 이름이 실제 설치된 모델과 안 맞는** 케이스입니다. OpenClaw 본체가 onboard 중 `OLLAMA_DEFAULT_MODEL = "gemma4"` 같은 **하드코딩된 가짜 기본값**을 모델 목록 맨 앞에 끼워 넣기 때문 (사용자가 실제 깐 건 `gemma4:26b` 같이 태그가 있는 형태).

빠른 진단:

```bash
# 1) 실제 설치된 모델 목록
ollama list

# 2) OpenClaw config 에 등록된 모델 목록
python3 -c '
import json
cfg = json.load(open("/Users/mo/.openclaw/openclaw.json"))
for m in cfg["models"]["providers"]["ollama"]["models"]:
    print(f"  - {m[\"id\"]}")
'

# 둘을 비교 → 1번엔 없는데 2번엔 있는 항목 = 가짜
```

**해결법 세 가지** (선호 순):

**A) `./openclaw setup` 다시 실행 (v0.2.11+)**
```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw setup --skip-confirm
# 마법사 완료 후 자동 후처리: 가짜 모델 항목을 백업 (~/.openclaw/openclaw.json.bak-...) 후 제거
# "설정 정리: openclaw.json 에서 실제 설치되지 않은 모델 항목 제거" 메시지 확인
```

**B) 가짜 이름 그대로 두고 그 모델을 받기**
```bash
# 예: config 에 'gemma4' 가 있고 그게 default 라면, 그 이름으로 진짜 pull
ollama pull gemma4
# 이렇게 하면 'gemma4' = 'gemma4:latest' 가 실제로 설치돼 fetch 가 성공함
```

**C) 수동 편집 (긴급용)**
```bash
# 백업
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 파이썬으로 ollama list 와 안 맞는 항목 제거
python3 - <<'PY'
import json, urllib.request
cfg = json.load(open("/Users/mo/.openclaw/openclaw.json"))
real = {m["name"] for m in json.load(urllib.request.urlopen("http://127.0.0.1:11434/api/tags"))["models"]}
ollama = cfg["models"]["providers"]["ollama"]
ollama["models"] = [m for m in ollama["models"] if m["id"] in real]
json.dump(cfg, open("/Users/mo/.openclaw/openclaw.json", "w"), indent=2)
print("done")
PY
```

세 방법 모두 후 **TUI 재시작 필수** — config 는 컨테이너 기동 시 한 번 읽힘. `Ctrl+D` 또는 `/exit` 로 TUI 빠져나오고 `docker compose run --rm openclaw-cli tui` 다시 시작.

---

## 🔧 시나리오 6 — 주기적 유지보수

| 주기 | 명령 | 무엇을 함 |
|---|---|---|
| 매일 (자동) | (백그라운드) | `restart: unless-stopped` 가 컨테이너 살아있게 유지 |
| 매주 1회 | `./openclaw update` | 코드 pull + 이미지 갱신 + Ollama 모델 갱신. 자동으로 잠깐 online → 끝나면 isolated 복귀 |
| 매월 | `./openclaw clean` | 메모리·디스크 정리 (Docker 캐시·미사용 이미지). 데이터는 절대 안 건드림 |
| 분기 / 큰 변경 전 | `./openclaw backup --name quarterly-YYYYMM` | 볼륨 + `.env` 백업. GPG 암호화 (`BACKUP_ENCRYPT=1` 시) |
| 자동 (선택) | `./openclaw schedule enable` | 매일 새벽 3시 자동 update (launchd 등록) |

**예: 주말 정기 유지보수 한 줄**:
```bash
./openclaw backup --name weekly-$(date +%Y%m%d) \
  && ./openclaw update \
  && ./openclaw clean --status   # 결과 확인만, 실제 정리는 인터랙티브로 별도
```

---

## 💾 종료 시 무엇이 보존되나?

`./openclaw stop` 또는 macOS 종료 후에도 다음은 **모두 디스크에 남습니다**:

| 위치 | 들어있는 것 | 보존? |
|---|---|---|
| `~/DEV/openclawAgent/` | 에이전트 작업 파일 (인격: `IDENTITY.md`/`SOUL.md`/`USER.md`, 일일 메모, MEMORY) | ✓ 항상 |
| `~/.openclaw/` | OpenClaw 설정 (`openclaw.json`), 토큰, 세션, 워크스페이스 마운트 | ✓ 항상 |
| `~/openclaw-backups/` | `./openclaw backup` 으로 만든 스냅샷 (sha256 + 선택적 GPG) | ✓ 항상 |
| Docker 볼륨 (`openclaw_*`) | 컨테이너 내부 캐시·세션 데이터 | ✓ `stop` 으로는 보존. `docker compose down -v` 면 삭제 |
| 호스트 Ollama 모델 (`ollama list`) | 받아둔 LLM 모델 (gemma4, llama3.1 등) | ✓ Ollama 자체 저장소 (`~/.ollama`) |
| `~/DEV/openclaw/` | OpenClaw 본체 클론 (소스 코드) | ✓ 단 수동으로 지우면 다음 install 시 자동 재클론 |
| `~/.openclaw-mgr/state` | install 단계 마커 | ✓ 산출물과 어긋나면 `validate_state` 가 자동 보정 |

**유실되는 것:**
- `./openclaw chat` REPL 의 대화 히스토리 (임시 파일에만 — 종료 시 자동 삭제)
- TUI 의 "현재 입력 중이던" 메시지 (전송 안 한 것)

---

## 🚪 종료 방법별 비교

| 명령 | 무엇을 끔 | 무엇을 보존 | 다시 시작 명령 |
|---|---|---|---|
| TUI 안에서 `Ctrl+D` 또는 `/exit` | 현재 TUI 세션만 | 컨테이너·세션 기록·설정 모두 | `docker compose run --rm openclaw-cli tui` |
| chat 안에서 `/exit` | 현재 chat REPL | (chat 은 영구 저장 안 함) | `./openclaw chat` |
| `./openclaw stop` | 모든 OpenClaw 컨테이너 | 볼륨·설정·세션·이미지 모두 | `./openclaw start` |
| `docker compose down` (수동, `~/DEV/openclaw` 에서) | 컨테이너 + 네트워크 | 볼륨·이미지 보존 | `./openclaw start` |
| `docker compose down -v` (수동, 위험) | 컨테이너 + 네트워크 + **볼륨** | 이미지·설정 (`~/.openclaw`)·코드만 보존, 컨테이너 내부 캐시 삭제 | `./openclaw install` (재초기화) |
| `./openclaw uninstall` | 모든 컨테이너 + 이미지 + 클론 | 백업·`.openclaw` 설정만 | `./openclaw install` 처음부터 |
| `./openclaw uninstall --purge` | 위 + Docker/Ollama 까지 | 백업만 | 완전 재설치 |

**일상에 권장:** `./openclaw stop` (가장 안전, 가장 빠른 재시작) 또는 그냥 macOS 종료 (대부분 동일하게 동작).

---

## 🔗 관련 문서

| 문서 | 무엇이 있나 |
|---|---|
| [▶ 설치 후 첫 사용 가이드](GUIDE-FIRST-USE.md) | 이 가이드의 **앞 단계** — install 직후 5분 안에 첫 대화까지 |
| [💬 Discord 봇 운영](GUIDE-DISCORD-BOT.md) | 봇으로 운영할 때의 일상 사이클·트러블슈팅 |
| [🌐 웹에서 정보 가져오기](GUIDE-WEB-FETCH.md) | 일상에 `surf` 명령으로 뉴스·코스피 가져오는 패턴 |
| [🚑 트러블슈팅](TROUBLESHOOTING.md) | 시나리오 5 더 자세한 진단 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·세션·메모리 |
| [README — 명령 카탈로그](../README.md#-명령-카탈로그) | 전체 명령 사전 |
| [README — 멱등 설계](../README.md#-개발자용) | `state` 파일·`validate_state` 동작 원리 |
| [README — 외부 네트워크 토글](../README.md#-외부-네트워크-잠깐-켜기) | online ↔ isolated 사이클 |

---

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)
