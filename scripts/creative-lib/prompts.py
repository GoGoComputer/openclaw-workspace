"""
prompts.py — Pinterest 레퍼런스를 비전 모델로 분석하고 변주 프롬프트 N개를 생성.

입력: ~/openclaw-creative/refs/<slug>/*.jpg + 키워드
출력: ~/openclaw-creative/prompts/<slug>.jsonl  ({"id":..,"prompt":..} 줄 단위)

Ollama 가 호스트 127.0.0.1:11434 에 떠 있어야 함. 모델은 사전 pull 되어 있어야 함:
    ollama pull qwen2.5vl:7b
    ollama pull qwen2.5-coder:7b
"""
from __future__ import annotations
import argparse, base64, json, sys, time
from pathlib import Path
import requests

OLLAMA = "http://127.0.0.1:11434"


def vlm_describe(model: str, images: list[Path]) -> str:
    """비전 모델에 참고 이미지들을 보여주고 공통 분위기·팔레트·구도 추출."""
    encoded = []
    for p in images[:6]:  # 토큰 절약을 위해 최대 6장
        encoded.append(base64.b64encode(p.read_bytes()).decode())
    system = (
        "You are an art director. Look at the provided reference images and "
        "extract the common visual DNA: subject, composition, lens/angle, "
        "lighting, colour palette (3-5 hex), mood, materials, time of day. "
        "Reply in compact bullet points, English, no preamble."
    )
    r = requests.post(
        f"{OLLAMA}/api/chat",
        json={
            "model": model,
            "stream": False,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": "Common visual DNA across these references:", "images": encoded},
            ],
        },
        timeout=180,
    )
    r.raise_for_status()
    return r.json()["message"]["content"].strip()


def expand_prompts(model: str, keyword: str, dna: str, n: int) -> list[str]:
    """텍스트 모델에 DNA + 키워드 → N개 변주 프롬프트."""
    system = (
        "You write image-generation prompts for Gemini 2.5 Flash Image (a.k.a. "
        "nano-banana). Each prompt must be 1 line, English, ~40-70 words, "
        "include: subject, composition, lens/angle, lighting, colour palette, "
        "atmosphere, key details, photographic style. Use the supplied visual DNA "
        "as the shared style anchor; vary subject angle, time, secondary elements. "
        "Output exactly N prompts, no numbering, no extra text — one prompt per line."
    )
    user = f"Keyword: {keyword}\nVisual DNA:\n{dna}\nN = {n}"
    r = requests.post(
        f"{OLLAMA}/api/chat",
        json={
            "model": model,
            "stream": False,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "options": {"temperature": 0.9},
        },
        timeout=180,
    )
    r.raise_for_status()
    text = r.json()["message"]["content"].strip()
    lines = [ln.strip(" -•\t") for ln in text.splitlines() if ln.strip()]
    # 너무 적게 나오면 빈 슬롯 채움
    while len(lines) < n:
        lines.append(f"{keyword}, variation {len(lines)+1}, {dna.splitlines()[0] if dna else ''}")
    return lines[:n]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--slug", required=True)
    ap.add_argument("--keyword", required=True)
    ap.add_argument("--variations", type=int, default=12)
    ap.add_argument("--vlm-model", default="qwen2.5vl:7b")
    ap.add_argument("--text-model", default="qwen2.5-coder:7b")
    ap.add_argument("--refs-dir", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    refs = sorted(Path(args.refs_dir).glob("*"))
    refs = [p for p in refs if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp")]

    if refs:
        print(f"▸ VLM ({args.vlm_model}) describing {len(refs)} refs ...")
        t0 = time.time()
        try:
            dna = vlm_describe(args.vlm_model, refs)
        except Exception as e:
            print(f"! VLM 실패 ({e}) — 키워드만으로 계속")
            dna = ""
        print(f"  DNA ({time.time()-t0:.1f}s):\n{dna[:500]}{'...' if len(dna)>500 else ''}")
    else:
        print("! 참고 이미지 없음 — 키워드만으로 진행")
        dna = ""

    print(f"▸ TEXT ({args.text_model}) → {args.variations} prompts ...")
    prompts = expand_prompts(args.text_model, args.keyword, dna, args.variations)

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as f:
        for i, p in enumerate(prompts, 1):
            f.write(json.dumps({"id": f"{i:02d}", "prompt": p}, ensure_ascii=False) + "\n")
    print(f"✔ {out} — {len(prompts)} prompts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
