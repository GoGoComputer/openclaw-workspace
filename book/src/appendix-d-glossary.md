# 부록 D · 용어집

본문에서 처음 등장할 때 한 번씩 풀어 적었지만, 까먹었을 때 펴는 한 페이지짜리 사전입니다.

## 가나다순

**고래 (🐳)**
도커 데스크탑의 메뉴바 아이콘. 도크에 떠 있으면 도커 데몬이 돌아가는 중.

**도커 (Docker)**
컨테이너를 만들고 굴리는 친구. 작업장 한쪽에 칸막이로 나눈 작은 공방을 떠올리면 됩니다.

**디스패처 (dispatcher)**
`./openclaw <command>` 명령을 받아서 적절한 `cmd/<command>.sh` 로 흘려보내는 진입 셸. [A11](appendix-a-scripts/A11-dispatcher.md) 참조.

**멱등성 (idempotency)**
같은 명령을 두 번 세 번 돌려도 결과가 같다는 성질. "있으면 안 깔고 넘어간다" 가 가장 직관적인 예. 7장과 [A5](appendix-a-scripts/A5-lib-common.md) 참조.

**오버레이 (compose overlay)**
기본 `docker-compose.yml` 위에 얹어 일부 설정만 바꾸는 yml 파일. `-f` 옵션으로 여러 개를 동시에 합칠 수 있음. [A7](appendix-a-scripts/A7-compose.md) 참조.

**올라마 (Ollama)**
맥 안에 사는 작은 동네 도서관. 인터넷 없이도 LLM 모델을 빌려 쓸 수 있게 해주는 친구.

**컨테이너 (container)**
도커가 만드는 격리된 작은 방. 한 방에 한 친구(서비스) 가 산다.

**터미널 (Terminal)**
까만 화면. 마우스 대신 글자로 컴퓨터에게 부탁하는 인터폰.

**홈브루 (Homebrew)**
맥용 앱스토어의 터미널 버전. `brew install <이름>` 으로 깔 수 있음.

**`.env`**
환경 변수 파일. 비유하자면 부엌 서랍 속 비밀번호장. [B1](appendix-b-env/B1-env-vars.md) 참조.

**`run_step`**
멱등성의 핵심 함수. 단계 이름을 받아서 성공 마커가 있으면 건너뛰고, 없으면 실행 후 마커를 기록. [A5](appendix-a-scripts/A5-lib-common.md) 참조.

---

다음 → [부록 E · 라이선스와 출처](appendix-e-license.md)
