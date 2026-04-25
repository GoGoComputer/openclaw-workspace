# 🎨 크리에이티브 파이프라인 가이드 / Creative Pipeline Guide

> Pinterest(레퍼런스) → Claude(프롬프트) → 나노바나나(이미지) → Figma 워크플로우를 **한 명령**으로 묶고, 나노바나나 웹 UI 를 **여러 창 병렬**로 띄워 속도를 올립니다.

이 가이드는 OpenClaw 의 일부가 아닌 **개인 작업 자동화** 입니다. 별도 디렉터리(`~/openclaw-creative/`) 에서 동작하며, OpenClaw 컨테이너의 isolated 정책과 무관합니다.

## 📖 목차 / Contents

- [🇰🇷 한국어](#-한국어)
  - [전체 그림](#전체-그림)
  - [⚠️ 약관·계정 주의사항](#️-약관계정-주의사항)
  - [1. 한 번만: 환경 세팅](#1-한-번만-환경-세팅)
  - [2. Step 1 — Pinterest 레퍼런스 수집 (gallery-dl)](#2-step-1--pinterest-레퍼런스-수집-gallery-dl)
  - [3. Step 2 — 로컬 LLM 으로 프롬프트 자동 생성](#3-step-2--로컬-llm-으로-프롬프트-자동-생성)
  - [4. Step 3 — 나노바나나 N개 창 병렬 생성](#4-step-3--나노바나나-n개-창-병렬-생성)
  - [5. Step 4 — Figma 로 자동 업로드](#5-step-4--figma-로-자동-업로드)
  - [6. 한 줄로 다 돌리기 (`creative run`)](#6-한-줄로-다-돌리기-creative-run)
  - [7. 트러블슈팅](#7-트러블슈팅)
- [🇬🇧 English](#-english)

---

## 🇰🇷 한국어

### 전체 그림

```
[과거 — 4단계 수동]
  Pinterest 검색·저장 ──► Claude 채팅창에 붙여 프롬프트 만들기
       │                          │
       └────────────► 나노바나나 창 1개 → 생성 대기 → Figma 드래그

[지금 — 1 명령]
  creative run "사이버펑크 카페 인테리어, 12장"
        │
        ├─ gallery-dl   : Pinterest 검색·다운로드 (참고 5장)
        ├─ Ollama       : 참고 이미지 분석 → 12개 변주 프롬프트 자동 생성
        ├─ Playwright   : 나노바나나(gemini) 4창 병렬, 12개 작업 큐 분배
        └─ Figma API    : 결과 PNG 업로드 → 페이지에 그리드 배치
```

핵심 단축 포인트:

1. **레퍼런스 수집 = 자동** (gallery-dl 이 보드/검색어를 통째로 다운로드).
2. **프롬프트 = 로컬 LLM** (Ollama 의 `qwen2.5-vl:7b` 가 참고 이미지 보고, `qwen2.5-coder:7b` 가 변주 12개 작성. Claude 안 거쳐도 됨).
3. **이미지 생성 = 4창 병렬** (Chromium 프로필 4개를 영구 보존, 나노바나나 웹 UI 에 병렬 입력 → 직렬 대비 약 4배 빠름).
4. **Figma = REST API** (PNG 업로드 후 한 페이지에 자동 그리드 배치).

### ⚠️ 약관·계정 주의사항

이 워크플로우는 **공식 API 를 거치지 않고 사람이 브라우저에서 클릭하듯** 자동화합니다.

| 서비스 | 약관 입장 | 권장 강도 |
|---|---|---|
| Pinterest 다운로드 (`gallery-dl`) | 공개 콘텐츠 개인용 다운로드는 일반적으로 허용. 대량 자동화는 회색지대 | 개인 무드보드 용도면 OK |
| Gemini / AI Studio 웹 자동화 (나노바나나) | **공식적으로 권장되지 않음** — 약관에 "automated means" 제한 조항 존재 | 본인 계정으로 소량(시간당 ~수십 장)만. 차단 시 즉시 중단. |
| Figma 웹/Desktop UI 자동화 (이 가이드 기본) | 본인이 로그인한 그대로 키보드·마우스 조작. **REST API 쓰기 쓸 때보다 신호는 적음** | 개인 작업 OK. CI 서버·팀 공용 계정은 REST API 권장 |
| Figma REST API (`creative figma --api`) | 공식 API — 100% 정상 경로 | 항상 OK |

**권장 운영 원칙:**

- 본인 계정에서, 본인 작업 결과물에만 사용.
- 동시 창은 4개 이하 (Google rate-limit + 의심행위 회피).
- 세션마다 `--rate-limit 30s` 같은 딜레이 둘 것.
- 차단·캡차가 뜨면 **즉시 멈추고 잠시 쉬기** (스크립트가 자동 종료함).
- 상업/팀 규모 작업은 **공식 Gemini API** (유료) 로 전환 — 같은 모델, 약관 안전.
### 🚬 OpenClaw Docker 샌드박스와의 관계 (중요)

이 파이프라인은 **완전히 별도 레인** 으로 돌아갑니다:

```
[OpenClaw 컨테이너]               [Creative 파이프라인]
  Docker 안                          호스트(맥북) 위
  network=isolated                    Chromium + Figma·Pinterest
  read_only FS                        ~/openclaw-creative/
  그대로 안전                          개인 계정 세션
```

- `creative` 명령은 **OpenClaw 컨테이너에 접근하지 않으며**, 호스트의 Ollama 데몬(127.0.0.1:11434) 만 호출합니다.
- 특히 Chromium 이 Figma·Gemini·Pinterest 와 통신하는 동안에도 OpenClaw 컨테이너는 그대로 `isolated` 으로 유지 (컨테이너 에서 외부 인터넷 감지 없음).
- Chromium 프로필·Figma 토큰·Gemini 세션은 전부 `~/openclaw-creative/` 에만 저장. 컨테이너 볼륨으로 새지지 않음 (마운트 없음).
- 차단 원하면 `chmod 700 ~/openclaw-creative` + 컨테이너는 계속 isolated.

> 즉, "디자이너 워크플로우에만 인터넷을 쓰고, OpenClaw 메인 에이전트는 계속 격리" 가 동시에 가능합니다.
### 1. 한 번만: 환경 세팅

```bash
# 1) 의존성 설치 (Homebrew + Python + Playwright Chromium)
~/DEV/openclaw-workspace/scripts/creative-pipeline-setup.sh
```

스크립트가 하는 일:
- Homebrew 로 `gallery-dl`, `python@3.12`, `jq`, `imagemagick` 설치
- 가상환경 `~/openclaw-creative/.venv` 생성 + `playwright`, `pillow`, `requests` 설치
- `playwright install chromium` (~150MB)
- 디렉터리 구조 생성:
  ```
  ~/openclaw-creative/
    refs/         (Pinterest 레퍼런스)
    prompts/      (생성된 프롬프트 .txt)
    out/          (나노바나나 결과 PNG)
    profiles/     (Chromium 영구 프로필 — 로그인 1회면 영구)
      banana-1/
      banana-2/
      banana-3/
      banana-4/
    logs/
  ```
- `~/bin/creative` 런처 심볼릭 링크 설치 (PATH 안내)

**최초 1회 — 나노바나나 4개 창에 로그인:**

```bash
creative banana-login
```

Chromium 4개 창이 차례로 뜹니다. 각 창에서 https://gemini.google.com 에 본인 Google 계정으로 로그인 → 창 닫기. 다음부터는 자동 로그인 유지 (프로필 영속).

**Figma 토큰 발급(선택):**
- https://www.figma.com/developers/api → Personal access tokens → 새 토큰 복사
- `~/openclaw-creative/.env` 에 저장:
  ```bash
  echo 'FIGMA_TOKEN=figd_...'        >> ~/openclaw-creative/.env
  echo 'FIGMA_FILE_KEY=...'           >> ~/openclaw-creative/.env
  chmod 600 ~/openclaw-creative/.env
  ```

### 2. Step 1 — Pinterest 레퍼런스 수집 (gallery-dl)

```bash
# 검색어 기반 (가장 흔한 케이스)
creative refs "cyberpunk cafe interior" --count 8

# 본인 보드 통째로
creative refs https://pinterest.com/yourname/moodboards/cyberpunk/

# 결과: ~/openclaw-creative/refs/<slug>/01.jpg ... 08.jpg
```

내부 동작:
- `gallery-dl` 로 Pinterest 페이지 파싱 (URL 또는 검색)
- 중복 제거 (perceptual hash)
- 짧은 변 1024px 로 리사이즈 (LLM 토큰 절약)

> 💡 보드 비공개거나 로그인이 필요하면 한 번만:  `gallery-dl oauth:pinterest`

### 3. Step 2 — 로컬 LLM 으로 프롬프트 자동 생성

```bash
creative prompts "cyberpunk cafe interior" --variations 12
```

내부 동작:
1. `~/openclaw-creative/refs/<slug>/*.jpg` 를 비전 모델(`qwen2.5vl:7b`)에 입력 → 공통 분위기·팔레트·구도 추출.
2. 추출 결과 + 사용자 키워드를 텍스트 모델(`qwen2.5-coder:7b`)에 넘김 → **12개 변주 프롬프트** 생성.
3. 결과: `~/openclaw-creative/prompts/<slug>.jsonl` (각 줄 = 한 작업).
   ```json
   {"id":"01","prompt":"cyberpunk cafe interior, neon pink and teal lighting, rain on window, 35mm film, low angle, ..."}
   {"id":"02","prompt":"... seen from second-floor balcony, two patrons in trench coats, holographic menu, ..."}
   ```

**Claude 안 거치고도 충분한 이유:** 프롬프트는 패턴(렌즈·구도·조명·분위기·디테일 5요소)이라, 7B 로컬 모델이 충분합니다. 더 정교히 원하면 `--model qwen2.5:14b` 옵션.

> Claude 를 정말 쓰고 싶으면 `creative prompts ... --review claude` (제출 전 Claude 에 리뷰 요청. 단 인터넷 필요).

### 4. Step 3 — 나노바나나 N개 창 병렬 생성

```bash
# 4창 병렬, 12개 작업 큐 분배 (창당 평균 3개)
creative banana --jobs ~/openclaw-creative/prompts/cyberpunk-cafe-interior.jsonl --windows 4
```

내부 동작:
- Playwright 가 영구 프로필 4개(`profiles/banana-1` … `banana-4`) 로 Chromium 4창 동시 실행.
- 각 창은 https://gemini.google.com 으로 이동, 로그인 세션이 이미 있으므로 바로 채팅 화면.
- 작업 큐를 4 워커에 라운드로빈 분배:
  - 워커가 채팅창에 프롬프트 입력 → 전송.
  - 응답 내 이미지 `<img>` 가 나타날 때까지 대기 (최대 60초).
  - 이미지 우클릭 → "이미지 저장" 자동화 → `out/<slug>/01.png`.
  - 다음 작업으로.
- 진행 표시:
  ```
  [banana-1] 03/12  ✓  out/cyberpunk-cafe-interior/03.png  (14.2s)
  [banana-2] 04/12  ✓  out/cyberpunk-cafe-interior/04.png  (16.8s)
  [banana-3] 05/12  ⠋  generating...
  [banana-4] 06/12  ✓  out/cyberpunk-cafe-interior/06.png  (12.1s)
  Total 06/12 — ETA ~01:45
  ```

옵션:

| 옵션 | 효과 |
|---|---|
| `--windows N` | 동시 창 개수 (기본 4, 권장 ≤ 4) |
| `--rate-limit 30s` | 같은 창 내 요청 최소 간격 (기본 25초) |
| `--retries 2` | 실패 시 재시도 |
| `--headed` | 창을 보이게 (디버그용, 기본은 headless) |
| `--watermark off` | 워터마크 제거 토글 (모델 옵션이 있으면) |

> 📈 **속도 비교 (12장 기준):** 1창 직렬 ≈ 4분 / 4창 병렬 ≈ 1분 5초. 약 **3.7배** 단축.

### 5. Step 4 — Figma 로 자동 업로드

#### Figma 가 처음? — 다운로드·설치·계정

Figma 는 **두 가지 모드** 가 있고 둘 다 가능합니다.

| 모드 | 설치 | 특징 | 본 가이드 |
|---|---|---|---|
| **Figma Web** (브라우저) | 설치 불필요 — https://www.figma.com 가입 | 별도 앱 없이 쓰기. 폰트는 [Figma Font Installer](https://www.figma.com/downloads/) 권장 | **기본값** (Playwright 가 직접 figma.com 컨트롤) |
| **Figma Desktop** | https://www.figma.com/downloads/ → "Mac with Apple chip" 다운로드 → DMG 더블클릭 → Applications 로 드래그 | 로컬 폰트·복수 파일 탭·오프라인 지속·키보드 단축키 더 빠름 | `--app desktop` 옵션으로 Desktop 사용 (실험적) |

**계정 만들기 (3분):**

1. https://www.figma.com → 우측 상단 *"Get started for free"* → Google 또는 이메일로 가입.
2. 가입 직후 브라우저에 첫 워크스페이스가 생깁니다 (개인 무료 플랜).
3. 좌측 상단 *"+ Design file"* 클릭 → 빈 디자인 파일 생성 → 파일명을 `Mood Board` 같은 걸로 변경.
4. 주소창의 URL 에서 **파일 키** 를 복사: `https://www.figma.com/file/<여기_파일키>/Mood-Board?...`

**Desktop 다운로드 자세히:**

1. https://www.figma.com/downloads/ 접속.
2. *"Desktop app for macOS"* 섹션에서 **"Mac with Apple chip"** (M1/M2/M3/M5...) 또는 *"Mac with Intel chip"* 중 본인 맥 칩에 맞는 걸 클릭.
   - 본인 맥 칩 모름? → 좌측 상단 🍎 → *이 Mac에 관하여* → "칩" 항목 (Apple M5 Pro 등이면 Apple chip).
3. `Figma.dmg` 다운로드 (~150MB).
4. `Figma.dmg` **더블클릭** → 창이 뜨면 `Figma` 아이콘을 옆의 `Applications` 폴더 위로 **드래그&드롭**.
5. 처음 실행 시 macOS 가 *"인터넷에서 다운로드한 앱"* 경고 → "열기" 클릭 (한 번만).
6. Figma 앱에서 같은 계정으로 로그인.

> 💡 **Desktop 의 진짜 이점**: 로컬 폰트(시스템 설치된 한글 폰트 등) 사용. 자동화 측면에서는 둘 다 동일.

#### 자동화 방식: GUI 컨트롤 (기본) vs REST API

이 가이드는 **사람이 보고 클릭하듯 Playwright 가 figma.com 을 조작** 하는 GUI 방식을 기본으로 합니다. 나노바나나와 같은 패턴 — 영구 Chromium 프로필에 한 번 로그인, 다음부터는 자동.

| 방식 | 명령 | 장점 | 단점 |
|---|---|---|---|
| **GUI 자동화** (기본) | `creative figma --slug ...` | • 토큰 발급 불필요 (계정 로그인만)<br>• 무료 플랜에서도 노드 생성 가능 (Editor 권한이면 됨)<br>• 사람이 보면서 도중에 끼어들기 쉬움 (`--headed`) | • Figma UI 변경에 취약 (셀렉터 갱신 필요)<br>• 화면 해상도 영향 (1280×900 가정) |
| **REST API** (선택) | `creative figma --api --slug ...` | • 안정적, CI 친화적<br>• 토큰만 있으면 headless | • Personal Access Token 필요<br>• 무료/스타터 플랜에서 노드 쓰기 제한 가능 |

```bash
# 최초 1회 — Figma 에 로그인 (별도 영구 프로필)
creative figma-login

# 12장을 Mood-2026-04 페이지에 4×3 그리드로 자동 배치
creative figma --slug cyberpunk-cafe-interior --page "Mood-2026-04"

# REST API 로 하고 싶으면 (.env 의 FIGMA_TOKEN, FIGMA_FILE_KEY 필요)
creative figma --api --slug cyberpunk-cafe-interior --page "Mood-2026-04"
```

#### GUI 자동화 내부 동작

```
1) ~/openclaw-creative/profiles/figma-1 (영구 프로필) Chromium 1창 실행
2) https://www.figma.com/file/<FIGMA_FILE_KEY>/ 로 직행 (.env 에 키 저장)
3) 좌측 패널에서 페이지 'Mood-2026-04' 검색
   - 없으면 "+" → 새 페이지 → 이름 입력
4) 캔버스 클릭으로 포커스 → ⌘⇧K (Place image) 또는 직접 드롭
   - file chooser 가 뜨면 Playwright 가 set_input_files() 로 PNG 12장 일괄 선택
5) 캔버스 좌상단부터 4열 × 3행 그리드 좌표 계산해서 클릭 → 이미지 배치
6) ⌘S (자동 저장됨) → 완료 메시지 + 파일 URL 출력
```

#### Figma 키 한 번에 익히기 (단축키)

| 단축키 | 동작 |
|---|---|
| `⌘⇧K` | Place image (이미지 가져오기 — 자동화에 핵심) |
| `R` | Rectangle 도구 |
| `T` | Text 도구 |
| `V` | Move 도구 (선택) |
| `⌘D` | 복제 |
| `⌘G` | Group |
| `⌘⌥G` | Frame 으로 감싸기 |
| `⌘+` / `⌘-` | 줌 인/아웃 (스크립트가 줌 100%로 리셋함) |

> ⚠️ Figma UI 가 업데이트되면 셀렉터가 바뀔 수 있습니다. 실패 시 `creative figma --headed` 로 화면을 보면서 어디서 멈췄는지 확인하세요.

#### 폴백: REST API 매니페스트

`--api` 옵션 또는 GUI 가 막히면 PNG 가 업로드된 image hash 목록을 `out/<slug>/figma-manifest.json` 으로 출력합니다. Figma 에서 *"Plugins → Search → Image Tray"* (또는 비슷한 자유 플러그인) 으로 매니페스트를 import 가능.

### 6. 한 줄로 다 돌리기 (`creative run`)

```bash
creative run "cyberpunk cafe interior" \
  --refs 8 \
  --variations 12 \
  --windows 4 \
  --figma-page "Mood-2026-04"
```

= `refs` → `prompts` → `banana` → `figma` 를 순서대로. 각 단계 결과물은 그대로 디스크에 남으므로 중간에 끊고 재개 가능 (`--resume`).

### 7. 트러블슈팅

| 증상 | 원인 | 대응 |
|---|---|---|
| `creative banana-login` 후에도 매번 로그인 요청 | 프로필 디렉터리 권한 | `chmod -R 700 ~/openclaw-creative/profiles` |
| Gemini 가 "automated activity" 차단 | 동시 창 너무 많음 / 너무 빠름 | `--windows 2 --rate-limit 60s` 로 낮추기, 1시간 쉬기 |
| 캡차 (reCAPTCHA) 등장 | 의심 행위 감지 | 스크립트가 자동 종료. 24시간 자제, 다음엔 더 보수적으로 |
| 결과 PNG 가 일부만 받아짐 | 응답 대기 타임아웃 | `--retries 3 --timeout 120` |
| `qwen2.5vl:7b` 가 없음 | Ollama 모델 미설치 | `ollama pull qwen2.5vl:7b` (~5GB) |
| Figma 401 | 토큰 만료 / 권한 부족 | 새 토큰 발급, `read+write` 체크 |
| 생성 이미지 품질 불만 | 프롬프트 변주가 평면적 | `creative prompts ... --variations 12 --diversity high` |
| 동시 창에서 요청이 같은 채팅 세션에 섞임 | 프로필 격리 실패 | `creative doctor` 가 프로필별 쿠키/세션 분리 검증 |

---

## 🇬🇧 English

### Big picture

```
Old (manual, 4 steps):
  Pinterest search → paste into Claude → nano-banana single tab → drag into Figma

New (one command):
  creative run "cyberpunk cafe interior, 12 variants"
    ├─ gallery-dl   : pull 8 Pinterest references
    ├─ Ollama       : VLM reads refs → coder writes 12 prompt variants
    ├─ Playwright   : 4 parallel Chromium windows on gemini.google.com
    └─ Figma API    : upload PNGs → grid them on a page
```

### ⚠️ ToS & account caveats

This pipeline drives **Gemini's web UI** with a real browser instead of the official API. Google's ToS restricts "automated means", so:

- Use only **your own** account, only on your own creative work.
- Keep concurrent windows ≤ 4 and add per-window rate limits (`--rate-limit 30s`).
- If a captcha or "automated activity" warning appears, **stop immediately** (the scripts do this automatically).
- For team / commercial / heavy use → switch to the **official Gemini API** (paid) — same model, no ToS risk.

Pinterest (`gallery-dl`) is generally OK for personal mood-board use; Figma REST API is fully sanctioned.

### Figma — install & sign up

Figma works in **two modes**, both supported:

- **Web** (default): no install — just sign up at https://www.figma.com → click "+ Design file" → copy the file key from the URL `https://www.figma.com/file/<KEY>/...`
- **Desktop** (optional, faster keyboard shortcuts): https://www.figma.com/downloads/ → "Mac with Apple chip" or "Mac with Intel chip" → open the DMG → drag `Figma` onto `Applications` → sign in.

> Tip: Same account works on both. The automation runs against `figma.com` directly via Playwright, so Web is enough.

### Sandbox boundary (important)

This pipeline lives **entirely on the host**, fully separate from the OpenClaw Docker container:

- `creative` only reaches the host's Ollama daemon (127.0.0.1:11434). It never touches the OpenClaw container.
- The OpenClaw container can stay in `isolated` while Chromium freely talks to figma.com / gemini / pinterest. No leak between the two.
- Profiles, Figma sessions, downloaded PNGs all live under `~/openclaw-creative/` (never mounted into the container).

### One-time setup

```bash
~/DEV/openclaw-workspace/scripts/creative-pipeline-setup.sh
creative banana-login   # log into Gemini in 4 persistent Chromium profiles
creative figma-login    # log into Figma in a 5th persistent profile (GUI mode, default)
echo 'FIGMA_FILE_KEY=...'    >> ~/openclaw-creative/.env       # GUI mode needs this
# Optional — only if you want the REST-API path:
# echo 'FIGMA_TOKEN=figd_...' >> ~/openclaw-creative/.env
chmod 600 ~/openclaw-creative/.env
```

### Daily usage

```bash
# References
creative refs "cyberpunk cafe interior" --count 8

# Prompts (local Ollama — no Claude needed)
creative prompts "cyberpunk cafe interior" --variations 12

# Parallel image generation (4 Chromium windows)
creative banana --jobs ~/openclaw-creative/prompts/cyberpunk-cafe-interior.jsonl --windows 4

# Push to Figma — GUI default (Playwright drives figma.com)
creative figma --slug cyberpunk-cafe-interior --page "Mood-2026-04"

# Or REST API mode (token-based, headless-friendly)
creative figma --api --slug cyberpunk-cafe-interior --page "Mood-2026-04"

# Or all four at once
creative run "cyberpunk cafe interior" --refs 8 --variations 12 --windows 4 --figma-page "Mood-2026-04"
```

### Speed gain (12 images)

- 1 window serial ≈ 4 min
- 4 windows parallel ≈ 1 min 5 sec — about **3.7×** faster.

### Troubleshooting (short)

| Symptom | Fix |
|---|---|
| Login asked every time | `chmod -R 700 ~/openclaw-creative/profiles` |
| "Automated activity" block | `--windows 2 --rate-limit 60s`, take a 1-hour break |
| reCAPTCHA appears | stop for 24h, lower concurrency next time |
| Some PNGs missing | `--retries 3 --timeout 120` |
| Figma 401 | regenerate token with read+write |
| Cross-window session leak | `creative doctor` checks per-profile isolation |
