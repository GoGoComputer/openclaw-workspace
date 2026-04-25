"""
surf.py — 샌드박스 컨테이너 안에서 실행되는 웹 브리프 생성기.

흐름:
  1) QUERY 와 SOURCES 환경변수에 따라 Playwright 로 다음에서 페이지 수집:
       - rss        : 연합뉴스·한겨레·구글뉴스 RSS (한국어), Reuters/BBC (영어)
       - naver      : finance.naver.com 의 시세/뉴스 (코스피 등 키워드 포함 시)
       - wikipedia  : 한·영 위키 검색 결과
       - URL 직접 입력은 SOURCES=url://https://...,url://... 형태로
  2) 수집한 본문 텍스트를 토큰 줄여서 호스트 Ollama 에 보냄.
  3) Ollama 가 한국어/영어 마크다운 브리프 생성.
  4) /work/out/<OUT_FILE> 로 저장.

이 스크립트는 read-only 루트 + tmpfs 환경에서 동작합니다.
"""
from __future__ import annotations
import asyncio, datetime as dt, json, os, re, sys, urllib.parse
from html import unescape
from pathlib import Path
from typing import Iterable

import requests
from playwright.async_api import async_playwright, Browser, Page

OLLAMA_HOST  = os.environ.get("OLLAMA_HOST", "http://host.docker.internal:11434")
TEXT_MODEL   = os.environ.get("OLLAMA_TEXT_MODEL", "qwen2.5-coder:7b")
QUERY        = os.environ.get("QUERY", "").strip()
SOURCES      = [s.strip() for s in os.environ.get("SOURCES", "rss,naver,wikipedia").split(",") if s.strip()]
MAX_PAGES    = int(os.environ.get("MAX_PAGES", "6"))
LANG         = os.environ.get("LANG", "ko")
OUT_FILE     = Path(os.environ.get("OUT_FILE", "/work/out/brief.md"))

if not QUERY:
    print("✗ QUERY 환경변수 필요", file=sys.stderr)
    sys.exit(2)


# ── 작은 유틸 ────────────────────────────────────────────────────────────────
def strip_html(s: str) -> str:
    s = re.sub(r"<script.*?</script>", "", s, flags=re.S | re.I)
    s = re.sub(r"<style.*?</style>", "", s, flags=re.S | re.I)
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", unescape(s)).strip()
    return s


def trim(s: str, n: int) -> str:
    return s if len(s) <= n else s[:n] + " …"


# ── RSS 처리 ─────────────────────────────────────────────────────────────────
RSS_FEEDS = {
    "ko": [
        ("연합뉴스",        "https://www.yna.co.kr/rss/news.xml"),
        ("한겨레",          "https://www.hani.co.kr/rss/"),
        ("구글뉴스(한국)",   "https://news.google.com/rss?hl=ko&gl=KR&ceid=KR:ko"),
    ],
    "en": [
        ("Reuters",  "https://feeds.reuters.com/reuters/topNews"),
        ("BBC",      "https://feeds.bbci.co.uk/news/rss.xml"),
        ("Google News", "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"),
    ],
}


def fetch_rss_items(query: str, lang: str, limit: int) -> list[dict]:
    items: list[dict] = []
    for source, url in RSS_FEEDS.get(lang, RSS_FEEDS["ko"]):
        try:
            r = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})
            r.raise_for_status()
            xml = r.text
        except Exception as e:
            print(f"  ! RSS {source} 실패: {e}")
            continue
        # 매우 단순한 파서 (의존성 추가 회피)
        for m in re.finditer(r"<item>(.*?)</item>", xml, flags=re.S | re.I):
            block = m.group(1)
            title = strip_html(re.search(r"<title>(.*?)</title>", block, flags=re.S | re.I).group(1)) if re.search(r"<title>", block, flags=re.I) else ""
            link  = (re.search(r"<link>(.*?)</link>", block, flags=re.S | re.I) or [None, ""])
            link  = strip_html(link.group(1)) if hasattr(link, "group") else ""
            desc  = re.search(r"<description>(.*?)</description>", block, flags=re.S | re.I)
            desc  = strip_html(desc.group(1)) if desc else ""
            text  = f"{title}. {desc}"
            if query.lower() in text.lower() or query in text:
                items.append({"source": source, "title": title, "link": link, "text": text})
            if len(items) >= limit:
                return items
    # 키워드 매치가 너무 적으면 상위 N개 무조건 채움
    if len(items) < limit:
        for source, url in RSS_FEEDS.get(lang, RSS_FEEDS["ko"]):
            try:
                r = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
                xml = r.text
            except Exception:
                continue
            for m in re.finditer(r"<item>(.*?)</item>", xml, flags=re.S | re.I):
                block = m.group(1)
                t = re.search(r"<title>(.*?)</title>", block, flags=re.S | re.I)
                l = re.search(r"<link>(.*?)</link>", block, flags=re.S | re.I)
                d = re.search(r"<description>(.*?)</description>", block, flags=re.S | re.I)
                if not t: continue
                items.append({
                    "source": source,
                    "title": strip_html(t.group(1)),
                    "link": strip_html(l.group(1)) if l else "",
                    "text": strip_html(t.group(1)) + ". " + (strip_html(d.group(1)) if d else "")
                })
                if len(items) >= limit:
                    return items
    return items[:limit]


