# 🐳 Docker 입문 가이드 / Beginner Guide

> 🇰🇷 **3분 안에**: Docker 가 뭔지, 왜 OpenClaw 를 컨테이너에 넣어 돌리는지, 어디까지 안전한지.
> 🇬🇧 **In 3 minutes**: what Docker is, why OpenClaw runs in a container, what it can and can't reach.

## 📖 목차 / Contents

- [🇰🇷 한국어](#-한국어)
- [🇬🇧 English](#-english)

---

## 🇰🇷 한국어

### Docker 가 뭐예요?

**Docker = "프로그램을 작은 가상 박스 (컨테이너) 안에 넣어 돌리는 도구"** 입니다.

비유: 맥북 안에 작은 가상의 리눅스 한 대를 띄워 그 안에서만 프로그램이 동작하게 만듭니다. 박스 밖 (여러분의 진짜 파일·앱) 은 건드리지 못합니다.

```
[맥북 macOS]
 ├─ 사진, 문서, 브라우저… (호스트 — Docker 가 못 건드림)
 ├─ 🐳 Docker Desktop
 │   └─ [컨테이너] OpenClaw
 │       └─ 자기 안의 파일시스템만 건드림
```

### 왜 OpenClaw 를 컨테이너에 넣나요?

OpenClaw 는 셸 명령을 실행하고 파일을 만지는 **강력한 AI 에이전트** 입니다. 호스트에 직접 깔면:

- 실수로 `rm -rf ~` 같은 명령이 돌면 진짜 사진·문서가 삭제됨 ❌
- 악성 패키지가 들어오면 SSH 키·브라우저 쿠키 다 노출 ❌

**컨테이너에 가두면**:
- 컨테이너 안의 파일시스템만 만질 수 있음 ✓
- 컨테이너를 지우면 끝 (호스트는 그대로) ✓
- 추가로 OpenClaw 설정은 컨테이너 root 도 read-only ✓
- 추가로 네트워크도 기본 차단 (`isolated` 모드) ✓

### Docker Desktop 이란?

맥에서 Docker 를 쓰려면 필요한 앱. **`openclaw install` 이 자동으로 설치합니다** (`brew install --cask docker`). 처음 켤 때 약관 동의 한 번만 해주면 됩니다.

확인:
```bash
docker --version             # docker version 출력되면 OK
docker ps                    # 지금 돌고 있는 컨테이너 목록
```

### 핵심 용어 4개만

| 용어 | 뜻 | 비유 |
|---|---|---|
| **이미지 (Image)** | 컨테이너의 "설계도" 또는 "스냅샷" | OS 설치 ISO 파일 |
| **컨테이너 (Container)** | 이미지를 실제로 띄운 "실행 인스턴스" | ISO 로 깐 가상 머신 |
| **볼륨 (Volume)** | 컨테이너가 지워져도 살아남는 "외장 디스크" | USB 메모리 |
| **compose** | 여러 컨테이너를 한꺼번에 정의·기동하는 YAML | 음식 레시피 |

OpenClaw 는 이미지를 받아 컨테이너를 띄우고, 데이터를 볼륨에 저장합니다. 그래서 컨테이너를 지우고 다시 만들어도 데이터는 그대로.

### 자주 쓰는 명령

```bash
docker ps                    # 실행 중인 컨테이너
docker ps -a                 # 정지된 것까지 전부
docker images                # 받아둔 이미지 목록
docker logs <컨테이너이름>    # 로그 보기
docker stats                 # CPU/메모리 사용량 실시간
docker volume ls             # 볼륨 목록 (데이터)
docker system df             # Docker 가 디스크 얼마 쓰는지
```

OpenClaw 가 한 줄로 감싼 것:

```bash
openclaw start               # 컨테이너 시작
openclaw stop                # 정지 (데이터 보존)
openclaw logs                # docker logs + 시크릿 마스킹
openclaw clean --status      # docker system df + ollama 디스크 사용량
openclaw clean --all         # 미사용 이미지·캐시 청소
```

### "포트 (Port)" 는 뭐예요?

컨테이너가 외부와 대화하는 "창구 번호". OpenClaw 의 웹UI 는 포트 `8000` 으로 노출되며, **항상 `127.0.0.1` 만** 바인딩됩니다 (LAN 의 다른 사람은 접속 못 함).

```
브라우저 (http://127.0.0.1:8000)  ─▶  Docker  ─▶  OpenClaw 컨테이너 :8000
```

### 보안 하드닝 (이 프로젝트가 추가로 하는 것)

`compose.security.yml` override 가 자동으로 적용:

| 옵션 | 효과 |
|---|---|
| `read_only: true` | 컨테이너 루트 파일시스템 쓰기 금지 |
| `cap_drop: [ALL]` | 모든 리눅스 capability 제거 |
| `tmpfs: /tmp` | 임시 파일은 RAM 에만, 재시작 시 사라짐 |
| `127.0.0.1` 만 바인딩 | LAN 노출 차단 |
| `no-new-privileges: true` | sudo 류 권한 상승 차단 |

### 디스크가 부족할 때

```bash
openclaw clean --status      # Docker / Ollama / 백업 사용량 한눈에
openclaw clean               # 단계별 y/n 안내 (안전)
docker system prune -a       # 직접 청소 (이미지 전부 삭제 — 주의)
```

### 더 알아보기
- 공식: https://www.docker.com
- compose 설명서: https://docs.docker.com/compose
- 보안 모델 자세히: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🇬🇧 English

### What is Docker?

**Docker = "tool for running programs inside small virtual boxes (containers)."**

Analogy: a tiny virtual Linux machine inside your Mac. Programs only see what's in their own box; they can't touch your real files or apps.

```
[your Mac (macOS)]
 ├─ Photos, documents, browser… (host — Docker can't reach this)
 ├─ 🐳 Docker Desktop
 │   └─ [container] OpenClaw
 │       └─ only sees its own filesystem
```

### Why run OpenClaw in a container?

OpenClaw is a **powerful AI agent** that executes shell commands and edits files. If installed directly on the host:

- A stray `rm -rf ~` would wipe your real photos and documents ❌
- A malicious package could exfiltrate your SSH keys or browser cookies ❌

**Inside a container**:
- It only sees the container's own filesystem ✓
- Delete the container — host is untouched ✓
- This project also sets the container's rootfs to read-only ✓
- And by default the container has **no outbound network** (`isolated`) ✓

### What is Docker Desktop?

The macOS app that lets you run Docker. **`openclaw install` installs it for you** (`brew install --cask docker`). On first launch you accept the terms of service once.

Verify:
```bash
docker --version
docker ps                    # currently-running containers
```

### Four terms to know

| Term | Meaning | Analogy |
|---|---|---|
| **Image** | A container "blueprint" / snapshot | OS install ISO |
| **Container** | A running instance of an image | a VM you booted from the ISO |
| **Volume** | A persistent "external disk" that survives container deletion | USB stick |
| **Compose** | A YAML file that defines & launches several containers | a recipe |

OpenClaw pulls images, runs containers, stores data in volumes. So you can destroy and recreate a container without losing data.

### Common commands

```bash
docker ps                    # running containers
docker ps -a                 # include stopped ones
docker images                # local images
docker logs <name>           # view logs
docker stats                 # live CPU/memory usage
docker volume ls             # data volumes
docker system df             # how much disk Docker uses
```

The OpenClaw one-liners:

```bash
openclaw start               # start container
openclaw stop                # stop (keeps data)
openclaw logs                # docker logs + secret masking
openclaw clean --status      # docker system df + Ollama disk usage
openclaw clean --all         # prune unused images & caches
```

### What is a "port"?

A container's communication "doorway number". OpenClaw exposes its web UI on port `8000`, **always bound to `127.0.0.1`** (other devices on your LAN can't reach it).

```
browser (http://127.0.0.1:8000)  ─▶  Docker  ─▶  OpenClaw container :8000
```

### Security hardening (this project adds)

Applied automatically via `compose.security.yml`:

| Option | Effect |
|---|---|
| `read_only: true` | Container rootfs is read-only |
| `cap_drop: [ALL]` | Drops every Linux capability |
| `tmpfs: /tmp` | Temp files in RAM only, lost on restart |
| `127.0.0.1` binding only | No LAN exposure |
| `no-new-privileges: true` | Blocks privilege escalation |

### When disk gets full

```bash
openclaw clean --status      # see usage at a glance
openclaw clean               # step-by-step y/n prompts
docker system prune -a       # raw cleanup (deletes all images — careful)
```

### Learn more
- Official: https://www.docker.com
- Compose docs: https://docs.docker.com/compose
- Detailed threat model: [ARCHITECTURE.md](ARCHITECTURE.md)
