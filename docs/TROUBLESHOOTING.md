# Troubleshooting / 트러블슈팅

> 🇰🇷 `./openclaw doctor` 출력에 따른 대응표.
> 🇺🇸 Recovery steps keyed off `./openclaw doctor` output.
>
> Each problem name below is followed by exact commands. The commands are language-agnostic; copy/paste as-is.

## `./openclaw doctor` 출력별 대응 / Recovery by `doctor` output

| 항목 | 상태 | 대응 |
|---|---|---|
| OS | ✗ | macOS 전용. Linux/Windows 미지원 |
| RAM | ⚠ | 16~24GB: 7B 모델 1개 권장. 동시 실행 자제 |
| RAM | ✗ | 16GB 미만: 외부 API 모드(`ENABLE_OLLAMA=0`) 권장 |
| 디스크 여유 | ✗ | 20GB 이상 확보 후 재시도 |
| Xcode CLT | ✗ | `xcode-select --install` 다이얼로그 따라가기 |
| Homebrew | ✗ | `./openclaw install` 이 자동 처리. 수동: brew.sh 공식 스크립트 |
| Docker 데몬 | ✗ | Docker Desktop 앱 실행. 약관 동의 필요할 수 있음 |
| Ollama 데몬 | ✗ | `brew services start ollama` |
| OpenClaw 저장소 | ✗ | `.env` 의 `OPENCLAW_REPO` 값 확인 |
| 컨테이너 실행 | ✗ | `./openclaw start` 또는 로그 확인 `./openclaw logs` |
| 포트 충돌 | ⚠ | `lsof -nP -iTCP:11434 -sTCP:LISTEN` 로 점유 프로세스 확인 |
| 자동 업데이트 | ⚠ | 원하면 `./openclaw schedule enable` |

## 흔한 오류

### `Error: Cannot connect to the Docker daemon`

Docker Desktop 이 안 켜져 있습니다. `open -a Docker` 후 90초 대기.

### `xcrun: error: invalid active developer path`

Xcode CLT 가 망가졌거나 macOS 업데이트 후. 해결:
```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### `pull access denied for ...` (compose pull 실패)

비공개 레지스트리 또는 잘못된 이미지 태그. `OPENCLAW_REPO` 확인 + `docker login` 필요할 수 있음.

### Ollama 모델 pull 중간에 멈춤

네트워크 일시 단절. 같은 명령 재실행 시 이어받기:
```bash
ollama pull <model>
```

### `./openclaw install` 이 같은 단계에서 계속 실패

해당 단계만 다시 시도하려면 `~/.openclaw-mgr/state` 에서 그 줄을 지우세요:
```bash
sed -i '' '/^docker_start=done$/d' ~/.openclaw-mgr/state
./openclaw install
```

### 백업 복원 시 `tar: invalid option`

macOS 의 BSD tar 와 GNU tar 차이. 이 도구는 BSD tar 호환 옵션만 사용하지만, 외부 백업이라면 `brew install gnu-tar` 후 `gtar` 로 직접 풀어보세요.

### launchd 스케줄이 안 도는 것 같다

```bash
launchctl list | grep openclaw                    # 등록 확인
cat ~/.openclaw-mgr/logs/update.err.log           # 에러 로그
launchctl print "gui/$(id -u)/com.user.openclaw.update"  # 다음 실행 시각
```

수동으로 한 번 돌려보기:
```bash
launchctl kickstart -p "gui/$(id -u)/com.user.openclaw.update"
```

## 보안 경고가 떴어요

### `위험: compose 파일에 /var/run/docker.sock 마운트가 발견되었습니다`

이는 컨테이너가 호스트 Docker 를 통째로 제어할 수 있는 권한입니다 = 사실상 호스트 root. 해당 줄을 제거한 fork 를 사용하거나, 그 OpenClaw 빌드를 신뢰하지 마세요.

### `WARN: .env is NOT git-ignored`

`.gitignore` 에 `.env` 를 추가하세요. 이미 커밋했다면 그 키를 즉시 회전(rotate)하고 git 히스토리에서 제거(`git filter-repo`).

## 도움 요청 시 첨부할 정보

```bash
./openclaw doctor 2>&1 | tee /tmp/oc-doctor.txt
docker version
sw_vers
uname -a
```

`/tmp/oc-doctor.txt` 의 내용을 [GitHub Issues](https://github.com/GoGoComputer/openclaw-workspace/issues) 에 붙여 등록하세요. 시크릿은 자동 마스킹되지만 한 번 더 검토 부탁드립니다.