# ── Playwright 로 본문 수집 ──────────────────────────────────────────────────
async def fetch_page(browser: Browser, url: str, timeout_ms: int = 20_000) -> str:
    ctx = await browser.new_context(user_agent="Mozilla/5.0 (compatible; OpenClawSurf/0.1)")
    page = await ctx.new_page()
    try:
        await page.goto(url, wait_until="domcontentloaded", timeout=timeout_ms)
        # JS 렌더링 잠깐 대기
        await page.wait_for_timeout(800)
        body = await page.locator("body").inner_text(timeout=5_000)
    except Exception as e:
        body = f"[fetch failed: {e}]"
    finally:
        await ctx.close()
    return trim(body.strip(), 6000)


async def fetch_naver(query: str, browser: Browser, limit: int) -> list[dict]:
    """네이버 통합검색 결과 + finance.naver.com (코스피 등) 자동 포함."""
    items: list[dict] = []
    q = urllib.parse.quote(query)
    urls = [f"https://search.naver.com/search.naver?query={q}"]
    if any(k in query for k in ("코스피", "kospi", "KOSPI", "코스닥", "KOSDAQ")):
        urls.insert(0, "https://finance.naver.com/sise/")
    for u in urls[:limit]:
        text = await fetch_page(browser, u)
        items.append({"source": "Naver", "title": query, "link": u, "text": text})
    return items


async def fetch_wikipedia(query: str, browser: Browser, lang: str) -> list[dict]:
    code = "ko" if lang == "ko" else "en"
    url = f"https://{code}.wikipedia.org/wiki/Special:Search?search={urllib.parse.quote(query)}&go=Go"
    text = await fetch_page(browser, url)
    return [{"source": f"Wikipedia({code})", "title": query, "link": url, "text": text}]


async def fetch_url(browser: Browser, url: str) -> dict:
    text = await fetch_page(browser, url)
    return {"source": "URL", "title": url, "link": url, "text": text}


# ── Ollama 에 마크다운 브리프 요청 ───────────────────────────────────────────
def write_brief(query: str, lang: str, sources: list[dict]) -> str:
    sys_prompt_ko = (
        "당신은 능숙한 리서치 어시스턴트입니다. 사용자의 질문에 대해 아래 출처들의 본문을 "
        "참고하여 한국어 마크다운 브리프를 작성하세요. 형식:\n"
        "  # <제목>\n  > 한 줄 요약\n  ## 핵심 포인트 (3~6개 불릿)\n"
        "  ## 자세히 (분석/숫자/표가 있으면 표로)\n  ## 출처 (각 항목의 URL)\n"
        "정보가 본문에서 분명하지 않으면 '본문에서 확인되지 않음' 이라고 솔직히 적으세요. "
        "추측·환각 금지."
    )
    sys_prompt_en = (
        "You are a competent research assistant. Using the source bodies below, write a "
        "concise English Markdown brief: # title, > one-line TL;DR, ## Key points (3-6 bullets), "
        "## Detail, ## Sources (URLs). If a fact is not present in the bodies, write "
        "'not in source'. Do not invent numbers."
    )
    sys_prompt = sys_prompt_ko if lang == "ko" else sys_prompt_en

    user = [f"질문 / question: {query}\n", "출처 본문 / sources:\n"]
    for i, s in enumerate(sources, 1):
        user.append(f"[{i}] {s['source']} — {s['title']}\nURL: {s['link']}\n본문 발췌:\n{trim(s['text'], 4000)}\n")
    user_text = "\n".join(user)

    print(f"▸ Ollama({TEXT_MODEL}) → 브리프 생성 (입력 ~{len(user_text)//4} tokens)")
    r = requests.post(
        f"{OLLAMA_HOST}/api/chat",
        json={
            "model": TEXT_MODEL,
            "stream": False,
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user",   "content": user_text},
            ],
            "options": {"temperature": 0.4},
        },
        timeout=300,
    )
    r.raise_for_status()
    return r.json()["message"]["content"].strip()


# ── 메인 ─────────────────────────────────────────────────────────────────────
async def main() -> int:
    print(f"== surf: '{QUERY}' (sources={SOURCES}, lang={LANG}, max={MAX_PAGES}) ==")

    items: list[dict] = []
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True, args=["--no-sandbox"])
        try:
            for src in SOURCES:
                if src == "rss":
                    print("▸ RSS 수집")
                    items.extend(fetch_rss_items(QUERY, LANG, limit=MAX_PAGES))
                elif src == "naver":
                    print("▸ 네이버 검색/금융")
                    items.extend(await fetch_naver(QUERY, browser, limit=2))
                elif src == "wikipedia":
                    print("▸ 위키피디아")
                    items.extend(await fetch_wikipedia(QUERY, browser, LANG))
                elif src.startswith("url://"):
                    url = src[len("url://"):]
                    print(f"▸ URL: {url}")
                    items.append(await fetch_url(browser, url))
                else:
                    print(f"  ! unknown source: {src}")
        finally:
            await browser.close()

    if not items:
        print("✗ 수집된 본문이 없음", file=sys.stderr)
        return 1

    # 너무 많이 모이면 상위만
    items = items[:MAX_PAGES]

    print(f"▸ {len(items)} 개 본문 수집 완료")

    md = write_brief(QUERY, LANG, items)
    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    header = (
        f"<!--\n"
        f"  surf brief\n"
        f"  query    : {QUERY}\n"
        f"  language : {LANG}\n"
        f"  sources  : {','.join(s['source'] for s in items)}\n"
        f"  generated: {dt.datetime.now().isoformat(timespec='seconds')}\n"
        f"  model    : {TEXT_MODEL}\n"
        f"-->\n\n"
    )
    OUT_FILE.write_text(header + md + "\n", encoding="utf-8")
    print(f"✔ {OUT_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
