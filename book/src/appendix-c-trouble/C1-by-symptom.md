# 부록 C · 트러블슈팅 (증상별)

> 강의실에서 "강사님 빨간색이요" 한 마디로 들어왔던 증상들을 모았습니다. 새 증상이 발견되면 이 표에 한 줄씩 추가됩니다.

## 빠른 진단 순서

1. `./openclaw doctor` — 전체 진단 ([A2](../appendix-a-scripts/A2-cmd-doctor.md))
2. `./openclaw logs <서비스명>` — 컨테이너 로그 ([A4-4](../appendix-a-scripts/A4-cmd-data.md))
3. `docker compose ps` — 컨테이너 상태 직접 확인

## 증상 → 원인 → 해결

### 1. `EADDRINUSE` (호스트 포트가 이미 사용 중)

- **증상**: `docker compose up` 중 `Error: address already in use`
- **원인**: `compose.security.yml` 의 `ports:` 가 base compose 와 자동 머지되어 같은 호스트 포트를 두 번 바인드.
- **해결**: 보안 오버레이의 `ports:` 에 `!override` 를 명시. [A7-2](../appendix-a-scripts/A7-compose.md) 참조.

### 2. 게이트웨이가 1분 단위 재시작 루프 (exit 78)

- **증상**: gateway 컨테이너가 `Missing config. Run openclaw setup` 로그를 남기며 1분마다 죽고 살아남.
- **원인**: 첫 부팅 시 `--allow-unconfigured` 플래그 없이 시작.
- **해결**: compose 의 `command:` 오버라이드로 해결. 설치 직후에는 자동 적용됨.

### 3. `./openclaw start` 가 "OpenClaw 가 설치돼 있지 않습니다" 라고 거짓말

- **증상**: 분명히 설치했는데 start 가 안 됨.
- **원인**: 사용자 `.env` 의 `OPENCLAW_DIR` 이 옛 위치(`$HOME/openclaw`) 를 가리키고 있음. 실제 위치는 `$HOME/DEV/openclaw`.
- **해결**: [A3-1 cmd/start.sh](../appendix-a-scripts/A3-cmd-lifecycle.md) 에 자동 마이그레이션 로직 있음. 그래도 안 되면 `.env` 를 직접 수정.

### 4. LM Studio 프록시 `Address already in use` (포트 11235)

- **증상**: `lmstudio_proxy.py` 시작 시 `OSError: [Errno 48] Address already in use`.
- **원인**: 같은 프록시가 이미 떠 있는데 한 번 더 띄움.
- **해결**: `lsof -nP -iTCP:11235 -sTCP:LISTEN` 로 확인. 정상이면 종료하지 않고 그대로 사용.

### 5. 도커 데스크탑 약관 / 로그인 팝업

- **증상**: 설치 후 도커 데스크탑이 처음 켜지면서 영문 팝업이 뜸.
- **원인**: 정상 동작.
- **해결**: 약관 동의 → 통계 보내기는 선택 → 로그인 화면은 작은 글씨 "Skip" 클릭. 가입 불필요.

### 6. 안내 URL 을 통째로 Safari 주소창에 붙이면 Google 검색으로 빠짐

- **증상**: `open http://127.0.0.1:18789` 안내문을 한 줄로 붙여 넣으면 Safari 가 검색 쿼리로 처리.
- **원인**: macOS Safari 의 주소창 입력 처리.
- **해결**: 책에서는 항상 "터미널" 과 "브라우저 주소창" 을 줄을 분리해서 보여줍니다. URL 은 `http://...` 부분만 따로 복사.

---

다음 → [부록 D · 용어집](../appendix-d-glossary.md)
