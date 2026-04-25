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

### `Docker Desktop - Rosetta installation failed` / `VZErrorDomain Code=1` (Apple Silicon)

Docker Desktop 첫 실행 시 Apple Silicon 맥에서 Rosetta 2 자동 설치가 실패할 때 뜨는 다이얼로그입니다. **Docker 자체는 정상**이며, OpenClaw 가 사용하는 모든 이미지는 ARM64 네이티브라 Rosetta 가 **필요 없습니다**.

**가장 쉬운 해결: 다이얼로그의 [Disable Rosetta] 버튼을 클릭하세요.** 끝.

그래도 Rosetta 를 깔고 싶으면 (다른 Intel-only 이미지를 같이 쓸 일이 있을 때):

```bash
# 터미널에서 직접 설치 (자동 설치보다 성공률이 높음)
softwareupdate --install-rosetta --agree-to-license

# 그 다음 Docker 다이얼로그의 [Retry] 클릭
# 또는 Docker 자체를 재시작:
osascript -e 'quit app "Docker"' && sleep 5 && open -a Docker
```

확인:
```bash
docker --version
docker info       # Server: ... 행이 보이면 OK
arch -x86_64 echo ok    # Rosetta 정상 작동 시: ok
```

> 💡 **권장**: OpenClaw 만 쓸 거면 그냥 **Disable Rosetta**. 나중에 필요해지면 Settings → General → "Use Rosetta for x86_64/amd64 emulation" 로 다시 켤 수 있습니다.

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

### `brew install` 중 `curl: (56) ... error: 502` / GitHub 502 Bad Gateway

GitHub (codeload) 일시 장애입니다. 우리 Formula·SHA256 문제가 아니므로 잠시 후 재시도하면 됩니다.

```bash
# 1) 같은 명령 다시
brew install gogocomputer/openclaw/openclaw-workspace

# 2) 그래도 안 되면 캐시 비우고 강제 재시도
brew cleanup -s
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --force gogocomputer/openclaw/openclaw-workspace

# 3) tarball 자체가 살아있는지 직접 확인 (200 이면 OK)
curl -sIL -o /dev/null -w "%{http_code}\n" \
  https://github.com/GoGoComputer/openclaw-workspace/archive/refs/tags/v0.1.6.tar.gz
```

> 💡 502 / 503 / 504 는 모두 동일한 처방. GitHub 상태는 https://www.githubstatus.com 에서 확인.

#### 502 가 계속될 때 — 개발자용 수동 설치 / Manual install fallback (developer)

GitHub codeload 가 길게 죽었을 때, 또는 brew 의존 없이 바로 쓰고 싶을 때:

**A) git clone 으로 바로 사용 (가장 확실)**

```bash
git clone https://github.com/GoGoComputer/openclaw-workspace.git ~/openclaw-workspace
cd ~/openclaw-workspace/openclaw-mgr
./openclaw doctor
./openclaw install

# PATH 에 등록하고 싶으면 (선택)
ln -sf "$PWD/openclaw" /usr/local/bin/openclaw    # Intel macOS
# 또는
ln -sf "$PWD/openclaw" /opt/homebrew/bin/openclaw # Apple Silicon
```

> Git 은 codeload 가 아닌 다른 GitHub 엔드포인트를 사용해서 502 영향을 덜 받습니다.

**B) tarball 직접 다운로드 후 brew 로 설치 (formula 만 사용)**

```bash
# 1) tarball 직접 받기
curl -fL -o /tmp/openclaw-v0.1.6.tar.gz \
  https://github.com/GoGoComputer/openclaw-workspace/archive/refs/tags/v0.1.6.tar.gz

# 2) Homebrew 다운로드 캐시에 미리 넣어두기 (brew 가 다시 받지 않게)
mv /tmp/openclaw-v0.1.6.tar.gz \
   "$(brew --cache)/downloads/$(shasum -a 256 < /tmp/openclaw-v0.1.6.tar.gz 2>/dev/null | awk '{print $1}')--openclaw-workspace-0.1.6.tar.gz" 2>/dev/null \
   || cp /tmp/openclaw-v0.1.6.tar.gz "$(brew --cache)/openclaw-workspace--0.1.6.tar.gz"

# 3) 평소처럼 설치 시도
brew install gogocomputer/openclaw/openclaw-workspace
```

**C) tap 없이 Formula 단일 파일로 설치**

```bash
brew install --build-from-source \
  https://raw.githubusercontent.com/GoGoComputer/homebrew-openclaw/main/Formula/openclaw-workspace.rb
```

**D) 특정 커밋(태그) 으로 고정 / Pin to a specific tag**

```bash
git -C ~/openclaw-workspace fetch --tags
git -C ~/openclaw-workspace checkout v0.1.6
~/openclaw-workspace/openclaw-mgr/openclaw doctor
```

### `zsh: unknown file attribute: ^-` 가 다음 줄에 떴다

이전 출력 줄의 글리프(`✘`, `✓`)를 zsh 가 다음 명령의 일부로 잘못 해석한 결과입니다. **무해**하므로 무시하고 다음 명령을 입력하세요.

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
