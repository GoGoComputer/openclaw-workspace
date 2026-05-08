# A7. compose 오버레이 파일들

> OpenClaw 본체의 `docker-compose.yml` 위에 **얹는** 네 개의 오버레이. `cmd/install.sh` 와 `cmd/start.sh` 가 `-f` 로 합쳐서 사용합니다. 모두 전문(全文) 으로 수록합니다.

## A7-1. `compose.network.yml` — 네트워크 격리

```yaml
{{#include ../../../openclaw-mgr/compose.network.yml}}
```

## A7-2. `compose.security.yml` — 보안 강화 오버레이

```yaml
{{#include ../../../openclaw-mgr/compose.security.yml}}
```

> 📌 **주의** · 이 파일의 `ports:` 항목은 base compose 와 자동 머지되면 같은 호스트 포트를 두 번 바인드하다가 `EADDRINUSE` 가 납니다. 반드시 `ports: !override` 사용. 자세한 사정은 [부록 C](../appendix-c-trouble/C1-by-symptom.md) 참고.

## A7-3. `compose.ollama.yml` — 올라마 통합

```yaml
{{#include ../../../openclaw-mgr/compose.ollama.yml}}
```

## A7-4. `compose.surf.yml` — Surf 웹 자동화

```yaml
{{#include ../../../openclaw-mgr/compose.surf.yml}}
```

---

다음 → [A8. scripts/creative](A8-scripts-creative.md)
