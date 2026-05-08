# A1. `cmd/install.sh` — 한 줄의 안쪽

> `./openclaw install` 디스패처가 실제로 호출하는 본체. 3장에서 다룬 여덟 단계가 모두 이 파일 안에 들어 있습니다.
>
> 원본 위치: `openclaw-mgr/cmd/install.sh`

## 전문 (자동 임베드 · 무삭제)

```bash
{{#include ../../../openclaw-mgr/cmd/install.sh}}
```

## 함께 읽으면 좋은 페이지

- [3장 · 설치 한 줄의 의미](../part2-install/03-install.md) — 이 스크립트의 여덟 단계를 산문으로 풀어쓴 본문
- [A5. `lib/common.sh`](A5-lib-common.md) — 이 스크립트가 호출하는 `run_step` 의 정의 (멱등성 마커)
- [A6. `lib/detect.sh`](A6-lib-rest.md) — OS·아키텍처 감지 로직
- [A7. compose 오버레이](A7-compose.md) — 이 스크립트가 `docker compose -f` 로 합치는 yml 파일들

---

다음 → [A2. cmd/doctor.sh](A2-cmd-doctor.md)
