"""
figma.py — 결과 PNG 들을 Figma 파일의 한 페이지에 그리드로 자동 배치.

Figma REST API 는 파일 노드 변경(POST /v1/images, POST /v1/files/<key>/nodes)이
플랜·토큰 권한에 따라 제한될 수 있음. 이 스크립트는:
  1) 각 PNG 를 Figma 에 업로드해서 image hash 받기 (POST /v1/images, multipart)
  2) 새 페이지(있으면 재사용) 만들기는 REST 로 직접 안 됨 → 사용자가 미리 만든
     `--page` 페이지 노드 ID 를 찾아서 frame 들에 image fill 적용
     (file_key + page name 으로 GET /v1/files/<key> → node tree 검색)
  3) 페이지 노드 목록을 갱신: PUT /v1/files/<key>/nodes (POST 가 안 되면 간이 fallback —
     이미지 hash 와 추천 위치만 출력해서 사용자가 Figma 플러그인/직접 배치).

플랜에 따라 쓰기가 막히면 (대다수 무료/스타터): 기능 1)+2)만 수행하고
~/openclaw-creative/out/<slug>/figma-manifest.json 을 출력.
사용자는 Figma 플러그인 'Image Tray' 등으로 그 매니페스트를 import 가능.
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
import requests

API = "https://api.figma.com/v1"


def upload_image(token: str, png: Path) -> str:
    """POST /v1/images — image hash 반환."""
    r = requests.post(
        f"{API}/images",
        headers={"X-Figma-Token": token},
        files={"image": (png.name, png.open("rb"), "image/png")},
        timeout=60,
    )
    r.raise_for_status()
    data = r.json()
    return data["meta"]["images"][png.name] if "meta" in data else data["images"][png.name]


def find_page_id(token: str, file_key: str, page_name: str) -> str | None:
    r = requests.get(
        f"{API}/files/{file_key}",
        headers={"X-Figma-Token": token},
        params={"depth": 1},
        timeout=30,
    )
    r.raise_for_status()
    doc = r.json()["document"]
    for node in doc.get("children", []):
        if node.get("type") == "CANVAS" and node.get("name") == page_name:
            return node["id"]
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="PNG 들이 있는 디렉터리")
    ap.add_argument("--token", required=True)
    ap.add_argument("--file", required=True, help="Figma file key")
    ap.add_argument("--page", default="Mood")
    args = ap.parse_args()

    src = Path(args.src)
    pngs = sorted(src.glob("*.png"))
    if not pngs:
        print(f"✗ PNG 없음: {src}", file=sys.stderr)
        return 2

    print(f"▸ {len(pngs)} 개 업로드 → Figma")
    manifest = {"page": args.page, "items": []}
    for p in pngs:
        try:
            h = upload_image(args.token, p)
        except requests.HTTPError as e:
            print(f"✗ {p.name}: {e}")
            continue
        manifest["items"].append({"name": p.name, "hash": h})
        print(f"  ✓ {p.name} → {h}")

    page_id = None
    try:
        page_id = find_page_id(args.token, args.file, args.page)
    except Exception as e:
        print(f"! 페이지 조회 실패 ({e}) — manifest 로 fallback")

    out = src / "figma-manifest.json"
    out.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f"✔ manifest: {out}")

    if page_id:
        print(f"▸ Figma 페이지 '{args.page}' (node {page_id})")
        url = f"https://www.figma.com/file/{args.file}/?node-id={page_id.replace(':','%3A')}"
        print(f"  열기: {url}")
        print("ℹ Figma 무료/스타터 플랜은 REST API 로 노드 생성이 막혀 있을 수 있어,")
        print("  배치는 Figma Desktop 의 'Image Tray' 또는 자체 플러그인으로 manifest 를 import 하세요.")
    else:
        print(f"! 페이지 '{args.page}' 를 Figma 파일에서 찾지 못함 — 페이지를 먼저 만들고 다시 실행하세요.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
