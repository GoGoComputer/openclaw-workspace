# Troubleshooting / 트러블슈팅

> 🇰🇷 `./openclaw doctor` 출력에 따른 대응표.
> 🇺🇸 Recovery steps keyed off `./openclaw doctor` output.
>
> Each problem name below is followed by exact commands. The commands are language-agnostic; copy/paste as-is.

## 📖 목차 / Contents

- [`./openclaw doctor` 출력별 대응 / Recovery by `doctor` output](#openclaw-doctor-출력별-대응--recovery-by-doctor-output)
- [`doctor` 항목별 상세 가이드](#doctor-항목별-상세-가이드)
  - [OS / CPU / RAM / 디스크](#os--cpu--ram--디스크)
  - [Xcode Command Line Tools](#xcode-command-line-tools)
  - [Homebrew](#homebrew)
  - [Docker / Compose v2](#docker--compose-v2)
  - [Docker 데몬 ✗](#docker-데몬-)
  - [Ollama / 데몬 / 모델](#ollama--데몬--모델)
  - [OpenClaw 저장소](#openclaw-저장소)
  - [컨테이너 실행 0개](#컨테이너-실행-0개)
  - [포트 충돌 11434](#포트-충돌-11434)
  - [자동 업데이트 스케줄](#자동-업데이트-스케줄)
  - [네트워크 격리 모드](#네트워크-격리-모드)
- [`./openclaw install` 단계별 실패 가이드](#openclaw-install-단계별-실패-가이드)
  - [compose 보안 경고 — `/var/run/docker.sock`](#compose-보안-경고--varrundockersock)
  - [.env 병합 실패](#env-병합-실패)
  - [compose up 실패](#compose-up-실패)
  - [헬스체크 실패](#헬스체크-실패)
- [흔한 오류](#흔한-오류)
- [보안 경고가 떴어요](#보안-경고가-떴어요)
- [도움 요청 시 첨부할 정보](#도움-요청-시-첨부할-정보)

---

## `./openclaw doctor` 출력별 대응 / Recovery by `doctor` output

| 항목 | 상태 | 대응 |
|---|---|---|
| OS | ✗ | macOS 전용. Linux/Windows 미지원 |
| RAM | ⚠ | 16~24GB: 7B 모델 1개 권장. 동시 실행 자제 |
| RAM | ✗ | 16GB 미만: 외부 API 모드(`ENABLE_OLLAMA=0`) 권장 |
| 디스크 여유 | ✗ | 20GB 이상 확보 후 재시도 |
| Xcode CLT | ✗ | `xcode-select --install` 다이얼로그 따라가기 |
| Homebrew | ✗ | `./openclaw install` 이 자동 처리. 수동: brew.sh 공식 스크립트 |
| Docker 데몬 | ✗ | Docker Desktop 앱 실행. 약관 동의 필요할 수 있음 |
| Ollama 데몬 | ✗ | `brew services start ollama` |
| OpenClaw 저장소 | ✗ | `.env` 의 `OPENCLAW_REPO` 값 확인 |
| 컨테이너 실행 | ✗ | `./openclaw start` 또는 로그 확인 `./openclaw logs` |
| 포트 충돌 | ⚠ | `lsof -nP -iTCP:11434 -sTCP:LISTEN` 로 점유 프로세스 확인 |
| 자동 업데이트 | ⚠ | 원하면 `./openclaw schedule enable` |

---

## `doctor` 항목별 상세 가이드

> 이 섹션은 `./openclaw doctor` 가 보여주는 **각 줄에 대한 정밀 가이드**입니다. 각 항목마다:
> 1) 그게 뭔지, 왜 필요한지
> 2) `./openclaw install` 이 자동으로 무엇을 해주는지
> 3) 수동으로 해결하려면 어떻게 하는지 (스크립트를 못 쓰는 환경)
> 4) 자주 생기는 문제와 그 처방
>
> 대부분의 항목은 `./openclaw install` 한 번이면 자동으로 해결됩니다. 그래도 무엇이 어디에서 일어나는지 알아두면 막혔을 때 빠르게 빠져나올 수 있습니다.

### OS / CPU / RAM / 디스크

**무엇** — `doctor` 의 첫 4줄은 하드웨어 점검입니다. 본 도구는 **macOS 전용**이며 Apple Silicon에서 가장 잘 동작합니다(Intel 도 동작하나 일부 모델 추론이 느립니다).

**최소 / 권장 사양**

| 항목 | 최소 | 권장 |
|---|---|---|
| OS | macOS 15(Sequoia) | macOS 15+ |
| CPU | Intel x86_64 | Apple Silicon (M1~M5+) |
| RAM | 16GB | 24GB+ (큰 모델 동시 실행 시 32GB) |
| 디스크 여유 | 20GB | 50GB+ (이미지 + 모델 + 백업) |

**자동 처리** — 없음. 하드웨어는 사람이 준비합니다.

**수동 점검**
```bash
sw_vers                                       # macOS 버전
uname -m                                      # arm64 (Apple Silicon) / x86_64 (Intel)
sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}'
df -h ~                                       # 홈 디렉토리 여유 공간
```

**자주 나는 문제**
- *macOS 14 이하*: 일부 Docker Desktop 버전이 동작 안 함 → macOS 업데이트 권장.
- *디스크 5GB 미만*: 설치 도중 멈춤 → `./openclaw clean --all` 또는 다른 큰 파일 정리 후 재시도.
- *RAM 8GB*: 로컬 모델 운용은 사실상 불가 → `.env` 에 `ENABLE_OLLAMA=0` 으로 외부 API 모드.

---

### Xcode Command Line Tools

**무엇** — Apple이 제공하는 기본 컴파일러·`git`·`make` 등의 모음. Homebrew 가 패키지를 빌드하거나 `git clone` 을 할 때 필요합니다.

**자동 처리** — `./openclaw install` 의 `xcode_clt` 단계가 `xcode-select --install` 다이얼로그를 띄웁니다. **사람이 [설치] 버튼을 클릭**하면 5~10분 후 완료, 그 후 install이 이어서 진행합니다.

**수동 처리**
```bash
xcode-select --install        # 다이얼로그 → 설치 클릭
# 설치 완료까지 대기 (5~15분, 인터넷 속도 따라)
xcode-select -p               # /Library/Developer/CommandLineTools 출력 = OK
git --version                 # git version 2.x = OK
```

**자주 나는 문제**
- *`xcrun: error: invalid active developer path`* — CLT가 macOS 업데이트로 망가짐:
  ```bash
  sudo rm -rf /Library/Developer/CommandLineTools
  xcode-select --install
  ```
- *다이얼로그가 안 뜸* — Apple 서버 일시 장애. 잠시 후 같은 명령 재실행.
- *Xcode.app(전체)이 깔려 있음* — 큰 Xcode가 깔린 사람도 CLT만 별도 등록이 필요할 수 있음. 위 `xcode-select --install` 을 그래도 한 번 실행.

---

### Homebrew

**무엇** — macOS 의 사실상 표준 패키지 매니저. Docker Desktop·Ollama·기타 의존성을 설치할 때 사용합니다. 본 워크스페이스는 Homebrew 없이도 `git clone` + Docker Desktop 수동 설치로 동작 가능합니다([수동 설치 가이드](GUIDE-MANUAL-INSTALL.md)).

**자동 처리** — `./openclaw install` 의 `brew` 단계가 [brew.sh 공식 설치 스크립트](https://brew.sh)를 실행합니다. 중간에 `sudo` 비밀번호 1회 묻습니다.

**수동 처리**
```bash
# Apple Silicon 의 경우 /opt/homebrew 에 설치됨
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 설치 후 PATH 등록 (스크립트가 안내하는 그대로)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew --version
```

**자주 나는 문제**
- *회사 프록시* — `HTTPS_PROXY` 환경변수가 설정되어 있어야 brew install이 됩니다.
- *`/usr/local` 권한* — Intel macOS에서 다른 도구가 `/usr/local` 권한을 잡고 있으면 충돌. `brew doctor` 로 진단.
- *brew 자체가 거부됨* — 회사 정책으로 brew 가 금지된 경우 → [수동 설치 가이드](GUIDE-MANUAL-INSTALL.md)로 진행. brew 없이도 모든 단계 가능.

---

### Docker / Compose v2

**무엇** — 컨테이너 런타임. OpenClaw 에이전트가 살 격리된 박스를 제공합니다. Compose v2 는 `docker compose ...` 명령으로 여러 컨테이너를 묶어 띄우는 기능이며 Docker Desktop 에 기본 포함됩니다.

**자동 처리** — `./openclaw install` 의 `docker_install` 단계가 brew cask로 Docker Desktop 을 설치합니다(Apple Silicon용 ARM 빌드 자동 선택). 그 후 `docker_start` 단계에서 `open -a Docker` 로 데몬을 깨웁니다.

**수동 처리**
1. https://www.docker.com/products/docker-desktop/ 에서 칩(Apple Silicon vs Intel)에 맞는 `.dmg` 다운로드
2. 더블클릭 → 고래 아이콘을 Applications 폴더로 드래그
3. Applications 에서 Docker.app 실행 → 첫 실행 다이얼로그 따라가기 (아래 ["Docker Desktop 첫 실행"](#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) 참조)
4. 메뉴바 🐳 고래가 움직이지 않으면 준비 완료
5. `docker info` 가 `Server: ...` 를 출력하면 OK

**자주 나는 문제**
- 첫 실행 시 [Disable Rosetta] / 시스템 비밀번호 / 약관 / Docker Hub 가입 권유 등 여러 다이얼로그 — 자세한 처리는 [Docker Desktop 첫 실행](#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) 절 참조.

---

### Docker 데몬 ✗

**무엇** — Docker Desktop 앱은 깔려 있는데 **앱이 꺼져 있어** 백그라운드 데몬이 응답 안 하는 상태. `docker info` 가 `Cannot connect to the Docker daemon` 을 출력합니다.

**자동 처리** — `./openclaw install` 또는 `./openclaw start` 가 `open -a Docker` 로 앱을 깨우고 최대 90초 대기합니다.

**수동 처리**
```bash
open -a Docker                     # 또는 Spotlight 에서 "Docker" 실행
# 메뉴바 고래 아이콘이 멈출 때까지 30~60초 대기
docker info >/dev/null 2>&1 && echo "✓ daemon up" || echo "✗ still down"
```

여전히 안 뜨면 강제 재시작:
```bash
osascript -e 'quit app "Docker"' && sleep 5 && open -a Docker
```

**자주 나는 문제**
- *첫 실행 — 약관 동의 / 시스템 비밀번호* — 사람이 한 번 입력해야 데몬이 올라옵니다. 다이얼로그가 어떤 것인지는 [Docker Desktop 첫 실행](#docker-desktop-첫-실행--업데이트-안내--시스템-비밀번호--백그라운드-실행-알림) 표 참조.
- *Apple Silicon Rosetta 다이얼로그* — [Disable Rosetta] 추천, [Rosetta 다이얼로그 절](#docker-desktop---rosetta-installation-failed--vzerrordomain-code1-apple-silicon).
- *VM 디스크 손상* — Docker → Settings → Troubleshoot → Reset to factory defaults (드물게 필요).
- *설치 도중 Docker Desktop 을 끔 — `compose_up` 이 데몬에 연결 못 함* —
  ```
  unable to get image 'openclaw:local': Cannot connect to the Docker daemon
  at unix:///Users/mo/.docker/run/docker.sock. Is the docker daemon running?
  ✗ 단계 실패: compose_up (rc=1)
  ```
  `docker_start=done` 마커는 그대로 남아 있지만 데몬은 죽은 상태. v0.1.8 이상에서는 `compose_up` 이 시작 시점에 데몬을 다시 검사·기동합니다. 이전 버전은 `./openclaw self-update` 후 재시도하거나, 수동으로 `open -a Docker` 후 `./openclaw install` 재실행하세요.

---

### Ollama / 데몬 / 모델

**무엇** — 로컬에서 LLM(언어 모델)을 돌리는 작은 서버. 기본 포트는 `127.0.0.1:11434`. `ollama list` 로 받아둔 모델을 확인합니다.

**자동 처리** — `./openclaw install` 의 `ollama_install` → `ollama_start` → `ollama_models` 3단계로 처리:
1. `brew install ollama`
2. `brew services start ollama` (부팅 시 자동 시작 등록)
3. `.env` 의 `OLLAMA_MODELS` 목록을 순서대로 `ollama pull`

**수동 처리**
```bash
# 1) 설치
brew install ollama
# 또는 https://ollama.com/download 에서 .dmg 직접 다운

# 2) 데몬 시작
brew services start ollama
# 또는 일회성: ollama serve &

# 3) 확인
ollama --version
curl -s http://127.0.0.1:11434/api/version
ollama list

# 4) 원하는 모델 받기
ollama pull llama3.1:8b           # 예: 8B 일반 목적
ollama pull qwen2.5-coder:7b      # 예: 코딩
ollama pull solar-pro              # 예: 한국 소버린 AI
```

**자주 나는 문제**
- *데몬이 안 응답* — `brew services restart ollama` 또는 `pkill -f ollama && ollama serve &`
- *모델 pull 중 멈춤* — 같은 `ollama pull <모델>` 재실행 시 이어받기.
- *`isolated` 모드에서 컨테이너가 호스트 Ollama 호출 실패* — 의도된 격리. `./openclaw network online --restart` 로 잠시 열기.
- *디스크 부족* — 모델 하나가 4~40GB. `ollama rm <모델>` 로 정리.

---

### OpenClaw 저장소

**무엇** — 에이전트 본체 코드의 git 클론 위치. 기본은 `~/openclaw` 또는 `.env` 의 `OPENCLAW_DIR`. 컴포즈 파일이 그 안에 있어야 컨테이너를 띄울 수 있습니다.

**자동 처리** — `./openclaw install` 의 `repo_clone` 단계가 `.env` 의 `OPENCLAW_REPO` (기본 `https://github.com/openclaw/openclaw.git`) 를 클론합니다. 이미 존재하면 `git pull --ff-only` 로 갱신.

**수동 처리**
```bash
OPENCLAW_DIR="${HOME}/openclaw"
git clone --depth 1 https://github.com/openclaw/openclaw.git "$OPENCLAW_DIR"
ls "$OPENCLAW_DIR"          # docker-compose.yml 보이면 OK
```

**자주 나는 문제**
- *GitHub 502 Bad Gateway* — codeload 일시 장애. [GitHub 502 절](#brew-install-중-curl-56--error-502--github-502-bad-gateway) 참조 (방법 A: `git clone` 우선).
- *권한 거부 (private fork)* — `.env` 의 `OPENCLAW_REPO` 가 private 이라면 `git config --global url.git@github.com:.insteadOf https://github.com/` + SSH 키 등록.
- *브랜치 변경* — `OPENCLAW_PIN_COMMIT` 또는 `OPENCLAW_BRANCH` 로 고정.

---

### 컨테이너 실행 0개

**무엇** — `docker compose ps` 가 빈 결과 = 에이전트가 떠 있지 않음. `install` 이 끝났는데도 0개라면 `compose_up` 또는 `health` 단계에서 멈춘 것입니다.

**자동 처리** — `./openclaw start` 가 `docker compose up -d` 로 백그라운드 기동.

**수동 처리**
```bash
./openclaw start
./openclaw logs                  # 전체 서비스 로그
./openclaw logs surf -f          # 특정 서비스 follow
docker compose ps                # 호스트에서 직접 상태 보기
```

문제가 있는 컨테이너가 보이면:
```bash
docker compose down              # 깨끗이 정리
docker compose up -d --force-recreate
```

**자주 나는 문제** — 거의 모두 `compose up` 단계 문제이며 [compose up 실패](#compose-up-실패) 절에서 다룹니다.

---

### 포트 충돌 11434

**무엇** — 11434 는 Ollama 의 기본 포트. **다른 프로세스가 같은 포트를 잡고 있으면** 새 Ollama 데몬이 못 뜨거나, 컨테이너에서 `host.docker.internal:11434` 호출이 엉뚱한 데로 갑니다. `doctor` 가 ⚠ 로 알려줍니다.

**자동 처리** — `install` 은 포트 충돌을 **자동으로 해결하지 않습니다** (그쪽 프로세스를 마음대로 죽이는 건 위험하므로). 사람이 확인 후 결정해야 합니다.

**수동 진단 — 누가 잡고 있나?**
```bash
lsof -nP -iTCP:11434 -sTCP:LISTEN
# 출력 예:
# COMMAND   PID USER   FD   TYPE ...
# ollama  12345 mo    7u   IPv4 ...    *:11434 (LISTEN)
```

**처방 1 — 같은 Ollama 인 경우 (가장 흔함)**
이미 `ollama serve` 가 떠 있는데 또 띄우려다 충돌한 것입니다. 그대로 두면 됩니다. 데몬을 재시작하고 싶으면:
```bash
brew services restart ollama
# 또는
pkill -f "ollama serve" && sleep 1 && ollama serve &
```

**처방 2 — 옛날에 띄워둔 다른 Ollama**
중복 인스턴스가 떠 있는 경우. PID 를 확인 후 종료:
```bash
lsof -nP -iTCP:11434 -sTCP:LISTEN | awk 'NR>1 {print $2}' | xargs kill
brew services start ollama
```

**처방 3 — 완전히 다른 프로그램이 11434 사용**
드물지만, 다른 ML 도구(LocalAI, llama.cpp 서버 등)가 같은 포트를 쓰고 있을 수 있습니다. 두 가지 선택:
- 그 도구 멈추기 (그쪽 manual)
- Ollama 의 포트 바꾸기:
  ```bash
  brew services stop ollama
  OLLAMA_HOST=127.0.0.1:11500 ollama serve &
  # 그리고 .env 에:
  # OLLAMA_HOST="http://host.docker.internal:11500"
  ./openclaw update
  ```

**확인**
```bash
curl -s http://127.0.0.1:11434/api/version   # {"version":"..."} 가 떠야 함
```

---

### 자동 업데이트 스케줄

**무엇** — macOS 의 launchd에 매일 정해진 시각(`.env` 의 `SCHEDULE_TIME`, 기본 03:00)에 `./openclaw update` 를 자동 실행하도록 등록합니다. 미설정이 기본값.

**자동 처리** — 없음(사용자 의사 결정). `./openclaw schedule enable` 한 번이면 끝.

**수동 처리**
```bash
./openclaw schedule enable      # 매일 자동 update 등록
./openclaw schedule status      # 다음 실행 시각 확인
./openclaw schedule disable     # 해제
```

**자주 나는 문제** — 등록은 됐는데 안 도는 듯한 경우:
```bash
launchctl list | grep openclaw                              # 등록 확인
cat ~/.openclaw-mgr/logs/update.err.log                     # 에러 로그
launchctl print "gui/$(id -u)/com.user.openclaw.update"     # 다음 실행 시각 / 종료 코드
launchctl kickstart -p "gui/$(id -u)/com.user.openclaw.update"   # 수동으로 한 번 돌리기
```

회사 노트북에서 *맥 잠긴 상태에서는 launchd 작업이 미뤄질 수 있음* — 점심 시간 등 깨어 있는 시각으로 `SCHEDULE_TIME` 을 옮기세요.

---

### 네트워크 격리 모드

**무엇** — 컨테이너의 외부 인터넷 접근을 켜고/끄는 토글. 기본값은 `isolated`(완전 차단). `online` 은 설치/업데이트 동안만 잠깐 사용. 자세한 의미와 트레이드오프는 [README — 🔒 네트워크 격리 모드](../README.md#-네트워크-격리-모드-명시적-외부-차단-토글) 참조.

**자동 처리** — `./openclaw update` 가 필요한 동안만 자동으로 `online` 으로 전환했다가 원래 모드로 복귀합니다.

**수동 처리**
```bash
./openclaw network status                   # 현재 모드
./openclaw network online --restart         # 일시 허용
./openclaw network isolated --restart       # 다시 잠그기 (평소 권장)
```

**자주 나는 문제**
- *`isolated` 인데 모델 pull 실패* — 의도된 동작. `online` 으로 잠시 전환.
- *`online` 인데도 외부 통신 실패* — 회사/공용 와이파이의 방화벽이 추가로 막고 있을 수 있음. `HTTPS_PROXY` 환경변수 설정 후 재시도.

---

## `./openclaw install` 단계별 실패 가이드

`install` 은 `lib/common.sh` 의 `run_step` 래퍼와 `~/.openclaw-mgr/state` 마커로 멱등 처리됩니다. 같은 명령을 다시 치면 **마지막 실패 단계부터** 이어집니다. 그래도 막히면 아래 처방을 참고하세요.

특정 단계만 다시 돌리려면 상태 파일에서 해당 줄을 지웁니다:

```bash
sed -i '' '/^docker_start=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

### 다른 컴퓨터에서 최신 받고 재설치 (한 번에)

집/회사 컴퓨터 등 **이미 한 번 설치된 머신** 에서 워크스페이스 코드를 최신화한 뒤 재설치하는 표준 절차:

```bash
# 1) 워크스페이스로 이동 (이전 설치 시 사용한 경로 그대로)
cd ~/DEV/openclawAgent/openclaw-workspace

# 2) 최신 코드 받기 (둘 중 하나)
git pull origin main
#   또는
./openclaw-mgr/openclaw self-update

# 3) 실패한 단계만 다시 돌리도록 마커 리셋
#    (예: compose_up 에서 죽었으면 compose_up 만 지움)
sed -i '' '/^compose_up=done$/d' ~/.openclaw-mgr/state

# 4) 재설치 — 끝난 단계는 자동 스킵, 실패 단계부터 재개
cd openclaw-mgr
./openclaw install

# 5) 정상 동작 확인
./openclaw doctor
```

처음부터 다시 깨끗이 하려면 마커 전체를 지워도 안전합니다 (각 단계가 자체적으로 "이미 됨" 을 감지):

```bash
rm ~/.openclaw-mgr/state
./openclaw install
```

저장소 자체를 처음 받는 새 컴퓨터의 경우는 [docs/QUICKSTART-ko.md](QUICKSTART-ko.md) 참조.

각 단계 실패의 일반적 원인은 [README — 설치 중 멈춘 시](../README.md#설치-중-멈춘-시--단계별-장애-가이드) 표 참조. 아래는 **자동 해결이 안 되는 단계**를 자세히 다룹니다.

### compose 보안 경고 — `/var/run/docker.sock`

```
» compose 보안 검사
✗ 위험: compose 파일에 /var/run/docker.sock 마운트가 발견되었습니다.
✗ 이 마운트는 컨테이너에서 호스트를 완전히 장악할 수 있는 권한입니다.
✗ 해당 줄을 제거하거나, 신뢰 가능한 fork 를 사용하세요.
✗ 단계 실패: compose_scan (rc=1)
```

**왜 위험한가**
- `/var/run/docker.sock` 은 호스트의 Docker 데몬과 직접 대화하는 소켓입니다.
- 이를 컨테이너에 마운트하면 그 컨테이너는 **호스트의 모든 컨테이너를 만들고/지우고/특권 모드로 띄울 수 있습니다**.
- 결과적으로 컨테이너 안의 코드가 호스트의 root 권한을 사실상 획득하는 것과 같습니다.
- AI 에이전트가 사는 컨테이너에 이 권한이 있으면, 프롬프트 인젝션 한 번으로 호스트 전체가 장악될 수 있습니다.
- 이 도구의 보안 정책은 **이 마운트를 절대 허용하지 않는 것**입니다. `compose_scan` 단계가 발견 즉시 설치를 중단합니다.

**스캐너의 판정 기준 (오탐 방지)**

`compose_scan` 은 YAML 의 **활성화된 마운트 항목**만 위험으로 본다:

| 라인 | 판정 |
|---|---|
| `      - /var/run/docker.sock:/var/run/docker.sock` | ✗ 위험 (활성 마운트) |
| `      - "/var/run/docker.sock:/var/run/docker.sock"` | ✗ 위험 (따옴표 변형) |
| `      # - /var/run/docker.sock:/var/run/docker.sock` | ✓ 안전 (주석 처리됨) |
| `      ## 다음 줄을 활성화하면 /var/run/docker.sock 마운트가 됩니다` | ✓ 안전 (설명 주석) |
| `# DOCKER_GID 는 stat -c '%g' /var/run/docker.sock 으로 확인` | ✓ 안전 (안내 주석) |

> 만약 위 표의 "안전" 줄에서도 ✗ 가 떴다면 스캐너 버그입니다. [GitHub Issues](https://github.com/GoGoComputer/openclaw-workspace/issues) 로 해당 compose 라인을 그대로 알려주세요. (v0.1.7 이전 버전은 주석 라인도 잘못 차단했었습니다 — `./openclaw self-update` 후 재시도하세요.)

**원인 — 어디서 들어왔나**
- 보통 `OPENCLAW_REPO` 가 가리키는 OpenClaw 저장소(또는 그 fork)의 `docker-compose.yml` 에 들어 있습니다.
- 일부 fork 가 "에이전트가 자기 자신을 재시작하게 하려고" 또는 "다른 컨테이너를 생성하게 하려고" 의도적으로 추가합니다 — **편의를 위해 보안을 포기한 설계**.

**해결 1 — 안전한 공식 저장소 사용 (권장)**
```bash
# .env 의 OPENCLAW_REPO 를 공식으로 되돌립니다
$EDITOR ~/.openclaw-mgr/.env
# OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"

# OpenClaw 본체를 깨끗이 다시 받기
rm -rf "$OPENCLAW_DIR"   # 기본 ~/openclaw
sed -i '' '/^repo_clone=done$/d;/^compose_scan=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

**해결 2 — fork 의 compose 파일을 직접 수정**
공식 저장소를 못 쓰는 사정(사내 fork)이 있다면, 그 fork 의 `docker-compose.yml` 또는 `compose.*.yml` 에서 다음 패턴을 **모두 삭제 또는 주석 처리**하세요:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock           # ← 삭제 또는 앞에 # 추가
  - /var/run/docker.sock:/var/run/docker.sock:ro        # ← 삭제 (read-only도 위험)
  - "/var/run/docker.sock:/var/run/docker.sock"
```

지운 뒤:
```bash
sed -i '' '/^compose_scan=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

> 단, 그 fork 가 docker.sock 을 정말 필요로 하는 기능을 갖고 있다면 그 기능은 동작하지 않을 수 있습니다. **그 기능보다 호스트 보안이 훨씬 더 중요합니다.**

**해결 3 — 의도적으로 무시 (하지 마세요)**
스캔을 우회하는 환경변수는 의도적으로 제공하지 않습니다. 이 보안 정책은 협상 불가입니다. 정말 필요한 경우는 격리된 가상머신 안에서 별도로 운영하세요.

**검증** — 해결 후 직접 검사:
```bash
# 활성 라인만 잡는 검사 (스캐너와 같은 방식)
sed -E 's/[[:space:]]*#.*$//' "$OPENCLAW_DIR"/docker-compose*.y*ml \
  | grep -E '(^|[[:space:]])-[[:space:]]+"?/var/run/docker\.sock' && echo "✗ 활성 마운트 발견" || echo "✓ 깨끗"
./openclaw doctor
```

---

### .env 병합 실패

**무엇** — `install` 의 `env_merge` 단계가 `.env.example` 의 새 키를 기존 `.env` 에 추가하려다 실패. 보통 권한 문제.

**해결**
```bash
ls -l ~/.openclaw-mgr/.env
chmod 600 ~/.openclaw-mgr/.env
# 또는 OpenClaw 본체 .env:
ls -l "$OPENCLAW_DIR/.env"
chmod 600 "$OPENCLAW_DIR/.env"

sed -i '' '/^env_merge=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

만약 `.env` 가 사용자 키를 잘못 덮었다면 백업에서 복원:
```bash
ls ~/.openclaw-mgr/.env.bak.*
cp ~/.openclaw-mgr/.env.bak.<timestamp> ~/.openclaw-mgr/.env
```

---

### compose up 실패

**무엇** — `docker compose up -d` 가 0이 아닌 종료 코드로 실패. 가장 흔한 5가지 원인:

**원인 0 — `services.openclaw-cli.security_opt items at 0 and 1 are equal`**

```
validating .../compose.security.yml: services.openclaw-cli.security_opt items at 0 and 1 are equal
✗ 단계 실패: compose_up (rc=1)
```

`compose.security.yml` 이 베이스 `docker-compose.yml` 과 머지될 때, Compose v2 는 시퀀스(예: `security_opt`, `cap_drop`, `ports`)를 **concat** 합니다. 양쪽이 같은 항목 (`no-new-privileges:true`) 을 갖고 있으면 머지 결과에 같은 값이 두 번 들어가고 최신 Compose 가 이를 거부합니다.

해결 — `openclaw-mgr/compose.security.yml` 의 `openclaw-cli` 블록에서 `security_opt` 를 **삭제** 합니다 (베이스가 이미 갖고 있으므로 중복 선언만 제거하면 됨):

```yaml
  openclaw-cli:
    cap_drop: [ALL]
    # security_opt 는 베이스가 이미 가짐 — 중복 선언 금지
    pids_limit: 256
```

본 레포의 v0.1.7 이상은 이 수정이 반영되어 있습니다. 이전 버전을 쓰고 있다면 `./openclaw self-update` 후 재시도하세요.

검증:
```bash
docker compose -f "$OPENCLAW_DIR"/docker-compose.yml -f openclaw-mgr/compose.security.yml config | grep -A2 security_opt
# 각 서비스마다 - no-new-privileges:true 가 1개씩만 나와야 함
```

---

**원인 A — 호스트 포트 점유**
```
Error: bind: address already in use
```
충돌하는 포트를 찾고 점유 프로세스를 처리:
```bash
# OpenClaw 가 쓰는 포트(.env 의 OPENCLAW_PORT, 기본 8000) 점유 확인
lsof -nP -iTCP:8000 -sTCP:LISTEN
# 다른 앱이라면 종료하거나, .env 의 OPENCLAW_PORT 를 8001 등 다른 번호로 변경
```

**원인 B — 이미지 pull 실패**
```
Error response from daemon: pull access denied for openclaw,
repository does not exist or may require 'docker login'
```
- *`openclaw:local` 을 pull 하려고 함* — `openclaw:local` 은 **로컬 빌드 이미지**라 레지스트리에 없습니다. v0.1.9 이상은 `compose_up` 직전에 자동으로 `docker build -t openclaw:local "$OPENCLAW_DIR"` 를 실행합니다. 이전 버전은 `./openclaw self-update` 후 재시도하거나, 수동으로:
  ```bash
  cd "$OPENCLAW_DIR"
  DOCKER_BUILDKIT=1 docker build -t openclaw:local .
  cd -
  ./openclaw install
  ```
- *공개 이미지인데 401* — Docker Hub 무인증 한도 초과(드뭄). `docker login` 후 재시도.
- *비공개 레지스트리* — `docker login <레지스트리>` 필요.
- *태그 오타* — `OPENCLAW_REPO` 의 compose 파일 이미지 태그 확인. 다른 이미지를 쓰려면 `.env` 의 `OPENCLAW_IMAGE` 를 그 태그로 지정.

**원인 C — Compose 파일 문법 오류**
```
yaml: line N: ...
```
직접 검증:
```bash
cd "$OPENCLAW_DIR"
docker compose config              # 파싱 에러 위치 출력
```

**원인 D — 디스크 부족**
```
no space left on device
```
```bash
df -h
docker system df                   # docker가 차지한 용량
./openclaw clean --all
```

해결 후:
```bash
sed -i '' '/^compose_up=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

---

### 헬스체크 실패

**무엇** — 컨테이너는 떴는데(`docker compose ps` 가 Up 표시) 헬스체크 엔드포인트(`http://127.0.0.1:8000/...`)가 응답 안 함.

**진단**
```bash
docker compose ps                          # health 컬럼 확인 (starting/healthy/unhealthy)
./openclaw logs                            # 전체 서비스 로그
./openclaw logs <서비스이름> -f            # 특정 서비스 follow
curl -fsS http://127.0.0.1:8000/healthz    # 직접 호출 (엔드포인트는 OpenClaw 버전마다 다름)
```

**일반적 처방**
- 첫 기동은 1~2분 걸릴 수 있음. 기다린 후 재진단.
- 모델이 큰 경우 첫 추론 전 메모리에 올리는 데 30~60초 걸림 → 헬스체크 타임아웃을 늘려도 됨(`compose.security.yml` 또는 OpenClaw 본체 compose).
- `isolated` 모드에서 외부 모델 호출이 필요한 워크플로 → `online` 으로 전환 후 재기동.

여전히 unhealthy 면 컨테이너만 재생성:
```bash
cd "$OPENCLAW_DIR"
docker compose up -d --force-recreate <서비스명>
```

---

## 흔한 오류

### `Error: Cannot connect to the Docker daemon`

Docker Desktop 이 안 켜져 있습니다. `open -a Docker` 후 90초 대기.

### `xcrun: error: invalid active developer path`

Xcode CLT 가 망가졌거나 macOS 업데이트 후. 해결:
```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### `Docker Desktop - Rosetta installation failed` / `VZErrorDomain Code=1` (Apple Silicon)

Docker Desktop 첫 실행 시 Apple Silicon 맥에서 Rosetta 2 자동 설치가 실패할 때 뜨는 다이얼로그입니다. **Docker 자체는 정상**이며, OpenClaw 가 사용하는 모든 이미지는 ARM64 네이티브라 Rosetta 가 **필요 없습니다**.

**가장 쉬운 해결: 다이얼로그의 [Disable Rosetta] 버튼을 클릭하세요.** 끝.

그래도 Rosetta 를 깔고 싶으면 (다른 Intel-only 이미지를 같이 쓸 일이 있을 때):

```bash
# 터미널에서 직접 설치 (자동 설치보다 성공률이 높음)
softwareupdate --install-rosetta --agree-to-license

# 그 다음 Docker 다이얼로그의 [Retry] 클릭
# 또는 Docker 자체를 재시작:
osascript -e 'quit app "Docker"' && sleep 5 && open -a Docker
```

확인:
```bash
docker --version
docker info       # Server: ... 행이 보이면 OK
arch -x86_64 echo ok    # Rosetta 정상 작동 시: ok
```

> 💡 **권장**: OpenClaw 만 쓸 거면 그냥 **Disable Rosetta**. 나중에 필요해지면 Settings → General → "Use Rosetta for x86_64/amd64 emulation" 로 다시 켤 수 있습니다.

### Docker Desktop 첫 실행 — 업데이트 안내 / 시스템 비밀번호 / "백그라운드 실행" 알림

[Disable Rosetta] 다음에 **순서대로** 다음 화면들이 뜨는 것은 모두 **정상** 입니다. 그냥 따라가시면 됩니다.

| 순서 | 화면 / 다이얼로그 | 어떻게 |
|---|---|---|
| 1 | "**A new version of Docker Desktop is available**" 업데이트 안내 | **[Update and Restart]** 또는 **[Install Update]** 클릭. 길어야 1~2분, 자동 재시작. (지금은 [Skip] 가능하지만 빨리 깔수록 좋음.) |
| 2 | "**Docker Desktop needs privileged access**" + macOS 시스템 비밀번호 입력창 | macOS 로그인 비밀번호 (Touch ID 가능) 입력 → **[OK]**. 이건 Docker 가 가상화 헬퍼·네트워크 드라이버를 설치하기 위한 1회성 권한입니다. |
| 4 | "**Complete the installation of Docker Desktop**" — *Use recommended settings (requires password)* ↔ *Use advanced settings* | **● Use recommended settings** 선택 → **[Finish]**. 추천 설정이 `docker` CLI symlink·가상화 헬퍼·네트워크 권한을 자동으로 잡아주며, OpenClaw 가 `docker` 명령을 PATH 에서 찾으려면 필수입니다. **Advanced** 는 설치 경로를 직접 지정하고 싶은 경우에만 — 일반 사용자에게는 불필요, 잘못 건드리면 OpenClaw 가 docker 명령을 못 찾을 수 있습니다. 모든 항목은 추후 Settings 에서 변경 가능. |
| 5 | "**Welcome to Docker**" / 설문 (사용 목적 등) | 원하면 작성, **[Skip]** 도 가능. OpenClaw 와 무관. |
| 5b | "**Sign in to Docker Desktop**" / Docker Hub 계정 가입 화면 | **로그인 불필요**. 화면 어딘가의 작은 **[Skip]** / **[Continue without signing in]** 클릭. Docker Hub 계정은 OpenClaw 사용과 무관 — 공개 이미지 pull 은 무인증으로 IP당 6시간에 100회까지 가능하고 (대부분 안 걸림), 우리는 비공개 레지스트리도 push 도 사용하지 않습니다. 한 줄 요약: **계정 만들 필요 없으니 Skip**. |
| 6 | 우측 상단 알림 — "**'Docker' can run in the background. You can manage background activity in Login Items & Extensions.**" | macOS 의 정보성 알림. **그냥 무시** 하면 됩니다. 의미: Docker 데몬이 메뉴바에 살아 있는다는 뜻 (정상). 자동시작이 싫으면 **시스템 설정 → 일반 → 로그인 항목 → 백그라운드 항목** 에서 `Docker` 토글 OFF. |

### ⚠️ 비밀번호 다이얼로그가 의심스러우면

진짜 macOS 시스템 다이얼로그인지 확인하는 법:
- 다이얼로그가 **화면 중앙**에 뜨고 (앱 안이 아니라)
- 자물쇠 아이콘 + "Touch ID 또는 비밀번호로..." 문구
- 발신자: `com.docker.vmnetd` 또는 `com.docker.helper`
- macOS 의 다른 모든 작업이 어두워짐 (모달)

위 4가지가 모두 맞으면 진짜입니다. 1회만 묻고 그 뒤로는 안 묻습니다.

### Docker Hub 계정은 만들어야 하나요? (Sign in 화면)

**아니요. OpenClaw 사용에는 전혀 필요 없습니다.** Docker Desktop 이 자꾸 가입을 권하지만 항상 Skip 가능합니다.

| 무엇 | OpenClaw 에 필요? |
|---|---|
| Docker Desktop 자체 | ✅ 필요 |
| Docker Hub 회원가입 / `docker login` | ❌ 불필요 |
| Docker Pro / Team 유료 구독 | ❌ 불필요 |

**왜 권유?** Docker 사 입장에서 등록 사용자를 늘리려는 마케팅. **Skip / Continue without signing in** 링크가 항상 화면 어딘가 (보통 작게) 있습니다.

**계정이 실제로 쓰이는 경우 (참고)**:
- 본인 이미지를 Docker Hub 에 push (개인 프로젝트 공개·비공개 저장)
- 회사 사내 레지스트리 `docker login mycompany.registry.com` 접속
- 무인증 pull 한도(IP당 6시간 100회) 초과 — 거의 안 걸림
- 250인 이상 기업의 Docker Desktop 유료 라이선스

OpenClaw 는 위 4가지 모두 해당 없음 → **Skip**.

### 첫 실행 끝났는지 확인

메뉴바 우측 상단 🐳 고래 아이콘이 **움직이지 않는 상태** = 데몬 준비 완료. 터미널에서:
```bash
docker --version
docker info        # Server: ... 행이 보이면 OK
```

### `pull access denied for ...` (compose pull 실패)

비공개 레지스트리 또는 잘못된 이미지 태그. `OPENCLAW_REPO` 확인 + `docker login` 필요할 수 있음.

### Ollama 모델 pull 중간에 멈춤

네트워크 일시 단절. 같은 명령 재실행 시 이어받기:
```bash
ollama pull <model>
```

### `./openclaw install` 이 같은 단계에서 계속 실패

해당 단계만 다시 시도하려면 `~/.openclaw-mgr/state` 에서 그 줄을 지우세요:
```bash
sed -i '' '/^docker_start=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

### `brew install` 중 `curl: (56) ... error: 502` / GitHub 502 Bad Gateway

GitHub (codeload) 일시 장애입니다. 우리 Formula·SHA256 문제가 아니므로 잠시 후 재시도하면 됩니다.

```bash
# 1) 같은 명령 다시
brew install gogocomputer/openclaw/openclaw-workspace

# 2) 그래도 안 되면 캐시 비우고 강제 재시도
brew cleanup -s
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --force gogocomputer/openclaw/openclaw-workspace

# 3) tarball 자체가 살아있는지 직접 확인 (200 이면 OK)
curl -sIL -o /dev/null -w "%{http_code}\n" \
  https://github.com/GoGoComputer/openclaw-workspace/archive/refs/tags/v0.1.6.tar.gz
```

> 💡 502 / 503 / 504 는 모두 동일한 처방. GitHub 상태는 https://www.githubstatus.com 에서 확인.

#### 502 가 계속될 때 — 개발자용 수동 설치 / Manual install fallback (developer)

GitHub codeload 가 길게 죽었을 때, 또는 brew 의존 없이 바로 쓰고 싶을 때:

**A) git clone 으로 바로 사용 (가장 확실)**

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/openclaw-workspace
cd ~/openclaw-workspace/openclaw-mgr
./openclaw doctor
./openclaw install

# PATH 에 등록하고 싶으면 (선택)
ln -sf "$PWD/openclaw" /usr/local/bin/openclaw    # Intel macOS
# 또는
ln -sf "$PWD/openclaw" /opt/homebrew/bin/openclaw # Apple Silicon
```

> Git 은 codeload 가 아닌 다른 GitHub 엔드포인트를 사용해서 502 영향을 덜 받습니다.

**B) tarball 직접 다운로드 후 brew 로 설치 (formula 만 사용)**

```bash
# 1) tarball 직접 받기
curl -fL -o /tmp/openclaw-v0.1.6.tar.gz \
  https://github.com/GoGoComputer/openclaw-workspace/archive/refs/tags/v0.1.6.tar.gz

# 2) Homebrew 다운로드 캐시에 미리 넣어두기 (brew 가 다시 받지 않게)
mv /tmp/openclaw-v0.1.6.tar.gz \
   "$(brew --cache)/downloads/$(shasum -a 256 < /tmp/openclaw-v0.1.6.tar.gz 2>/dev/null | awk '{print $1}')--openclaw-workspace-0.1.6.tar.gz" 2>/dev/null \
   || cp /tmp/openclaw-v0.1.6.tar.gz "$(brew --cache)/openclaw-workspace--0.1.6.tar.gz"

# 3) 평소처럼 설치 시도
brew install gogocomputer/openclaw/openclaw-workspace
```

**C) tap 없이 Formula 단일 파일로 설치**

```bash
brew install --build-from-source \
  https://raw.githubusercontent.com/GoGoComputer/homebrew-openclaw/main/Formula/openclaw-workspace.rb
```

**D) 특정 커밋(태그) 으로 고정 / Pin to a specific tag**

```bash
git -C ~/openclaw-workspace fetch --tags
git -C ~/openclaw-workspace checkout v0.1.6
~/openclaw-workspace/openclaw-mgr/openclaw doctor
```

### `zsh: unknown file attribute: ^-` 가 다음 줄에 떴다

이전 출력 줄의 글리프(`✘`, `✓`)를 zsh 가 다음 명령의 일부로 잘못 해석한 결과입니다. **무해**하므로 무시하고 다음 명령을 입력하세요.

### 백업 복원 시 `tar: invalid option`

macOS 의 BSD tar 와 GNU tar 차이. 이 도구는 BSD tar 호환 옵션만 사용하지만, 외부 백업이라면 `brew install gnu-tar` 후 `gtar` 로 직접 풀어보세요.

### launchd 스케줄이 안 도는 것 같다

```bash
launchctl list | grep openclaw                    # 등록 확인
cat ~/.openclaw-mgr/logs/update.err.log           # 에러 로그
launchctl print "gui/$(id -u)/com.user.openclaw.update"  # 다음 실행 시각
```

수동으로 한 번 돌려보기:
```bash
launchctl kickstart -p "gui/$(id -u)/com.user.openclaw.update"
```

## 보안 경고가 떴어요

### `위험: compose 파일에 /var/run/docker.sock 마운트가 발견되었습니다`

→ **별도 정밀 가이드: [compose 보안 경고 — `/var/run/docker.sock`](#compose-보안-경고--varrundockersock)** 에서 원인·해결·검증을 자세히 다룹니다.

요약: 호스트 root와 같은 권한이라 절대 허용 불가. 공식 저장소 사용 또는 fork의 compose에서 해당 줄 삭제.

### `WARN: .env is NOT git-ignored`

`.gitignore` 에 `.env` 를 추가하세요. 이미 커밋했다면 그 키를 즉시 회전(rotate)하고 git 히스토리에서 제거(`git filter-repo`).

## 도움 요청 시 첨부할 정보

```bash
./openclaw doctor 2>&1 | tee /tmp/oc-doctor.txt
docker version
sw_vers
uname -a
```

`/tmp/oc-doctor.txt` 의 내용을 [GitHub Issues](https://github.com/GoGoComputer/openclaw-workspace/issues) 에 붙여 등록하세요. 시크릿은 자동 마스킹되지만 한 번 더 검토 부탁드립니다.

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
| [🧠 Ollama 기초](GUIDE-OLLAMA.md) | 로컬 LLM 데몬 사용법 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·웹에서 가져오기 단락 |
| [🌐 웹 정보 가져오기 / surf](GUIDE-WEB-FETCH.md) | 코스피·뉴스·환율·논문 — `surf` 샌드박스 명령 포함 |
| [🎨 크리에이티브 파이프라인](GUIDE-CREATIVE-PIPELINE.md) | Pinterest → 나노바나나(4창) → Figma 자동 배치 |
| [🎬 쇼츠 자동화](GUIDE-SHORTS-PIPELINE.md) | Pinterest → 미리캔버스 → CapCut → 9:16 MP4 |
| [🧠 아키텍처](ARCHITECTURE.md) | 디스패처·멱등 설계·compose override |
| [🤝 기여 가이드 (입문)](GUIDE-CONTRIBUTING.md) | 오타·번역·베타테스트도 환영 |
| [🐙 기여 가이드 (코드)](CONTRIBUTING.md) | 코드 스타일·PR 절차 |
| [📦 릴리스 노트 v0.1.0](RELEASE_NOTES_v0.1.0.md) | 변경 사항 |

⬆️ [README (KO)](../README.md) · [README (EN)](../README.en.md)
<!-- RELATED-DOCS:END -->
