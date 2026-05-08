# B1. 환경 변수 (`.env`)

> `openclaw-mgr/.env.example` 전문(全文) 을 무삭제 임베드합니다. 이 파일을 `.env` 로 복사한 뒤 필요한 값만 바꾸면 됩니다.

## 전문

```bash
{{#include ../../../openclaw-mgr/.env.example}}
```

## 우선순위

1. `OPENCLAW_MGR_DIR/.env` — git clone 경로 (개발용)
2. `${OPENCLAW_MGR_HOME:-$HOME/.openclaw-mgr}/.env` — Homebrew 등 read-only 폴백

자세한 동작은 [A5. `lib/common.sh`](../appendix-a-scripts/A5-lib-common.md) 의 `.env` 로딩 함수를 참고하세요.

---

다음 → [B2. 경로와 상태 파일](B2-paths.md)
