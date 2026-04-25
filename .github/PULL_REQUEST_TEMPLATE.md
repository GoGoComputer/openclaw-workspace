<!-- 🇰🇷 / 🇬🇧 — fill the side you're comfortable with. Bilingual welcome. -->

## Summary / 변경 요약

<!-- One or two sentences. / 한두 문장 -->

## Motivation / Related issue · 동기 / 관련 이슈

Closes #

## Checklist / 체크리스트

- [ ] `bash -n` passes / 통과 (`find openclaw-mgr -name '*.sh' -exec bash -n {} \;`)
- [ ] No new `shellcheck -S style` warnings / 새 경고 없음
- [ ] `shfmt -d -i 2 openclaw-mgr` shows no diff / 차이 없음
- [ ] README command table updated if a new command/option was added / 명령 표 업데이트
- [ ] User input paths go through `lib/sec.sh` validators / 사용자 입력은 검증 통과
- [ ] No secrets / `.env` committed / 시크릿 미포함
- [ ] Bash 3.2 compatible (no associative arrays, `mapfile`, `${var,,}`) / Bash 3.2 호환

## How to test / 테스트 방법

```bash
# the exact commands you ran to verify / 검증한 명령
```

## Screenshots / Logs (if any) · 스크린샷 / 로그 (있으면)

> 🌱 First time contributing? See [docs/GUIDE-CONTRIBUTING.md](../blob/main/docs/GUIDE-CONTRIBUTING.md) — non-developers welcome.
> 🌱 처음이세요? [docs/GUIDE-CONTRIBUTING.md](../blob/main/docs/GUIDE-CONTRIBUTING.md) 참조 — 비개발자도 환영입니다.
