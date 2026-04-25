## 변경 요약

<!-- 이 PR이 무엇을 바꾸는지 한두 문장 -->

## 동기 / 관련 이슈

Closes #

## 체크리스트

- [ ] `bash -n` 통과 (`find openclaw-mgr -name '*.sh' -exec bash -n {} \;`)
- [ ] `shellcheck -S style` 새 경고 없음
- [ ] `shfmt -d -i 2 openclaw-mgr` 차이 없음
- [ ] 새 명령/옵션이 있다면 README 표 업데이트
- [ ] 사용자 입력을 받는 경로는 `lib/sec.sh` 검증 함수 통과
- [ ] 시크릿/환경 파일을 커밋에 포함하지 않음
- [ ] Bash 3.2 호환 (associative array, `mapfile`, `${var,,}` 사용 안 함)

## 테스트 방법

```bash
# 어떻게 검증했는지 명령으로
```

## 스크린샷 / 로그 (있으면)
