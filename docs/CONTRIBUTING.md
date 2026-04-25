# Contributing / 기여 가이드

> 🇰🇷 PR·이슈는 한국어 또는 영어 모두 환영합니다.
> 🇺🇸 PRs and issues are welcome in either Korean or English.

먼저 시간 내주셔서 감사합니다 🙏 / Thanks for taking the time 🙏

## 빠른 시작

1. Fork → clone
2. 브랜치 생성: `git checkout -b feat/짧은-설명`
3. 로컬 검증:
   ```bash
   # 문법
   find openclaw-mgr -name '*.sh' -exec bash -n {} \;
   bash -n openclaw-mgr/openclaw

   # 정적 분석 (있으면 좋음)
   brew install shellcheck shfmt
   shellcheck -S style openclaw-mgr/openclaw openclaw-mgr/lib/*.sh openclaw-mgr/cmd/*.sh
   shfmt -d -i 2 openclaw-mgr
   ```
4. 커밋: [Conventional Commits](https://www.conventionalcommits.org/) (예: `feat: schedule status command`, `fix: BSD tar compat`)
5. PR 생성 — 템플릿의 체크리스트를 채워주세요

## 코드 스타일

- **Bash 3.2 호환** (macOS 기본). 다음을 쓰지 마세요:
  - `declare -A` (associative array)
  - `${var,,}` `${var^^}`
  - `mapfile` / `readarray`
  - `wait -n`
- 모든 변수는 `"$var"` 로 인용 (배열은 `"${arr[@]}"`)
- `eval`, `bash -c "$untrusted"` 금지
- 모든 스크립트 상단에:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- 임시 파일은 `mktemp -d` + trap 정리

## 문서

- 한국어 README 가 1순위, `README.en.md` 는 핵심만 영어로
- 코드 주석은 한국어 (비개발자가 봐도 의도 파악 가능 수준)
- 새 명령 추가 시 README의 "명령 카탈로그" 표 갱신

## 보안

- 시크릿/키를 절대 커밋하지 마세요. CI 의 `gitleaks` 가 막지만 사람이 먼저 조심
- 새 외부 명령(curl, brew install 등)을 추가할 때는 출처 도메인을 PR 설명에 명시
- 사용자 입력을 받는 경로는 `lib/sec.sh` 의 검증 함수를 통과시켜 주세요

## 라이선스 동의

PR 을 보내시면 [MIT 라이선스](../LICENSE) 로 기여하시는 데 동의하신 것으로 간주합니다.
