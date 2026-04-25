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
4. **`Docker.dmg` 더블클릭** → 잠시 도쿼니콘·화살표·Applications 폴더가 그려진 츽이 뜨고 세 아이콘이 나란히 떠있습니다.

   #### 🔗 드래그 앤 드롭 처음 해보세요? — 마우스로 이사하는 동작

   ```
   ┌───────────────────────┐
   │  🐳      ➜       📁 A     │
   │ Docker         Applications │
   └───────────────────────┘
        ↑                  ↑
      (이 고래를       (여기로
      잘·이하·끌고   놓아주세요)
      떨어뜨리세요)
   ```

   1. 마우스 커서를 **파란 고래(🐳 Docker)** 아이콘 위로 가져가세요.
   2. **트랙패드/마우스 왼쪽 버튼을 누른 채** 손가락을 뗼지 마세요.
   3. 그 상태로 파란 고래를 **염 폴더(📁 Applications)** 위까지 이동.
   4. 폴더가 **파랙게 하이라이트 되면** 그때 손가락을 뗘니다 (마우스 버튼 놓기).
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

`Cannot connect to the Docker daemon` 가 나오면 → 아직 시동 중. 잠시 기다리거나 메뉴바 고래 아이콘을 클릭해 상태 확인.

#### 데몬(서버) 끄기 / 재시작

| 동작 | 어떻게 |
|---|---|
| 🛑 **그냥 끄기** | 메뉴바 🐳 고래 클릭 → **Quit Docker Desktop** |
| 🔁 **재시작** | 메뉴바 🐳 고래 클릭 → **Restart** (충돌·메모리 누수 시 유용) |
| ⌨ **터미널에서 끄기** | `osascript -e 'quit app "Docker"'` |

> 💡 데몬을 끄면 **실행 중이던 OpenClaw 컨테이너도 자동으로 정지** 됩니다 (데이터는 보존, 다시 켜면 그대로 복귀).

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

### 3단계 — Ollama 직접 다운로드 (선택 — 로컬 LLM 쓸 때)

> Ollama = 내 컴퓨터에서 LLM(Llama, Qwen, Solar 등) 을 돌리는 런타임. 외부 API(OpenAI 등) 만 쓸 거면 이 단계는 건너뛰어도 됩니다.

1. 공식 다운로드 페이지: **https://ollama.com/download**
2. **Download for macOS** → `Ollama-darwin.zip` 또는 `.dmg` 받기 (~200MB).
3. zip 이면 더블클릭으로 풀고, **Ollama.app** 을 **Applications** 로 드래그 (위 2단계의 "드래그 앤 드롭" 설명 참조 — 동일한 동작)
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

> 🤔 **잠깐, 두 개의 저장소가 헷갈려요!**
>
> | 저장소 | 누구 | 무엇 | 언제 받나? |
> |---|---|---|---|
> | 🟢 **`GoGoComputer/openclaw-workspace`** (지금 이 저장소) | 박성모 (이 도구 메인테이너) | macOS 자동화 도구 (`./openclaw` 명령·docker-compose 보안 override·이 가이드 등) | **항상 받아야 함** — 4단계가 이걸 받는 단계 |
> | 🔵 **`openclaw/openclaw`** (OpenClaw 본체) | OpenClaw 공식팀 | AI 에이전트 본체 (Python/JS 코드, 컨테이너 이미지 소스) | **수동으로 받을 필요 없음** — `./openclaw install` 이 자동으로 `~/openclaw` 에 clone 함 |
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
git clone https://github.com/openclaw/openclaw.git ~/openclaw

