# 🌱 비개발자도 기여할 수 있어요 / Non-Developer Contributing Guide

> 🇰🇷 코드 한 줄 못 짜도 기여할 수 있는 방법이 많이 있습니다.
> 🇬🇧 You don't need to write code to contribute meaningfully.

이 가이드는 [docs/CONTRIBUTING.md](CONTRIBUTING.md) (개발자용) 와 짝을 이룹니다. **둘 중 어느 쪽으로 시작해도 환영입니다.**

---

## 🇰🇷 한국어

### 어떤 일이 "기여" 인가요?

**전부 기여입니다:**

| 종류 | 난이도 | 어떻게 |
|---|---|---|
| 🐛 버그 신고 | ⭐ | GitHub 에서 [새 이슈 → 🐛 Bug](../../issues/new/choose) |
| 💡 기능 아이디어 제안 | ⭐ | GitHub 에서 [새 이슈 → ✨ Feature](../../issues/new/choose) |
| ❓ 질문하기 | ⭐ | [Discussions](../../discussions) (있으면) 또는 이슈 |
| 📝 오타·말투 수정 | ⭐⭐ | README 의 ✏️ 아이콘 → 직접 수정 → "Propose changes" |
| 📖 문서 번역·보강 | ⭐⭐ | KO ↔ EN 번역, 헷갈렸던 부분 명확화 |
| 🆘 다른 사람 질문에 답하기 | ⭐⭐ | 이슈/디스커션에서 본인 경험 공유 |
| 🧪 새 버전 테스트 | ⭐⭐ | `openclaw self-update` 후 `openclaw doctor` 결과 공유 |
| 🐙 코드 PR | ⭐⭐⭐ | [CONTRIBUTING.md](CONTRIBUTING.md) 참조 |

### 1️⃣ 가장 쉬운 시작 — 버그 신고

뭔가 안 되거나 메시지가 이상하면 그게 곧 기여거리. **부담 갖지 마세요.**

1. https://github.com/GoGoComputer/openclaw-workspace/issues 접속
2. **New issue** → "🐛 Bug 리포트" 선택
3. 폼이 뜹니다. 모르면 모르는 대로 비우고 제출해도 됩니다.

#### 좋은 버그 리포트의 5가지

```
1) 무엇을 했나     : `openclaw install` 실행
2) 무엇을 기대했나 : 설치 완료 메시지
3) 실제로는?      : "command not found: docker" 에러
4) 환경            : macOS 15.4, M5 Pro, 24GB
5) 첨부            : openclaw doctor 출력 (시크릿 자동 마스킹됨)
```

> 💡 `openclaw doctor` 출력은 자동으로 비밀번호·키를 가립니다. 안심하고 붙여넣으세요.

### 2️⃣ 두 번째로 쉬운 시작 — 오타·문서 수정

GitHub 웹 UI 에서 직접 가능. **터미널 안 써도 됩니다.**

1. 고치고 싶은 문서 페이지 (예: [README.md](../README.md)) 열기
2. 오른쪽 위 **✏️ (연필 아이콘)** 클릭
3. 텍스트 바로 수정
4. 아래 **"Propose changes"** 버튼
5. 짧은 설명 적고 **"Create pull request"**

GitHub 이 자동으로 fork 하고 PR 까지 만들어줍니다. 우리가 받아서 머지하거나 코멘트 드려요.

### 3️⃣ 번역 기여

문서가 한 쪽 언어만 있거나 어색하면 큰 기여거리.

| 한 파일에 KO+EN 병기 | 파일이 분리됨 |
|---|---|
| `docs/ARCHITECTURE.md` | `README.md` ↔ `README.en.md` |
| `docs/CONTRIBUTING.md` | `docs/QUICKSTART-ko.md` ↔ `docs/QUICKSTART-en.md` |
| `docs/TROUBLESHOOTING.md` | |
| `docs/RELEASE_NOTES_*.md` | |
| `docs/GUIDE-*.md` | |

번역할 때 톤은 **"존댓말, 전문 용어는 영어 그대로"** (예: "컨테이너", "포트") 권장.

### 4️⃣ 다른 사람 도와주기

이슈 목록에서 본인이 답할 수 있는 게 보이면 그냥 답글. **메인테이너가 아니어도 OK.** "저는 이렇게 해결했어요" 한 줄도 큰 도움.

### 5️⃣ 새 버전 테스트 (베타 테스터)

```bash
openclaw self-update     # 최신 버전 받기
openclaw doctor          # 결과 확인
openclaw install         # 새 환경에서 설치 시도
```

이상한 게 있으면 1️⃣ 로 돌아가 신고. **"문제 없습니다" 도 가치 있는 정보.** 디스커션에 한 줄 남겨주세요.

