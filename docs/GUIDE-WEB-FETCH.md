# 🌐 웹에서 정보 가져오기 가이드 — 코스피·뉴스·환율 등 / Web Fetch Guide

[← README 로 돌아가기](../README.md) · [README (English)](../README.en.md)

> **한 줄 요약.** OpenClaw 는 기본적으로 외부 인터넷을 차단(`isolated`)합니다. 필요한 시점에만 잠깐 `online` 으로 열어 실시간 데이터를 가져오고 다시 잠금니다. 더 쉬운 방식은 이 가이드 §8 의 `surf` 명령 — 한 줄로 검색 → 마크다운 브리프를 1회용 Docker 샌드박스 안에서 만듭니다.

<table>
<tr><td><b>누구에게 좋은가요?</b></td><td>• 매일 코스피 종가·뉴스 요약을 부담 없이 받고 싶은 일반 사용자<br>• 논문·리서치·FX 같은 실시간 데이터를 LLM 입력으로 쓰고 싶은 개발자<br>• 보안이 중요한 환경에서 웹 접근을 명시적 토글로 관리하고자 하는 팀</td></tr>
<tr><td><b>무엇이 필요한가요?</b></td><td>• OpenClaw 설치 완료 (`./openclaw doctor` 결과 OK)<br>• 인터넷 연결<br>• (`surf` 만) Docker Desktop 실행 중 + `bash scripts/surf-setup.sh` 1회 실행</td></tr>
<tr><td><b>조심할 점은?</b></td><td>• 웹 페이지는 악의적 프롬프트를 포함할 수 있으므로 (**간접 프롬프트 인젝션**), 작업 직후 다시 `isolated` 로 잠그고 RSS·공식 API 를 우선하세요. 작업하는 동안에도 컨테이너는 read-only + 127.0.0.1 전용 바인딩이라 호스트 파일 시스템과 식별자는 그대로 보호됩니다.</td></tr>
</table>

## 5분 빠른 시작 (TL;DR)

```bash
# 더 쉽고 안전한 길: 1회용 샌드박스 컨테이너
bash scripts/surf-setup.sh                           # 1회
surf "오늘 코스피 종가와 거래대금"             # 이후 매번
# → ~/openclaw-surf/out/오늘-코스피-종가...-YYYYMMDD-HHMM.md

# 전통적 길: OpenClaw 컨테이너 자체를 online 으로 잠시 전환
./openclaw network online --restart
#  … 원하는 질문을 OpenClaw UI 에서 수행 …
./openclaw network isolated --restart                # 작업 끝나면 잠그기
```

---

이 가이드는 [GUIDE-OPENCLAW.md](GUIDE-OPENCLAW.md) 의 짧은 "웹에서 가져오기" 단락을 **실전 예시·안전 패턴·트러블슈팅** 까지 확장합니다.

## 📖 목차 / Contents

