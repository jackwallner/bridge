#!/usr/bin/env python3
"""Composite raw simulator captures into on-brand App Store screenshots.

Reads the raw 1320x2868 6.9" captures in scripts/screenshot_raw/, draws a
warm cream + jade frame matching MahjTrainer/Utilities/Theme.swift (serif
display headline, room-accent eyebrow + rule, faint "麻" watermark), and
writes finals to fastlane/screenshots/en-US/ at exactly 1320x2868 using
fastlane naming (01_....png ... 06_....png).

Usage: python3 scripts/appstore_screenshot_compositor.py
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "scripts" / "screenshot_raw"
OUT_DIR = ROOT / "fastlane" / "screenshots" / "en-US"

CANVAS_W, CANVAS_H = 1320, 2868

# MARK: - Theme (mirrors MahjTrainer/Utilities/Theme.swift light-mode values)

CREAM = (247, 241, 230)
CREAM_DEEP = (240, 231, 214)  # bottom-of-gradient tone, same hue family
CARD = (255, 252, 246)
RULE = (219, 209, 191)
INK = (41, 36, 31)
INK_SECONDARY = (112, 102, 92)

JADE = (23, 107, 92)
CORAL = (219, 107, 79)
GOLD = (194, 145, 46)
PLUM = (122, 71, 133)

NEWYORK = "/System/Library/Fonts/NewYork.ttf"
SFNS = "/System/Library/Fonts/SFNS.ttf"
CJK = "/System/Library/Fonts/Hiragino Sans GB.ttc"

WATERMARK_GLYPH = "麻"  # same glyph MahjCardFace uses


def serif(size: int, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(NEWYORK, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def sans(size: int, weight: str = "Semibold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(SFNS, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def cjk_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(CJK, size)


@dataclass
class Shot:
    raw: str
    out: str
    eyebrow: str
    headline: str
    accent: tuple


SHOTS = [
    Shot(
        raw="01-quicksession.png",
        out="01_quick_session.png",
        eyebrow="GET STARTED",
        headline="Practice between games",
        accent=JADE,
    ),
    Shot(
        raw="02-handmatch.png",
        out="02_hand_match.png",
        eyebrow="THE CARD ROOM",
        headline="Read the rack, name the section",
        accent=CORAL,
    ),
    Shot(
        raw="03-keepthrow.png",
        out="03_keep_or_throw.png",
        eyebrow="THE TABLE ROOM",
        headline="Make the call, learn the why",
        accent=GOLD,
    ),
    Shot(
        raw="04-charleston.png",
        out="04_charleston.png",
        eyebrow="THE CHARLESTON ROOM",
        headline="Beat Charleston nerves",
        accent=PLUM,
    ),
    Shot(
        raw="05-home.png",
        out="05_home.png",
        eyebrow="MAHJ TRAINER",
        headline="Five minutes a day. It sticks.",
        accent=JADE,
    ),
    Shot(
        raw="06-tileroom.png",
        out="06_tile_room.png",
        eyebrow="THE TILE ROOM",
        headline="Meet every tile",
        accent=JADE,
    ),
]

# MARK: - Layout

TOP_MARGIN = 118
EYEBROW_SIZE = 32
HEADLINE_SIZE = 96
HEADLINE_LINE_HEIGHT = 112
HEADLINE_MAX_WIDTH = CANVAS_W - 2 * 130
HEADLINE_MAX_LINES = 2  # every headline in SHOTS wraps to <= 2 lines at this size

# The headline block always reserves space for HEADLINE_MAX_LINES so the rule
# and screenshot land in the same place regardless of a given headline's
# actual line count (1-line headlines are vertically centered in the slot).
_HEADLINE_TOP = TOP_MARGIN + 74
_HEADLINE_BLOCK_BOTTOM = _HEADLINE_TOP + HEADLINE_MAX_LINES * HEADLINE_LINE_HEIGHT
_RULE_Y = _HEADLINE_BLOCK_BOTTOM + 22

BOTTOM_MARGIN = 64
SCREENSHOT_TOP = _RULE_Y + 6 + 46
SCREENSHOT_CORNER = 72
SCREENSHOT_BORDER = 3
SCREENSHOT_H = CANVAS_H - BOTTOM_MARGIN - SCREENSHOT_TOP
SCREENSHOT_W = round(SCREENSHOT_H * (1320 / 2868))
SIDE_MARGIN = (CANVAS_W - SCREENSHOT_W) // 2


def rounded_mask(size: tuple, radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask


def wrap_headline(text: str, font: ImageFont.FreeTypeFont, max_width: int, draw: ImageDraw.ImageDraw) -> list:
    words = text.split()
    lines, current = [], []
    for word in words:
        trial = " ".join(current + [word])
        if draw.textlength(trial, font=font) <= max_width or not current:
            current.append(word)
        else:
            lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines


def draw_background(img: Image.Image, accent: tuple) -> None:
    """Warm cream vertical gradient + a faint room-accent glow behind the
    headline zone, plus the mahjong-card watermark glyph bottom-right."""
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(CANVAS_H):
        t = y / CANVAS_H
        r = round(CREAM[0] + (CREAM_DEEP[0] - CREAM[0]) * t)
        g = round(CREAM[1] + (CREAM_DEEP[1] - CREAM[1]) * t)
        b = round(CREAM[2] + (CREAM_DEEP[2] - CREAM[2]) * t)
        draw.line([(0, y), (CANVAS_W, y)], fill=(r, g, b))

    # Soft accent glow centered on the headline zone.
    glow_r = 900
    glow = Image.new("RGBA", (glow_r * 2, glow_r * 2), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([(0, 0), (glow_r * 2, glow_r * 2)], fill=(*accent, 22))
    glow = glow.filter(ImageFilter.GaussianBlur(180))
    img.paste(glow, (CANVAS_W // 2 - glow_r, TOP_MARGIN - glow_r + 140), glow)

    # Watermark glyph, bottom-right, very faint.
    watermark_size = 620
    wm_font = cjk_font(watermark_size)
    wm_layer = Image.new("RGBA", (watermark_size + 80, watermark_size + 80), (0, 0, 0, 0))
    wdraw = ImageDraw.Draw(wm_layer)
    wdraw.text((0, -40), WATERMARK_GLYPH, font=wm_font, fill=(*accent, 14))
    wm_layer = wm_layer.rotate(-8, expand=True, resample=Image.BICUBIC)
    img.paste(wm_layer, (CANVAS_W - wm_layer.width + 90, CANVAS_H - wm_layer.height + 60), wm_layer)


def render(shot: Shot) -> Path:
    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), CREAM)
    draw_background(canvas, shot.accent)
    draw = ImageDraw.Draw(canvas, "RGBA")

    # Eyebrow (small-caps room label, tracked, accent color) with frame dots
    eyebrow_font = sans(EYEBROW_SIZE, "Heavy")
    tracked = f"  {shot.eyebrow}  "
    # Manual letter-spacing since Pillow has no native tracking.
    spaced = (" ").join(list(shot.eyebrow))
    eb_w = draw.textlength(spaced, font=eyebrow_font)
    eb_x = (CANVAS_W - eb_w) / 2
    eb_y = TOP_MARGIN
    dot_gap = 22
    dot_r = 4
    draw.ellipse(
        [(eb_x - dot_gap - dot_r, eb_y + EYEBROW_SIZE * 0.55 - dot_r),
         (eb_x - dot_gap + dot_r, eb_y + EYEBROW_SIZE * 0.55 + dot_r)],
        fill=(*shot.accent, 200),
    )
    draw.ellipse(
        [(eb_x + eb_w + dot_gap - dot_r, eb_y + EYEBROW_SIZE * 0.55 - dot_r),
         (eb_x + eb_w + dot_gap + dot_r, eb_y + EYEBROW_SIZE * 0.55 + dot_r)],
        fill=(*shot.accent, 200),
    )
    draw.text((eb_x, eb_y), spaced, font=eyebrow_font, fill=(*shot.accent, 235))

    # Headline: serif display, up to HEADLINE_MAX_LINES lines, centered, and
    # vertically centered within the fixed-height headline slot so the rule
    # and screenshot below always land in the same place.
    headline_font = serif(HEADLINE_SIZE, "Bold")
    lines = wrap_headline(shot.headline, headline_font, HEADLINE_MAX_WIDTH, draw)
    slot_lines = HEADLINE_MAX_LINES
    y_offset = (slot_lines - len(lines)) * HEADLINE_LINE_HEIGHT / 2
    headline_top = _HEADLINE_TOP + y_offset
    for i, line in enumerate(lines):
        w = draw.textlength(line, font=headline_font)
        x = (CANVAS_W - w) / 2
        y = headline_top + i * HEADLINE_LINE_HEIGHT
        draw.text((x, y), line, font=headline_font, fill=INK)

    # Accent rule under the headline (fixed position, independent of line count).
    rule_y = _RULE_Y
    rule_w = 108
    draw.rounded_rectangle(
        [(CANVAS_W / 2 - rule_w / 2, rule_y), (CANVAS_W / 2 + rule_w / 2, rule_y + 6)],
        radius=3,
        fill=shot.accent,
    )

    # Screenshot: rounded corners, soft shadow, hairline + accent edge.
    raw_path = RAW_DIR / shot.raw
    raw_img = Image.open(raw_path).convert("RGB")
    if raw_img.size != (1320, 2868):
        raise ValueError(f"{raw_path} is {raw_img.size}, expected 1320x2868")
    scaled = raw_img.resize((SCREENSHOT_W, SCREENSHOT_H), Image.LANCZOS)

    shadow_pad = 60
    shadow = Image.new("RGBA", (SCREENSHOT_W + shadow_pad * 2, SCREENSHOT_H + shadow_pad * 2), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [(shadow_pad, shadow_pad + 14), (shadow_pad + SCREENSHOT_W, shadow_pad + 14 + SCREENSHOT_H)],
        radius=SCREENSHOT_CORNER,
        fill=(20, 16, 12, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    canvas.paste(shadow, (SIDE_MARGIN - shadow_pad, SCREENSHOT_TOP - shadow_pad), shadow)

    mask = rounded_mask((SCREENSHOT_W, SCREENSHOT_H), SCREENSHOT_CORNER)
    canvas.paste(scaled, (SIDE_MARGIN, SCREENSHOT_TOP), mask)

    draw2 = ImageDraw.Draw(canvas, "RGBA")
    draw2.rounded_rectangle(
        [(SIDE_MARGIN, SCREENSHOT_TOP), (SIDE_MARGIN + SCREENSHOT_W, SCREENSHOT_TOP + SCREENSHOT_H)],
        radius=SCREENSHOT_CORNER,
        outline=(*shot.accent, 130),
        width=SCREENSHOT_BORDER,
    )
    draw2.rounded_rectangle(
        [(SIDE_MARGIN - 8, SCREENSHOT_TOP - 8),
         (SIDE_MARGIN + SCREENSHOT_W + 8, SCREENSHOT_TOP + SCREENSHOT_H + 8)],
        radius=SCREENSHOT_CORNER + 8,
        outline=(*RULE, 160),
        width=1,
    )

    out_path = OUT_DIR / shot.out
    canvas.save(out_path, "PNG")
    assert canvas.size == (CANVAS_W, CANVAS_H)
    return out_path


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for shot in SHOTS:
        path = render(shot)
        print(f"wrote {path} ({Image.open(path).size})")


if __name__ == "__main__":
    main()
