# v0.1.0 — initial release

> 🇰🇷 한국어 · 🇺🇸 English (both languages below)

## 📖 목차 / Contents

- [🇰🇷 한국어](#-한국어)
- [🇺🇸 English](#-english)
- [🙏 License](#-license)

---

## 🇰🇷 한국어

OpenClaw 셀프호스트 자동화 도구의 첫 공개 릴리스입니다.

### ✨ 새로운 기능

- **단일 진입 CLI/런처** `./openclaw` — 인자 없이 실행하면 **대화형 메뉴(`menu`)**, 모든 명령은 서브커맨드 한 줄로도 가능
  - `menu`, `doctor`, `install`, `start`, `stop`, `logs`, `update`, `backup`, `restore`, `schedule`, `network`, `clean`, `uninstall`
- **멱등 설치** — 중간에 끊겨도 다시 실행하면 이어서 진행 (`~/.openclaw-mgr/state` 기반). 공장 초기화 맥에서도, 일부 도구가 이미 설치된 맥에서도 동일하게 동작 (중복 설치 자동 방지).
- **상태 점검** — Xcode CLT / Homebrew / Docker / Ollama / 저장소 / 컨테이너 / 포트 / 디스크 / RAM / 자동 스케줄 / 네트워크 격리 / 한국 소버린 AI 호환 — 한 화면에 ✓/✗/⚠ 로 표시
- **백업·복원** — Docker 볼륨 + `.env` 를 `tar.gz` 로, sha256 체크섬 + GPG 대칭암호화(기본 ON)
- **자동 업데이트** — `launchd` 로 매일 정해진 시각 자동 `git pull --ff-only` + 이미지 갱신 + Ollama 모델 갱신
- **🔒 네트워크 격리 런처** — `./openclaw network isolated|online` 으로 컨테이너 외부 통신을 한 번에 켜고 끄기. **기본값은 isolated (외부 차단)**. 악성 패키지 다운로드, 데이터 외부 유출 모두 물리적으로 불가.
- **🧹 메모리·디스크 정리** — `./openclaw clean` 으로 비개발자도 안전하게 정리(`--status`, `--light`, `--all`, 대화형).
- **한국 소버린 AI 자연 호환** — 자매 프로젝트 [korea-sovereign-ai](https://github.com/GoGoComputer/korea-sovereign-ai) 의 EXAONE/A.X/Solar 모델을 호스트 Ollama 공유로 그대로 사용.

### 🔒 보안

- `compose.security.yml` 강제 — `read_only`, `cap_drop:[ALL]`, `no-new-privileges`, pid/mem/cpu 한도
- **네트워크 격리(기본값)** — Docker `internal: true` + DNS 차단으로 컨테이너→외부 모든 통신 차단
- `/var/run/docker.sock` 마운트 자동 검출·차단
- 모든 외부 노출 포트는 `127.0.0.1` 에만 바인딩
- `.env` chmod 600 + `.gitignore` 강제 + git-ignore 검증
- 백업 traversal 방어 (`tar tzf` 사전 검사 + `--no-same-owner`)
- launchd plist 권한·소유자·절대경로 검증
- `git clone --depth 1` + 선택적 `OPENCLAW_PIN_COMMIT` 핀
- 로그 출력에서 `*KEY|*TOKEN|*SECRET|PASSWORD` 자동 마스킹
- gitleaks pre-commit hook + CI 검사

### 📚 문서

- [README.md](../README.md) — 한국어 메인
- [README.en.md](../README.en.md) — 영어 (동등 분량)
- [docs/QUICKSTART-ko.md](QUICKSTART-ko.md) · [docs/QUICKSTART-en.md](QUICKSTART-en.md) — 비개발자용 단계별 가이드
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — 모듈 다이어그램·상태 머신·백업 포맷
- [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) — `doctor` 출력별 대응표
- [docs/CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](../SECURITY.md)

### ⚠️ 알려진 제한

- macOS 전용 (Linux/Windows 미지원)
- 레퍼런스 머신: MacBook Pro 16" M5 Pro / 24GB RAM (Apple Silicon arm64)

### 🚀 설치

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace/openclaw-mgr
./openclaw            # 대화형 메뉴 (또는: ./openclaw doctor && ./openclaw install)
```

> `.env` 는 첫 실행 시 자동 생성됩니다.

---

## 🇺🇸 English

First public release of the OpenClaw self-host automation tool.

### ✨ New features

- **Single-entry CLI/launcher** `./openclaw` — run with no arguments to open the **interactive menu (`menu`)**, or use any subcommand directly
  - `menu`, `doctor`, `install`, `start`, `stop`, `logs`, `update`, `backup`, `restore`, `schedule`, `network`, `clean`, `uninstall`
- **Idempotent install** — interrupted runs resume from the last completed step (state in `~/.openclaw-mgr/state`). Works identically on a freshly factory-reset Mac and on a Mac that already has some tools installed (duplicates auto-skipped).
- **State diagnosis** — Xcode CLT / Homebrew / Docker / Ollama / repo / container / ports / disk / RAM / auto-schedule / network isolation / Korean Sovereign AI compatibility — all in one ✓/✗/⚠ table
- **Backup & restore** — Docker volumes + `.env` packed as `tar.gz`, sha256 checksum + GPG symmetric encryption (default ON)
- **Auto-update** — daily at a fixed time via `launchd`: `git pull --ff-only` + image refresh + Ollama model refresh
- **🔒 Network isolation launcher** — `./openclaw network isolated|online` toggles outbound traffic in one command. **Default is `isolated` (outbound blocked)**. Malicious package downloads and data exfiltration are physically impossible.
- **🧹 Memory & disk cleanup** — `./openclaw clean` lets non-developers safely tidy up (`--status`, `--light`, `--all`, interactive).
- **Native Korean Sovereign AI compatibility** — sister project [korea-sovereign-ai](https://github.com/GoGoComputer/korea-sovereign-ai) (EXAONE/A.X/Solar) shares the host Ollama and works as-is.

### 🔒 Security

- `compose.security.yml` enforced — `read_only`, `cap_drop:[ALL]`, `no-new-privileges`, pid/mem/cpu limits
- **Network isolation by default** — Docker `internal: true` + DNS blocked → no outbound traffic from the container
- Auto-detects and blocks `/var/run/docker.sock` mounts
- All exposed ports bind to `127.0.0.1` only
- `.env` chmod 600 + enforced in `.gitignore` + verified
- Backup traversal protection (`tar tzf` pre-check + `--no-same-owner`)
- launchd plist permission/owner/absolute-path validation
- `git clone --depth 1` + optional `OPENCLAW_PIN_COMMIT`
- Auto-masks `*KEY|*TOKEN|*SECRET|PASSWORD` in log output
- gitleaks pre-commit hook + CI scan

### 📚 Docs

- [README.md](../README.md) — Korean (main)
- [README.en.md](../README.en.md) — English (equivalent depth)
- [docs/QUICKSTART-ko.md](QUICKSTART-ko.md) · [docs/QUICKSTART-en.md](QUICKSTART-en.md) — non-developer step-by-step
- [docs/ARCHITECTURE.md](ARCHITECTURE.md), [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md), [docs/CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](../SECURITY.md)

### ⚠️ Known limitations

- macOS only (no Linux/Windows)
- Reference machine: MacBook Pro 16" M5 Pro / 24GB RAM (Apple Silicon arm64)

### 🚀 Install

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git
cd openclaw-workspace/openclaw-mgr
./openclaw            # interactive menu (or: ./openclaw doctor && ./openclaw install)
```

> `.env` is created automatically on first run.

---

## 🙏 License

MIT © 2026 박성모 Park Sungmo

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
| [🚑 트러블슈팅](TROUBLESHOOTING.md) | 흔한 오류와 해결 명령 |
| [🧠 아키텍처](ARCHITECTURE.md) | 디스패처·멱등 설계·compose override |
| [🤝 기여 가이드 (입문)](GUIDE-CONTRIBUTING.md) | 오타·번역·베타테스트도 환영 |
| [🐙 기여 가이드 (코드)](CONTRIBUTING.md) | 코드 스타일·PR 절차 |

⬆️ [README (KO)](../README.md) · [README (EN)](../README.en.md)
<!-- RELATED-DOCS:END -->