- [🇰🇷 한국어](#-한국어)
  - [핵심 요약](#핵심-요약)
  - [1. 인터넷 켜기 → 작업 → 다시 잠그기 (권장 사이클)](#1-인터넷-켜기--작업--다시-잠그기-권장-사이클)
  - [2. 실전 프롬프트 — 코스피·뉴스·환율](#2-실전-프롬프트--코스피뉴스환율)
  - [3. 어떤 출처가 잘 동작하나](#3-어떤-출처가-잘-동작하나)
  - [4. 공식 API 키 쓰는 법 (선택)](#4-공식-api-키-쓰는-법-선택)
  - [5. 안전 패턴 (꼭 읽기)](#5-안전-패턴-꼭-읽기)
  - [6. 자동화 — 매일 아침 9시 코스피 요약](#6-자동화--매일-아침-9시-코스피-요약)
  - [7. 트러블슈팅](#7-트러블슈팅)
  - [8. 🧪 샌드박스 자동 브리프 — `surf` 명령](#8--샌드박스-자동-브리프--surf-명령)
- [🇬🇧 English](#-english)
  - [TL;DR](#tldr)
  - [1. Open the network → work → lock back (recommended cycle)](#1-open-the-network--work--lock-back-recommended-cycle)
  - [2. Practical prompts — stocks · news · FX](#2-practical-prompts--stocks--news--fx)
  - [3. Which sources work well](#3-which-sources-work-well)
  - [4. Using official API keys (optional)](#4-using-official-api-keys-optional)
  - [5. Safety patterns (must read)](#5-safety-patterns-must-read)
  - [6. Automation — daily 9am KOSPI brief](#6-automation--daily-9am-kospi-brief)
  - [7. Troubleshooting](#7-troubleshooting)

---

## 🇰🇷 한국어

### 핵심 요약

- OpenClaw 는 기본적으로 **외부 인터넷이 차단** 되어 있습니다 (`isolated` 모드).
- 웹에서 정보를 가져오려면 **잠깐 `online` 으로 전환** → 작업 → **다시 `isolated`** 로 잠그면 끝.
- 호스트(맥북) 파일·`~/.ssh`·LAN 다른 기기는 **online 모드에서도 보호** 됩니다 (마운트가 없고 127.0.0.1 만 바인딩되기 때문).
- 코스피·뉴스 같은 공개 정보는 **공식 API** (한국거래소 KRX, 한국은행 ECOS, 네이버/다음 RSS) 를 쓰면 가장 안정적이고 빠릅니다. API 키 없이 HTML 만 긁어도 동작은 합니다.

### 1. 인터넷 켜기 → 작업 → 다시 잠그기 (권장 사이클)

```bash
# 1) 인터넷 허용 (이 한 줄로 컨테이너만 인터넷에 닿게 됨)
./openclaw network online --restart

# 2) OpenClaw UI 에서 자유롭게 질문
#    예) "오늘 코스피 종가와 거래량 알려줘"
#        "한겨레 1면 헤드라인 5개를 한 줄씩 요약"
#        "원/달러 환율 어제 대비 변화율"

# 3) 끝나면 바로 잠그기 (습관화 강력 권장)
./openclaw network isolated --restart

# 4) 현재 모드 확인
./openclaw network status
```

> 💡 `./openclaw update` 는 내부적으로 `online` 으로 잠깐 전환했다가 끝나면 **이전 모드를 자동 복원** 합니다. 그래서 평소엔 `isolated` 로 두고 살아도 업데이트가 막히지 않습니다.

### 2. 실전 프롬프트 — 코스피·뉴스·환율

OpenClaw UI 에 그대로 붙여 넣으면 됩니다. 모델은 `qwen2.5-coder:7b` 또는 `solar-pro:latest` 정도면 충분합니다.

#### 📈 코스피·코스닥 종가

```
오늘 코스피·코스닥 종가, 등락폭, 거래대금을
다음 형식으로 한 표에 정리해줘:

| 지수 | 종가 | 전일대비 | 등락률 | 거래대금 |
|---|---|---|---|---|

출처는 표 아래에 줄로 명시.
```

> Tip: 출처를 명시하라고 하면 모델이 환각(hallucination) 대신 실제 fetch 한 페이지를 인용합니다.

#### 🗞 뉴스 헤드라인 요약

```
한겨레·조선일보·연합뉴스 1면 헤드라인 각각 5개씩 가져와서
한 줄씩 한국어로 요약해줘. 각 줄 끝에 (출처: 한겨레) 식으로 표기.
정치·경제·사회를 균형 있게.
```

#### 💱 환율·금리

```
한국은행 ECOS 또는 네이버 금융에서:
1) 원/달러, 원/엔, 원/위안 어제 종가 대비 변화율
2) 미 10년 국채 금리 어제 대비 변화 (bp)
표로 정리. 데이터가 없으면 "데이터 없음" 이라고 솔직히 적어줘.
```

#### 📊 종목 분석 (단순)

```
삼성전자(005930) 와 SK하이닉스(000660):
- 최근 5거래일 종가
- 이동평균(5일) 비교
- 외국인 순매수/순매도 추세 (가능하면)
표 + 100자 코멘트.
```

> ⚠️ **투자 자문이 아닙니다.** OpenClaw 가 가져온 숫자는 표시 시점의 공개 정보이며, 모델 해석은 참고용입니다.

#### 📚 논문·문서 요약

```
이 URL 의 본문을 긁어서 한국어로 5문장 요약 + 영어 abstract 직역:
https://arxiv.org/abs/2310.06825
```

### 3. 어떤 출처가 잘 동작하나

| 출처 | 안정성 | 비고 |
|---|---|---|
| **네이버 금융** `https://finance.naver.com` | ⭐⭐⭐⭐ | 종가·거래량·뉴스 한 곳에. HTML 단순 |
| **다음 금융** `https://finance.daum.net` | ⭐⭐⭐ | JS 렌더링 일부 — fetch 만으로 안 될 수 있음 |
| **한국거래소 KRX** `http://data.krx.co.kr` | ⭐⭐⭐⭐⭐ | **공식**. 일별 시세 CSV 다운로드 가능 |
| **한국은행 ECOS** `https://ecos.bok.or.kr` | ⭐⭐⭐⭐⭐ | **공식 API**. 키 발급 필요 (무료) |
| **연합뉴스 RSS** `https://www.yna.co.kr/rss/news.xml` | ⭐⭐⭐⭐⭐ | RSS 가 가장 안정적 |
| **한겨레 RSS** `https://www.hani.co.kr/rss/` | ⭐⭐⭐⭐ | 카테고리별 별도 RSS |
| **Google News RSS** `https://news.google.com/rss?hl=ko` | ⭐⭐⭐⭐ | 검색어 기반 RSS 도 가능 |
| **arxiv.org** | ⭐⭐⭐⭐⭐ | API + abstract 페이지 모두 안정 |
| **로그인 필요한 사이트 (증권사 HTS, 카카오 본인인증)** | ❌ | 동작 안 함. API 키나 RSS 우회 권장 |
| **JS 가 다 그리는 SPA (예: 일부 핀테크 대시보드)** | ⭐⭐ | 모델이 fetch 한 HTML 에 데이터가 비어 있을 수 있음 |

> 💡 **RSS 가 사실상 최고**. JSON/HTML 파싱보다 가볍고, 차단도 거의 없습니다.

### 4. 공식 API 키 쓰는 법 (선택)

API 키를 쓰면 **차단·rate limit 없이** 더 빠르고 안정적으로 받을 수 있습니다.

#### 한국은행 ECOS

1. https://ecos.bok.or.kr → 회원가입 → "Open API → 인증키 신청" → 무료 키 발급.
2. `.env` 에 추가:
   ```bash
   echo 'ECOS_API_KEY=여기_발급받은_키' >> ~/DEV/openclaw-workspace/openclaw-mgr/.env
   chmod 600  ~/DEV/openclaw-workspace/openclaw-mgr/.env
   ./openclaw stop && ./openclaw start
   ```
3. 프롬프트:
   ```
   ECOS_API_KEY 환경변수의 키로 한국은행 ECOS API 호출:
   - 통계표 코드 731Y001 (원/달러 환율) 최근 30일
   curl 한 줄 + 결과 한 줄 요약.
   ```

#### KRX 일별 시세 (키 불필요)

```
http://data.krx.co.kr/contents/MDC/MDI/mdiLoader/index.cmd?menuId=MDC0201020101
형태로 일자 파라미터를 바꿔가며 OTPgen → 데이터 다운로드 흐름.
오늘 코스피 일별 시세 CSV 를 받아 헤더 + 상위 10행만 보여줘.
```

#### Google Search (Programmable Search Engine)

```bash
# https://programmablesearchengine.google.com 에서 무료 엔진 생성
echo 'GOOGLE_CSE_ID=...' >> .env
echo 'GOOGLE_API_KEY=...' >> .env
```

### 5. 안전 패턴 (꼭 읽기)

웹을 켜는 순간 **공급망/프롬프트 인젝션 위험** 이 같이 들어옵니다. 다음 패턴을 지키세요.

| 위험 | 대응 |
|---|---|
| **악성 페이지가 모델에게 "이 토큰을 외부로 전송하라" 라고 지시** (간접 prompt injection) | 출처 신뢰도가 낮은 URL 은 직접 붙이지 말고 RSS·공식 API 를 통하기. 결과 표시 후 즉시 `isolated` 로 잠그기. |
| **악성 다운로드 (악성 PDF/스크립트)** | 컨테이너는 `read_only: true` 라 영속 변경 불가. 호스트로 빠져나갈 수 없음 (마운트 없음). |
| **API 키 노출** | `.env` 권한 `600`, 백업은 `OPENCLAW_BACKUP_GPG_RECIPIENT` 로 암호화. |
| **자료 인용 환각** | 프롬프트 끝에 *"실제 fetch 한 URL 과 발췌 문구를 그대로 인용해줘. 못 가져온 항목은 '데이터 없음' 으로."* 추가. |
| **사이트 robots.txt 위반** | 공개 RSS·공식 API 를 우선 사용. 대량 자동 크롤은 자제. |
| **민감 폴더 마운트 후 인터넷 열기** | `~/.ssh`, `~/Documents` 등 절대 마운트하지 말 것. 공유 필요 시 `~/Desktop/openclaw-share` 같은 격리 폴더만. |

#### 권장 "1회용 인터넷 세션" 스니펫

```bash
# session-online.sh — 5분만 인터넷 허용 후 자동 잠금
./openclaw network online --restart
echo "🌐 online — 5분 후 자동 isolated 로 복귀합니다."
( sleep 300 && ./openclaw network isolated --restart ) &
disown
```

저장: `~/bin/openclaw-session-online`, `chmod +x` 후 `openclaw-session-online`.

### 6. 자동화 — 매일 아침 9시 코스피 요약

```bash
# ~/bin/kospi-brief.sh
#!/usr/bin/env bash
set -euo pipefail
cd ~/DEV/openclaw-workspace
./openclaw network online --restart

PROMPT='오늘 코스피·코스닥 종가, 등락률, 거래대금 요약.
표 한 개 + 한 줄 코멘트. 출처는 표 아래 명시.'

# OpenClaw 컨테이너에 직접 추론 요청 (예시 — UI 자동화는 별도)
curl -s http://127.0.0.1:11434/api/generate -d "$(jq -n \
  --arg model "qwen2.5-coder:7b" \
  --arg prompt "$PROMPT" \
  '{model:$model, prompt:$prompt, stream:false}')" | jq -r '.response' \
  > ~/Desktop/kospi-$(date +%F).md

./openclaw network isolated --restart
```

```bash
chmod +x ~/bin/kospi-brief.sh
crontab -e
# 평일 9시
0 9 * * 1-5 ~/bin/kospi-brief.sh
```

> 또는 `launchd` (`~/Library/LaunchAgents/local.openclaw.kospi.plist`) 로 등록하면 노트북 깨어 있을 때만 실행되어 더 자연스럽습니다.

### 7. 트러블슈팅

| 증상 | 원인 | 대응 |
|---|---|---|
| `openclaw network online --restart` 후에도 fetch 가 실패 | DNS 가 아직 캐시 안 잡힘 | 30초 대기 후 재시도, 또는 `docker compose restart` |
| 결과가 "최신 정보를 가져올 수 없습니다" 라고만 답함 | 모델이 `online` 인지 모름 (시스템 프롬프트 미설정) | 프롬프트 앞에 *"인터넷 접근 가능. 실시간 정보 fetch 후 답변."* 명시 |
| HTML 은 받아왔는데 본문이 비어 있음 | JavaScript 렌더링 사이트 | RSS·공식 API 로 우회, 또는 `playwright` 기반 헤드리스 브라우저 추가 (고급) |
| 한 페이지에 모든 정보가 너무 많아 잘림 | 컨텍스트 길이 초과 | 더 큰 컨텍스트 모델 (`qwen2.5:14b-instruct-q4_K_M`) 또는 미리 `curl ... \| pup`/`htmlq` 로 잘라서 입력 |
| `network online` 한 채로 깜빡 잊음 | 사람의 망각 | 위 [1회용 세션 스니펫](#권장-1회용-인터넷-세션-스니펫) 으로 자동 잠금 |
| 사이트가 봇 차단(403/429) | UA 누락 / rate limit | RSS 로 전환. 정 안 되면 `Mozilla/5.0` UA 명시. 그래도 안 되면 그 사이트는 포기. |

### 8. 🧪 샌드박스 자동 브리프 — `surf` 명령

> **OpenClaw 메인 컨테이너를 건드리지 않고**, 1회용 격리 컨테이너에서 검색·수집·요약·문서화까지 한 번에 끝냅니다. 코스피 종가, 뉴스 5선, 환율 등 **명령 → 검색 → 마크다운** 시나리오에 최적화.

#### 한 줄로:

```bash
surf "오늘 코스피 종가와 거래대금"
# → ~/openclaw-surf/out/오늘-코스피-종가와-거래대금-20260426-0930.md

surf "이번 주 IT 빅뉴스 5건" --max 8
surf "S&P 500 weekly recap" --lang en --sources rss,wikipedia
surf "이 논문 요약" --sources url://https://arxiv.org/abs/2310.06825
surf "삼성전자 외국인 매매 추이" --out samsung-foreign.md
```

#### 어떻게 동작하나

```
호스트(맥북)                                              인터넷
  └ surf "오늘 코스피 ..."  ─►  Docker compose run --rm
                                       │
                                ┌──────▼──────────────────┐
                                │ 1회용 컨테이너            │   ⇄ 일반 인터넷
                                │ Playwright + Python       │
                                │ read_only: true           │
                                │ cap_drop: ALL             │
                                │ tmpfs:/tmp                │
                                │ 마운트: out/ 만 read-write │
                                └──────┬──────────────────┘
                                       │ host.docker.internal:11434
                                ┌──────▼─────────────────┐
                                │ 호스트 Ollama          │
                                │ (qwen2.5-coder:7b)     │
                                └──────┬─────────────────┘
                                       │
            ~/openclaw-surf/out/*.md  ◄┘ (호스트에 저장, 컨테이너는 사라짐)
```

#### OpenClaw 메인 컨테이너와의 격리

| 항목 | 영향? |
|---|---|
| OpenClaw 컨테이너 `isolated` 모드 유지? | ✅ 그대로 유지 (별개 compose 프로젝트, 별개 네트워크) |
| 호스트 `~/.ssh`, `~/Documents` 접근 | ❌ 마운트 없음 |
| OpenClaw `.env` / `compose.security.yml` 접근 | ❌ 마운트 없음 |
| 컨테이너의 영속 변경 | ❌ `read_only: true` + `--rm` (실행 후 자동 삭제) |
| 권한 상승 (sudo) | ❌ `cap_drop: ALL` + `no-new-privileges` |
| 호스트 Ollama 호출 | ✅ `host.docker.internal:11434` 만 |

즉, **명령마다 새 컨테이너** 가 떴다 사라지고, 호스트로 빠져나오는 건 출력 마크다운 한 개뿐입니다.

#### 1회 세팅

```bash
~/DEV/openclaw-workspace/scripts/surf-setup.sh
# - SURF_HOME (~/openclaw-surf) 생성
# - Playwright Docker 이미지 사전 pull (~700MB)
# - ~/bin/surf 런처
```

#### 옵션

| 옵션 | 효과 | 기본 |
|---|---|---|
| `--sources rss,naver,wikipedia` | 출처 선택. `url://https://...` 도 가능 | `rss,naver,wikipedia` |
| `--lang ko` / `--lang en` | RSS 피드와 위키 언어 | `ko` |
| `--max N` | 컨테이너가 모을 본문 수 상한 | `6` |
| `--out NAME.md` | 출력 파일명 (생략 시 자동 슬러그) | 자동 |
| `SURF_OPEN=1 surf ...` | 완료 후 `open` 으로 자동 열기 | `0` |

#### 환경변수 (compose.surf.yml 가 읽음)

| 변수 | 의미 |
|---|---|
| `SURF_HOME` | 결과 저장 위치 (기본 `~/openclaw-surf`) |
| `OLLAMA_TEXT_MODEL` | 요약 모델 (기본 `qwen2.5-coder:7b`) |

#### 일정 자동화 (cron / launchd)

```bash
# 평일 오전 9시 5분에 코스피·코스닥 브리프
crontab -e
5 9 * * 1-5 ~/bin/surf "오늘 코스피·코스닥 종가·거래대금" --out kospi-$(date +\%F).md
```

> 결과는 항상 `~/openclaw-surf/out/` 에 마크다운으로 떨어지므로 [Obsidian / Bear / Notes 자동 import](https://help.obsidian.md/Files+and+folders/Folder+structure) 에 그대로 연결됩니다.

#### `surf` 트러블슈팅

| 증상 | 대응 |
|---|---|
| `Ollama 데몬이 응답하지 않습니다` | Ollama 앱 실행 후 다시 |
| 첫 실행이 느림 | Playwright 이미지(~700MB) 첫 pull. 다음부턴 ~5초 |
| 출처 본문이 비어있음 | RSS 가 가장 안정적. `--sources rss` 만으로도 시도 |
| 결과가 너무 짧음 | `--max 8` 로 본문 더 모으기, 또는 `OLLAMA_TEXT_MODEL=qwen2.5:14b-instruct-q4_K_M` |
| Bot 차단(403/429) | `--sources rss,wikipedia` 또는 `url://` 로 직접 URL 지정 |


---

## 🇬🇧 English

### TL;DR

- OpenClaw blocks outbound internet by default (`isolated` mode).
- To pull live info, briefly switch to `online`, do the work, then lock back to `isolated`.
- Even in `online` mode, the host's files (`~/.ssh`, `~/Documents`), other LAN devices, and the container's persistent state remain protected (no mounts, `127.0.0.1`-only bind, `read_only: true`).
- For Korean stocks/news, RSS feeds and official APIs (KRX, BOK ECOS) are the most reliable.

### 1. Open the network → work → lock back (recommended cycle)

```bash
./openclaw network online --restart      # 1) allow internet
# In the OpenClaw UI: "today's S&P 500 close", "summarize NYT front page"
./openclaw network isolated --restart    # 2) lock again
./openclaw network status                # check current mode
```

> `./openclaw update` flips to `online` automatically and **restores the previous mode** afterward, so you can keep `isolated` as the default and updates still work.

### 2. Practical prompts — stocks · news · FX

#### 📈 Index close

```
Fetch today's S&P 500 and Nasdaq close, change, and dollar volume.
Render as a single Markdown table. Cite the source URL beneath the table.
```

#### 🗞 News headlines

```
Pull the top 5 headlines from BBC, Reuters, and AP RSS.
One-line summary in English per headline. Tag each with (source: ...).
```

#### 💱 FX / rates

```
USD vs EUR/JPY/KRW today vs yesterday (% change).
US 10y yield change in basis points.
Single table. If a value is missing, write "no data" — do not guess.
```

#### 📚 Paper summary

```
Fetch https://arxiv.org/abs/2310.06825 and produce:
- 5-sentence English summary
- 5-sentence Korean translation
```

### 3. Which sources work well

| Source | Reliability | Notes |
|---|---|---|
| Yahoo Finance | ⭐⭐⭐⭐ | Stable HTML, broad coverage |
| Reuters / BBC / AP RSS | ⭐⭐⭐⭐⭐ | RSS is by far the easiest |
| arxiv.org | ⭐⭐⭐⭐⭐ | API + abstract pages both work |
| FRED (St. Louis Fed) | ⭐⭐⭐⭐⭐ | Free API key, official macro data |
| Wikipedia | ⭐⭐⭐⭐⭐ | Stable, quotable |
| SPA dashboards (JS-only) | ⭐⭐ | HTML often empty until JS runs |
| Login-required sites | ❌ | Use the official API instead |

### 4. Using official API keys (optional)

```bash
# .env additions
echo 'FRED_API_KEY=...'   >> ~/DEV/openclaw-workspace/openclaw-mgr/.env
echo 'GOOGLE_CSE_ID=...'  >> ~/DEV/openclaw-workspace/openclaw-mgr/.env
echo 'GOOGLE_API_KEY=...' >> ~/DEV/openclaw-workspace/openclaw-mgr/.env
chmod 600 ~/DEV/openclaw-workspace/openclaw-mgr/.env
./openclaw stop && ./openclaw start
```

Then in your prompt: *"Use the FRED_API_KEY env var to fetch series GDP for the last 4 quarters."*

### 5. Safety patterns (must read)

| Risk | Mitigation |
|---|---|
| Indirect prompt injection from a malicious page | Prefer official APIs / RSS over arbitrary URLs; lock back to `isolated` immediately after work |
| Drive-by malware | Container is `read_only: true` and has no host mounts → cannot escape |
| API key leakage | `.env` perms `600`; encrypted backups via `OPENCLAW_BACKUP_GPG_RECIPIENT` |
| Hallucinated citations | Append *"Quote the actual fetched URL and snippet. If a value is missing, say 'no data' — do not guess."* |
| Disrespecting robots.txt | Use RSS / official APIs; avoid mass scraping |
| Mounting sensitive folders before going online | Never mount `~/.ssh`, `~/Documents`. Only an isolated dir like `~/Desktop/openclaw-share` |

#### One-shot internet session snippet

```bash
# ~/bin/openclaw-session-online — 5-minute window, auto-lock afterwards
./openclaw network online --restart
echo "🌐 online — auto-isolating in 5 minutes."
( sleep 300 && ./openclaw network isolated --restart ) &
disown
```

### 6. Automation — daily 9am KOSPI brief

```bash
# ~/bin/kospi-brief.sh
#!/usr/bin/env bash
set -euo pipefail
cd ~/DEV/openclaw-workspace
./openclaw network online --restart

PROMPT='Summarize today KOSPI / KOSDAQ close, change %, volume.
Single table + one-line comment. Cite source URLs.'

curl -s http://127.0.0.1:11434/api/generate -d "$(jq -n \
  --arg model 'qwen2.5-coder:7b' \
  --arg prompt "$PROMPT" \
  '{model:$model, prompt:$prompt, stream:false}')" | jq -r '.response' \
  > ~/Desktop/kospi-$(date +%F).md

./openclaw network isolated --restart
```

```bash
chmod +x ~/bin/kospi-brief.sh
crontab -e
# Weekdays 9am
0 9 * * 1-5 ~/bin/kospi-brief.sh
```

### 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Fetch still fails after `network online --restart` | DNS not propagated yet | Wait 30s, retry; or `docker compose restart` |
| "I cannot access live info" | Model unaware of `online` state | Prepend *"Internet access enabled. Fetch live data before answering."* to the prompt |
| HTML retrieved but body empty | JS-rendered SPA | Use RSS / official API, or add a Playwright-based headless fetcher |
| Result truncated | Context length exceeded | Use a larger-context model, or pre-cut HTML with `htmlq`/`pup` |
| Forgot to lock back to isolated | Human forgetfulness | Use the [one-shot session snippet](#one-shot-internet-session-snippet) |
| 403 / 429 from a site | Bot detection / rate limit | Switch to RSS; add `Mozilla/5.0` UA; otherwise abandon that source |

### 8. 🧪 Sandboxed auto-brief — the `surf` command

> One command → throwaway Docker container fetches and summarizes → Markdown brief on disk. The OpenClaw main container stays in `isolated` the whole time.

```bash
surf "today's KOSPI close and turnover"
surf "S&P 500 weekly recap" --lang en
surf "this week's IT headlines" --max 8
surf "summarize this paper" --sources url://https://arxiv.org/abs/2310.06825
```

**Sandbox guarantees** — every run spawns a fresh `mcr.microsoft.com/playwright/python` container with `read_only: true`, `cap_drop: ALL`, `no-new-privileges`, `tmpfs:/tmp`. Only `~/openclaw-surf/out` is mounted (read-write); `~/.ssh`, the OpenClaw `.env`, and the OpenClaw container are **not** touched. The container hits `host.docker.internal:11434` to reach the host Ollama, then is `--rm`'d.

**One-time setup:**

```bash
~/DEV/openclaw-workspace/scripts/surf-setup.sh    # pulls Playwright image, creates ~/bin/surf
```

**Options:** `--sources rss,naver,wikipedia,url://https://...` · `--lang ko|en` · `--max N` · `--out file.md` · env `SURF_OPEN=1` to auto-open.

**Cron example:**

```bash
5 9 * * 1-5 ~/bin/surf "today's KOSPI/KOSDAQ close and turnover" --out kospi-$(date +\%F).md
```

