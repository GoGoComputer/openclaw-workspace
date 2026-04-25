"""
figma_gui.py — Figma 웹/Desktop UI 를 Playwright 로 직접 조작.

영구 프로필(~/openclaw-creative/profiles/figma-1) 에 한 번 로그인하면 다음부터 자동.
나노바나나와 같은 패턴 — 사람이 클릭하듯 화면을 그대로 컨트롤.

명령:
  python figma_gui.py login --profiles-dir <dir>
  python figma_gui.py place --profiles-dir <dir> --file-key <key> --page <name> \
                            --src <png-dir> [--cols 4] [--gap 40] [--headed]

주의: Figma UI 셀렉터는 변경될 수 있음. 실패하면 --headed 로 진단.
"""
from __future__ import annotations
import argparse, asyncio, sys, time
from pathlib import Path

from playwright.async_api import async_playwright, Page, TimeoutError as PWTimeout


FIGMA_FILE_URL = "https://www.figma.com/file/{key}/"


# ── 로그인 ───────────────────────────────────────────────────────────────────
async def cmd_login(profiles_dir: Path) -> int:
    prof = profiles_dir / "figma-1"
    prof.mkdir(parents=True, exist_ok=True)
    print(f"▸ figma-1 창 — Figma 에 로그인 후 창을 닫으세요")
    async with async_playwright() as pw:
        ctx = await pw.chromium.launch_persistent_context(
            str(prof), headless=False, viewport={"width": 1440, "height": 900}
        )
        page = await ctx.new_page()
        await page.goto("https://www.figma.com/login", wait_until="domcontentloaded")
        try:
            await page.wait_for_event("close", timeout=0)
        finally:
            await ctx.close()
    print("✔ figma-1 세션 저장됨.")
    return 0


# ── 페이지 보장: 없으면 생성 ─────────────────────────────────────────────────
async def ensure_page(page: Page, page_name: str) -> None:
    """좌측 페이지 패널에서 page_name 페이지가 없으면 생성하고 활성화."""
    # 좌측 패널 펼치기
    try:
        toggle = page.get_by_role("button", name="Pages")
        if await toggle.count() > 0:
            await toggle.first.click(timeout=2000)
    except Exception:
        pass

    # 기존 페이지 항목 클릭 시도
    item = page.get_by_role("treeitem", name=page_name).first
    if await item.count() > 0:
        await item.click()
        return

    # 없음 → "+" 버튼으로 새 페이지 추가
    add_btn = page.get_by_role("button", name="Add page").first
    if await add_btn.count() == 0:
        # 일부 UI 에서는 "Create new page"
        add_btn = page.get_by_role("button", name="Create new page").first
    await add_btn.click()
    # 이름 입력
    await page.keyboard.type(page_name, delay=20)
    await page.keyboard.press("Enter")
    await page.wait_for_timeout(800)


# ── 캔버스에 이미지 배치 ─────────────────────────────────────────────────────
async def place_images(page: Page, pngs: list[Path], cols: int, gap: int) -> int:
    """⌘⇧K (Place image) → 파일 일괄 선택 → 캔버스에 그리드 배치."""
    placed = 0

    # 캔버스 영역의 박스 좌표
    canvas = page.locator("canvas").first
    await canvas.wait_for(state="visible", timeout=15_000)
    box = await canvas.bounding_box()
    if box is None:
        raise RuntimeError("canvas bounding box 를 찾지 못함")

    # 좌상단 시작점 (캔버스 안 약간 안쪽)
    x0, y0 = box["x"] + 80, box["y"] + 80
    # 가정: 이미지를 1024×1024 로 받아오므로 화면 표시 시 이 정도 크기
    cell_w, cell_h = 320, 320

    # 줌 100% 로 리셋
    await page.keyboard.press("Shift+1")  # Zoom to fit (실수로 zoom 100%인 ⌘0와 다름)
    await page.keyboard.press("Meta+0")   # Zoom 100%
    await page.wait_for_timeout(300)

    for idx, png in enumerate(pngs):
        col = idx % cols
        row = idx // cols
        cx = x0 + col * (cell_w + gap)
        cy = y0 + row * (cell_h + gap)

        # 캔버스 클릭으로 포커스
        await page.mouse.click(cx, cy)
        await page.wait_for_timeout(100)

        # ⌘⇧K → 파일 선택 다이얼로그
        async with page.expect_file_chooser(timeout=15_000) as fc_info:
            await page.keyboard.press("Meta+Shift+K")
        chooser = await fc_info.value
        await chooser.set_files(str(png))

        # Place image 모드: 마우스를 따라다님. 좌표 클릭으로 떨어뜨림
        await page.wait_for_timeout(700)  # 이미지 로드 대기
        await page.mouse.click(cx, cy)
        await page.wait_for_timeout(300)
        placed += 1
        print(f"  ✓ {png.name} → ({col},{row})")

    return placed


