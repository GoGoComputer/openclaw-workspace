# openclaw-workspace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)](#)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-arm64-blue?logo=apple)](#)
[![Shell](https://img.shields.io/badge/shell-bash%203.2%2B-1f425f?logo=gnu-bash)](#)
[![CI](https://img.shields.io/github/actions/workflow/status/GoGoComputer/openclaw-workspace/ci.yml?branch=main)](https://github.com/GoGoComputer/openclaw-workspace/actions)

> **OpenClaw 셀프호스트 자동화 — macOS용 한 줄 설치/유지보수 도구**
>
> 새 맥북에서 `./openclaw install` 한 번이면 Docker · (선택)Ollama · OpenClaw 컨테이너까지 자동으로 준비됩니다. 중간에 끊겨도 다시 실행하면 **이어서** 진행합니다. 로컬 100% 격리 환경을 지향합니다.

> 🇬🇧 English version: [README.en.md](README.en.md)

## 📖 목차 / Contents

- [🔁 워크스페이스 파이프라인](#-워크스페이스-파이프라인)
- [🚀 5분 시작 (비개발자 OK)](#-5분-시작-비개발자-ok)
  - [표준 — 스크립트 설치 (권장)](#표준--스크립트-설치-권장)
  - [완전 수동 설치 (회사 정책·오프라인용)](#완전-수동-설치-회사-정책오프라인용)
- [🩺 진단 / `doctor` 항목별 가이드](#-진단--doctor-항목별-가이드)
- [🤖 자동화 3종 — 한눈 카탈로그](#-자동화-3종--한눈-카탈로그)
- [📚 문서 가이드](#-문서-가이드)
- [🤔 이게 뭐예요?](#-이게-뭐예요)
- [📋 명령 카탈로그](#-명령-카탈로그)
- [🤖 모델 관리 — 내 로컬 Ollama 모델 그대로 쓰기](#-모델-관리--내-로컬-ollama-모델-그대로-쓰기)
  - [비개발자 모드 (한 줄 명령)](#비개발자-모드-한-줄-명령)
  - [개발자 모드 (직접 편집 또는 호스트 명령)](#개발자-모드-직접-편집-또는-호스트-명령)
  - [⚠️ isolated 모드 주의](#️-isolated-모드-주의)
- [⚙️ 설정 (`.env`)](#️-설정-env)
- [💻 셸 호환성 (zsh / bash)](#-셸-호환성-zsh--bash)
- [🇰🇷 한국 소버린 AI 와 함께 쓰기](#-한국-소버린-ai-와-함께-쓰기)
- [🧹 메모리·디스크 정리 (비개발자용)](#-메모리디스크-정리-비개발자용)
- [🔒 네트워크 격리 모드](#-네트워크-격리-모드-명시적-외부-차단-토글)
  - [🔒 isolated (기본) 에서 막히는 것](#-isolated-기본-에서-막히는-것)
  - [어떤 상황에서 유용한가요?](#어떤-상황에서-유용한가요)
  - [설치/업데이트용 표준 워크플로우](#설치업데이트용-표준-워크플로우)
- [🔒 보안 주의 (꼭 읽으세요)](#-보안-주의-꼭-읽으세요)
- [❓ FAQ](#-faq)
- [🛠 개발자용](#-개발자용)
  - [디렉터리 구조](#디렉터리-구조)
  - [멱등 설계 (`state` 파일 포맷)](#멱등-설계-state-파일-포맷)
  - [정적 검사](#정적-검사)
  - [기여하기](#기여하기)
  - [자체 게시](#자체-게시-자기-fork-를-github-에-올릴-때)
- [📜 라이선스](#-라이선스)

---

## 🔁 워크스페이스 파이프라인

> 이 README 는 **하나의 파이프라인**입니다. 위에서 아래로, 또는 아래 표의 단계별 가이드를 따라가면 **설치 → 사용 → 유지보수 → 설정 → 업데이트** 까지 한 번에 됩니다. 각 단계마다 어떤 명령을 치고 어떤 문서를 보면 되는지 정해져 있습니다.

| # | 단계 | 핵심 명령 | 안내 문서 |
|---|---|---|---|
| 1 | **설치** (Install) | `git clone … && ./openclaw install` | [표준 설치](#표준--스크립트-설치-권장) · [완전 수동](docs/GUIDE-MANUAL-INSTALL.md) · [처음부터](docs/GUIDE-FROM-ZERO.md) |
| 2 | **진단** (Doctor) | `./openclaw doctor` | [진단 항목별 가이드](#-진단--doctor-항목별-가이드) · [TROUBLESHOOTING](docs/TROUBLESHOOTING.md) |
| 3 | **사용** (Use) | `./openclaw start` · `docker compose exec openclaw-cli bash` · `surf "…"` · `creative run "…"` · `shorts run "…"` | [설치 끝났습니다 — 어떻게 대화하죠?](docs/GUIDE-OPENCLAW.md#설치-끝났습니다--이제-어떻게-대화하죠) · [자동화 3종](#-자동화-3종--한눈-카탈로그) · [GUIDE-WEB-FETCH](docs/GUIDE-WEB-FETCH.md) · [GUIDE-CREATIVE-PIPELINE](docs/GUIDE-CREATIVE-PIPELINE.md) · [GUIDE-SHORTS-PIPELINE](docs/GUIDE-SHORTS-PIPELINE.md) |
| 4 | **유지보수** (Maintain) | `./openclaw logs` · `./openclaw clean` · `./openclaw backup` · `./openclaw restore` | [명령 카탈로그](#-명령-카탈로그) · [정리](#-메모리디스크-정리-비개발자용) |
| 5 | **설정 변경** (Configure) | `.env` 편집 · `./openclaw models …` · `./openclaw network …` | [.env 설정](#️-설정-env) · [모델 관리](#-모델-관리--내-로컬-ollama-모델-그대로-쓰기) · [네트워크 격리](#-네트워크-격리-모드-명시적-외부-차단-토글) |
| 6 | **업데이트** (Update) | `./openclaw update` · `./openclaw self-update` · `./openclaw schedule enable` | [업데이트 흐름](#-업데이트-흐름) |
| 7 | **문제 해결** (Recover) | `./openclaw doctor` → `./openclaw logs <svc>` → 해당 항목 가이드 | [진단 항목별 가이드](#-진단--doctor-항목별-가이드) · [TROUBLESHOOTING](docs/TROUBLESHOOTING.md) |

각 단계의 명령은 모두 멱등(여러 번 실행해도 안전)입니다. 중간에 끊겨도 다시 같은 명령을 치면 이어서 진행됩니다.

---

## 🚀 5분 시작 (비개발자 OK)

> "터미널이 뭐예요?" 라면 먼저 [docs/QUICKSTART-ko.md](docs/QUICKSTART-ko.md) 부터 보세요. 더 앞 단계(클릭/폴더/경로 개념) 부터 필요하면 [docs/GUIDE-FROM-ZERO.md](docs/GUIDE-FROM-ZERO.md). 단계별 예시 출력이 다 있습니다. (English: [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md))

설치 경로는 두 가지뿐입니다 — **표준 스크립트 설치** (대부분의 경우) 또는 **완전 수동 설치** (회사 보안 정책 / 오프라인 / GitHub 장애 시).

### 표준 — 스크립트 설치 (권장)

```bash
# 1) 코드 받기
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace/openclaw-mgr

# 2) 진단 — 지금 무엇이 부족한지 한눈에
./openclaw doctor

# 3) 설치 — 부족한 부분만 자동으로. 중간에 끊겨도 다시 치면 이어서 진행
./openclaw install

# 4) 인자 없이 실행하면 한국어/영어 대화형 메뉴
./openclaw
```

설치 중 **Docker Desktop 약관 동의 / Xcode Command Line Tools 다이얼로그**가 뜰 수 있습니다. 따라가시면 됩니다. 각 다이얼로그가 무엇을 묻는지 자세한 설명은 [docs/TROUBLESHOOTING.md — Docker Desktop 첫 실행](docs/TROUBLESHOOTING.md#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) 참조.

설치 끝나면 한 번 더 진단하고, 원하면 자동 업데이트를 켭니다:

```bash
./openclaw doctor              # 모두 ✓ 확인
./openclaw schedule enable     # 매일 새벽 자동 업데이트 (선택)
```

> ℹ️ **OpenClaw 본체 공식 저장소**: `https://github.com/openclaw/openclaw` — `.env` 는 **첫 실행 시 자동 생성**됩니다(`cp` 불필요). `./openclaw install` 만으로 바로 띄울 수 있습니다.

### 📍 `./openclaw` 명령은 어디서 실행하나요?

> 이 README/가이드의 **모든 `./openclaw <verb>` 예시는 `openclaw-workspace/` 또는 `openclaw-workspace/openclaw-mgr/` 디렉터리에서 실행하는 것을 가정**합니다. 다른 곳에서 치면 `zsh: no such file or directory: ./openclaw` 가 납니다.

세 가지 호출 방식 중 편한 걸 쓰세요:

```bash
# 방식 A — 워크스페이스 루트에서 (권장: 가장 짧음)
cd ~/DEV/openclawAgent/openclaw-workspace
./openclaw doctor

# 방식 B — 매니저 디렉터리에서 (원본 위치)
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw doctor

# 방식 C — 어디서나 (PATH 등록·1회 설정)
echo 'export PATH="$HOME/DEV/openclawAgent/openclaw-workspace:$PATH"' >> ~/.zshrc
source ~/.zshrc
openclaw doctor                 # cd 없이 바로 실행
```

> 첫 설치 시 `git clone` 위치가 달랐다면 그에 맞춰 경로만 바꾸세요. 어디에 깔렸는지 모르겠으면:
> ```bash
> find ~ -type f -name openclaw -path '*/openclaw-mgr/*' 2>/dev/null
> ```

자세한 PATH 등록·alias 사용법은 [TROUBLESHOOTING — `./openclaw` 명령 위치 / PATH 등록](docs/TROUBLESHOOTING.md#openclaw-명령-위치--path-등록) 참조.

### 완전 수동 설치 (회사 정책·오프라인용)

`curl | bash` 형태의 자동 설치를 못 쓰는 환경 — 사내 보안 정책, GitHub codeload 502 장기 장애, 또는 "내 손으로 한 단계씩 확인하고 깔고 싶다" 는 분들을 위해 **완전 수동 설치 가이드**가 따로 있습니다.

| 무엇 | 어디서 직접 받나 |
|---|---|
| Xcode Command Line Tools | `xcode-select --install` 다이얼로그 |
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| Ollama (선택) | https://ollama.com/download |
| openclaw-workspace | `git clone …` 또는 GitHub Releases tarball |
| OpenClaw 본체 | `git clone https://github.com/openclaw/openclaw.git` |

전체 단계·명령·예시 출력은 → **[docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md)**

수동 설치 후에도 마지막에는 동일한 명령으로 검증·운영합니다:

```bash
cd openclaw-workspace/openclaw-mgr
./openclaw doctor      # 진단
./openclaw install     # 누락된 부분만 자동 보충 (수동으로 다 깔았다면 거의 다 skip)
./openclaw start       # 컨테이너 기동
```

---

## 🤖 자동화 3종 — 한눈 카탈로그

> **⚠️ 세팅 먼저, 사용은 그 다음.** 아래 세 명령은 모두 *해당 setup 스크립트를 한 번 실행한 후* 쓸 수 있습니다. 로그인이 필요한 도구(나노바나나 / Figma / 미리캔버스 / CapCut)는 setup 이후 한 번만 `*-login` 명령으로 세션을 잡아두면 됨.

| 명령 | 무엇을 하나 | 1회 세팅 → 로그인 → 사용 | 가이드 |
|---|---|---|---|
| 🌐 `surf "..."` | 웹에서 코스피·뉴스·논문 등 검색 → 마크다운 브리프 (1회용 Docker 샌드박스 안에서) | `bash scripts/surf-setup.sh` → (로그인 불필요) → `surf "..."` | [GUIDE-WEB-FETCH.md §8](docs/GUIDE-WEB-FETCH.md#8--샌드박스-자동-브리프--surf-명령) |
| 🎨 `creative run "..."` | Pinterest → 나노바나나(4창 병렬) → Figma 디자인 자동 배치 | `bash scripts/creative-pipeline-setup.sh` → `creative banana-login` `creative figma-login` → `creative run "..."` | [GUIDE-CREATIVE-PIPELINE.md](docs/GUIDE-CREATIVE-PIPELINE.md) |
| 🎬 `shorts run "..."` | Pinterest → 미리캔버스(1080×1920) → CapCut(9:16 MP4 export) | `bash scripts/shorts-setup.sh` → `shorts miri-login` `shorts capcut-login` → `shorts run "..."` | [GUIDE-SHORTS-PIPELINE.md](docs/GUIDE-SHORTS-PIPELINE.md) |

**공통 흐름:**

```bash
# 1단계 — 세팅 (며등, 따라서 여러 번 실행해도 안전)
#   brew 의존성 설치, Python venv 생성, Playwright Chromium 다운로드,
#   ~/openclaw-{surf,creative,shorts}/ 생성, ~/bin/<명령> 심볼링
bash scripts/surf-setup.sh
bash scripts/creative-pipeline-setup.sh
bash scripts/shorts-setup.sh

# 2단계 — 로그인 (계정마다 딱 1번・창 뜨면 사람이 로그인 후 닫기)
creative banana-login        # Gemini / nano-banana
creative figma-login         # Figma
shorts miri-login            # 미리캔버스
shorts capcut-login          # CapCut Web
# (surf 는 로그인 불필요 — RSS·공개 페이지만 수집)

# 3단계 — 이제부터는 이 명령만
surf     "오늘 코스피 종가와 거래대금"
creative run "동남아시아 풍경 일러스트"
shorts   run "여행 감성 풍경"
```

> 모든 자동화는 **호스트 영구 프로필** 방식 — OpenClaw 본 컨테이너는 `isolated` 그대로, 호스트 `~/.ssh`·OpenClaw `.env` 접근 0. 각 가이드의 "샌드박스 경계" 섹션 참조.

## 📚 문서 가이드

> 어떤 문서부터 봐야 할지 모르겠다면 아래 표를 참고하세요. 한국어/영어 모두 완비.

| 누구 | 어디부터 | 무엇이 있나 |
|---|---|---|
| 🌱 **진짜 처음부터 (폴더 만들기·`pwd`·`cd` 부터)** | [docs/GUIDE-FROM-ZERO.md](docs/GUIDE-FROM-ZERO.md) | **−1단계: 클릭/더블클릭/우클릭 차이, GUI vs CLI, 창·메뉴바·Dock, 파일·폴더·경로** 부터 시작 → 터미널 열기 → 5개 핵심 명령 → 한 줄 설치. KO+EN 병기 |
| 🪜 **완전 수동 설치 (공식 사이트에서 직접 다운)** | [docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md) | brew/스크립트 없이 Docker·Ollama·소스 직접 다운. 회사 IT 심사·GitHub 502 회피용. KO+EN 병기 |
| 🆕 **처음 보는 사람 / 터미널 처음** | [docs/QUICKSTART-ko.md](docs/QUICKSTART-ko.md) | 터미널 여는 법부터 단계별로, 예시 출력 포함 |
| 🇬🇧 **English first-timer** | [docs/QUICKSTART-en.md](docs/QUICKSTART-en.md) | Same as above, in English |
| 📖 **단어가 낯설면 (Ollama · Docker · OpenClaw)** | [docs/GUIDE-OLLAMA.md](docs/GUIDE-OLLAMA.md) · [docs/GUIDE-DOCKER.md](docs/GUIDE-DOCKER.md) · [docs/GUIDE-OPENCLAW.md](docs/GUIDE-OPENCLAW.md) | 3분용 기초 가이드 3편 (구조·용어·철학) — KO+EN 병기 |
| 🌐 **웹에서 코스피·뉴스·환율 가져오기** | [docs/GUIDE-WEB-FETCH.md](docs/GUIDE-WEB-FETCH.md) | 네트워크 토글 사이클·실전 프롬프트·공식 API 키·자동화·트러블슈팅. **`surf` 명령으로 샌드박스 도커 안에서 검색 → 마크다운 도구 포함**. KO+EN 병기 |
| 🎨 **디자이너 워크플로우 자동화 (Pinterest → 나노바나나 → Figma)** | [docs/GUIDE-CREATIVE-PIPELINE.md](docs/GUIDE-CREATIVE-PIPELINE.md) | 4단계 수작업 → 1명령. 나노바나나 4창 병렬로 속도 ~3.7×. KO+EN 병기 |
| 🎬 **쇼츠 자동화 (Pinterest → 미리캔버스 → CapCut)** | [docs/GUIDE-SHORTS-PIPELINE.md](docs/GUIDE-SHORTS-PIPELINE.md) | `shorts run "키워드"` 으로 레퍼런스·1080×1920 디자인·9:16 영상 export. 샌드박스 경계 유지 + 프로그램 설치 안내 포함. KO+EN |
| 👤 **일반 사용자** | [README.md](README.md) (이 문서) | 명령 카탈로그·`.env`·네트워크 격리·FAQ |
| 🇬🇧 **General user (EN)** | [README.en.md](README.en.md) | Full English equivalent of this README |
| 🩺 **진단 항목별 상세 가이드** | [docs/TROUBLESHOOTING.md — doctor 상세 항목별 가이드](docs/TROUBLESHOOTING.md#doctor-항목별-상세-가이드) | OS · RAM · 디스크 · Xcode CLT · Docker 데몬 · 포트 충돌 · compose 보안 경고(`docker.sock`) 각각에 대한 의미·자동·수동 해결 |
| 🚑 **문제가 생겼을 때** | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 흔한 오류·해결 명령 (KO+EN 병기) |
| 🛡 **보안이 궁금한 사람** | [SECURITY.md](SECURITY.md) · 본문 [🔒 보안 주의](#-보안-주의-꼭-읽으세요) · [🔒 네트워크 격리](#-네트워크-격리-모드-명시적-외부-차단-토글) | 위협 모델·취약점 신고 절차 |
| 🧠 **내부 동작 알고 싶음** | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 디스패처·멱등 설계·compose override (KO+EN 병기) |
| 🤝 **기여하고 싶음 (처음)** | [docs/GUIDE-CONTRIBUTING.md](docs/GUIDE-CONTRIBUTING.md) | 비개발자도 환영 — 오타·번역·베타테스트도 기여 |
| 🐙 **기여하고 싶음 (코드)** | [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | 코드 스타일·PR 절차 (KO+EN 병기) |
| 📦 **릴리스 내역** | [docs/RELEASE_NOTES_v0.1.0.md](docs/RELEASE_NOTES_v0.1.0.md) | 변경 사항 (KO+EN 병기) |

---

## 🤔 이게 뭐예요?

[**OpenClaw**](https://clawbro.ai)는 사용자 PC에서 셸 명령어 실행·파일 시스템 접근·웹 탐색을 직접 수행할 수 있는 강력한 오픈소스 AI 에이전트입니다. 강력한 만큼 보안이 중요해서, **반드시 Docker 같은 격리된 환경(샌드박스)** 에서 실행해야 합니다.

이 프로젝트는 그 셋업을 **새 맥북에서 한 번에** 끝낼 수 있게 해주는 도구입니다.

| 이 도구가 해주는 것 | 이 도구가 안 하는 것 |
|---|---|
| Docker · Ollama · Homebrew(필요 시) 자동 설치 (스크립트) | OpenClaw 자체 개발/수정 |
| OpenClaw 저장소 clone & 컨테이너 기동 | 클라우드 호스팅 (그건 [ClawBro.ai](https://clawbro.ai)) |
| 매일 자동 업데이트 (launchd) | Windows / Linux 지원 |
| 백업·복원·완전 제거 | 멀티 인스턴스 동시 운영 |
| 보안 하드닝 (read-only, cap_drop, 127.0.0.1만 바인딩 등) | OpenClaw 의 채널 연동 (Telegram 등) |

---

## 📋 명령 카탈로그

| 명령 | 한 줄 설명 |
|---|---|
| `./openclaw` (또는 `menu`) | 대화형 메뉴 (한국어/영어 자동) — 모든 작업을 번호로 선택 |
| `./openclaw doctor` | 현재 시스템/설치 상태 점검 (✓/✗/⚠ 표) |
| `./openclaw install` | 부족한 부분만 자동 설치. 중간에 끊겨도 이어서 진행 |
| `./openclaw start` | 컨테이너 시작 |
| `./openclaw stop` | 컨테이너 정지 (데이터 보존) |
| `./openclaw logs [service]` | 컨테이너 로그 실시간 보기 (시크릿 자동 마스킹) |
| `./openclaw update` | 코드 pull + 이미지 갱신 + Ollama 모델 갱신 |
| `./openclaw backup [--name N]` | 볼륨+`.env` 백업 (sha256, 선택적 GPG 암호화) |
| `./openclaw restore <file>` | 백업 파일에서 안전 복원 (체크섬·미리보기 검증) |
| `./openclaw schedule enable\|disable\|status` | 매일 자동 업데이트 launchd 등록/해제 |
| `./openclaw network status\|isolated\|online` | 외부 인터넷 차단 토글 (기본: isolated) |
| `./openclaw models list\|add\|remove\|pull\|suggest` | 로컬 LLM 모델 관리 (·env 자동 수정) |
| `./openclaw clean [--light\|--all\|--status]` | 메모리·디스크 정리 (비개발자용 대화형) |
| `./openclaw uninstall [--purge]` | OpenClaw 제거. `--purge` 면 Docker/Ollama까지 |

---

---

## 🩺 진단 / `doctor` 항목별 가이드

`./openclaw doctor` 는 설치 전·후 언제든 안전하게 돌리는 명령입니다. 한 번에 모든 항목을 `✓ / ✗ / ⚠` 로 보여주며, **부족한 항목은 거의 모두 `./openclaw install` 이 자동으로 채워줍니다**.

다만 각 항목이 무슨 뜻이고, **자동으로 뭐를 하고**, **수동으로 고친다면 어떻게 하는지**, **자주 생기는 문제는 무엇인지** 는 따로 정리되어 있습니다. 항목 이름을 클릭하세요 — [TROUBLESHOOTING — doctor 항목별 상세 가이드](docs/TROUBLESHOOTING.md#doctor-항목별-상세-가이드) 으로 갑니다.

| 항목 | 일반적 상태 | 자동 해결 | 수동/문제 시 가이드 |
|---|---|---|---|
| OS / CPU / RAM / 디스크 | 하드웨어 설명·최소 권장치 | — (하드웨어) | [하드웨어 요구](docs/TROUBLESHOOTING.md#os--cpu--ram--디스크) |
| Xcode CLT | git · 컴파일러 도구 | ✓ `install` 이 설치 다이얼로그 호출 | [Xcode CLT](docs/TROUBLESHOOTING.md#xcode-command-line-tools) |
| Homebrew | macOS 패키지 매니저 | ✓ `install` 이 공식 스크립트 실행 | [Homebrew](docs/TROUBLESHOOTING.md#homebrew) |
| Docker / Compose v2 | 샌드박스 런타임 | ✓ `install` 이 Docker Desktop 설치 + 실행 | [Docker 설치/첫 실행](docs/TROUBLESHOOTING.md#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) |
| Docker 데몬 ✗ | Docker Desktop 앱이 꺼져 있음 | ⚠ `install` 이 앱을 엽니다 (첫 실행 시 일회성 시스템 비밀번호 필요) | [Docker 데몬 ✗](docs/TROUBLESHOOTING.md#docker-데몬-✗) |
| Ollama / Ollama 데몬 / 모델 | 로컬 LLM 서비스 | ✓ `install` 이 설치 + `brew services start` | [Ollama](docs/TROUBLESHOOTING.md#ollama--데몬--모델) |
| OpenClaw 저장소 | 에이전트 본체 소스 | ✓ `install` 이 git clone (존재하면 pull) | [OpenClaw 저장소](docs/TROUBLESHOOTING.md#openclaw-저장소) |
| 컨테이너 실행 0개 | 에이전트가 마지막 종료 상태 | `./openclaw start` | [컨테이너 0개](docs/TROUBLESHOOTING.md#컨테이너-실행-0개) |
| ⚠ **포트 충돌 11434** | 다른 Ollama/동일 포트 프로세스 | — (수동 확인 필요) | [포트 충돌 11434](docs/TROUBLESHOOTING.md#포트-충돌-11434) |
| ⚠ 자동 업데이트 | launchd 미등록 | `./openclaw schedule enable` (선택) | [스케줄](docs/TROUBLESHOOTING.md#자동-업데이트-스케줄) |
| ⚠ 네트워크 격리 | online (일시 허용) | `./openclaw network isolated --restart` | [네트워크 명시적 격리](#-네트워크-격리-모드-명시적-외부-차단-토글) |
| 한국 소버린 AI | EXAONE · A.X · Solar 감지 | — (자동 감지만) | [한국 소버린 AI](#-한국-소버린-ai-와-함께-쓰기) |

### 설치 중 멈춘 시 — 단계별 장애 가이드

`./openclaw install` 은 멱등 설계라 중단되어도 **같은 명령을 다시 치면 마지막 실패 단계부터 이어서** 진행됩니다. 이어서도 계속 실패하는 경우:

| 실패 단계 | 일반적 원인 | 가이드 |
|---|---|---|
| `xcode_clt` | 애플 서버 일시 장애 / OS 너무 옛 버전 | [Xcode CLT](docs/TROUBLESHOOTING.md#xcode-command-line-tools) |
| `brew` | Homebrew 설치 스크립트 다운로드 실패 (회사 프록시) | [Homebrew](docs/TROUBLESHOOTING.md#homebrew) |
| `docker_install` / `docker_start` | 데몬 멈춤 · Rosetta · 약관 동의 | [Docker 첫 실행](docs/TROUBLESHOOTING.md#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) |
| `ollama_install` / `ollama_start` | brew services 권한 또는 포트 충돌 | [Ollama](docs/TROUBLESHOOTING.md#ollama--데몬--모델) · [포트 충돌 11434](docs/TROUBLESHOOTING.md#포트-충돌-11434) |
| `repo_clone` | GitHub 502 / 사내 프록시 | [GitHub 502 우회](docs/TROUBLESHOOTING.md#brew-install-중-curl-56--error-502--github-502-bad-gateway) · [완전 수동](docs/GUIDE-MANUAL-INSTALL.md) |
| ✗ **`compose_scan`** — "`/var/run/docker.sock` 마운트 발견" | OpenClaw fork 가 호스트 Docker 명령권을 요구 | [compose 보안 경고](docs/TROUBLESHOOTING.md#compose-보안-경고--varrundockersock) |
| `env_merge` | 존재하는 `.env` 권한 | [.env 병합 실패](docs/TROUBLESHOOTING.md#env-병합-실패) |
| `compose_up` | 포트 점유 / 이미지 pull 실패 / 디스크 부족 | [compose up 실패](docs/TROUBLESHOOTING.md#compose-up-실패) |
| `health` | 컨테이너는 떴는데 초기화가 오래 걸림 | [헬스체크 실패](docs/TROUBLESHOOTING.md#헬스체크-실패) |

특정 단계만 다시 돌리려면 상태 파일에서 해당 줄을 지웁니다:

```bash
# 예: docker_start 만 다시
sed -i '' '/^docker_start=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

---

## 🔄 업데이트 흐름

두 종류의 업데이트가 있습니다 — **워크스페이스 자체** 와 **OpenClaw 컨테이너·이미지·모델**.

```bash
# 1) 이 런처 자체 갱신 (이 저장소의 코드)
./openclaw self-update

# 2) OpenClaw 코드 + Docker 이미지 + Ollama 모델 갱신
./openclaw update
#   ├ 필요한 동안만 자동으로 isolated → online 으로 전환
#   └ 완료 후 원래 모드로 복귀

# 3) 매일 새벽 자동 돌아가게 (선택)
./openclaw schedule enable
./openclaw schedule status   # 다음 실행 시각 확인
./openclaw schedule disable  # 해제
```

업데이트 전에는 백업 한 번을 권장합니다:

```bash
./openclaw backup --name before-update
./openclaw update
# 문제 시:
./openclaw restore ~/openclaw-backups/openclaw-...-before-update.tar.gz
```

launchd 스케줄이 안 돌 때의 진단은 [TROUBLESHOOTING — 자동 업데이트 스케줄](docs/TROUBLESHOOTING.md#자동-업데이트-스케줄) 참조.

### 다른 컴퓨터에서 최신 받고 재설치 (이미 한 번 설치한 머신)

```bash
cd ~/DEV/openclawAgent/openclaw-workspace        # 첫 설치 시 사용한 경로
git pull --ff-only origin main                    # 또는 ./openclaw-mgr/openclaw self-update
sed -i '' '/^compose_up=done$/d' ~/.openclaw-mgr/state   # 막힌 단계 마커만 리셋
cd openclaw-mgr && ./openclaw install             # 끝난 단계는 자동 스킵
./openclaw doctor                                 # 정상 동작 확인
```

처음부터 다시 깨끗이 하려면 `rm ~/.openclaw-mgr/state` 후 `./openclaw install`.

**`git pull` 후 무엇을 다시 돌릴지** 변경 종류별 가이드와 14개 단계 마커 전체 목록은 [GUIDE-MANUAL-INSTALL — 7.2 git pull 후 무엇을 다시 해야 하나](docs/GUIDE-MANUAL-INSTALL.md#72-git-pull-후-무엇을-다시-해야-하나-변경-종류별) 참조. 자주 쓰는 마커 리셋 한 줄 모음은 [7.4 절](docs/GUIDE-MANUAL-INSTALL.md#74-자주-쓰는-마커-리셋-한-줄-모음).

---

## 🤖 모델 관리 — 내 로컬 Ollama 모델 그대로 쓰기

> **핵심**: OpenClaw 의 컨테이너는 호스트의 Ollama (`host.docker.internal:11434`) 를 공유합니다. **이미 `ollama pull` 로 받아둔 모델은 재설치 필요 없으며**, 아래 목록이 그리는 그대로 동작합니다.

```
사용자 PC                                          OpenClaw 컨테이너
┌──────────────────────────────┐                  ┌──────────────────────┐
│ ollama list                  │   <─── 같은 ───> │ host.docker.internal │
│  • solar-pro                 │      Ollama      │      :11434          │
│  • exaone4.0                 │      서비스       │   (이 모델들 그대로  │
│  • qwen2.5-coder:7b          │                  │    사용 가능)        │
└──────────────────────────────┘                  └──────────────────────┘
```

### 비개발자 모드 (한 줄 명령)

```bash
openclaw models                  # 현재 .env 목록 + 로컬 설치된 모델 모두 보기
openclaw models suggest          # 24GB 맥용 추천 모델 목록
openclaw models add llama3.1:8b  # .env 에 추가 + 자동 pull
openclaw models remove llama3.1:8b           # .env 에서 빼기 (모델 파일은 남김)
openclaw models remove llama3.1:8b --purge   # 모델 파일까지 삭제
openclaw models pull llava:7b    # .env 건들지 않고 pull 만
```

메뉴에서는 **14번** "모델 목록·추가". `.env` 파일을 직접 열 필요 없습니다.

### 개발자 모드 (직접 편집 또는 호스트 명령)

세 가지 메커니즘 중 아무거나:

1. **`.env` 직접 편집** → `openclaw update` (컨테이너도 같이 갱신)
   ```bash
   $EDITOR ~/.openclaw-mgr/.env   # OLLAMA_MODELS="qwen2.5-coder:7b,llama3.1:8b"
   openclaw update
   ```
2. **호스트에서 그냥 `ollama pull`** — OpenClaw 는 별도 설정 없이 즉시 사용 가능 (UI 에서 모델 선택)
   ```bash
   ollama pull qwen2.5:14b
   ```
3. **`openclaw models add ... --no-pull`** — 명단에만 등록하고 다음번 update 때 받기

### ⚠️ isolated 모드 주의

기본값 `isolated` 에서는 **호스트 Ollama 도 차단** 됩니다 (컨테이너→외부 완전 차단). 로컬 LLM 을 쓰려면:

```bash
openclaw network online --restart    # 일시 허용
# 작업…
openclaw network isolated --restart   # 다시 잠그기 (항상 이 상태 권장)
```

> 💡 참고: `openclaw update` 는 필요한 동안만 **자동으로** online 으로 전환하고 끝나면 원래 모드로 복귀합니다. `openclaw models add` 의 `ollama pull` 은 호스트에서 돌아 컨테이너 네트워크 토글한 필요 없습니다 (호스트 인터넷만 필요).

---

## ⚙️ 설정 (`.env`)

`.env.example` 의 모든 변수에 주석이 달려 있습니다. 핵심:

```bash
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"  # 공식 URL
OPENCLAW_DIR="$HOME/openclaw"                             # 클론 위치
OPENCLAW_PORT="8000"                                      # 항상 127.0.0.1 만
ENABLE_OLLAMA="1"                                         # 0=외부 API만 사용
OLLAMA_MODELS="qwen2.5-coder:7b"                          # 콤마 구분
OPENCLAW_PIN_COMMIT=""                                    # 보안: 특정 커밋 고정
SCHEDULE_TIME="03:00"                                     # 자동 업데이트 시각
BACKUP_DIR="$HOME/openclaw-backups"
BACKUP_KEEP="7"                                           # 오래된 것 자동 삭제
BACKUP_ENCRYPT="1"                                        # .env GPG 암호화
```

---

## 💻 셸 호환성 (zsh / bash)

맥에서 기본 셸은 **zsh** 입니다. 이 도구는 모든 스크립트가 `#!/usr/bin/env bash` 로 시작해 항상 bash 로 실행되므로, **zsh 사용자가 그대로 써도 100% 호환** 됩니다.

```zsh
# zsh 에서도 동일하게:
./openclaw doctor
./openclaw install
```

수동으로 라이브러리 함수를 셸에 불러올 일은 없으니 `source` / `.` 호환은 신경쓰지 않아도 됩니다.

---

## 🇰🇷 한국 소버린 AI 와 함께 쓰기

같은 메인테이너의 자매 프로젝트 [**korea-sovereign-ai**](https://github.com/GoGoComputer/korea-sovereign-ai) (LG EXAONE / SKT A.X / Upstage Solar) 와 **자연 호환** 됩니다. 둘 다 호스트 Ollama 를 공유하기 때문에 한 번 깔아두면 OpenClaw 가 그 모델들을 그대로 쓸 수 있습니다.

```bash
# 한국 소버린 AI 먼저 깔기 (선택)
git clone https://github.com/GoGoComputer/korea-sovereign-ai.git ~/DEV/llmDev/korea-ai
cd ~/DEV/llmDev/korea-ai && ./install.sh --minimal     # EXAONE + A.X (~5GB)

# 그 다음 OpenClaw 에서 한 줄로 등록 (·env 자동 수정):
openclaw models add exaone3.5:7.8b solar-pro:22b
```

`./openclaw doctor` 가 자동으로 한국 모델을 감지해 `한국 소버린 AI: ✓` 로 표시합니다. 메모리는 24GB 에서 동시 1개 모델만 로드하는 걸 권장합니다 (`./openclaw clean` 으로 다른 모델 언로드 가능).

---

## 🧹 메모리·디스크 정리 (비개발자용)

Docker 와 Ollama 는 시간이 갈수록 디스크와 메모리를 많이 차지할 수 있습니다. 한 줄 명령으로 정리:

```bash
./openclaw clean --status   # 현재 사용량만 보고
./openclaw clean            # 대화형 — 단계마다 y/n 묻기 (안전)
./openclaw clean --light    # 캐시·정지 컨테이너만 (빠름·안전)
./openclaw clean --all      # 강함: 미사용 이미지·모델 삭제 + macOS 메모리 압축
```

`--all` 모드는 `sudo purge` (macOS 통합메모리 압축)를 실행할 때만 비밀번호를 한 번 묻습니다. 데이터(볼륨·`.env`·백업)는 절대 건드리지 않습니다.

---

## 🔒 네트워크 격리 모드 (명시적 외부 차단 토글)

**완전 차단이 기본값** 입니다. 설치/업데이트 때만 잠깐 열어서 쓰세요.

```bash
./openclaw network status                  # 현재 모드 보기
./openclaw network online --restart        # 일시적으로 열기 (설치/업데이트용)
./openclaw network isolated --restart      # 다시 잠그기 ← 항상 이 상태로 둘 것
```

| 모드 | 아웃바운드(컨테이너→외부) | 웹UI(127.0.0.1) | host Ollama | 언제 쓰나 |
|---|---|---|---|---|
| **`isolated`** 🔒 (기본) | 완전 차단 | 접속 ✓ | 연결 안됨 | 평소, 실제 작업 시 — 난리 시에도 안전 |
| **`online`** 🌐 | 허용 | 접속 ✓ | 연결 ✓ | 설치/업데이트/모델 다운로드 잠깐만 |

### 🔒 isolated (기본) 에서 **막히는** 것
- **컨테이너 안에서 외부 DNS / 외부 IP 로 나가는 모든 통신**.
- 이 때문에 다음이 안 됩니다 — 허용하려면 `online` 으로 잠깐 전환:
  - `pip install <패키지>`, `npm install`, `apt-get update`
  - `git clone https://github.com/...` 등 GitHub·GitLab 다운로드
  - Hugging Face / pypi / docker registry 다운로드
  - **호스트의 Ollama** 호출 (`host.docker.internal:11434`) — isolated 에서는 차단됩니다.
  - **외부로의 데이터 유출 시도** (악성 주입·제로데이 이메일 프롬프트 등) 도 자동으로 차단.

### 어떤 상황에서 유용한가요?
- **궁극 보안**: AI 에이전트가 웹을 돌아다니며 코드/패키지를 다운로드해 실행할 때 악성 패키지/익스플로잇을 **가져오는 경로 자체를 막아 버립니다**.
- **데이터 유출 공격 대비**: 프롬프트 인젝션으로 "내 파일을 X 주소로 보내" 라는 시도가 있어도 네트워크 자체가 없으니 **나갈 수 있는 통로가 물리적으로 없는 상태**.
- **공공 Wi-Fi**: 카페·공항 와이파이에 접속해서도 외부 서버↔컨테이너가 온전히 차단되어 있으니 안전.

### 설치/업데이트용 표준 워크플로우
```bash
./openclaw network online --restart    # 잠깐 열고
./openclaw update                       # 업데이트
./openclaw network isolated --restart   # 곧장 다시 잠그기
```

> `./openclaw update` 는 이 과정을 **자동으로** 처리합니다 (잠깐 online→완료 후 이전 모드로 복귀).

---

## 🔒 보안 주의 (꼭 읽으세요)

OpenClaw 에이전트는 **셸과 파일을 직접 만지는 권한**을 가집니다. 안전하게 쓰려면:

1. **샌드박스(Docker)를 절대 우회하지 마세요.** 호스트에 직접 설치하면 안 됩니다.
2. **민감한 폴더를 마운트 금지** — 다음 폴더는 절대 컨테이너에 `:rw` 로 노출하지 마세요:
   - `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.config`, `~/Library`, `/etc`, `/var`, `/usr`
3. **`.env` 를 커밋하지 마세요.** `.gitignore` 에 이미 들어 있습니다. 만약 실수로 올렸다면 즉시 키를 회전하세요.
4. **`OLLAMA_HOST=0.0.0.0` 사용 금지** — Mac 에서는 `host.docker.internal` 로 충분합니다. 0.0.0.0 은 LAN/공용 Wi-Fi에서 모델을 노출시킵니다.
5. **`OPENCLAW_PIN_COMMIT` 권장** — 검증된 커밋으로 핀하면 공급망 공격에 강해집니다.
6. **외부 노출은 모두 `127.0.0.1`** 만 — `compose.security.yml` 이 강제합니다.
7. **백업의 `.env`** 는 GPG 대칭키로 암호화됩니다 (`BACKUP_ENCRYPT=1`).
8. **취약점 발견 시** 공개 이슈 대신 [SECURITY.md](SECURITY.md) 절차를 따라주세요.

자세한 위협 모델과 컨테이너 하드닝 옵션은 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 를 참조하세요.

---

## ❓ FAQ

<details>
<summary><b>Docker Desktop 이 안 켜져요</b></summary>

`./openclaw install` 이 자동으로 `open -a "Docker"` 를 실행하지만, 첫 실행 시 약관 동의가 필요합니다. 동의 후 다시 `./openclaw install` 하면 이어서 진행됩니다.
</details>

<details>
<summary><b>포트 11434 가 이미 사용 중이래요</b></summary>

다른 Ollama 인스턴스가 떠 있을 수 있습니다.
```bash
lsof -nP -iTCP:11434 -sTCP:LISTEN
brew services restart ollama
```
</details>

<details>
<summary><b>다른 Ollama 모델로 바꾸려면?</b></summary>

가장 간단: `openclaw models add <이름>` (·env 자동 수정 + pull). 이미 로컬에 있는 모델은 `openclaw models` 로 모두 확인. 추천 목록은 `openclaw models suggest`. 수동으로 하고 싶으면 `.env` 의 `OLLAMA_MODELS` 편집 후 `./openclaw update`. 24GB RAM 에서는 7~8B 추천, 13B 이상은 자동 경고.
</details>

<details>
<summary><b>백업은 어디에 저장되나요?</b></summary>

`~/openclaw-backups/openclaw-YYYYmmdd-HHMMSS-<name>.tar.gz` (그리고 `.sha256`). 위치는 `.env` 의 `BACKUP_DIR` 로 변경 가능. 보관 개수는 `BACKUP_KEEP` (기본 7개).
</details>

<details>
<summary><b>완전히 지우고 싶어요</b></summary>

```bash
./openclaw backup --name before-uninstall   # 안전을 위해
./openclaw uninstall --purge                # Docker/Ollama 까지 제거
```
</details>

<details>
<summary><b>설치를 중간에 멈췄는데 다시 시작하면?</b></summary>

`./openclaw install` 을 다시 실행하세요. 이미 끝난 단계는 `[skip]` 로 표시되고 남은 단계만 진행합니다. (상태 파일: `~/.openclaw-mgr/state`)
</details>

<details>
<summary><b>맥북이 느려졌어요 / 메모리가 가득 찼어요</b></summary>

```bash
./openclaw clean --status   # 무엇이 얼마나 차지하는지 보기
./openclaw clean            # 단계별 y/n 으로 안전하게 정리
```
Docker/Ollama 가 시간이 갈수록 캐시·이미지를 쌓습니다. 위 명령은 데이터(볼륨·.env·백업)는 절대 건드리지 않고 캐시·미사용 이미지만 청소합니다.
</details>

<details>
<summary><b>한국어 LLM(EXAONE/A.X/Solar)도 같이 쓸 수 있나요?</b></summary>

네. [korea-sovereign-ai](https://github.com/GoGoComputer/korea-sovereign-ai) 를 먼저 깔면 호스트 Ollama 에 한국 모델들이 등록되고, OpenClaw 가 `host.docker.internal:11434` 로 그대로 사용합니다. `./openclaw doctor` 가 자동 감지합니다.

⚠ 단, 기본 `isolated` 모드에서는 host Ollama 도 차단됩니다. 한국 모델을 쓰려면 `./openclaw network online --restart` 로 잠깐 열어야 합니다.
</details>

<details>
<summary><b>OpenClaw 가 제 컴퓨터의 어디까지 접근하나요? 이 폴더 안에서만 동작하나요?</b></summary>

**기본적으로 컨테이너(Docker) 안에서만** 동작하며, 호스트(맥북) 의 파일을 직접 건드리지 못합니다.

| 무엇 | 접근 가능? |
|---|---|
| 컨테이너 내부 파일시스템 | ✅ (read-only 루트 + `/tmp` tmpfs) |
| Docker 볼륨 (백업·세션 데이터) | ✅ |
| 호스트의 `~/Documents`, `~/.ssh`, `~/Library` 등 | ❌ (마운트 안 함) |
| 호스트 USB·외장 디스크 | ❌ |
| 호스트의 다른 앱 (브라우저 쿠키 등) | ❌ |
| 외부 인터넷 | ❌ (`isolated` 모드 — 기본값) / ✅ (`online`) |

**즉, 사용자가 의도적으로 폴더를 마운트해 주지 않는 한** OpenClaw 는 자기 컨테이너 박스 안에서만 일합니다. 폴더를 공유하고 싶으면 OpenClaw 의 base `docker-compose.yml` 에 `volumes:` 항목을 직접 추가하세요. (보안상 `~/Desktop/openclaw-share` 같은 전용 폴더 권장)
</details>

<details>
<summary><b>AI 가 인터넷에서 악성 코드를 다운로드해서 실행할 수 있나요?</b></summary>

**기본 `isolated` 모드에서는 불가능합니다.** Docker 네트워크 자체를 `internal: true` 로 만들어 컨테이너에서 외부로 나가는 모든 패킷이 막힙니다. DNS 도 막혀 도메인 해석조차 안 됩니다.

`pip install`, `npm install`, `git clone https://...`, Hugging Face 다운로드 모두 차단됩니다. 잠깐 필요할 때만 `./openclaw network online --restart` 로 여세요.
</details>

<details>
<summary><b>AI 가 제 데이터를 외부로 빼돌릴 수 있나요?</b></summary>

**기본 `isolated` 모드에서는 불가능합니다.** 외부로 나가는 통로 자체가 없으니, 프롬프트 인젝션 등으로 "이 파일 내용을 X 서버로 보내" 라는 지시가 들어와도 실행 불가합니다.

추가 방어:
- 로그 출력 시 자동 비밀 마스킹 (`./openclaw logs`)
- 백업의 `.env` 는 GPG 암호화
- 모든 포트는 `127.0.0.1` 바인딩 (LAN 노출 안 함)
</details>

<details>
<summary><b>AI 가 제 파일을 지우거나 수정할 수 있나요?</b></summary>

호스트 파일은 못 건드립니다 (위 폴더 접근 표 참조). 컨테이너 안의 파일만 수정 가능하며, 컨테이너의 루트 파일시스템도 `read_only: true` 로 잠겨 있어 임시 파일은 `/tmp` (tmpfs, 재시작 시 삭제) 에만 쓸 수 있습니다.

영구 데이터는 Docker 볼륨에 저장되며, `./openclaw backup` 으로 언제든 복구 가능합니다.
</details>

<details>
<summary><b>스크립트가 제 시스템을 마음대로 바꾸나요? 안전한가요?</b></summary>

설치/삭제 동작은 모두 **사용자 확인 후** 진행되며, 스크립트가 하는 일은:
- Homebrew, Docker Desktop, Ollama 설치 (공식 채널)
- `~/DEV/openclaw` 에 OpenClaw clone
- launchd 에 매일 update 스케줄 등록 (활성화 했을 때만)
- `~/.openclaw-mgr/` 에 상태 파일 저장

`sudo` 는 거의 쓰지 않으며, 쓰는 곳은 `clean --all` 의 `sudo purge` (메모리 압축, 표준 macOS 명령) 한 곳뿐입니다. 모든 소스가 공개돼 있고 50줄 안에 1번씩 주석으로 설명돼 있어 직접 읽어볼 수 있습니다.
</details>

<details>
<summary><b>Docker Desktop / Ollama 가 자동으로 켜지나요?</b></summary>

`./openclaw start` 가 Docker Desktop 을 자동 실행합니다 (`open -a Docker`). Ollama 는 Homebrew 서비스로 등록돼 부팅 시 자동 시작합니다 (`brew services start ollama`).
</details>

<details>
<summary><b>Wi-Fi 가 끊겨도 OpenClaw 가 동작하나요?</b></summary>

`isolated` 모드에서는 어차피 인터넷을 안 쓰므로 **완전히 정상 동작** 합니다 (이미 깔린 모델·코드만 사용). `online` 모드일 때 Wi-Fi 가 끊기면 외부 API 호출만 실패하고 나머지는 동작합니다.
</details>

<details>
<summary><b>여러 사람이 같은 맥에서 쓸 수 있나요?</b></summary>

각자 다른 macOS 사용자 계정으로 로그인해 따로 설치하는 걸 권장합니다 (`OPENCLAW_DIR`, `BACKUP_DIR` 가 `$HOME` 기준이므로 자연스럽게 분리). 같은 계정 내 멀티 인스턴스는 현재 미지원입니다.
</details>

<details>
<summary><b>업그레이드하다 깨지면 어떡하죠?</b></summary>

```bash
./openclaw backup --name before-upgrade   # 항상 먼저 백업
./openclaw update
# 문제 시:
./openclaw restore ~/openclaw-backups/openclaw-...-before-upgrade.tar.gz
```
`update` 는 `git pull --ff-only` 만 사용해 강제 머지가 없고, 실패해도 데이터(볼륨) 는 그대로입니다.
</details>

<details>
<summary><b>회사 보안 정책으로 외부 통신이 일부 차단된 환경에서도 되나요?</b></summary>

`isolated` 모드는 어차피 외부 통신을 안 하므로 영향 없습니다. `install` / `update` 시점에만 인터넷이 필요한데, 사내 프록시가 있는 경우 셸 환경 변수 `HTTPS_PROXY`, `HTTP_PROXY` 가 docker / git / brew 에 자동 적용됩니다. 자체 서명 인증서가 필요하면 macOS 키체인에 등록하면 됩니다.
</details>

---

## 🛠 개발자용

### 디렉터리 구조

```
openclaw-mgr/
├── openclaw                # 단일 진입 디스패처 (서브커맨드 라우팅 + .env 로드)
├── .env.example            # 환경 변수 템플릿
├── compose.security.yml    # 보안 override (read_only, cap_drop, ...)
├── lib/
│   ├── common.sh           # 로그·확인·멱등 단계 관리 (run_step, state)
│   ├── sec.sh              # 입력 검증·시크릿 마스킹·위험 마운트 검사
│   ├── detect.sh           # 시스템 상태 KV 출력 (eval 가능)
│   └── prompt.sh           # 대화형 입력 헬퍼
├── cmd/
│   ├── doctor.sh           # 진단 (✓/✗/⚠)
│   ├── install.sh          # 멱등 설치 (이어서 진행)
│   ├── start.sh / stop.sh / logs.sh
│   ├── update.sh           # git pull --ff-only + compose 갱신
│   ├── backup.sh / restore.sh
│   ├── uninstall.sh        # --purge 옵션
│   └── schedule.sh         # launchd plist enable/disable/status
├── etc/
│   └── pre-commit.tmpl     # gitleaks 훅
└── docs/
    ├── QUICKSTART-ko.md
    ├── ARCHITECTURE.md
    ├── TROUBLESHOOTING.md
    └── CONTRIBUTING.md
```

### 멱등 설계 (`state` 파일 포맷)

`~/.openclaw-mgr/state` 는 한 줄에 `KEY=done` 형태로 누적됩니다.

```
xcode_clt=done
brew=done
docker_install=done
docker_start=done
ollama_install=done
ollama_start=done
ollama_models=done
repo_clone=done
compose_scan=done
env_merge=done
compose_up=done
health=done
```

`./openclaw install` 은 `state_has KEY` 검사 후 `done` 이면 단계를 건너뜁니다. 특정 단계만 다시 돌리려면 그 줄을 지우면 됩니다.

### 정적 검사

```bash
# Bash 문법 검사
find openclaw-mgr -name '*.sh' -exec bash -n {} \;
# 진입 스크립트
bash -n openclaw-mgr/openclaw

# shellcheck (brew install shellcheck)
shellcheck -S style openclaw-mgr/openclaw openclaw-mgr/lib/*.sh openclaw-mgr/cmd/*.sh

# shfmt (brew install shfmt)
shfmt -d -i 2 openclaw-mgr
```

### 기여하기

[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) 를 참조하세요.

### 자체 게시 (자기 fork 를 GitHub 에 올릴 때)

```bash
brew install gh
gh auth login
./scripts/publish.sh        # 메인 저장소 생성·푸시·토픽·v0.1.0 릴리스까지 자동
```

> Homebrew 탭 공식 배포는 현재 공식 경로에서 제외되었습니다. 설치는 스크립트 한 가지 경로로 통일되며, 완전 수동 경로([docs/GUIDE-MANUAL-INSTALL.md](docs/GUIDE-MANUAL-INSTALL.md))를 백업으로 제공합니다. `Formula/` 디렉토리와 `scripts/publish-tap.sh` 는 내부·실험을 위해 남겨두지만, 공식 안내에서는 `git clone` 경로만 권장합니다.

---

## 📜 라이선스

[MIT](LICENSE) © 2026 박성모 Park Sungmo

ClawBro / OpenClaw 상표 및 코드는 각 권리자의 자산입니다. 이 저장소는 어떤 공식 기관과도 제휴 관계가 없습니다.
