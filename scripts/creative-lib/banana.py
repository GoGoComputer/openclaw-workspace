"""
banana.py — Gemini 웹(나노바나나) 을 N개 영구 프로필로 병렬 자동화.

부작용/한계:
- Gemini ToS 의 "automated means" 회색지대. 본인 계정·소량만 권장.
- 캡차나 차단 신호가 보이면 즉시 종료.
- 동시 창은 4개 이하 권장.

사용:
  python banana.py login --profiles-dir <dir> --url https://gemini.google.com/app
  python banana.py run --jobs <jsonl> --out <png-dir> --profiles-dir <dir> \
                       --windows 4 --rate-limit 25 --retries 2 --timeout 90
"""
from __future__ import annotations
import argparse, asyncio, json, sys, time, random
from pathlib import Path

# Playwright 는 venv 에 설치되어 있어야 함.
from playwright.async_api import async_playwright, Page, BrowserContext, TimeoutError as PWTimeout


# 셀렉터는 Gemini UI 변화에 취약하므로 환경변수로 override 가능하게.
SEL_PROMPT_INPUT = "div[contenteditable='true'][role='textbox']"
SEL_SEND_BUTTON  = "button[aria-label*='Send'], button[aria-label*='보내기']"
SEL_RESULT_IMG   = "img[src^='data:image'], img[src*='lh3.googleusercontent.com'][alt]"
SEL_CAPTCHA      = "iframe[src*='recaptcha'], div:has-text('automated activity'), div:has-text('자동화')"


# ── login ────────────────────────────────────────────────────────────────────
async def cmd_login(profiles_dir: Path, url: str, n: int = 4) -> int:
    """N개 영구 프로필을 차례로 띄워 사용자가 로그인하도록."""
    async with async_playwright() as pw:
        for i in range(1, n + 1):
            prof = profiles_dir / f"banana-{i}"
            prof.mkdir(parents=True, exist_ok=True)
            print(f"▸ banana-{i} 창 — Gemini 에 로그인 후 창을 닫으세요 (다음 창이 뜸)")
            ctx = await pw.chromium.launch_persistent_context(
                str(prof), headless=False, viewport={"width": 1280, "height": 900}
            )
            page = await ctx.new_page()
            await page.goto(url, wait_until="domcontentloaded")
            try:
                await page.wait_for_event("close", timeout=0)
            finally:
                await ctx.close()
    print("✔ 모든 프로필 로그인 세션 저장됨.")
    return 0


# ── 한 워커가 한 작업 처리 ──────────────────────────────────────────────────
async def run_one_job(page: Page, prompt: str, out_path: Path, timeout_s: int) -> bool:
    # 캡차 확인
    if await page.locator(SEL_CAPTCHA).count() > 0:
        raise RuntimeError("CAPTCHA / automation block detected — stopping")

    # 입력창 찾기
    box = page.locator(SEL_PROMPT_INPUT).first
    await box.wait_for(state="visible", timeout=10_000)
    await box.click()
    await box.fill("")  # 초기화
    # 이미지 의도를 명시 (Gemini 는 자동 라우팅하지만 안전하게)
    full = f"Generate an image: {prompt}"
    await box.type(full, delay=8)

    send = page.locator(SEL_SEND_BUTTON).first
    await send.click()

    # 응답 이미지 대기. 첫 1~3초간 로딩 인디케이터 후 img 등장.
    deadline = time.time() + timeout_s
    img_locator = page.locator(SEL_RESULT_IMG).last
    while time.time() < deadline:
        try:
            await img_locator.wait_for(state="visible", timeout=5_000)
            src = await img_locator.get_attribute("src")
            if not src:
                continue
            # data: URI 또는 https → 다운로드
            if src.startswith("data:image"):
                import base64, re
                m = re.match(r"data:image/(?P<ext>\w+);base64,(?P<b64>.+)", src)
                if m:
                    out_path.write_bytes(base64.b64decode(m.group("b64")))
                    return True
            else:
                # 외부 URL — context.request 로 다운로드 (쿠키 공유)
                resp = await page.context.request.get(src)
                out_path.write_bytes(await resp.body())
                return True
        except PWTimeout:
            # 캡차 다시 확인
            if await page.locator(SEL_CAPTCHA).count() > 0:
                raise RuntimeError("CAPTCHA appeared mid-job — stopping")
            continue
    return False


