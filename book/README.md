# OpenClaw 자동화 한 권으로

> 저자: **박성모 (Park Sungmo)**
> 빌드: [mdBook](https://rust-lang.github.io/mdBook/)

`docs/lecture/H1~H8` 강의 대본을 **혼자 읽고 따라할 수 있는 한 권의 책**으로 재편집한 결과물입니다.
이 책은 **이 레포가 없어도** 처음부터 끝까지 OpenClaw 자동화 환경을 재현할 수 있도록, 부록 A에 모든 스크립트 전문(全文)을 무삭제로 수록합니다.

## 빌드

```bash
brew install mdbook
cd book
mdbook serve --open    # 로컬 미리보기 (http://localhost:3000)
mdbook build           # build/ 디렉터리에 정적 HTML 산출
```

## 인쇄 / PDF 만들기

mdBook 은 빌드 시 모든 챕터를 한 페이지로 합쳐주는 `build/print.html` 을 자동으로 만듭니다.
이 파일을 브라우저로 열어 ⌘ + P 로 PDF/종이 인쇄가 가능하며, 한국 로케일 기준 **기본 용지는 A4** 입니다.

### 가장 쉬운 길 — 브라우저로 PDF 저장

```bash
cd book
mdbook build
open build/print.html       # ⌘ + P → "PDF로 저장"
```

> 권장 인쇄 옵션: 배경 그래픽 켜기 (코드 블록 음영 보존), 헤더/푸터 끄기, 양면 인쇄.

### Safari 로 PDF 저장 (가장 호환성 좋은 길)

Chrome 이 안 깔려 있어도 macOS 에 기본 탑재된 **Safari** 만으로 PDF 를 만들 수 있습니다.
그래픽 인터페이스로 진행하므로 가장 직관적이고 실패가 적습니다.

```bash
cd /Users/mo/DEV/llmDev/openclaw-workspace/book
mdbook build
open -a Safari build/print.html
```

각 줄의 의미:

| 항목 | 의미 |
|---|---|
| `cd /Users/mo/DEV/llmDev/openclaw-workspace/book` | 작업 디렉터리를 책 폴더로 옮깁니다. 다음 명령들이 모두 이 폴더 기준으로 동작합니다. |
| `mdbook build` | `src/` 마크다운을 `build/` 의 정적 HTML 로 빌드합니다. 이때 전 챕터 + 부록 A 전문(全文) 이 한 페이지로 합쳐진 `build/print.html` 이 자동으로 생성됩니다. |
| `open -a Safari build/print.html` | macOS 의 `open` 명령으로 `print.html` 을 **Safari 앱** (`-a Safari`) 으로 엽니다. 기본 브라우저가 Chrome/Firefox 여도 강제로 Safari 가 띄워집니다. |

Safari 가 열리면 (페이지가 길어서 로딩에 몇 초 걸립니다):

1. 메뉴 **File → Print…** 또는 단축키 **⌘ + P**
2. 인쇄 대화상자 좌하단의 **PDF ▾** 드롭다운 클릭
3. **"Save as PDF…"** (한국어: *"PDF로 저장…"*) 선택
4. 파일 이름: `openclaw-book-A4.pdf` 등으로 입력
5. 저장 위치 선택 → **저장**

> 💡 **Safari 가 다른 브라우저보다 좋은 점**
> - macOS 기본 앱이라 추가 설치 불필요
> - macOS 시스템 PDF 엔진 (Quartz) 으로 출력되어 한글·이모지 폰트가 깔끔
> - 인쇄 대화상자에 "PDF" 버튼이 항상 명확히 보임
>
> ⚠️ **주의**
> - Safari 는 명령줄 `--print-to-pdf` 옵션이 없어서 **자동화·CI 용도로는 부적합**합니다. 자동화 시에는 아래 Chrome/Edge 헤드리스 방법을 쓰세요.
> - 인쇄 대화상자에서 용지 크기를 바꾸려면 **Page Setup** 창을 따로 열거나, 인쇄 대화상자 안의 *"Paper Size"* 드롭다운에서 A4/B5 등을 선택합니다.

### 한 줄로 A4 PDF 자동 생성 (Chrome 헤드리스)

다음은 Chrome 을 화면에 띄우지 않고 백그라운드에서 `print.html` 을 PDF 로 변환하는 방법입니다.
스크립트화·CI 자동화에 적합합니다.

```bash
cd /Users/mo/DEV/llmDev/openclaw-workspace/book
mdbook build

# A4 PDF
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf=openclaw-book-A4.pdf \
  --print-to-pdf-no-header \
  "file://$PWD/build/print.html"
```

각 줄의 의미:

| 항목 | 의미 |
|---|---|
| `mdbook build` | `src/` 의 마크다운을 `build/` 의 HTML 로 정적 빌드합니다. 이 과정에서 `build/print.html` (전 챕터 단일 합본) 이 함께 생성됩니다. |
| `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"` | macOS 에 설치된 Chrome 의 실행 바이너리 절대 경로입니다. (Chrome 미설치라면 [chrome.google.com](https://www.google.com/chrome/) 에서 설치하세요.) |
| `--headless` | UI 창을 띄우지 않고 백그라운드로만 실행합니다. |
| `--disable-gpu` | 헤드리스 모드 안정성용 (구형 macOS 에서 GPU 초기화 실패 방지). |
| `--no-pdf-header-footer` / `--print-to-pdf-no-header` | 페이지 상단·하단의 URL·날짜·페이지번호 자동 표시를 끕니다. (책 본문만 깔끔하게.) |
| `--print-to-pdf=openclaw-book-A4.pdf` | 출력 파일 경로. 현재 디렉터리에 만들어집니다. 절대 경로를 줘도 됩니다. |
| `"file://$PWD/build/print.html"` | 입력 HTML. 로컬 파일을 `file://` 스킴으로 지정합니다. `$PWD` 는 현재 작업 디렉터리. |

**용지 규격을 바꾸고 싶다면** `--print-to-pdf=...` 줄 위에 다음 옵션을 추가합니다 (단위: 인치).

```bash
  --print-to-pdf-paper-width=6.93 \    # B5 = 176mm = 6.93in
  --print-to-pdf-paper-height=9.84 \   # B5 = 250mm = 9.84in
```

자주 쓰는 판형:

| 판형 | 가로 (in) | 세로 (in) | mm |
|---|---|---|---|
| **A4** (기본) | 8.27 | 11.69 | 210×297 |
| **B5** | 6.93 | 9.84 | 176×250 |
| **A5** / 신국판 근사 | 5.83 | 8.27 | 148×210 |
| Letter | 8.5 | 11 | 216×279 |

**여백·배율**도 추가 옵션으로 지정 가능합니다.

```bash
  --print-to-pdf-margin-top=0.4 \      # 단위: 인치 (1in ≈ 25.4mm)
  --print-to-pdf-margin-bottom=0.4 \
  --print-to-pdf-margin-left=0.6 \     # 제본 여백은 살짝 넓게
  --print-to-pdf-margin-right=0.4 \
  --print-to-pdf-scale=1.0 \           # 1.0 = 100% (기본)
```

성공하면 `openclaw-book-A4.pdf` 파일이 같은 폴더에 생깁니다. 부크크·교보 퍼플 등 POD 인쇄소에 그대로 업로드하실 수 있습니다.

> ⚠️ 알아두기
> - `print.html` 은 **부록 A 의 모든 스크립트 전문(全文)** 까지 한 문서에 포함되므로, 결과 PDF 는 200~300 페이지 분량이 됩니다.
> - 한글 폰트는 시스템에 설치된 폰트(Apple SD Gothic Neo 등)를 그대로 사용합니다. 별도 임베드 작업이 필요 없습니다.
> - Chrome 외에 Microsoft Edge 도 동일한 옵션을 지원합니다. (`--print-to-pdf` 등)

## 무삭제 원칙

- 부록 A는 `{{#include ../../../<원본>}}` 지시자로 워크스페이스의 실제 스크립트를 통째로 임베드합니다.
- 본문에서도 코드 블록 안에 `# ... 생략 ...` / `# (이하 동일)` / `...` 등은 사용 금지입니다.
- 같은 스크립트가 여러 장에서 등장해도 **항상 전문**으로 다시 적습니다.
- 검증: [`scripts/check-no-elision.sh`](scripts/check-no-elision.sh)

## 구조

```
book/
├── book.toml
├── README.md           # 이 파일
├── scripts/
│   └── check-no-elision.sh
└── src/
    ├── SUMMARY.md
    ├── 00-cover.md
    ├── 00-preface.md
    ├── part1-why/      # H1·H2
    ├── part2-install/  # H3·H4
    ├── part3-use/      # H5·H6
    ├── part4-deep/     # H7·H8
    ├── appendix-a-scripts/
    ├── appendix-b-env/
    ├── appendix-c-trouble/
    ├── appendix-d-glossary.md
    └── appendix-e-license.md
```