# 또는 ZIP: 위 GitHub 페이지 → 초록 [<> Code] → Download ZIP →
unzip ~/Downloads/openclaw-main.zip -d ~/
mv ~/openclaw-main ~/openclaw
```

이렇게 미리 받아두면 `~/openclaw` 에 본체가 있으니 `./openclaw install` 이 그걸 그대로 사용합니다 (clone 단계 [skip]). 다른 위치에 받았으면 `.env` 의 `OPENCLAW_DIR` 만 수정하세요.

> ⚠ **주의**: 본체 저장소 URL 이나 클론 위치를 바꾸려면 `.env` 의 `OPENCLAW_REPO`, `OPENCLAW_DIR` 두 변수를 함께 맞춰주세요. 첫 실행 시 `.env` 가 자동 생성되니 그때 편집하면 됩니다.

### 5단계 — `openclaw` 첫 실행

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

> ❓ **OpenClaw 본체가 업데이트되면 내 도구도 자동으로 업데이트되나요?**
>
> **아니요.** 두 저장소는 서로 독립적인 git 저장소이며 따로 갱신해야 합니다.
>
> | 무엇 | 어떻게 갱신 | 무엇이 갱신되나 |
> |---|---|---|
> | 🟢 내 도구 (`openclaw-workspace`) | `git pull` (수동 모드) 또는 `openclaw self-update` (brew 모드) | `openclaw` CLI, `lib/`, `cmd/`, 보안 override, 가이드 문서 |
> | 🔵 OpenClaw 본체 (`~/openclaw`) | `openclaw update` ← 내 도구가 알아서 본체 git pull + 이미지 pull + 모델 pull 까지 | 본체 코드, Docker 이미지, Ollama 모델 |
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
  ├── cd ~/openclaw && git pull --ff-only          ← 본체 코드 갱신
  ├── docker compose pull                            ← 본체 이미지 갱신
  ├── docker compose up -d                           ← 새 이미지로 재기동
  ├── ollama pull <OLLAMA_MODELS 의 각 모델>        ← 모델 갱신
  └── network isolated (다시 잠금)
```

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

If you see `Cannot connect to the Docker daemon` it's still booting — wait a bit, or click the menu-bar whale to see status.

#### Stop / restart the daemon

| Action | How |
|---|---|
| 🛑 **Quit** | Menu-bar 🐳 → **Quit Docker Desktop** |
| 🔁 **Restart** | Menu-bar 🐳 → **Restart** (helps with crashes / memory leaks) |
| ⌨ **Quit from terminal** | `osascript -e 'quit app "Docker"'` |

> 💡 Stopping the daemon **also stops any running OpenClaw containers** (data is preserved; restart and they come back).

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

> Ollama runs LLMs (Llama, Qwen, Solar, …) on your Mac. Skip this step if you'll only use external APIs (OpenAI etc.).

1. Open **https://ollama.com/download**
2. **Download for macOS** → `Ollama-darwin.zip` or `.dmg` (~200 MB).
3. If zip: unzip and drag **Ollama.app** to **Applications** (same gesture as Step 2 above — see the "drag-and-drop" callout there).
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

> 🤔 **Wait, two repos? Which one am I downloading?**
>
> | Repository | Owner | What it is | Do I need to download it? |
> |---|---|---|---|
> | 🟢 **`GoGoComputer/openclaw-workspace`** (this repo) | Park Sungmo (maintainer of this tool) | macOS automation tool — the `./openclaw` CLI, security compose overrides, this guide | **Yes — that's what Step 4 fetches** |
> | 🔵 **`openclaw/openclaw`** (OpenClaw upstream) | Official OpenClaw team | The AI agent itself (Python/JS code, container image source) | **No need to fetch manually** — `./openclaw install` clones it into `~/openclaw` automatically |
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
git clone https://github.com/openclaw/openclaw.git ~/openclaw

# Or ZIP: GitHub page → green [<> Code] → Download ZIP →
unzip ~/Downloads/openclaw-main.zip -d ~/
mv ~/openclaw-main ~/openclaw
```

If `~/openclaw` already exists, `./openclaw install` will skip the clone step. Using a different location? Edit `OPENCLAW_DIR` in `.env`.

> ⚠ If you change the upstream URL or location, keep `OPENCLAW_REPO` and `OPENCLAW_DIR` in `.env` consistent. The `.env` file is auto-created on first run, so you can edit it then.

### Step 5 — First run of `openclaw`

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
> | 🔵 OpenClaw upstream (`~/openclaw`) | `openclaw update` ← this tool runs upstream `git pull` + image pull + model pull for you | Upstream code, Docker images, Ollama models |
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
  ├── cd ~/openclaw && git pull --ff-only          ← upstream code
  ├── docker compose pull                            ← upstream images
  ├── docker compose up -d                           ← restart with new images
  ├── ollama pull <each model in OLLAMA_MODELS>     ← refresh models
  └── network isolated (lock back down)
```

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
