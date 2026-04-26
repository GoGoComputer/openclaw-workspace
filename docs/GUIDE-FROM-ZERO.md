# 🌱 진짜 처음부터 — 폴더 만들기부터 / Truly From Zero — Starting From `mkdir`

> 🇰🇷 **누구를 위한 글?** "터미널이 뭐예요? 폴더는 어디에 만들어요? `cd` 가 뭐예요?" 단계.
> 🇬🇧 **For whom?** "What's a terminal? Where do folders even go? What does `cd` do?" level.

이 글이 끝나면 → [QUICKSTART-ko.md](QUICKSTART-ko.md) 또는 [QUICKSTART-en.md](QUICKSTART-en.md) 로 넘어가세요.

## 📖 목차 / Contents

- [🇰🇷 한국어 — 0단계부터](#-한국어--0단계부터)
  - [−1단계: 컬퓨터·GUI·CLI 기초 용어 (클릭이 뭐예요?)](#1단계-컬퓨터gui-cli-기초-용어-클릭이-뭐예요)
- [❓ 자주 막히는 부분 (FAQ)](#-자주-막히는-부분-faq)
- [🇬🇧 English — From Step Zero](#-english--from-step-zero)
  - [Step −1: Computer·GUI·CLI vocabulary (what does "click" mean?)](#step-1-computergui-cli-vocabulary-what-does-click-mean)
- [❓ Where people commonly get stuck](#-where-people-commonly-get-stuck)

---

## 🗺 이 문서를 처음 보신다면 / Document Map

이 문서는 **터미널을 한 번도 써본 적 없는** 분을 가정합니다. 한국어/영어 거울 구조:

| 부 | 내용 |
|---|---|
| 🇰🇷 [한국어 — 0단계부터](#-한국어--0단계부터) | −1단계 (클릭/더블클릭/우클릭) → 0단계 (터미널 열기) → 1~5단계 (필수 명령 5개) → git clone 설치 |
| ❓ [한국어 FAQ](#-자주-막히는-부분-faq) | "엔터를 쳤는데 아무 반응이 없어요" 등 자주 막히는 곳 |
| 🇬🇧 [English — From Step Zero](#-english--from-step-zero) | 같은 내용의 영문 거울 |
| ❓ [English FAQ](#-where-people-commonly-get-stuck) | English version of common pitfalls |

> 🎯 **첫 방문 권장**: 한국어 또는 영어 중 한 쪽만 끝까지 → 다음으로 [QUICKSTART-ko.md](QUICKSTART-ko.md) / [QUICKSTART-en.md](QUICKSTART-en.md).

---

## 🇰🇷 한국어 — 0단계부터

### −1단계: 컬퓨터·GUI·CLI 기초 용어 (클릭이 뭐예요?)

> "마우스는 써봤는데 클릭·더블클릭·우클릭이 뭐가 다른지 모르겠어요" 의 단계. 이미 아시면 다음 섹션으로 건너뛰세요.

#### 클릭 / 더블클릭 / 우클릭 / 드래그

| 용어 | 동작 | 의미 |
|---|---|---|
| **클릭 (click)** | 트랙패드/마우스 버튼을 한 번 높뀸 누르고 뗼 | "이거 골랐어" 의 의미. 아이콘이 잠깐 파래짐 |
| **더블클릭** | 빠르게 두 번 연속 클릭 | "이걸 열어". 앱·폴더·파일이 실제로 실행/열림 |
| **우클릭** | 마우스 오른쪽 버튼 / 트랙패드에서 두 손가락으로 클릭 | "이 항목 의 메뉴" 표시 (복사/삭제/이름 바꾸기 등) |
| **드래그 (drag)** | 버튼을 누른 채로 이동 | 아이콘을 집어서 옮김 |
| **드롭 (drop)** | 드래그 끝에 버튼을 뗼 | 옮긴 자리에 놓음 |

> 💱 맥북 트랙패드 설정: 시스템 설정 > 트랙패드 > "두 손가락으로 탭하여 보조 클릭" 체크 → 그게 **우클릭** 입니다.

#### GUI vs CLI (그래픽 화면 vs 명령줄)

| | **GUI** (Graphical User Interface) | **CLI** (Command Line Interface) |
|---|---|---|
| 예 | Finder, Safari, 설정, 메모 | 터미널(Terminal.app) |
| 입력 | 마우스 클릭 / 터치 | 글자 타이핑 + Enter |
| 장점 | 직관적, 아이콘으로 따라가면 됨 | 빠르고, 자동화·복사/붙여넣기 가능, 멀리 있는 서버도 제어 |
| 단점 | 자동화 어려움, 버튼 앤 도달 까지 느림 | 처음에는 명령어를 외워야 함 |
| 비유 | 식당에서 사진 메뉴 고르기 | 주방장에게 "그 요리, 매운맛, 2인분" 라고 말로 주문 |

**핵심**: 명령줄은 "와, 난 개발자가 아닌데 못 쓰겠지?" 하는 게 아니라 **설치 자동화를 위해 5【6줄 쳤다 끈는 용도** 입니다. 특별한 게 있다면, 의결이 설치 끝난 뒤 다시 켜서 클릭하는 건 GUI 로 돌아가서 하면 됩니다.

#### 창 / 메뉴바 / 독(Dock)

```
┌─ 메뉴바 (화면 맨 위) ──────────────────────────────────┐
│  Terminal  세션  편집  보기  창  도움말           🔋 100%  Q  │
└────────────────────────────────────────────────────────────┘
┌─ 창 (window) ─────────────────────────────────┐
│ 🔴 🟡 🟢  제목                                              │
│     ↑ 닫기 / 최소화 / 최대화                          │
│                                                          │
│  yourname@MacBook-Pro ~ %                                │
└──────────────────────────────────────────────────┘
┌─ Dock (화면 아래) ───────────────────────────┐
│  Finder  Safari  메모  Terminal  ...                  │
└──────────────────────────────────────────────────┘
```

- **🔴 빨강 동그라미** — 창 닫기 (앱은 종료 안 될 수 있음)
- **🟡 노랑** — 최소화 (Dock 으로 숨김)
- **🟢 초록** — 최대화 / 전체 화면 (`option`+클릭 하면 원래 크기)
- **메뉴바**는 항상 화면 맨 위 — **계속 건드리세요**, 단축키는 여기서 찾아봅니다 (예: 편집 > 붙여넣기 의 `⌘V`).

#### 파일 / 폴더 / 경로 (Path)

- **파일 (file)** = 하나의 문서·그림·아이콘. 아이콘 1개.
- **폴더 (folder = directory)** = 파일들을 담는 상자. 무한히 중첩 가능.
- **경로 (path)** = "어느 서랍의 어느 킨의 어느 쪽" 을 주소로 적은 것. 예: `/Users/mo/Documents/매모.txt`
  - `/` 는 폴더 구분자 (맥/리눅스). 창원도우의 `\` 와 다름.
  - `/` 하나로 시작하면 = 디스크 맨 위 (루트) 부터의 절대경로.
  - `~` = 내 홈 폴더 (`/Users/내아이디`).
  - `.` = 지금 있는 폴더 (현재).
  - `..` = 한 단계 위 폴더 (부모).

#### Finder vs Terminal: 같은 폴더를 둘 다르게 보고 있을 뿐

```
Finder 에서          ⇔   Terminal 에서
  ~ (홈)               =   pwd 결과 /Users/yourname
  폴더 더블클릭     =   cd 폴더이름
  상위 폴더 가기   =   cd ..
  새 폴더 만들기     =   mkdir 이름
  파일 삭제           =   rm 파일이름    (휴지통 안 감. 증습 삭제)
  이름 바꾸기/이동    =   mv 이전이름 새이름
  복사하기           =   cp 원본 사본
```

> 💡 **Finder 에서 현재 위치의 경로를 보는 법**: Finder > 보기 > "경로 막대 표시". 창 아래에 `💻 맥 > Users > 내이름 > 문서` 가 뜨면 = `/Users/내이름/문서`.

#### 대소문자 / 공백 / 숨김 파일

- macOS 커맨드는 **대소문자 구분** (`Documents` ≠ `documents`).
- **공백이 들어간 파일명**은 따옷표로 묶거나 역슬래쉬로 보호: `cd "My Folder"` 또는 `cd My\ Folder`.
- **·으로 시작하는 파일** (예: `.env`, `.gitignore`)은 Finder 에서 숨겨져 있음. 트글: `⌘ + Shift + .` (도트). Terminal 에서는 `ls -a`.

#### 커서 깜빡임·고령 아이콘·키보드

- 터미널에서 비밀번호 칠 때 **그 어떤 표시도 안 떨** (★ 도 • 도 안 뜨는 게 정상). 타이핑이 안 되는 게 아닌가요.
- 마우스 포인터가 마치컰따를 돌려주는 **프로퍼러(고령)** = 맥이 시간 걸리는 작업 중 (설치/다운로드). 기다릴 것.
- **커먬드 키 = `⌘`** (Cmd, 스페이스바 양 옥), **옵션 = `⌥`**, **쉬프트 = `⇧`**, **컨트롤 = `⌃`**.
- 붙이기 단축키는 Finder/대부분 앱 = `⌘V`. **터미널 안에서도 `⌘V`** (Linux 의 `Ctrl+V` 와 다름).

#### 이 가이드가 쓰는 손짓 약속

- ` ` (앞에 공백 있는 줄) → 명령어 결과 설명.
- `$` 또는 `%` 로 시작하는 줄 → 터미널에 칠 명령 (`$`/`%` 는 치지 않음 — 프롬프트 표시일 뿐).
- `# 주석` → 설명, 실행에 영향 없음.
- `<꼬씬논 괄호>` → "여기는 당신 값으로 교체" (예: `<내아이디>` → `mo`).

---

### 0. 마음의 준비

- 터미널 = "Finder 의 텍스트 버전". 마우스로 클릭하던 걸 글자로 친다고 보면 됩니다.
- 명령어를 잘못 쳐도 컴퓨터는 "그런 명령 없음" 이라 답할 뿐, 망가지지 않습니다. **편하게 쳐보세요.**
- 모든 명령은 Enter 키를 눌러야 실행됩니다.

### 1. 터미널 열기

```
⌘(커맨드) + Space → "터미널" 입력 → Enter
```

검은(또는 흰) 창이 뜨고, 마지막 줄 끝이 `%` (또는 `$`) 면 입력 대기 중. 그 뒤에 명령을 칩니다.

```
yourname@MacBook-Pro ~ %  ← 여기 뒤에 입력
```

### 2. "지금 내가 어디 있지?" — `pwd`

```bash
pwd
```

`pwd` = "Print Working Directory" (지금 폴더). 이런 게 뜹니다:

```
/Users/yourname
```

이게 여러분의 **홈 폴더** 입니다. Finder 의 "🏠 yourname" 과 같은 곳. 줄여서 `~` (틸드) 라고도 씁니다.

### 3. "여기에 뭐가 있지?" — `ls`

```bash
ls
```

폴더 안의 파일·폴더 목록이 나옵니다:

```
Applications  Desktop  Documents  Downloads  Movies  Music  Pictures  Public
```

### 4. 새 폴더 만들기 — `mkdir`

OpenClaw 작업용 폴더를 홈에 하나 만들어 봅시다.

```bash
mkdir ~/openclaw-workspace
```

`mkdir` = "Make Directory" (폴더 만들기). 아무 메시지가 안 나오면 **성공** (유닉스 관습: 조용 = 잘됨).

확인:
```bash
ls ~
```
목록에 `openclaw-workspace` 가 보이면 OK.

### 5. 그 폴더로 들어가기 — `cd`

```bash
cd ~/openclaw-workspace
```

`cd` = "Change Directory" (폴더 이동). 다시 `pwd` 쳐보면:
```
/Users/yourname/openclaw-workspace
```

> 💡 **꿀팁**: `cd ~` 만 치면 홈으로 돌아옵니다. `cd ..` 는 한 단계 위 폴더로.

### 6. 핵심 5개 명령 정리

| 명령 | 의미 | 예시 |
|---|---|---|
| `pwd` | 지금 어디? | `pwd` |
| `ls` | 여기 뭐 있어? | `ls`, `ls ~/Documents` |
| `cd` | 폴더 이동 | `cd ~/openclaw-workspace`, `cd ..` |
| `mkdir` | 폴더 만들기 | `mkdir my-project` |
| `clear` | 화면 지우기 | `clear` |

이 5개만 알면 시작하기에 충분합니다.

### 7. 이제 OpenClaw 설치 — git clone

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/DEV/openclaw-workspace
mkdir -p ~/.local/bin
ln -sf ~/DEV/openclaw-workspace/openclaw-mgr/openclaw ~/.local/bin/openclaw
```

`git clone` = GitHub 에서 코드 받아오기. `ln -sf` = 어디서나 `openclaw` 명령어를 쓸 수 있도록 단축어 만들기. `~/.local/bin` 이 `$PATH` 에 없으면 줄을 추가하거나 `~/DEV/openclaw-workspace/openclaw-mgr/openclaw` 전체 경로를 쓰세요.

### 8. 설치 끝났는지 확인

```bash
openclaw version
```

`openclaw-mgr 0.1.3` 같은 게 뜨면 성공.

### 9. 이제 본격 시작

```bash
openclaw
```

대화형 메뉴가 한국어로 뜹니다. **번호만 누르면 됩니다.** `2` 를 눌러서 자동 설치를 시작하세요.

### 10. 다음에 할 일

이 가이드는 여기까지. 더 자세한 단계별 출력 예시는:
- 🇰🇷 [QUICKSTART-ko.md](QUICKSTART-ko.md) — 터미널 화면 그대로 따라하기
- 📖 [GUIDE-OPENCLAW.md](GUIDE-OPENCLAW.md) — OpenClaw 가 뭔지 3분 설명
- 📖 [GUIDE-OLLAMA.md](GUIDE-OLLAMA.md) — 로컬 LLM 이해
- 📖 [GUIDE-DOCKER.md](GUIDE-DOCKER.md) — 왜 컨테이너에 가두는지

---

## ❓ 자주 막히는 부분 (FAQ)

<details>
<summary><b>"command not found: openclaw" 가 뜹니다</b></summary>

설치 직후엔 PATH 가 갱신 안 됐을 수 있습니다. 새 터미널 창을 열거나:
```bash
exec $SHELL
```
이래도 안 되면 Homebrew 가 PATH 에 안 들어갔을 수 있어요:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```
</details>

<details>
<summary><b>"Permission denied" 라고 합니다</b></summary>

권한 문제. 보통은 설치 중 sudo 비밀번호를 안 쳤거나, 폴더 소유자가 다른 경우. 메시지를 그대로 복사해 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 에서 검색해보세요.
</details>

<details>
<summary><b>화면이 갑자기 멈춘 것 같아요</b></summary>

다운로드 중일 가능성이 큽니다. 1~2분 기다려보고, 키보드 입력에도 반응이 없으면 `Ctrl + C` (컨트롤 + C) 로 취소 후 다시 시도.
</details>

<details>
<summary><b>실수로 이상한 명령을 쳤어요. 망가졌나요?</b></summary>

99% 안 망가졌습니다. 위에서 만든 폴더가 이상하면 `rm -rf ~/openclaw-workspace` 로 지우고 처음부터. (단, **`rm -rf ~` 또는 `rm -rf /` 는 절대 금지** — 시스템 전체가 날아갑니다.)
</details>

<details>
<summary><b>Homebrew 설치 중 계속 비밀번호를 묻습니다</b></summary>

정상입니다. Homebrew 자체 설치 + 의존성 설치 중 한두 번 물어볼 수 있습니다. 평소 맥 로그인 비밀번호 입력. (입력 시 별표·점 표시도 안 나오는 게 정상)
</details>

---

## 🇬🇧 English — From Step Zero

### Step −1: Computer·GUI·CLI vocabulary (what does "click" mean?)

> For people who have used a Mac but never thought about the difference between "click", "double-click", and "right-click". If you know all of this, skip ahead.

#### Click / double-click / right-click / drag

| Term | Action | Meaning |
|---|---|---|
| **Click** | Press the trackpad/mouse button once | "I picked this". The icon flashes briefly. |
| **Double-click** | Two fast clicks in a row | "Open this". The app/folder/file actually launches. |
| **Right-click** | Right mouse button / two-finger tap on trackpad | Show context menu (Copy / Delete / Rename...). |
| **Drag** | Hold the button down while moving | You're carrying the icon. |
| **Drop** | Release the button at the destination | You set it down. |

> 💱 Mac trackpad: System Settings > Trackpad > enable "Secondary click" (two-finger tap) — that **is** right-click.

#### GUI vs CLI (graphical screen vs command line)

| | **GUI** (Graphical User Interface) | **CLI** (Command Line Interface) |
|---|---|---|
| Examples | Finder, Safari, Settings, Notes | Terminal.app |
| Input | Mouse clicks / touches | Typed text + Enter |
| Pros | Intuitive, follow icons | Fast, scriptable, copy-paste, can drive remote servers |
| Cons | Hard to automate, slow when there are many steps | You have to learn commands |
| Analogy | Pointing at pictures on a restaurant menu | Telling the chef "that ingredient, spicy, party of two" in words |

**The point**: the command line is not for showing off — it's the most reliable way to **automate a 5–10-line install**. After install you can go back to the GUI and click as usual.

#### Window / menu bar / Dock

```
┌─ Menu bar (very top of screen) ──────────────────────┐
│  Terminal  Shell  Edit  View  Window  Help    🔋 100%  Q  │
└──────────────────────────────────────────────────────┘
┌─ Window ───────────────────────────────────┐
│ 🔴 🟡 🟢  Title                                          │
│     ↑ close / minimize / zoom                          │
│                                                          │
│  yourname@MacBook-Pro ~ %                                │
└──────────────────────────────────────────────────┘
┌─ Dock (bottom of screen) ──────────────────┐
│  Finder  Safari  Notes  Terminal  ...                  │
└──────────────────────────────────────────────────┘
```

- **🔴 red** — close window (the app may still keep running).
- **🟡 yellow** — minimize (hide into the Dock).
- **🟢 green** — zoom / fullscreen (Option-click for original size).
- The **menu bar** stays at the top of the screen — keep looking up there for options and shortcuts (e.g. Edit > Paste = `⌘V`).

#### File / folder / path

- **File** = a single document, image, or icon. One icon = one file.
- **Folder (= directory)** = a box that holds files. Folders can nest infinitely.
- **Path** = the address "which drawer, which shelf, which side". Example: `/Users/mo/Documents/memo.txt`.
  - `/` separates folders (Mac/Linux). Windows uses `\`.
  - A path starting with `/` is **absolute**, from the disk root.
  - `~` = your home folder (`/Users/yourname`).
  - `.` = the current folder.
  - `..` = one folder up (the parent).

#### Finder vs Terminal: same folders, two views

```
In Finder              ⇔   In Terminal
  ~ (Home)              =   pwd shows /Users/yourname
  Double-click folder   =   cd foldername
  Go to parent          =   cd ..
  New folder            =   mkdir name
  Delete file           =   rm filename    (no Trash! permanent)
  Rename / move         =   mv oldname newname
  Copy                  =   cp source dest
```

> 💡 To see the current path in Finder: View > Show Path Bar. The bar at the bottom (`💻 Mac > Users > you > Documents`) = `/Users/you/Documents`.

#### Case sensitivity / spaces / hidden files

- macOS commands are **case-sensitive** (`Documents` ≠ `documents`).
- **Filenames with spaces** must be quoted or escaped: `cd "My Folder"` or `cd My\ Folder`.
- Files starting with `.` (e.g. `.env`, `.gitignore`) are hidden in Finder. Toggle: `⌘ + Shift + .` (period). In Terminal: `ls -a`.

#### Cursor / spinner / keyboard

- Terminal hides typed passwords completely — **no dots, no asterisks**. Keep typing; that's normal.
- A spinning beach ball means the Mac is busy (installing/downloading). Wait it out.
- **`⌘` = Command** (the keys next to spacebar), **`⌥` = Option**, **`⇧` = Shift**, **`⌃` = Control**.
- Paste shortcut is `⌘V` everywhere on macOS, **including Terminal** (unlike Linux's `Ctrl+V`).

#### Conventions used in this guide

- Lines starting with whitespace = explanation of the result.
- Lines starting with `$` or `%` = type into Terminal (don't include the `$`/`%`; that's the prompt).
- `# comment` = explanation, ignored when run.
- `<angle brackets>` = replace with your value (e.g. `<your-id>` → `mo`).

---

### 0. Mindset

- The terminal = "the text version of Finder". You type instead of clicking.
- Typing a wrong command just prints "command not found" — your computer is **not** at risk. Experiment freely.
- Every command needs **Enter** to run.

### 1. Open Terminal

```
⌘(Command) + Space → type "terminal" → Enter
```

A black (or white) window appears. The last line ending in `%` (or `$`) means it's ready for input.

```
yourname@MacBook-Pro ~ %  ← type here
```

### 2. "Where am I?" — `pwd`

```bash
pwd
```

Prints the current folder:
```
/Users/yourname
```

That's your **home folder** — same place as Finder's "🏠 yourname". Shorthand: `~` (tilde).

### 3. "What's here?" — `ls`

```bash
ls
```

Lists files and folders:
```
Applications  Desktop  Documents  Downloads  Movies  Music  Pictures  Public
```

### 4. Create a new folder — `mkdir`

```bash
mkdir ~/openclaw-workspace
```

`mkdir` = "Make Directory". No output = **success** (Unix convention: silence is good).

Verify:
```bash
ls ~
```
You should now see `openclaw-workspace` in the list.

### 5. Go into that folder — `cd`

```bash
cd ~/openclaw-workspace
```

`cd` = "Change Directory". Now `pwd` shows:
```
/Users/yourname/openclaw-workspace
```

> 💡 Tips: `cd ~` returns to home. `cd ..` goes up one level.

### 6. The five essential commands

| Command | Meaning | Example |
|---|---|---|
| `pwd` | Where am I? | `pwd` |
| `ls` | What's here? | `ls`, `ls ~/Documents` |
| `cd` | Move to a folder | `cd ~/openclaw-workspace`, `cd ..` |
| `mkdir` | Create a folder | `mkdir my-project` |
| `clear` | Clear the screen | `clear` |

These five are enough to start.

### 7. Install OpenClaw — git clone

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/DEV/openclaw-workspace
mkdir -p ~/.local/bin
ln -sf ~/DEV/openclaw-workspace/openclaw-mgr/openclaw ~/.local/bin/openclaw
```

`git clone` downloads the code from GitHub. `ln -sf` creates a shortcut so you can run `openclaw` from anywhere. If `~/.local/bin` is not in your `$PATH`, either add it or use the full path `~/DEV/openclaw-workspace/openclaw-mgr/openclaw`.

> 💡 If a **password prompt** shows up, that's your Mac login password (Homebrew needs permission for system paths). It's normal that **nothing appears as you type** — keep typing and press Enter.

### 8. Verify

```bash
openclaw version
```

Output like `openclaw-mgr 0.1.3` means success.

### 9. Real start

```bash
openclaw
```

Interactive menu opens (auto-detects English). **Just press numbers.** Press `2` to start the auto-install.

### 10. What to read next

This guide ends here. For more detailed walkthroughs:
- 🇬🇧 [QUICKSTART-en.md](QUICKSTART-en.md) — terminal-by-terminal walkthrough
- 📖 [GUIDE-OPENCLAW.md](GUIDE-OPENCLAW.md) — what OpenClaw is, in 3 minutes
- 📖 [GUIDE-OLLAMA.md](GUIDE-OLLAMA.md) — understanding local LLMs
- 📖 [GUIDE-DOCKER.md](GUIDE-DOCKER.md) — why we sandbox in a container

---

## ❓ Where people commonly get stuck

<details>
<summary><b>"command not found: openclaw"</b></summary>

PATH may not have refreshed. Open a new Terminal window, or:
```bash
exec $SHELL
```
If that fails, Homebrew might not be on PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```
</details>

<details>
<summary><b>"Permission denied"</b></summary>

A permission issue — usually means a sudo password wasn't entered, or a folder is owned by someone else. Copy the exact message and search [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
</details>

<details>
<summary><b>The screen seems frozen</b></summary>

Most likely a download in progress. Wait 1–2 minutes; if it's truly stuck and the keyboard does nothing, press `Ctrl + C` to cancel and retry.
</details>

<details>
<summary><b>I typed something weird. Did I break my Mac?</b></summary>

99% no. If the folder we made is messed up, just delete it: `rm -rf ~/openclaw-workspace` and start over. (But **never run `rm -rf ~` or `rm -rf /`** — that wipes everything.)
</details>

<details>
<summary><b>Homebrew keeps asking for my password</b></summary>

Normal. The Homebrew installer (and some of its dependencies) may ask once or twice. It's your Mac login password. (No asterisks/dots will appear as you type — that's also normal.)
</details>

---

<!-- RELATED-DOCS:BEGIN -->
## 🔗 관련 문서 / Related docs

| 문서 | 무엇이 있나 |
|---|---|
| [🚀 빠른 시작 (KO)](QUICKSTART-ko.md) | 터미널 열기 → 5개 명령 → 한 줄 설치 |
| [🚀 Quickstart (EN)](QUICKSTART-en.md) | Open terminal → 5 commands → one-liner install |
| [🪜 완전 수동 설치](GUIDE-MANUAL-INSTALL.md) | brew/스크립트 없이 직접 다운 (KO+EN, 프로덕션 부록) |
| [🐳 Docker 기초](GUIDE-DOCKER.md) | 컨테이너·이미지·compose 3분 가이드 |
| [🧠 Ollama 기초](GUIDE-OLLAMA.md) | 로컬 LLM 데몬 사용법 |
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
