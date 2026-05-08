# 부록 A · 스크립트 전문 (全文 · 무삭제)

이 부록은 OpenClaw 자동화의 **모든 셸 스크립트와 Compose 파일을 한 글자도 빠짐없이** 수록합니다. 본문에서 "이 한 줄 안에서 무슨 일이 일어나는가" 가 궁금해질 때마다 여기로 와서 실제 코드를 확인하실 수 있습니다.

## 무삭제 보장 메커니즘

각 페이지의 코드 블록은 mdBook 의 `{{#include}}` 지시자로 워크스페이스의 원본 파일을 **빌드 시점에 자동 임베드**합니다.

````markdown
```bash
{{#include ../../../openclaw-mgr/cmd/install.sh}}
```
````

이 방식의 장점:

1. **사람이 손으로 복붙하지 않음** → 한 줄 빠질 위험 0
2. **원본이 바뀌면 책도 자동 동기화** → 두 곳 관리 부담 0
3. **CI 검사 가능** → `book/scripts/check-no-elision.sh` 가 `생략 / 이하 동일 / ...` 같은 표현을 0건으로 강제

## 분류 (좌측 사이드바 순서대로)

| # | 페이지 | 원본 위치 |
|---|---|---|
| A1 | [cmd/install.sh](A1-cmd-install.md) | `openclaw-mgr/cmd/install.sh` |
| A2 | [cmd/doctor.sh](A2-cmd-doctor.md) | `openclaw-mgr/cmd/doctor.sh` |
| A3 | [cmd 라이프사이클](A3-cmd-lifecycle.md) | start/stop/update/clean/uninstall/self-update |
| A4 | [cmd 데이터·운영](A4-cmd-data.md) | backup/restore/models/logs/menu/network/schedule |
| A5 | [lib/common.sh](A5-lib-common.md) | `openclaw-mgr/lib/common.sh` |
| A6 | [lib 나머지](A6-lib-rest.md) | detect/prompt/sec/update_check |
| A7 | [compose 오버레이](A7-compose.md) | `openclaw-mgr/compose.*.yml` |
| A8 | [scripts/creative](A8-scripts-creative.md) | `scripts/creative*` |
| A9 | [scripts/shorts](A9-scripts-shorts.md) | `scripts/shorts*` |
| A10 | [scripts/surf](A10-scripts-surf.md) | `scripts/surf*` |
| A11 | [디스패처](A11-dispatcher.md) | 루트 `openclaw`, `openclaw-mgr/openclaw` |

## 디스패처와 실행 흐름

```
사용자 터미널
  │  ./openclaw <command> [args...]
  ▼
[루트 openclaw]               ← 워크스페이스 진입 디스패처 (A11)
  │  cd openclaw-mgr && ./openclaw <command>
  ▼
[openclaw-mgr/openclaw]       ← 매니저 디스패처 (A11)
  │  source lib/common.sh, lib/detect.sh, ...
  │  exec cmd/<command>.sh
  ▼
[cmd/<command>.sh]            ← 실제 작업 (A1~A4)
  │  run_step "단계명" 함수 → 멱등성 마커 기록 (A5)
  │  docker compose -f compose.*.yml ... (A7)
  ▼
완료 / 실패 시 빨간 메시지
```

이 흐름이 머리 속에 그려져 있으면, 어느 페이지를 펴도 "지금 보고 있는 코드가 어디서 호출되는지" 가 보입니다.

---

다음 → [A1. cmd/install.sh](A1-cmd-install.md)