### 🚨 절대 하지 말아야 할 것

- ❌ **`.env` 파일을 PR 에 포함** — API 키 노출 위험. 이미 `.gitignore` 에 있지만 한 번 더 확인.
- ❌ **공개 이슈에 보안 취약점 작성** — 대신 [SECURITY.md](../SECURITY.md) 절차로 비공개 신고.
- ❌ **다른 사람 정보 (스크린샷의 메일주소·토큰 등) 노출** — 가리고 올리세요.

### 행동 강령

서로 존중. 차별·괴롭힘·인신공격 금지. 의견 차이는 건강한 토론으로. 위반 신고는 [SECURITY.md](../SECURITY.md) 의 연락처로.

### 더 깊이

코드 수정·PR 절차·스타일 가이드는 [CONTRIBUTING.md](CONTRIBUTING.md) (개발자용) 참조.

---

## 🇬🇧 English

### What counts as a "contribution"?

**Everything below counts:**

| Kind | Difficulty | How |
|---|---|---|
| 🐛 Report a bug | ⭐ | GitHub → [New issue → 🐛 Bug](../../issues/new/choose) |
| 💡 Suggest a feature | ⭐ | GitHub → [New issue → ✨ Feature](../../issues/new/choose) |
| ❓ Ask a question | ⭐ | [Discussions](../../discussions) (if enabled) or an issue |
| 📝 Fix a typo / wording | ⭐⭐ | Click ✏️ in any README → edit → "Propose changes" |
| 📖 Translate / improve docs | ⭐⭐ | KO ↔ EN translation; clarify confusing parts |
| 🆘 Help others on issues | ⭐⭐ | Share your own experience |
| 🧪 Beta-test new releases | ⭐⭐ | Run `openclaw self-update` then `openclaw doctor`, share results |
| 🐙 Code PR | ⭐⭐⭐ | See [CONTRIBUTING.md](CONTRIBUTING.md) |

### 1️⃣ Easiest start — file a bug

If something feels broken or a message is confusing, that's a contribution opportunity. **No need to feel like a burden.**

1. Open https://github.com/GoGoComputer/openclaw-workspace/issues
2. **New issue** → pick "🐛 Bug report"
3. The form has fields — leave blanks if you don't know.

#### Five things that make a great bug report

```
1) What you did       : ran `openclaw install`
2) What you expected  : install-complete message
3) What actually...   : "command not found: docker" error
4) Environment        : macOS 15.4, M5 Pro, 24GB
5) Attached           : `openclaw doctor` output (secrets auto-masked)
```

> 💡 `openclaw doctor` output auto-redacts passwords and keys. Paste freely.

### 2️⃣ Second-easiest — fix a typo or doc

You can do it entirely in the GitHub web UI. **No terminal needed.**

1. Open the doc page you want to fix (e.g. [README.en.md](../README.en.md))
2. Click the **✏️ pencil icon** at the top right
3. Edit the text
4. Click **"Propose changes"** at the bottom
5. Short title + **"Create pull request"**

GitHub forks the repo and opens the PR for you. We'll review and merge or comment.

### 3️⃣ Translation contributions

If a doc is one-language-only or sounds awkward, that's huge.

| Bilingual in one file | Separate files |
|---|---|
| `docs/ARCHITECTURE.md` | `README.md` ↔ `README.en.md` |
| `docs/CONTRIBUTING.md` | `docs/QUICKSTART-ko.md` ↔ `docs/QUICKSTART-en.md` |
| `docs/TROUBLESHOOTING.md` | |
| `docs/RELEASE_NOTES_*.md` | |
| `docs/GUIDE-*.md` | |

Tone: keep technical terms (container, port, formula) in English even in Korean text.

### 4️⃣ Help others

Browse the issue list — if you know an answer, post it. **You don't need to be a maintainer.** "Here's how I worked around it" is valuable.

### 5️⃣ Beta-test new releases

```bash
openclaw self-update     # pull the latest
openclaw doctor          # check
openclaw install         # try a fresh install path
```

Anything weird? Go to step 1️⃣. **"No issues" is also valuable signal** — drop a one-liner in Discussions.

### 🚨 Things to never do

- ❌ **Include `.env` in a PR** — API keys may leak. It's `.gitignored`, but double-check.
- ❌ **Post security vulnerabilities in public issues** — follow [SECURITY.md](../SECURITY.md) for private disclosure.
- ❌ **Leak other people's data** (emails, tokens visible in screenshots) — redact before posting.

### Code of conduct

Be respectful. No discrimination, harassment, or personal attacks. Healthy disagreement is welcome. Report violations via the contact in [SECURITY.md](../SECURITY.md).

### Going deeper

Code style, PR process, and developer-side details are in [CONTRIBUTING.md](CONTRIBUTING.md).
