"""
capcut.py — CapCut Web (https://www.capcut.com/editor) GUI 자동화

흐름:
  shorts capcut-login         → 1회 로그인 후 창 닫기
  shorts capcut "키워드"       → refs(또는 miri.png) 업로드 → 슬라이드쇼 생성 → 1080p MP4 export

⚠️ CapCut Web UI 셀렉터는 변경 빈도가 매우 높습니다.
   첫 실행은 SHORTS_HEADED=1 로 띄우고 단계마다 이상 없는지 확인하세요.

CapCut Desktop 을 선호하면:
  https://www.capcut.com/ko-kr/tools/desktop-video-editor 에서 .dmg 다운로드 →
  Applications 로 드래그. Desktop 앱은 GUI 자동화가 더 까다로우니
  본 스크립트는 Web 에디터를 기준으로 동작합니다.
"""
from __future__ import annotations
import argparse, asyncio, os, sys
from pathlib import Path

from playwright.async_api import async_playwright, BrowserContext

SHORTS_HOME = Path(os.environ["SHORTS_HOME"])
PROFILE_DIR = SHORTS_HOME / "profiles" / "capcut-1"
CAPCUT_URL  = os.environ.get("CAPCUT_URL", "https://www.capcut.com/editor")
HEADED      = os.environ.get("SHORTS_HEADED", "0") == "1"
TIMEOUT     = int(os.environ.get("SHORTS_TIMEOUT", "45000"))
RES         = os.environ.get("CAPCUT_RES", "1080p")
FPS         = os.environ.get("CAPCUT_FPS", "30")

# ── 셀렉터 (UI 변경 시 여기만 수정) ────────────────────────────────────────
SEL_NEW_PROJECT  = "button:has-text('새 프로젝트'), button:has-text('New project')"
SEL_RATIO_9_16   = "button:has-text('9:16'), [data-ratio='9_16']"
SEL_UPLOAD_TAB   = "button:has-text('미디어'), button:has-text('Media'), [data-panel='media']"
SEL_UPLOAD_INPUT = "input[type='file']"
SEL_EXPORT_BTN   = "button:has-text('내보내기'), button:has-text('Export')"
SEL_RES_SELECT   = "button:has-text('해상도'), button:has-text('Resolution')"
SEL_RES_1080P    = "li:has-text('1080p'), button:has-text('1080p')"
SEL_EXPORT_GO    = "button:has-text('내보내기'):not([disabled]), button:has-text('Export'):not([disabled])"
SEL_DOWNLOAD     = "button:has-text('다운로드'), a:has-text('다운로드'), button:has-text('Download')"


async def open_ctx(pw) -> BrowserContext:
    PROFILE_DIR.mkdir(parents=True, exist_ok=True)
    return await pw.chromium.launch_persistent_context(
        user_data_dir=str(PROFILE_DIR),
        headless=not HEADED,
        viewport={"width": 1600, "height": 1000},
        accept_downloads=True,
        args=["--disable-blink-features=AutomationControlled"],
    )


async def cmd_login() -> int:
    print("▸ CapCut 로그인 창을 엽니다. TikTok/Google/이메일로 로그인 후 창을 닫으세요.")
    async with async_playwright() as pw:
        ctx = await open_ctx(pw)
        page = await ctx.new_page()
        await page.goto("https://www.capcut.com/login")
        ev = asyncio.Event()
        page.on("close", lambda *_: ev.set())
        await ev.wait()
        await ctx.close()
    print("✔ 세션 저장됨 (profiles/capcut-1)")
    return 0


async def cmd_run(slug: str, refs_dir: Path) -> int:
    out_dir = SHORTS_HOME / "out" / slug
    out_dir.mkdir(parents=True, exist_ok=True)

    # 입력 후보: miri.png(있으면 우선) + refs 이미지들
    candidates: list[Path] = []
    miri_png = out_dir / "miri.png"
    if miri_png.exists():
        candidates.append(miri_png)
    candidates.extend(sorted([p for p in refs_dir.rglob("*")
                              if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}]))
    candidates = candidates[:15]
    if not candidates:
        print(f"✗ 업로드할 이미지가 없음 ({refs_dir})", file=sys.stderr)
        return 2
    print(f"▸ CapCut Web: {len(candidates)} 클립 업로드 → 9:16 / {RES}")

    async with async_playwright() as pw:
        ctx = await open_ctx(pw)
        page = await ctx.new_page()
        page.set_default_timeout(TIMEOUT)
        await page.goto(CAPCUT_URL, wait_until="domcontentloaded")
        await page.wait_for_load_state("networkidle")

        # 1) 새 프로젝트 (가능하면 9:16)
        try:
            await page.locator(SEL_NEW_PROJECT).first.click(timeout=10000)
        except Exception:
            print("  ! '새 프로젝트' 미발견 — 이미 편집 화면일 수 있음")
        try:
            await page.locator(SEL_RATIO_9_16).first.click(timeout=4000)
        except Exception:
            print("  ! 9:16 비율 버튼 미발견 — 편집 화면에서 수동 설정 필요할 수 있음")

        await page.wait_for_load_state("networkidle")

        # 2) 미디어 업로드
        try:
            await page.locator(SEL_UPLOAD_TAB).first.click(timeout=8000)
        except Exception:
            pass
        file_inputs = page.locator(SEL_UPLOAD_INPUT)
        if await file_inputs.count() == 0:
            print("✗ 업로드 input 미발견 — SHORTS_HEADED=1 로 확인.", file=sys.stderr)
            await ctx.close()
            return 3
        await file_inputs.first.set_input_files([str(p) for p in candidates])
        print("  ⏳ 업로드/임포트 대기 (대용량이면 길어질 수 있음)…")
        await page.wait_for_timeout(15000)

        # 3) 타임라인 자동 배치는 CapCut Web 의 비공개 좌표 API 의존이라 신뢰도 낮음.
        # 권장 흐름: 업로드만 자동, 사용자가 헤드모드에서 드래그 후 'Export' 만 자동.
        # 자동 export 시도 →
        try:
            await page.locator(SEL_EXPORT_BTN).first.click(timeout=8000)
            try:
                await page.locator(SEL_RES_SELECT).first.click(timeout=4000)
                await page.locator(SEL_RES_1080P).first.click(timeout=4000)
            except Exception:
                pass
            async with page.expect_download(timeout=600_000) as dl_ctx:
                await page.locator(SEL_EXPORT_GO).last.click()
                try:
                    await page.locator(SEL_DOWNLOAD).first.click(timeout=300_000)
                except Exception:
                    pass
            dl = await dl_ctx.value
            target = out_dir / "shorts.mp4"
            await dl.save_as(str(target))
            print(f"✔ {target}")
        except Exception as e:
            print(f"  ! 자동 export 실패 — SHORTS_HEADED=1 로 띄워서 사람이 마무리 후 {out_dir}/shorts.mp4 로 저장: {e}")

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
