# 🎬 쇼츠 자동화 — Pinterest → 미리캔버스 → CapCut → Shorts

> 한 명령(`shorts run "키워드"`)으로 **레퍼런스 수집 → 디자인 편집 → 영상 export** 까지. OpenClaw 보안 모델은 그대로 유지하고, 호스트(맥북)에서 실제 프로그램(미리캔버스 웹, CapCut Web/Desktop)을 사람과 동일하게 GUI 로 조종합니다.

---

## 📋 목차

- [🇰🇷 한국어](#-한국어)
  - [1. 큰 그림](#1-큰-그림)
  - [2. 보안 — 샌드박스 경계](#2-보안--샌드박스-경계)
  - [3. 사전 준비 — 프로그램 설치](#3-사전-준비--프로그램-설치)
    - [3.1 Pinterest 계정](#31-pinterest-계정)
    - [3.2 미리캔버스](#32-미리캔버스)
    - [3.3 CapCut (Web vs Desktop)](#33-capcut-web-vs-desktop)
    - [3.4 Homebrew · ffmpeg · gallery-dl](#34-homebrew--ffmpeg--gallery-dl)
  - [4. 1회 세팅](#4-1회-세팅)
  - [5. 일상 사용](#5-일상-사용)
  - [6. 셀렉터가 깨졌을 때 (UI 변경 대응)](#6-셀렉터가-깨졌을-때-ui-변경-대응)
  - [7. 트러블슈팅](#7-트러블슈팅)
  - [8. 약관·저작권 체크](#8-약관저작권-체크)
- [🇬🇧 English](#-english)

---

## 🇰🇷 한국어

### 1. 큰 그림

**기존 (수동 4단계):**

```
Pinterest 검색 → 12장 저장   →   미리캔버스 업로드/배치   →   CapCut 임포트/편집/내보내기   →   업로드
   (브라우저)                  (브라우저)                    (앱)
```

**자동화 후:**

```
$ shorts run "여행 감성 풍경"
   │
   ├── 1) gallery-dl 이 Pinterest 에서 12장 → ~/openclaw-shorts/refs/<slug>/
   ├── 2) Playwright 가 미리캔버스 영구 프로필(miri-1) 로 로그인된 채
   │       1080×1920 새 디자인 → 이미지 일괄 업로드 → PNG 다운로드
   └── 3) Playwright 가 CapCut Web 영구 프로필(capcut-1) 로
           9:16 새 프로젝트 → 미디어 업로드 → 1080p MP4 export
                                                 ↓
                              ~/openclaw-shorts/out/<slug>/shorts.mp4
```

> 📌 **솔직한 한계**: 미리캔버스/CapCut Web 의 **드래그·타임라인 좌표 API 는 비공개** 이므로, 본 스크립트는 "**업로드와 export 까지 자동, 미세 배치는 사람이 헤드모드에서 1분**" 정책을 채택합니다. 완전 자동 영상 합성을 원하면 마지막 부분에서 [`ffmpeg` 옵션](#7-트러블슈팅) 안내를 보세요.

---

### 2. 보안 — 샌드박스 경계

```
┌──────────────────────────────────┐    ┌─────────────────────────────────────┐
│ OpenClaw 컨테이너 (Docker)        │    │ Shorts 파이프라인 (호스트, 맥북)    │
│   network=isolated 그대로         │    │  ~/openclaw-shorts/                  │
│   read_only FS                    │    │   ├─ refs/    (Pinterest 다운로드)   │
│   호스트와 절연                   │    │   ├─ out/     (PNG·MP4 산출물)       │
│                                   │    │   ├─ profiles/miri-1                 │
│   → 일절 영향 없음                │    │   └─ profiles/capcut-1               │
└──────────────────────────────────┘    │  Chromium 만 인터넷 (사람과 동일)    │
                                         └─────────────────────────────────────┘
```

| 항목 | 보장 |
|---|---|
| OpenClaw 본 컨테이너 | `isolated` 모드 그대로, 마운트·네트워크 변화 없음 |
| 영구 프로필(쿠키·세션) | `~/openclaw-shorts/profiles/{miri-1,capcut-1}/` 700 권한 |
| 호스트 `~/.ssh`, OpenClaw `.env` | **자동화 스크립트가 일절 읽지 않음** |
| 핀터레스트/미리캔버스/CapCut 와의 통신 | Chromium 단독, 사람의 브라우저와 동일 |
| 실행 산출물 | `~/openclaw-shorts/out/` 한 곳에만 |
| 시스템 외부 명령 | `gallery-dl`, `ffmpeg`, `jq` (brew) — sudo 없음 |

> **"피그마/나노바나나 패턴" 동일.** 도커 안에서 GUI 자동화를 하면 미리캔버스·CapCut 의 봇 차단·CAPTCHA 에 자주 막혀 실용성 제로 → 호스트의 "로그인된 영구 프로필"을 그대로 재사용하는 방식이 가장 안정적이고 사람과 구분이 안 됩니다.

---

### 3. 사전 준비 — 프로그램 설치

#### 3.1 Pinterest 계정

1. https://www.pinterest.com/ → "가입하기"
2. 이메일/구글 중 편한 쪽으로 가입
3. **로그인 상태 자체는 `gallery-dl` 사용에 필수가 아닙니다** (공개 핀 한정). 비공개 보드를 받으려면 `~/.config/gallery-dl/config.json` 에 쿠키 추가 ([gallery-dl 문서](https://github.com/mikf/gallery-dl/blob/master/docs/configuration.rst#extractorpinterestcookies)).

#### 3.2 미리캔버스

미리캔버스는 **다운로드 없는 100% 웹 서비스**입니다.

1. https://www.miricanvas.com/ko 접속
2. 우상단 **회원가입** → 카카오/구글/네이버/이메일 중 선택
3. 무료 플랜으로 충분 (PNG 다운로드 가능, 워터마크 없음). 유료(Pro)는 프리미엄 요소 잠금 해제용.
4. 처음 로그인 후 본 스크립트의 `shorts miri-login` 으로 한 번만 세션을 잡아두면 됩니다.

#### 3.3 CapCut (Web vs Desktop)

| 옵션 | 어디서 | 자동화 적합성 | 추천 |
|---|---|---|---|
| **CapCut Web** | https://www.capcut.com/editor (브라우저) | ⭐⭐⭐⭐ Playwright 가능 | **본 스크립트 기본값** |
| CapCut Desktop (Mac) | https://www.capcut.com/ko-kr/tools/desktop-video-editor | ⭐⭐ AppleScript/UIAutomation 필요 | 수동 편집 선호 시 |

**CapCut Desktop 설치 (선택):**

1. https://www.capcut.com/ko-kr/tools/desktop-video-editor → "Mac 다운로드"
2. M1/M2/M3/M4/M5 칩이면 **Apple Silicon** 버전, Intel 맥이면 **Intel** 버전 (🍎 → "이 Mac에 관하여" 에서 칩 확인)
3. 다운로드된 `.dmg` 더블클릭 → CapCut 아이콘을 **Applications 폴더로 드래그&드롭**
4. 첫 실행 시 macOS 가 "인터넷에서 다운로드한 앱입니다" 경고 → **열기** 클릭
5. TikTok/Google/이메일로 로그인

**CapCut Web 사용 (자동화 대상):**

1. https://www.capcut.com/editor 접속
2. 첫 진입 시 로그인 요구 → TikTok 또는 구글로 가입/로그인
3. 본 스크립트의 `shorts capcut-login` 으로 세션 1회 캡처

> 💡 CapCut 약관: 개인 콘텐츠 제작을 위한 GUI 자동화는 일반적으로 허용 범위지만, 대량 계정 자동 생성·스팸 export 는 금지. 본 스크립트는 **로그인된 본인 계정 1개**만 사용합니다.

#### 3.4 Homebrew · ffmpeg · gallery-dl

`shorts setup` 이 자동 설치하지만, 미리 깔아두려면:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install gallery-dl python@3.12 ffmpeg jq imagemagick
```

---

### 4. 1회 세팅

```bash
cd ~/DEV/llmDev/openclaw-workspace
./scripts/shorts-setup.sh
```

세팅이 하는 일:

1. brew 의존성 (gallery-dl/ffmpeg/jq/imagemagick/python@3.12)
2. `~/openclaw-shorts/{refs,out,logs,profiles/{miri-1,capcut-1}}` 700 권한 생성
3. Python venv + Playwright + Chromium 다운로드 (~700MB, 1회)
4. `.env` 템플릿 생성 (`~/openclaw-shorts/.env`)
5. `~/bin/shorts` 심볼릭 링크

이어서 한 번만 로그인:

```bash
shorts miri-login        # 미리캔버스 로그인 후 창 닫기
shorts capcut-login      # CapCut 로그인 후 창 닫기
```

세션은 영구 프로필에 저장되어, 이후 명령은 사람 손 없이 자동 실행됩니다.

---

### 5. 일상 사용

```bash
# 0) 환경 점검
shorts doctor

# 1) 핀터레스트에서 12장 다운로드 (REFS_PER_QUERY 로 조절)
shorts refs "여행 감성 풍경"
# → ~/openclaw-shorts/refs/여행-감성-풍경/

# 2) 미리캔버스 1080×1920 + 일괄 업로드 + PNG 다운로드
shorts miri "여행 감성 풍경"
# → ~/openclaw-shorts/out/여행-감성-풍경/miri.png  (자동 다운로드 성공 시)

# 3) CapCut Web 9:16 새 프로젝트 + 미디어 업로드 + 1080p MP4 export
shorts capcut "여행 감성 풍경"
# → ~/openclaw-shorts/out/여행-감성-풍경/shorts.mp4

# 풀체인 (위 3개 한 번에)
shorts run "여행 감성 풍경"
```

**옵션:**

| 환경변수 | 효과 | 기본 |
|---|---|---|
| `SHORTS_HEADED=1` | Chromium 창을 보이게 (디버깅·수동 보정용) | `0` |
| `REFS_PER_QUERY` | Pinterest 다운로드 장수 | `12` |
| `MIRI_CANVAS_W/H` | 미리캔버스 캔버스 크기 | `1080×1920` |
| `CAPCUT_RES` | CapCut export 해상도 | `1080p` |
| `OLLAMA_TEXT_MODEL` | 자막/카피 생성 모델 (확장용) | `qwen2.5-coder:7b` |

---

### 6. 셀렉터가 깨졌을 때 (UI 변경 대응)

미리캔버스·CapCut 은 UI 가 자주 바뀝니다. 자동화가 멈추면:

```bash
SHORTS_HEADED=1 shorts miri "테스트"
```

으로 창을 띄우고 어디서 멈추는지 본 뒤,

- [scripts/shorts-lib/miri.py](../scripts/shorts-lib/miri.py) 상단 `SEL_*` 상수
- [scripts/shorts-lib/capcut.py](../scripts/shorts-lib/capcut.py) 상단 `SEL_*` 상수

만 DevTools(우클릭 → 검사) 로 본 새 셀렉터로 교체하면 됩니다. 코드 본문은 손대지 않아도 됩니다.

---

### 7. 트러블슈팅

| 증상 | 원인 / 대응 |
|---|---|
| `gallery-dl` 결과 0개 | Pinterest 가 UA·쿠키 요구. `~/.config/gallery-dl/config.json` 에 브라우저 쿠키 추출 후 시도. |
| 미리캔버스 "새 디자인" 버튼 못 찾음 | UI 변경. `SHORTS_HEADED=1` + DevTools 로 셀렉터 갱신 |
| CapCut Web 업로드는 됐는데 export 안 됨 | 첫 export 는 회원가입/약관 동의 추가 단계 발생. `SHORTS_HEADED=1` 로 1회 수동 export 후 자동 재시도 |
| 자동 export 가 너무 불안정 | 아래 ffmpeg 폴백 사용 |
| 한글 슬러그가 깨짐 | macOS 의 NFD/NFC 차이 — 다른 앱에서 폴더 보일 때 정상이면 무시 가능 |

#### ffmpeg 풀자동 폴백 (CapCut Web 자동화 실패 시)

CapCut 자동화가 깨지면, 단순 슬라이드쇼 영상은 ffmpeg 한 줄로 즉시 만들 수 있습니다:

```bash
SLUG="여행-감성-풍경"
DIR="$HOME/openclaw-shorts/refs/$SLUG"
OUT="$HOME/openclaw-shorts/out/$SLUG/shorts.mp4"
mkdir -p "$(dirname "$OUT")"

# 2.5초씩 1080×1920 페이드, BGM 없이
ffmpeg -y -framerate 1/2.5 -pattern_type glob -i "$DIR/*.jpg" \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,format=yuv420p,fade=t=in:st=0:d=0.4" \
  -r 30 -c:v libx264 -pix_fmt yuv420p "$OUT"
```

BGM 추가:

```bash
ffmpeg -y -framerate 1/2.5 -pattern_type glob -i "$DIR/*.jpg" \
  -i ~/Music/bgm.mp3 \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,format=yuv420p" \
  -shortest -r 30 -c:v libx264 -c:a aac -b:a 192k "$OUT"
```

> 자막은 `drawtext` 또는 [.ass 자막](https://ffmpeg.org/ffmpeg-filters.html#subtitles-1)으로 추가 가능. 자동화 정도가 깊어질수록 ffmpeg 가 가장 신뢰성 높습니다.

---

### 8. 약관·저작권 체크

| 항목 | 권장 |
|---|---|
| Pinterest 다운로드 이미지 사용 | **2차 창작/원본 권리자 표기 권장**. 핀 자체에는 원본 출처 링크가 따라옴 (`gallery-dl` 가 메타데이터로 저장) |
| 미리캔버스 무료 요소 | 출처 표기 불필요 (요소별 라이선스 확인) |
| CapCut 음원 라이브러리 | "상업용 가능" 필터로 좁히기. CapCut 자체 라이선스가 가장 안전 |
| 자동화의 윤리 | 본인 계정 1개에서 사람과 동일한 페이스로 (대량 자동 업로드/스팸 금지) |

---

## 🇬🇧 English

### TL;DR

A single command (`shorts run "keyword"`) automates the full **Pinterest → Miricanvas → CapCut → Shorts** chain while keeping the OpenClaw container in `isolated` and treating each web app exactly like a human user via persistent Chromium profiles.

### Architecture

```
host (your Mac)                              internet
  shorts run "..."
    ├─ gallery-dl   ──────────────────►   pinterest.com
    ├─ Playwright (profile miri-1)   ─►   miricanvas.com
    └─ Playwright (profile capcut-1) ─►   capcut.com/editor
                                                │
                            ~/openclaw-shorts/out/<slug>/shorts.mp4
```

OpenClaw's Docker container is untouched (`isolated` stays `isolated`). All session cookies live under `~/openclaw-shorts/profiles/`. No mounts, no SSH, no `.env` access.

### Install

1. **Pinterest** — sign up at pinterest.com (gallery-dl works on public pins without login).
2. **Miricanvas** — web only, no install. Sign up at https://www.miricanvas.com/ko.
3. **CapCut** — choose:
   - **Web** (default for this script): https://www.capcut.com/editor
   - **Desktop**: https://www.capcut.com/ko-kr/tools/desktop-video-editor → DMG → drag to Applications. Pick *Apple Silicon* or *Intel* per your chip (🍎 → "About This Mac").
4. **Homebrew tools** (auto-installed by `shorts setup`):
   ```bash
   brew install gallery-dl python@3.12 ffmpeg jq imagemagick
   ```

### Usage

```bash
./scripts/shorts-setup.sh           # one-time
shorts miri-login                   # one-time, log in once and close window
shorts capcut-login                 # one-time
shorts run "moody travel landscapes"

# or step-by-step
shorts refs   "moody travel landscapes"
shorts miri   "moody travel landscapes"
shorts capcut "moody travel landscapes"

# debug a broken selector visually
SHORTS_HEADED=1 shorts miri "moody travel landscapes"
```

### Honest limits

Miricanvas and CapCut Web do not expose layout/timeline coordinates publicly. The script automates *upload* and *export* reliably; precise drag/positioning is best done by you in headed mode for ~1 minute. If you need fully unattended video assembly, fall back to ffmpeg:

```bash
ffmpeg -y -framerate 1/2.5 -pattern_type glob -i "refs/*.jpg" \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,format=yuv420p" \
  -r 30 -c:v libx264 out/shorts.mp4
```

### Security boundary (same as the creative pipeline)

| | |
|---|---|
| OpenClaw container | stays `isolated`, untouched |
| Persistent profiles | `~/openclaw-shorts/profiles/{miri-1,capcut-1}` (chmod 700) |
| Host secrets (`~/.ssh`, OpenClaw `.env`) | **never read** by the automation |
| Network egress | only from Chromium, identical to your everyday browsing |
| sudo / privilege escalation | none |

### Selectors break? Edit two files only

- [scripts/shorts-lib/miri.py](../scripts/shorts-lib/miri.py) — top `SEL_*`
- [scripts/shorts-lib/capcut.py](../scripts/shorts-lib/capcut.py) — top `SEL_*`

Open DevTools in headed mode, copy the new selector, paste, done.

---

Copyright © 2026 박성모 Park Sungmo — MIT License
