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
- [🆕 시나리오 0 — 컴퓨터 완전히 껐다 켰을 때 (cold boot)](#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot)
- [🌅 시나리오 1 — 일상 시작 (Mac 슬립 해제 / 터미널 새로 열기)](#-시나리오-1--일상-시작-mac-슬립-해제--터미널-새로-열기)
- [☕ 시나리오 2 — 잠깐 자리 비울 때](#-시나리오-2--잠깐-자리-비울-때)
- [🌙 시나리오 3 — 컴퓨터 끄기 전 (full shutdown)](#-시나리오-3--컴퓨터-끄기-전-full-shutdown)
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

### 💬 Discord 에서 자주 쓰는 프롬프트 (병렬 cheat sheet)

호스트 터미널 대신 **Discord 로** OpenClaw 봇을 부를 때 가장 자주 보내는 메시지. 봇 이름은 예시 (`@OpenClaw-Mo`) — 당신이 [GUIDE-DISCORD-BOT](GUIDE-DISCORD-BOT.md) 에서 설정한 이름으로 바꿔서 사용.

```
# ① 봇 살아있는지 확인 (cold boot 직후 / 모바일에서 점검)
@OpenClaw-Mo 살아있어?

# ② 빠른 질문 (채널)
@OpenClaw-Mo rsync 권한 유지 옵션이 뭐였지?

# ③ 1:1 대화 (DM) — 매번 멘션 불필요, 평문 입력
[봇과 DM 채널 열고]  안녕. 너는 어떤 모델이야?

# ④ 워크스페이스 파일 작업 (모바일에서도 가능)
@OpenClaw-Mo ~/DEV/openclawAgent/daily-notes/2026-05-14.md 만들어서
오늘 회의 핵심 3줄 적어줘:
- A 안건 연기
- B 내일 초안
- C 검토 완료

# ⑤ 컨텍스트 초기화 (인격은 유지, 대화 히스토리만 삭제)
/reset                또는    @OpenClaw-Mo /reset

# ⑥ 모델 즉시 전환 (admin)
/agent model gemma4:26b
```

**핵심 트리거 4종 한 줄 요약:**

| 트리거 | 언제 | 컨텍스트 |
|---|---|---|
| `@봇이름 <메시지>` | 채널에서 가끔 부를 때 | 메시지마다 새로 |
| DM 평문 | 1:1, 모바일, 비밀 작업 | 가장 길게 유지 |
| `/명령` (슬래시) | 매개변수 많은 작업 | 필드별 분리 → 오타 없음 |
| 자동응답 채널 | 봇 전용 채널 (`#ai-chat` 등) | 멘션 없이 모든 메시지 |

자세한 8개 상황별 워크플로우 (모바일·팀·파일·운영·긴 작업·정기·cold boot) + 9구간 시간순 통합 시나리오 → [GUIDE-DISCORD-BOT §12](GUIDE-DISCORD-BOT.md#12--상황별-discord-워크플로우--모든-상황에서).

---

**컴퓨터 완전히 껐다 켠 직후라면** → 곧장 [🆕 시나리오 0 (cold boot)](#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 로. 5단계 + 1분 검증 체크리스트.

**Discord 를 주 인터페이스로 쓰고 싶으면** (모바일·팀 협업·외출·정기 알림·시스템 운영 등 8개 상황) → [GUIDE-DISCORD-BOT §12 — 상황별 워크플로우](GUIDE-DISCORD-BOT.md#12--상황별-discord-워크플로우--모든-상황에서) (특히 [⓪ 통합 시나리오](GUIDE-DISCORD-BOT.md#-통합-시나리오--노트북-끔-상태에서-discord-만으로-하루-보내기) 부터).

---

## 🆕 시나리오 0 — 컴퓨터 완전히 껐다 켰을 때 (cold boot)

전원이 완전히 꺼졌다가 켜진 직후. 아무것도 떠 있지 않은 가장 보수적인 상태에서 채팅 가능 상태까지 가는 전체 경로.

### 자동으로 일어나는 일 vs 사용자가 할 일

| 구성요소 | 자동? | 비고 |
|---|---|---|
| Docker Desktop | ⚙️ 자동 (설정한 경우) / 수동 | "Start Docker Desktop when you sign in" 체크 권장 |
| Ollama (메뉴바) | ✓ 자동 | macOS Ollama 앱이 알아서 메뉴바에 뜸 |
| 호스트 LLM 모델 (`ollama list`) | ✓ 보존 | 다시 받을 필요 없음 |
| OpenClaw 컨테이너 (`gateway`/`cli`) | ⚙️ Docker 가 뜨면 **자동 복구** | compose 의 `restart: unless-stopped` 정책 |
| 네트워크 모드 (`isolated` / `online`) | ✓ 보존 | `~/.openclaw-mgr/network-mode` 에 마지막 값 저장 |
| OpenClaw 설정 (`~/.openclaw/openclaw.json`) | ✓ 보존 | 모델·인증·Discord 토큰 등 그대로 |
| 워크스페이스 (`~/DEV/openclawAgent/`) | ✓ 보존 | IDENTITY/SOUL/USER/MEMORY 그대로 |
| Discord 봇 | ⚙️ 컨테이너 뜨면 자동 재연결 | gateway healthy 후 30~60초 안에 Online |
| 웹 UI (`127.0.0.1:18789`) | ⚙️ **isolated 면 차단** | online 이어야 접근 가능 — Docker 의 port publishing 동작 [GUIDE-DAILY-USE 종료 시 보존](#-종료-시-무엇이-보존되나) 참조 |
| chat REPL / TUI 세션 | ✗ 매번 새로 | 프로세스라 종료 후 재실행 필요 |

→ **이상적 시나리오**: Docker 자동 시작 + 마지막 모드가 `online` 이었다면, 부팅 후 1~2분 안에 모든 게 그냥 떠 있음. 사용자는 `./openclaw chat` 또는 브라우저만 열면 됨.

### 단계별 절차 (보수적 — 매 단계 검증)

**1단계 — Docker 데몬 띄우기 (30초 ~ 1분)**

```bash
# Docker Desktop 자동 시작이 설정돼 있으면 이미 떠 있을 것 — 메뉴바 🐳 아이콘 확인
# 안 보이면 수동으로:
open -a Docker

# 데몬 응답 대기 (보통 30~60초)
until docker info >/dev/null 2>&1; do printf '.'; sleep 2; done; echo " Docker ready"
```

> 첫 부팅 후 1분이 지나도 🐳 아이콘이 회전 중이면 Docker Desktop 자체가 업데이트 / 설정 다이얼로그 띄우는 중일 수 있음. 메뉴바 아이콘 클릭해서 상태 확인.

**2단계 — Ollama 확인 (보통 자동, 5초)**

```bash
# 메뉴바에 🦙 아이콘이 보이면 OK. 아니면:
open -a Ollama

# API 응답 확인
curl -sf --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null && echo "Ollama ready" || echo "Ollama DOWN"
```

> 모델은 **요청 시점에 RAM 로드**됩니다 — 부팅 직후엔 모델이 RAM 에 없을 수 있어요. 첫 메시지 응답이 5~15초 걸려도 정상 (이후 빨라짐).

**3단계 — OpenClaw 컨테이너 자동 복구 확인 (보통 자동, 10~30초)**

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw doctor

# 빨리 보고 싶으면:
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep openclaw
# openclaw-openclaw-gateway-1   Up 1 minute (healthy)   127.0.0.1:18789-18790->18789-18790/tcp
```

`Up (healthy)` 가 보이면 OK. **`Up (unhealthy)` 또는 컨테이너 자체가 안 보이면:**
```bash
./openclaw start    # 멱등 — 이미 떠 있어도 안전
```

**4단계 — 네트워크 모드 확인**

```bash
./openclaw network status
# 현재 네트워크 모드: isolated  ← 마지막 종료 시 그 상태
```

- **`online`** → 웹 UI 도 접근 가능, Discord 도 응답
- **`isolated`** → 웹 UI 차단, host Ollama 도 컨테이너→호스트 차단 (다만 `./openclaw chat` 은 호스트 직접 호출이라 OK)

웹 UI 가 필요하면 잠깐 켜기:
```bash
./openclaw network online --restart
```

**5단계 — 채팅 시작**

```bash
# 가장 빠름 — 호스트 Ollama 직접, 인격 자동 로드
./openclaw chat

# 본체 OpenClaw TUI — 풀 기능 (세션 영구 저장)
cd ~/DEV/openclaw && docker compose run --rm openclaw-cli tui

# 웹 UI (online 모드일 때만)
open http://127.0.0.1:18789

# Discord 봇 — 자동으로 다시 Online (gateway 가 healthy 면 30~60초 안에)
```

> 💡 **Discord 만으로 종일 작업할 거면** → 시나리오 0 마치고 곧장 [GUIDE-DISCORD-BOT ⓪ 통합 시나리오](GUIDE-DISCORD-BOT.md#-통합-시나리오--노트북-끔-상태에서-discord-만으로-하루-보내기) 로. 09:00 부팅 → 09:01 Discord 봇 확인 → 09:15 모바일 → 11:00 팀 협업 → 14:30 파일 작업 → 16:00 긴 작업 → 18:00 운영 점검 → 22:00 종료 까지 시간순.

### ✅ 1분 부팅 검증 체크리스트

전부 통과하면 끝. 하나라도 X 면 그 단계로 돌아가 진단.

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

docker info >/dev/null 2>&1 && echo "✓ Docker"   || echo "✗ Docker — open -a Docker"
curl -sf --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null && echo "✓ Ollama" || echo "✗ Ollama — open -a Ollama"
docker ps --format '{{.Names}}' | grep -q openclaw-openclaw-gateway && echo "✓ Gateway 컨테이너" || echo "✗ Gateway — ./openclaw start"
./openclaw doctor 2>&1 | grep -q "모두 정상" && echo "✓ Doctor: 모두 정상" || echo "⚠ Doctor: 항목 확인 필요"
```

한 줄로:
```bash
docker info >/dev/null 2>&1 && curl -sf http://127.0.0.1:11434/api/tags >/dev/null && docker ps | grep -q openclaw && echo "✅ ALL OK — ready to chat" || echo "⚠ 단계별 점검 필요"
```

### 자주 막히는 cold-boot 케이스

| 증상 | 짚어볼 곳 |
|---|---|
| Docker 가 1분 넘게 안 뜸 | macOS 업데이트 직후라 Docker 가 업데이트 중. 메뉴바 아이콘 확인 |
| 컨테이너가 Exited 상태 | 마지막 종료가 비정상. `./openclaw start` |
| `./openclaw chat` 이 `Ollama not reachable` | Ollama 앱이 아직 안 뜸. `open -a Ollama` 후 5초 |
| 웹 UI "Safari Can't Connect" | 마지막 상태가 isolated. `./openclaw network online --restart` |
| Discord 봇 Offline 인 채로 | gateway 가 아직 안정화 중. 1~2분 더 기다리거나 `./openclaw logs \| grep -i discord` 로 재연결 시도 확인 |
| TUI 가 `fetch failed` | 모델 이름 미스매치 (드물게 cold-boot 후 발생) → [§ 현재 어떤 모델을 쓰는지](#-현재-어떤-모델을-쓰는지--openclawjson-점검) |

---

## 🌅 시나리오 1 — 일상 시작 (Mac 슬립 해제 / 터미널 새로 열기)

전원을 끄지 않았고 (슬립이거나 그냥 자리만 비웠던) Docker·Ollama·컨테이너가 다 살아있는 상태에서 다시 작업 시작. **이게 가장 흔한 케이스** — cold boot 보다 훨씬 빠름.

```bash
# 곧장 채팅 시작
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw chat                                   # 호스트 Ollama 직접 (가장 빠름)

# 또는 본체 TUI
cd ~/DEV/openclaw && docker compose run --rm openclaw-cli tui

# 또는 웹 UI (online 모드 + 컨테이너 healthy 면)
open http://127.0.0.1:18789
```

이상하면 한 줄 진단:
```bash
./openclaw doctor
```

> 💡 **Docker Desktop 자동 시작 추천**: Docker → Settings → "Start Docker Desktop when you sign in to your computer" 체크. cold boot 마다 매뉴얼 실행 안 해도 됨.
>
> 💡 **컨테이너가 이미 떠 있는 경우**: `./openclaw start` 는 멱등이라 매번 호출해도 안전. "이미 실행 중" 메시지 후 즉시 종료.

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

## 🌙 시나리오 3 — 컴퓨터 끄기 전 (full shutdown)

전원을 완전히 끌 때 (밤에 가방 넣기, 출장 전 등). [시나리오 0 (cold boot)](#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 의 역방향.

### 권장 종료 순서 (느슨 → 강함)

**Level 1 — 그냥 macOS 종료 (가장 흔함)**
```bash
# 진행 중인 TUI/chat 종료
#   - TUI:   Ctrl+D 또는 /exit
#   - chat:  /exit
# → macOS 종료 (Cmd+Q 로 Docker 빠져나오기는 불필요)
```
- macOS 가 모든 앱·컨테이너 안전 종료
- Docker 의 `restart: unless-stopped` 정책 덕에 다음 부팅 시 자동 복구
- **이걸로 충분합니다.** 90% 케이스에 권장.

**Level 2 — 컨테이너 명시 정지 (며칠 안 쓸 때)**
```bash
# 1) TUI/chat 종료
# 2) 컨테이너만 깨끗이 정지 (데이터·이미지 보존)
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw stop
# 3) macOS 종료
```
- 다음 부팅 시 컨테이너가 "Stopped" 상태로 시작 — `./openclaw start` 한 번 필요
- 메모리·CPU 자원 확실히 회수

**Level 3 — Docker Desktop 까지 끄기 (장기 미사용·RAM 절약)**
```bash
# 1) TUI/chat 종료
./openclaw stop                                    # 컨테이너 정지
osascript -e 'quit app "Docker"'                   # Docker Desktop 까지 종료
# 2) macOS 종료
```
- Docker Desktop 의 Linux VM 까지 종료 → RAM ~2 GB 해방
- 다음 부팅 시 [시나리오 0](#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 1~2단계부터 다시

### 종료 전 권장 체크 (선택)

```bash
# 1) Discord 봇이 메시지 처리 중인가? — 진행 중이면 잠깐 기다리기
./openclaw logs | tail -10

# 2) 현재 네트워크 모드 확인 — 부팅 후 그대로 복구됨
./openclaw network status
# isolated 면 다음 부팅 시 웹UI 막혀 있을 거라는 점만 기억

# 3) 최근 작업물 백업 (큰 변경이 있었다면)
./openclaw backup --name pre-shutdown-$(date +%Y%m%d)
```

### `./openclaw stop` 을 꼭 해야 하나요?
- **아니요.** macOS 종료/재시작 시 Docker Desktop 이 컨테이너를 안전하게 정리합니다. `docker-compose.yml` 의 `restart: unless-stopped` 정책 때문에 부팅 후 자동 복구됨.
- **그래도 권장하는 경우**: 며칠 안 쓸 예정 / RAM 여유 만들기 / Discord 봇을 꺼둔 채로 두고 싶을 때 / 정리된 상태로 두고 싶을 때.

### 다음 부팅 시
→ [시나리오 0 (cold boot)](#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 의 단계별 절차 + ✅ 1분 검증 체크리스트.

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
| Discord 봇 응답: **`Something went wrong while processing your request. Please try again, or use /new to start a fresh session.`** (게이트웨이 로그에서 `Failed to inspect sandbox image: dial unix /var/run/docker.sock: no such file or directory`) | `./openclaw stop && start` 또는 `network` 토글 후 **gateway 컨테이너에 `/var/run/docker.sock` 마운트가 빠진 상태**. 봇이 도구 실행할 때 sandbox 컨테이너 못 띄움. v0.2.17+ 에서 `start.sh` / `step_lockdown` 이 자동으로 `docker-compose.sandbox.yml` 오버레이를 포함하도록 패치됨 — `git pull && ./openclaw stop && ./openclaw start` 한 번이면 해결. 확인: `docker inspect openclaw-openclaw-gateway-1 --format '{{range .Mounts}}{{.Source}} {{end}}' \| grep docker.sock` |
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
| [💬 Discord 봇 운영](GUIDE-DISCORD-BOT.md) | 봇으로 운영할 때의 일상 사이클·트러블슈팅. **§7–§11 일상 사용법** (트리거 4종 · 자주 쓰는 프롬프트 · 채널별 모델/인격 · cheat sheet) |
| [🌐 웹에서 정보 가져오기](GUIDE-WEB-FETCH.md) | 일상에 `surf` 명령으로 뉴스·코스피 가져오는 패턴 |
| [🚑 트러블슈팅](TROUBLESHOOTING.md) | 시나리오 5 더 자세한 진단 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·세션·메모리 |
| [README — 명령 카탈로그](../README.md#-명령-카탈로그) | 전체 명령 사전 |
| [README — 멱등 설계](../README.md#-개발자용) | `state` 파일·`validate_state` 동작 원리 |
| [README — 외부 네트워크 토글](../README.md#-외부-네트워크-잠깐-켜기) | online ↔ isolated 사이클 |

---

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)
