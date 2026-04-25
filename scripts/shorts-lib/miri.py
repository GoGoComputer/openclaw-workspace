"""
miri.py — 미리캔버스 GUI 자동화 (Playwright, 영구 프로필 miri-1)

구조:
    shorts miri-login          → 사람이 1회 로그인 후 창 닫기
    shorts miri "키워드"        → 1080×1920 새 디자인에 refs/<slug>/* 업로드 + 그리드 배치
                                 결과 PNG 를 out/<slug>/miri.png 로 다운로드

⚠️ 주의: 미리캔버스 UI 셀렉터는 자주 바뀝니다.
   - 처음 돌릴 때 SHORTS_HEADED=1 로 창을 띄워 확인하세요.
   - 셀렉터가 안 잡히면 본 파일 SEL_* 값을 DevTools 로 보정하세요.
"""
from __future__ import annotations
import argparse, asyncio, os, sys
from pathlib import Path

from playwright.async_api import async_playwright, BrowserContext, Page

SHORTS_HOME = Path(os.environ["SHORTS_HOME"])
PROFILE_DIR = SHORTS_HOME / "profiles" / "miri-1"
MIRI_URL    = os.environ.get("MIRI_URL", "https://www.miricanvas.com/ko")
HEADED      = os.environ.get("SHORTS_HEADED", "0") == "1"
TIMEOUT     = int(os.environ.get("SHORTS_TIMEOUT", "45000"))
CANVAS_W    = int(os.environ.get("MIRI_CANVAS_W", "1080"))
CANVAS_H    = int(os.environ.get("MIRI_CANVAS_H", "1920"))

# ── 셀렉터 (UI 변경 시 여기만 수정) ─────────────────────────────────────────
SEL_NEW_DESIGN_BTN = "a:has-text('새 디자인'), button:has-text('새 디자인')"
SEL_CUSTOM_SIZE    = "button:has-text('직접 입력'), button:has-text('사용자 지정')"
SEL_WIDTH_INPUT    = "input[placeholder*='가로'], input[name*='width']"
SEL_HEIGHT_INPUT   = "input[placeholder*='세로'], input[name*='height']"
SEL_CREATE_BTN     = "button:has-text('만들기'), button:has-text('생성')"
SEL_UPLOAD_TAB     = "button:has-text('업로드'), [data-tab*='upload']"
SEL_UPLOAD_INPUT   = "input[type='file']"
SEL_DOWNLOAD_BTN   = "button:has-text('다운로드'), a:has-text('다운로드')"
SEL_PNG_OPTION     = "label:has-text('PNG'), button:has-text('PNG')"
SEL_DOWNLOAD_FINAL = "button:has-text('빠른 다운로드'), button:has-text('다운로드 시작')"


async def open_ctx(pw) -> BrowserContext:
    PROFILE_DIR.mkdir(parents=True, exist_ok=True)
    return await pw.chromium.launch_persistent_context(
        user_data_dir=str(PROFILE_DIR),
        headless=not HEADED,
        viewport={"width": 1440, "height": 900},
        accept_downloads=True,
        args=["--disable-blink-features=AutomationControlled"],
    )


async def cmd_login() -> int:
    print("▸ 미리캔버스 로그인 창을 엽니다. 카카오/구글/이메일로 로그인 후 창을 닫으세요.")
    async with async_playwright() as pw:
        ctx = await open_ctx(pw)
        page = await ctx.new_page()
        await page.goto(MIRI_URL)
        # 사람이 로그인 끝낼 때까지 대기 (창 닫으면 close 이벤트)
        ev = asyncio.Event()
        page.on("close", lambda *_: ev.set())
        await ev.wait()
        await ctx.close()
    print("✔ 세션 저장됨 (profiles/miri-1)")
    return 0


async def cmd_run(slug: str, refs_dir: Path) -> int:
    out_dir = SHORTS_HOME / "out" / slug
    out_dir.mkdir(parents=True, exist_ok=True)

    pngs = sorted([p for p in refs_dir.rglob("*")
                   if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}])
    if not pngs:
        print(f"✗ refs 가 비어있음: {refs_dir} — 먼저 'shorts refs' 실행", file=sys.stderr)
        return 2
    pngs = pngs[:12]
    print(f"▸ 미리캔버스: {len(pngs)} 이미지 업로드 → {CANVAS_W}×{CANVAS_H}")

    async with async_playwright() as pw:
        ctx = await open_ctx(pw)
        page = await ctx.new_page()
        page.set_default_timeout(TIMEOUT)
        await page.goto(MIRI_URL, wait_until="domcontentloaded")

        # 1) 새 디자인 (사용자 지정 1080x1920)
        try:
            await page.locator(SEL_NEW_DESIGN_BTN).first.click()
            await page.locator(SEL_CUSTOM_SIZE).first.click()
            await page.locator(SEL_WIDTH_INPUT).first.fill(str(CANVAS_W))
            await page.locator(SEL_HEIGHT_INPUT).first.fill(str(CANVAS_H))
            await page.locator(SEL_CREATE_BTN).first.click()
        except Exception as e:
            print(f"  ! '새 디자인' UI 미감지 — 이미 에디터일 수 있음 ({e})")

        await page.wait_for_load_state("networkidle")

        # 2) 업로드 탭 → 파일 선택
        try:
            await page.locator(SEL_UPLOAD_TAB).first.click()
        except Exception:
            pass
        file_inputs = page.locator(SEL_UPLOAD_INPUT)
        if await file_inputs.count() == 0:
            print("✗ 업로드 input[type=file] 미발견 — 미리캔버스 UI 변경 가능. SHORTS_HEADED=1 로 확인하세요.", file=sys.stderr)
            await ctx.close()
            return 3
        await file_inputs.first.set_input_files([str(p) for p in pngs])
        print("  ⏳ 업로드 진행 중…")
        await page.wait_for_timeout(8000)

        # 3) PNG 다운로드 (요청대로 그리드/배치는 미리캔버스 자체 UI 이용 권장)
        # 자동 배치는 미리캔버스 좌표 API 비공개라 신뢰성 낮음. 사용자가 헤드모드에서 한번 정렬 후 닫기.
        try:
            async with page.expect_download(timeout=60000) as dl_ctx:
                await page.locator(SEL_DOWNLOAD_BTN).first.click()
                try:
                    await page.locator(SEL_PNG_OPTION).first.click()
                except Exception:
                    pass
                await page.locator(SEL_DOWNLOAD_FINAL).first.click()
            dl = await dl_ctx.value
            target = out_dir / "miri.png"
            await dl.save_as(str(target))
            print(f"✔ {target}")
        except Exception as e:
            print(f"  ! 자동 다운로드 실패 — 헤드모드(SHORTS_HEADED=1)에서 직접 다운로드 후 {out_dir}/miri.png 로 저장하세요: {e}")

        await ctx.close()

    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("login")
    r = sub.add_parser("run")
    r.add_argument("--slug", required=True)
    r.add_argument("--refs", required=True)
    args = ap.parse_args()

    if args.cmd == "login":
        return asyncio.run(cmd_login())
    return asyncio.run(cmd_run(args.slug, Path(args.refs)))


if __name__ == "__main__":
    sys.exit(main())
