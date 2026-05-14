# 💬 Discord 봇 연동 가이드 / Discord Bot Integration Guide

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)

> **한 줄 요약 / TL;DR.** OpenClaw 에이전트를 Discord 봇으로 띄워서 디스코드 채널에서 직접 대화·자동화 시키는 가이드. **봇 토큰 1개**만 등록하면 OpenClaw 가 Discord Gateway 에 붙어서 메시지를 듣고 답합니다. 첫 설정 5분, 이후 영구.

<table>
<tr><td><b>누구에게 좋은가요?</b></td><td>• Discord 친구·팀 채널에서 AI 비서를 부르고 싶은 사람<br>• 슬래시 명령으로 OpenClaw 워크플로우 (예: "<code>/summarize</code>")를 트리거하고 싶은 사람<br>• 팀 채널에 자동 요약 봇, 이슈 알림 봇을 두고 싶은 사람</td></tr>
<tr><td><b>무엇이 필요한가요?</b></td><td>• Discord 계정 + 봇을 초대할 서버에서 <b>관리자 권한</b> (또는 봇 초대 권한)<br>• OpenClaw 설치 + 1회 onboard 완료 (<code>./openclaw setup</code>)<br>• 컨테이너에서 Discord 로 나가야 하므로 잠시 또는 영구 <b><code>./openclaw network online --restart</code></b></td></tr>
<tr><td><b>조심할 점은?</b></td><td>• 봇 토큰 = 봇 계정 전체 권한. <b>절대 공개 저장소·스크린샷·로그에 노출 금지</b><br>• 노출 의심 시 Discord Developer Portal 에서 즉시 <b>Reset Token</b> 후 OpenClaw 재설정<br>• <b>Message Content Intent</b> 활성화 안 하면 봇이 본문을 읽지 못해 답을 못 함 (가장 흔한 첫 실수)</td></tr>
</table>

---

## 📖 목차 / Contents

