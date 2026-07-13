#!/usr/bin/env python3
"""Generate the decorative room banners once, bake them into the asset catalog.

These images are ATMOSPHERE ONLY. They are never allowed to carry information a
player has to read: no tile faces a learner might trust, no card sections, no
text. A diffusion model cannot be trusted to draw a real 2 Crak, and a wrong
tile in a teaching app teaches the wrong thing. Anything informational stays in
`TileView` / `TileRackView`, which draw real tiles from real data.

Run it by hand when the art needs to change; the app never calls Pollinations.

    python3 scripts/generate_room_art.py [--force]
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "MahjTrainer" / "Assets.xcassets" / "RoomArt"

# One shared style so five separate generations still read as one set.
# Blank surfaces are a hard requirement, not a preference: a generated tile FACE
# is a wrong tile, and pseudo-glyph "decoration" is just garbled text. Say it
# several ways, because one way is not enough.
STYLE = (
    "flat vector illustration, elegant art deco, warm cream and ivory background, "
    "jade green and soft coral and muted gold palette, clean geometric shapes, "
    "smooth flat color, calm and inviting, minimal, "
    "all tiles completely blank and unmarked, plain undecorated surfaces, "
    "no text, no lettering, no numbers, no words, no symbols, no glyphs, "
    "no chinese characters, no patterns on the tiles, not a photograph"
)

ROOMS = {
    "room-tile-room": "a tidy row of plain blank mahjong tiles standing on a wooden rack, side view",
    "room-card-room": "a blank cream paper card propped on a small easel beside a teacup, flat vector illustration",
    "room-charleston-room": "three stylized hands passing blank tiles across a round table, sweeping motion arcs",
    "room-table-room": "four empty wooden mahjong racks around a green felt table, overhead view, empty table, no tiles",
    "room-pro-tables": "a pendant lamp glowing over a completely empty polished mahjong table at night, nothing on the table, deep jade and gold, plain undecorated walls",
}

WIDTH, HEIGHT = 1024, 512
# What actually ships: a 2x banner for a ~390pt-wide card. Anything bigger is
# bundle weight nobody sees.
OUT_WIDTH = 800


def generate(name: str, subject: str, force: bool, seed_offset: int = 0) -> None:
    imageset = ASSETS / f"{name}.imageset"
    jpg = imageset / f"{name}.jpg"
    if jpg.exists() and not force:
        print(f"  {name}: already present, skipping (use --force to redo)")
        return

    imageset.mkdir(parents=True, exist_ok=True)
    prompt = urllib.parse.quote(f"{subject}, {STYLE}")
    # Fixed seed: same prompt, same picture, so a rerun is reproducible.
    seed = (sum(ord(c) for c in name) * 977 + seed_offset) % 100_000
    url = (
        f"https://image.pollinations.ai/prompt/{prompt}"
        f"?width={WIDTH}&height={HEIGHT}&seed={seed}&nologo=true&model=flux"
    )
    print(f"  {name}: generating...")
    raw = imageset / "_raw.png"
    # Pollinations 403s the default urllib agent.
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=300) as response:
        raw.write_bytes(response.read())

    subprocess.run(
        ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "78",
         "-Z", str(OUT_WIDTH), str(raw), "--out", str(jpg)],
        check=True, capture_output=True,
    )
    raw.unlink()

    contents = {
        "images": [{"filename": jpg.name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print(f"  {name}: {jpg.stat().st_size // 1024} KB")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="regenerate images that already exist")
    parser.add_argument("--only", nargs="*", help="asset names to (re)generate, e.g. room-card-room")
    parser.add_argument("--seed-offset", type=int, default=0, help="reroll the same prompt")
    args = parser.parse_args()

    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n"
    )
    print(f"Room art -> {ASSETS.relative_to(REPO)}")
    for name, subject in ROOMS.items():
        if args.only and name not in args.only:
            continue
        generate(name, subject, args.force or bool(args.only), args.seed_offset)
    return 0


if __name__ == "__main__":
    sys.exit(main())