# ── 워커 (창 1개) ────────────────────────────────────────────────────────────
async def worker(idx: int, profile_dir: Path, url: str, headless: bool,
                 queue: asyncio.Queue, out_dir: Path, rate_limit: int,
                 retries: int, timeout_s: int) -> dict:
    stats = {"idx": idx, "done": 0, "fail": 0}
    async with async_playwright() as pw:
        ctx: BrowserContext = await pw.chromium.launch_persistent_context(
            str(profile_dir),
            headless=headless,
            viewport={"width": 1280, "height": 900},
        )
        page = (ctx.pages[0] if ctx.pages else await ctx.new_page())
        await page.goto(url, wait_until="domcontentloaded")
        # "automated activity" 페이지면 즉시 중단
        if await page.locator(SEL_CAPTCHA).count() > 0:
            print(f"[banana-{idx}] ✗ blocked at start — stopping this worker")
            await ctx.close()
            return stats

        last_send = 0.0
        while True:
            try:
                job = queue.get_nowait()
            except asyncio.QueueEmpty:
                break
            jid = job["id"]
            prompt = job["prompt"]
            out_file = out_dir / f"{jid}.png"
            if out_file.exists():
                print(f"[banana-{idx}] {jid} ⤳ skip (exists)")
                stats["done"] += 1
                queue.task_done()
                continue

            wait = max(0.0, last_send + rate_limit - time.time())
            if wait > 0:
                await asyncio.sleep(wait + random.uniform(0, 1.5))

            attempt = 0
            ok = False
            t0 = time.time()
            while attempt <= retries and not ok:
                attempt += 1
                try:
                    ok = await run_one_job(page, prompt, out_file, timeout_s)
                    if not ok and attempt <= retries:
                        print(f"[banana-{idx}] {jid} ⟳ retry {attempt}")
                        # 새 채팅으로
                        await page.goto(url, wait_until="domcontentloaded")
                except RuntimeError as e:
                    print(f"[banana-{idx}] ✗ {e}")
                    queue.task_done()
                    await ctx.close()
                    return stats
                except Exception as e:
                    print(f"[banana-{idx}] {jid} 예외: {e}")
                    if attempt <= retries:
                        await page.goto(url, wait_until="domcontentloaded")
            last_send = time.time()
            elapsed = time.time() - t0
            if ok:
                print(f"[banana-{idx}] {jid} ✓ {out_file}  ({elapsed:.1f}s)")
                stats["done"] += 1
            else:
                print(f"[banana-{idx}] {jid} ✗ giving up")
                stats["fail"] += 1
            queue.task_done()

        await ctx.close()
    return stats


# ── run ──────────────────────────────────────────────────────────────────────
async def cmd_run(args) -> int:
    jobs_path = Path(args.jobs)
    out_dir   = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    queue: asyncio.Queue = asyncio.Queue()
    with jobs_path.open() as f:
        for line in f:
            line = line.strip()
            if not line: continue
            queue.put_nowait(json.loads(line))
    total = queue.qsize()
    print(f"▸ {total} jobs, {args.windows} windows, rate {args.rate_limit}s")

    profiles_dir = Path(args.profiles_dir)
    workers = []
    for i in range(1, args.windows + 1):
        prof = profiles_dir / f"banana-{i}"
        if not prof.exists():
            print(f"✗ {prof} 없음 — `creative banana-login` 먼저", file=sys.stderr)
            return 2
        workers.append(worker(
            idx=i, profile_dir=prof, url=args.url,
            headless=not args.headed,
            queue=queue, out_dir=out_dir,
            rate_limit=args.rate_limit, retries=args.retries,
            timeout_s=args.timeout,
        ))
    results = await asyncio.gather(*workers, return_exceptions=True)
    done = sum(r["done"] for r in results if isinstance(r, dict))
    fail = sum(r["fail"] for r in results if isinstance(r, dict))
    print(f"\n=== 완료: {done}/{total} 성공, {fail} 실패 → {out_dir}")
    return 0 if fail == 0 else 1


# ── main ─────────────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    pl = sub.add_parser("login")
    pl.add_argument("--profiles-dir", required=True)
    pl.add_argument("--url", default="https://gemini.google.com/app")

    pr = sub.add_parser("run")
    pr.add_argument("--jobs", required=True)
    pr.add_argument("--out", required=True)
    pr.add_argument("--profiles-dir", required=True)
    pr.add_argument("--url", default="https://gemini.google.com/app")
    pr.add_argument("--windows", type=int, default=4)
    pr.add_argument("--rate-limit", type=int, default=25)
    pr.add_argument("--retries", type=int, default=2)
    pr.add_argument("--timeout", type=int, default=90)
    pr.add_argument("--headed", action="store_true")

    args = ap.parse_args()
    if args.cmd == "login":
        return asyncio.run(cmd_login(Path(args.profiles_dir), args.url))
    if args.cmd == "run":
        return asyncio.run(cmd_run(args))
    return 2


if __name__ == "__main__":
    sys.exit(main())
