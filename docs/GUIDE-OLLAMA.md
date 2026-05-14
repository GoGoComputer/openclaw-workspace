# 🦙 Ollama 입문 가이드 / Beginner Guide

> 🇰🇷 **3분 안에**: Ollama 가 뭔지, 왜 OpenClaw 가 이걸 쓰는지, 모델은 어디 저장되는지.
> 🇬🇧 **In 3 minutes**: what Ollama is, why OpenClaw uses it, where models live.

## 📖 목차 / Contents

- 🇰🇷 [한국어](#-한국어)
  - [Ollama 가 뭐예요?](#ollama-가-뭐예요) · [왜 OpenClaw 가 Ollama 를 쓰나요?](#왜-openclaw-가-ollama-를-쓰나요) · [어떻게 설치되나요?](#어떻게-설치되나요) · [모델(Model) 이란?](#모델-model-이란) · [자주 쓰는 명령](#자주-쓰는-명령) · [모델은 어디 저장되나요?](#모델은-어디-저장되나요) · ["Ollama 서버" 라는 건?](#ollama-서버-라는-건) · [더 알아보기](#더-알아보기)
- 🇬🇧 [English](#-english)
  - [What is Ollama?](#what-is-ollama) · [Why does OpenClaw use Ollama?](#why-does-openclaw-use-ollama) · [How is it installed?](#how-is-it-installed) · [What is a "model"?](#what-is-a-model) · [Common commands](#common-commands) · [Where do models live?](#where-do-models-live) · [What's the "Ollama server"?](#whats-the-ollama-server) · [Learn more](#learn-more)

---

## 🗺 이 문서를 처음 보신다면 / Document Map

이 문서는 **Ollama 입문** 가이드입니다 (3분 내). "로컬 LLM 이 뭐라고?" 부터 "모델은 어디 저장되고 서버는 언제 돌고 OpenClaw 가 왜 이걸 골랐는지"까지.

> 🎯 **권장 흐름**: 위 TOC 의 처음 4항목 (Ollama 란 → 왜 → 설치 → 모델) 만 읽으면 개념 완료. 자주 쓰는 명령 치트시트가 필요하면 "자주 쓰는 명령" 절로 점프. 포트 11434 충돌로 에러나면 [GUIDE-MANUAL-INSTALL.md §0.5.2-A](GUIDE-MANUAL-INSTALL.md#052-a--11434-가-ollama-가-아닌-프로세스에-잡혀-있을-때--자세히).

---

## 🇰🇷 한국어

### Ollama 가 뭐예요?

**Ollama 는 "내 맥북에서 돌아가는 ChatGPT 같은 LLM 실행기"** 입니다.

- ChatGPT / Claude 같은 클라우드 LLM 은 OpenAI / Anthropic 서버에서 돕니다 → 인터넷 필요, 데이터 외부 전송, 사용료.
- **Ollama** 는 같은 종류의 모델 (Llama, Qwen, Mistral, EXAONE…) 을 **여러분 컴퓨터 안에서** 돌립니다 → 인터넷 불필요, 데이터 외부 안 나감, 무료.

```
[사용자 질문] ──▶ Ollama (내 맥북 RAM/GPU) ──▶ [답변]
                  ↑
                  모델 파일 (~/. ollama/models 에 저장)
```

### 왜 OpenClaw 가 Ollama 를 쓰나요?

OpenClaw 는 코딩·웹 탐색을 직접 해주는 AI 에이전트인데, 매번 OpenAI API 부르면:
1. 돈이 듭니다 (토큰당 과금)
2. 코드·파일이 외부로 나갑니다 (보안 문제)
3. 인터넷 끊기면 못 씁니다

**Ollama 를 쓰면 셋 다 해결** — 무료 + 100% 로컬 + 오프라인 가능.

### 어떻게 설치되나요?

`openclaw install` 한 번이면 끝. 이게 알아서 합니다:

```bash
brew install ollama          # 1) Ollama 자체 설치
brew services start ollama   # 2) 백그라운드로 항상 켜둠
ollama pull qwen2.5-coder:7b # 3) 추천 모델 다운 (~4.7GB)
```

직접 깔아도 똑같이 동작합니다 (`brew install ollama && ollama pull <모델>`).

### 🔌 Ollama 켜기 · 끄기 · 재시작 · 자동시작 (종합)

macOS 에서 Ollama 데몬을 띄우는 **3가지 방식** — 각자 장단점 다름. 셋 다 결국 같은 일(포트 11434 HTTP 서버 실행)을 함:

| 방식 | 명령 | 자동 재시작 | 메뉴바 아이콘 | 권장 사용처 |
|---|---|---|---|---|
| **A. macOS 앱** | `open -a Ollama` | 사용자가 로그인하면 (Login Items 등록 시) | ✓ 🦙 표시 | **일반 사용자 (권장)** |
| **B. brew services** | `brew services start ollama` | Mac 부팅 시 자동 | ✗ | 헤드리스 서버 / 자동화 |
| **C. 일회성** | `ollama serve &` | ✗ (셸 종료 시 죽음) | ✗ | 디버깅 · 빠른 테스트 |

> 💡 **세 방식이 동시에 떠 있으면 충돌** — 포트 11434 중복 바인딩으로 두 번째 이후가 즉시 죽음. 한 방식만 골라 쓰세요.

#### 🟢 켜기

```bash
# A. macOS 앱 (권장 — 메뉴바에 🦙 아이콘 보임)
open -a Ollama

# B. 항상 백그라운드로 (Mac 재부팅 시도 자동)
brew services start ollama

# C. 일회성 (이 셸이 살아있을 동안만)
ollama serve &
```

#### 🔴 끄기

```bash
# A. macOS 앱 종료 (가장 깔끔)
osascript -e 'quit app "Ollama"'

# B. brew services 정지
brew services stop ollama

# C. 일회성으로 띄운 거 종료
pkill -f "ollama serve"

# 어느 방식이든 강제 종료 (응급)
pkill -9 -f ollama
```

#### 🔄 재시작

```bash
# A. 앱 재시작 (모델이 RAM 에서 풀려 깨끗한 시작)
osascript -e 'quit app "Ollama"' && sleep 2 && open -a Ollama

# B. brew services 재시작
brew services restart ollama

# 어느 방식이든 강제 재시작 (응급)
pkill -f ollama; sleep 2; open -a Ollama
```

#### ⚙️ Mac 켜질 때 자동 시작 설정

**A 방식 (macOS 앱) 자동 시작:**
1. 시스템 설정(System Settings) → 일반(General) → 로그인 항목(Login Items)
2. "로그인 시 열기 (Open at Login)" 에 **Ollama.app 추가**
3. 다음 부팅부터 메뉴바에 🦙 자동 표시

또는 한 줄 명령:
```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Ollama.app", hidden:false}'
```

**B 방식 (brew services) 은 기본적으로 자동 시작** — `brew services start ollama` 한 번 하면 LaunchAgent 가 등록돼 매 부팅마다 자동 기동.

#### ✅ 동작 확인 (켜졌는지 점검)

```bash
# HTTP API 응답
curl -sf http://127.0.0.1:11434/api/tags >/dev/null && echo "✓ Ollama OK" || echo "✗ Ollama DOWN"

# 어떤 모델 로드돼 있나
ollama list                  # 깔린 모델 전체
ollama ps                    # 지금 RAM 에 올라간 모델만

# 어떤 프로세스가 11434 잡고 있나
lsof -nP -iTCP:11434 -sTCP:LISTEN
```

#### 🐛 자주 막히는 부분

| 증상 | 원인 / 해결 |
|---|---|
| `open -a Ollama` 했는데 메뉴바 아이콘 안 뜸 | 첫 실행이라 macOS 가 "확인되지 않은 개발자" 경고 — Finder → Applications → Ollama 우클릭 → 열기 한 번 |
| `bind: address already in use` | 다른 방식이 이미 떠 있음 — `lsof -iTCP:11434` 로 PID 찾아 정리 |
| 데몬은 떴는데 모델 응답이 30초+ 걸림 | 모델이 RAM 에 처음 로드 중 — 정상. 다음 요청부터 빠름 |
| `~/.ollama/models` 위치를 다른 디스크로 옮기고 싶음 | `OLLAMA_MODELS` 환경변수 설정 + 데몬 재시작 |
| 컨테이너에서 Ollama 가 안 보임 | `127.0.0.1:11434` 아니라 `host.docker.internal:11434` 로 호출해야 함 — [Ollama URL 함정 FAQ](../README.md) |
| `isolated` 모드라 봇이 host Ollama 못 부름 | `./openclaw network online --restart` (이 가이드 § "Ollama 서버 라는 건?" 참조) |

> 일상 사이클 (Mac 끔→켬, 자리 비움, 종료) 전체 흐름은 [GUIDE-DAILY-USE.md](GUIDE-DAILY-USE.md) — 특히 [시나리오 0 cold boot 의 2단계](GUIDE-DAILY-USE.md#-시나리오-0--컴퓨터-완전히-껐다-켰을-때-cold-boot) 가 Ollama 켜기·확인을 다룹니다.

### 모델 (Model) 이란?

모델 = AI의 "두뇌 파일". 크기가 클수록 똑똑하지만 RAM/디스크를 더 먹습니다.

| 이름 표기 | 뜻 | 예시 |
|---|---|---|
| `qwen2.5-coder:7b` | "Qwen 2.5 Coder 모델, 7B 파라미터 버전" | 코딩 추천 |
| `llama3.1:8b` | "Llama 3.1, 8B 파라미터" | 범용 |
| `solar-pro:22b` | "Upstage Solar Pro, 22B" | 강력하지만 13GB 차지 |
| `exaone3.5:7.8b` | "LG EXAONE 3.5, 7.8B" | 한국어 강함 |

**24GB RAM 맥북 권장**: 7B~8B 모델. 13B 이상은 느려지거나 swap 발생.

### 자주 쓰는 명령

```bash
ollama list                      # 내가 받아둔 모델 전부 보기
ollama pull llama3.1:8b          # 새 모델 다운
ollama rm llama3.1:8b            # 모델 삭제 (디스크 회수)
ollama run llama3.1:8b           # 터미널에서 직접 대화 (나가기: /bye)
ollama ps                        # 지금 메모리에 로드된 모델
```

OpenClaw 에서 위 작업을 한 줄로:

```bash
openclaw models                  # ollama list + .env 통합 보기
openclaw models add llama3.1:8b  # .env 등록 + 자동 pull
openclaw models suggest          # 24GB 추천 모델 목록
```

### 모델은 어디 저장되나요?

```
~/.ollama/models/    # 보통 수 GB ~ 수십 GB. 디스크 부족하면 여기부터 점검.
```

청소: `openclaw clean --all` 또는 직접 `ollama rm <이름>`.

### "Ollama 서버" 라는 건?

`brew services start ollama` 가 항상 백그라운드에서 띄우는 작은 HTTP 서버 (포트 `11434`).
- 호스트(맥북) 에서: `http://localhost:11434`
- Docker 컨테이너 안에서: `http://host.docker.internal:11434`

OpenClaw 컨테이너는 **두 번째 주소** 로 호스트 Ollama 에 접속해 모델을 빌려 씁니다 (컨테이너 안에 따로 모델 설치 안 함 = 디스크 절약).

> ⚠️ `isolated` 네트워크 모드에서는 이 연결도 차단됩니다. 로컬 LLM 쓸 때는 `openclaw network online --restart`.

### 더 알아보기
- 공식: https://ollama.com
- 모델 검색: https://ollama.com/library
- 트러블슈팅: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🇬🇧 English

### What is Ollama?

**Ollama is "ChatGPT-style LLMs running on your own Mac."**

- Cloud LLMs (ChatGPT, Claude) run on OpenAI / Anthropic servers → needs internet, data leaves your machine, costs money.
- **Ollama** runs the same family of models (Llama, Qwen, Mistral, EXAONE…) **inside your computer** → no internet, no data egress, free.

```
[your prompt] ──▶ Ollama (your Mac's RAM/GPU) ──▶ [answer]
                   ↑
                   model files (stored in ~/.ollama/models)
```

### Why does OpenClaw use Ollama?

OpenClaw is an AI agent that runs code and browses the web. Calling OpenAI's API every time means:
1. Token costs add up
2. Your code & files go to a third-party server
3. You can't use it offline

**Ollama solves all three** — free, 100% local, works offline.

### How is it installed?

One `openclaw install` does it for you:

```bash
brew install ollama          # 1) install Ollama itself
brew services start ollama   # 2) keep it running in the background
ollama pull qwen2.5-coder:7b # 3) pull the default coding model (~4.7GB)
```

You can install it manually too — same result.

### What is a "model"?

A model is the AI's "brain file". Bigger = smarter but uses more RAM and disk.

| Name | Meaning | Use |
|---|---|---|
| `qwen2.5-coder:7b` | Qwen 2.5 Coder, 7B parameters | recommended for coding |
| `llama3.1:8b` | Llama 3.1, 8B parameters | general purpose |
| `solar-pro:22b` | Upstage Solar Pro, 22B | powerful but ~13GB |
| `exaone3.5:7.8b` | LG EXAONE 3.5, 7.8B | strong on Korean |

**24GB RAM Mac recommendation**: 7B–8B. Above 13B will swap or run slowly.

### Common commands

```bash
ollama list                      # show all models you've pulled
ollama pull llama3.1:8b          # download a new one
ollama rm llama3.1:8b            # delete (reclaim disk)
ollama run llama3.1:8b           # chat directly (exit with /bye)
ollama ps                        # currently-loaded models in RAM
```

Same things via OpenClaw, in one line:

```bash
openclaw models                  # ollama list + your .env entries
openclaw models add llama3.1:8b  # update .env and pull
openclaw models suggest          # 24GB-Mac picks
```

### Where do models live?

```
~/.ollama/models/    # usually several GB to tens of GB
```

Clean up: `openclaw clean --all` or `ollama rm <name>`.

### What's the "Ollama server"?

`brew services start ollama` runs a tiny HTTP server on port `11434`:
- From your Mac: `http://localhost:11434`
- From inside a Docker container: `http://host.docker.internal:11434`

The OpenClaw container connects via the **second address**, reusing your host Ollama (no duplicated model files inside the container).

> ⚠️ The default `isolated` network mode blocks this too. To use local LLMs run `openclaw network online --restart`.

### Learn more
- Official: https://ollama.com
- Model library: https://ollama.com/library
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

<!-- RELATED-DOCS:BEGIN -->
## 🔗 관련 문서 / Related docs

| 문서 | 무엇이 있나 |
|---|---|
| [🌱 처음부터 / From zero](GUIDE-FROM-ZERO.md) | 터미널·클릭·파일 개념부터 차근차근 (KO+EN) |
| [🚀 빠른 시작 (KO)](QUICKSTART-ko.md) | 터미널 열기 → 5개 명령 → 한 줄 설치 |
| [🚀 Quickstart (EN)](QUICKSTART-en.md) | Open terminal → 5 commands → one-liner install |
| [🪜 완전 수동 설치](GUIDE-MANUAL-INSTALL.md) | brew/스크립트 없이 직접 다운 (KO+EN, 프로덕션 부록) |
| [🐳 Docker 기초](GUIDE-DOCKER.md) | 컨테이너·이미지·compose 3분 가이드 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·웹에서 가져오기 단락 |
| [🌐 웹 정보 가져오기 / surf](GUIDE-WEB-FETCH.md) | 코스피·뉴스·환율·논문 — `surf` 샌드박스 명령 포함 |
| [🎨 크리에이티브 파이프라인](GUIDE-CREATIVE-PIPELINE.md) | Pinterest → 나노바나나(4창) → Figma 자동 배치 |
| [🎬 쇼츠 자동화](GUIDE-SHORTS-PIPELINE.md) | Pinterest → 미리캔버스 → CapCut → 9:16 MP4 |
| [🚑 트러블슈팅](TROUBLESHOOTING.md) | 흔한 오류와 해결 명령 |
| [🧠 아키텍처](ARCHITECTURE.md) | 디스패처·멱등 설계·compose override |
| [🤝 기여 가이드 (입문)](GUIDE-CONTRIBUTING.md) | 오타·번역·베타테스트도 환영 |
| [🐙 기여 가이드 (코드)](CONTRIBUTING.md) | 코드 스타일·PR 절차 |
| [📦 릴리스 노트 v0.1.0](RELEASE_NOTES_v0.1.0.md) | 변경 사항 |

⬆️ [README (KO)](../README.md) · [README (EN)](../README.en.md)
<!-- RELATED-DOCS:END -->
