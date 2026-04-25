# 🌱 진짜 처음부터 — 폴더 만들기부터 / Truly From Zero — Starting From `mkdir`

> 🇰🇷 **누구를 위한 글?** "터미널이 뭐예요? 폴더는 어디에 만들어요? `cd` 가 뭐예요?" 단계.
> 🇬🇧 **For whom?** "What's a terminal? Where do folders even go? What does `cd` do?" level.

이 글이 끝나면 → [QUICKSTART-ko.md](QUICKSTART-ko.md) 또는 [QUICKSTART-en.md](QUICKSTART-en.md) 로 넘어가세요.

## 📖 목차 / Contents

- [🇰🇷 한국어 — 0단계부터](#-한국어--0단계부터)
- [❓ 자주 막히는 부분 (FAQ)](#-자주-막히는-부분-faq)
- [🇬🇧 English — From Step Zero](#-english--from-step-zero)
- [❓ Where people commonly get stuck](#-where-people-commonly-get-stuck)

---

## 🇰🇷 한국어 — 0단계부터

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
