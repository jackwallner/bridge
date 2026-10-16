#!/usr/bin/env python3
"""Composite raw Android captures into Google Play screenshots and the feature graphic.

Cream frame in the Bridge Trainer palette (Bridge/Utilities/Theme.swift light
values): serif headline, room-accent eyebrow and rule, faint spade watermark.
Play wants 1080x1920 portrait screenshots (nothing longer than 2:1, and the
raw 1080x2400 emulator captures are 2.22:1) plus a 1024x500 feature graphic.
Reads android/play-assets/raw/ and writes android/play-assets/screenshots/ and
android/play-assets/feature-graphic.png.

Usage: python3 scripts/play_screenshot_compositor.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "android" / "play-assets" / "raw"
OUT = ROOT / "android" / "play-assets" / "screenshots"
FEATURE = ROOT / "android" / "play-assets" / "feature-graphic.png"
ICON = ROOT / "android" / "play-assets" / "icon-512.png"

CREAM = (247, 241, 230)
CREAM_DEEP = (240, 231, 214)
INK = (41, 36, 31)
INK_SECONDARY = (97, 89, 79)
JADE = (23, 107, 92)
CORAL = (219, 107, 79)
GOLD = (194, 145, 46)
PLUM = (122, 71, 133)

NEWYORK = "/System/Library/Fonts/NewYork.ttf"
SFNS = "/System/Library/Fonts/SFNS.ttf"
WATERMARK_GLYPH = "♠"

W, H = 1080, 1920
TOP = 84
EYEBROW = 26
HEADLINE = 74
LINE = 88
RULE_Y = TOP + 60 + 2 * LINE + 18
SHOT_TOP = RULE_Y + 44
SHOT_H = H - SHOT_TOP - 48
SHOT_W = round(SHOT_H * 1080 / 2400)
CORNER = 56


@dataclass
class Shot:
    raw: str
    out: str
    eyebrow: str
    headline: str
    accent: tuple


SHOTS = [
    Shot("01-quicksession.png", "01_quick_session.png", "FIVE MINUTES", "A short round of bridge practice", JADE),
    Shot("02-opening.png", "02_opening.png", "THE AUCTION ROOM", "Count the points, pick your opening", CORAL),
    Shot("03-leadorhold.png", "03_lead_or_hold.png", "THE DEFENSE ROOM", "Lead or hold? Learn the why", GOLD),
    Shot("04-declarer.png", "04_declarer.png", "THE DECLARER ROOM", "Choose the card that wins tricks", PLUM),
    Shot("05-home.png", "05_home.png", "BRIDGE TRAINER", "Four rooms from first hand to table", JADE),
    Shot("06-auctionroom.png", "06_auction_room.png", "THE AUCTION ROOM", "Drills for every opening call", CORAL),
]


def font(path: str, size: int, weight: str) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def rounded_mask(size: tuple, radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask


def wrap(text: str, face: ImageFont.FreeTypeFont, max_width: int, draw: ImageDraw.ImageDraw) -> list[str]:
    lines: list[str] = []
    current: list[str] = []
    for word in text.split():
        trial = " ".join(current + [word])
        if draw.textlength(trial, font=face) <= max_width or not current:
            current.append(word)
        else:
            lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines


def background(accent: tuple, size: tuple) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size, CREAM)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / height
        draw.line([(0, y), (width, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(CREAM, CREAM_DEEP)))
    glow = Image.new("RGBA", (1400, 1400), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([(0, 0), (1400, 1400)], fill=(*accent, 22))
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    img.paste(glow, (width // 2 - 700, -560), glow)
    mark = Image.new("RGBA", (520, 560), (0, 0, 0, 0))
    ImageDraw.Draw(mark).text((0, -30), WATERMARK_GLYPH, font=ImageFont.truetype(SFNS, 480), fill=(*accent, 14))
    mark = mark.rotate(-8, expand=True, resample=Image.BICUBIC)
    img.paste(mark, (width - mark.width + 70, height - mark.height + 50), mark)
    return img


def render(shot: Shot) -> Path:
    canvas = background(shot.accent, (W, H))
    draw = ImageDraw.Draw(canvas, "RGBA")
    eyebrow_font = font(SFNS, EYEBROW, "Heavy")
    spaced = " ".join(shot.eyebrow)
    eb_w = draw.textlength(spaced, font=eyebrow_font)
    eb_x = (W - eb_w) / 2
    for dot_x in (eb_x - 20, eb_x + eb_w + 20):
        draw.ellipse([(dot_x - 4, TOP + 10), (dot_x + 4, TOP + 18)], fill=(*shot.accent, 200))
    draw.text((eb_x, TOP), spaced, font=eyebrow_font, fill=(*shot.accent, 235))

    face = font(NEWYORK, HEADLINE, "Bold")
    lines = wrap(shot.headline, face, W - 180, draw)
    if len(lines) > 2:
        raise ValueError(f"{shot.headline!r} wraps to {len(lines)} lines")
    top = TOP + 60 + (2 - len(lines)) * LINE / 2
    for i, line in enumerate(lines):
        draw.text(((W - draw.textlength(line, font=face)) / 2, top + i * LINE), line, font=face, fill=INK)
    draw.rounded_rectangle([(W / 2 - 44, RULE_Y), (W / 2 + 44, RULE_Y + 5)], radius=3, fill=shot.accent)

    raw = Image.open(RAW / shot.raw).convert("RGB")
    if raw.size != (1080, 2400):
        raise ValueError(f"{shot.raw} is {raw.size}, expected 1080x2400")
    scaled = raw.resize((SHOT_W, SHOT_H), Image.LANCZOS)
    left = (W - SHOT_W) // 2
    shadow = Image.new("RGBA", (SHOT_W + 100, SHOT_H + 100), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([(50, 62), (50 + SHOT_W, 62 + SHOT_H)], radius=CORNER, fill=(20, 16, 12, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(shadow, (left - 50, SHOT_TOP - 50), shadow)
    canvas.paste(scaled, (left, SHOT_TOP), rounded_mask((SHOT_W, SHOT_H), CORNER))
    ImageDraw.Draw(canvas, "RGBA").rounded_rectangle(
        [(left, SHOT_TOP), (left + SHOT_W, SHOT_TOP + SHOT_H)], radius=CORNER, outline=(*shot.accent, 130), width=3)

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / shot.out
    canvas.save(path, "PNG")
    return path


def feature_graphic() -> Path:
    canvas = background(CORAL, (1024, 500))
    draw = ImageDraw.Draw(canvas, "RGBA")
    icon = Image.open(ICON).convert("RGB").resize((260, 260), Image.LANCZOS)
    canvas.paste(icon, (70, 120), rounded_mask((260, 260), 58))
    draw.text((380, 150), "Bridge Trainer", font=font(NEWYORK, 64, "Bold"), fill=INK)
    draw.rounded_rectangle([(384, 262), (464, 267)], radius=3, fill=CORAL)
    tagline = font(SFNS, 34, "Semibold")
    draw.text((382, 290), "Bid, declare and defend", font=tagline, fill=INK_SECONDARY)
    draw.text((382, 334), "one short drill at a time", font=tagline, fill=INK_SECONDARY)
    canvas.save(FEATURE, "PNG")
    return FEATURE


def main() -> None:
    for shot in SHOTS:
        path = render(shot)
        print(f"wrote {path.relative_to(ROOT)} {Image.open(path).size}")
    path = feature_graphic()
    print(f"wrote {path.relative_to(ROOT)} {Image.open(path).size}")


if __name__ == "__main__":
    main()
