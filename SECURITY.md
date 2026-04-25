# 보안 정책

## 책임 있는 공개 (Responsible Disclosure)

이 도구는 AI 에이전트의 실행 환경을 셋업합니다. 보안 취약점이 있다면 사용자의 호스트 시스템에 직접적인 위협이 될 수 있어, 공개 이슈로 등록하지 마시고 아래 절차를 따라주세요.

### 신고 방법

1. GitHub 의 [Security Advisories](https://github.com/GoGoComputer/openclaw-workspace/security/advisories/new) 에 비공개로 작성, 또는
2. 작성자에게 직접 연락 (`README` 의 작성자 정보 참조)

### 신고 시 포함해주세요

- 영향받는 버전 / 커밋 해시
- 재현 단계 (가능하면 PoC)
- 영향 범위 평가 (Critical / High / Medium / Low)
- 가능한 mitigation

### 응답 SLA

- **24시간 안에** 접수 확인
- **7일 안에** 초기 평가
- **90일 임베고** 후 공개 (협의 가능)

## 우리가 신경 쓰는 위협 모델

| 위협 | 대응 |
|---|---|
| 컨테이너 → 호스트 탈출 | `compose.security.yml`(read_only, cap_drop, no-new-privileges), Docker 소켓 마운트 자동 차단 |
| LAN/공용 Wi-Fi 노출 | 모든 포트 `127.0.0.1` 만 바인딩, Ollama `0.0.0.0` 안내 제거 |
| 시크릿 누출 | `.env` chmod 600, `.gitignore` 강제, 로그 자동 마스킹, 백업 GPG 암호화 |
| 공급망 공격 | `git clone --depth 1` + 선택적 `OPENCLAW_PIN_COMMIT`, brew 외 임의 URL 다운로드 금지 |
| `curl \| bash` MITM | TLS 1.2 강제, 기본 설치 경로는 `git clone`, 1-라이너는 SHA-256 핀 동반 |
| launchd 변조 | plist 권한·소유자·절대경로 검증 |
| 백업 traversal | `tar tzf` 사전 검사 + `--no-same-owner --no-same-permissions` |

## 우리가 책임지지 않는 것

- OpenClaw 자체(업스트림)의 취약점 — 업스트림에 별도 신고 필요
- 사용자가 스스로 안전 옵션을 끈 경우 (`compose.security.yml` 미적용 등)
- Docker Desktop / Ollama / Homebrew 자체의 취약점

## 자체 점검

```bash
# 시크릿 누설 검사
brew install gitleaks
gitleaks detect --no-git -v

# 컨테이너 보안 옵션 확인
docker inspect <container_id> | grep -E 'ReadonlyRootfs|CapAdd|SecurityOpt|PidsLimit'

# 외부 노출 포트 확인 (모두 127.0.0.1 이어야 함)
lsof -nP -iTCP -sTCP:LISTEN | grep -v '127.0.0.1\|::1'
```
