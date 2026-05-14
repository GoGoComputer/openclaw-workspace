# 🎉 설치 후 첫 사용 가이드 / First-time Use After Install

> 🇰🇷 `./openclaw install` 가 `✓ 설치 완료!` 를 출력한 직후부터 **5분 안에 첫 대화** 까지.
> 🇬🇧 From the moment `./openclaw install` prints `✓ install complete` to **your first conversation in 5 minutes**.

이 문서가 필요한 사람:
- ✅ 설치는 끝났는데 **"이제 어디에 무엇을 치는지"** 막막한 분
- 🌐 브라우저로 열어야 하나 / 터미널에 쳐야 하나 헷갈리는 분
- 🤖 어떤 모델로 첫 질문을 해야 좋은지 모르는 분
- 📂 만들어진 파일이 **내 맥북 어디로** 가는지 궁금한 분

설치 자체가 안 된 분은 [README](../README.md) → [GUIDE-OPENCLAW](GUIDE-OPENCLAW.md) → 막히면 [TROUBLESHOOTING](TROUBLESHOOTING.md).

---

## 📖 목차 / Contents

| 단계 | 내용 | 시간 |
|---|---|---|
| [① 살아있는지 확인](#-1단계--살아있는지-확인-30초) | health · 컨테이너 상태 | 30초 |
| [② 첫 대화 (3가지 방식)](#-2단계--첫-대화-3가지-방식) | UI / CLI 컨테이너 / `openclaw` 메뉴 | 1~2분 |
| [③ 모델 선택 / 추가](#-3단계--모델-선택--추가) | Ollama 모델 보기·추가·전환 | 1분 |
| [④ 작업 파일은 어디?](#-4단계--작업-파일은-어디) | 호스트 ↔ 컨테이너 마운트 | 30초 |
| [⑤ 일상 운영](#-5단계--일상-운영-매일-하는-동작) | 시작·정지·로그·재시작 | — |
| [⑥ 웹에서 정보 가져오기](#-6단계--웹에서-정보-가져오기-online-모드-잠깐-열기) | network online ↔ isolated | — |
| [⑦ 자주 막히는 부분](#-7단계--자주-막히는-부분-postinstall-체크리스트) | 첫 사용 트러블슈팅 | — |
| [🇬🇧 English mirror](#-english) | 영어 거울 | — |

> 🎯 **권장 진입점**:
> - 처음이면 ① → ② → ③ 순서로
> - 며칠 째 쓰는 중이면 ⑤·⑥
> - 막히면 ⑦ → [TROUBLESHOOTING](TROUBLESHOOTING.md)

---

## ✅ 1단계 — 살아있는지 확인 (30초)

설치 끝난 직후 가장 먼저:

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

**기대 출력 — 모두 `✓` 면 OK**:
```
✓ Docker Desktop daemon
✓ Ollama daemon
✓ openclaw containers running
✓ network mode: isolated
✓ sandbox: ON
```

`✗` 가 하나라도 나오면 그 항목의 안내대로:
- `Docker daemon` ✗ → `open -a Docker` 후 30~60초 대기, 다시 `./openclaw doctor`
- `containers running` ✗ → `./openclaw start`
- 그 외 → [TROUBLESHOOTING](TROUBLESHOOTING.md) 의 동일 항목

**컨테이너만 빠르게 보고 싶으면**:
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep openclaw
```

기대 출력 (이름·포트는 환경 따라 다를 수 있음):
```
openclaw-openclaw-gateway-1   Up 2 minutes   127.0.0.1:18789->18789/tcp
openclaw-openclaw-cli-1       Up 2 minutes
```

---

## 💬 2단계 — 첫 대화 (3가지 방식)

OpenClaw 와 대화하는 방법은 3가지. **처음이면 방식 B (컨테이너 CLI) 가 가장 직관적**입니다.

### 방식 A — 브라우저 UI

**터미널에서 한 줄로**:
```bash
open http://127.0.0.1:18789
```

**또는 Safari/Chrome 주소창에 직접 입력** (`open ` 은 빼고 URL 만):
```
http://127.0.0.1:18789
```

> ⚠ **자주 하는 실수** — `open http://127.0.0.1:18789` **전체 문장**을 그대로 Safari 주소창에 붙여넣으면 Google 검색으로 빠집니다 ("open http%3A%2F%2F..."). `open` 은 macOS 터미널 명령어 — 터미널 창에서만 통합니다. 브라우저 주소창에는 `http://127.0.0.1:18789` 만 입력하세요.

| 응답 | 의미 | 다음 |
|---|---|---|
| 채팅 화면이 뜸 | ✓ 사용 가능 — 입력창에 질문 입력 | 아래 "첫 프롬프트 예시" |
| `Safari can't connect` / `Cannot connect` | 18789 포트가 안 열림 | 7단계 "`Empty reply` / `Can't connect`" 행 참고 |
| `Empty reply from server` | gateway 컨테이너는 떴지만 부팅 중 | 30~60초 대기 후 새로고침. 1분 넘으면 `./openclaw logs gateway` |
| `404` / JSON 만 보임 | OpenClaw 버전이 UI 미내장 (헤드리스) | 방식 B 로 전환 |

> 💡 OpenClaw 본체 버전에 따라 UI 가 내장되어 있을 수도, API 만 있을 수도 있습니다. UI 가 없으면 방식 B 를 쓰세요.

### 방식 B — 컨테이너 안 CLI (본체 OpenClaw 풀 기능)

**첫 설정은 `./openclaw setup` 한 줄.** OpenClaw 의 `onboard` 마법사를 Docker 안에서 안전하게 돌리는 래퍼입니다. 멱등 — 언제든 다시 실행해도 안전.

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

# 1) 첫 설정 (또는 재설정)
./openclaw setup
# → 14단계 마법사 (보안 동의 → flow → mode → gateway 바인드/포트/인증 →
#    daemon 설치 → provider 선택 [ollama 추천] → workspace → search →
#    skills → UI → tailscale → health check) 가 컨테이너 안에서 진행
# → 결과는 ~/.openclaw/openclaw.json 에 저장
# → 중간 Ctrl+C 안전, 답하기 싫은 항목은 Enter 로 기본값 유지
# → 각 단계 권장 답안 표:  README.md '마법사가 차례로 묻는 단계' 펼치기 섹션

# 2) 설정 확인 (변경 없음)
./openclaw setup status

# 3) 이후 채팅
cd ~/DEV/openclaw
docker compose run --rm openclaw-cli tui                          # 터미널 UI 채팅
docker compose run --rm openclaw-cli agent --message "안녕"   # 한 줄 명령
```

> ⚠️ `openclaw-cli` 컨테이너는 entrypoint 가 `node dist/index.js` 라서 인자 없이 뜨면 help 출력 후 **즉시 종료**합니다 (`docker ps -a` 에서 `Exited (1)`). 그래서 `docker compose exec openclaw-cli bash` 는 항상 실패. 매번 새 일회용 컨테이너를 띄우는 **`docker compose run --rm`** 이 올바른 패턴이고, `./openclaw setup` 이 이걸 내부적으로 처리합니다.

**컨테이너 안 셸이 필요하면** (드물게):
```bash
cd ~/DEV/openclaw
docker compose run --rm --entrypoint bash openclaw-cli
# 셸 안에서: openclaw <subcommand>  (예: openclaw tui)
```

**첫 프롬프트 예시** (`tui` 안에서):
```
안녕. 너는 어떤 모델이야?
~/.openclaw/workspace 안에 hello.py 라는 파일을 만들고 "Hello from OpenClaw" 를 출력하게 해줘
방금 만든 파일을 실행해서 결과를 보여줘
```

빠져나오기: `Ctrl+D` 또는 `/exit` (TUI 안에서). `run --rm` 이라 종료 시 컨테이너 자동 삭제 — 다음에 또 `docker compose run --rm openclaw-cli tui` 로 띄우면 됩니다.

> 🔒 컨테이너 안에서 일어나는 모든 일은 격리 — 호스트 (`~/Documents`, `~/.ssh` 등) 에는 접근 불가. 파일을 호스트와 공유하려면 `~/.openclaw/workspace` (컨테이너 안) 에 만드세요 (호스트의 `~/DEV/openclawAgent` 와 자동 동기화).

### 방식 C — `./openclaw` 대화형 메뉴

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw
```

한국어/영어 메뉴가 뜹니다. 숫자만 누르면 됩니다 — 진단·시작·정지·로그·업데이트가 한 화면에. **터미널이 익숙하지 않은 분에게 권장**.

---

## 🤖 3단계 — 모델 선택 / 추가

설치 직후엔 `.env` 의 기본 모델이 사용됩니다. 다른 모델을 쓰려면:

### 지금 깔린 모델 보기
```bash
ollama list
# NAME                   ID            SIZE    MODIFIED
# qwen2.5-coder:7b       abc1234...    4.7 GB  방금 전
```

### 새 모델 추가 (M5 Pro 24GB 권장)

| 용도 | 추천 모델 | 명령 |
|---|---|---|
| 코딩 (가성비 최고) | `qwen2.5-coder:7b` | `./openclaw models add qwen2.5-coder:7b` |
| 일반 채팅 (빠름) | `llama3.2:3b` | `./openclaw models add llama3.2:3b` |
| 한국어 강함 | `exaone3.5:7.8b` | `./openclaw models add exaone3.5:7.8b` |
| 무거운 추론 | `qwen2.5:14b` | `./openclaw models add qwen2.5:14b` |

> ⚠️ 24GB RAM 에서는 **14B 까지가 실용**. 30B 이상은 스왑 발생으로 매우 느려짐.

### 사용 모델 전환
```bash
# .env 편집 (또는 ./openclaw models default <이름>)
nano ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr/.env
# OLLAMA_MODEL="qwen2.5-coder:7b" 줄 수정 후 저장

./openclaw start          # 컨테이너 재기동 (변경 반영)
```

자세한 모델 관리 (REST API, 임베딩, 양자화 비교) → [GUIDE-MANUAL-INSTALL.md § 3단계](GUIDE-MANUAL-INSTALL.md#3단계--ollama-설치-로컬-llm--m5-pro-gpu-가속-활용)

---

## 📂 4단계 — 작업 파일은 어디?

```
컨테이너 안                          ←→  호스트 (Finder 에서 보임)
/home/node/.openclaw/workspace      ←→  ~/DEV/openclawAgent
/home/node/.openclaw                ←→  ~/.openclaw  (설정·세션·토큰 — 직접 편집 X)
```

### 확인하기
```bash
# 컨테이너에서 파일 만들기 (cli 컨테이너가 죽어 있으므로 exec 가 아니라 run --rm)
docker compose run --rm --entrypoint sh openclaw-cli -c 'echo "test" > /home/node/.openclaw/workspace/hello.txt'

# 호스트에서 즉시 보임
ls ~/DEV/openclawAgent/hello.txt
cat ~/DEV/openclawAgent/hello.txt
# test

# Finder 에서도 즉시 보임
open ~/DEV/openclawAgent
```

> 🔒 **컨테이너는 `~/.openclaw/workspace` 밖으로 못 나갑니다** — 에이전트가 `~/Desktop` 이나 `~/Documents` 를 건드릴 수 없도록 마운트 자체가 안 되어 있습니다. 추가 폴더를 공유하고 싶으면 `~/DEV/openclawAgent` 안에 심볼릭 링크나 하위 폴더를 만드세요.

---

## 🔁 5단계 — 일상 운영 (매일 하는 동작)

| 동작 | 명령 | 비고 |
|---|---|---|
| 시작 | `./openclaw start` | 컨테이너 기동. Docker Desktop 이 켜져 있어야 함 |
| 정지 (잠깐) | `./openclaw stop` | 데이터 보존. 다시 `start` 로 복귀 |
| 상태 확인 | `./openclaw doctor` | ✓/✗ 한 화면 |
| 로그 보기 | `./openclaw logs` | 전체. `./openclaw logs gateway` 등 서비스별도 |
| 업데이트 | `./openclaw update` | 본체 + 이미지 갱신. **online 모드 필요** (아래 6단계) |
| 자기 자신 업데이트 | `./openclaw self-update` | 워크스페이스 (이 레포) git pull |
| 자동 업데이트 켜기 | `./openclaw schedule enable` | 매일 새벽 3시 |
| 백업 / 복구 | `./openclaw backup` / `./openclaw restore` | `~/openclaw-backups/` 에 저장 |
| 디스크 정리 | `./openclaw clean` | 오래된 이미지·로그·캐시 |

### Docker Desktop 까지 자동으로 켜고 끄기 (선택)
```bash
# 켜기 — Docker 자동 기동까지 포함
./openclaw start

# 컴퓨터 끌 때 (Docker 도 정리)
./openclaw stop
dockerstop                   # 6.5단계에서 등록한 alias — Docker Desktop 까지 완전 종료
```

---

## 🌐 6단계 — 웹에서 정보 가져오기 (`online` 모드 잠깐 열기)

기본 모드는 `isolated` (외부 인터넷 차단). 뉴스·주가·외부 API 가 필요할 때만 잠깐 엽니다.

```bash
# 1) 잠깐 열기
./openclaw network online --restart

# 2) UI 또는 CLI 에서 자유롭게:
#    "오늘 코스피 종가 알려줘"
#    "한겨레 1면 헤드라인 요약"
#    "https://example.com 의 메타 태그 보여줘"

# 3) 끝나면 바로 잠그기 (습관화)
./openclaw network isolated --restart
```

> 📖 실전 프롬프트 템플릿·자동화 흐름 → [GUIDE-WEB-FETCH](GUIDE-WEB-FETCH.md)

`online` 모드여도 **여전히 보호되는 것**:
- ✅ 호스트 파일 시스템 접근 차단 (마운트 자체 없음)
- ✅ `~/.ssh`, `~/Documents` 등 접근 차단
- ✅ 컨테이너 루트 파일시스템 read-only
- ✅ 권한 상승 (sudo 류) 차단
- ✅ LAN 다른 기기에서 접근 차단 (`127.0.0.1` 만)
- ⚠ **임의 외부 서버 호출 허용** (online 의 본질)
- ⚠ **프롬프트 인젝션으로 데이터 외부 전송 이론상 가능** — 끝나면 즉시 isolated

---

## ❓ 7단계 — 자주 막히는 부분 (post-install 체크리스트)

| 증상 | 즉석 점검 | 해결 |
|---|---|---|
| Safari 주소창에 `open http://...` 가 그대로 들어감 → Google 검색으로 빠짐 | 주소창 내용 확인 | `open ` 제거하고 `http://127.0.0.1:18789` 만 입력 (`open` 은 터미널 명령어) |
| `Safari can't connect to 127.0.0.1` / `curl: (7) Failed to connect` | `docker ps \| grep gateway` 에 `Restarting` 보임 | gateway 가 크래시 루프 — `./openclaw logs gateway` 로 사유 확인. `Missing config. Run \`openclaw setup\`` 가 보이면 이 워크스페이스를 최신으로 (`./openclaw self-update`) 후 `./openclaw stop && ./openclaw start` 다시 |
| `Empty reply from server` (포트는 열렸는데 응답 없음) | 30~60초 더 대기 | gateway 가 첫 부팅 중. 1분이 넘는데도 그대로면 `./openclaw logs gateway` 에 `starting...` 만 반복 — 본체 버그일 수 있으니 `./openclaw network online --restart && ./openclaw update` |
| `./openclaw start` → `OpenClaw 가 설치돼 있지 않습니다` (그런데 `~/DEV/openclaw` 가 있음) | `grep OPENCLAW_DIR openclaw-mgr/.env` | `.env` 가 옛날 스키마. 한 줄로 고치기:  `sed -i '' 's\|^OPENCLAW_DIR=.*\|OPENCLAW_DIR="$HOME/DEV/openclaw"\|' openclaw-mgr/.env` |
| `failed to bind host port 127.0.0.1:18789/tcp: address already in use` | `lsof -nP -iTCP:18789` (아무것도 안 보이면 Docker 내부) | `./openclaw stop && docker rm -f openclaw-openclaw-gateway-1 openclaw-openclaw-cli-1 && ./openclaw start` (좀비 포워더 정리) |
| `docker compose exec` → `service "openclaw-cli" is not running` | `docker ps \| grep openclaw` | `./openclaw start` 후 재시도 |
| CLI 안에서 `claude` → `command not found` | 컨테이너 이미지 버전 체크 | `./openclaw update` (online 모드) |
| 모델 응답이 없음 / 매우 느림 | `ollama list` · `ollama ps` | (a) Ollama 데몬 OFF → `open -a Ollama` (b) 모델 미설치 → `ollama pull <모델>` (c) 24GB 에서 14B 초과 → 더 작은 모델로 |
| 첫 응답이 30초 넘게 걸림 | 정상 — 모델 메모리 로드 중 | 두 번째 질문부터는 즉시 응답 |
| 파일을 만들었는데 Finder 에 안 보임 | `/workspace` 에 만들었는지 확인 | `/tmp` 등에 만들면 호스트에 안 동기화 — `/workspace` 안으로 이동 |
| `./openclaw update` → 네트워크 에러 | 현재 네트워크 모드 확인 | `./openclaw network online --restart` 후 재시도 |
| 매번 Docker 켜는 게 귀찮음 | Docker Desktop Settings | "Start Docker Desktop when you sign in" ✓ |

더 자세한 트러블슈팅 → [TROUBLESHOOTING](TROUBLESHOOTING.md)

---

## 🔗 다음에 읽을 것

- [README](../README.md) — 명령 카탈로그 · 자동화 3종 (surf / creative / shorts)
- [GUIDE-OPENCLAW](GUIDE-OPENCLAW.md) — OpenClaw 본체와 워크스페이스 분리 이해
- [GUIDE-WEB-FETCH](GUIDE-WEB-FETCH.md) — 웹 검색·뉴스 수집 실전
- [GUIDE-CREATIVE-PIPELINE](GUIDE-CREATIVE-PIPELINE.md) — 이미지 / 디자인 자동화
- [GUIDE-SHORTS-PIPELINE](GUIDE-SHORTS-PIPELINE.md) — 숏폼 영상 자동화
- [TROUBLESHOOTING](TROUBLESHOOTING.md) — 에러 메시지별 대응

---

## 🇬🇧 English

> From the `✓ install complete` banner to your first conversation — in five minutes.

### ✅ Step 1 — Verify it's alive (30 sec)

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw doctor
```

All `✓` = ready. Any `✗` → follow the inline hint or [TROUBLESHOOTING](TROUBLESHOOTING.md).

Quick container check:
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep openclaw
```

### 💬 Step 2 — Your first conversation (3 ways)

**Option A — Browser UI**
```bash
# Right after install the network is in 'isolated' — port publishing is off.
./openclaw network online --restart
open http://127.0.0.1:18789
```
If the page is empty / black / "Safari Can't Connect" → this OpenClaw build's web UI is admin-only (Control Panel) and the chat lives in the CLI. Use Option B.

**Option B — In-container CLI (full OpenClaw stack)**

The first-time setup is one command — `./openclaw setup` wraps OpenClaw's `onboard` wizard and runs it inside an isolated container. Re-runnable anytime.

```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr

# 1) First time (or any time you want to re-configure)
./openclaw setup
# → 14-step wizard (risk acknowledgment → flow → mode → gateway
#    bind/port/auth → daemon → provider [pick `ollama` for local
#    models] → workspace → search → skills → UI → tailscale → health)
#    runs inside the container.
# → Settings persist to ~/.openclaw/openclaw.json
# → Ctrl+C is safe; Enter keeps any existing answer
# → Recommended answer for each step: README.md "What the wizard asks"
#   collapsible section

# 2) Inspect current configuration (read-only)
./openclaw setup status

# 3) Then chat
cd ~/DEV/openclaw
docker compose run --rm openclaw-cli tui                          # terminal UI chat
docker compose run --rm openclaw-cli agent --message "hi"   # one-shot
```

> ⚠️ Use `run --rm`, not `exec`. The `openclaw-cli` container's entrypoint (`node dist/index.js`) prints help and exits when invoked with no args (`docker ps -a` shows it as `Exited (1)`). `./openclaw setup` handles this internally; for direct invocations always use `docker compose run --rm openclaw-cli <subcommand>`.

**Option C — Terminal REPL chat (skip OpenClaw entirely)**
```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw chat                          # interactive model picker + auto personality
```
Talks directly to host Ollama. The picker shows your installed models numbered — Enter for the default, or pick a number. Auto-loads workspace personality files (`IDENTITY.md` / `SOUL.md` / `USER.md`). No OpenClaw onboard required, no API key.

**Option D — `./openclaw` interactive menu**
```bash
cd ~/DEV/openclawAgent/openclaw-workspace/openclaw-mgr
./openclaw
```

### 🤖 Step 3 — Pick / add a model

```bash
ollama list                                       # see installed models
./openclaw models add qwen2.5-coder:7b            # add a new one (best for coding on M-series, 24 GB)
# Edit OLLAMA_MODEL in openclaw-mgr/.env, then:
./openclaw start                                  # restart to apply
```

24 GB RAM sweet spot: **3B–14B**. 30 B+ swaps and gets very slow.

### 📂 Step 4 — Where do files live?

```
container         ←→  host (visible in Finder)
/workspace        ←→  ~/DEV/openclawAgent
/home/node/.openclaw ←→  ~/.openclaw  (config & sessions — don't edit by hand)
```

The container **cannot escape `/workspace`** — `~/Desktop`, `~/.ssh`, `~/Documents` are not mounted at all.

### 🔁 Step 5 — Daily ops

| Action | Command |
|---|---|
| start / stop | `./openclaw start` / `./openclaw stop` |
| status | `./openclaw doctor` |
| logs | `./openclaw logs` (or `./openclaw logs gateway`) |
| update | `./openclaw update` (needs online mode) |
| auto-update | `./openclaw schedule enable` |
| backup / restore | `./openclaw backup` / `./openclaw restore` |
| disk cleanup | `./openclaw clean` |

### 🌐 Step 6 — Fetch web data (open `online` briefly)

```bash
./openclaw network online --restart       # 1) open
# ... ask your prompts about news / stocks / external sites
./openclaw network isolated --restart     # 2) close — make this a habit
```

Even in `online` mode: host filesystem isolation, read-only container root, no `sudo`, `127.0.0.1`-only — all stay in effect. Only outbound HTTP is allowed. Details: [GUIDE-WEB-FETCH](GUIDE-WEB-FETCH.md).

### ❓ Step 7 — Common first-use issues

| Symptom | Fix |
|---|---|
| Empty page at `:18789` | Wait 30 s for gateway boot, then `./openclaw logs gateway` |
| `service ... is not running` | `./openclaw start` |
| `claude: command not found` in container | `./openclaw update` (online mode) |
| First reply takes 30 s+ | Normal — model is loading into RAM. Subsequent replies are instant |
| File not appearing in Finder | Make sure you wrote it under `/workspace`, not `/tmp` |
| `update` fails with network error | `./openclaw network online --restart` first |

### 🔗 Read next
- [README](../README.en.md) · [GUIDE-OPENCLAW](GUIDE-OPENCLAW.md) · [GUIDE-WEB-FETCH](GUIDE-WEB-FETCH.md) · [TROUBLESHOOTING](TROUBLESHOOTING.md)
