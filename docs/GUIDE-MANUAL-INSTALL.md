# 🪜 완전 수동 설치 가이드 / Fully Manual Install Guide

> 🇰🇷 Homebrew·스크립트 없이 **공식 사이트에서 직접 다운로드**해서 설치하는 방법입니다.
> 🇬🇧 Install everything by **downloading directly from official websites** — no Homebrew, no install scripts.

이 문서가 필요한 사람:
- 🛡 **회사 정책**상 `curl | bash` 형태의 원라인 인스톨러를 못 쓰는 분
- 🌐 **GitHub 502 / 네트워크 장애** 로 brew/`scripts/install.sh` 가 계속 실패하는 분
- 🔍 **각 컴포넌트가 무엇인지 눈으로 확인**하고 한 단계씩 직접 깔고 싶은 분
- 💼 **회사 IT 팀**에 "이 파일이 필요합니다" 라고 보여줄 자료가 필요한 분

빠른 길 (자동) 을 원하면 [README.md](../README.md#-30초-설치-터미널에-그대로-붙여넣기) 의 한 줄 인스톨러를 쓰세요.

---

## 🇰🇷 한국어

### 0단계 — 준비물 확인

| 항목 | 최소 | 권장 |
|---|---|---|
| macOS | 13 (Ventura) | 15 (Sequoia) 이상 |
| RAM | 16GB | 24GB 이상 |
| 디스크 여유 | 30GB | 60GB |
| 칩 | Intel / Apple Silicon 모두 OK | Apple Silicon (M1+) |

터미널 여는 법: `⌘ Space` → "터미널" 입력 → Enter. (모르겠으면 [GUIDE-FROM-ZERO.md](GUIDE-FROM-ZERO.md))

칩 확인:
```bash
uname -m
# arm64  → Apple Silicon (M1/M2/M3/M4/M5)
# x86_64 → Intel
```

### 1단계 — Xcode Command Line Tools (Git 등 기본 도구)

터미널에서:
```bash
xcode-select --install
```

다이얼로그가 뜨면 **설치** 클릭 → 약관 동의 → 약 5~10분 대기. 이미 깔려 있으면 `command line tools are already installed` 메시지가 나옵니다 (정상).

확인:
```bash
git --version       # git version 2.x 가 나오면 OK
clang --version
```

### 2단계 — Docker Desktop 직접 다운로드

> Docker = 컨테이너(격리된 가상 환경) 를 돌리는 엔진. OpenClaw 가 호스트 시스템을 망가뜨리지 못하게 막는 핵심.

1. 공식 다운로드 페이지 방문: **https://www.docker.com/products/docker-desktop/**
2. **Download for Mac** 버튼 클릭. 칩에 맞는 것 선택:
   - **Apple Silicon** (`uname -m` 이 `arm64`): "Mac with Apple chip"
   - **Intel**: "Mac with Intel chip"
3. `Docker.dmg` 파일이 다운로드 폴더에 떨어집니다 (~600MB).
4. `.dmg` 더블클릭 → **Docker.app** 을 **Applications** 폴더로 드래그.
5. **Applications → Docker** 더블클릭으로 처음 실행 → 약관 동의 → 권한 다이얼로그(헬퍼 설치) 통과 → 메뉴바 우측 상단에 🐳 고래 아이콘 등장.
6. 고래 아이콘이 멈춘 상태(움직이지 않음) = 준비 완료.

확인:
```bash
docker --version       # Docker version 27.x ...
docker compose version # Docker Compose version v2.x ...
docker info            # Server: ... 가 보이면 데몬 정상
```

> 💡 회사용/큰 조직 (250인 이상) 은 Docker Desktop 유료 라이선스가 필요할 수 있습니다. 무료 대안: **Colima** (`brew install colima`, Homebrew 가능할 때만).

### 3단계 — Ollama 직접 다운로드 (선택 — 로컬 LLM 쓸 때)

> Ollama = 내 컴퓨터에서 LLM(Llama, Qwen, Solar 등) 을 돌리는 런타임. 외부 API(OpenAI 등) 만 쓸 거면 이 단계는 건너뛰어도 됩니다.

1. 공식 다운로드 페이지: **https://ollama.com/download**
2. **Download for macOS** → `Ollama-darwin.zip` 또는 `.dmg` 받기 (~200MB).
3. zip 이면 더블클릭으로 풀고, **Ollama.app** 을 **Applications** 로 드래그.
4. **Applications → Ollama** 더블클릭 → 메뉴바에 🦙 라마 아이콘 등장 → 백그라운드로 데몬이 떠 있음.

확인:
```bash
ollama --version
ollama list           # 처음엔 빈 목록 (NAME  ID  SIZE  MODIFIED)
curl -s http://localhost:11434/api/version    # {"version":"0.x.x"}
```

모델 한 개 받아보기:
```bash
ollama pull qwen2.5-coder:7b   # 약 5GB, 5~15분
ollama list                     # qwen2.5-coder:7b 보이면 OK
```

> 💡 첫 모델은 작은 걸로 (`qwen2.5-coder:7b`, `llama3.1:8b`). 24GB RAM 기준 7~8B 가 안전선.

### 4단계 — openclaw-workspace 소스 직접 받기

#### 방법 A — Git clone (권장, 가장 깔끔)

```bash
mkdir -p ~/DEV
cd ~/DEV
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace
ls    # README.md, openclaw-mgr/, docs/ 등이 보이면 OK
```

#### 방법 B — ZIP 파일 직접 다운로드 (Git 도 못 쓸 때)

1. 브라우저로 **https://github.com/GoGoComputer/openclaw-workspace** 방문.
2. 초록색 **`<> Code`** 버튼 → **Download ZIP**.
3. 다운로드 폴더에 `openclaw-workspace-main.zip` 떨어짐.
4. 더블클릭으로 풀기 → 원하는 곳으로 이동:
   ```bash
   mkdir -p ~/DEV
   mv ~/Downloads/openclaw-workspace-main ~/DEV/openclaw-workspace
   cd ~/DEV/openclaw-workspace
   ```

#### 방법 C — 특정 릴리스 tarball (안정 버전 고정)

1. **https://github.com/GoGoComputer/openclaw-workspace/releases** 방문.
2. 원하는 버전 (예: **v0.1.6**) 의 **Source code (tar.gz)** 우클릭 → "다른 이름으로 링크 저장" 또는 그냥 클릭해서 받기.
3. 풀기:
   ```bash
   mkdir -p ~/DEV
   cd ~/DEV
   tar -xzf ~/Downloads/openclaw-workspace-0.1.6.tar.gz
   mv openclaw-workspace-0.1.6 openclaw-workspace
   cd openclaw-workspace
   ```

### 5단계 — `openclaw` 첫 실행

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

다음과 비슷한 표가 나와야 정상:
```
[doctor]
OS                    ✓ macOS 15.x
Xcode CLT             ✓
Homebrew              ⚠ (없어도 무방 — 수동 설치 모드)
Docker                ✓ 27.x
Docker daemon         ✓ running
Ollama                ✓ 0.x  (선택)
Ollama daemon         ✓
RAM                   ✓ 24GB
Disk free             ✓ 60GB
```

`✗` 가 있으면 어느 단계가 실패했는지 다시 점검. 모두 ✓ 면:

```bash
./openclaw install     # 부족분만 자동 설치 — 수동으로 다 깔았으면 대부분 [skip]
./openclaw start       # OpenClaw 컨테이너 기동
./openclaw logs        # 로그 보기 (Ctrl+C 로 빠져나오기)
```

브라우저로 **http://localhost:8000** 열기 → OpenClaw UI 등장.

### 6단계 — PATH 등록 (선택, 어디서나 `openclaw` 한 단어로 실행)

```bash
# zsh 사용자 (macOS 기본)
echo 'export PATH="$HOME/DEV/openclaw-workspace/openclaw-mgr:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 확인
which openclaw         # /Users/이름/DEV/openclaw-workspace/openclaw-mgr/openclaw
openclaw doctor        # ./ 없이도 동작
```

또는 symlink:
```bash
sudo ln -sf "$HOME/DEV/openclaw-workspace/openclaw-mgr/openclaw" /usr/local/bin/openclaw       # Intel
sudo ln -sf "$HOME/DEV/openclaw-workspace/openclaw-mgr/openclaw" /opt/homebrew/bin/openclaw    # Apple Silicon
```

### 7단계 — 업데이트는 어떻게?

수동 설치 모드에서는 **Git 으로 직접 갱신**:
```bash
cd ~/DEV/openclaw-workspace
git pull --ff-only
./openclaw-mgr/openclaw update    # 컨테이너/모델 갱신
```

특정 안정 버전으로 고정하고 싶으면:
```bash
cd ~/DEV/openclaw-workspace
git fetch --tags
git checkout v0.1.6
```

> ⚠️ 수동 설치 환경에서는 `openclaw self-update` 가 의도적으로 비활성됩니다 (Homebrew formula 가 아니므로). 항상 `git pull` 을 쓰세요.

### ❓ 자주 막히는 부분

| 증상 | 원인 / 해결 |
|---|---|
| `command not found: docker` | Docker Desktop 이 안 깔렸거나 첫 실행을 안 함. 5단계 다시. |
| 메뉴바에 고래 아이콘 없음 | Applications → Docker 더블클릭. |
| `Cannot connect to the Docker daemon` | Docker Desktop 데몬이 시동 중. 30~60초 대기 후 재시도. |
| `port 8000 already in use` | 다른 앱이 8000 점유. `lsof -nP -iTCP:8000 -sTCP:LISTEN` 으로 확인. |
| `port 11434 already in use` | Ollama 가 이미 떠 있음 (정상). 아무것도 할 필요 없음. |
| ZIP 다운이 자꾸 깨짐 | GitHub 502. 잠시 후 재시도 또는 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 의 502 섹션 참조. |
| `xcrun: error: invalid active developer path` | Xcode CLT 손상. `sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install` |

더 많은 사례는 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 참조.

### 🗑 완전 제거 (수동 설치한 경우)

```bash
# 1) 컨테이너·볼륨 정리 (백업 먼저!)
~/DEV/openclaw-workspace/openclaw-mgr/openclaw backup --name before-uninstall
~/DEV/openclaw-workspace/openclaw-mgr/openclaw uninstall

# 2) 소스 폴더 삭제
rm -rf ~/DEV/openclaw-workspace

# 3) Docker Desktop 제거: Applications 에서 Docker.app 휴지통으로 + 메뉴 → Troubleshoot → Uninstall
# 4) Ollama 제거 (선택): Applications 에서 Ollama.app 휴지통으로
rm -rf ~/.ollama       # 모델 파일까지 (수GB 절약)

# 5) PATH 등록 줄 제거
$EDITOR ~/.zshrc       # openclaw 관련 줄 삭제
```

---

## 🇬🇧 English

### Step 0 — Prerequisites

| Item | Min | Recommended |
|---|---|---|
| macOS | 13 (Ventura) | 15 (Sequoia)+ |
| RAM | 16 GB | 24 GB+ |
| Free disk | 30 GB | 60 GB |
| Chip | Intel or Apple Silicon | Apple Silicon (M1+) |

Open Terminal: `⌘ Space` → "Terminal" → Enter. (New to terminals? See [GUIDE-FROM-ZERO.md](GUIDE-FROM-ZERO.md).)

Check chip:
```bash
uname -m
# arm64  → Apple Silicon
# x86_64 → Intel
```

### Step 1 — Xcode Command Line Tools (Git etc.)

```bash
xcode-select --install
```

Dialog appears → click **Install** → accept → ~5–10 min. Already installed? You'll see `command line tools are already installed` (fine).

Verify:
```bash
git --version
clang --version
```

### Step 2 — Download Docker Desktop directly

> Docker runs containers — isolated mini-environments that protect your Mac from anything OpenClaw does.

1. Open **https://www.docker.com/products/docker-desktop/**
2. Click **Download for Mac** and pick:
   - **Apple Silicon** (if `uname -m` says `arm64`)
   - **Intel** (if `x86_64`)
3. Downloads `Docker.dmg` (~600 MB).
4. Double-click `.dmg` → drag **Docker.app** to **Applications**.
5. Open **Applications → Docker** → accept terms → grant helper permission → 🐳 whale icon appears in the menu bar.
6. Whale stops animating = ready.

Verify:
```bash
docker --version
docker compose version
docker info
```

> 💡 Companies with 250+ employees may need a paid Docker Desktop licence. Free alternative: **Colima** (`brew install colima`, only when Homebrew is allowed).

### Step 3 — Download Ollama directly (optional — for local LLMs)

> Ollama runs LLMs (Llama, Qwen, Solar, …) on your Mac. Skip this step if you'll only use external APIs (OpenAI etc.).

1. Open **https://ollama.com/download**
2. **Download for macOS** → `Ollama-darwin.zip` or `.dmg` (~200 MB).
3. If zip: unzip and drag **Ollama.app** to **Applications**.
4. Open **Applications → Ollama** → 🦙 llama icon appears in menu bar; daemon runs in background.

Verify:
```bash
ollama --version
ollama list
curl -s http://localhost:11434/api/version
```

Pull one model:
```bash
ollama pull qwen2.5-coder:7b   # ~5 GB, 5–15 min
ollama list
```

> 💡 Start small (`qwen2.5-coder:7b`, `llama3.1:8b`). On 24 GB RAM, 7–8 B is the safe ceiling.

### Step 4 — Get openclaw-workspace source

#### Option A — Git clone (recommended)

```bash
mkdir -p ~/DEV
cd ~/DEV
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace
```

#### Option B — Download ZIP via browser

1. Open **https://github.com/GoGoComputer/openclaw-workspace**
2. Green **`<> Code`** → **Download ZIP**.
3. Unzip and move:
   ```bash
   mkdir -p ~/DEV
   mv ~/Downloads/openclaw-workspace-main ~/DEV/openclaw-workspace
   cd ~/DEV/openclaw-workspace
   ```

#### Option C — Pinned release tarball

1. Open **https://github.com/GoGoComputer/openclaw-workspace/releases**
2. Right-click **Source code (tar.gz)** of e.g. **v0.1.6** → save.
3. Extract:
   ```bash
   mkdir -p ~/DEV
   cd ~/DEV
   tar -xzf ~/Downloads/openclaw-workspace-0.1.6.tar.gz
   mv openclaw-workspace-0.1.6 openclaw-workspace
   ```

### Step 5 — First run of `openclaw`

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

Expect something like:
```
[doctor]
OS                    ✓ macOS 15.x
Xcode CLT             ✓
Homebrew              ⚠ (absent but not required in manual mode)
Docker                ✓ 27.x
Docker daemon         ✓ running
Ollama                ✓ 0.x  (optional)
RAM                   ✓ 24GB
Disk free             ✓ 60GB
```

If everything is ✓:
```bash
./openclaw install     # auto-installs missing pieces — mostly [skip] in manual mode
./openclaw start       # start OpenClaw containers
./openclaw logs
```

Open **http://localhost:8000** in your browser → OpenClaw UI.

### Step 6 — Add to PATH (optional)

```bash
echo 'export PATH="$HOME/DEV/openclaw-workspace/openclaw-mgr:$PATH"' >> ~/.zshrc
source ~/.zshrc
which openclaw
openclaw doctor
```

Or symlink:
```bash
sudo ln -sf "$HOME/DEV/openclaw-workspace/openclaw-mgr/openclaw" /usr/local/bin/openclaw       # Intel
sudo ln -sf "$HOME/DEV/openclaw-workspace/openclaw-mgr/openclaw" /opt/homebrew/bin/openclaw    # Apple Silicon
```

### Step 7 — Updating

In manual mode you update via Git:
```bash
cd ~/DEV/openclaw-workspace
git pull --ff-only
./openclaw-mgr/openclaw update
```

Pin to a specific stable tag:
```bash
git fetch --tags
git checkout v0.1.6
```

> ⚠️ `openclaw self-update` is intentionally disabled in manual mode (it's only for the Homebrew formula). Always use `git pull`.

### ❓ Common pitfalls

| Symptom | Cause / Fix |
|---|---|
| `command not found: docker` | Docker Desktop not installed or never opened once. Redo step 2. |
| No whale icon in menu bar | Open Applications → Docker. |
| `Cannot connect to the Docker daemon` | Daemon still starting. Wait 30–60 s. |
| `port 8000 already in use` | Another app holds 8000. Check: `lsof -nP -iTCP:8000 -sTCP:LISTEN` |
| `port 11434 already in use` | Ollama already running (fine). |
| ZIP download keeps failing | GitHub 502. Retry later or see the 502 section in [TROUBLESHOOTING.md](TROUBLESHOOTING.md). |
| `xcrun: error: invalid active developer path` | Broken CLT. `sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install` |

More cases: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### 🗑 Full uninstall (manual-mode)

```bash
# 1) Backup & uninstall containers/volumes
~/DEV/openclaw-workspace/openclaw-mgr/openclaw backup --name before-uninstall
~/DEV/openclaw-workspace/openclaw-mgr/openclaw uninstall

# 2) Delete the source folder
rm -rf ~/DEV/openclaw-workspace

# 3) Remove Docker Desktop: Applications → drag Docker.app to Trash + menu Troubleshoot → Uninstall
# 4) Remove Ollama (optional): Applications → drag Ollama.app to Trash
rm -rf ~/.ollama       # also remove model files (saves several GB)

# 5) Remove PATH line
$EDITOR ~/.zshrc       # delete the openclaw export line
```
