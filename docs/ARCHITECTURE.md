# Architecture / 아키텍처

> 🇰🇷 이 문서는 모듈 구조·상태 머신·백업 포맷·보안 위협 모델을 다룹니다.
> 🇺🇸 This document covers module structure, state machine, backup format, and security threat model.
> Diagrams are language-agnostic; section headers below are in Korean for brevity. Open an issue if a full English translation is needed.

## 모듈 구조 / Module structure

```mermaid
flowchart TD
  user["사용자<br/>./openclaw &lt;cmd&gt;"]
  disp["openclaw (디스패처)<br/>.env 로드 + 라우팅"]
  user --> disp

  subgraph lib[lib/]
    common[common.sh<br/>로깅·run_step·state]
    sec[sec.sh<br/>입력 검증·마스킹]
    detect[detect.sh<br/>시스템 상태 KV]
    prompt[prompt.sh<br/>대화형 입력]
  end

  subgraph cmd[cmd/]
    doctor
    install
    start
    stop
    logs
    update
    backup
    restore
    uninstall
    schedule
  end

  disp --> doctor
  disp --> install
  disp --> start
  disp --> stop
  disp --> logs
  disp --> update
  disp --> backup
  disp --> restore
  disp --> uninstall
  disp --> schedule

  install --> common
  install --> sec
  install --> detect
  install --> prompt

  state[("~/.openclaw-mgr/state<br/>(KEY=done)")]
  install <-->|run_step| state

  docker[("Docker Desktop<br/>compose + volumes")]
  install --> docker
  start --> docker
  update --> docker
  backup --> docker
  restore --> docker

  ollama[("Ollama @ 127.0.0.1:11434")]
  install -.선택.-> ollama
  update -.모델 갱신.-> ollama

  launchd[("launchd<br/>com.user.openclaw.update")]
  schedule --> launchd
  launchd -->|매일 새벽| update
```

## install 상태 머신

```mermaid
stateDiagram-v2
  [*] --> xcode_clt
  xcode_clt --> brew
  brew --> docker_install
  docker_install --> docker_start
  docker_start --> ollama_install: ENABLE_OLLAMA=1
  docker_start --> repo_clone: ENABLE_OLLAMA=0
  ollama_install --> ollama_start
  ollama_start --> ollama_models
  ollama_models --> repo_clone
  repo_clone --> compose_scan
  compose_scan --> env_merge
  env_merge --> compose_up
  compose_up --> health
  health --> [*]

  note right of compose_scan
    /var/run/docker.sock 마운트 검출 시
    설치 즉시 중단 (Critical 보안)
  end note
```

각 상태는 `~/.openclaw-mgr/state` 에 `KEY=done` 으로 기록되어 다음 실행 시 자동 스킵.

## 백업 포맷

`openclaw-YYYYmmdd-HHMMSS-<NAME>.tar.gz` 안:

```
META                       # created, host, openclaw_dir, git_commit, mgr_version
volumes/
  <project>_<volname>.tgz  # docker volume 별 tar
env.gpg   또는   env.plain # .env (GPG AES256 또는 평문)
```

같은 이름의 `<archive>.sha256` 파일이 함께 생성됩니다. `restore.sh` 는 다음 순서로 검증:

1. `shasum -a 256 -c` 무결성
2. `tar tzf` 로 절대경로/`..` 미리 검사 → 발견 시 거부
3. `--no-same-owner --no-same-permissions` 로 임시 디렉터리 추출
4. 사용자 확인 후 볼륨 재생성·`.env` 복구

## 보안 컨테이너 옵션 (compose.security.yml)

| 옵션 | 효과 |
|---|---|
| `read_only: true` + `tmpfs` | 루트 파일시스템 변조 차단 |
| `cap_drop: [ALL]` | Linux capabilities 제거 (CAP_SYS_ADMIN 등) |
| `security_opt: [no-new-privileges:true]` | setuid 권한 상승 차단 |
| `pids_limit`, `mem_limit`, `cpus` | fork bomb / OOM / CPU 폭주 방어 |
| 항상 `127.0.0.1` 바인딩 (base compose 수정) | LAN 노출 차단 |

## 데이터 흐름

```mermaid
sequenceDiagram
  participant U as 사용자 셸
  participant H as host.docker.internal
  participant O as Ollama (host)
  participant C as OpenClaw 컨테이너 (sandbox)

  U->>C: HTTPS 127.0.0.1:8000
  C->>H: HTTPS host.docker.internal:11434
  H->>O: 127.0.0.1:11434 (loopback)
  O-->>C: 모델 응답
  C-->>U: 결과
  Note over O,C: LAN/외부망 트래픽 0
```
