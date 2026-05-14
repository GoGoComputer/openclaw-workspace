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
