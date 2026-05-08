# A11. 디스패처 (`openclaw`, `openclaw-mgr/openclaw`)

> 사용자가 `./openclaw <command>` 로 호출할 때 실제로 실행되는 두 개의 진입 셸. 워크스페이스 루트의 디스패처가 매니저 디스패처를 호출하고, 매니저 디스패처가 다시 `cmd/<command>.sh` 를 실행합니다. 모두 전문(全文) 으로 수록합니다.

## A11-1. 워크스페이스 루트 — `openclaw`

```bash
{{#include ../../../openclaw}}
```

## A11-2. 매니저 — `openclaw-mgr/openclaw`

```bash
{{#include ../../../openclaw-mgr/openclaw}}
```

## A11-3. 보조 — `scripts/publish.sh`

```bash
{{#include ../../../scripts/publish.sh}}
```

## A11-4. 보조 — `scripts/publish-tap.sh`

```bash
{{#include ../../../scripts/publish-tap.sh}}
```

## A11-5. 경로 정규화 — `fix_paths.py`

```python
{{#include ../../../fix_paths.py}}
```

---

다음 → [부록 B · 설정 레퍼런스](../appendix-b-env/B0-overview.md)