- [0. 시작 전 사전 확인](#0-시작-전-사전-확인)
- [1. Discord 앱 + 봇 만들기](#1-discord-앱--봇-만들기)
- [2. Bot Token 발급 + 안전 보관](#2-bot-token-발급--안전-보관)
- [3. Privileged Gateway Intents 활성화](#3-privileged-gateway-intents-활성화-가장-흔한-함정)
- [4. OAuth2 URL Generator 로 서버에 초대](#4-oauth2-url-generator-로-서버에-초대)
- [5. OpenClaw 에 토큰 등록](#5-openclaw-에-토큰-등록)
- [6. 첫 테스트](#6-첫-테스트)
- [7. 봇과 대화하는 4가지 방법](#7-봇과-대화하는-4가지-방법)
- [8. 자주 쓰는 프롬프트 패턴](#8-자주-쓰는-프롬프트-패턴)
- [9. 채널·서버별 동작 조정](#9-채널·서버별-동작-조정)
- [10. 워크스페이스·인격을 봇으로 끌어오기](#10-워크스페이스인격을-봇으로-끌어오기)
- [11. 봇 행동 관리 (mute · disable · 다중 서버)](#11-봇-행동-관리-mute--disable--다중-서버)
- [12. 🎬 상황별 Discord 워크플로우 — 모든 상황에서](#12--상황별-discord-워크플로우--모든-상황에서)
  - [⓪ 통합 시나리오 — 노트북 끔 → Discord 만으로 하루 → 다시 끔](#-통합-시나리오--노트북-끔-상태에서-discord-만으로-하루-보내기)
  - [① 노트북 옆 — 빠른 질문](#-노트북-옆에-있을-때--빠른-질문)
  - [② 외출 / 모바일](#-외출-중--모바일에서만-접근-가능)
  - [③ 팀 채널 협업](#-팀-채널-협업)
  - [④ 워크스페이스 파일 작업](#-워크스페이스-파일-작업-읽기수정정리)
  - [⑤ 시스템 운영 / DevOps](#-시스템-상태-점검--운영-devops)
  - [⑥ 긴 작업 + 알림](#-긴-작업-트리거--알림-받기)
  - [⑦ 정기 작업·리마인더](#-정기-작업--리마인더)
  - [⑧ Cold boot 직후 응급](#-cold-boot--노트북-비정상-종료-직후)
- [🎯 명령·인터랙션 cheat sheet](#-명령인터랙션-cheat-sheet)
- [🔒 보안 주의](#-보안-주의-꼭-읽으세요)
- [🛠 트러블슈팅](#-트러블슈팅)
- [🔗 관련 문서](#-관련-문서)

---

## 0. 시작 전 사전 확인

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

# 1) OpenClaw 본체 설치 + 1회 onboard 완료 상태인지
./openclaw doctor
./openclaw setup status      # ~/.openclaw/openclaw.json 의 키 목록 표시

# 2) Discord Gateway 로 나가야 하니 네트워크를 online 으로 (필요 시)
./openclaw network online --restart
```

> Discord 봇은 **outbound 연결**(컨테이너 → `gateway.discord.gg`)을 필요로 합니다. `isolated` 모드는 이 outbound 를 차단하므로 봇 사용 중에는 `online` 으로 유지해야 합니다. 평소 보안을 위해 봇 안 쓸 때는 다시 `isolated` 로.

---

## 1. Discord 앱 + 봇 만들기

1. https://discord.com/developers/applications 접속 → 우상단 **"New Application"** 클릭
2. 앱 이름 입력 (예: `OpenClaw-Mo`) → "Create"
3. 좌측 메뉴 **"Bot"** 클릭 (또는 "Add Bot" 버튼이 있으면 누름)

이 시점에 봇 계정이 만들어집니다. 이름·아바타·설명은 나중에 언제든 수정 가능.

---

## 2. Bot Token 발급 + 안전 보관

같은 **Bot** 탭 안에서:

1. **"Reset Token"** 클릭 (또는 "Copy" — 새 앱이면 토큰 즉시 표시)
2. 토큰이 한 번만 표시됩니다 → **임시로 클립보드 + 안전한 메모장에 복사**

```
MTAxXXXXXXXXXXXXXXXXXX.GxXXXXXXXXXXXXXXXXXXXXX
```

> ⚠️ **이 문자열이 외부에 노출되면 누구나 당신의 봇 계정으로 메시지 전송·서버 조회 가능.**
> - GitHub·Gist·스크린샷·공개 채널에 절대 붙여넣지 마세요
> - 의심되면 같은 페이지에서 **Reset Token** → 즉시 무효화 → 새로 발급
> - `.env` 같은 파일에 평문 저장도 비추 — OpenClaw 의 secret provider 사용 권장 (§5)

---

## 3. Privileged Gateway Intents 활성화 (가장 흔한 함정)

같은 **Bot** 탭에서 아래로 스크롤:

**Privileged Gateway Intents** 섹션에서 다음을 **반드시** 켜세요:

| Intent | 켜야 하는가? | 이유 |
|---|---|---|
| **MESSAGE CONTENT INTENT** | ✅ **필수** | 봇이 채널 메시지의 본문을 읽을 수 있게 함. 안 켜면 멘션·DM 외에는 봇이 "빈 메시지" 만 받음 |
| **SERVER MEMBERS INTENT** | 선택 | 멤버 입/퇴장 이벤트를 받고 싶을 때 |
| **PRESENCE INTENT** | 선택 | 멤버 온라인 상태를 추적할 때 |

각 토글 우측 **"Save Changes"** 클릭 잊지 마세요.

> 🪤 **가장 흔한 첫 실수**: 토큰 등록까지 마쳤는데 봇이 채널 메시지에 반응 안 함 → 거의 100% **Message Content Intent 가 꺼져 있는** 상태. 이 페이지 다시 와서 켜고 봇 재시작.
>
> 100명 이상 서버에서 봇을 운영하려면 Discord 의 추가 검증(verification) 필요. 친구·팀 서버(100명 미만) 에서는 그냥 켜면 됨.

---

## 4. OAuth2 URL Generator 로 서버에 초대

좌측 메뉴 **OAuth2 → URL Generator** 클릭:

### Scopes (필수)

- ✅ **`bot`** — 봇으로 서버에 합류
- (선택) ✅ **`applications.commands`** — 슬래시 명령(`/명령어`)을 등록·사용할 때

### Bot Permissions (최소 권장)

| 권한 | 이유 |
|---|---|
| **View Channels** | 채널 보기 (필수) |
| **Send Messages** | 답글 보내기 (필수) |
| **Read Message History** | 과거 메시지 컨텍스트 읽기 |
| **Embed Links** | 마크다운 카드형 출력 |
| **Attach Files** | 이미지·파일 첨부 답변 |
| Manage Webhooks | 외부 → 채널 알림 자동화할 때 |
| Use Slash Commands | 슬래시 명령 호출 |

> ⚠️ **`Administrator` 권한은 주지 마세요.** 봇이 토큰 노출 등으로 공격당하면 서버 전체가 위험. 최소 권한 원칙.

### 초대

페이지 하단에 자동 생성된 URL 을 새 탭에서 열기 →
1. 봇을 추가할 **서버 선택** (관리자 권한 있는 서버만 표시)
2. **"Authorize"** → 캡차 확인 → 완료

서버의 멤버 목록에 봇이 (Offline 상태로) 추가됩니다. OpenClaw 가 연결되는 §5 단계 이후에 Online 으로 바뀝니다.

---

## 5. OpenClaw 에 토큰 등록

`./openclaw setup` 마법사를 다시 실행. 멱등이므로 이미 한 답변은 그대로 두고 Discord 단계까지 Enter 연타로 도달.

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw setup
```

Discord 단계에서 마법사가 다음과 같이 묻습니다:

```
3) OAuth2 -> URL Generator -> scope 'bot' -> invite to your server
   Tip: enable Message Content Intent if you need message text.
   (Bot -> Privileged Gateway Intents -> Message Content Intent)
   Docs: discord

? How do you want to provide this Discord bot token?
  ● Enter Discord bot token (Stores the credential directly in OpenClaw config)
  ○ Use external secret provider
```

선택 가이드:

| 선택 | 언제 |
|---|---|
| **Enter Discord bot token** (권장 시작) | 토큰을 그대로 `~/.openclaw/openclaw.json` 에 저장. 빠르고 간단. 개인용. |
| **Use external secret provider** | 1Password·Vault·AWS Secrets Manager 등 외부 secret store 에 보관하고 OpenClaw 가 런타임에 가져옴. 팀·프로덕션 환경. |

**"Enter Discord bot token"** 선택 후 §2 에서 복사해둔 토큰 붙여넣기 (입력은 가려져서 안 보입니다 — 정상). Enter.

이후 마법사가:
- 응답 트리거 (예: 멘션, DM, 특정 prefix)
- 기본 모델 (앞서 8번 단계의 `ollama` 모델 그대로 또는 변경)
- 채널 화이트리스트 (선택)
등을 묻고 끝.

---

## 6. 첫 테스트

마법사 완료 후 OpenClaw 가 자동으로 Discord Gateway 에 연결을 시도합니다.

```bash
# 게이트웨이 로그에서 Discord 채널 등록 확인
./openclaw logs | grep -i discord

# 또는 본체 헬스
./openclaw doctor
```

서버에서 봇 멤버 옆에 초록 점(Online) 이 뜨면 OK.

**첫 메시지 테스트:**

서버의 아무 채널에서:
```
@OpenClaw-Mo 안녕!
```

또는 봇과 DM 열어서:
```
안녕. 너는 어떤 모델이야?
```

응답이 오면 끝. 안 오면 → [트러블슈팅](#-트러블슈팅).

**슬래시 명령 (선택):** `applications.commands` scope 도 부여했다면 채널 입력창에서 `/` 입력 시 봇의 명령이 자동 완성으로 뜹니다. OpenClaw 가 정의한 명령(예: `/agent ask`)을 클릭해서 사용.

---

## 7. 봇과 대화하는 4가지 방법

봇이 메시지에 "반응할지/안 할지" 는 **트리거** 가 결정합니다. Discord 봇 표준 + OpenClaw 가 더한 옵션:

### A. @멘션 (가장 흔함)

서버 채널에서:
```
@OpenClaw-Mo 오늘 회의록 3줄 요약해줘
```
- 봇이 자기 mention 을 받으면 즉시 그 메시지를 처리. 채널 안 다른 잡담엔 반응 안 함.
- 채널의 다른 사람과 대화 흐름을 안 깨려면 **답글(Reply)** 로 멘션하는 게 깔끔.
- 봇이 답할 때 자동으로 원 메시지를 reply 로 묶는 동작은 OpenClaw 설정에 따라 다름 — `~/.openclaw/openclaw.json` 의 `channels.discord.reply` 옵션.

### B. DM (1:1 — 가장 사적인 채널)

봇 프로필 클릭 → **Message** → 평문 입력. 매번 멘션 안 해도 모든 메시지에 응답.
- 채널 권한·서버 정책 무관 — Discord 가 직접 라우팅.
- 컨텍스트도 가장 길게 유지 (DM 별 세션 자동 생성).
- 비밀 작업, 토큰 입력, 개인 메모 작업 같은 거 권장 위치.

> 봇이 DM 을 보내지/받지 못하면? 서버 Privacy Settings → "Allow direct messages from server members" 가 켜져 있어야 함. 봇 자체에 별도 DM 권한 설정은 없음 (Discord 가 사용자 단위 설정).

### C. 슬래시 명령 (`/`)

OAuth scope 에 `applications.commands` 가 있으면 채널 입력창에서 `/` 만 누르면 자동완성:

```
/agent ask        질문: <텍스트>
/agent summarize  대상: <메시지 또는 URL>
/agent reset      현재 세션 컨텍스트 초기화
/agent model      모델 전환 (admin 만)
```
- 실제 명령 목록은 OpenClaw 버전·활성화한 플러그인에 따라 다름. `/` + 봇 이름 검색해서 봐주세요.
- 슬래시 명령은 **각 매개변수가 별도 입력 필드** 로 분리돼 오타·따옴표 실수 없음. 긴 텍스트는 멘션·DM 이 편함.
- 첫 등록은 봇이 서버에 합류한 직후 ~10분 안에 자동. 자동완성에 안 뜨면 [트러블슈팅](#-트러블슈팅) 참조.

### D. 채널 화이트리스트 (자동 응답)

특정 채널을 봇 전용으로 지정해서 **멘션 없이도 모든 메시지에 응답**.

```bash
# OpenClaw 설정에서 채널 ID 등록 (서버에서 채널 우클릭 → "Copy Channel ID")
# 마법사로:
./openclaw setup        # Discord 단계에서 'auto-respond channels' 항목

# 또는 직접 편집:
~/.openclaw/openclaw.json  →  channels.discord.autoChannels: ["123456789012345678"]
```
- 봇 전용 채널 (예: `#ai-chat`, `#bot-lab`) 운영에 편함.
- 다른 멤버도 자유롭게 봇과 대화 가능 → 봇 부하·메시지량 주의.

---

## 8. 자주 쓰는 프롬프트 패턴

OpenClaw 가 IDENTITY/SOUL/USER/AGENTS/MEMORY 를 system prompt 로 자동 로드하니, Discord 에서도 같은 인격 그대로 호출됩니다. 자주 쓰는 형태:

### 한 줄 질문
```
@bot 오늘 코스피 종가 어디서 확인하지?
```

### 회의록·긴 텍스트 요약 (스레드 추천)
```
@bot 아래 텍스트 핵심 3줄 + 액션 아이템만 뽑아줘
[긴 텍스트 붙여넣기]
```
> Discord 메시지 길이 제한: 2,000자. 더 길면 봇이 자동으로 잘라서 받음 (또는 스레드/파일 첨부 권장).

### 코드 리뷰
```
@bot 이 diff 잠재적 버그·성능 이슈 짚어줘
```
````
```diff
+ 코드 ...
- 코드 ...
```
````

### 워크플로우 트리거 (도구 결합)
```
@bot ~/DEV/openclawAgent/MEMORY.md 안에서 "디스코드" 키워드 찾아서 정리해줘
```
- 봇이 컨테이너 안 워크스페이스(`/home/node/.openclaw/workspace`, 호스트 `~/DEV/openclawAgent`) 에 접근 가능 — 파일을 그대로 읽음.
- 호스트 임의 경로(`~/Documents` 등) 는 안 닿음 (격리 의도).

### 한 컨텍스트로 연속 대화 (스레드)

채널에서 메시지에 마우스 오버 → **"Create Thread"** → 봇과 스레드 안에서 계속 대화.
- 봇이 스레드를 별도 세션으로 인식 → 다른 멤버 잡담과 분리.
- 메인 채널 흐름을 안 깨면서 길게 대화 가능.

### 컨텍스트 초기화

```
@bot /reset             또는    /agent reset
```
- 현재 세션의 대화 히스토리만 삭제, 인격(IDENTITY 등) 은 유지.
- DM 에서도 동일.

### 모델 즉시 전환 (admin)
```
/agent model gemma4:26b
/agent model llama3.1:8b-instruct-q4_K_M
```
- 무거운 모델이 너무 느리면 가벼운 걸로, 한국어 약하면 EXAONE/Solar 로.
- 채널마다 다른 모델을 두는 건 §9 참조.

---

## 9. 채널·서버별 동작 조정

대규모 서버, 또는 봇을 여러 용도로 쓰면 채널·서버마다 다르게 동작하도록 설정 가능. 핵심 매개변수:

| 항목 | 어디서 | 효과 |
|---|---|---|
| **자동 응답 채널** | `channels.discord.autoChannels` | 멘션 없이도 모든 메시지에 응답 (§7 D) |
| **금지 채널** | `channels.discord.muteChannels` | 멘션돼도 무시 (예: `#admin-only`) |
| **채널별 모델** | `channels.discord.channelModels` | `#general` 은 `gemma4:26b`, `#code` 는 `qwen2.5-coder:7b` 처럼 분리 |
| **채널별 인격** | `channels.discord.channelPersonas` | 워크스페이스의 다른 IDENTITY 파일을 채널별로 매핑 (예: `#kr-team` 은 한국어 톤, `#en-team` 은 영어 톤) |
| **서버별 화이트리스트** | `channels.discord.allowedGuilds` | 봇이 동작할 서버 ID 제한. 다른 서버에 초대돼도 무시 |
| **메시지 길이 컷** | `channels.discord.maxInputChars` | 너무 긴 입력은 자동 거절 (DDoS·비용 방지) |

설정 방법 두 가지:
1. `./openclaw setup` 마법사 → Discord 단계의 advanced 항목
2. `~/.openclaw/openclaw.json` 직접 편집 후 `./openclaw stop && ./openclaw start`

**예: 코드 채널만 코딩 모델, 일반 채널은 가벼운 모델:**
```json
"channels": {
  "discord": {
    "channelModels": {
      "1234567890123456": "qwen2.5-coder:7b",
      "9876543210987654": "llama3.1:8b-instruct-q4_K_M"
    }
  }
}
```
(채널 ID: Discord 에서 우클릭 → "Copy Channel ID". 개발자 모드 켜야 보임 — Settings → Advanced → Developer Mode.)

---

## 10. 워크스페이스·인격을 봇으로 끌어오기

`./openclaw chat` 에서 자동 로드되는 인격 파일이 **Discord 봇에서도 그대로 작동**합니다. 봇은 컨테이너 안 워크스페이스 마운트(`~/DEV/openclawAgent`)를 보고 다음을 system prompt 로 묶음:

- `IDENTITY.md` — 봇의 이름·말투·종족
- `SOUL.md` — 가치·태도·금지선 (예: "장난 받아주되 모욕은 정중히 거절")
- `USER.md` — 당신에 대한 메모 (호칭·역할·관심사)
- `AGENTS.md` — 작업 규칙 (예: "코드 답변엔 항상 unit test 도 같이")
- `MEMORY.md` — 장기 기억 (대화 도중 추가 가능)

### 워크스페이스 파일 수정 → 봇 즉시 반영
```bash
# 호스트에서 IDENTITY 수정
nano ~/DEV/openclawAgent/IDENTITY.md

# 봇이 다음 메시지부터 바로 반영 (재시작 불필요 — 매 호출 시 파일 다시 읽음)
```
> 대규모 변경은 새 세션부터 적용. 진행 중 대화는 기존 인격 그대로. `/reset` 으로 즉시 적용도 가능.

### Discord 에서 메모를 워크스페이스에 적기
```
@bot 이거 기억해줘: 매주 월요일 9시 회의록 자동 요약해서 #notes 에 올리기. MEMORY.md 에 'recurring/monday-summary' 항목으로 저장.
```
- 봇이 도구 사용 권한 있으면 직접 `~/DEV/openclawAgent/MEMORY.md` 에 append.
- 그 다음 세션부터 자동으로 system prompt 에 포함 → "지난번에 말씀하신 월요일 요약…"

### 파일·이미지 첨부 (사용 가능 시)

OpenClaw 가 attachment 지원하는 경우:
- Discord 에서 파일 첨부(드래그) + 멘션 → 봇이 파일 내용 읽음
- 이미지 멀티모달 모델(예: `llava:7b`) 이면 봇이 이미지 설명 가능
- 한도: Discord 자체 25 MB (Nitro 면 더 큼)

---

## 11. 봇 행동 관리 (mute · disable · 다중 서버)

### 잠깐 조용히 시키기 (Discord 측 기능)

- 채널 설정 → "Mute @OpenClaw-Mo" — 그 채널에서만 알림 차단(봇 자체는 동작). 또는 봇 역할 권한에서 Send Messages 일시 제거.
- 봇이 폭주(루프 응답 등) 하면 빠른 응급: `./openclaw stop` (봇 자체를 끔).

### 영구적으로 채널·서버에서 빼기

- 채널: 봇 역할 권한에서 해당 채널 View 권한 제거.
- 서버: 봇 멤버 우클릭 → "Kick" 또는 "Ban". OpenClaw 측에서도 `channels.discord.allowedGuilds` 에서 해당 서버 ID 제거 권장.

### 다중 서버 운영

같은 봇 토큰으로 여러 서버 동시 운영 가능 — §4 의 OAuth invite URL 만 다시 열어서 다른 서버 선택.
- 모든 서버가 같은 OpenClaw 인스턴스의 컨텍스트 공유 (메모리·인격 동일).
- 서버별로 다른 인격이 필요하면 `channels.discord.channelPersonas` (§9) 또는 **봇 자체를 따로 만들기** (Discord Developer Portal 에서 새 앱·새 토큰).

### 임시 끄고 켜기 — 매일 패턴

```bash
# 봇 잠깐 끄기 (점심·회의 중)
./openclaw stop

# 다시 켜기
./openclaw start
# Discord 봇은 자동 재연결 (gateway 의 reconnect 로직)
```

자세한 일상 on/off 사이클: [GUIDE-DAILY-USE.md](GUIDE-DAILY-USE.md).

---

## 12. 🎬 상황별 Discord 워크플로우 — 모든 상황에서

"지금 내 위치/상황에서 Discord 로 OpenClaw 에이전트한테 무엇을 어떻게 시키면 되나" 의 8가지 케이스. 각 시나리오는 **언제 / Discord 에 보낼 메시지 / 일어나는 일 / 한계** 4개로 구성.

> **🌍 먼저 보는 게 좋은 통합 시나리오** — "전원 완전 종료 → 켜기 → 종일 Discord 만으로 작업 → 다시 종료" 한 흐름으로 따라가고 싶으면 바로 아래 [⓪ 통합 시나리오](#-통합-시나리오--노트북-끔-상태에서-discord-만으로-하루-보내기) 를 먼저 읽고, 그 다음 ①~⑧ 의 디테일로 들어오세요.

---

### ⓪ 통합 시나리오 — 노트북 끔 상태에서 Discord 만으로 하루 보내기

전원이 완전히 꺼진 노트북을 켜서 → 하루 종일 Discord 만으로 OpenClaw 와 작업하고 → 다시 끄기까지 시간순 walkthrough. 각 시점에 어디 시나리오를 같이 봐야 하는지도 표시.

**🕘 09:00 ─ 노트북 켬 (cold boot)**

GUIDE-DAILY-USE 의 [시나리오 0 — Cold boot](GUIDE-DAILY-USE.md#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 그대로 따라하기 → 핵심은:

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

# 1분 검증 (전부 ✓ 이면 다음 단계로)
docker info >/dev/null 2>&1 && curl -sf http://127.0.0.1:11434/api/tags >/dev/null \
  && docker ps | grep -q openclaw && echo "✅ ALL OK" || echo "⚠ 점검 필요"

# Discord 봇이 outbound 로 나갈 수 있게 — isolated 면 봇은 Discord 와 통신 불가
./openclaw network status
./openclaw network online --restart    # isolated 였으면 잠깐 켜기
```

**🕘 09:01 ─ Discord 에서 봇 살아있는지 확인**

Discord 앱 열기 → 봇 멤버 옆 초록 점 확인 → DM 으로:
```
@OpenClaw-Mo 살아있어?
```
응답 오면 OK. 안 오면 → [§12 ⑧ Cold boot 응급](#-cold-boot--노트북-비정상-종료-직후) + [§ 트러블슈팅](#-트러블슈팅).

**🕘 09:15 ─ 출근길 카페 / 이동 중 (모바일만)**

Discord 모바일 앱에서 DM 으로 [§12 ② 외출](#-외출-중--모바일에서만-접근-가능) 패턴:
```
오늘 ~/DEV/openclawAgent/daily-notes/2026-05-14.md 만들고
아래 회고 적어줘:
- 어제 PR 리뷰 끝냈음
- 오늘 미팅 2개, 그 사이 코드 작업 가능
- 점심 이후 글쓰기 1시간 확보
```

**🕘 11:00 ─ 팀 채널에서 회의 자료 요약 요청**

데스크에서 또는 모바일에서 팀 채널 [§12 ③ 협업](#-팀-채널-협업):
```
@OpenClaw-Mo 위에 P 가 올린 30분 회의 녹취록 핵심 3줄 + 우리 팀 액션 아이템만 뽑아줘
스레드로 답해줘
```

**🕘 13:00 ─ 점심 동안 봇 잠깐 끄기 (선택)**

자원 절약·노이즈 차단을 원하면 잠깐 정지:
```bash
./openclaw stop
# 점심 후
./openclaw start
# Discord 봇은 자동 재연결 (30~60초)
```
또는 그냥 Discord 측에서 채널 mute — [§11 봇 행동 관리](#11-봇-행동-관리-mute--disable--다중-서버).

**🕘 14:30 ─ 워크스페이스 파일 작업 (Discord 에서)**

코드 메모·MEMORY 갱신 [§12 ④ 워크스페이스](#-워크스페이스-파일-작업-읽기수정정리):
```
@OpenClaw-Mo MEMORY.md 에 오늘자로 'discord-only-workflow' 항목 추가:
"v0.2.14 부터 §12 통합 시나리오 활용. 외출 중에도 작업 연속성 확보."
```

**🕘 16:00 ─ 큰 작업 트리거 (백그라운드)**

[§12 ⑥ 긴 작업](#-긴-작업-트리거--알림-받기) 패턴 — 30분짜리 자료 요약 시켜놓고 다른 일:
```
@OpenClaw-Mo 첨부 PDF 30페이지 요약, 끝나면 멘션으로 알려줘
```
회의 끝나고 돌아오면 봇이 결과 + 멘션 알림 보내놨음.

**🕘 18:00 ─ 시스템 운영 점검 (Discord 로)**

DM 으로 [§12 ⑤ 시스템 운영](#-시스템-상태-점검--운영-devops):
```
@OpenClaw-Mo doctor 결과 보여줘
@OpenClaw-Mo gateway 오늘 로그에서 ERROR/WARN 만 추려줘
```
이상 없으면 종료 준비.

**🕘 22:00 ─ 컴퓨터 끄기 (full shutdown)**

[GUIDE-DAILY-USE 시나리오 3](GUIDE-DAILY-USE.md#-시나리오-3--컴퓨터-끄기-전-full-shutdown) — 보통 Level 1 (그냥 macOS 종료) 면 충분. Discord 측에서:
- 진행 중인 봇 작업 (§12 ⑥ 긴 작업 등) 끝났는지 채널 확인
- 다음 부팅까지 봇은 Offline — 모바일에서 봇한테 메시지 보내도 다음날 아침까지 응답 없음
- 정기 작업 (§12 ⑦) 도 노트북 꺼진 동안엔 안 돔

종료 후 다음날 아침엔 다시 위 09:00 단계로.

### 통합 시나리오 — 한 줄 매트릭스

| 시간 | 상황 | 노트북에서 | Discord 에서 | 자세히 |
|---|---|---|---|---|
| 09:00 | Cold boot | `doctor` + `network online` | (봇 자동 재연결 대기) | [GUIDE-DAILY-USE 시나리오 0](GUIDE-DAILY-USE.md#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) |
| 09:01 | 봇 가용성 확인 | — | `@bot 살아있어?` | [§12 ⑧](#-cold-boot--노트북-비정상-종료-직후) |
| 09:15 | 출근길/모바일 | (켜둠) | DM 으로 파일 작업 지시 | [§12 ②](#-외출-중--모바일에서만-접근-가능) |
| 11:00 | 팀 협업 | (켜둠) | 팀 채널 @멘션 + 스레드 | [§12 ③](#-팀-채널-협업) |
| 13:00 | 점심 (선택) | `./openclaw stop` → `start` | 봇 자동 재연결 | [§11](#11-봇-행동-관리-mute--disable--다중-서버) |
| 14:30 | 파일·메모 작업 | (켜둠) | @멘션 with 경로 명시 | [§12 ④](#-워크스페이스-파일-작업-읽기수정정리) |
| 16:00 | 큰 작업 트리거 | (켜둠) | @멘션 + "끝나면 알려줘" | [§12 ⑥](#-긴-작업-트리거--알림-받기) |
| 18:00 | 운영 점검 | (켜둠) | DM 으로 `doctor` / 로그 요청 | [§12 ⑤](#-시스템-상태-점검--운영-devops) |
| 22:00 | Full shutdown | TUI 종료 → `./openclaw stop` (선택) → macOS 종료 | (봇 Offline 으로) | [GUIDE-DAILY-USE 시나리오 3](GUIDE-DAILY-USE.md#-시나리오-3--컴퓨터-끄기-전-full-shutdown) |

### 통합 시나리오 — 자주 막히는 부분

| 시점 | 증상 | 원인 / 해결 |
|---|---|---|
| 09:00 ~ 09:01 | 봇이 1분 후에도 Offline | network 가 `isolated` 로 잔존 → `./openclaw network online --restart`. 그래도 안 뜨면 [§ 트러블슈팅: Offline](#봇이-서버에서-계속-offline) |
| 09:15 | 모바일에서 보낸 메시지에 응답 없음 | 노트북이 슬립 들어갔거나 Docker 가 자동 종료. Mac → System Settings → Battery / Energy 에서 "Prevent automatic sleeping" 또는 caffeinate 권장 |
| 11:00 | 팀 채널에서 다른 사람 메시지에도 봇이 답함 | 자동응답 채널로 잘못 설정. [§9 `muteChannels`](#9-채널·서버별-동작-조정) 로 명시적 차단 |
| 14:30 | 워크스페이스 파일이 안 만들어짐 | 경로 오타 또는 호스트 외부 경로. 봇은 `~/DEV/openclawAgent/` 안만 접근 가능 |
| 16:00 | 봇이 긴 작업 도중 응답 멈춤 | 모델이 너무 크거나 컨테이너 OOM. 작업 짧게 분할 또는 가벼운 모델로 |
| 18:00 | `doctor` 결과를 봇이 못 가져옴 | 봇에 호스트 명령 권한 없음 — 정상. 터미널에서 직접 |
| 22:00 | 종료했더니 다음날 봇이 안 살아남 | Docker 자동 시작 비활성. Settings → "Start Docker Desktop when you sign in" 체크 |

---

### ① 노트북 옆에 있을 때 — 빠른 질문

**언제** — 코드 짜다 막힘, 모르는 명령어, 단순 Q&A.

**Discord 에**
```
@OpenClaw-Mo rsync 로 권한 유지하면서 폴더 동기화하는 옵션이 뭐였지?
```

**일어나는 일** — 봇이 즉시 응답. 채널에 그 답이 남으니 나중에 "지난주에 답해줬던 거" 검색 가능.

**한계** — 터미널과 비교: TUI/chat 이 응답 속도는 더 빠르고 토큰도 절약 (시스템 prompt 가 매번 안 실림). 그래도 채널 히스토리·팀 공유 이점이 크면 Discord.

**TIP**: 자주 쓰는 quick-Q 채널 하나 만들어서 [§9 채널 화이트리스트](#9-채널·서버별-동작-조정) 에 등록 → 멘션 없이 모든 메시지에 응답.

---

### ② 외출 중 / 모바일에서만 접근 가능

**언제** — 카페·이동 중·미팅 대기. 노트북 못 열고 폰만 있음.

**Discord 에 (DM 으로)**
```
오늘 약속 끝나고 ~/DEV/openclawAgent/daily-notes/ 안에
"2026-05-14.md" 파일 만들어서 다음 내용 적어줘:

회의 핵심:
- A 안건은 다음주로 연기
- B 는 내일 오전까지 초안 보내기
```

**일어나는 일**
- 봇이 호스트 워크스페이스(`~/DEV/openclawAgent`) 에 파일 작성. 노트북은 켜져 있어야 함 (OpenClaw 컨테이너가 살아있어야 봇이 도구 사용 가능).
- 노트북 돌아가서 보면 그 파일이 그대로 있음.

**한계**
- 노트북이 꺼져 있거나 슬립이면 (Docker·OpenClaw 가 안 떠 있으면) 봇이 Offline → 답 없음. **외출 전엔 `./openclaw start` 확인 + Discord 봇 Online 인지 한 줄 보고.**
- 모바일은 긴 코드 붙여넣기 불편 — `surf` 같은 도구 호출도 가능하지만 결과를 폰에서 읽긴 짧은 게 편함.

**예: 외출 전 30초 점검**
```bash
./openclaw doctor               # ✓ 다 떠 있는지
./openclaw network status       # online 인지 (isolated 면 봇이 Discord 와 통신 못 함)
# Discord 에서 봇 Online 점 확인
```

---

### ③ 팀 채널 협업

**언제** — 동료들과 같이 회의록·외부 링크·코드 리뷰를 같이 보고 싶을 때.

**Discord 에 (팀 채널)**
```
@OpenClaw-Mo 이 PR diff 핵심 3가지 + 잠재 버그 / 보안 이슈 요약해줘
```
````
```diff
+ const apiKey = process.env.API_KEY;
- const apiKey = "hardcoded-key-123";
+ fetch(url + "?key=" + apiKey)
```
````

**일어나는 일** — 봇 응답이 채널에 공개로 남음 → 팀 전원이 활용. 다른 멤버가 follow-up 질문 가능: `@OpenClaw-Mo 그러면 .env 파일 형식은 어떻게 하는 게 좋아?`

**한계** — 채널의 모든 멤버가 봇 응답을 볼 수 있음. 비밀 코드는 DM 으로. 봇 토큰을 채널에 노출 절대 금지 ([🔒 보안 주의](#-보안-주의-꼭-읽으세요) §3).

**TIP**: 코드 리뷰·회의록 같은 팀 작업은 **스레드** 로 진행 → 메인 채널 잡담 안 끊고 길게 대화 가능.

---

### ④ 워크스페이스 파일 작업 (읽기·수정·정리)

**언제** — 자기 노트·MEMORY·일일 기록을 봇으로 조회·정리.

**Discord 에**
```
@OpenClaw-Mo ~/DEV/openclawAgent/MEMORY.md 에서 "디스코드" 키워드 들어간 항목만
시간순으로 정리해서 보여줘

@OpenClaw-Mo daily-notes 폴더 최근 7일치 회고만 모아서 한 줄씩 요약해줘

@OpenClaw-Mo 방금 우리 대화 핵심을 MEMORY.md 에 "discord-workflows" 섹션으로 추가해줘
```

**일어나는 일** — 봇이 호스트 워크스페이스 (마운트된 `/home/node/.openclaw/workspace`, 호스트의 `~/DEV/openclawAgent`) 에 직접 접근. 변경된 파일은 호스트에서 그대로 보임.

**한계**
- 호스트 임의 경로 (`~/Documents`, `~/Desktop`) 는 **접근 불가** — 격리 의도. 공유하려면 워크스페이스 안에 둬야 함.
- 큰 파일 (수십 MB+) 은 컨텍스트에 한 번에 못 들어감. 봇이 "일부만 봤다" 라고 명시할 것.
- 동시 수정 위험 — 봇이 파일 쓰는 도중 사용자가 열어서 편집하면 충돌. 큰 작업 전에 알려서 동시 편집 회피.

---

### ⑤ 시스템 상태 점검 / 운영 (DevOps)

**언제** — "서버 떠 있어?", "에러 났던 거 로그 보여줘" — 터미널 못 열고 빠르게.

**Discord 에 (DM 추천)**
```
@OpenClaw-Mo 지금 ./openclaw doctor 결과 보여줘

@OpenClaw-Mo gateway 컨테이너 최근 50줄 로그에서 ERROR 나 WARN 만 추려줘

@OpenClaw-Mo ~/.openclaw-mgr/network-mode 파일 내용 알려줘
```

**일어나는 일** — 봇이 도구 사용 권한 있고 명령 실행 허용된 설정이면 호스트 명령을 컨테이너 안에서 또는 SSH 같은 방식으로 실행 후 결과 정리해서 답. (OpenClaw 의 정책·플러그인에 따라 달라짐 — 기본은 워크스페이스 안 파일 조회만 안전.)

**한계 (중요)**
- 봇에게 임의 호스트 명령 실행 권한 주는 건 보안 트레이드오프. **계정 사용자 = Discord 친구들** 인 작은 운영팀에서만 권장.
- 민감 작업(컨테이너 재시작, 백업 복원, 토큰 갱신 등) 은 차라리 터미널로 직접. 봇 응답 신뢰성·롤백 비용 고려.

**TIP**: 운영용 채널 (예: `#ops-alerts`) 을 [§9 자동 응답 채널](#9-채널·서버별-동작-조정) 로 등록 → 멘션 없이도 "지금 상태?" 같은 메시지에 응답.

---

### ⑥ 긴 작업 트리거 + 알림 받기

**언제** — 대용량 PDF 요약, 여러 URL 크롤·정리, 큰 모델 추론 등 1~10분 걸리는 작업.

**Discord 에**
```
@OpenClaw-Mo 이 PDF 30페이지 요약 부탁 (첨부 파일)
끝나면 멘션으로 알려줘

@OpenClaw-Mo surf 로 "오늘 KOSPI 종가 + 외인 순매수 상위 10개" 검색해서
마크다운 표로 정리, 완료 시 #notes 에 올려줘
```

**일어나는 일**
- 봇이 작업 시작 → 짧은 "받았어, 시작할게" 응답
- 백그라운드 처리 후 결과를 답글 또는 다른 채널에 포스팅
- 봇이 mention 으로 알림 → Discord 알림 → 폰까지 푸시

**한계**
- 봇이 작업 도중 컨테이너가 재시작되면 작업 유실. 매우 긴 작업은 별도 큐/스케줄러 필요.
- 메시지 길이 한도 (2,000자) — 결과가 길면 봇이 자동으로 파일로 첨부 또는 스레드 분할.

---

### ⑦ 정기 작업 · 리마인더

**언제** — "매일 아침 어제 회의록 요약", "월요일 9시에 주간 OKR 점검 알림".

**Discord 에 (설정 한 번)**
```
@OpenClaw-Mo 매일 평일 오전 9시에 #notes 채널에
어제 daily-notes 폴더에 새로 추가된 파일이 있으면 요약해서 올려줘
없으면 조용히 패스
```

**일어나는 일** — OpenClaw 의 스케줄러 / cron 통합이 활성화돼 있으면 봇이 정해진 시간에 자동 실행. ([README — 자동 업데이트 스케줄](../README.md#-업데이트-흐름) 의 launchd 와 같은 메커니즘.)

**한계**
- OpenClaw 본체 / 플러그인 버전에 따라 스케줄러 지원이 다름. 미지원이면 호스트에서 cron 으로 `./openclaw chat --no-system -m gemma4:26b <<< "..."` 같은 방식 우회.
- 봇이 끄져 있는 시간엔 스케줄도 안 돌아감. 노트북 항상 켜져 있다는 전제.

---

### ⑧ Cold boot / 노트북 비정상 종료 직후

**언제** — 노트북을 완전히 껐다 다시 켰거나, 비정상 종료 후 일어남.

**Discord 측**
- 봇은 자동으로 다시 Online 시도 (gateway healthy 후 30~60초 안에).
- 봇 멤버 옆 초록 점이 보이지 않으면 노트북 측 점검 필요.

**확인 / 복구 순서**
```bash
# 노트북에서 (시나리오 0 cold-boot 경로 — GUIDE-DAILY-USE 참조)
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw doctor
./openclaw start                     # 컨테이너 자동 복구 안 된 경우
./openclaw network status            # isolated 면 → online 으로 (봇이 Discord 로 나갈 길)
./openclaw network online --restart
./openclaw logs | grep -i discord    # 봇 재연결 진행 확인
```

**Discord 에서 빠른 테스트**
```
@OpenClaw-Mo 살아있어?
```
응답 오면 OK. 안 오면 [§ 트러블슈팅: 봇 Offline](#봇이-서버에서-계속-offline) 트레일.

**한계** — Discord 만 있고 노트북 접근이 아예 불가능한 상황에선 봇 자체를 다시 살릴 방법이 없음. **모바일 응급용 SSH** (예: Tailscale + iSH/Termius) 같은 비상 경로를 미리 준비해두면 외출 중에도 `./openclaw start` 가능.

---

### 상황별 빠른 매칭 표

| 어디 / 언제 | 권장 트리거 | 채널 | 비고 |
|---|---|---|---|
| 노트북 옆 | @멘션 또는 자동응답 채널 | 채널 | TUI/chat 도 같이 좋은 선택 |
| 외출 (모바일) | DM | DM | 노트북 켜져 있어야 함 |
| 팀 협업 | @멘션 + 스레드 | 팀 채널 | 비밀 정보는 DM 으로 |
| 워크스페이스 작업 | @멘션 (workspace 내 경로 명시) | 어디든 | 호스트 외부 경로는 접근 불가 |
| 시스템 운영 | DM 또는 운영 전용 채널 | 운영 채널 | 권한 신중 |
| 긴 작업 트리거 | @멘션 + "완료 시 알려줘" | 채널 (결과 공개 OK 라면) | 결과 길면 자동 첨부 |
| 정기 알림 | 한 번 설정 + 봇 자동 실행 | 알림 채널 | 노트북 항상 켜져 있어야 함 |
| Cold boot 직후 | @멘션 "살아있어?" | DM 또는 채널 | 봇 Offline 이면 노트북 점검 |

### 영구 비활성 (Discord 만 빼고 OpenClaw 는 유지)

```bash
./openclaw setup    # 마법사의 Discord 단계에서 토큰을 빈 값으로 입력
```
또는:
```bash
python3 -c '
import json
cfg = json.load(open("/Users/mo/.openclaw/openclaw.json"))
cfg.setdefault("channels", {}).pop("discord", None)
json.dump(cfg, open("/Users/mo/.openclaw/openclaw.json", "w"), indent=2)
'
./openclaw stop && ./openclaw start
```

---

## 🎯 명령·인터랙션 cheat sheet

가장 자주 쓰는 것만 한 화면에:

| 하고 싶은 것 | Discord 에서 | 효과 |
|---|---|---|
| 봇 부르기 | `@OpenClaw-Mo <메시지>` | 멘션만 → 그 메시지 처리 |
| 1:1 대화 | DM 열고 평문 입력 | 매번 멘션 불필요, 컨텍스트 가장 길게 유지 |
| 슬래시 명령 | `/` 누르고 자동완성 선택 | 매개변수가 필드별 분리 (긴 텍스트는 멘션 권장) |
| 컨텍스트 초기화 | `/reset` 또는 `@bot /reset` | 인격은 유지, 대화 히스토리만 삭제 |
| 모델 전환 | `/agent model <name>` (admin) | 즉시 다음 응답부터 새 모델 |
| 스레드 대화 | 메시지 → "Create Thread" → 입력 | 메인 채널 안 흐트러뜨림 |
| 봇 무시하기 | 채널 설정 → Mute / 봇 역할 권한 | Discord 측 처리 (OpenClaw 무관) |
| 봇 일시 정지 | `./openclaw stop` (호스트) | 모든 서버에서 즉시 Offline |
| 봇 재시작 | `./openclaw start` (호스트) | 자동 재연결 |
| 토큰 노출 응급 | Discord Portal → Reset Token → `./openclaw setup` | 옛 토큰 즉시 무효화 + 재발급 |
| Discord 로그 | `./openclaw logs \| grep -i discord` | 채널 등록·메시지 흐름 점검 |
| 봇 응답 안 함 | [트러블슈팅](#-트러블슈팅) | 8케이스 매핑 |

호스트(터미널) 측 자주 쓰는 명령:

| 명령 | 효과 |
|---|---|
| `./openclaw start` / `stop` | 봇 포함 전체 컨테이너 on/off |
| `./openclaw doctor` | gateway·Discord 채널 연결 상태 |
| `./openclaw logs \| grep -i discord` | Discord 관련 로그만 추출 |
| `./openclaw setup` | 토큰 갱신 / 채널 설정 변경 (멱등) |
| `./openclaw chat` | 봇 없이 호스트 Ollama 와 즉시 대화 (디버깅용) |

---

## 🔒 보안 주의 (꼭 읽으세요)

1. **토큰 = 봇 계정 전체 권한** — `.env`/일반 파일에 평문 저장 비권장. 외부 secret provider 사용을 권합니다 (§5 두 번째 옵션).
2. **노출되면 즉시 Reset** — Discord Developer Portal → Bot 탭 → Reset Token. 옛 토큰 즉시 무효화 + 새 토큰으로 `./openclaw setup` 재실행.
3. **권한은 최소로** — `Administrator` 절대 금지. 봇이 메시지 보내고 읽을 정도로만 권한 부여 (§4 표 참조).
4. **`Privileged Gateway Intents` 는 필요한 것만** — Message Content Intent 외에는 꺼두는 게 안전.
5. **신뢰 안 되는 서버에 봇 넣지 말 것** — 봇의 명령으로 OpenClaw 가 코드를 실행할 수 있으므로 (간접 프롬프트 인젝션 + 도구 사용 결합) 친구·팀 서버 등 신뢰 가능한 곳에서만 운영.
6. **모니터링** — `./openclaw logs` 에서 봇이 어떤 명령을 받았는지 가끔 확인.
7. **`network online` 유지의 보안 영향** — 봇을 켜두는 동안 컨테이너의 외부 outbound 가 열려 있습니다 ([🔒 네트워크 격리 모드](../README.md#-네트워크-격리-모드-명시적-외부-차단-토글) 참조). 봇 안 쓸 때는 `./openclaw network isolated --restart` 로 잠가두세요.

---

## 🛠 트러블슈팅

### "봇이 서버에서 계속 Offline"

```bash
./openclaw logs | grep -iE "discord|gateway"
```

체크리스트:
- [ ] 네트워크 모드 `online` 인가? (`./openclaw network status`)
- [ ] 토큰을 잘못 복사 (앞뒤 공백·줄바꿈)? `./openclaw setup` 다시 실행해 재입력
- [ ] Discord 측에서 토큰 무효화(Reset 후 옛 토큰 유지)? → Bot 탭 가서 새 토큰 발급 후 재등록
- [ ] OpenClaw 게이트웨이 컨테이너가 떠 있는가? `docker compose ps`
- [ ] 방화벽이 `discord.com`/`gateway.discord.gg` outbound 를 차단? (회사 네트워크 흔한 케이스)

### "봇이 응답으로 `Something went wrong while processing your request. Please try again, or use /new to start a fresh session.`"

게이트웨이 로그를 보면 둘 중 하나입니다 — **마운트 누락**(v0.2.17 이전 회귀) 또는 **권한 거부**(v0.2.18 이전 회귀):

```bash
./openclaw logs | grep -i "Failed to inspect sandbox image"
# 케이스 A — 마운트 누락 (v0.2.17 에서 fix):
#   Error: ... no such file or directory
# 케이스 B — 권한 거부 (v0.2.19 에서 fix):
#   Error: ... permission denied while trying to connect to the docker API
```

**케이스 B (macOS Docker Desktop 흔함)**: docker.sock 은 호스트에서는 `root:daemon`(GID=1) 인데 컨테이너 안에선 `root:root`(GID=0) 로 보임. 마운트는 있어도 node 사용자가 GID=0 그룹에 없으면 거부. v0.2.19+ 의 `step_sandbox` 는 `group_add` 에 `0` 과 호스트 GID 둘 다 추가.

즉시 fix:
```bash
# sandbox compose 파일에 group_add: ["0", "1"] 박기
python3 -c '
open("/Users/mo/DEV/openclaw/docker-compose.sandbox.yml","w").write(
  "services:\n  openclaw-gateway:\n    volumes:\n      - /var/run/docker.sock:/var/run/docker.sock\n    group_add:\n      - \"0\"\n      - \"1\"\n"
)'

cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw stop && ./openclaw start

# 검증 (서버 버전이 나오면 OK)
docker exec openclaw-openclaw-gateway-1 docker info --format '{{.ServerVersion}}'
# → 29.x.x  같은 출력
```

원인: `./openclaw stop && start` 또는 `network online/isolated --restart` 사이클 후 gateway 컨테이너 안에 `/var/run/docker.sock` 마운트가 빠진 상태. 봇이 메시지를 받으면 도구 실행을 위해 **sandbox 서브컨테이너**를 띄우려는데 socket 이 없어 실패.

해결 (v0.2.17+):
```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
git pull
./openclaw stop && ./openclaw start
# 확인:
docker inspect openclaw-openclaw-gateway-1 \
  --format '{{range .Mounts}}{{.Source}} {{end}}' | tr ' ' '\n' | grep docker.sock
# → /var/run/docker.sock  이 나와야 정상
```

원래는 install 의 `step_sandbox` 가 `docker-compose.sandbox.yml` 을 만들어 처음엔 마운트가 들어가는데, 그 이후 stop/start 또는 lockdown 이 호출되면 sandbox 오버레이가 빠지는 게 v0.2.16 까지의 회귀였음. v0.2.17 에서 `start.sh` 와 `step_lockdown` 둘 다 sandbox 오버레이를 자동 포함하도록 수정.

### "봇이 Online 인데 어떤 메시지에도 응답 안 함 — TUI 에서는 `fetch failed`"

OpenClaw 의 설정에 등록된 **모델 이름이 실제 설치된 Ollama 모델과 다른** 케이스. OpenClaw 가 onboard 중 하드코딩 기본값 (`gemma4` 등 태그 없는 이름) 을 자동으로 모델 목록에 끼워 넣어 일어남. → [GUIDE-DAILY-USE: 현재 어떤 모델을 쓰는지](GUIDE-DAILY-USE.md#-현재-어떤-모델을-쓰는지--openclawjson-점검) 의 진단·해결 3단계 그대로 적용. 빠른 fix: `./openclaw setup --skip-confirm` (v0.2.11+ 자동 정리).

### "봇이 멘션엔 답하는데 일반 메시지엔 답 안 함"

`Message Content Intent` 미활성. §3 다시 가서 켜고 **Save Changes**. 봇 자동 재연결 (또는 `./openclaw stop && ./openclaw start`).

### "슬래시 명령(`/`) 자동완성에 봇이 안 나옴"

OAuth2 URL Generator scope 에 `applications.commands` 가 빠진 채로 초대됨. §4 에서 두 scope 모두 체크한 새 URL 생성 → 봇 다시 초대(같은 봇 추가 시 권한만 갱신).

### "봇 응답이 너무 느리거나 끊김"

- 로컬 Ollama 모델이 너무 무거움 (예: 24GB 맥에서 27B+) → `./openclaw chat` 의 picker 로 7~8B 모델로 변경, 또는 `~/.openclaw/openclaw.json` 의 default 모델 변경 후 재기동
- 호스트 메모리 부족 → `./openclaw clean --status` 로 점검

### "DM 으로는 답하는데 채널에선 안 답함"

채널에서 봇이 **View Channels / Send Messages / Read Message History** 권한 있는지 확인. 채널 설정 → 권한 → 역할/멤버에서 봇 역할 권한 조정.

### "토큰을 실수로 GitHub 에 푸시했어요"

1. **즉시** Discord Developer Portal → Bot → Reset Token (옛 토큰 무효화)
2. 새 토큰으로 `./openclaw setup` 재실행
3. GitHub 에서 git history rewrite — `git filter-repo` 또는 BFG. 단순 `git push --force` 만으로는 GitHub 캐시에 남을 수 있으니 [SECRETS-EXPOSED 회복 절차](TROUBLESHOOTING.md) 참조 (해당 섹션이 있다면).

### "여러 서버에 같은 봇 넣고 싶음"

같은 OAuth2 invite URL 을 다시 열고 다른 서버 선택. 토큰은 동일. OpenClaw 의 채널 화이트리스트 옵션으로 서버별 행동 제한 가능.

### "OpenClaw 설정에서 Discord 만 끄고 싶음"

```bash
./openclaw setup
# 마법사가 Discord 단계 도달했을 때 'skip' 또는 빈 토큰 입력
# (또는 ~/.openclaw/openclaw.json 의 discord 키만 제거 후 재기동)
```

---

## 🔗 관련 문서 / Related docs

| 문서 | 무엇이 들어있나 |
|---|---|
| [▶ 설치 후 첫 사용 가이드 / First-use](GUIDE-FIRST-USE.md) | 설치 직후 5분 안에 첫 대화. setup 마법사 14단계 walkthrough 의 한 단계가 Discord 토큰 입력 |
| [🔄 일상 사용 가이드 / Daily use](GUIDE-DAILY-USE.md) | 매일 켜고 끄기·세션 이어가기·트러블슈팅·유지보수 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·채널 연동의 일반 원칙 |
| [🌐 GUIDE-WEB-FETCH](GUIDE-WEB-FETCH.md) | 봇이 웹 검색·외부 데이터를 가져올 때 사용하는 `surf` 명령 |
| [🪜 완전 수동 설치](GUIDE-MANUAL-INSTALL.md) | OpenClaw 본체·gateway·sandbox 설치 과정 |
| [🛡 트러블슈팅](TROUBLESHOOTING.md) | 일반 진단·복구 (Discord 외 항목 포함) |
| [README — 마법사 14단계 표](../README.md#-install-직후--첫-사용) | setup 의 어디서 Discord 가 등장하는지 위치 |
| [README — 🔒 네트워크 격리 모드](../README.md#-네트워크-격리-모드-명시적-외부-차단-토글) | 봇 운영 중의 outbound 정책 |

**외부 링크:**
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Developer Docs — Gateway & Intents](https://discord.com/developers/docs/topics/gateway#privileged-intents)
- [Discord — Permissions Calculator](https://discord.com/developers/applications) (앱 생성 후 OAuth2 → URL Generator 에서 시각 도구 제공)
- OpenClaw 공식 채널 설정 docs (마법사 안 `Docs: discord` 링크 — 본체 버전마다 다름)

---

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)
