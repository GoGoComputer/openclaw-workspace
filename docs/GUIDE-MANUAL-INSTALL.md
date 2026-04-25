# 🪜 완전 수동 설치 가이드 / Fully Manual Install Guide

> 🇰🇷 Homebrew·스크립트 없이 **공식 사이트에서 직접 다운로드**해서 설치하는 방법입니다.
> 🇬🇧 Install everything by **downloading directly from official websites** — no Homebrew, no install scripts.

이 문서가 필요한 사람:
- 🛡 **회사 정책**상 `curl | bash` 형태의 원라인 인스톨러를 못 쓰는 분
- 🌐 **GitHub 502 / 네트워크 장애** 로 brew/git clone 이 계속 실패하는 분
- 🔍 **각 컴포넌트가 무엇인지 눈으로 확인**하고 한 단계씩 직접 깔고 싶은 분
- 💼 **회사 IT 팀**에 "이 파일이 필요합니다" 라고 보여줄 자료가 필요한 분

빠른 길 (자동) 을 원하면 [README.md](../README.md) 의 git clone 설치 방법을 쓰세요.

## 📖 목차 / Contents

- [⚡ 명령어만 (빠른 복사용) / Commands Only (quick copy)](#-명령어만-빠른-복사용--commands-only-quick-copy)
- [🔐 이 가이드의 보안 원칙 (읽고 시작하세요)](#-이-가이드의-보안-원칙-읽고-시작하세요)
- [🇬🇧 English](#-english)
- [🧰 부록 A: 전문가용 운영 체크리스트 / Production-grade Checklist](#-부록-a-전문가용-운영-체크리스트--production-grade-checklist)
- [🧰 Appendix A: Production-grade Checklist (English mirror)](#-appendix-a-production-grade-checklist-english-mirror)

> 단계 표제(0단계, 1단계, 2단계 …)는 H3 입니다. 위 H2 섹션 내부에 순서대로 들어 있습니다.

---

## ⚡ 명령어만 (빠른 복사용) / Commands Only (quick copy)

> 설명 없이 명령만 순서대로. 각 명령의 의미가 궁금하면 아래 단계별 섹션을 참고.
> Just the commands in order. See the step-by-step sections below for explanations.

<details>
<summary>🇰🇷 한국어 — 명령어만 펼치기</summary>

```zsh
# ── 0. 칩/OS 확인 ──────────────────────────────────
uname -m          # arm64 = Apple Silicon / x86_64 = Intel
sw_vers           # macOS 버전 확인

# ── 1. Xcode CLT ───────────────────────────────────
xcode-select --install          # 다이얼로그 → 설치 클릭 → 5~10분 대기
# 이미 있으면: "command line tools are already installed"
git --version                   # git version 2.x 가 나오면 OK

# ── 2. Docker Desktop ──────────────────────────────
# 브라우저: https://www.docker.com/products/docker-desktop/
# Apple Silicon: "Download for Mac – Apple Silicon"
# Intel:         "Download for Mac – Intel Chip"
# → .dmg 더블클릭 → Docker 아이콘을 Applications 폴더로 드래그
open -a Docker                  # Docker Desktop 실행
# 메뉴바 🐳 고래가 움직임을 멈출 때까지 30~60초 대기
docker info >/dev/null 2>&1 && echo "✓ daemon up" || echo "✗ daemon down"
docker --version
docker compose version

# ── 3. Ollama (선택 — 로컬 LLM 쓸 때) ─────────────
# 브라우저: https://ollama.com/download
# Download for macOS → .dmg/.zip → Applications 로 드래그 → 실행
ollama --version
ollama list                     # 처음엔 빈 목록
curl -s http://localhost:11434/api/version
# 모델 받기 (원하는 것으로):
# ollama pull <모델>:<태그>      # 예: ollama pull llama3.1:8b

# ── 4. openclaw-workspace 소스 받기 ────────────────
mkdir -p ~/DEV
cd ~/DEV
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace
ls                              # README.md, openclaw-mgr/, docs/ 보이면 OK

# ── 4.5 .env 준비 ──────────────────────────────────
cd openclaw-mgr
cp .env.example .env
chmod 600 .env
# 편집 (필요 시): open -e .env   또는  nano .env
# 최소 확인: OPENCLAW_REPO, OPENCLAW_DIR

# ── 5. 진단 ────────────────────────────────────────
./openclaw doctor
# ✓ 다 보이면 OK / ✗ 있으면 해당 단계 재확인

# ── 5b. OpenClaw 본체 git clone ────────────────────
OPENCLAW_DIR="${HOME}/openclaw"
OPENCLAW_REPO="$(grep '^OPENCLAW_REPO=' .env | cut -d= -f2-)"
[ -z "$OPENCLAW_REPO" ] && OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"
git clone --depth 1 "$OPENCLAW_REPO" "$OPENCLAW_DIR"
ls "$OPENCLAW_DIR"              # docker-compose.yml 보이면 OK

# 5b-.env 머지
SRC="$OPENCLAW_DIR/.env.example"; DST="$OPENCLAW_DIR/.env"
[ -f "$DST" ] || cp "$SRC" "$DST"
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue;; esac
  key="${line%%=*}"
  grep -qE "^${key}=" "$DST" 2>/dev/null || echo "$line" >> "$DST"
done < "$SRC"
chmod 600 "$DST"

# 5b-컨테이너 기동
cd "$OPENCLAW_DIR"
COMPOSE_FILES="-f docker-compose.yml"
[ -f compose.yml ] && COMPOSE_FILES="-f compose.yml"
SEC="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.security.yml"
[ -f "$SEC" ] && COMPOSE_FILES="$COMPOSE_FILES -f $SEC"
docker compose $COMPOSE_FILES up -d
docker compose $COMPOSE_FILES ps   # State=running 확인

# 헬스체크
curl -sS --max-time 5 -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8000
# HTTP 200 이면 UI 열림 → 브라우저: http://localhost:8000

# 네트워크 격리 적용 (보안 권장)
NET="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.network.yml"
[ -f "$NET" ] && COMPOSE_FILES="$COMPOSE_FILES -f $NET"
docker compose $COMPOSE_FILES up -d
mkdir -p "$HOME/.openclaw-mgr" && echo isolated > "$HOME/.openclaw-mgr/network-mode"

# ── 6. PATH 등록 (선택) ────────────────────────────
echo 'export PATH="$HOME/DEV/openclaw-workspace/openclaw-mgr:$PATH"' >> ~/.zshrc
source ~/.zshrc
which openclaw                  # 경로가 나오면 OK

# ── Docker 상태 관리 alias 등록 (선택) ────────────
cat >> ~/.zshrc <<'EOF'
alias dockerstop='osascript -e "quit app \"Docker\"" 2>/dev/null; sleep 3; \
  pkill -TERM -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  sleep 2; \
  pkill -KILL -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ Docker 완전 종료"'
EOF
source ~/.zshrc
type dockerstop                 # alias dockerstop=... 나오면 OK

# ── 최종 확인 ──────────────────────────────────────
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor               # 모두 정상입니다 🎉 가 나오면 완료
```

</details>

<details>
<summary>🇬🇧 English — commands only, expand</summary>

```zsh
# ── 0. Check chip / OS ─────────────────────────────
uname -m          # arm64 = Apple Silicon / x86_64 = Intel
sw_vers

# ── 1. Xcode CLT ───────────────────────────────────
xcode-select --install          # click Install in dialog → ~5–10 min
git --version                   # git version 2.x = OK

# ── 2. Docker Desktop ──────────────────────────────
# Browser: https://www.docker.com/products/docker-desktop/
# Apple Silicon: "Download for Mac – Apple Silicon"
# Intel:         "Download for Mac – Intel Chip"
# → double-click .dmg → drag Docker to Applications
open -a Docker                  # launch Docker Desktop
# wait 30–60 s for menu-bar 🐳 whale to stop animating
docker info >/dev/null 2>&1 && echo "✓ daemon up" || echo "✗ daemon down"
docker --version
docker compose version

# ── 3. Ollama (optional — local LLMs) ──────────────
# Browser: https://ollama.com/download
# Download for macOS → .dmg/.zip → drag to Applications → launch
ollama --version
ollama list
curl -s http://localhost:11434/api/version
# Pull a model (your choice):
# ollama pull <model>:<tag>     # e.g. ollama pull llama3.1:8b

# ── 4. Get openclaw-workspace source ───────────────
mkdir -p ~/DEV
cd ~/DEV
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace
ls                              # README.md, openclaw-mgr/, docs/ visible = OK

# ── 4.5 Prepare .env ───────────────────────────────
cd openclaw-mgr
cp .env.example .env
chmod 600 .env
# Edit if needed: open -e .env   or   nano .env
# Key fields: OPENCLAW_REPO, OPENCLAW_DIR

# ── 5. Doctor ──────────────────────────────────────
./openclaw doctor
# all ✓ = OK / any ✗ = revisit that step

# ── 5b. Clone OpenClaw upstream ────────────────────
OPENCLAW_DIR="${HOME}/openclaw"
OPENCLAW_REPO="$(grep '^OPENCLAW_REPO=' .env | cut -d= -f2-)"
[ -z "$OPENCLAW_REPO" ] && OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"
git clone --depth 1 "$OPENCLAW_REPO" "$OPENCLAW_DIR"
ls "$OPENCLAW_DIR"              # docker-compose.yml visible = OK

# 5b — merge .env
SRC="$OPENCLAW_DIR/.env.example"; DST="$OPENCLAW_DIR/.env"
[ -f "$DST" ] || cp "$SRC" "$DST"
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue;; esac
  key="${line%%=*}"
  grep -qE "^${key}=" "$DST" 2>/dev/null || echo "$line" >> "$DST"
done < "$SRC"
chmod 600 "$DST"

# 5b — start containers
cd "$OPENCLAW_DIR"
COMPOSE_FILES="-f docker-compose.yml"
[ -f compose.yml ] && COMPOSE_FILES="-f compose.yml"
SEC="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.security.yml"
[ -f "$SEC" ] && COMPOSE_FILES="$COMPOSE_FILES -f $SEC"
docker compose $COMPOSE_FILES up -d
docker compose $COMPOSE_FILES ps   # State=running = OK

# Health check
curl -sS --max-time 5 -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8000
# HTTP 200 → open browser: http://localhost:8000

# Apply network isolation (recommended)
NET="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.network.yml"
[ -f "$NET" ] && COMPOSE_FILES="$COMPOSE_FILES -f $NET"
docker compose $COMPOSE_FILES up -d
mkdir -p "$HOME/.openclaw-mgr" && echo isolated > "$HOME/.openclaw-mgr/network-mode"

# ── 6. Add to PATH (optional) ──────────────────────
echo 'export PATH="$HOME/DEV/openclaw-workspace/openclaw-mgr:$PATH"' >> ~/.zshrc
source ~/.zshrc
which openclaw

# ── Register dockerstop alias (optional) ───────────
cat >> ~/.zshrc <<'EOF'
alias dockerstop='osascript -e "quit app \"Docker\"" 2>/dev/null; sleep 3; \
  pkill -TERM -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  sleep 2; \
  pkill -KILL -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ Docker fully stopped"'
EOF
source ~/.zshrc
type dockerstop                 # should print: alias dockerstop=...

# ── Final check ────────────────────────────────────
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor               # "All good 🎉" = done
```

</details>

---

## 🔐 이 가이드의 보안 원칙 (읽고 시작하세요)

> **M5 Pro 24GB / macOS / zsh 기준으로 작성되었습니다.**

### ❌ 이 가이드에서 절대 하지 않는 것

| 금지 | 이유 |
|---|---|
| `brew install openclaw` | 글로벌 설치 — 시스템 오염 |
| `npm install -g ...` | 글로벌 npm 패키지 |
| `pip install ...` | 글로벌 Python 패키지 |
| `sudo ...` (Docker/Ollama 설치 제외) | 불필요한 관리자 권한 |
| `curl ... \| bash` (이 레포 web-installer 제외) | 검증 없는 원격 실행 |

> **이 가이드를 따라가다 위 명령이 나오면 멈추고 확인하세요.**

### ✅ 이 레포의 역할 (연결·설정·자동화 전담)

```
┌─────────────────────────────────────────────────────────────────┐
│  openclaw-workspace (이 레포)                                    │
│  역할: 연결 / 설치 설정 / 사용 / 유지보수 자동화                  │
│                                                                  │
│  ① Docker Desktop   ← docker.com 공식 사이트에서 직접 설치       │
│  ② Ollama           ← ollama.com 공식 앱에서 직접 설치           │
│  ③ OpenClaw 본체    ← github.com/openclaw/openclaw 공식 클론     │
│                                                                  │
│  ③을 받아서 Docker 컨테이너로 기동하는 것이 이 레포의 전부입니다  │
└─────────────────────────────────────────────────────────────────┘
```

### 🗂 설치 후 폴더 구조

```
~/DEV/
├── openclaw/           ← OpenClaw 본체 (공식 클론, 직접 수정 X)
├── openclaw-workspace/ ← 이 레포 (관리 도구)
└── openclawAgent/      ← 에이전트가 만드는 파일 (Docker 볼륨 마운트)
                           Finder 에서 바로 확인 가능

~/.openclaw/            ← 설정·토큰·세션 (숨김, 직접 편집 불필요)
```

> **에이전트가 파일을 만들어도 `~/DEV/openclawAgent` 밖으로는 나갈 수 없습니다.**  
> Docker 볼륨 마운트로 격리 + 샌드박스(OPENCLAW_SANDBOX=1)로 이중 격리.

### 🛡 M5 Pro 24GB 권장 보안 설정

| 설정 | 값 | 이유 |
|---|---|---|
| 샌드박스 | `OPENCLAW_SANDBOX=1` | 에이전트 코드 실행 격리 컨테이너 |
| 네트워크 | `isolated` (기본) | 외부 인터넷 차단 |
| Ollama | `host` 모드 (ollama.com 앱) | Apple Silicon Neural Engine GPU 가속 |
| 모델 | `qwen2.5-coder:7b` or `llama3.2:3b` | 24GB 에서 안정적 (13B+ 비추) |
| 포트 | `127.0.0.1` 전용 | LAN/공용 Wi-Fi 노출 없음 |

---



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
4. **`Docker.dmg` 더블클릭** → 잠시 도커 아이콘·화살표·Applications 폴더가 그려진 창이 뜨고 세 아이콘이 나란히 떠있습니다.

   #### 🔗 드래그 앤 드롭 처음 해보세요? — 마우스로 이사하는 동작

   ```
   ┌───────────────────────┐
   │  🐳      ➜       📁 A     │
   │ Docker         Applications │
   └───────────────────────┘
        ↑                  ↑
      (이 고래를       (여기로
      잘 잡아 끌고
      떨어뜨리세요)
   ```

   1. 마우스 커서를 **파란 고래(🐳 Docker)** 아이콘 위로 가져가세요.
   2. **트랙패드/마우스 왼쪽 버튼을 누른 채** 손가락을 떼지 마세요.
   3. 그 상태로 파란 고래를 **열린 폴더(📁 Applications)** 위까지 이동.
   4. 폴더가 **파랗게 하이라이트 되면** 그때 손가락을 뗍니다 (마우스 버튼 놓기).
   5. 복사 진행률 표시 → 완료되면 Applications 안에 Docker.app 이 들어왔습니다.

   > 💡 **한 손으로 멈추지 않고 생각**: 아이콘 클릭해서 "잡고" → Applications 공간으로 "옮기고" → "놓기". 그냥 마우스 버튼을 눌러 있는 동안에만 들고 다니다고 생각하면 쉽습니다.
   >
   > 🖥 **맥북 트랙패드 사용자**: 두 손가락을 그대로 대고 움직이면 잡힌 것이 그대로 따라옵니다. 손가락을 뗼다 = 잡은 것을 놓는다.
   >
   > 🖡️ **외장 마우스 사용자**: 단순히 왼쪽 버튼을 꾹 누른 상태로 이동 → 목적지에서 놈기.

5. **Applications 폴더 열기** (Finder 왼쪽 사이드바 → "응용 프로그램" 또는 `Cmd+⇧+A`) → **Docker** 더블클릭으로 첫 실행 → 약관 동의 → 권한 다이얼로그(헬퍼 설치) 통과 → 메뉴바 우측 상단에 🐳 고래 아이콘 등장.

   #### 첫 실행 시 순서대로 뜨는 다이얼로그들 (전부 정상)

   | 순서 | 화면 | 어떻게 |
   |---|---|---|
   | 1 | **Rosetta installation failed** (Apple Silicon만, 가끔) | **[Disable Rosetta]** 클릭. OpenClaw 이미지는 ARM64 네이티브라 불필요. ([상세](TROUBLESHOOTING.md#docker-desktop---rosetta-installation-failed--vzerrordomain-code1-apple-silicon)) |
   | 2 | **A new version of Docker Desktop is available** | **[Update and Restart]** — 1~2분 후 자동 재시작 |
   | 3 | **Docker needs privileged access** + 시스템 비밀번호 입력창 | macOS 로그인 비밀번호 (Touch ID 가능) 입력 → [OK]. 1회성 권한. |
   | 4 | **Complete the installation of Docker Desktop** — *Use recommended settings* ↔ *Use advanced settings* | **● Use recommended settings (requires password)** 선택 → **[Finish]**. 추천 설정은 `docker` CLI symlink·가상화 헬퍼·네트워크 권한을 자동 활성. OpenClaw 가 `docker` 명령을 찾으려면 필수. *Advanced* 는 설치 경로를 직접 지정하려는 사용자용. |
   | 5 | **Welcome to Docker** + 사용 목적 설문 | 원하면 작성, **[Skip]** 가능 |
   | 5b | **Sign in to Docker Desktop** / 계정 가입 화면 | **로그인 불필요** — 화면 아래·염의 작은 글씨 **[Skip]** / **[Continue without signing in]** 클릭. Docker Hub 계정은 OpenClaw 사용과 무관한다 (공개 이미지 pull 은 무인증으로 됨). 계정이 필요한 경우는 이미지를 직접 push 하거나 비공개 저장소를 쓸 때뿐. |
   | 6 | 우측 상단 알림 "**'Docker' can run in the background**" | 무시. Docker 가 메뉴바에 살아 있다는 뜻 (정상) |

6. 고래 아이콘이 멈춘 상태(움직이지 않음) = 준비 완료.

확인:
```bash
docker --version       # Docker version XX.Y.Z, build ...
docker compose version # Docker Compose version vX.Y.Z (Compose v2 이상이면 OK)
docker info            # Server: ... 가 보이면 데몬 정상
```

> 💡 회사용/큰 조직 (250인 이상) 은 Docker Desktop 유료 라이선스가 필요할 수 있습니다. 무료 대안: **Colima** (`brew install colima`, Homebrew 가능할 때만).

### 2.5단계 — Docker 사용법 기초 (데몬 = 서버 켜고 끄기)

> 🤔 **"Docker 데몬이 뭐예요? 서버를 매번 켜야 하나요?"**
>
> 비유: Docker 는 **두 부분** 으로 됩니다.
> - 🐳 **Docker 데몬 (서버)** = 백그라운드에서 컨테이너를 실제로 돌리는 엔진. **메뉴바의 고래 아이콘 = 데몬이 켜진 상태**.
> - 💻 **`docker` 명령어 (클라이언트)** = 터미널에서 데몬에게 명령을 보내는 도구.
>
> **데몬이 꺼져 있으면 `docker` 명령은 모두 실패** ("Cannot connect to the Docker daemon"). OpenClaw 도 데몬이 켜져 있어야 동작합니다.

#### 데몬(서버) 켜기

| 방법 | 명령 / 동작 |
|---|---|
| 🖱 **앱으로 켜기** (가장 쉬움) | Applications → **Docker.app** 더블클릭, 또는 Spotlight (`⌘ Space` → "docker") |
| ⌨ **터미널에서 켜기** | `open -a Docker` |
| 🔄 **부팅 시 자동 켜기** (기본 ON) | GUI: Docker Desktop 설정 → General → "Start Docker Desktop when you sign in" — CLI 는 아래 섬션 참고 |

켜진 후 **메뉴바의 🐳 고래 아이콘이 움직임을 멈출 때까지** 30~60초 대기 → 그제서야 `docker` 명령이 동작합니다.

#### 데몬(서버) 켜졌는지 확인

```bash
# 가장 확실한 한 줄
if docker info >/dev/null 2>&1; then echo "✓ daemon up"; else echo "✗ daemon down"; fi

# 버전만 짧게
docker info --format '{{.ServerVersion}}'   # 예: 29.4.0

# 전체 정보 보기
docker info | head -30                       # "Server:" 섬션이 아래쪽에 나와야 OK
docker ps                                    # 표 헤더 (CONTAINER ID  IMAGE ...) 나오면 OK
```

> ⚠️ `docker info | head -5` 는 **Client 섹션만** 출력해서 데몬이 껌져 있어도 동일하게 보입니다. **`Server:` 줄을 확인**하거나 위의 한 줄짜리 방법을 쓰세요.

**✗ daemon down 이 나오면 → Docker 앱이 안 켜져 있는 것입니다:**
```bash
open -a Docker          # 앱 실행
# 메뉴바 🐳 가 움직임을 멈출 때까지 30~60초 대기
# 그 뒤 위 확인 명령 다시 치기 → ✓ daemon up 이 나와야 OK
```

`Cannot connect to the Docker daemon` 가 나오면 → 아직 시동 중. 잠시 기다리거나 메뉴바 고래 아이콘을 클릭해 상태 확인.

#### Docker 켜기 / 끄기 / 항상 켜기 / 완전 죽이기 — 한눈에

> 🐳 **상황별 메뉴얼**. "잠깐 끔" 과 "완전 종료" 는 다릅니다. OpenClaw 가 잘 동작하지 않을 때, 디스크/메모리 회수할 때, 컴퓨터 켤 때마다 자동으로 뜨게 하거나 끄고 싶을 때 참고.

| 상황 | GUI | CLI | 결과 |
|---|---|---|---|
| ▶️ **켜기 (한 번)** | Applications → Docker.app 더블클릭 | `open -a Docker` | 데몬 기동 (메뉴바 🐳 등장, 30~60초) |
| 🛑 **끄기 (보통 — 잠깐만)** | 메뉴바 🐳 → **Quit Docker Desktop** | `osascript -e 'quit app "Docker"'` | 데몬 종료. **OpenClaw 컨테이너 자동 정지** (데이터 보존). 다시 켜면 컨테이너 자동 복귀 |
| 🔁 **재시작** | 메뉴바 🐳 → **Restart** | `osascript -e 'quit app "Docker"'; sleep 5; open -a Docker` | 충돌·메모리 누수·hang 풀 때. 컨테이너도 같이 재기동 |
| 🔄 **항상 켜기 (로그인 시 자동)** | Settings → General → "Start Docker Desktop when you sign in" ✓ → Apply & restart | (자동시작 절 참조) | 부팅·로그인하면 자동으로 데몬 켜짐 |
| ❌ **항상 꺼두기 (자동시작 OFF)** | Settings → General → 위 체크 해제 → Apply | (자동시작 절 참조) | 매번 수동으로 켜야 함 |
| 💀 **완전 죽이기 (강제 종료)** | (불응 시) `kill -9` 사용 | 아래 5줄 명령 | Quit 이 안 먹힐 때 (hang 상태). 데이터는 보존 |
| 🗑 **완전 제거 (앱 + 모든 데이터)** | Docker.app 휴지통 + 데이터 폴더 삭제 | 아래 "완전 제거" 절 | OpenClaw 데이터 포함 **모든 컨테이너·이미지·볼륨 삭제**. 처음 상태로 |

#### ▶️ 켜기 (자세히)

```bash
open -a Docker                                  # 앱 실행
# 메뉴바 🐳 가 움직임 멈출 때까지 30~60초 대기

# 켜졌는지 확인
docker info >/dev/null 2>&1 && echo "✓ daemon up" || echo "✗ daemon down"
```

#### 🛑 끄기 (잠깐 — 권장 방법)

```bash
osascript -e 'quit app "Docker"'                # 정상 종료 (Quit)
# 또는: 메뉴바 🐳 → Quit Docker Desktop

# 끝났는지 확인 (모든 Docker 관련 프로세스)
pgrep -lf "Docker|com.docker|vpnkit|docker-agent|docker-sandbox" \
  || echo "✓ Docker 모두 종료됨"
```

> 💡 OpenClaw 컨테이너는 **자동 정지** 됩니다. 다음에 Docker 를 다시 켜면 자동으로 복귀 (`restart: unless-stopped` 정책). 데이터·세션·다운받은 모델 **모두 그대로**.

##### ⚠️ "Quit 했는데도 프로세스가 살아있다"

Docker Desktop 4.70+ 에서 흔한 현상 — 메인 GUI 는 종료됐는데 **헬퍼·서브프로세스가 좀비처럼 남음**:
- `com.docker.build`, `docker-sandbox daemon start`, `docker-agent serve api`
- `Docker Desktop Helper` (GPU / Renderer / Network)
- `vpnkit`, `qemu` (Apple Silicon VM)

확인:
```bash
ps -ef | grep -i 'docker\|vpnkit' | grep -v grep
# 또는 한 줄 카운트
pgrep -lf "Docker|com.docker|vpnkit|docker-agent|docker-sandbox" | wc -l
# 0 이 아니면 잔존 있음
```

**완전한 한 줄 정리 (안전 — TERM 신호 먼저, 그래도 살아있으면 KILL):**
```bash
osascript -e 'quit app "Docker"' 2>/dev/null; sleep 3; \
pkill -TERM -f 'Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system' 2>/dev/null; \
sleep 2; \
pkill -KILL -f 'Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system' 2>/dev/null; \
sleep 1; \
pgrep -lf 'Docker|com.docker|vpnkit' || echo "✓ 잔존 프로세스 없음"
```

**같은 동작을 alias 로** (`~/.zshrc` 에 추가하면 `dockerstop` 한 단어로 끝):
```bash
cat >> ~/.zshrc <<'EOF'

# OpenClaw: Docker 완전 정상 종료 (잔존 프로세스까지 청소)
alias dockerstop='osascript -e "quit app \"Docker\"" 2>/dev/null; sleep 3; \
  pkill -TERM -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  sleep 2; \
  pkill -KILL -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ Docker 완전 종료"'
EOF
source ~/.zshrc
```

> ⚠️ **이미 열려있는 다른 터미널 창은 자동 반영 X.** 그 창에서도 쓰려면 각각 `source ~/.zshrc` 하거나 새 터미널(`⌘+T`) 을 염세요. 적용 확인: `type dockerstop` 에 `alias dockerstop=...` 가 나와야 정상.

**왜 이런 일이?**
- Docker Desktop 의 일부 헬퍼는 **부모(`Docker Desktop`)** 가 종료해도 즉시 함께 종료되지 않습니다 (sandbox / build helper / agent). 5~10초 안에는 보통 알아서 정리되지만, 그 안에 새 명령을 치면 헷갈립니다.
- **AI/Build 기능을 켰을 때** 더 자주 발생: `docker-agent` (Docker AI), `docker-sandbox` (sandbox CLI plugin), `com.docker.build` (Buildx daemon).
- 위 한 줄은 TERM(정상신호) → 2초 대기 → KILL 순서라 **데이터 손상 위험은 없음**. 단지 좀비 청소.

**예방 (애초에 잔존을 줄이기):**
- Docker Desktop **Settings → Beta features** 에서 **"Docker AI" 와 "Sandbox" 를 사용 안 하면 끄기** → 좀비 헬퍼 자체가 안 떠짐.
- Settings → General → **"Open Docker Dashboard at startup"** 끄기 → GPU/Renderer 헬퍼가 백그라운드에 안 남음.
- `dockerstop` (위 alias) 을 종료 시 항상 사용 → 부분 종료 상황 자체를 없앰.

#### 🔁 재시작 (충돌 / 응답 없을 때)

```bash
osascript -e 'quit app "Docker"'
sleep 5
open -a Docker
```

또는 GUI: 메뉴바 🐳 → **Restart**.

#### 💀 완전 죽이기 (Quit 도 안 먹는 hang 상태)

> ⚠️ **마지막 수단**. 정상 Quit 가 30초 이상 응답 없을 때만. 컨테이너는 갑자기 멈추지만 영구 데이터는 보존됩니다.

```bash
# 1) 정상 Quit 시도
osascript -e 'quit app "Docker"' 2>/dev/null
sleep 3

# 2) 그래도 살아있으면 SIGKILL
pkill -9 -f "Docker Desktop"            # GUI 앱
pkill -9 -f "com.docker.backend"        # 백엔드 프로세스
pkill -9 -f "com.docker.helper"         # 헬퍼 프로세스
pkill -9 -f "vpnkit\|qemu\|docker-vmnetd"  # 가상화 프로세스

# 3) 확인
sleep 2
pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ 모두 종료됨"
```

> 💡 죽인 후 다시 시작하면 일관성 검사로 시간이 걸릴 수 있습니다. **다음 부팅 전에는 docker 명령이 동작하지 않습니다** (`open -a Docker` 로 다시 켜세요).

#### 🗑 완전 제거 (Docker Desktop + 모든 데이터)

> ⚠️ **OpenClaw 컨테이너·볼륨·이미지가 전부 사라집니다.** 다시 깔면 처음부터. 진짜로 정리해야 할 때만.

```bash
# 1) Docker Desktop 자체 클린업 (가장 안전 — 앱 내장)
osascript -e 'quit app "Docker"'; sleep 3
open -a Docker
# 메뉴바 🐳 → Troubleshoot (벌레 아이콘) → "Clean / Purge data" → 확인

# 2) 그 다음 앱 제거
osascript -e 'quit app "Docker"'; sleep 3
sudo rm -rf "/Applications/Docker.app"

# 3) 사용자 데이터 폴더 모두 삭제
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Application\ Support/Docker\ Desktop
rm -rf ~/Library/Preferences/com.docker.docker.plist
rm -rf ~/Library/Saved\ Application\ State/com.electron.docker-frontend.savedState
rm -rf ~/Library/Logs/Docker\ Desktop
rm -rf ~/.docker

# 4) (선택) 자동시작 등록도 제거
osascript -e 'tell application "System Events" to delete login item "Docker"' 2>/dev/null

# 5) 확인
ls /Applications | grep -i docker || echo "✓ 앱 제거됨"
ls ~/Library/Group\ Containers/ 2>/dev/null | grep -i docker || echo "✓ 데이터 제거됨"
```

> 💡 다시 설치하려면 이 가이드의 [2단계](#2단계--docker-desktop-직접-다운로드) 로.

#### 자동시작(로그인 시 켜기) — CLI 로 토글 / 확인

> macOS 의 "로그인 항목 (Login Items)" 으로 등록되는 동작입니다. CLI 로도 완전히 제어할 수 있어요.

**현재 등록 상태 확인:**
```bash
osascript -e 'tell application "System Events" to get the name of every login item' \
  | tr ',' '\n' | grep -i docker || echo "(Docker 자동시작 OFF)"
```

**자동시작 켜기 (로그인 항목에 추가):**
```bash
osascript -e 'tell application "System Events" to make login item at end \
  with properties {path:"/Applications/Docker.app", hidden:true, name:"Docker"}'
```

**자동시작 끄기 (로그인 항목에서 제거):**
```bash
osascript -e 'tell application "System Events" to delete login item "Docker"'
```

> 🔐 처음 실행 시 **"시스템 이벤트가 제어를 요청합니다"** 권한 다이얼로그가 뜨면 **확인**. 이후엔 묻지 않습니다.

**Docker Desktop 내부 설정 파일도 함께 확인 (참고용):**
```bash
SET=~/Library/Group\ Containers/group.com.docker/settings-store.json
[ -f "$SET" ] && python3 -c "import json,sys; d=json.load(open('$SET'.replace('\\\\ ',' '))); print('AutoStart =', d.get('AutoStart', d.get('autoStart','(키 없음)')))" || echo "(설정 파일 없음 — Docker Desktop 미실행 상태일 수 있음)"
```

**전체 macOS Login Items 목록 (어떤 앱들이 자동시작되는지 한눈에):**
```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

#### Docker Desktop 창 — 무엇을 볼 수 있나?

메뉴바 🐳 → **Dashboard** (또는 앱 아이콘 클릭) 으로 GUI 가 열립니다. 좌측 사이드바:

| 탭 | 무엇 |
|---|---|
| **Containers** | 현재 실행 중·정지된 컨테이너 목록. ▶️ 시작·⏹ 정지·🗑 삭제·로그 보기 모두 GUI 로 가능. OpenClaw 컨테이너도 여기 보임. |
| **Images** | 다운받은 컨테이너 이미지 목록 (디스크 차지) |
| **Volumes** | 영구 데이터 저장소 (OpenClaw 백업·세션이 여기) |
| **Builds** | 본인이 빌드한 이미지 (OpenClaw 사용자에겐 거의 비어있음) |
| **Settings (⚙)** | 메모리·CPU 할당, 자동시작 토글, Rosetta 토글 등 |

> 💡 **터미널에 명령 칠 줄 몰라도** 모든 컨테이너 작업을 Dashboard 에서 클릭으로 할 수 있습니다. 하지만 OpenClaw 는 `./openclaw` 명령으로 통합 관리하는 걸 권장 (백업·네트워크 격리 토글 등 보안 기능 자동 적용).

#### OpenClaw 가 데몬을 어떻게 사용하나?

```
┌─────────────────┐         ┌────────────────────┐         ┌──────────────────┐
│ ./openclaw start│ ──────> │ Docker 데몬(서버)  │ ──────> │ OpenClaw 컨테이너 │
│ ./openclaw stop │   명령   │ (메뉴바 🐳)        │  관리   │ (실제 AI 에이전트) │
│ ./openclaw logs │         └────────────────────┘         └──────────────────┘
└─────────────────┘
```

즉 `./openclaw` 가 `docker compose` 명령을 알아서 호출합니다. 사용자가 직접 `docker` 명령을 칠 일은 거의 없습니다 (디버깅이나 호기심 때만).

#### 자주 쓰는 docker 명령 (참고)

| 명령 | 무엇 |
|---|---|
| `docker ps` | 실행 중 컨테이너 목록 |
| `docker ps -a` | 정지된 것까지 모두 |
| `docker images` | 다운받은 이미지 목록 |
| `docker logs <이름>` | 특정 컨테이너 로그 (OpenClaw 는 `./openclaw logs` 로) |
| `docker stats` | CPU·메모리 실시간 사용량 |
| `docker system df` | Docker 가 차지한 디스크 (`./openclaw clean --status` 로 한 번에) |

OpenClaw 사용자에게 **꼭 외울 명령 = 0개**. `./openclaw` 가 다 해줍니다.

### 3단계 — Ollama 설치 (로컬 LLM — M5 Pro GPU 가속 활용)

> 외부 API(OpenAI, Anthropic 등)만 쓸 거면 이 단계를 **건너뛰어도** 됩니다 (`.env` 에서 `ENABLE_OLLAMA=0`).

#### 🤔 Ollama 가 뭐예요? (기초 개념)

**Ollama** = 내 컴퓨터 안에서 LLM(대형 언어 모델)을 실행하는 런타임(서버)입니다.

```
사용자 ─→ OpenClaw UI ─→ Ollama (로컬 서버 :11434) ─→ 모델 파일 (.gguf)
                                      ↑
                           Apple Silicon GPU + Neural Engine 가속
```

| 비교 | 외부 API (OpenAI 등) | 로컬 Ollama |
|---|---|---|
| 데이터 위치 | 클라우드 서버로 전송 | 내 맥 안에서만 처리 |
| 비용 | 토큰당 유료 | 무료 (전기세만) |
| 속도 | 인터넷 대역폭 종속 | M5 Pro 기준 30~60 tok/s |
| 오프라인 | ❌ | ✅ |
| 개인정보 | 외부 전송됨 | 로컬 100% |
| 모델 선택 | 제공 모델만 | ollama.com/library 전부 |

#### 🧠 모델 기초 (처음 보는 분을 위해)

**LLM** = 수십억 개의 숫자(파라미터)로 이루어진 언어 이해·생성 프로그램. Ollama 가 이 파일을 불러와 GPU 로 추론합니다.

| 용어 | 의미 | 예 |
|---|---|---|
| **파라미터 (B = 십억)** | 모델의 "뇌 세포" 수. 클수록 똑똑하지만 느리고 RAM 을 많이 씀 | `7b` = 70억 개 |
| **양자화 (Quantization)** | 모델 파일을 압축하는 방식. 품질과 속도의 트레이드오프 | `q4_K_M` = 4비트 압축 (품질·속도 균형, 권장) |
| **GGUF** | Ollama 가 읽는 모델 파일 형식 | `qwen2.5-coder-7b-q4_K_M.gguf` |
| **컨텍스트 윈도우** | 한 번에 처리할 수 있는 텍스트 길이 (토큰 단위) | `4096`, `8192`, `128k` |
| **토큰** | 모델이 처리하는 단위 ≈ 영어 단어 3/4 개, 한글 1~2자 | "Hello world" ≈ 2 토큰 |

```
파라미터 크기 → RAM 요구량 (q4_K_M 양자화 기준):
 3B  → ~2 GB      7B  → ~4.5 GB     8B  → ~5 GB
13B  → ~8 GB     14B  → ~9 GB      30B  → ~20 GB   ← 24GB 에서 OS 공유 포함 시 위험
70B  → ~45 GB                                       ← 불가
```

> **Apple Silicon 통합 메모리(UMA) 의 장점**: CPU·GPU 가 같은 메모리 풀 공유 → 24GB 전체를 GPU 가 활용 가능. Intel+NVIDIA 대비 동급 RAM 에서 훨씬 빠른 추론.

#### 설치

> ⚠ **`brew install ollama` 하지 마세요** — brew 로 설치하면 백그라운드 서비스로 등록되어 앱처럼 제어하기 불편하고 GPU 가속 효율도 낮을 수 있습니다.

**공식 앱으로 설치 (권장):**

1. **https://ollama.com/download** → **Download for macOS**
2. `Ollama-darwin.zip` 더블클릭 → **Ollama.app** 을 **Applications** 로 드래그 (Docker 와 동일한 동작)
3. **Applications → Ollama** 더블클릭 → 메뉴바에 🦙 아이콘 등장 → 서버 자동 실행

확인:
```bash
ollama --version                              # 버전 출력
curl -s http://localhost:11434/api/version    # {"version":"0.x.x"}
```

#### 데몬(서버) 관리 — 켜기 / 끄기 / 자동시작

Docker 처럼 Ollama 도 백그라운드 서버가 필요합니다.

| 동작 | 방법 |
|---|---|
| **켜기** | Applications → Ollama 더블클릭, 또는 `open -a Ollama` |
| **켜졌는지 확인** | `curl -s http://localhost:11434/api/version` |
| **끄기** | 메뉴바 🦙 → Quit Ollama |
| **터미널에서 끄기** | `osascript -e 'quit app "Ollama"'` |
| **재시작** | `osascript -e 'quit app "Ollama"'; sleep 2; open -a Ollama` |
| **자동시작 토글** | 메뉴바 🦙 → "Start Ollama at Login" 체크/해제 |

앱 없이 터미널에서 직접 실행 (환경 변수 적용하려면 이 방법):
```bash
ollama serve                                     # 포그라운드 실행 (Ctrl+C 로 종료)
OLLAMA_NUM_CTX=8192 OLLAMA_FLASH_ATTENTION=1 ollama serve   # 환경 변수 포함
```

#### 모델 관리 (기초 → 고급)

##### 모델 받기 (pull)

```bash
ollama pull qwen2.5-coder:7b       # 모델 다운로드 (~4.7 GB)
ollama pull llama3.1:8b
ollama pull <모델이름>:<태그>       # 일반형
# 태그 없으면 latest 자동 선택
```

> 📂 **모델 파일 저장 위치**: `~/.ollama/models/` — 수 GB 차지. 정리하려면 `ollama rm <모델명>`.

##### 목록 확인

```bash
ollama list
# NAME                   ID            SIZE    MODIFIED
# qwen2.5-coder:7b       abc1234...    4.7 GB  2 days ago
```

##### 터미널에서 바로 대화 (테스트용)

```bash
ollama run qwen2.5-coder:7b                     # 인터랙티브 채팅 (Ctrl+D 로 종료)
ollama run llama3.1:8b "한국어로 자기소개 해줘"  # 단발성 실행
```

##### 모델 상세 정보

```bash
ollama show qwen2.5-coder:7b
# Architecture: qwen2    Parameters: 7.6B    Quantization: Q4_K_M    Context length: 32768
```

##### 모델 업데이트 (새 버전 받기)

```bash
# 특정 모델
ollama pull qwen2.5-coder:7b        # 이미 있어도 새 버전 있으면 갱신

# 설치된 모든 모델 일괄 업데이트
ollama list --json | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin)['models']:
    print(f'Updating {m[\"name\"]}...')
    subprocess.run(['ollama', 'pull', m['name']])
"
```

##### 모델 삭제 (디스크 회수)

```bash
ollama rm qwen2.5-coder:7b          # 특정 모델 삭제

# 모든 모델 삭제 (초기화)
ollama list --json | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin)['models']:
    subprocess.run(['ollama', 'rm', m['name']])
"
```

#### Ollama REST API (개발자·프로덕션)

Ollama 는 `http://localhost:11434` 에 REST API 를 제공합니다. OpenClaw 가 내부적으로 이 API 로 모델을 호출합니다. 직접 호출해 테스트하거나 외부 스크립트를 붙일 수도 있습니다.

##### 주요 엔드포인트

| 엔드포인트 | 방식 | 설명 |
|---|---|---|
| `/api/version` | GET | 버전 확인 |
| `/api/tags` | GET | 설치된 모델 목록 |
| `/api/ps` | GET | 현재 메모리에 로드된 모델 |
| `/api/generate` | POST | 텍스트 생성 (스트리밍/논스트리밍) |
| `/api/chat` | POST | 채팅 (메시지 배열 형식) |
| `/api/embeddings` | POST | 임베딩 벡터 생성 (RAG 용) |
| `/api/pull` | POST | 모델 다운로드 |
| `/api/delete` | DELETE | 모델 삭제 |
| `/api/show` | POST | 모델 상세 정보 |
| `/v1/chat/completions` | POST | **OpenAI 호환** 엔드포인트 |

##### curl 로 API 테스트

```bash
# 버전
curl -s http://localhost:11434/api/version | python3 -m json.tool

# 설치 모델 목록
curl -s http://localhost:11434/api/tags | python3 -m json.tool

# 텍스트 생성 (논스트리밍 — 결과 한 번에)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"Python 으로 Hello World","stream":false}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['response'])"

# 채팅 형식 (스트리밍 — 줄마다 JSON)
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"안녕"}]}'

# OpenAI 호환 (OpenAI SDK 를 그대로 Ollama 에 연결할 때)
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"피보나치 Python"}]}' \
  | python3 -m json.tool

# 현재 로드된 모델 (메모리 상주 여부)
curl -s http://localhost:11434/api/ps | python3 -m json.tool
```

##### Python 클라이언트

```bash
pip3 install ollama        # 공식 Python 클라이언트
```

```python
import ollama

# 단발성 채팅
response = ollama.chat(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': '피보나치 수열 Python 으로 짜줘'}]
)
print(response['message']['content'])

# 스트리밍 (글자 하나씩 출력)
for chunk in ollama.chat(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': '긴 설명 요청'}],
    stream=True
):
    print(chunk['message']['content'], end='', flush=True)

# 임베딩 (벡터 DB / RAG 용)
emb = ollama.embeddings(model='qwen2.5-coder:7b', prompt='검색할 텍스트')
print(len(emb['embedding']))   # 벡터 차원 수

# OpenAI SDK 를 Ollama 에 연결 (기존 코드 재사용)
from openai import OpenAI
client = OpenAI(base_url='http://localhost:11434/v1', api_key='ollama')
res = client.chat.completions.create(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': 'Hello'}]
)
print(res.choices[0].message.content)
```

#### 성능 튜닝 (Apple Silicon M-series)

##### 추론 속도 측정

```bash
# 토큰/초 확인 (eval_rate)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"1+1=","stream":false}' \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
eval_tok = d.get('eval_count', 0)
eval_ns  = d.get('eval_duration', 1)
prompt_tok = d.get('prompt_eval_count', 0)
prompt_ns  = d.get('prompt_eval_duration', 1)
print(f'출력 속도: {eval_tok / eval_ns * 1e9:.1f} tok/s')
print(f'입력 처리: {prompt_tok / prompt_ns * 1e9:.1f} tok/s')
"
```

M5 Pro 24GB 기준 qwen2.5-coder:7b → 30~55 tok/s 가 정상.

##### GPU (Metal) 가속 확인

```bash
# 서버 로그에서 Metal 사용 여부
cat ~/Library/Logs/Ollama/server.log 2>/dev/null | grep -iE "metal|gpu|offload|layer" | tail -10

# 디버그 모드로 실행 (앱 종료 후)
OLLAMA_DEBUG=1 ollama serve 2>&1 | grep -iE "metal|gpu|offload"
# "offloading X layers to GPU" 가 보이면 GPU 가속 중
```

##### 환경 변수로 동작 튜닝

> ⚠ 아래 변수는 **Ollama 를 실행하는 셸**에서 설정해야 합니다. macOS 앱으로 실행 시 `~/.zshrc` 는 읽히지 않으므로 앱 종료 후 `ollama serve` 로 직접 실행하거나 `launchctl setenv` 를 사용하세요.

```bash
# ~/.zshrc 에 추가 (터미널에서 `ollama serve` 로 실행할 때 적용)

# 컨텍스트 윈도우 기본값 (토큰 수 — 기본 2048, 클수록 RAM 더 필요)
export OLLAMA_NUM_CTX=8192

# GPU 레이어 수 (-1 = 전부 GPU 권장, 0 = CPU 전용)
export OLLAMA_GPU_LAYERS=-1

# 동시 요청 처리 수 (기본 1, 여러 클라이언트 동시 처리 시 올리기)
export OLLAMA_NUM_PARALLEL=1

# 모델 메모리 상주 시간 (기본 5m. -1 = 영구, 0 = 즉시 언로드)
export OLLAMA_KEEP_ALIVE=10m

# Flash Attention (메모리 효율 개선, 실험적)
export OLLAMA_FLASH_ATTENTION=1

# 모델 저장 경로 변경 (기본 ~/.ollama/models)
# export OLLAMA_MODELS="$HOME/MyModels"
```

**launchctl 로 Ollama 앱에 환경 변수 주입 (앱으로 실행하면서도 튜닝하려면):**
```bash
launchctl setenv OLLAMA_NUM_CTX 8192
launchctl setenv OLLAMA_FLASH_ATTENTION 1
# 설정 후 Ollama 재시작
osascript -e 'quit app "Ollama"'; sleep 2; open -a Ollama
```

##### M5 Pro 24GB 권장 설정 요약

```bash
export OLLAMA_NUM_CTX=8192        # 8K 컨텍스트 (7B 모델 + 24GB 에서 안정적)
export OLLAMA_KEEP_ALIVE=10m      # 10분 상주 (자주 쓰면 길게)
export OLLAMA_FLASH_ATTENTION=1   # Flash Attention 활성
export OLLAMA_GPU_LAYERS=-1       # 전 레이어 GPU
```

#### 메모리 관리 (모델 언로드 / 다중 모델)

```bash
# 현재 메모리에 로드된 모델 확인
curl -s http://localhost:11434/api/ps | python3 -m json.tool

# 특정 모델 즉시 언로드 (메모리 회수)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"","keep_alive":0}' > /dev/null
echo "언로드 완료"

# 로드된 모든 모델 일괄 언로드
curl -s http://localhost:11434/api/ps | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin).get('models', []):
    name = m['name']
    print(f'언로드: {name}')
    subprocess.run(['curl', '-s', 'http://localhost:11434/api/generate',
                    '-d', f'{{\"model\":\"{name}\",\"prompt\":\"\",\"keep_alive\":0}}'],
                   capture_output=True)
"

# macOS 통합 메모리 현재 압력 확인
memory_pressure
```

> 💡 24GB 에서는 한 번에 7B 모델 하나만 로드하는 게 안정적. 두 개를 동시에 쓰면 OS 스왑이 늘어 느려짐. `./openclaw clean` 으로 Docker 포함 전체 정리 가능.

#### M5 Pro 24GB 권장 모델 전체 목록

| 모델 | 크기 | 속도 | 용도 | 명령 |
|---|---|---|---|---|
| `qwen2.5-coder:7b` | ~4.7 GB | 빠름 | **코딩 최우선** — Neural Engine 최적화 | `ollama pull qwen2.5-coder:7b` |
| `llama3.2:3b` | ~2.0 GB | 매우 빠름 | 경량·빠른 응답 | `ollama pull llama3.2:3b` |
| `llama3.1:8b` | ~4.9 GB | 빠름 | 범용 고품질 | `ollama pull llama3.1:8b` |
| `qwen2.5:7b` | ~4.7 GB | 빠름 | 한국어 강점 범용 | `ollama pull qwen2.5:7b` |
| `deepseek-r1:7b` | ~4.7 GB | 보통 | 추론·수학 강점 | `ollama pull deepseek-r1:7b` |
| `solar-pro` | ~14 GB | 느림 | 한국 소버린 AI (Solar/EXAONE) | `ollama pull solar-pro` |

> ⚠ **13B 이상 24GB 에서 주의** — macOS UMA 구조상 OS·앱과 메모리 공유, 실사용 가능 ~14~16 GB. 13B+ 는 OOM 또는 심각한 속도 저하 가능.

```bash
ollama pull qwen2.5-coder:7b   # 시작은 이것 하나로 충분
ollama list                     # 받은 모델 확인
```

#### OpenClaw 와 연동 확인

OpenClaw 컨테이너는 `host.docker.internal:11434` 로 호스트 Ollama 에 접근합니다.

```bash
# 컨테이너에서 Ollama 가 보이는지 (OpenClaw 기동 후)
docker exec openclaw-gateway \
  curl -s http://host.docker.internal:11434/api/tags | head -c 200
# {"models":[...]} 나오면 연동 성공

# OpenClaw 에서 사용할 기본 모델 등록
./openclaw models add qwen2.5-coder:7b     # .env 자동 수정 + pull
./openclaw models list                      # 설정 확인
```

> ⚠ **기본 `isolated` 네트워크 모드에서는 Ollama 도 차단** 됩니다. Ollama 를 쓰려면:
> ```bash
> ./openclaw network online --restart      # 연결 허용
> # 사용 후
> ./openclaw network isolated --restart    # 다시 차단
> ```

#### 모니터링 및 문제 해결

```bash
# 서버 로그
cat ~/Library/Logs/Ollama/server.log
tail -f ~/Library/Logs/Ollama/server.log    # 실시간

# 포트 점유 확인
lsof -nP -iTCP:11434 -sTCP:LISTEN

# Ollama 프로세스 메모리 사용량
ps -o pid,rss,vsz,command -p $(pgrep -x ollama 2>/dev/null || echo 0) 2>/dev/null \
  | awk 'NR>1 && $1!="0" {printf "PID %s  RSS %dMB  VSZ %dMB\n", $1, $2/1024, $3/1024}'

# Apple Silicon GPU 사용률 (1회 샘플)
sudo powermetrics --samplers gpu_power -n 1 2>/dev/null \
  | grep -iE "gpu active|gpu power|neural"
```

| 증상 | 원인 / 해결 |
|---|---|
| `connection refused 11434` | Ollama 앱이 안 켜짐 → `open -a Ollama` |
| `port 11434 already in use` | 다른 Ollama 인스턴스 실행 중 (정상). `lsof -nP -iTCP:11434` 로 PID 확인 |
| 모델이 느리다 | 메모리 부족 → `./openclaw clean` 으로 Docker 캐시·모델 정리 |
| 모델이 중간에 끊긴다 | 컨텍스트 초과 → 더 작은 모델 또는 `OLLAMA_NUM_CTX` 줄이기 |
| `model not found` | `ollama pull <모델명>` 로 다운로드 필요 |
| OpenClaw 에서 모델 안 보임 | `isolated` 모드 해제 필요 → `./openclaw network online --restart` |
| GPU 가속 안 됨 | Ollama 버전 구버전 → `ollama --version` 확인 후 앱 재설치 |

#### 대안 — Ollama in Docker (GPU 가속 없음, 느림)

Apple Silicon GPU 없이 순수 Docker 로 실행하고 싶다면:
```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
# .env 에서 OLLAMA_MODE="docker" 로 변경 후:
./openclaw install
# compose.ollama.yml 이 자동으로 포함됩니다
```
> 성능 차이: M5 Pro 기준 host Ollama 대비 3~10배 느림. 가급적 공식 앱 사용 권장.



### 4단계 — openclaw-workspace 소스 직접 받기

> 🤔 **잠깐, 두 개의 저장소가 헷갈려요!**
>
> | 저장소 | 누구 | 무엇 | 언제 받나? |
> |---|---|---|---|
> | 🟢 **`GoGoComputer/openclaw-workspace`** (지금 이 저장소) | 박성모 (이 도구 메인테이너) | macOS 자동화 도구 (`./openclaw` 명령·docker-compose 보안 override·이 가이드 등) | **항상 받아야 함** — 4단계가 이걸 받는 단계 |
> | 🔵 **`openclaw/openclaw`** (OpenClaw 본체) | OpenClaw 공식팀 | AI 에이전트 본체 (Python/JS 코드, 컨테이너 이미지 소스) | **수동으로 받을 필요 없음** — `./openclaw install` 이 자동으로 `~/DEV/openclaw` 에 clone 함 |
>
> 즉 4단계에서는 **이 저장소 (`GoGoComputer/openclaw-workspace`)** 만 받으면 됩니다. OpenClaw 본체는 5단계의 `./openclaw install` 이 알아서 가져옵니다. 본체 사이트도 보고 싶다면 [💡 OpenClaw 본체 사이트 직접 방문하기](#-openclaw-본체-사이트-직접-방문하기-선택) 섹션 참조.

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

#### 💡 OpenClaw 본체 사이트 직접 방문하기 (선택)

본체가 어떻게 생겼는지 미리 보고 싶거나, **회사 IT 심사**용으로 본체 코드까지 직접 검토해야 할 때:

| 무엇 | URL |
|---|---|
| 🌐 OpenClaw 공식 웹사이트 (제품 소개·문서) | **https://clawbro.ai** |
| 🐙 OpenClaw 본체 GitHub | **https://github.com/openclaw/openclaw** |
| 📦 본체 릴리스 페이지 | https://github.com/openclaw/openclaw/releases |
| 📖 본체 공식 문서 | https://github.com/openclaw/openclaw#readme |

본체를 **수동으로 미리 받아두기** (선택, `./openclaw install` 의 clone 단계를 건너뛰고 싶을 때):

```bash
# Git
git clone https://github.com/openclaw/openclaw.git ~/DEV/openclaw

# 또는 ZIP: 위 GitHub 페이지 → 초록 [<> Code] → Download ZIP →
unzip ~/Downloads/openclaw-main.zip -d ~/
mv ~/openclaw-main ~/DEV/openclaw
```

이렇게 미리 받아두면 `~/DEV/openclaw` 에 본체가 있으니 `./openclaw install` 이 그걸 그대로 사용합니다 (clone 단계 [skip]). 다른 위치에 받았으면 `.env` 의 `OPENCLAW_DIR` 만 수정하세요.

> ⚠ **주의**: 본체 저장소 URL 이나 클론 위치를 바꾸려면 `.env` 의 `OPENCLAW_REPO`, `OPENCLAW_DIR` 두 변수를 함께 맞춰주세요. 첫 실행 시 `.env` 가 자동 생성되니 그때 편집하면 됩니다.

### 5단계 — `openclaw` 첫 실행

> ⚠ **설치 전 확인**: `~/DEV/openclawAgent` 폴더가 있어야 합니다 (에이전트 파일 저장 위치).
> ```bash
> mkdir -p ~/DEV/openclawAgent
> ls ~/DEV/    # openclaw/  openclaw-workspace/  openclawAgent/  세 개 다 보이면 OK
> ```

> 🔀 **경로 선택**: 이 가이드는 두 가지 첫 실행 방법을 제공합니다.

| | **경로 A — 관리 도구 사용** | **경로 B — 수동 직접 실행** |
|---|---|---|
| 대상 | openclaw-workspace 도구로 나머지를 자동화 | openclaw 레포에서 직접 기동 |
| 명령 위치 | `~/DEV/openclaw-workspace/openclaw-mgr/` | `~/DEV/openclaw/` |
| 첫 명령 | `./openclaw doctor` | `./docker-setup.sh` |
| 권장 대상 | 처음 설치하는 경우 | 이미 openclaw 레포를 직접 받은 경우 |

---

#### 경로 A — 관리 도구로 기동 (권장)

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

다음과 비슷한 표가 나와야 정상:
```
[doctor]
OS                    ✓ macOS (버전)
Xcode CLT             ✓
Homebrew              ⚠ (없어도 무방 — 수동 설치 모드)
Docker                ✓ (버전 표시)
Docker daemon         ✓ running
Ollama                ✓ (버전 표시)  (선택)
Ollama daemon         ✓
RAM                   ✓ 24GB
Disk free             ✓ 60GB
```

`✗` 가 있으면 어느 단계가 실패했는지 다시 점검. 모두 ✓ 면:

```bash
# 보안 강화 설치 (샌드박스 활성화 — 강력 권장)
OPENCLAW_SANDBOX=1 ./openclaw install

# 또는 기본 설치 (샌드박스 나중에 5c단계에서 활성화 가능)
./openclaw install

./openclaw start       # OpenClaw 컨테이너 기동
./openclaw logs        # 로그 보기 (Ctrl+C 로 빠져나오기)
```

설치 완료 후 에이전트 파일 확인:
```bash
ls ~/DEV/openclawAgent/    # 에이전트가 여기에 파일을 만듭니다
```

브라우저로 **http://localhost:18789** 열기 → OpenClaw UI 등장.

---

#### 경로 B — 수동 직접 기동 (openclaw 레포를 직접 받은 경우)

> 이미 `git clone https://github.com/openclaw/openclaw.git ~/DEV/openclaw` 으로 본체를 받아뒀다면, `docker-setup.sh` 한 번으로 이미지 빌드 + 초기 설정 + 컨테이너 기동이 모두 됩니다.

```bash
cd ~/DEV/openclaw

# ① 초기 설정 스크립트 실행 (인터랙티브 — 처음 한 번만)
./docker-setup.sh
```

스크립트가 순서대로:
1. Docker 이미지를 로컬 빌드 (`DOCKER_BUILDKIT=1 docker build`)
2. 초기 설정 파일(`.env`) 자동 생성
3. 온보딩 안내 출력 (채널 연결 선택, 건너뛰어도 됨)
4. `docker compose up -d openclaw-gateway` 로 컨테이너 기동

완료 후 확인:
```bash
docker compose ps                   # State=running 이면 OK
docker compose logs -f --tail=50    # 로그 실시간 확인 (Ctrl+C 로 종료)
```

브라우저로 **http://localhost:8000** → UI 등장.

> 💡 이후 일상적인 시작/종료는:
> ```bash
> cd ~/DEV/openclaw
> docker compose up -d      # 시작
> docker compose down       # 종료
> docker compose logs -f    # 로그
> ```

브라우저로 **http://localhost:8000** 열기 → OpenClaw UI 등장.

### 5b단계 — `openclaw install` 없이 모든 것을 수동으로 (각 단계 이해)

> 🎯 `doctor` 끝에 **"⚠ N 개 항목이 미설정입니다 — './openclaw install' 로 자동 해결됩니다"** 가 보일 때, 자동에 의존하지 않고 **무엇이 일어나는지 정확히 알면서 직접 처리**하고 싶다면 이 절을 따라하세요.
>
> `./openclaw install` 은 아래 9단계를 멱등(idempotent)하게 수행합니다. 수동으로 깔았으면 대부분 `[skip]` 으로 넘어가지만, **마지막 두 항목 (저장소 clone + 컨테이너 기동)** 이 보통 미설정으로 남습니다. 그것만 손으로 처리하면 됩니다.

#### `openclaw install` 이 하는 9단계 (`openclaw-mgr/cmd/install.sh`)

| # | 단계 | 수동 동치 명령 | 우리가 이미 한 것 |
|---|---|---|-
| 1 | Xcode CLT | `xcode-select --install` | ✓ 1단계 |
| 2 | Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | (수동 설치 모드는 brew 없이 OK) |
| 3 | Docker Desktop | `brew install --cask docker` 또는 docker.com 에서 dmg | ✓ 2단계 |
| 3b | Docker 데몬 | `open -a Docker` + 90초 대기 | ✓ 2.5단계 |
| 4 | Ollama 실행 확인 + **기존 모델 표시** | `open -a Ollama` + `ollama list` | ✓ 3단계 |
| 4b | *(모델은 수동)* | `ollama pull <모델>` — 자동 다운로드 안 함 | 원하는 모델을 직접 pull |
| 5 | OpenClaw 본체 git clone | 아래 **5b-A** 참조 | **여기부터 수동** |
| 6 | `.env` 머지 | 아래 **5b-B** | **여기부터 수동** |
| 7 | `docker compose up -d` | 아래 **5b-C** | **여기부터 수동** |
| 8 | 헬스체크 | 아래 **5b-D** | |
| 9 | 네트워크 격리 적용 | 아래 **5b-E** | |

> 💡 1\~4 는 이미 이 가이드의 1\~3단계로 완료. **남은 것은 5\~9** — 그래서 보통 doctor 가 "2개 미설정" 으로 표시합니다 (저장소 + 컨테이너).
> 
> ⚠ **Ollama 모델은 자동 다운로드하지 않습니다.** `openclaw install` 은 이미 설치된 모델 목록만 표시합니다. 필요한 모델은 직접 pull 하세요 (`ollama pull qwen2.5-coder:7b` 등).

---

#### 5b-A. OpenClaw 본체 git clone (수동)

> ✅ **5단계 경로 B (직접 clone) 로 왔다면 이미 완료** — `~/DEV/openclaw` 에 본체가 있으면 이 절 전체를 건너뛰고 바로 5b-B 로 이동하세요.

> 아직 본체를 받지 않았다면 (경로 A로 진행 중인 경우):

```bash
# 1) 본체 clone
git clone --depth 1 \
  https://github.com/openclaw/openclaw.git \
  ~/DEV/openclaw

# 2) 받았는지 확인
ls ~/DEV/openclaw    # docker-compose.yml, README.md 등이 보이면 OK
```

> 🔐 보안 검사 (선택): `docker.sock` 마운트가 있으면 호스트 장악 위험:
> ```bash
> grep -RIn '/var/run/docker.sock' ~/DEV/openclaw/*compose*.y*ml || echo "OK — 위험 마운트 없음"
> ```

#### 5b-B. `.env` 머지 (선택 — 본체 .env.example 의 누락 키 추가)

```bash
SRC="$OPENCLAW_DIR/.env.example"          # 본체가 제공하는 예제
DST="$OPENCLAW_DIR/.env"                  # 실제 사용 파일
[ -f "$DST" ] || cp "$SRC" "$DST"          # 처음이면 그대로 복사

# 누락 키만 추가 (덮어쓰기 X)
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  key="${line%%=*}"
  grep -qE "^${key}=" "$DST" 2>/dev/null || echo "$line" >> "$DST"
done < "$SRC"

chmod 600 "$DST"
```

#### 5b-C. 컨테이너 기동 (`docker compose up -d`)

```bash
cd "$OPENCLAW_DIR"

# compose 파일 자동 감지 (둘 중 있는 것 사용)
COMPOSE_FILES="-f docker-compose.yml"
[ -f compose.yml ] && COMPOSE_FILES="-f compose.yml"

# 이 도구가 제공하는 보안 override 도 같이 적용 (권장)
SEC="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.security.yml"
[ -f "$SEC" ] && COMPOSE_FILES="$COMPOSE_FILES -f $SEC"

# (첫 기동은 외부 의존성 받아야 하므로 일단 isolated 가 아닌 상태에서 시작)
docker compose $COMPOSE_FILES up -d

docker compose $COMPOSE_FILES ps           # State=running 인지 확인
```

#### 5b-D. 헬스체크 (수동)

```bash
# 컨테이너가 다 떠있는지
TOTAL=$(docker compose $COMPOSE_FILES ps -q | wc -l | tr -d ' ')
RUN=$(docker compose $COMPOSE_FILES ps --status running -q | wc -l | tr -d ' ')
echo "running: $RUN / $TOTAL"

# Ollama 가 호스트에서 응답하는지 (컨테이너에서 host.docker.internal 로 접근)
curl -sS --max-time 3 http://127.0.0.1:11434/api/tags | head -c 200; echo

# UI 포트 (기본 8000) 응답 확인
curl -sS --max-time 5 -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8000
```

브라우저로 **http://localhost:8000** → UI 가 보이면 ✓

#### 5b-E. 네트워크 격리 모드 (보안 권장 — 외부 차단)

> `openclaw install` 의 마지막 단계는 컨테이너를 **isolated** (외부 네트워크 차단) 로 재기동합니다. 본체에 보안 격리 override 가 들어가는 것.

```bash
# 이 도구가 제공하는 격리용 override
NET="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.network.yml"
[ -f "$NET" ] && COMPOSE_FILES="$COMPOSE_FILES -f $NET"

cd "$OPENCLAW_DIR"
docker compose $COMPOSE_FILES up -d        # 격리 모드로 재기동

# 상태 기록 (이 도구가 다음 doctor 에서 인식)
mkdir -p "$HOME/.openclaw-mgr"
echo isolated > "$HOME/.openclaw-mgr/network-mode"
```

> 💡 **나중에 업데이트할 때**는 이 모드를 잠깐 풀어야 인터넷에서 새 이미지를 받을 수 있습니다:
> ```bash
> ./openclaw network online --restart        # 격리 해제 + 재기동
> ./openclaw update                          # 업데이트
> ./openclaw network isolated --restart      # 다시 격리
> ```
> 또는 위 5b-C / 5b-E 의 compose 명령을 직접 다시 실행 (override 파일 포함/제외 토글).

---

#### 끝났는지 최종 확인

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

이제 **"모두 정상입니다 🎉"** 가 보이면 완료. 만약 `자동 업데이트 ⚠ 미설정` 이 남아 있으면 그건 launchd 자동 스케줄(선택 항목) 이라 무시해도 됩니다. 원하면:
```bash
./openclaw schedule enable     # 매일 자동 update 등록 (수동 동치는 launchd plist 작성 — 7단계 참조)
```

### 5c단계 — 샌드박스 (Sandbox) + 보안 강화 설치

> 🔒 **샌드박스란?** OpenClaw 에이전트가 코드를 실행할 때 **격리된 컨테이너** 안에서만 돌아가도록 제한합니다. 에이전트가 호스트 파일시스템 · 네트워크 · 프로세스에 직접 접근하지 못합니다. 보안이 중요하다면 반드시 활성화하세요.

#### 샌드박스 동작 원리

```
[에이전트 요청]
       ↓
  openclaw-gateway (컨테이너)
       ↓  docker.sock 을 통해
  openclaw-sandbox (임시 컨테이너 — 코드 실행 후 즉시 폐기)
       ↓
  결과만 gateway 로 반환
```

- **`agents.defaults.sandbox.mode = non-main`** — 메인 에이전트 이외 모든 서브에이전트에 샌드박스 강제
- **`agents.defaults.sandbox.scope = agent`** — 에이전트 단위 격리
- **`agents.defaults.sandbox.workspaceAccess = none`** — 샌드박스 컨테이너에서 워크스페이스 직접 접근 차단

#### 방법 A — 자동 (권장)

```bash
cd ~/DEV/openclaw

# 샌드박스 활성화 + 보안 강화 빌드 + 기동 (한 번에)
OPENCLAW_SANDBOX=1 ./docker-setup.sh
```

이 명령이 순서대로:
1. Docker 이미지를 **Docker CLI 포함**으로 다시 빌드 (`--build-arg OPENCLAW_INSTALL_DOCKER_CLI=1`)
2. `docker.sock` GID 자동 감지 → `docker-compose.sandbox.yml` 오버레이 생성 (소켓 마운트 + group_add)
3. `agents.defaults.sandbox.mode/scope/workspaceAccess` 설정 적용
4. gateway 재기동 (샌드박스 오버레이 포함)

완료 메시지:
```
Sandbox enabled: mode=non-main, scope=agent, workspaceAccess=none
Docs: https://docs.openclaw.ai/gateway/sandboxing
```

#### 방법 B — 수동 (각 단계 직접)

```bash
cd ~/DEV/openclaw

# 1) Docker CLI 포함으로 이미지 재빌드
DOCKER_BUILDKIT=1 docker build \
  --build-arg OPENCLAW_INSTALL_DOCKER_CLI=1 \
  -t openclaw:local .

# 2) 샌드박스 전용 이미지 빌드
DOCKER_BUILDKIT=1 docker build \
  -t openclaw-sandbox:bookworm-slim \
  -f Dockerfile.sandbox .

# 3) Docker socket GID 확인 (macOS)
DOCKER_GID=$(stat -f '%g' /var/run/docker.sock)
echo "DOCKER_GID=$DOCKER_GID"

# 4) 샌드박스 compose 오버레이 생성
cat > docker-compose.sandbox.yml <<EOF
services:
  openclaw-gateway:
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    group_add:
      - "${DOCKER_GID}"
EOF

# 5) 샌드박스 포함으로 기동
docker compose \
  -f docker-compose.yml \
  -f docker-compose.sandbox.yml \
  up -d openclaw-gateway

# 6) 샌드박스 설정 적용
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.mode non-main
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.scope agent
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.workspaceAccess none

# 7) gateway 재기동 (설정 반영)
docker compose \
  -f docker-compose.yml \
  -f docker-compose.sandbox.yml \
  up -d openclaw-gateway
```

#### 샌드박스 확인

```bash
# 컨테이너 상태
docker compose ps
# openclaw-gateway   running

# 샌드박스 이미지 존재 확인
docker images | grep sandbox
# openclaw-sandbox   bookworm-slim   ...

# 설정 확인
docker compose exec openclaw-gateway \
  node dist/index.js config get agents.defaults.sandbox
# 예상 출력:
# { mode: 'non-main', scope: 'agent', workspaceAccess: 'none' }
```

#### ⚠️ 보안 참고사항

| 항목 | 내용 |
|---|---|
| `docker.sock` 마운트 | 샌드박스 컨테이너를 새로 띄우기 위해 필수. 단, gateway 컨테이너가 타협되면 호스트 docker 접근 가능 — 신뢰된 이미지만 사용 |
| 샌드박스 이미지 | `Dockerfile.sandbox` 기반 `debian:bookworm-slim` — 최소 패키지만 포함 |
| 네트워크 격리 | 샌드박스 자체는 `openclaw-cli` 와 동일한 `network_mode: service:openclaw-gateway` 사용. 추가 외부 차단은 `./openclaw network isolated --restart` 로 적용 |
| 워크스페이스 접근 | `workspaceAccess=none` — 샌드박스가 호스트 파일 읽기 불가 |

#### 샌드박스 비활성화 (원래대로)

```bash
cd ~/DEV/openclaw
# sandbox 없이 재실행
./docker-setup.sh     # OPENCLAW_SANDBOX 없으면 자동으로 sandbox.mode=off 으로 리셋
```

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

> ❓ **OpenClaw 본체가 업데이트되면 내 도구도 자동으로 업데이트되나요?**
>
> **아니요.** 두 저장소는 서로 독립적인 git 저장소이며 따로 갱신해야 합니다.
>
> | 무엇 | 어떻게 갱신 | 무엇이 갱신되나 |
> |---|---|---|
> | 🟢 내 도구 (`openclaw-workspace`) | `git pull` (수동 모드) 또는 `openclaw self-update` (brew 모드) | `openclaw` CLI, `lib/`, `cmd/`, 보안 override, 가이드 문서 |
> | 🔵 OpenClaw 본체 (`~/DEV/openclaw`) | `openclaw update` ← 내 도구가 알아서 본체 git pull + 이미지 pull + 모델 pull 까지 | 본체 코드, Docker 이미지, Ollama 모델 |
>
> 즉 **내 도구만 최신 ≠ 본체도 최신**. 둘 다 최신으로 두고 싶으면 두 명령을 차례로 돌리세요.

#### 매번 하는 표준 절차 (수동 설치 모드)

```bash
# 1) 내 도구(workspace) 갱신
cd ~/DEV/openclaw-workspace
git pull --ff-only

# 2) 본체(OpenClaw) + 컨테이너 이미지 + 모델 갱신 (한 명령)
./openclaw-mgr/openclaw update

# 3) 둘 다 ✓ 인지 확인
./openclaw-mgr/openclaw doctor
```

#### `openclaw update` 가 내부적으로 하는 일

```
openclaw update
  ├── network online (잠깐 외부 허용)
  ├── cd ~/DEV/openclaw && git pull --ff-only          ← 본체 코드 갱신
  ├── docker compose pull                            ← 본체 이미지 갱신
  ├── docker compose up -d                           ← 새 이미지로 재기동
  └── network isolated (다시 잠금)
```

> 💡 **Ollama 모델 갱신은 별도로:** update 는 모델을 자동으로 받지 않습니다.
> ```bash
> ollama list              # 현재 설치 목록 확인
> ollama pull <모델명>     # 개별 갱신 (예: ollama pull qwen2.5-coder:7b)
> ```

#### 자동화 — 매일 새벽에 본체까지 자동 업데이트

```bash
./openclaw-mgr/openclaw schedule enable    # 매일 03:00 (기본) 에 launchd 가 `openclaw update` 자동 실행
./openclaw-mgr/openclaw schedule status     # 다음 실행 시각 확인
./openclaw-mgr/openclaw schedule disable    # 끄기
```

> ⚠ `schedule` 은 **본체 update** 만 자동 실행합니다. 내 도구(workspace) 의 `git pull` 은 자동화하지 않습니다 — 도구가 깨져 있으면 자동복구가 위험하므로. 내 도구는 가끔 직접 `git pull` 권장.

#### 특정 버전에 고정 (Pin to a stable tag)

내 도구를 특정 안정 버전으로:
```bash
cd ~/DEV/openclaw-workspace
git fetch --tags
git checkout v0.1.6
```

본체를 특정 커밋으로 고정 (공급망 공격 방어용):
```bash
$EDITOR ~/.openclaw-mgr/.env
# OPENCLAW_PIN_COMMIT="abc1234..."
./openclaw-mgr/openclaw update
```

> ⚠️ 수동 설치 환경에서는 `openclaw self-update` 가 의도적으로 비활성됩니다 (Homebrew formula 가 아니므로). 내 도구는 항상 `git pull` 을 쓰세요.

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
4. **Double-click `Docker.dmg`** → a small floating window appears showing two icons side by side: the whale (Docker) on the left, the Applications folder on the right.

   #### 🔗 First time using drag-and-drop? — how to "carry" something with the mouse

   ```
   ┌─────────────────────────┐
   │  🐳      ➜       📁 A     │
   │ Docker         Applications │
   └───────────────────────┘
        ↑                  ↑
     (grab here,      (drop here)
     hold, carry)
   ```

   1. Move the mouse over the **blue whale (🐳 Docker)** icon.
   2. **Press and hold** the trackpad / left mouse button — don't let go yet.
   3. While still holding, **drag** the whale onto the **Applications folder (📁)**.
   4. When the folder **highlights blue**, release the button ("drop").
   5. A copy progress bar appears → when it finishes, Docker.app is now inside Applications.

   > 💡 **Mental model**: click to *grab*, move to *carry*, release to *drop*. The mouse button must stay pressed the whole time you're "carrying."
   >
   > 🖥 **Trackpad users**: keep two fingers down and the cursor follows; lift them = drop.
   >
   > 🖡️ **External-mouse users**: hold the left button down while moving → release at the destination.

5. **Open Applications** (Finder sidebar → "Applications" or `Cmd+⇧+A`) → double-click **Docker** to launch first time → accept terms → grant the helper permission dialog → 🐳 whale icon appears in the menu bar.

   #### First-launch dialogs you'll see, in order (all normal)

   | # | Screen | What to do |
   |---|---|---|
   | 1 | **Rosetta installation failed** (Apple Silicon only, sometimes) | Click **[Disable Rosetta]**. OpenClaw images are ARM64-native — Rosetta isn't needed. ([details](TROUBLESHOOTING.md#docker-desktop---rosetta-installation-failed--vzerrordomain-code1-apple-silicon)) |
   | 2 | **A new version of Docker Desktop is available** | Click **[Update and Restart]** — auto-restarts in ~1–2 min |
   | 3 | **Docker needs privileged access** + macOS password prompt | Enter your macOS login password (Touch ID works) → [OK]. One-time permission. |
   | 4 | **Complete the installation of Docker Desktop** — *Use recommended settings* vs *Use advanced settings* | Choose **● Use recommended settings (requires password)** → **[Finish]**. Recommended sets up the `docker` CLI symlink, virtualization helper, and network permissions automatically — OpenClaw needs the symlink to find `docker`. *Advanced* is only for users who want to pick install paths manually. |
   | 5 | **Welcome to Docker** + usage survey | Fill if you want, or **[Skip]** |
   | 5b | **Sign in to Docker Desktop** / account creation screen | **No login needed** — click the small **[Skip]** / **[Continue without signing in]** link (usually bottom or side). A Docker Hub account is unrelated to using OpenClaw (public images pull anonymously). You only need an account if you push images or use a private registry. |
   | 6 | Top-right notification: "**'Docker' can run in the background**" | Ignore. Just means Docker lives in the menu bar (normal). |

6. Whale stops animating = ready.

Verify:
```bash
docker --version
docker compose version
docker info
```

> 💡 Companies with 250+ employees may need a paid Docker Desktop licence. Free alternative: **Colima** (`brew install colima`, only when Homebrew is allowed).

### Step 2.5 — Docker basics (turning the daemon = server on/off)

> 🤔 **"What's the daemon? Do I have to start the server every time?"**
>
> Mental model: Docker has **two parts**.
> - 🐳 **Docker daemon (server)** = the background engine that actually runs containers. **The whale icon in the menu bar = daemon running.**
> - 💻 **`docker` CLI (client)** = the command in your terminal that sends instructions to the daemon.
>
> **If the daemon isn't running, every `docker` command fails** with "Cannot connect to the Docker daemon" — and OpenClaw won't work either.

#### Start the daemon (server)

| Method | Command / Action |
|---|---|
| 🖱 **Open the app** (easiest) | Applications → **Docker.app**, or Spotlight (`⌘ Space` → "docker") |
| ⌨ **Terminal** | `open -a Docker` |
| 🔄 **Auto-start on login** (default ON) | GUI: Docker Desktop Settings → General → "Start Docker Desktop when you sign in" — see CLI section below |

After starting, **wait 30–60 s for the menu-bar 🐳 whale to stop animating** — only then are `docker` commands ready.

#### Check the daemon is up

```bash
# One-liner status check
if docker info >/dev/null 2>&1; then echo "✓ daemon up"; else echo "✗ daemon down"; fi

# Just the version
docker info --format '{{.ServerVersion}}'   # e.g. 29.4.0

# Full output
docker info | head -30                       # "Server:" section must appear
docker ps                                    # Header (CONTAINER ID  IMAGE ...) means OK
```

> ⚠️ `docker info | head -5` only shows the **Client** section — the daemon could be either up or down and you'd see the same thing. **Look for the `Server:` line**, or use the one-liner above.

**If you see ✗ daemon down → Docker is not running:**
```bash
open -a Docker          # same as the Start step above
# wait 30–60 s, then rerun the check
```

#### Start / Stop / Always-on / Force-kill — at a glance

> 🐳 Cheat-sheet by intent. "Stop for a moment" and "completely uninstall" are very different. Use this when OpenClaw misbehaves, when reclaiming RAM/disk, or when you want Docker to (not) auto-launch on login.

| Intent | GUI | CLI | Result |
|---|---|---|---|
| ▶️ **Start (one-off)** | Applications → Docker.app | `open -a Docker` | Daemon boots (whale 🐳 in menu bar, 30–60 s) |
| 🛑 **Stop (the normal way)** | Menu-bar 🐳 → **Quit Docker Desktop** | `osascript -e 'quit app "Docker"'` | Daemon quits. **OpenClaw containers stop automatically** (data preserved). They come back when Docker restarts. |
| 🔁 **Restart** | Menu-bar 🐳 → **Restart** | `osascript -e 'quit app "Docker"'; sleep 5; open -a Docker` | For crashes / memory leaks / hangs. Containers restart too. |
| 🔄 **Always on (auto-start at login)** | Settings → General → "Start Docker Desktop when you sign in" ✓ → Apply & restart | (see Auto-start section) | Daemon launches at login automatically. |
| ❌ **Always off (no auto-start)** | Settings → General → uncheck above → Apply | (see Auto-start section) | Manual start every time. |
| 💀 **Force-kill (Quit doesn't respond)** | (none) | 5-line command below | When Quit hangs > 30 s. Data preserved. |
| 🗑 **Completely uninstall (app + all data)** | Trash Docker.app + delete data folders | "Completely uninstall" section below | **Deletes all containers, images, volumes including OpenClaw data.** Back to square one. |

#### ▶️ Start (detail)

```bash
open -a Docker
# Wait until menu-bar 🐳 stops animating (30–60 s)

docker info >/dev/null 2>&1 && echo "✓ daemon up" || echo "✗ daemon down"
```

#### 🛑 Stop (the normal way — recommended)

```bash
osascript -e 'quit app "Docker"'
# or: Menu-bar 🐳 → Quit Docker Desktop

# Verify (covers all helpers, not just main app)
pgrep -lf "Docker|com.docker|vpnkit|docker-agent|docker-sandbox" \
  || echo "✓ Docker fully stopped"
```

> 💡 OpenClaw containers **stop automatically**; with `restart: unless-stopped` they come back when Docker is started again. Data, sessions, downloaded models are preserved.

##### ⚠️ "I Quit, but processes are still alive"

Common on Docker Desktop 4.70+: the main GUI exits but **helpers / sub-processes linger like zombies**:
- `com.docker.build`, `docker-sandbox daemon start`, `docker-agent serve api`
- `Docker Desktop Helper` (GPU / Renderer / Network)
- `vpnkit`, `qemu` (Apple Silicon VM)

Check:
```bash
ps -ef | grep -i 'docker\|vpnkit' | grep -v grep
pgrep -lf "Docker|com.docker|vpnkit|docker-agent|docker-sandbox" | wc -l
# anything > 0 means leftovers
```

**Full clean stop one-liner (safe — TERM first, then KILL):**
```bash
osascript -e 'quit app "Docker"' 2>/dev/null; sleep 3; \
pkill -TERM -f 'Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system' 2>/dev/null; \
sleep 2; \
pkill -KILL -f 'Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system' 2>/dev/null; \
sleep 1; \
pgrep -lf 'Docker|com.docker|vpnkit' || echo "✓ no leftovers"
```

**Same as a shell alias** (add to `~/.zshrc`, then `dockerstop` quits cleanly every time):
```bash
cat >> ~/.zshrc <<'EOF'

# OpenClaw: clean Docker shutdown (also reaps leftover helpers)
alias dockerstop='osascript -e "quit app \"Docker\"" 2>/dev/null; sleep 3; \
  pkill -TERM -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  sleep 2; \
  pkill -KILL -f "Docker Desktop|com.docker|docker-agent|docker-sandbox|vpnkit|qemu-system" 2>/dev/null; \
  pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ Docker fully stopped"'
EOF
source ~/.zshrc
```

> ⚠️ **Other terminal windows already open won't pick this up automatically.** Run `source ~/.zshrc` in each, or open a new terminal (`⌘+T`). Verify: `type dockerstop` should print `alias dockerstop=...`.

**Why does this happen?**
- Some Docker Desktop helpers don't exit immediately when the parent (`Docker Desktop`) quits (sandbox / build helper / agent). They usually clean up within 5–10 s, but if you run new commands in that window things look broken.
- It's worse with **AI / Build features enabled**: `docker-agent` (Docker AI), `docker-sandbox` (CLI plugin), `com.docker.build` (Buildx daemon).
- The one-liner sends TERM (graceful) → 2 s wait → KILL — **no risk of data corruption**, just zombie cleanup.

**Prevent it (reduce leftovers in the first place):**
- Docker Desktop **Settings → Beta features** — disable **"Docker AI" and "Sandbox"** if you don't use them. The zombie helpers stop spawning at all.
- Settings → General → uncheck **"Open Docker Dashboard at startup"** — keeps GPU/Renderer helpers out of the background.
- Use `dockerstop` (alias above) every time you quit — eliminates the "partial shutdown" state entirely.

#### 🔁 Restart (crash / unresponsive)

```bash
osascript -e 'quit app "Docker"'
sleep 5
open -a Docker
```

Or GUI: Menu-bar 🐳 → **Restart**.

#### 💀 Force-kill (Quit hung > 30 s)

> ⚠️ **Last resort.** Use only if a normal Quit doesn't respond. Containers stop abruptly; persistent data is preserved.

```bash
# 1) Try a polite Quit first
osascript -e 'quit app "Docker"' 2>/dev/null
sleep 3

# 2) If still alive, SIGKILL
pkill -9 -f "Docker Desktop"
pkill -9 -f "com.docker.backend"
pkill -9 -f "com.docker.helper"
pkill -9 -f "vpnkit\|qemu\|docker-vmnetd"

# 3) Verify
sleep 2
pgrep -lf "Docker|com.docker|vpnkit" || echo "✓ all stopped"
```

> 💡 After force-kill, the next start may take longer (consistency check). The `docker` CLI won't work until you `open -a Docker` again.

#### 🗑 Completely uninstall (Docker Desktop + all data)

> ⚠️ **All OpenClaw containers, volumes, and images will be wiped.** Reinstalling = fresh start. Only do this when you really want to clean up.

```bash
# 1) Use Docker Desktop's built-in cleanup (safest)
osascript -e 'quit app "Docker"'; sleep 3
open -a Docker
# Menu-bar 🐳 → Troubleshoot (bug icon) → "Clean / Purge data" → confirm

# 2) Then remove the app
osascript -e 'quit app "Docker"'; sleep 3
sudo rm -rf "/Applications/Docker.app"

# 3) Remove all user-data folders
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Application\ Support/Docker\ Desktop
rm -rf ~/Library/Preferences/com.docker.docker.plist
rm -rf ~/Library/Saved\ Application\ State/com.electron.docker-frontend.savedState
rm -rf ~/Library/Logs/Docker\ Desktop
rm -rf ~/.docker

# 4) (optional) remove auto-start entry
osascript -e 'tell application "System Events" to delete login item "Docker"' 2>/dev/null

# 5) Verify
ls /Applications | grep -i docker || echo "✓ app removed"
ls ~/Library/Group\ Containers/ 2>/dev/null | grep -i docker || echo "✓ data removed"
```

> 💡 To reinstall, see [Step 2](#step-2--download-docker-desktop-directly).

#### Auto-start on login — toggle / check via CLI

> Two places hold this setting — on modern macOS, **Docker Desktop's own setting (`AutoStart` in `settings-store.json`)** is primary; the system-level **Login Items** list is used additionally on some macOS versions.

**① Check Docker Desktop's own auto-start key (most reliable):**
```bash
F="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
python3 -c "import json; d=json.load(open(r'''$F''')); print('AutoStart =', d.get('AutoStart','(key absent)'))"
# AutoStart = True → ON / AutoStart = False → OFF
```

**② Check macOS Login Items list (informational):**
```bash
osascript -e 'tell application "System Events" to get the name of every login item' \
  | tr ',' '\n' | grep -i docker || echo "(Docker not in Login Items)"
```
> 💡 On modern macOS, Docker registers via SMAppService and may **not appear** in this list. In that case ① 's `AutoStart` is the real source of truth.

**Toggle auto-start — most reliable: GUI**

```bash
open -a Docker        # opens Docker Desktop
# Settings → General → "Start Docker Desktop when you sign in" → toggle → Apply & restart
```

Fully via CLI (advanced — quit Docker Desktop first):

```bash
osascript -e 'quit app "Docker"'; sleep 3
F="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
python3 -c "import json,sys; p=r'''$F'''; d=json.load(open(p)); d['AutoStart']=True; json.dump(d, open(p,'w'), indent=2)"
# Use False to disable
open -a Docker
```

> ⚠️ Editing settings-store.json directly is an undocumented internal format. Prefer the GUI toggle for everyday use.

**Add / remove a system Login Item directly (only needed on some setups):**
```bash
# Add
osascript -e 'tell application "System Events" to make login item at end \
  with properties {path:"/Applications/Docker.app", hidden:true, name:"Docker"}'

# Remove
osascript -e 'tell application "System Events" to delete login item "Docker"'
```
> 🔐 First run prompts "System Events wants control..." → click **OK**.

**List all macOS Login Items:**
```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

#### What's in the Docker Desktop window?

Menu-bar 🐳 → **Dashboard** (or click the app icon) opens the GUI. Sidebar tabs:

| Tab | What |
|---|---|
| **Containers** | Running & stopped containers. ▶️ start, ⏹ stop, 🗑 delete, view logs — all clickable. OpenClaw containers show up here. |
| **Images** | Downloaded container images (disk usage). |
| **Volumes** | Persistent data stores (OpenClaw backups & sessions live here). |
| **Builds** | Images you built locally (rarely used by OpenClaw users). |
| **Settings (⚙)** | RAM/CPU allocation, auto-start toggle, Rosetta toggle, etc. |

> 💡 **You can do everything via the Dashboard** without typing — but for OpenClaw, prefer `./openclaw` commands so security features (network isolation, automatic backups) apply.

#### How OpenClaw uses the daemon

```
┌─────────────────┐         ┌────────────────────┐         ┌──────────────────┐
│ ./openclaw start│ ──────> │ Docker daemon      │ ──────> │ OpenClaw         │
│ ./openclaw stop │ command │ (menu-bar 🐳)       │ manages │ container        │
│ ./openclaw logs │         └────────────────────┘         └──────────────────┘
└─────────────────┘
```

`./openclaw` calls `docker compose` for you. You almost never need to run `docker` directly (only for debugging / curiosity).

#### Handy `docker` commands (reference)

| Command | What |
|---|---|
| `docker ps` | Running containers |
| `docker ps -a` | Including stopped |
| `docker images` | Downloaded images |
| `docker logs <name>` | One container's logs (use `./openclaw logs` for OpenClaw) |
| `docker stats` | Live CPU / memory |
| `docker system df` | Disk used by Docker (or use `./openclaw clean --status`) |

Number of `docker` commands an OpenClaw user must memorise: **zero**. `./openclaw` handles it all.

### Step 3 — Download Ollama directly (optional — for local LLMs)

> Skip this step if you'll only use external APIs (OpenAI, Anthropic, etc.). Set `ENABLE_OLLAMA=0` in `.env` and Ollama is not needed.

#### 🤔 What is Ollama? (basics)

**Ollama** = a runtime (local server) that runs LLMs on your Mac.

```
User → OpenClaw UI → Ollama (local server :11434) → model file (.gguf)
                              ↑
                   Apple Silicon GPU + Neural Engine acceleration
```

| | External API (OpenAI etc.) | Local Ollama |
|---|---|---|
| Data location | Sent to cloud servers | Stays on your Mac only |
| Cost | Per-token billing | Free (electricity only) |
| Speed | Depends on internet | 30–60 tok/s on M5 Pro |
| Offline | ❌ | ✅ |
| Privacy | Data leaves device | 100% local |
| Model choice | Provider's catalog | Everything on ollama.com/library |

#### 🧠 Model basics (for first-timers)

**LLM** = a program made of billions of numbers (parameters) that understands and generates text. Ollama loads these files and runs them on your GPU.

| Term | Meaning | Example |
|---|---|---|
| **Parameters (B = billion)** | The model's "neurons". More = smarter but slower and larger | `7b` = 7 billion |
| **Quantization** | Compression: trades some quality for size/speed | `q4_K_M` = 4-bit (recommended balance) |
| **GGUF** | The file format Ollama uses | `qwen2.5-coder-7b-q4_K_M.gguf` |
| **Context window** | Max text length processed at once (in tokens) | `4096`, `8192`, `128k` |
| **Token** | The unit models process ≈ ¾ of an English word | "Hello world" ≈ 2 tokens |

```
Parameter size → RAM needed (q4_K_M quantization):
 3B → ~2 GB     7B → ~4.5 GB     8B → ~5 GB
13B → ~8 GB    14B → ~9 GB      30B → ~20 GB   ← risky at 24 GB shared with OS
70B → ~45 GB                                    ← impossible
```

> **Apple Silicon Unified Memory Architecture (UMA) advantage**: CPU and GPU share the same memory pool → all 24 GB is directly available to GPU inference. Much faster than Intel+NVIDIA with equivalent RAM.

#### Installation

> ⚠ **Do not `brew install ollama`** — it installs as a background brew service, making it harder to control and potentially limiting GPU acceleration.

1. Open **https://ollama.com/download**
2. **Download for macOS** → `Ollama-darwin.zip` or `.dmg` (~200 MB)
3. Unzip / double-click dmg → drag **Ollama.app** to **Applications** (same gesture as Step 2 — see the drag-and-drop callout there)
4. Open **Applications → Ollama** → 🦙 llama icon appears in menu bar; daemon starts

Verify:
```bash
ollama --version
curl -s http://localhost:11434/api/version    # {"version":"0.x.x"}
```

#### Daemon management — start / stop / auto-start

| Action | How |
|---|---|
| **Start** | Applications → Ollama, or `open -a Ollama` |
| **Check if running** | `curl -s http://localhost:11434/api/version` |
| **Stop** | Menu-bar 🦙 → Quit Ollama |
| **Stop via terminal** | `osascript -e 'quit app "Ollama"'` |
| **Restart** | `osascript -e 'quit app "Ollama"'; sleep 2; open -a Ollama` |
| **Auto-start toggle** | Menu-bar 🦙 → "Start Ollama at Login" |

Run directly from terminal (needed to apply environment variables):
```bash
ollama serve                                                       # foreground (Ctrl+C to stop)
OLLAMA_NUM_CTX=8192 OLLAMA_FLASH_ATTENTION=1 ollama serve         # with tuning vars
```

#### Model management (basics → advanced)

##### Pull a model

```bash
ollama pull qwen2.5-coder:7b        # downloads ~4.7 GB
ollama pull llama3.1:8b
ollama pull <name>:<tag>             # general form (no tag = latest)
```

> 📂 **Models stored at**: `~/.ollama/models/` — can be several GB. Clean up with `ollama rm`.

##### List installed models

```bash
ollama list
# NAME                   ID            SIZE    MODIFIED
# qwen2.5-coder:7b       abc1234...    4.7 GB  2 days ago
```

##### Chat directly in the terminal (quick test)

```bash
ollama run qwen2.5-coder:7b                      # interactive chat (Ctrl+D to quit)
ollama run llama3.1:8b "Explain Docker in 3 lines"  # single shot
```

##### Inspect a model

```bash
ollama show qwen2.5-coder:7b
# Architecture: qwen2    Parameters: 7.6B    Quantization: Q4_K_M    Context: 32768
```

##### Update models (pull latest)

```bash
# One model
ollama pull qwen2.5-coder:7b        # re-pulls if a newer version exists

# All installed models at once
ollama list --json | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin)['models']:
    print(f'Updating {m[\"name\"]}...')
    subprocess.run(['ollama', 'pull', m['name']])
"
```

##### Delete models (reclaim disk)

```bash
ollama rm qwen2.5-coder:7b            # remove one model

# Remove all models (factory reset)
ollama list --json | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin)['models']:
    subprocess.run(['ollama', 'rm', m['name']])
"
```

#### Ollama REST API (developer / production)

Ollama exposes a REST API at `http://localhost:11434`. OpenClaw calls this internally. You can also hit it directly from scripts or other tools.

##### Key endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/version` | GET | Version check |
| `/api/tags` | GET | List installed models |
| `/api/ps` | GET | Currently loaded models (in memory) |
| `/api/generate` | POST | Text generation (streaming / non-streaming) |
| `/api/chat` | POST | Chat (message-array format) |
| `/api/embeddings` | POST | Embedding vectors (for RAG) |
| `/api/pull` | POST | Download a model |
| `/api/delete` | DELETE | Delete a model |
| `/api/show` | POST | Model details |
| `/v1/chat/completions` | POST | **OpenAI-compatible** endpoint |

##### curl examples

```bash
# Version
curl -s http://localhost:11434/api/version | python3 -m json.tool

# Installed models
curl -s http://localhost:11434/api/tags | python3 -m json.tool

# Text generation (non-streaming — whole response at once)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"Python Hello World","stream":false}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['response'])"

# Chat (streaming — one JSON object per line)
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"Hello"}]}'

# OpenAI-compatible endpoint (drop-in for OpenAI SDK)
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"Write Fibonacci in Python"}]}' \
  | python3 -m json.tool

# Currently loaded models
curl -s http://localhost:11434/api/ps | python3 -m json.tool
```

##### Python client

```bash
pip3 install ollama          # official Python client
```

```python
import ollama

# Single chat
response = ollama.chat(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': 'Write a Fibonacci function in Python'}]
)
print(response['message']['content'])

# Streaming (print token-by-token)
for chunk in ollama.chat(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': 'Tell me a long story'}],
    stream=True
):
    print(chunk['message']['content'], end='', flush=True)

# Embeddings (for RAG / vector search)
emb = ollama.embeddings(model='qwen2.5-coder:7b', prompt='some text')
print(len(emb['embedding']))    # vector dimensions

# Use existing OpenAI SDK pointing to Ollama (reuse old code)
from openai import OpenAI
client = OpenAI(base_url='http://localhost:11434/v1', api_key='ollama')
res = client.chat.completions.create(
    model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': 'Hello'}]
)
print(res.choices[0].message.content)
```

#### Performance tuning (Apple Silicon M-series)

##### Measure inference speed

```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"1+1=","stream":false}' \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'Output: {d.get(\"eval_count\",0)/max(d.get(\"eval_duration\",1),1)*1e9:.1f} tok/s')
print(f'Prompt: {d.get(\"prompt_eval_count\",0)/max(d.get(\"prompt_eval_duration\",1),1)*1e9:.1f} tok/s')
"
```

Expected on M5 Pro 24GB with qwen2.5-coder:7b: **30–55 tok/s**.

##### Verify GPU (Metal) acceleration

```bash
# Check server log for Metal usage
cat ~/Library/Logs/Ollama/server.log 2>/dev/null \
  | grep -iE "metal|gpu|offload|layer" | tail -10

# Or run with debug output (quit the app first)
OLLAMA_DEBUG=1 ollama serve 2>&1 | grep -iE "metal|gpu|offload"
# "offloading X layers to GPU" = GPU acceleration active
```

##### Environment variables for tuning

> ⚠ These variables must be set **in the shell that runs Ollama**. The macOS app does not read `~/.zshrc`. Either run `ollama serve` from terminal, or use `launchctl setenv`.

```bash
# Add to ~/.zshrc (applies when running `ollama serve` from terminal)

# Default context window in tokens (default 2048; larger = more RAM needed)
export OLLAMA_NUM_CTX=8192

# GPU layers (-1 = all GPU, recommended; 0 = CPU only)
export OLLAMA_GPU_LAYERS=-1

# Concurrent requests (default 1; increase for multiple simultaneous clients)
export OLLAMA_NUM_PARALLEL=1

# How long a model stays in memory (default 5m; -1 = forever; 0 = unload immediately)
export OLLAMA_KEEP_ALIVE=10m

# Flash Attention — improves memory efficiency (experimental)
export OLLAMA_FLASH_ATTENTION=1
```

**Inject env vars into the Ollama app (without running from terminal):**
```bash
launchctl setenv OLLAMA_NUM_CTX 8192
launchctl setenv OLLAMA_FLASH_ATTENTION 1
# Then restart Ollama
osascript -e 'quit app "Ollama"'; sleep 2; open -a Ollama
```

##### Recommended settings for M5 Pro 24 GB

```bash
export OLLAMA_NUM_CTX=8192          # 8 K context (stable with 7B + 24 GB)
export OLLAMA_KEEP_ALIVE=10m        # stay in memory for 10 min
export OLLAMA_FLASH_ATTENTION=1     # Flash Attention on
export OLLAMA_GPU_LAYERS=-1         # all layers on GPU
```

#### Memory management (unload / multi-model)

```bash
# Check what's currently loaded in memory
curl -s http://localhost:11434/api/ps | python3 -m json.tool

# Immediately unload a specific model (free RAM)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"","keep_alive":0}' > /dev/null
echo "unloaded"

# Unload all currently loaded models
curl -s http://localhost:11434/api/ps | python3 -c "
import json, sys, subprocess
for m in json.load(sys.stdin).get('models', []):
    name = m['name']
    print(f'Unloading {name}...')
    subprocess.run(['curl', '-s', 'http://localhost:11434/api/generate',
                    '-d', f'{{\"model\":\"{name}\",\"prompt\":\"\",\"keep_alive\":0}}'],
                   capture_output=True)
"

# macOS unified memory pressure
memory_pressure
```

> 💡 On 24 GB, running one 7B model at a time is most stable. Loading two simultaneously spills into swap and slows everything. Use `./openclaw clean` to free both Docker and Ollama memory at once.

#### Recommended models for M5 Pro 24 GB

| Model | Size | Speed | Best for | Command |
|---|---|---|---|---|
| `qwen2.5-coder:7b` | ~4.7 GB | Fast | **Coding — Neural Engine optimized** | `ollama pull qwen2.5-coder:7b` |
| `llama3.2:3b` | ~2.0 GB | Very fast | Lightweight / low-latency | `ollama pull llama3.2:3b` |
| `llama3.1:8b` | ~4.9 GB | Fast | High-quality general purpose | `ollama pull llama3.1:8b` |
| `qwen2.5:7b` | ~4.7 GB | Fast | Multilingual / strong Korean | `ollama pull qwen2.5:7b` |
| `deepseek-r1:7b` | ~4.7 GB | Medium | Reasoning / math | `ollama pull deepseek-r1:7b` |
| `solar-pro` | ~14 GB | Slow | Korean sovereign AI | `ollama pull solar-pro` |

> ⚠ **13B+ models on 24 GB — use with caution**: shared UMA means OS + apps eat into RAM, leaving ~14–16 GB for the model. 13B+ may cause OOM or severe slowdown. Stick with 7–8B for reliability.

```bash
ollama pull qwen2.5-coder:7b    # start with this one
ollama list                      # confirm
```

> 💡 **Not sure which to pick?** Browse https://ollama.com/library — filter by use case, size, and licence. OpenClaw doesn't require any specific model; set yours via `.env`'s `OLLAMA_DEFAULT_MODEL` or in the OpenClaw UI.

#### Integration with OpenClaw

OpenClaw containers reach the host Ollama via `host.docker.internal:11434`.

```bash
# Verify Ollama is reachable from inside the container (after starting OpenClaw)
docker exec openclaw-gateway \
  curl -s http://host.docker.internal:11434/api/tags | head -c 200
# {"models":[...]} = connected

# Register a model for OpenClaw to use
./openclaw models add qwen2.5-coder:7b     # updates .env + pulls if needed
./openclaw models list                      # check current config
```

> ⚠ **In `isolated` network mode, Ollama is also blocked**. To use Ollama you need to switch to `online` mode:
> ```bash
> ./openclaw network online --restart       # allow
> # when done
> ./openclaw network isolated --restart     # block again
> ```

#### Monitoring and troubleshooting

```bash
# Server logs
cat ~/Library/Logs/Ollama/server.log
tail -f ~/Library/Logs/Ollama/server.log    # live

# Port check
lsof -nP -iTCP:11434 -sTCP:LISTEN

# Ollama process memory usage
ps -o pid,rss,vsz,command -p $(pgrep -x ollama 2>/dev/null || echo 0) 2>/dev/null \
  | awk 'NR>1 && $1!="0" {printf "PID %s  RSS %dMB  VSZ %dMB\n",$1,$2/1024,$3/1024}'

# Apple Silicon GPU utilization (one sample)
sudo powermetrics --samplers gpu_power -n 1 2>/dev/null \
  | grep -iE "gpu active|gpu power|neural"
```

| Symptom | Cause / Fix |
|---|---|
| `connection refused 11434` | Ollama not running → `open -a Ollama` |
| `port 11434 already in use` | Another Ollama instance (normal). Check: `lsof -nP -iTCP:11434` |
| Model is slow | Low RAM — unload other models, run `./openclaw clean` |
| Response cuts off mid-sentence | Context overflow — use a smaller model or reduce `OLLAMA_NUM_CTX` |
| `model not found` | Run `ollama pull <model>` first |
| Model not visible in OpenClaw | `isolated` mode blocking it → `./openclaw network online --restart` |
| GPU not accelerating | Outdated Ollama version — reinstall from ollama.com |

### Step 4 — Get openclaw-workspace source

> 🤔 **Wait, two repos? Which one am I downloading?**
>
> | Repository | Owner | What it is | Do I need to download it? |
> |---|---|---|---|
> | 🟢 **`GoGoComputer/openclaw-workspace`** (this repo) | Park Sungmo (maintainer of this tool) | macOS automation tool — the `./openclaw` CLI, security compose overrides, this guide | **Yes — that's what Step 4 fetches** |
> | 🔵 **`openclaw/openclaw`** (OpenClaw upstream) | Official OpenClaw team | The AI agent itself (Python/JS code, container image source) | **No need to fetch manually** — `./openclaw install` clones it into `~/DEV/openclaw` automatically |
>
> So in Step 4 you only download **this repo (`GoGoComputer/openclaw-workspace`)**. The upstream agent is fetched for you in Step 5. Want to peek at the upstream too? See [💡 Visiting the OpenClaw upstream site](#-visiting-the-openclaw-upstream-site-optional) below.

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

#### 💡 Visiting the OpenClaw upstream site (optional)

If you want to preview what OpenClaw is, or if **corporate IT review** requires looking at the upstream code itself:

| What | URL |
|---|---|
| 🌐 OpenClaw official website (product, docs) | **https://clawbro.ai** |
| 🐙 OpenClaw upstream GitHub | **https://github.com/openclaw/openclaw** |
| 📦 Upstream releases | https://github.com/openclaw/openclaw/releases |
| 📖 Upstream README | https://github.com/openclaw/openclaw#readme |

Pre-fetching the upstream manually (optional — skips the clone step in `./openclaw install`):

```bash
# Git
git clone https://github.com/openclaw/openclaw.git ~/DEV/openclaw

# Or ZIP: GitHub page → green [<> Code] → Download ZIP →
unzip ~/Downloads/openclaw-main.zip -d ~/
mv ~/openclaw-main ~/DEV/openclaw
```

If `~/DEV/openclaw` already exists, `./openclaw install` will skip the clone step. Using a different location? Edit `OPENCLAW_DIR` in `.env`.

> ⚠ If you change the upstream URL or location, keep `OPENCLAW_REPO` and `OPENCLAW_DIR` in `.env` consistent. The `.env` file is auto-created on first run, so you can edit it then.

### Step 5 — First run of `openclaw`

> 🔀 **Choose your path:**

| | **Path A — Use the management tool** | **Path B — Run directly (manual)** |
|---|---|---|
| For | Letting openclaw-workspace automate the rest | You already cloned the openclaw repo directly |
| Directory | `~/DEV/openclaw-workspace/openclaw-mgr/` | `~/DEV/openclaw/` |
| First command | `./openclaw doctor` | `./docker-setup.sh` |
| Best if | First-time install | You've already cloned `openclaw/openclaw` |

---

#### Path A — Start via management tool (recommended)

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

Expect something like:
```
[doctor]
OS                    ✓ macOS (version)
Xcode CLT             ✓
Homebrew              ⚠ (absent but not required in manual mode)
Docker                ✓ (version)
Docker daemon         ✓ running
Ollama                ✓ (version)  (optional)
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

---

#### Path B — Direct first run (already cloned the openclaw repo)

> If you already ran `git clone https://github.com/openclaw/openclaw.git ~/DEV/openclaw`, one script handles everything: image build, initial config, and container startup.

```bash
cd ~/DEV/openclaw

# ① Run the setup script (interactive — one-time only)
./docker-setup.sh
```

The script will:
1. Build the Docker image locally (`DOCKER_BUILDKIT=1 docker build`)
2. Auto-generate the `.env` config file
3. Print onboarding info (channel connections optional — skip if you want)
4. Start the container: `docker compose up -d openclaw-gateway`

Verify after completion:
```bash
docker compose ps                   # State=running → OK
docker compose logs -f --tail=50    # Live logs (Ctrl+C to exit)
```

Open **http://localhost:8000** → UI appears.

> 💡 Day-to-day start/stop after this:
> ```bash
> cd ~/DEV/openclaw
> docker compose up -d      # start
> docker compose down       # stop
> docker compose logs -f    # logs
> ```

### Step 5b — Skip `openclaw install` and do everything manually (understand each step)

> 🎯 When `doctor` ends with **"⚠ N items unconfigured — './openclaw install' will fix them"**, follow this section if you'd rather **understand exactly what happens** instead of letting the script run.
>
> `./openclaw install` performs the 9 idempotent steps below. After manual installation most steps are `[skip]`; usually only the **last two (clone repo + start containers)** remain.

#### What `openclaw install` actually does (`openclaw-mgr/cmd/install.sh`)

| # | Step | Manual equivalent | Already done in this guide? |
|---|---|---|---|
| 1 | Xcode CLT | `xcode-select --install` | ✓ Step 1 |
| 2 | Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | (manual mode works without brew) |
| 3 | Docker Desktop | `brew install --cask docker` or download `.dmg` from docker.com | ✓ Step 2 |
| 3b | Docker daemon | `open -a Docker` + 90 s wait | ✓ Step 2.5 |
| 4 | Ollama running + **show existing models** | `open -a Ollama` + `ollama list` | ✓ Step 3 |
| 4b | *(models are manual)* | `ollama pull <model>` — not auto-downloaded | Pull whichever models you need |
| 5 | git clone OpenClaw upstream | see **5b-A** below | **manual from here** |
| 6 | Merge `.env` | see **5b-B** | **manual from here** |
| 7 | `docker compose up -d` | see **5b-C** | **manual from here** |
| 8 | Health check | see **5b-D** | |
| 9 | Apply network isolation | see **5b-E** | |

> 💡 Steps 1–4 were already done in this guide's Steps 1–3, so `doctor` typically reports "2 items unconfigured" (repo + containers). Only those remain.
>
> ⚠ **Ollama models are not auto-downloaded.** `openclaw install` only displays already-installed models. Pull what you need manually (`ollama pull qwen2.5-coder:7b` etc.).

---

#### 5b-A. git clone the OpenClaw upstream (manual)

> ✅ **Already done if you followed Step 5 Path B** — if `~/DEV/openclaw` exists, skip this section and go straight to 5b-B.

> If you haven't cloned the upstream yet (following Path A):

```bash
# Shallow clone (saves disk space)
git clone --depth 1 \
  https://github.com/openclaw/openclaw.git \
  ~/DEV/openclaw

# Verify
ls ~/DEV/openclaw    # docker-compose.yml, README.md, etc. → OK
```

> 🔐 Security check (optional): a `docker.sock` mount in compose = host takeover risk:
> ```bash
> grep -RIn '/var/run/docker.sock' ~/DEV/openclaw/*compose*.y*ml || echo "OK — no risky mount"
> ```

#### 5b-B. Merge `.env` (optional — fill missing keys from upstream's example)

```bash
SRC="$OPENCLAW_DIR/.env.example"
DST="$OPENCLAW_DIR/.env"
[ -f "$DST" ] || cp "$SRC" "$DST"

while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  key="${line%%=*}"
  grep -qE "^${key}=" "$DST" 2>/dev/null || echo "$line" >> "$DST"
done < "$SRC"

chmod 600 "$DST"
```

#### 5b-C. Start the containers (`docker compose up -d`)

```bash
cd "$OPENCLAW_DIR"

# Auto-detect compose file
COMPOSE_FILES="-f docker-compose.yml"
[ -f compose.yml ] && COMPOSE_FILES="-f compose.yml"

# Layer this tool's security override (recommended)
SEC="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.security.yml"
[ -f "$SEC" ] && COMPOSE_FILES="$COMPOSE_FILES -f $SEC"

# First boot needs internet (dependencies); start in non-isolated mode
docker compose $COMPOSE_FILES up -d
docker compose $COMPOSE_FILES ps           # State should be "running"
```

#### 5b-D. Health check (manual)

```bash
TOTAL=$(docker compose $COMPOSE_FILES ps -q | wc -l | tr -d ' ')
RUN=$(docker compose $COMPOSE_FILES ps --status running -q | wc -l | tr -d ' ')
echo "running: $RUN / $TOTAL"

# Ollama reachable from host?
curl -sS --max-time 3 http://127.0.0.1:11434/api/tags | head -c 200; echo

# UI port 8000?
curl -sS --max-time 5 -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8000
```

Open **http://localhost:8000** → if the UI loads, ✓.

#### 5b-E. Network isolation (recommended for security)

> The final step `openclaw install` does is restart the stack in **isolated** mode — outbound network blocked.

```bash
NET="$HOME/DEV/openclaw-workspace/openclaw-mgr/compose.network.yml"
[ -f "$NET" ] && COMPOSE_FILES="$COMPOSE_FILES -f $NET"

cd "$OPENCLAW_DIR"
docker compose $COMPOSE_FILES up -d        # restart in isolated mode

mkdir -p "$HOME/.openclaw-mgr"
echo isolated > "$HOME/.openclaw-mgr/network-mode"
```

> 💡 **Updates need a temporary opening:**
> ```bash
> ./openclaw network online --restart
> ./openclaw update
> ./openclaw network isolated --restart
> ```
> Or repeat 5b-C / 5b-E manually, toggling whether the network override is included.

---

#### Final check

```bash
cd ~/DEV/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

You should now see **"All good 🎉"**. If `Auto-update ⚠ unconfigured` remains, that's just an optional launchd schedule:
```bash
./openclaw schedule enable
```

### Step 5c — Sandbox + Security Hardening

> 🔒 **What is the sandbox?** When OpenClaw agents execute code, they run inside an **isolated container** — no direct access to your host filesystem, network, or processes. Enable this if security matters.

#### How sandbox isolation works

```
[agent request]
       ↓
  openclaw-gateway (container)
       ↓  via docker.sock
  openclaw-sandbox (ephemeral container — destroyed after each exec)
       ↓
  result returned to gateway only
```

- **`agents.defaults.sandbox.mode = non-main`** — forces sandbox for all sub-agents (not the main agent shell)
- **`agents.defaults.sandbox.scope = agent`** — isolation per agent
- **`agents.defaults.sandbox.workspaceAccess = none`** — sandbox cannot read workspace files directly

#### Method A — Automatic (recommended)

```bash
cd ~/DEV/openclaw

# Enable sandbox + rebuild with Docker CLI + start (all at once)
OPENCLAW_SANDBOX=1 ./docker-setup.sh
```

This command:
1. Rebuilds the Docker image with Docker CLI included (`--build-arg OPENCLAW_INSTALL_DOCKER_CLI=1`)
2. Auto-detects `docker.sock` GID → generates `docker-compose.sandbox.yml` overlay (socket mount + group_add)
3. Applies `agents.defaults.sandbox.mode/scope/workspaceAccess` config
4. Restarts the gateway (with sandbox overlay)

Expected completion message:
```
Sandbox enabled: mode=non-main, scope=agent, workspaceAccess=none
Docs: https://docs.openclaw.ai/gateway/sandboxing
```

#### Method B — Manual (step by step)

```bash
cd ~/DEV/openclaw

# 1) Rebuild image with Docker CLI included
DOCKER_BUILDKIT=1 docker build \
  --build-arg OPENCLAW_INSTALL_DOCKER_CLI=1 \
  -t openclaw:local .

# 2) Build the sandbox image
DOCKER_BUILDKIT=1 docker build \
  -t openclaw-sandbox:bookworm-slim \
  -f Dockerfile.sandbox .

# 3) Get Docker socket GID (macOS)
DOCKER_GID=$(stat -f '%g' /var/run/docker.sock)
echo "DOCKER_GID=$DOCKER_GID"

# 4) Create sandbox compose overlay
cat > docker-compose.sandbox.yml <<EOF
services:
  openclaw-gateway:
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    group_add:
      - "${DOCKER_GID}"
EOF

# 5) Start with sandbox overlay
docker compose \
  -f docker-compose.yml \
  -f docker-compose.sandbox.yml \
  up -d openclaw-gateway

# 6) Apply sandbox config
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.mode non-main
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.scope agent
docker compose exec openclaw-gateway \
  node dist/index.js config set agents.defaults.sandbox.workspaceAccess none

# 7) Restart to apply config
docker compose \
  -f docker-compose.yml \
  -f docker-compose.sandbox.yml \
  up -d openclaw-gateway
```

#### Verify sandbox

```bash
# Container status
docker compose ps
# openclaw-gateway   running

# Sandbox image exists
docker images | grep sandbox
# openclaw-sandbox   bookworm-slim   ...

# Check config
docker compose exec openclaw-gateway \
  node dist/index.js config get agents.defaults.sandbox
# Expected:
# { mode: 'non-main', scope: 'agent', workspaceAccess: 'none' }
```

#### ⚠️ Security notes

| Item | Detail |
|---|---|
| `docker.sock` mount | Required to spawn sandbox containers. If the gateway container is compromised, host Docker is accessible — use only trusted images |
| Sandbox image | `debian:bookworm-slim` via `Dockerfile.sandbox` — minimal packages only |
| Network isolation | Sandbox uses the same `network_mode: service:openclaw-gateway`. For extra external blocking: `./openclaw network isolated --restart` |
| Workspace access | `workspaceAccess=none` — sandbox cannot read host files |

#### Disable sandbox (revert)

```bash
cd ~/DEV/openclaw
# Re-run without OPENCLAW_SANDBOX — automatically resets sandbox.mode to off
./docker-setup.sh
```

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

> ❓ **If OpenClaw upstream updates, does my tool update automatically?**
>
> **No.** They are independent git repos and must be updated separately.
>
> | What | How to update | What it refreshes |
> |---|---|---|
> | 🟢 This tool (`openclaw-workspace`) | `git pull` (manual mode) or `openclaw self-update` (brew mode) | `openclaw` CLI, `lib/`, `cmd/`, security overrides, guide docs |
> | 🔵 OpenClaw upstream (`~/DEV/openclaw`) | `openclaw update` ← this tool runs upstream `git pull` + image pull + model pull for you | Upstream code, Docker images, Ollama models |
>
> So **tool up-to-date ≠ upstream up-to-date**. Run both to keep everything fresh.

#### Standard refresh (manual mode)

```bash
# 1) Update this tool (workspace)
cd ~/DEV/openclaw-workspace
git pull --ff-only

# 2) Update upstream + container images + models (one command)
./openclaw-mgr/openclaw update

# 3) Verify
./openclaw-mgr/openclaw doctor
```

#### What `openclaw update` does internally

```
openclaw update
  ├── network online (briefly allow outbound)
  ├── cd ~/DEV/openclaw && git pull --ff-only          ← upstream code
  ├── docker compose pull                            ← upstream images
  ├── docker compose up -d                           ← restart with new images
  └── network isolated (lock back down)
```

> 💡 **Ollama models are refreshed separately:** `update` does not pull models automatically.
> ```bash
> ollama list              # see what's installed
> ollama pull <model>      # e.g. ollama pull qwen2.5-coder:7b
> ```

#### Automate it — daily upstream update via launchd

```bash
./openclaw-mgr/openclaw schedule enable    # default 03:00 daily, runs `openclaw update`
./openclaw-mgr/openclaw schedule status
./openclaw-mgr/openclaw schedule disable
```

> ⚠ `schedule` only auto-runs **upstream update**. It does NOT auto-pull this tool — auto-recovering a broken tool is risky. Pull this tool by hand occasionally.

#### Pin to a specific version

This tool to a stable tag:
```bash
cd ~/DEV/openclaw-workspace
git fetch --tags
git checkout v0.1.6
```

Upstream to a specific commit (supply-chain hardening):
```bash
$EDITOR ~/.openclaw-mgr/.env
# OPENCLAW_PIN_COMMIT="abc1234..."
./openclaw-mgr/openclaw update
```

> ⚠️ `openclaw self-update` is intentionally disabled in manual mode (it's only for the Homebrew formula). Always use `git pull` for this tool in manual mode.

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

---

## 🧰 부록 A: 전문가용 운영 체크리스트 / Production-grade Checklist

> 이 섹션은 **이미 모든 단계를 완수한 사람** 을 위한 "운영 단계 굳히기" 안내입니다. 한 번씩 점검하면 회사·소버린 환경에서도 그대로 쓸 수 있습니다.

### A1. 보안 하드닝 / Security hardening

| 항목 | 명령 / 설정 | 왜 |
|---|---|---|
| `.env` 파일 권한 | `chmod 600 ~/DEV/openclaw-workspace/openclaw-mgr/.env` | 다른 사용자에게 시크릿 노출 방지 |
| 백업 디렉터리 권한 | `chmod 700 ~/openclaw-backups` | 스냅샷에 토큰·.env 포함됨 |
| GPG 백업 암호화 | `OPENCLAW_BACKUP_GPG_RECIPIENT=you@example.com ./openclaw backup` | 백업이 유출돼도 키 없으면 복호화 불가 |
| 네트워크 격리 기본 | `./openclaw network status` → `isolated` | 컨테이너가 외부 인터넷으로 데이터 누설 X |
| 컨테이너 read-only FS | `compose.security.yml` `read_only: true` | 컨테이너 안에서 악성 코드가 영속화 X |
| seccomp/capabilities 제한 | 동 파일 `cap_drop: [ALL]` + 필요한 것만 add | 시스템콜 표면 최소화 |
| 호스트 포트 바인딩 | `OPENCLAW_PORT` 는 `127.0.0.1:8000` 만 노출 | LAN/외부에서 접근 불가 (기본 그렇게 설정됨) |
| 자동 업데이트 후 재격리 | `./openclaw update` 가 자동으로 prev_mode 복원 | 업데이트 중에만 online, 끝나면 isolated |
| 의존성 핀 (재현성) | `.env` 의 `OPENCLAW_PIN_COMMIT=<sha>` | main 자동 추적 OFF, 감사 가능 |

### A2. 성능 튜닝 / Performance tuning (Apple Silicon)

```bash
# Metal 가속 사용 여부 확인 (반드시 true)
ollama run --verbose <model> "hi" 2>&1 | grep -i metal

# 모델 메모리에서 즉시 unload
curl -s http://127.0.0.1:11434/api/generate \
  -d '{"model":"<name>","keep_alive":0}'

# 동시 요청 수 / 컨텍스트 길이 환경변수 (~/Library/LaunchAgents 또는 launchctl setenv)
launchctl setenv OLLAMA_NUM_PARALLEL 2
launchctl setenv OLLAMA_MAX_LOADED_MODELS 1
launchctl setenv OLLAMA_FLASH_ATTENTION 1   # M3+ 권장
# 변경 후 Ollama 앱 재시작
```

| 변수 | 의미 | 권장값 (M5 Pro 24GB) |
|---|---|---|
| `OLLAMA_NUM_PARALLEL` | 동시 요청 처리 슬롯 | `1`–`2` |
| `OLLAMA_MAX_LOADED_MODELS` | 동시에 GPU에 올려둘 모델 수 | `1` |
| `OLLAMA_KEEP_ALIVE` | 미사용 모델 메모리 유지 시간 | `5m` (기본) |
| `OLLAMA_FLASH_ATTENTION` | 어텐션 최적화 (M3+) | `1` |
| `OLLAMA_HOST` | 청취 주소 | `127.0.0.1:11434` (외부 노출 금지) |

### A3. 가시성 / Observability

```bash
# 컨테이너 리소스 실시간
docker stats $(docker ps -q --filter name=openclaw)

# Ollama 모델별 메모리·로딩 상태
curl -s http://127.0.0.1:11434/api/ps | jq

# OpenClaw 로그 + 시크릿 마스킹
./openclaw logs | tee ~/openclaw-debug.log

# launchd 자동업데이트 마지막 결과
launchctl list | grep openclaw
tail -100 ~/.openclaw-mgr/schedule.log 2>/dev/null
```

### A4. 재현 가능한 배포 / Reproducible deploy

1. 한 머신에서 `./openclaw doctor` 통과 → `./openclaw backup --name golden`
2. `golden.tar.gz` + `golden.tar.gz.sha256` 를 다른 머신으로 복사 (USB 또는 사설 S3)
3. 새 머신: 본 가이드대로 0\~6단계 완료 → `./openclaw restore golden.tar.gz`
4. `.env` 의 `OPENCLAW_PIN_COMMIT` 동일하게 맞추면 코드 트리도 동일

### A5. CI / 사전 커밋 검사 / CI / pre-commit

```bash
# 매니저 자체 검사 (사용자 머신에서도 한 번씩)
bash -n $(find ~/DEV/openclaw-workspace -name '*.sh')   # 셸 구문
brew install shellcheck && shellcheck ~/DEV/openclaw-workspace/openclaw-mgr/cmd/*.sh
brew install gitleaks   && gitleaks detect --source ~/DEV/openclaw-workspace --no-git
```

> 사용자 머신에서 `gitleaks detect` 가 통과해야 백업·푸시가 안전합니다.

### A6. 회사·소버린 환경 체크 / Enterprise & sovereign checklist

- [ ] 모든 외부 도메인 접근 = `Docker.app`(이미지 pull) + `Ollama.app`(모델 pull) 둘뿐. 그 외는 컨테이너 isolated 모드에서 차단.
- [ ] LLM 추론은 100% 호스트(Apple Silicon) 위에서, 외부 API 호출 없음.
- [ ] 사용된 모델·버전·SHA256 = `./openclaw doctor` 출력 + `~/.ollama/models/manifests` 에 기록.
- [ ] `.env` / 백업 / 모델 파일이 회사 DLP 정책에 맞는 위치(`~/openclaw-backups`)에만 저장.
- [ ] 사고 대응: `./openclaw stop` → `./openclaw network isolated --restart` → `./openclaw backup --name incident-$(date +%F)` → 로그 수집.

---

## 🧰 Appendix A: Production-grade Checklist (English mirror)

The Korean checklist above applies as-is. English summary:

- **Permissions**: `chmod 600 .env`, `chmod 700 ~/openclaw-backups`.
- **Backups**: enable `OPENCLAW_BACKUP_GPG_RECIPIENT` for encrypted snapshots.
- **Network**: keep `./openclaw network status` = `isolated`; `update` auto-restores after.
- **Reproducibility**: pin `OPENCLAW_PIN_COMMIT=<sha>` in `.env`; ship `backup --name golden` between machines.
- **Performance** (Apple Silicon): verify Metal in `ollama run --verbose`; tune `OLLAMA_NUM_PARALLEL=1–2`, `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_FLASH_ATTENTION=1` via `launchctl setenv`.
- **Observability**: `docker stats`, `curl /api/ps | jq`, `./openclaw logs` (secrets masked).
- **CI/pre-commit**: `bash -n`, `shellcheck`, `gitleaks detect` before any commit/backup share.
- **Sovereign/enterprise**: only `Docker.app` and `Ollama.app` reach the public internet; inference is fully on-device; record model digests from `~/.ollama/models/manifests`.
