# 🚀 비개발자용 시작 가이드 (한국어)

> 이 문서는 "터미널을 한 번도 안 써봤다" 는 분을 기준으로 합니다. 명령어 한 줄 한 줄을 그대로 복사·붙여넣기 하면 됩니다.

## 📖 목차

- [사전 준비](#사전-준비)
- [1. 터미널 열기](#1-터미널-열기)
- [2. 코드 받기](#2-코드-받기)
- [3. 폴더로 이동](#3-폴더로-이동)
- [4. 설정 파일 (자동 생성 — 아무것도 안 해도 됩니다)](#4-설정-파일-자동-생성--아무것도-안-해도-됩니다)
- [5. 현재 상태 점검](#5-현재-상태-점검)
- [6. 설치 시작](#6-설치-시작)
- [7. 잘 되는지 확인](#7-잘-되는지-확인)
- [8. 매일 자동으로 최신 유지](#8-매일-자동으로-최신-유지)
- [9. 안전하게 백업](#9-안전하게-백업)
- [문제가 생기면](#문제가-생기면)

---

## 사전 준비

- **맥북** (M1 이상의 Apple Silicon 권장. 이 프로젝트의 레퍼런스는 MacBook Pro 16" M5 Pro · 24GB RAM)
- **인터넷 연결**
- **여유 디스크 공간 50GB 이상**
- **30분의 시간** (대부분 다운로드 대기)

## 1. 터미널 열기

> 📸 *(스크린샷 자리: Spotlight → "터미널" 검색)*

1. 키보드에서 `⌘ + Space` (커맨드 + 스페이스바)
2. **터미널** 이라고 치고 Enter
3. 검은(또는 흰) 창이 뜨면 성공입니다

터미널을 열면 이런 식으로 보입니다:

```
Last login: Sat Apr 25 10:30:12 on ttys000
yourname@MacBook-Pro ~ %
```

맨 끝의 `%` 뒤에 명령을 입력합니다.

## 2. 코드 받기

아래 한 줄을 복사해서 터미널에 붙여넣고 Enter:

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/openclaw-workspace
```

> 💡 처음에 `git` 이 없다고 하면 자동으로 Xcode Command Line Tools 설치 다이얼로그가 뜹니다. **설치** 를 누르고 끝날 때까지 기다리세요. (약 5분)

## 3. 폴더로 이동

```bash
cd ~/openclaw-workspace/openclaw-mgr
```

## 4. 설정 파일 (자동 생성 — 아무것도 안 해도 됩니다)

`./openclaw` 를 처음 실행하면 `.env` 파일이 자동으로 만들어집니다. OpenClaw 공식 저장소 주소도 이미 기본값으로 들어 있습니다.

```
✔ .env 자동 생성됨 (.env.example 기본값 적용)
```

이 메시지가 보이면 성공입니다. **아무것도 수정하지 않아도 바로 설치로 넘어갈 수 있습니다.**

> 💡 나중에 모델이나 백업 경로 등을 바꾸고 싶으면 `openclaw-mgr/.env` 를 텍스트 편집기로 열어 수정하면 됩니다. 지금은 안 해도 됩니다.

## 5. 현재 상태 점검

```bash
./openclaw doctor
```

빨간 ✗ 와 노란 ⚠ 가 보일 겁니다. 정상입니다 — 다음 단계가 자동으로 해결합니다.

예시 출력 (설치 전 — 거의 대부분 미설치 상태):

```
━━━━━━━━ OpenClaw 시스템 진단 ━━━━━━━━
  ✓  OS                     Darwin 15.4 arm64
  ✓  CPU                    Apple M5 Pro
  ✓  RAM                    24GB
  ✓  디스크 여유             142GB
  ─────────────────────────────────────
  ✗  Xcode CLT              —
       ↳ 없으면 install 이 자동 설치
  ✗  Homebrew               —
       ↳ 없으면 install 이 자동 설치
  ✗  Docker                 —
       ↳ Docker Desktop 필요
  ⚠  Docker 데몬             —
       ↳ Docker Desktop 앱을 실행하세요
  ✗  Ollama                 —
  ─────────────────────────────────────
  ⚠  OpenClaw 저장소         —
       ↳ .env 의 OPENCLAW_REPO 를 먼저 채우세요
  ⚠  컨테이너 실행           0개
       ↳ ./openclaw start
  ─────────────────────────────────────
  🔒  네트워크 격리           isolated (외부 차단)
       ↳ 최고 보안 — 설치/업데이트 시 ./openclaw network online --restart
```

색상은 실제 터미널에서 빨강(✗) / 노랑(⚠) / 초록(✓) 으로 보입니다.

## 6. 설치 시작

```bash
./openclaw install
```

진행 중에 다음과 같은 일이 일어납니다 — 모두 그냥 따라가시면 됩니다:

| 단계 | 무슨 일이 | 예상 시간 |
|---|---|---|
| Xcode CLT | 시스템 다이얼로그가 뜨면 **설치** | 5분 |
| Homebrew | `Press RETURN to continue` 가 나오면 Enter, 비밀번호 요청 시 입력 | 2분 |
| Docker Desktop | 처음 자동 실행 후 약관 동의 화면이 뜸 → **Accept** | 3분 |
| Ollama 설치 | 자동 | 1분 |
| 모델 다운로드 (`qwen2.5-coder:7b`, ~4.7GB) | 자동 | 5~10분 |
| OpenClaw 저장소 clone | 자동 | 1분 |
| 컨테이너 빌드/시작 | 자동 | 5~15분 |

전체 대략 **20~40분** (대부분 다운로드 대기). 중간에 노트북을 닫아도 괜찮습니다 — 다시 열어서 같은 명령을 실행하면 끊긴 지점부터 이어집니다.

## 7. 잘 되는지 확인

```bash
./openclaw doctor
```

이번엔 모두 ✓ (초록 체크)면 성공입니다 🎉

```bash
./openclaw logs
```

컨테이너가 무엇을 하고 있는지 실시간으로 보입니다. 종료는 `Ctrl + C`.

## 8. 매일 자동으로 최신 유지

```bash
./openclaw schedule enable
```

매일 새벽 3시에 자동으로 업데이트됩니다. 끄려면 `./openclaw schedule disable`.

## 9. 안전하게 백업

```bash
./openclaw backup --name 처음설치직후
```

`~/openclaw-backups/` 안에 `.tar.gz` 파일이 생깁니다. 외장하드나 클라우드(시크릿 검토 후)에 복사해 두세요.

## 문제가 생기면

1. `./openclaw doctor` — 어디가 문제인지 알려줍니다
2. [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) — 흔한 오류 대응표
3. 그래도 안 되면 [GitHub Issues](https://github.com/GoGoComputer/openclaw-workspace/issues) 에 `./openclaw doctor` 출력을 붙여서 등록해주세요. (시크릿은 자동 마스킹됩니다)
