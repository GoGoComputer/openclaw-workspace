# B2. 경로와 상태 파일

OpenClaw 가 사용하는 디스크 경로 한눈에.

| 변수 / 경로 | 기본값 | 의미 |
|---|---|---|
| `OPENCLAW_DIR` | `$HOME/DEV/openclaw` | OpenClaw **본체** 클론 위치 (compose 가 사는 곳) |
| `OPENCLAW_MGR_DIR` | `$HOME/DEV/openclaw-workspace/openclaw-mgr` | 매니저 스크립트 위치 |
| `OPENCLAW_MGR_HOME` | `$HOME/.openclaw-mgr` | Homebrew 설치 시 `.env` 와 상태 파일 폴백 위치 |
| `~/.openclaw-mgr/network-mode` | `isolated` 또는 `host` | 현재 네트워크 격리 모드 마커 |
| `~/.openclaw/state/` | — | `run_step` 멱등성 마커가 단계별로 쌓이는 곳 (구현 위치는 [A5](../appendix-a-scripts/A5-lib-common.md) 참조) |

## 자주 마주치는 경로 함정

- `./openclaw start` 가 "OpenClaw 가 설치되어 있지 않습니다" 라고 거짓말하면 사용자 `.env` 의 `OPENCLAW_DIR` 이 옛 위치(`$HOME/openclaw`) 인지 확인하세요. 실제 위치는 `$HOME/DEV/openclaw` 입니다. [A3-1 `cmd/start.sh`](../appendix-a-scripts/A3-cmd-lifecycle.md) 에 자동 마이그레이션 로직이 들어 있습니다.
- 강제로 처음부터 설치를 다시 돌리려면 `~/.openclaw/state/` 를 통째로 지우거나 `./openclaw install --force` (옵션이 존재한다면) 를 사용합니다.

---

다음 → [부록 C · 트러블슈팅](../appendix-c-trouble/C1-by-symptom.md)
