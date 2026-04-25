# 🦞 OpenClaw 입문 가이드 / Beginner Guide

> 🇰🇷 **3분 안에**: OpenClaw 가 뭔지, openclaw-workspace 와 뭐가 다른지, 처음 5분 동안 뭘 하면 되는지.
> 🇬🇧 **In 3 minutes**: what OpenClaw is, how it differs from openclaw-workspace, what to do in your first 5 minutes.

---

## 🇰🇷 한국어

### OpenClaw 가 뭐예요?

[**OpenClaw**](https://clawbro.ai) = **"내 컴퓨터 안에서 도는 코딩 비서 AI 에이전트"** (오픈소스).

비유: ChatGPT 처럼 채팅으로 질문하면, OpenClaw 는 그냥 답만 하는 게 아니라 **실제로 셸 명령을 실행하고 파일을 만들고 코드를 고칩니다.** Cursor / Claude Code 같은 IDE 에이전트와 비슷하지만 백엔드를 자기 컴퓨터에 호스팅한다는 차이.

```
[사용자]  "이 폴더에 있는 파이썬 파일들 PEP8 로 정리해줘"
   │
   ▼
[OpenClaw]  ─▶ ollama / OpenAI 호출 → 계획 세움
            ─▶ 셸에서 black/ruff 실행
            ─▶ 결과를 사용자에게 보고
```

### "OpenClaw" vs "openclaw-workspace" — 뭐가 달라요?

이건 처음에 다들 헷갈리는 부분입니다.

| 이름 | 누가 만듦 | 역할 |
|---|---|---|
| **OpenClaw** | OpenClaw 팀 | AI 에이전트 본체 (Python, 웹UI). 저장소: `github.com/openclaw/openclaw` |
| **openclaw-workspace** (이 저장소) | GoGoComputer | OpenClaw 를 **macOS 에서 한 줄로 설치·관리·보안하드닝** 하는 래퍼 |

비유:
- OpenClaw = 자동차
- openclaw-workspace = "자동차 공장에서 차 꺼내고, 보험 들어주고, 매주 세차해주는 컨시어지"

**여러분이 직접 OpenClaw 코드를 고치진 않을 가능성이 큼**. 대부분의 사용자는 `openclaw install` 만 하면 OpenClaw 가 컨테이너에서 알아서 동작합니다.

### 처음 5분 동안 할 일

```bash
# 1) 설치 (한 줄)
curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash

# 2) 시스템 점검
openclaw doctor

# 3) Docker · Ollama · OpenClaw 컨테이너까지 한 번에
openclaw install

# 4) 브라우저로 접속
open http://127.0.0.1:8000
```

이게 다입니다. 모르는 단어가 나오면:
- 🦙 Ollama → [GUIDE-OLLAMA.md](GUIDE-OLLAMA.md)
- 🐳 Docker → [GUIDE-DOCKER.md](GUIDE-DOCKER.md)

### OpenClaw 는 내 컴퓨터에 뭘 남기나요?

```
~/openclaw/                  # OpenClaw 소스코드 (git clone)
~/.openclaw-mgr/             # 이 도구의 상태·로그·.env (Homebrew 설치 시)
~/openclaw-backups/          # backup 명령 결과
~/.ollama/models/            # Ollama 모델 파일 (수 GB)
Docker Volumes               # OpenClaw 의 세션·DB (영구 데이터)
```

전부 지우려면: `openclaw uninstall --purge` (Docker / Ollama 까지 제거).

### 모드 정리 — "내가 어떤 모드에서 쓰고 있지?"

| 질문 | 답 |
|---|---|
| 내가 OpenClaw 코드를 고치고 싶다 | `git clone openclaw/openclaw` 직접 + 컨테이너 마운트로 dev 모드. 이 가이드 범위 밖 |
| 그냥 OpenClaw 를 잘 쓰고 싶다 (대부분) | `openclaw install` → 끝. `openclaw self-update` 로 갱신 |
| 한국 모델 (EXAONE/Solar) 쓰고 싶다 | `openclaw models add exaone3.5:7.8b solar-pro:22b` |
| 회사 보안상 외부 통신 다 막고 싶다 | 기본 `isolated` 그대로. 모델 다운 시만 `network online` |

### "OpenClaw 가 내 파일을 망가뜨리지 않나요?"

기본 설정에서:
- 컨테이너 루트는 `read_only` → 컨테이너 안의 시스템 파일도 못 고침
- 호스트의 `~/Documents`, `~/.ssh` 등은 **마운트 안 됨** → 접근 자체가 불가
- `isolated` 모드 → 외부에 데이터 못 보냄
- 작업할 폴더를 명시적으로 마운트해야 OpenClaw 가 그 폴더만 만질 수 있음

자세히는 메인 README 의 [🔒 보안 주의](../README.md#-보안-주의-꼭-읽으세요) 참조.

### 일상 사용 명령 5개

| 언제 | 명령 |
|---|---|
| 매일 아침 | (자동 — `openclaw schedule enable` 해두면 새벽 3시에 자동 update) |
| 새 모델 추가 | `openclaw models add <이름>` |
| 컨테이너 정지 | `openclaw stop` |
| 다시 켜기 | `openclaw start` |
| 디스크가 꽉 참 | `openclaw clean` |

### 다음에 읽을 것
- [README](../README.md) — 명령 카탈로그·`.env`·FAQ
- [QUICKSTART-ko](QUICKSTART-ko.md) — 단계별 예시 출력
- [TROUBLESHOOTING](TROUBLESHOOTING.md) — 흔한 에러
- [ARCHITECTURE](ARCHITECTURE.md) — 내부 동작

---

## 🇬🇧 English

### What is OpenClaw?

[**OpenClaw**](https://clawbro.ai) = **"an open-source coding-assistant AI agent that runs on your own computer."**

Like ChatGPT, but instead of just answering, OpenClaw **actually runs shell commands, creates files, and edits code.** Similar in spirit to Cursor / Claude Code, but you self-host the backend.

```
[user]  "tidy every Python file in this folder to PEP8"
   │
   ▼
[OpenClaw] ─▶ calls Ollama / OpenAI → plans
           ─▶ runs black/ruff in the shell
           ─▶ reports back
```

### "OpenClaw" vs "openclaw-workspace" — what's the difference?

This trips up everyone at first.

| Name | Maintainer | Role |
|---|---|---|
| **OpenClaw** | OpenClaw team | The AI agent itself (Python, web UI). Repo: `github.com/openclaw/openclaw` |
| **openclaw-workspace** (this repo) | GoGoComputer | A macOS wrapper that **installs, manages, and security-hardens OpenClaw with one command** |

Analogy:
- OpenClaw = the car
- openclaw-workspace = "the concierge service that delivers it from the factory, insures it, and washes it every week"

**Most users will never edit OpenClaw's code directly.** Just run `openclaw install` and OpenClaw runs in a container by itself.

### Your first 5 minutes

```bash
# 1) install (one line)
curl -fsSL https://raw.githubusercontent.com/GoGoComputer/openclaw-workspace/main/scripts/install.sh | bash

# 2) check the system
openclaw doctor

# 3) Docker, Ollama, OpenClaw container — all in one step
openclaw install

# 4) open in your browser
open http://127.0.0.1:8000
```

That's it. If you hit unfamiliar terms:
- 🦙 Ollama → [GUIDE-OLLAMA.md](GUIDE-OLLAMA.md)
- 🐳 Docker → [GUIDE-DOCKER.md](GUIDE-DOCKER.md)

### What does OpenClaw leave on my computer?

```
~/openclaw/                  # OpenClaw source (git clone)
~/.openclaw-mgr/             # this tool's state, logs, .env (Homebrew install)
~/openclaw-backups/          # output of `openclaw backup`
~/.ollama/models/            # Ollama model files (several GB)
Docker Volumes               # OpenClaw sessions / DB (persistent data)
```

To wipe everything: `openclaw uninstall --purge` (also removes Docker / Ollama).

### Which mode am I in?

| Question | Answer |
|---|---|
| I want to modify OpenClaw's code | Clone `openclaw/openclaw` directly and mount it as a dev volume. Out of scope here |
| I just want to use OpenClaw well (most users) | `openclaw install` → done. Update with `openclaw self-update` |
| I want to use Korean models (EXAONE/Solar) | `openclaw models add exaone3.5:7.8b solar-pro:22b` |
| Corporate policy blocks all outbound | Stay on the default `isolated` mode. Use `network online` only when pulling models |

### "Will OpenClaw mess up my files?"

By default:
- Container rootfs is `read_only` → can't even modify the container's own system files
- Your host's `~/Documents`, `~/.ssh`, etc. are **not mounted** → genuinely unreachable
- `isolated` mode → no outbound network, no exfiltration
- You must explicitly mount any folder you want OpenClaw to touch

Details: see the main README's [🔒 Security section](../README.en.md#-security-please-read).

### Five everyday commands

| When | Command |
|---|---|
| Every morning | (automatic — `openclaw schedule enable` runs `update` at 3 AM) |
| Add a new model | `openclaw models add <name>` |
| Stop the container | `openclaw stop` |
| Start it again | `openclaw start` |
| Disk getting full | `openclaw clean` |

### What to read next
- [README (EN)](../README.en.md) — command catalog, `.env`, FAQ
- [QUICKSTART-en](QUICKSTART-en.md) — step-by-step with example output
- [TROUBLESHOOTING](TROUBLESHOOTING.md) — common errors
- [ARCHITECTURE](ARCHITECTURE.md) — how it works inside
