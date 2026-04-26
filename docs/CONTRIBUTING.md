# Contributing / 기여 가이드

> 🇰🇷 PR·이슈는 한국어 또는 영어 모두 환영합니다.
> 🇺🇸 PRs and issues are welcome in either Korean or English.

먼저 시간 내주셔서 감사합니다 🙏 / Thanks for taking the time 🙏

## 📖 목차 / Contents

- [빠른 시작](#빠른-시작)
- [코드 스타일](#코드-스타일)
- [문서](#문서)
- [보안](#보안)
- [라이선스 동의](#라이선스-동의)

---

## 🗺 이 문서를 처음 보신다면 / Document Map

이 문서는 **개발자용 기여 가이드**입니다 (코드/문서/PR). 비개발자(번역·버그 신고·베타 테스트) 라면 [GUIDE-CONTRIBUTING.md](GUIDE-CONTRIBUTING.md) 를 먼저.

| 절 | 내용 |
|---|---|
| [빠른 시작](#빠른-시작) | Fork → 브랜치 → PR 5단계 |
| [코드 스타일](#코드-스타일) | shellcheck / shfmt / Bash 규칙 |
| [문서](#문서) | KO/EN 미러 정책, 마크다운 컨벤션 |
| [보안](#보안) | 취약점 보고, 민감 정보 처리 |
| [라이선스 동의](#라이선스-동의) | DCO sign-off |

> 🎯 **권장 흐름**: 빠른 시작 5단계만 보고 작은 PR 한 건 시도 → 막힐 때 해당 절로 점프.

---

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

---

<!-- RELATED-DOCS:BEGIN -->
## 🔗 관련 문서 / Related docs

| 문서 | 무엇이 있나 |
|---|---|
| [🌱 처음부터 / From zero](GUIDE-FROM-ZERO.md) | 터미널·클릭·파일 개념부터 차근차근 (KO+EN) |
| [🚀 빠른 시작 (KO)](QUICKSTART-ko.md) | 터미널 열기 → 5개 명령 → 한 줄 설치 |
| [🚀 Quickstart (EN)](QUICKSTART-en.md) | Open terminal → 5 commands → one-liner install |
| [🪜 완전 수동 설치](GUIDE-MANUAL-INSTALL.md) | brew/스크립트 없이 직접 다운 (KO+EN, 프로덕션 부록) |
| [🐳 Docker 기초](GUIDE-DOCKER.md) | 컨테이너·이미지·compose 3분 가이드 |
| [🧠 Ollama 기초](GUIDE-OLLAMA.md) | 로컬 LLM 데몬 사용법 |
| [🐾 OpenClaw 기초](GUIDE-OPENCLAW.md) | 에이전트 구조·웹에서 가져오기 단락 |
| [🌐 웹 정보 가져오기 / surf](GUIDE-WEB-FETCH.md) | 코스피·뉴스·환율·논문 — `surf` 샌드박스 명령 포함 |
| [🎨 크리에이티브 파이프라인](GUIDE-CREATIVE-PIPELINE.md) | Pinterest → 나노바나나(4창) → Figma 자동 배치 |
| [🎬 쇼츠 자동화](GUIDE-SHORTS-PIPELINE.md) | Pinterest → 미리캔버스 → CapCut → 9:16 MP4 |
| [🚑 트러블슈팅](TROUBLESHOOTING.md) | 흔한 오류와 해결 명령 |
| [🧠 아키텍처](ARCHITECTURE.md) | 디스패처·멱등 설계·compose override |
| [🤝 기여 가이드 (입문)](GUIDE-CONTRIBUTING.md) | 오타·번역·베타테스트도 환영 |
| [📦 릴리스 노트 v0.1.0](RELEASE_NOTES_v0.1.0.md) | 변경 사항 |

⬆️ [README (KO)](../README.md) · [README (EN)](../README.en.md)
<!-- RELATED-DOCS:END -->