# ── place 메인 ───────────────────────────────────────────────────────────────
async def cmd_place(args) -> int:
    profiles_dir = Path(args.profiles_dir)
    prof = profiles_dir / "figma-1"
    if not prof.exists() or not any(prof.iterdir()):
        print("✗ figma-1 프로필이 비었음 — `creative figma-login` 먼저", file=sys.stderr)
        return 2

    src = Path(args.src)
    pngs = sorted(src.glob("*.png"))
    if not pngs:
        print(f"✗ PNG 없음: {src}", file=sys.stderr)
        return 2

    url = FIGMA_FILE_URL.format(key=args.file_key)
    print(f"▸ Figma 열기: {url}")

    async with async_playwright() as pw:
        ctx = await pw.chromium.launch_persistent_context(
            str(prof),
            headless=not args.headed,
            viewport={"width": 1440, "height": 900},
        )
        page = ctx.pages[0] if ctx.pages else await ctx.new_page()
        await page.goto(url, wait_until="domcontentloaded")

        # Figma 가 완전히 로드될 때까지 (캔버스 등장)
        try:
            await page.locator("canvas").first.wait_for(state="visible", timeout=30_000)
        except PWTimeout:
            print("✗ Figma 캔버스가 30초 안에 뜨지 않음 — 로그인 만료 가능성", file=sys.stderr)
            await ctx.close()
            return 1

        # 페이지 보장
        try:
            await ensure_page(page, args.page)
        except Exception as e:
            print(f"! 페이지 '{args.page}' 처리 실패 ({e}) — 현재 페이지에 배치합니다")

        # 배치
        try:
            n = await place_images(page, pngs, cols=args.cols, gap=args.gap)
            print(f"✔ {n}/{len(pngs)} 배치 완료 → {url}")
        except Exception as e:
            print(f"✗ 배치 중 오류: {e}", file=sys.stderr)
            await ctx.close()
            return 1

        # 자동 저장은 Figma 가 알아서 함. 닫기.
        await page.wait_for_timeout(2000)
        await ctx.close()
    return 0


# ── main ─────────────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    pl = sub.add_parser("login")
    pl.add_argument("--profiles-dir", required=True)

    pp = sub.add_parser("place")
    pp.add_argument("--profiles-dir", required=True)
    pp.add_argument("--file-key", required=True)
    pp.add_argument("--page", default="Mood")
    pp.add_argument("--src", required=True)
    pp.add_argument("--cols", type=int, default=4)
    pp.add_argument("--gap", type=int, default=40)
    pp.add_argument("--headed", action="store_true")

    args = ap.parse_args()
    if args.cmd == "login":
        return asyncio.run(cmd_login(Path(args.profiles_dir)))
    if args.cmd == "place":
        return asyncio.run(cmd_place(args))
    return 2


if __name__ == "__main__":
    sys.exit(main())
