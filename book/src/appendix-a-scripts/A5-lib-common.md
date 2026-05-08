# A5. `lib/common.sh` — `run_step` 과 멱등성

> 모든 `cmd/*.sh` 가 `source` 하는 공통 라이브러리. 멱등성의 핵심 구현체인 `run_step` 함수가 여기 들어 있습니다. 7장의 산문 설명은 이 파일을 출발점으로 합니다.
>
> 원본 위치: `openclaw-mgr/lib/common.sh`

## 전문 (자동 임베드 · 무삭제)

```bash
{{#include ../../../openclaw-mgr/lib/common.sh}}
```

## 왜 이게 핵심인가

- 각 단계의 **성공/실패 마커를 상태 파일에 기록**합니다.
- 같은 단계가 이미 성공으로 표시되어 있으면 **건너뜁니다** — 이게 곧 멱등성입니다.
- 중단 후 재실행 시 마커를 보고 **이어서 실행**합니다.
- 강제로 처음부터 돌리고 싶을 때는 상태 파일을 지웁니다.

## 함께 읽으면 좋은 페이지

- [7장 · 멱등성과 내부 구조](../part4-deep/07-internals.md)
- [A1. cmd/install.sh](A1-cmd-install.md) — `run_step` 을 가장 많이 호출하는 곳
- [부록 B2 · 경로와 상태 파일](../appendix-b-env/B2-paths.md) — 상태 파일이 실제로 어디 저장되는지

---

다음 → [A6. lib 나머지](A6-lib-rest.md)
