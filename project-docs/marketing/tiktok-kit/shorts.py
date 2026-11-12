#!/usr/bin/env python3
"""Twenty animated Bridge lesson shorts on the Mahj shorts engine.

    ~/.cache/pelojack-tts/bin/python shorts.py V1 [out.mp4] [--still t1,t2,...] [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts.py captions [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts.py check       # recount every hand shown, V9 to V20

V1 to V8 are the first lessons. V9 to V14 are "what do you open?" quizzes on hands that pass a Python port of
HandGenerator.opening(); V15 to V20 are beginner lessons (Stayman, support points, the 1-level response, counting
losers, leading partner's suit, second hand low).

The engine (~/ios/growth/animated-shorts-2026-10-27/render.py, with the lesson helpers in
~/ios/growth/tiktok-2026-10-29/kit.py) paints each scene with a watercolour pass, speaks the
lines with Kokoro, captions them word by word and adds a score. This file loads this kit's
build_kit first, so the engine draws Bridge felt, icon and captures; cards are this kit's drawn cards,
laid on top crisp after the paint pass. It swaps in a Bridge-only music bed (E-flat swing at 104 BPM with plucked
bass, electric piano and brushes, where Mahj's is F-major sine pads) and does its blurs locally so a frame
renders in a fraction of the time; V1 to V8 come out pixel for pixel as before.
"""
from __future__ import annotations

import functools
import math
import pathlib
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import signal

import build_kit as B

if not pathlib.Path(B.FONT).exists():  # Linux render box: the same two fonts, copied beside the home folder
    B.FONT, B.SERIF = (str(pathlib.Path.home() / ".fonts-mahj" / f) for f in ("SFNS.ttf", "NewYork.ttf"))
if not B.ICON.exists():  # the icon lives in this repo
    B.ICON = pathlib.Path(__file__).resolve().parents[3] / "Bridge/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(pathlib.Path.home() / "ios/growth/tiktok-2026-10-29"))
B.cloth = B.felt  # the engine's end card and backgrounds read K.cloth
import kit  # noqa: E402
from kit import GOLD, GREEN, OUT, RED, bell, seg, wave  # noqa: E402

R = kit.R
CREAM, INK = R.CREAM, R.INK
CH = 1.42  # card height per width
OUTDIR = B.ICLOUD / "Animated shorts"


# ---------------------------------------------------------------- pieces

@functools.cache
def bg(seed: int) -> Image.Image:
    im = B.felt(seed).copy()
    R.glow(im, 540, 860, 900, (255, 240, 210), 0.12)
    return im


@functools.cache
def back(width: int) -> Image.Image:
    h = int(width * CH)
    im = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, width - 1, h - 1), int(width * 0.12), fill=(255, 253, 248))
    m = max(6, width // 12)
    d.rounded_rectangle((m, m, width - 1 - m, h - 1 - m), int(width * 0.08), fill=(26, 104, 88))
    d.rounded_rectangle((m * 2, m * 2, width - 1 - m * 2, h - 1 - m * 2), int(width * 0.06),
                        outline=(214, 190, 120), width=max(2, width // 40))
    return im


@functools.cache
def sprite(code: str, width: int) -> Image.Image:
    """A card ('AS', 'TH', or 'BACK') with its own soft shadow."""
    face = back(width) if code == "BACK" else B.card(code[0], code[1], width)
    pad = 24
    out = Image.new("RGBA", (face.width + 2 * pad, face.height + 2 * pad), (0, 0, 0, 0))
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0))
    sh.paste((10, 20, 16, 120), (pad, pad + 8), face.getchannel("A"))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(9)))
    out.alpha_composite(face, (pad, pad))
    return out


def put(layer, code: str, x: float, y: float, w: int, angle: float = 0.0, alpha: float = 1.0,
        scale: float = 1.0, dim: float = 0.0) -> None:
    if alpha <= 0.01:
        return
    s = sprite(code, max(8, int(w * scale)))
    if dim > 0:
        s = s.copy()
        rgb = Image.blend(s.convert("RGB"), Image.new("RGB", s.size, (40, 60, 52)), dim * 0.6)
        rgb.putalpha(s.getchannel("A"))
        s = rgb
    R.paste_center(layer, kit.fade(s, alpha), x, y, angle)


def soft(layer: Image.Image, box, blur: int, draw) -> None:
    """Draw with draw(ImageDraw, dx, dy), blur it and lay it on `layer`, working only near `box`.

    The engine blurred a whole 1080x1920 layer for every shadow and glow, which cost most of each frame;
    blurring the neighbourhood gives the same pixels (the pad is more than three sigma).
    """
    pad = blur * 3 + 6
    x0, y0 = max(0, int(box[0]) - pad), max(0, int(box[1]) - pad)
    x1, y1 = min(layer.width, int(box[2]) + pad + 1), min(layer.height, int(box[3]) + pad + 1)
    if x1 <= x0 or y1 <= y0:
        return
    sub = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    draw(ImageDraw.Draw(sub), -x0, -y0)
    layer.alpha_composite(sub.filter(ImageFilter.GaussianBlur(blur)), (x0, y0))


def ring(layer, x: float, y: float, w: int, color, alpha: float) -> None:
    if alpha <= 0.01:
        return
    bw, bh = w + 22, int(w * CH) + 22
    box = (x - bw / 2, y - bh / 2, x + bw / 2, y + bh / 2)
    soft(layer, box, 10, lambda d, dx, dy: d.rounded_rectangle(
        (box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy), int(w * 0.16), outline=color + (int(200 * alpha),), width=18))
    ImageDraw.Draw(layer).rounded_rectangle(box, int(w * 0.16), outline=color + (int(255 * alpha),), width=8)


def chip(layer, label: str, x: float, y: float, pop: float = 1.0, h: int = 96, dim: float = 0.0) -> None:
    """A bidding-box card: white with the bid in its suit colour, green for Pass."""
    if pop <= 0.01:
        return
    sc = OUT(min(pop * 1.6, 1)) * (1 + 0.12 * bell(min(pop, 1)) * (pop < 1))
    hh = h * sc
    f = B.font(max(8, int(hh * 0.56)), "Heavy")
    d = ImageDraw.Draw(layer)
    w = max(hh * 2.4, d.textlength(label, font=f) + hh * 0.9)
    box = (x - w / 2, y - hh / 2, x + w / 2, y + hh / 2)
    passing = label.upper() == "PASS"
    fill = (70, 150, 96) if passing else (255, 253, 248)
    a = int(255 * (1 - 0.55 * dim))
    soft(layer, (box[0], box[1] + 8, box[2], box[3] + 8), 8, lambda dr, dx, dy: dr.rounded_rectangle(
        (box[0] + dx, box[1] + 8 + dy, box[2] + dx, box[3] + 8 + dy), int(hh * 0.22), fill=(10, 20, 16, int(110 * (1 - dim)))))
    d.rounded_rectangle(box, int(hh * 0.22), fill=fill + (a,))
    color = CREAM if passing else B.suit_color(label)
    d.text((x, y + hh * 0.02), label, font=f, fill=color + (a,), anchor="mm")


def fast_pill(layer, s: str, x: float, y: float, size: int, bg, fg=CREAM, alpha: float = 1.0, pop: float = 1.0) -> None:
    """kit.pill with the shadow blurred locally: same label, same look, far less work per frame."""
    if alpha <= 0.01 or pop <= 0.01:
        return
    sc = 1 + 0.18 * math.sin(math.pi * min(pop, 1)) * (pop < 1) if pop < 1 else 1.0
    sc *= OUT(min(pop * 1.6, 1))
    f = B.font(max(8, int(size * sc)), "Heavy", serif=False)
    d = ImageDraw.Draw(layer)
    w = d.textlength(s, font=f)
    hgt = size * sc * 1.5
    box = (x - w / 2 - hgt * 0.45, y - hgt / 2, x + w / 2 + hgt * 0.45, y + hgt / 2)
    soft(layer, (box[0], box[1] + 8, box[2], box[3] + 8), 8, lambda dr, dx, dy: dr.rounded_rectangle(
        (box[0] + dx, box[1] + 8 + dy, box[2] + dx, box[3] + 8 + dy), int(hgt / 2), fill=(30, 20, 16, int(90 * alpha))))
    a = int(255 * alpha)
    d.rounded_rectangle(box, int(hgt / 2), fill=bg + (a,))
    d.text((x, y + size * sc * 0.04), s, font=f, fill=fg + (a,), anchor="mm")


kit.pill = fast_pill


def seat(layer, name: str, x: float, y: float, alpha: float = 1.0) -> None:
    kit.pill(layer, name, x, y, 34, (16, 30, 26), CREAM, alpha=alpha * 0.92)


def slots(n: int, cx: float, cy: float, w: int, gap: int = 10, per_row: int = 7, row_gap: int = 28):
    rows = -(-n // per_row)
    per = -(-n // rows)
    out = []
    for i in range(n):
        r, c = divmod(i, per)
        in_row = min(per, n - r * per)
        out.append((cx + (c - (in_row - 1) / 2) * (w + gap), cy + (r - (rows - 1) / 2) * (w * CH + row_gap)))
    return out


def codes(hand: str) -> list[str]:
    return [r + s for r, s in B.parse_hand(hand)]


# Seats around a trick: where a seat's label sits, and where its card lands in the middle.
SEATS = {"N": (540, 470), "E": (900, 860), "S": (540, 1250), "W": (180, 860)}
PLAY = {"N": (540, 700), "E": (690, 860), "S": (540, 1020), "W": (390, 860)}
NAMES = {"N": "NORTH", "E": "EAST", "S": "SOUTH", "W": "WEST"}
CW = 150


def table(layer, alpha: float = 1.0, names: dict | None = None) -> None:
    for k, (x, y) in SEATS.items():
        seat(layer, (names or NAMES)[k], x, y, alpha)


def played(layer, t: float, plays: list[tuple[str, str, float]], w: int = CW) -> None:
    """Cards flying from their seats to the middle: (seat, card, start time)."""
    for k, (who, code, t0) in enumerate(plays):
        p = seg(t, t0, t0 + 0.55)
        if p <= 0:
            continue
        x, y = kit.fly(p, SEATS[who], PLAY[who], arc=40)
        put(layer, code, x, y, w, angle=(k - 1.5) * 3 * OUT(p), alpha=min(1, p * 3))


def lesson(name: str, lines, hook, draws, events, subs, seed: int) -> kit.Lesson:
    return kit.Lesson(name, lines, hook, draws, [lambda: bg(seed)] * len(draws), events, subs)


# ---------------------------------------------------------------- end card

def end_overlay(t: float):
    p, q = OUT(seg(t, 0.15, 0.95)), OUT(seg(t, 0.45, 1.25))
    ic = R.icon(340).copy()
    ic.putalpha(ic.getchannel("A").point(lambda v: int(v * p)))
    f = B.font(92, "Semibold", serif=True)
    text = "Bridge Trainer"
    tw = int(ImageDraw.Draw(ic).textlength(text, font=f))
    label = Image.new("RGBA", (tw + 20, 130), (0, 0, 0, 0))
    ImageDraw.Draw(label).text((10, 6), text, font=f, fill=B.INK + (int(255 * q),))
    return [(ic, (540 - ic.width // 2, int(560 + 40 * (1 - p)))),
            (label, (540 - label.width // 2, int(1000 + 24 * (1 - q))))]


R.scene6_overlay = end_overlay

NUMS = {"twenty-five": "25", "twenty five": "25", "twenty": "20", "thirty": "30"}


# ---------------------------------------------------------------- V1: counting points

def v1() -> kit.Lesson:
    lines = [
        "How to count bridge points, in twenty seconds.",
        "Every ace is worth four points.",
        "Kings are three, queens two, jacks one.",
        "This hand has twelve. That's enough to open the bidding.",
    ]
    hand = codes("S:AQ74 H:K93 D:J82 C:Q65")
    w = 118
    sl = slots(13, 540, 930, w, row_gap=96)
    value = {"A": 4, "K": 3, "Q": 2, "J": 1}

    def draw_hand(layer, lit: dict[int, float]) -> None:
        for i, c in enumerate(hand):
            x, y = sl[i]
            honor = c[0] in value
            put(layer, c, x, y, w, dim=0.0 if honor and lit.get(i, 0) > 0 else 0.55 * max(lit.values(), default=0))
            if lit.get(i, 0) > 0:
                ring(layer, x, y, w, GOLD, OUT(lit[i]))
                kit.pill(layer, f"+{value[c[0]]}", x, y + w * CH / 2 + 34, 34, GOLD, INK, pop=lit[i])

    honors = [i for i, c in enumerate(hand) if c[0] in value]

    def hook(t, dur, layer):
        draw_hand(layer, {i: 1.0 for i in honors})
        kit.pill(layer, "12 POINTS", 540, 620, 58, GREEN, pop=1.0)

    def aces(t, dur, layer):
        ta = L.at(1, "ace", 0.5)
        draw_hand(layer, {i: seg(t, ta, ta + 0.5) for i in honors if hand[i][0] == "A"})

    def others(t, dur, layer):
        lit = {i: 1.0 for i in honors if hand[i][0] == "A"}
        for word, rank in (("kings", "K"), ("queens", "Q"), ("jacks", "J")):
            tw = L.at(2, word, 0.5)
            lit.update({i: seg(t, tw, tw + 0.45) for i in honors if hand[i][0] == rank})
        draw_hand(layer, lit)

    def total(t, dur, layer):
        draw_hand(layer, {i: 1.0 for i in honors})
        tw, to = L.at(3, "twelve", 0.4), L.at(3, "open", 1.6)
        kit.pill(layer, "12 POINTS", 540, 620, 58, GREEN, pop=seg(t, tw, tw + 0.5))
        kit.pill(layer, "OPEN", 540, 470, 46, GOLD, INK, pop=seg(t, to, to + 0.5))

    def events():
        ev = [(1, L.at(1, "ace", 0.5), "ding", 0.15)]
        ev += [(2, L.at(2, w_, 0.5), "click", 0.3) for w_ in ("kings", "queens", "jacks")]
        ev += [(3, L.at(3, "twelve", 0.4), "ding", 0.18)]
        return ev

    L = lesson("bridge-points", lines, ("Count bridge points", "in 20 seconds."), [hook, aces, others, total],
               events, {"twelve": "12", **NUMS}, 0)
    return L


# ---------------------------------------------------------------- V2: a trick

def v2() -> kit.Lesson:
    lines = [
        "How a bridge trick works, in twenty-five seconds.",
        "West leads a card. Here, the seven of hearts.",
        "Everyone follows suit if they can.",
        "The highest heart wins. The ace takes the trick.",
        "The winner leads next. Thirteen tricks make one deal.",
    ]
    trick = [("W", "7H"), ("N", "3H"), ("E", "QH"), ("S", "AH")]

    def full(layer, t=99.0, starts=(0, 0, 0, 0)):
        played(layer, t, [(s, c, t0) for (s, c), t0 in zip(trick, starts)])

    def hook(t, dur, layer):
        table(layer)
        full(layer, starts=(-1, -1, -1, -1))
        ring(layer, *PLAY["S"], CW, GOLD, 1.0)
        kit.pill(layer, "HIGHEST CARD WINS", 540, 1380, 46, GOLD, INK, pop=1.0)

    def lead(t, dur, layer):
        table(layer)
        tl = L.at(1, "leads", 0.6)
        played(layer, t, [("W", "7H", tl)])
        kit.pill(layer, "LEAD", 390, 860 - 150, 36, GOLD, INK, pop=seg(t, tl + 0.4, tl + 0.9))

    def follow(t, dur, layer):
        table(layer)
        te = L.at(2, "everyone", 0.3)
        played(layer, t, [("W", "7H", -1), ("N", "3H", te), ("E", "QH", te + 0.6), ("S", "AH", te + 1.2)])

    def win(t, dur, layer):
        table(layer)
        full(layer, starts=(-1, -1, -1, -1))
        ta = L.at(3, "ace", 1.4)
        ring(layer, *PLAY["S"], CW, GOLD, OUT(seg(t, ta, ta + 0.4)))
        kit.check(layer, PLAY["S"][0] + CW / 2 + 10, PLAY["S"][1] - CW * CH / 2, 34, GREEN, seg(t, ta + 0.2, ta + 0.8))

    def gather(t, dur, layer):
        table(layer)
        tw = L.at(4, "winner", 0.3)
        p = seg(t, tw, tw + 0.8)
        for k, (who, code) in enumerate(trick):
            a, b = PLAY[who], (540, 1130)
            x, y = kit.fly(p, a, b)
            put(layer, "BACK" if p > 0.5 else code, x, y, int(CW * (1 - 0.35 * OUT(p))), angle=(k - 1.5) * 3)
        tt = L.at(4, "thirteen", 2.0)
        kit.pill(layer, "TRICK 1 OF 13", 540, 640, 46, GREEN, pop=seg(t, tt, tt + 0.5))

    def events():
        ev = [(1, L.at(1, "leads", 0.6) + 0.5, "click", 0.4)]
        te = L.at(2, "everyone", 0.3)
        ev += [(2, te + k * 0.6 + 0.5, "click", 0.4) for k in range(3)]
        ev += [(3, L.at(3, "ace", 1.4), "ding", 0.18), (4, L.at(4, "winner", 0.3), "whoosh", 0.4)]
        return ev

    L = lesson("bridge-trick", lines, ("How a bridge trick works,", "in 25 seconds."),
               [hook, lead, follow, win, gather], events, {"thirteen": "13", **NUMS}, 1)
    return L


# ---------------------------------------------------------------- V3: trump

def v3() -> kit.Lesson:
    lines = [
        "What trump means in bridge, in thirty seconds.",
        "Say spades are trump. Any spade beats every other suit.",
        "West leads the ace of diamonds.",
        "North has no diamonds left, so North plays a small spade.",
        "East and South follow suit.",
        "The little trump wins the trick.",
        "You can only trump when you're out of the suit led.",
    ]
    trick = [("W", "AD"), ("N", "2S"), ("E", "5D"), ("S", "9D")]

    def hook(t, dur, layer):
        table(layer)
        played(layer, 9, [(s, c, -1) for s, c in trick])
        ring(layer, *PLAY["N"], CW, GOLD, 1.0)
        kit.pill(layer, "♠ IS TRUMP", 540, 1380, 50, GOLD, INK, pop=1.0)

    def trumps(t, dur, layer):
        table(layer)
        ts = L.at(1, "spades", 0.5)
        for k, r in enumerate("AKQ2"):
            p = seg(t, ts + k * 0.12, ts + k * 0.12 + 0.5)
            put(layer, r + "S", 540 + (k - 1.5) * 150, 860 - 40 * (1 - OUT(p)), 130, alpha=min(1, p * 3))
        kit.pill(layer, "♠ IS TRUMP", 540, 660, 50, GOLD, INK, pop=seg(t, ts, ts + 0.5))

    def lead(t, dur, layer):
        table(layer)
        kit.pill(layer, "♠ IS TRUMP", 540, 360, 40, GOLD, INK, pop=1.0)
        played(layer, t, [("W", "AD", L.at(2, "leads", 0.5))])

    def ruff(t, dur, layer):
        table(layer)
        kit.pill(layer, "♠ IS TRUMP", 540, 360, 40, GOLD, INK, pop=1.0)
        tn, ts = L.at(3, "no", 0.6), L.at(3, "spade", 2.6)
        kit.pill(layer, "NO ♦", 760, 470, 36, RED, pop=seg(t, tn, tn + 0.5))
        played(layer, t, [("W", "AD", -1), ("N", "2S", ts)])

    def rest(t, dur, layer):
        table(layer)
        kit.pill(layer, "♠ IS TRUMP", 540, 360, 40, GOLD, INK, pop=1.0)
        te = L.at(4, "east", 0.3)
        played(layer, t, [("W", "AD", -1), ("N", "2S", -1), ("E", "5D", te), ("S", "9D", te + 0.7)])

    def win(t, dur, layer):
        table(layer)
        kit.pill(layer, "♠ IS TRUMP", 540, 360, 40, GOLD, INK, pop=1.0)
        played(layer, 9, [(s, c, -1) for s, c in trick])
        tw = L.at(5, "trump", 0.8)
        ring(layer, *PLAY["N"], CW, GOLD, OUT(seg(t, tw, tw + 0.4)))
        kit.check(layer, PLAY["N"][0] + CW / 2 + 10, PLAY["N"][1] - CW * CH / 2, 34, GREEN, seg(t, tw + 0.2, tw + 0.8))

    def rule(t, dur, layer):
        table(layer, 0.4)
        played(layer, 9, [(s, c, -1) for s, c in trick])
        to = L.at(6, "out", 1.4)
        kit.pill(layer, "OUT OF THE SUIT? TRUMP IT", 540, 380, 44, GOLD, INK, pop=seg(t, to, to + 0.5))

    def events():
        return [(2, L.at(2, "leads", 0.5) + 0.5, "click", 0.4), (3, L.at(3, "spade", 2.6) + 0.5, "click", 0.4),
                (4, L.at(4, "east", 0.3) + 0.5, "click", 0.4), (4, L.at(4, "east", 0.3) + 1.2, "click", 0.4),
                (5, L.at(5, "trump", 0.8), "ding", 0.18)]

    L = lesson("bridge-trump", lines, ("What trump means,", "in 30 seconds."),
               [hook, trumps, lead, ruff, rest, win, rule], events, NUMS, 2)
    return L


# ---------------------------------------------------------------- V4: the bidding ladder

def v4() -> kit.Lesson:
    lines = [
        "The bridge bidding ladder, in thirty seconds.",
        "Clubs, diamonds, hearts, spades. Then notrump on top.",
        "Every bid has to beat the one before it.",
        "One heart beats one diamond. One notrump beats one spade.",
        "After one notrump, the next bid up is two clubs.",
        "Three passes in a row, and the last bid is the contract.",
    ]
    ladder = ["1♣", "1♦", "1♥", "1♠", "1NT", "2♣"]
    ys = [1180 - k * 118 for k in range(6)]

    def draw_ladder(layer, pops, dims=None, x=540):
        for k, b in enumerate(ladder):
            chip(layer, b, x, ys[k], pop=pops[k], dim=(dims or {}).get(k, 0.0))

    def hook(t, dur, layer):
        draw_ladder(layer, [1] * 6)
        kit.arrow(layer, 800, 1180, 800, 590, GOLD, 1.0)

    def build(t, dur, layer):
        tw = [L.at(1, w_, 0.4 + k * 0.6) for k, w_ in enumerate(("clubs", "diamonds", "hearts", "spades", "notrump"))]
        draw_ladder(layer, [seg(t, a, a + 0.5) for a in tw] + [0])

    def beat(t, dur, layer):
        draw_ladder(layer, [1] * 5 + [0])
        tb = L.at(2, "beat", 0.8)
        kit.arrow(layer, 800, 1180, 800, 700, GOLD, seg(t, tb - 0.2, tb + 0.8))

    def pairs(t, dur, layer):
        th_, tn = L.at(3, "heart", 0.4), L.at(3, "notrump", 2.2)
        p1, p2 = seg(t, th_, th_ + 0.4), seg(t, tn, tn + 0.4)
        draw_ladder(layer, [1] * 5 + [0], {1: p1 * (1 - p2), 3: p2})
        ring_chip(layer, ys[2], GREEN, p1 * (1 - p2))
        ring_chip(layer, ys[4], GREEN, p2)

    def next_up(t, dur, layer):
        tt = L.at(4, "two", 2.0)
        draw_ladder(layer, [1] * 5 + [seg(t, tt, tt + 0.5)])
        ring_chip(layer, ys[5], GREEN, seg(t, tt + 0.3, tt + 0.7))

    def passes(t, dur, layer):
        tt, tc = L.at(5, "three", 0.3), L.at(5, "contract", 2.6)
        chip(layer, "1♥", 540, 600, pop=1.0)
        for k in range(3):
            chip(layer, "Pass", 540, 760 + k * 120, pop=seg(t, tt + k * 0.35, tt + k * 0.35 + 0.5))
        kit.pill(layer, "CONTRACT: 1♥", 540, 450, 46, GOLD, INK, pop=seg(t, tc, tc + 0.5))

    def events():
        ev = [(1, L.at(1, w_, 0.4 + k * 0.6), "click", 0.35)
              for k, w_ in enumerate(("clubs", "diamonds", "hearts", "spades", "notrump"))]
        ev += [(4, L.at(4, "two", 2.0), "click", 0.4)]
        ev += [(5, L.at(5, "three", 0.3) + k * 0.35, "click", 0.35) for k in range(3)]
        ev += [(5, L.at(5, "contract", 2.6), "ding", 0.18)]
        return ev

    L = lesson("bridge-ladder", lines, ("The bridge bidding ladder,", "in 30 seconds."),
               [hook, build, beat, pairs, next_up, passes], events, NUMS, 3)
    return L


def ring_chip(layer, y: float, color, alpha: float, x: float = 540, w: int = 260, h: int = 96) -> None:
    if alpha <= 0.01:
        return
    box = (x - w / 2 - 12, y - h / 2 - 12, x + w / 2 + 12, y + h / 2 + 12)
    ImageDraw.Draw(layer).rounded_rectangle(box, 30, outline=color + (int(255 * alpha),), width=8)


# ---------------------------------------------------------------- V5: opening bids

def v5() -> kit.Lesson:
    lines = [
        "What to open in bridge, in twenty-five seconds.",
        "Under twelve points? Pass.",
        "Fifteen to seventeen points, and a balanced hand? Open one notrump.",
        "Five hearts or five spades? Open that suit.",
        "Otherwise, open your longer minor.",
    ]
    hands = [
        ("S:K84 H:QJ6 D:9753 C:K42", "9 POINTS", "Pass", None, ("pass", 1.4)),
        ("S:AJ5 H:KQ4 D:KT83 C:Q72", "15 · BALANCED", "1NT", None, ("notrump", 3.6)),
        ("S:KQT83 H:A5 D:K74 C:962", "12 · FIVE SPADES", "1♠", "S", ("suit", 2.0)),
        ("S:AK7 H:J4 D:KJ984 C:Q63", "14 · FIVE DIAMONDS", "1♦", "D", ("minor", 1.6)),
    ]
    w = 110
    sl = slots(13, 540, 880, w, row_gap=26)

    def show(layer, hand: str, suit: str | None, glow: float) -> None:
        for i, c in enumerate(codes(hand)):
            put(layer, c, *sl[i], w)
            if suit and c[1] == suit:
                ring(layer, *sl[i], w, GOLD, glow)

    def hook(t, dur, layer):
        for k, b in enumerate(["Pass", "1NT", "1♠", "1♦"]):
            chip(layer, b, 540 + (k - 1.5) * 235, 880, pop=1.0, h=86)

    def make(n: int):
        hand, points, bid, suit, (word, default) = hands[n]

        def draw(t, dur, layer):
            line = n + 1
            show(layer, hand, suit, OUT(seg(t, 0.6, 1.1)))
            kit.pill(layer, points, 540, 620, 44, GREEN, pop=seg(t, 0.3, 0.8))
            tb = L.at(line, word, default)
            chip(layer, bid, 540, 1150, pop=seg(t, tb, tb + 0.5), h=110)
        return draw

    def events():
        return [(n + 1, L.at(n + 1, h[4][0], h[4][1]), "click", 0.45) for n, h in enumerate(hands)]

    L = lesson("bridge-openings", lines, ("What to open in bridge,", "in 25 seconds."),
               [hook] + [make(n) for n in range(4)], events,
               {"twelve": "12", "fifteen": "15", "seventeen": "17", "one notrump": "1NT", **NUMS}, 4)
    return L


# ---------------------------------------------------------------- V6: game contracts

def v6() -> kit.Lesson:
    lines = [
        "What game means in bridge, in twenty-five seconds.",
        "The first six tricks are free. That's called book.",
        "Three notrump needs nine tricks.",
        "Four hearts or four spades needs ten.",
        "Five clubs or five diamonds needs eleven.",
        "Around twenty-five points between you and partner is usually enough for game.",
    ]
    w = 96
    sl = slots(13, 540, 930, w, gap=14, row_gap=40)

    def tricks(layer, n_book: int, n_more: int, t: float, t0: float, color=GREEN) -> None:
        for i in range(13):
            x, y = sl[i]
            if i < n_book:
                put(layer, "BACK", x, y, w, dim=0.35 if n_more else 0.0)
            elif i < n_book + n_more:
                p = seg(t, t0 + (i - n_book) * 0.12, t0 + (i - n_book) * 0.12 + 0.4)
                put(layer, "BACK", x, y - 60 * (1 - OUT(p)), w, alpha=min(1, p * 3))
                ring(layer, x, y, w, color, p)
            else:
                ImageDraw.Draw(layer).rounded_rectangle((x - w / 2, y - w * CH / 2, x + w / 2, y + w * CH / 2), 12,
                                                        outline=CREAM + (70,), width=3)

    def hook(t, dur, layer):
        for k, (bids, n) in enumerate(((["3NT"], "9"), (["4♥", "4♠"], "10"), (["5♣", "5♦"], "11"))):
            y = 680 + k * 220
            for j, b in enumerate(bids):
                chip(layer, b, 300 + j * 230, y, h=100)
            kit.pill(layer, f"{n} TRICKS", 800, y, 44, GOLD, INK, pop=1.0)

    def book(t, dur, layer):
        tb = L.at(1, "six", 0.6)
        for i in range(13):
            x, y = sl[i]
            if i < 6:
                p = seg(t, tb + i * 0.12, tb + i * 0.12 + 0.4)
                put(layer, "BACK", x, y - 60 * (1 - OUT(p)), w, alpha=min(1, p * 3))
            else:
                ImageDraw.Draw(layer).rounded_rectangle((x - w / 2, y - w * CH / 2, x + w / 2, y + w * CH / 2), 12,
                                                        outline=CREAM + (70,), width=3)
        tk = L.at(1, "book", 2.4)
        kit.pill(layer, "BOOK = 6", 540, 620, 48, GOLD, INK, pop=seg(t, tk, tk + 0.5))

    def need(line: int, bids: list[str], more: int, word: str):
        def draw(t, dur, layer):
            tw = L.at(line, word, 1.2)
            tricks(layer, 6, more, t, tw)
            for j, b in enumerate(bids):
                chip(layer, b, 540 + (j - (len(bids) - 1) / 2) * 240, 620, pop=seg(t, 0.2 + j * 0.25, 0.7 + j * 0.25))
            kit.pill(layer, f"{6 + more} TRICKS", 540, 1180, 46, GREEN, pop=seg(t, tw + 0.4, tw + 0.9))
        return draw

    def points(t, dur, layer):
        tt = L.at(5, "twenty-five", 0.8)
        tricks(layer, 6, 3, 99, 0)
        kit.pill(layer, "ABOUT 25 POINTS = GAME", 540, 620, 46, GOLD, INK, pop=seg(t, tt, tt + 0.5))

    def events():
        tb = L.at(1, "six", 0.6)
        ev = [(1, tb + i * 0.12 + 0.3, "click", 0.2) for i in range(6)]
        for line, more, word in ((2, 3, "nine"), (3, 4, "ten"), (4, 5, "eleven")):
            tw = L.at(line, word, 1.2)
            ev += [(line, tw + i * 0.12 + 0.3, "click", 0.2) for i in range(more)]
        ev += [(5, L.at(5, "twenty-five", 0.8), "ding", 0.18)]
        return ev

    L = lesson("bridge-game", lines, ("What game means in bridge,", "in 25 seconds."),
               [hook, book, need(2, ["3NT"], 3, "nine"), need(3, ["4♥", "4♠"], 4, "ten"),
                need(4, ["5♣", "5♦"], 5, "eleven"), points], events,
               {"six": "6", "three notrump": "3NT", "nine": "9", "ten": "10", "eleven": "11", **NUMS}, 0)
    return L


# ---------------------------------------------------------------- V7: the finesse

def v7() -> kit.Lesson:
    lines = [
        "The bridge finesse, in twenty-five seconds.",
        "Dummy has the ace and queen of spades. The king is missing.",
        "Lead a small spade toward dummy.",
        "West plays low, so you play the queen.",
        "West had the king, so the queen wins the trick.",
        "That's a finesse. When the king sits on your left, it works.",
    ]
    names = {"N": "DUMMY", "E": "EAST", "S": "YOU", "W": "WEST"}
    seats = dict(SEATS)
    spot = {"N": (540, 850), "W": (400, 990), "E": (680, 990), "S": (540, 1110)}  # below dummy's cards
    w = 140

    def board(layer, played_q: bool = False, west_open: float = 0.0, lit: float = 0.0):
        table(layer, names=names)
        put(layer, "AS", 470, 610, w)
        if not played_q:
            put(layer, "QS", 610, 610, w)
        if lit:
            ring(layer, 470, 610, w, GOLD, lit)
            if not played_q:
                ring(layer, 610, 610, w, GOLD, lit)
        x, y = seats["W"][0], seats["W"][1] + 190
        put(layer, "KS" if west_open > 0.5 else "BACK", x, y, 110, scale=1 + 0.1 * bell(west_open))
        if west_open > 0.5:
            ring(layer, x, y, 110, RED, OUT(seg(west_open, 0.5, 1)))

    def trick(layer, t, plays):
        for who, code, t0 in plays:
            p = seg(t, t0, t0 + 0.55)
            if p <= 0:
                continue
            start = (610, 610) if who == "N" else seats[who]
            x, y = kit.fly(p, start, spot[who], arc=40)
            put(layer, code, x, y, w, alpha=min(1, p * 3))

    def hook(t, dur, layer):
        board(layer, played_q=True, west_open=1.0)
        trick(layer, 9, [("S", "3S", -1), ("W", "7S", -1), ("N", "QS", -1), ("E", "5S", -1)])
        ring(layer, *spot["N"], w, GREEN, 1.0)

    def missing(t, dur, layer):
        ta, tk = L.at(1, "ace", 0.8), L.at(1, "king", 2.6)
        board(layer, lit=OUT(seg(t, ta, ta + 0.5)))
        kit.pill(layer, "WHERE'S THE K♠?", 540, 900, 44, RED, pop=seg(t, tk, tk + 0.5))

    def lead(t, dur, layer):
        board(layer)
        tl = L.at(2, "lead", 0.3)
        trick(layer, t, [("S", "3S", tl)])
        kit.arrow(layer, 540, 1000, 540, 740, GOLD, seg(t, tl + 0.6, tl + 1.3), width=18)

    def queen(t, dur, layer):
        tw, tq = L.at(3, "low", 0.8), L.at(3, "queen", 2.0)
        board(layer, played_q=t > tq)
        trick(layer, t, [("S", "3S", -1), ("W", "7S", tw), ("N", "QS", tq)])

    def wins(t, dur, layer):
        tk, tw = L.at(4, "king", 0.8), L.at(4, "wins", 2.0)
        board(layer, played_q=True, west_open=seg(t, tk, tk + 0.6))
        trick(layer, t, [("S", "3S", -1), ("W", "7S", -1), ("N", "QS", -1), ("E", "5S", 0.1)])
        x, y = spot["N"]
        ring(layer, x, y, w, GREEN, OUT(seg(t, tw, tw + 0.4)))
        kit.check(layer, x + w / 2 + 10, y - w * CH / 2, 34, GREEN, seg(t, tw + 0.2, tw + 0.8))

    def name(t, dur, layer):
        board(layer, played_q=True, west_open=1.0)
        trick(layer, 9, [("S", "3S", -1), ("W", "7S", -1), ("N", "QS", -1), ("E", "5S", -1)])
        tf = L.at(5, "finesse", 0.6)
        kit.pill(layer, "THE FINESSE", 540, 360, 50, GOLD, INK, pop=seg(t, tf, tf + 0.5))

    def events():
        return [(2, L.at(2, "lead", 0.3) + 0.5, "click", 0.4), (3, L.at(3, "low", 0.8) + 0.5, "click", 0.4),
                (3, L.at(3, "queen", 2.0) + 0.5, "click", 0.4), (4, 0.6, "click", 0.4),
                (4, L.at(4, "wins", 2.0), "ding", 0.18)]

    L = lesson("bridge-finesse", lines, ("The bridge finesse,", "in 25 seconds."),
               [hook, missing, lead, queen, wins, name], events, NUMS, 1)
    return L


# ---------------------------------------------------------------- V8: the opening lead

def v8() -> kit.Lesson:
    lines = [
        "What to lead in bridge, in twenty-five seconds.",
        "Against notrump, look for three touching honors.",
        "Lead the top one, the king.",
        "Declarer wins it with the ace.",
        "Now your queen and jack are both winners.",
        "Top of a sequence. It's safe, and it sets up your suit.",
    ]
    hand = codes("S:KQJ5 H:874 D:962 C:A73")
    w = 112
    sl = slots(13, 540, 1080, w, row_gap=22)
    K_AT = (470, 640)

    def show(layer, skip_k: bool, lit: float, win: float = 0.0):
        for i, c in enumerate(hand):
            if skip_k and c == "KS":
                continue
            put(layer, c, *sl[i], w)
            if c in ("KS", "QS", "JS") and lit:
                ring(layer, *sl[i], w, GOLD, lit)
            if c in ("QS", "JS") and win:
                ring(layer, *sl[i], w, GREEN, win)
                kit.check(layer, sl[i][0] + w / 2, sl[i][1] - w * CH / 2, 26, GREEN, win)

    def label(layer):
        seat(layer, "YOU", 540, 860)
        seat(layer, "DECLARER", 880, 470)

    def hook(t, dur, layer):
        label(layer)
        show(layer, False, 1.0)
        kit.pill(layer, "LEAD THE KING", 540, 560, 52, GOLD, INK, pop=1.0)

    def look(t, dur, layer):
        label(layer)
        th_ = L.at(1, "touching", 1.4)
        show(layer, False, OUT(seg(t, th_, th_ + 0.5)))

    def lead(t, dur, layer):
        label(layer)
        tk = L.at(2, "king", 1.2)
        p = seg(t, tk - 0.3, tk + 0.3)
        show(layer, p > 0, 1.0 - OUT(p))
        if p > 0:
            x, y = kit.fly(p, sl[hand.index("KS")], K_AT, arc=-60)
            put(layer, "KS", x, y, 140)

    def ace(t, dur, layer):
        label(layer)
        show(layer, True, 0.0)
        put(layer, "KS", *K_AT, 140)
        ta = L.at(3, "ace", 1.3)
        p = seg(t, ta - 0.4, ta + 0.2)
        if p > 0:
            x, y = kit.fly(p, (880, 470), (620, 640), arc=40)
            put(layer, "AS", x, y, 140, angle=4 * OUT(p))
        ring(layer, 620, 640, 140, RED, OUT(seg(t, ta + 0.2, ta + 0.6)))

    def winners(t, dur, layer):
        label(layer)
        put(layer, "KS", *K_AT, 140)
        put(layer, "AS", 620, 640, 140, angle=4)
        tq = L.at(4, "queen", 0.8)
        show(layer, True, 0.0, OUT(seg(t, tq, tq + 0.6)))

    def name(t, dur, layer):
        label(layer)
        show(layer, False, 1.0)
        ts = L.at(5, "sequence", 0.8)
        kit.pill(layer, "TOP OF A SEQUENCE", 540, 560, 50, GOLD, INK, pop=seg(t, ts, ts + 0.5))

    def events():
        return [(1, L.at(1, "touching", 1.4), "ding", 0.15), (2, L.at(2, "king", 1.2) + 0.3, "click", 0.45),
                (3, L.at(3, "ace", 1.3) + 0.2, "click", 0.45), (4, L.at(4, "queen", 0.8), "ding", 0.18)]

    L = lesson("bridge-lead", lines, ("What to lead in bridge,", "in 25 seconds."),
               [hook, look, lead, ace, winners, name], events, NUMS, 2)
    return L


# ---------------------------------------------------------------- Hand generator port (V9 to V14 deal from it)

HCPV = {"A": 4, "K": 3, "Q": 2, "J": 1}


class Shape:
    """Port of HandGenerator.Shape (Shared/Content/HandGenerator.swift): lengths, points and the derived facts."""

    def __init__(self, cards: list[tuple[str, str]]):
        self.cards = cards
        self.lengths = {s: sum(1 for _, x in cards if x == s) for s in "SHDC"}
        self.hcp = sum(HCPV.get(r, 0) for r, _ in cards)

    def length(self, s: str) -> int:
        return self.lengths[s]

    @property
    def sorted(self) -> list[int]:
        return sorted(self.lengths.values(), reverse=True)

    @property
    def balanced(self) -> bool:
        v = list(self.lengths.values())
        return sum(1 for x in v if x < 2) == 0 and sum(1 for x in v if x == 2) <= 1

    @property
    def longest_major(self) -> str | None:
        best = max(self.length("S"), self.length("H"))
        if best < 5:
            return None
        return "S" if self.length("S") == best else "H"

    @property
    def longest_minor_len(self) -> int:
        return max(self.length("C"), self.length("D"))

    @property
    def four441(self) -> bool:
        return self.sorted == [4, 4, 4, 1]

    @property
    def longer_minor(self) -> str:
        c, d = self.length("C"), self.length("D")
        if d > c:
            return "D"
        if c > d:
            return "C"
        return "C" if c == 3 else "D"

    @property
    def rule20(self) -> int:
        return self.hcp + sum(self.sorted[:2])

    @property
    def pattern(self) -> str:
        return "-".join(map(str, self.sorted))


def opening(cards: list[tuple[str, str]]) -> str | None:
    """HandGenerator.opening(for:) line for line: Pass, 1C, 1D, 1H, 1S, 1NT, or None when the hand is not graded."""
    if len(cards) != 13 or len(set(cards)) != 13:
        return None
    sh = Shape(cards)
    hcp = sh.hcp
    if hcp >= 20:
        return None
    if hcp < 12:
        if not (hcp <= 10 and sh.rule20 < 20 and sh.sorted[0] <= 4):
            return None
        return "Pass"
    if not (hcp >= 13 or sh.rule20 >= 20):
        return None
    if sh.four441:
        return None
    if 15 <= hcp <= 17 and sh.balanced:
        if sh.longest_major:
            return None
        return "1NT"
    major = sh.longest_major
    if major and sh.length(major) >= sh.longest_minor_len:
        return "1S" if major == "S" else "1H"
    return "1D" if sh.longer_minor == "D" else "1C"


RANKS13 = "AKQJT98765432"
DECK = [(r, s) for s in "SHDC" for r in RANKS13]
# What each quiz needed from the deal (a shape and a points range on top of the answer opening() must give).
QUIZ_WANTS = {
    "1NT": lambda s: s.pattern == "4-3-3-3" and s.hcp in (15, 16),
    "1S": lambda s: s.hcp == 13 and s.length("S") == 5 and s.pattern in ("5-3-3-2", "5-4-2-2") and s.length("H") <= 4,
    "1C": lambda s: s.hcp in (13, 14) and s.length("C") == 3 and s.length("D") == 3 and s.longest_major is None,
    "Pass": lambda s: s.hcp in (7, 8) and s.pattern in ("4-3-3-3", "4-4-3-2"),
    "1H": lambda s: s.hcp == 12 and s.length("H") == 5 and s.pattern == "5-4-2-2" and s.length("S") <= 4,
    "1D": lambda s: s.hcp in (13, 14) and s.length("D") == 5 and s.length("H") == 4 and s.pattern == "5-4-2-2",
}


def deal_candidates(seed: int = 2026, deals: int = 400_000, per_answer: int = 4) -> dict[str, list[str]]:
    """Random deals (random.Random(seed).sample, like the app's shuffled deck) that opening() grades and QUIZ_WANTS likes."""
    import random
    rng, out = random.Random(seed), {k: [] for k in QUIZ_WANTS}
    for _ in range(deals):
        cs = rng.sample(DECK, 13)
        ans = opening(cs)
        if ans in QUIZ_WANTS and len(out[ans]) < per_answer and QUIZ_WANTS[ans](Shape(cs)):
            out[ans].append(" ".join(f"{s}:" + "".join(sorted((r for r, x in cs if x == s), key=RANKS13.index))
                                     for s in "SHDC"))
    return out


# The hands below came from deal_candidates() (seed 2026); every one classifies non-nil under opening().
QUIZ_HANDS = {
    "V9": ("S:QJ43 H:AJ5 D:KQT C:KT3", "1NT"),
    "V10": ("S:KQJ64 H:A52 D:J63 C:Q3", "1S"),
    "V11": ("S:A732 H:QJ9 D:632 C:AQ5", "1C"),
    "V12": ("S:KJT H:8753 D:QT8 C:Q85", "Pass"),
    "V13": ("S:7642 H:AKJ76 D:65 C:A6", "1H"),
    "V14": ("S:65 H:AT53 D:AKQ43 C:53", "1D"),
}
# The five lesson hands drawn by hand: (hand, what the script must confirm).
LESSON_HANDS = {
    "V15": "S:KJ63 H:Q92 D:A84 C:874",
    "V16": "S:J874 H:KT52 D:J963 C:5",
    "V17": "S:KJ72 H:Q83 D:T63 C:954",
    "V19": "S:97532 H:KQ4 D:86 C:J75",
}
V15_OPENER = "S:AQ82 H:K54 D:KJ6 C:Q75"  # partner's 1NT, named in the narration only
V18_YOU = "S:K75 H:AKJ84 D:962 C:85"
V18_DUMMY = "S:AQ4 H:Q753 D:A3 C:K642"


def cards_of(hand: str) -> list[tuple[str, str]]:
    return B.parse_hand(hand)


def top_three_losers(you: str, dummy: str) -> dict[str, int]:
    """Losers by suit for declarer: the missing aces, kings and queens among the top three cards of the longer hand."""
    out = {}
    for s in "SHDC":
        a = [r for r, x in cards_of(you) if x == s]
        b = [r for r, x in cards_of(dummy) if x == s]
        held = len({r for r in a + b if r in "AKQ"})
        out[s] = max(0, min(3, max(len(a), len(b))) - held)
    return out


def check_hands() -> str:
    """Recount every hand the shorts show, by script. Returns the text; raises on any mismatch."""
    lines = []
    for key, (hand, want) in QUIZ_HANDS.items():
        cs = cards_of(hand)
        sh = Shape(cs)
        got = opening(cs)
        assert len(cs) == 13 and len(set(cs)) == 13, key
        assert got == want, (key, got, want)
        assert sh.hcp == B.hcp(hand), key
        lines.append(f"{key}  {hand:30s} HCP {sh.hcp:2d}  shape {sh.pattern}  lengths S{sh.length('S')} H{sh.length('H')} "
                     f"D{sh.length('D')} C{sh.length('C')}  rule20 {sh.rule20}  opening() = {got}  expected {want}  OK")
    for key, hand in LESSON_HANDS.items():
        sh = Shape(cards_of(hand))
        assert len(set(cards_of(hand))) == 13 and sh.hcp == B.hcp(hand)
        lines.append(f"{key}  {hand:30s} HCP {sh.hcp:2d}  shape {sh.pattern}  lengths S{sh.length('S')} H{sh.length('H')} "
                     f"D{sh.length('D')} C{sh.length('C')}  OK")
    # V15: you 10 HCP with four spades; partner's 1NT hand is balanced 15 to 17 with four spades, no five-card major.
    y, o = Shape(cards_of(LESSON_HANDS["V15"])), Shape(cards_of(V15_OPENER))
    assert y.hcp == 10 and y.length("S") == 4 and y.length("H") < 5
    assert o.balanced and 15 <= o.hcp <= 17 and o.longest_major is None and o.length("S") == 4
    assert opening(cards_of(V15_OPENER)) == "1NT"
    lines.append(f"V15  partner's 1NT hand {V15_OPENER}: HCP {o.hcp}, {o.pattern}, 4 spades, opening() = 1NT; "
                 f"you 10 + partner {o.hcp} = {10 + o.hcp} (game); spades fit {y.length('S') + o.length('S')} cards  OK")
    # V16: 5 HCP + 3 for the singleton = 8 support points with four trumps in partner's major.
    s16 = Shape(cards_of(LESSON_HANDS["V16"]))
    sing = [s for s in "SHDC" if s16.length(s) == 1]
    assert s16.hcp == 5 and s16.length("H") == 4 and sing == ["C"] and 6 <= s16.hcp + 3 <= 10
    lines.append(f"V16  support points: HCP {s16.hcp} + singleton club 3 = {s16.hcp + 3}; 4 hearts; range 6 to 10 = simple raise to 2H  OK")
    # V17: 6 HCP, four spades, three of each other suit, partner opened 1C.
    s17 = Shape(cards_of(LESSON_HANDS["V17"]))
    assert s17.hcp == 6 and s17.length("S") == 4 and s17.length("C") == 3 and s17.length("H") == 3 and s17.length("D") == 3
    lines.append(f"V17  HCP {s17.hcp} (needs 6+ to respond); 4 spades, no other suit above 3; answer 1S  OK")
    # V18
    ys, ds = Shape(cards_of(V18_YOU)), Shape(cards_of(V18_DUMMY))
    assert ys.length("H") + ds.length("H") == 9 and ys.hcp + ds.hcp == 26
    assert len(set(cards_of(V18_YOU) + cards_of(V18_DUMMY))) == 26
    lose = top_three_losers(V18_YOU, V18_DUMMY)
    assert lose == {"S": 0, "H": 0, "D": 2, "C": 2} and sum(lose.values()) == 4
    assert ds.length("D") == 2 and ys.length("D") == 3
    lines.append(f"V18  you {V18_YOU} HCP {ys.hcp} {ys.pattern}; dummy {V18_DUMMY} HCP {ds.hcp} {ds.pattern}; total {ys.hcp + ds.hcp}; "
                 f"26 distinct cards; trumps {ys.length('H') + ds.length('H')}; top-three losers {lose} = {sum(lose.values())}; "
                 f"4H allows {13 - 10}; ruff 3rd diamond in dummy (dummy has {ds.length('D')} diamonds) -> {sum(lose.values()) - 1}  OK")
    # V19
    s19 = Shape(cards_of(LESSON_HANDS["V19"]))
    assert s19.hcp == 6 and s19.length("S") == 5 and s19.length("H") == 3
    lines.append(f"V19  HCP {s19.hcp}; spades {s19.length('S')} (no honor), hearts KQ4 = partner's suit, lead the K from touching K-Q  OK")
    # V20: the club suit only
    assert B.parse_hand("C:K82") == [("K", "C"), ("8", "C"), ("2", "C")] and B.parse_hand("C:AJ5")
    lines.append("V20  clubs: dummy A-J-5, you K-8-2, declarer leads the 4 (a small card): low keeps the K a winner; K first loses it to the A  OK")
    return "\n".join(lines)


def check_against_app() -> str:
    """Run the port over the app's own authored opening hands (HandMatchQuestion in Shared/Content): all must agree."""
    import re
    names = {"ace": "A", "king": "K", "queen": "Q", "jack": "J", "ten": "T", "nine": "9", "eight": "8", "seven": "7",
             "six": "6", "five": "5", "four": "4", "three": "3", "two": "2"}
    answers = {"pass": "Pass", "oneClub": "1C", "oneDiamond": "1D", "oneHeart": "1H", "oneSpade": "1S", "oneNotrump": "1NT"}
    n = ok = 0
    for f in sorted((pathlib.Path(__file__).resolve().parents[3] / "Shared/Content").glob("*.swift")):
        for m in re.finditer(r'HandMatchQuestion\(\s*id: "([^"]+)",\s*cards: \[(.*?)\],\s*choices:.*?answer: \.(\w+)',
                             f.read_text(), re.S):
            cs = [(names[r], s.upper()) for s, r in re.findall(r"\.([shdc])\(\.(\w+)\)", m.group(2))]
            n += 1
            ok += opening(cs) == answers[m.group(3)]
    assert n and ok == n, (ok, n)
    return f"port vs the app's {n} authored opening hands: {ok}/{n} agree"


# ---------------------------------------------------------------- the Bridge music bed

BPM = 104  # Mahj's score floats at about 17 bars a minute in F major on sine pads; this one swings at 104 in E-flat
BEAT = 60 / BPM
SW = 2 / 3  # swing: the off-beat eighth lands two thirds into the beat


def _pluck(freq: float, dur: float, vel: float) -> np.ndarray:
    t = np.arange(int(dur * R.SR)) / R.SR
    y = np.sin(2 * np.pi * freq * t) * np.exp(-t * 4.5) + 0.45 * np.sin(4 * np.pi * freq * t) * np.exp(-t * 9)
    y += 0.2 * np.sin(6 * np.pi * freq * t) * np.exp(-t * 16)
    return vel * y * (1 - np.exp(-t * 600))


def _ep(freq: float, dur: float, vel: float) -> np.ndarray:
    """A little electric piano: two-operator FM with a bright tine that dies quickly."""
    t = np.arange(int(dur * R.SR)) / R.SR
    idx = 2.2 * np.exp(-t * 6)
    y = np.sin(2 * np.pi * freq * t + idx * np.sin(2 * np.pi * freq * t)) * np.exp(-t * 2.8)
    y += 0.22 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t * 15)
    return vel * y * (1 - np.exp(-t * 500))


def _brush(rng: np.random.Generator, dur: float, vel: float) -> np.ndarray:
    n = int(dur * R.SR)
    t = np.arange(n) / R.SR
    b, a = signal.butter(2, [2500 / (R.SR / 2), 9000 / (R.SR / 2)], "band")
    return vel * signal.lfilter(b, a, rng.normal(size=n)) * np.exp(-t * 30) * (1 - np.exp(-t * 900))


def bridge_score(total: float, card_at: float) -> np.ndarray:
    """Card-room swing: plucked bass, electric piano on the off-beats, brushes on 2 and 4, E-flat major, 104 BPM."""
    rng = np.random.default_rng(8)
    buf = np.zeros(int(total * R.SR) + R.SR)
    bars = [  # E-flat maj7, C min7, F min7, B-flat 7
        ("Eb2", "Bb2", ["G3", "Bb3", "D4"]), ("C2", "G2", ["Eb3", "G3", "Bb3"]),
        ("F2", "C3", ["Ab3", "C4", "Eb4"]), ("Bb2", "F3", ["D4", "F4", "Ab4"]),
    ]
    n_bars = int(card_at / (4 * BEAT)) + 1
    for b in range(n_bars):
        root, fifth, voicing = bars[b % 4]
        t0 = b * 4 * BEAT
        R.add(buf, _pluck(R.hz(root), 1.4 * BEAT * 2, 0.34), t0)
        R.add(buf, _pluck(R.hz(fifth), 1.2 * BEAT, 0.26), t0 + 2 * BEAT)
        R.add(buf, _pluck(R.hz(root) * 2 if b % 2 else R.hz(fifth), 0.8 * BEAT, 0.14), t0 + 3 * BEAT)
        for at, vel in ((0.0, 0.10), (1 + SW, 0.12), (3 + SW, 0.10)):
            for k, n in enumerate(voicing):
                R.add(buf, _ep(R.hz(n), 1.2, vel), t0 + at * BEAT + k * 0.012)
        for beat in (1, 3):
            R.add(buf, _brush(rng, 0.25, 0.20), t0 + beat * BEAT)
        for beat in range(4):
            R.add(buf, _brush(rng, 0.07, 0.07), t0 + beat * BEAT)
            R.add(buf, _brush(rng, 0.06, 0.04), t0 + (beat + SW) * BEAT)
        if b % 4 == 3:  # a tiny turnaround figure on the last bar of each four
            for k, n in enumerate(["G5", "Bb5", "D6"]):
                R.add(buf, _ep(R.hz(n), 0.8, 0.07), t0 + (2 + k * 0.5) * BEAT)
    for k, n in enumerate(["Eb2", "Bb2", "G3", "D4", "F4", "Bb4"]):  # the closing chord, E-flat maj9
        R.add(buf, _ep(R.hz(n), total - card_at + 0.6, 0.12), card_at + k * 0.05)
    R.add(buf, _pluck(R.hz("Eb2"), 2.0, 0.34), card_at)
    b, a = signal.butter(2, 4200 / (R.SR / 2))
    buf = signal.lfilter(b, a, buf)
    ir_t = np.arange(int(1.0 * R.SR)) / R.SR
    ir = np.random.default_rng(3).normal(size=len(ir_t)) * np.exp(-ir_t * 5.5)
    wet = signal.fftconvolve(buf, ir)[: len(buf)]
    buf = buf + 0.12 * wet / (np.abs(wet).max() + 1e-9) * np.abs(buf).max()
    fade = np.ones_like(buf)
    end = int(total * R.SR)
    fade[end - int(1.2 * R.SR): end] = np.linspace(1, 0, int(1.2 * R.SR))
    fade[end:] = 0
    return buf * fade


MAHJ_SCORE = R.score  # kept only so the two beds can be compared
R.score = bridge_score  # every Bridge short, V1 to V20, takes this bed instead of the Mahj one

# The paint pass depends only on the felt (the same image all through a short) and which of three line wobbles is up,
# so repaint once per (felt, wobble) instead of every frame. Output is identical to the engine's own pass.
_paint, _painted = R.paint, {}


def _cached_paint(img: Image.Image, frame: int) -> Image.Image:
    key = (hash(img.tobytes()), (frame // 4) % 3)
    if key not in _painted:
        if len(_painted) > 12:
            _painted.clear()
        _painted[key] = _paint(img, frame)
    return _painted[key]


R.paint = _cached_paint


# ---------------------------------------------------------------- shared drawing for V9 to V20

SYM = B.SUITS
ROW_X0, ROW_Y0, ROW_PITCH, ROW_W = 205, 600, 176, 112


def row_slots(hand: str, w: int = ROW_W, gap: int = 10, x0: float | None = None, y0: int = ROW_Y0,
              pitch: int = ROW_PITCH):
    """The hand dealt by suit, spades on top, like the quiz screens: (code, x, y), cards centred as a block."""
    if x0 is None:
        longest = max(sum(1 for c in cards_of(hand) if c[1] == s) for s in "SHDC")
        x0 = 540 - (longest * (w + gap) - gap) / 2
    out = []
    for si, s in enumerate("SHDC"):
        for j, (r, _) in enumerate([c for c in cards_of(hand) if c[1] == s]):
            out.append((r + s, x0 + w / 2 + j * (w + gap), y0 + si * pitch))
    return out


def suit_tag(layer, s: str, y: float, x: float = 135, alpha: float = 1.0) -> None:
    kit.pill(layer, SYM[s], x, y, 44, (255, 253, 248), B.suit_color(SYM[s]), alpha=alpha)


def draw_rows(layer, slots_, w: int = ROW_W, dim=None, rings=None, tags: bool = True, bob: float = 0.0) -> None:
    tag_x = min(x for _, x, _ in slots_) - w / 2 - 70
    for code, x, y in slots_:
        put(layer, code, x, y + bob, w, dim=(dim(code) if dim else 0.0))
        rg = rings(code) if rings else None
        if rg:
            ring(layer, x, y + bob, w, *rg)
    if tags:
        for si, s in enumerate("SHDC"):
            suit_tag(layer, s, ROW_Y0 + si * ROW_PITCH + bob, x=tag_x)


def answer_chips(layer, t: float, y0: float = 1290, h: int = 80, active: bool = True) -> None:
    """The six answers a player can give, with a ring that sweeps across them."""
    labels = ["Pass", "1♣", "1♦", "1♥", "1♠", "1NT"]
    on = int(t / 0.38) % 6
    for k, b in enumerate(labels):
        x, y = 280 + (k % 3) * 260, y0 + (k // 3) * 110
        chip(layer, b, x, y, pop=1.0, h=h)
        if active and k == on:
            ring_chip(layer, y, GOLD, 0.6 + 0.4 * abs(wave(t, 0.76)), x=x, w=2 * h * 1.2, h=h)


def auction(layer, y: float, items, pitch: int = 215, h: int = 76) -> None:
    """Bids left to right: items are (label, who, pop). Seat tags sit above each bid."""
    n = len(items)
    for k, (label, who, pop) in enumerate(items):
        if pop <= 0.01:
            continue
        x = 540 + (k - (n - 1) / 2) * pitch
        kit.pill(layer, who, x, y - 66, 26, (16, 30, 26), CREAM, alpha=min(1, pop * 2) * 0.92)
        chip(layer, label, x, y, pop=pop, h=h)


def tally(layer, text: str, y: float = 440, size: int = 54, color=GREEN, pop: float = 1.0) -> None:
    kit.pill(layer, text, 540, y, size, color, pop=pop)


# ---------------------------------------------------------------- V9 to V14: what do you open?

QUIZ_SUBS = {"fifteen to seventeen": "15 to 17", "one notrump": "1NT", "four three three three": "4333", "five and four": "5 and 4",
             "sixteen": "16", "fifteen": "15", "seventeen": "17", "thirteen": "13", "twelve": "12", "twenty-one": "21",
             "eight": "8", "twenty": "20", "ace four": "ace 4", "king three": "king 3", "queen two": "queen 2",
             "jack one": "jack 1"}


def quiz(name: str, key: str, lines: list[str], hook: tuple[str, str], seed: int, shape_text: str,
         focus: str | None, total_key: str, ans_key: str, subs: dict | None = None) -> kit.Lesson:
    hand, ans = QUIZ_HANDS[key]
    sh = Shape(cards_of(hand))
    sl = row_slots(hand)
    val = HCPV
    label = {"1NT": "1NT", "1S": "1♠", "1H": "1♥", "1D": "1♦", "1C": "1♣", "Pass": "Pass"}[ans]
    badge_x = max(x for _, x, _ in sl) + ROW_W / 2 + 55

    def hook_(t, dur, layer):
        draw_rows(layer, sl, bob=2.5 * wave(t, 1.6))
        answer_chips(layer, t)

    def points(t, dur, layer):
        lit, total = {}, 0
        for r, word, dflt in (("A", "ace", 0.9), ("K", "king", 1.8), ("Q", "queen", 2.7), ("J", "jack", 3.5)):
            tw = L.at(1, word, dflt)
            p = seg(t, tw, tw + 0.4)
            for code, _, _ in sl:
                if code[0] == r:
                    lit[code] = p
            if p > 0.5:
                total += sum(1 for code, _, _ in sl if code[0] == r) * val[r]
        m = max(lit.values(), default=0)
        draw_rows(layer, sl, dim=lambda c: 0.0 if lit.get(c, 0) > 0 else 0.55 * m,
                  rings=lambda c: (GOLD, OUT(lit[c])) if lit.get(c, 0) > 0 else None)
        if total:
            tt = L.at(1, total_key, 4.4)
            big = seg(t, tt, tt + 0.5)
            tally(layer, f"{total} POINTS", pop=1.0 if total < sh.hcp or big > 0 else seg(t, 0, 0.4),
                  color=GREEN if big > 0 else GOLD)

    def shape(t, dur, layer):
        dimmed = (lambda c: 0.5 * OUT(seg(t, 0.8, 1.3)) if c[1] != focus else 0.0) if focus else None
        rgs = (lambda c: (GOLD, OUT(seg(t, 0.8, 1.3))) if c[1] == focus else None) if focus else None
        draw_rows(layer, sl, dim=dimmed, rings=rgs)
        for si, s in enumerate("SHDC"):
            hot = s == focus
            kit.pill(layer, str(sh.length(s)), badge_x, ROW_Y0 + si * ROW_PITCH, 44, GOLD if hot else (70, 96, 86),
                     INK if hot else CREAM, pop=seg(t, 0.25 + si * 0.14, 0.65 + si * 0.14))
        tally(layer, shape_text, color=GREEN, pop=seg(t, 0.15, 0.65))

    def answer(t, dur, layer):
        draw_rows(layer, sl)
        ta = L.at(3, ans_key, 1.0)
        pop = seg(t, ta, ta + 0.5)
        chip(layer, label, 540, 420, pop=pop, h=130)
        ring_chip(layer, 420, GREEN, OUT(seg(t, ta + 0.3, ta + 0.7)), w=312, h=130)

    def events():
        return [(1, L.at(1, "ace", 0.9), "click", 0.3), (1, L.at(1, "king", 1.8), "click", 0.3),
                (1, L.at(1, "queen", 2.7), "click", 0.3), (1, L.at(1, "jack", 3.5), "click", 0.3),
                (1, L.at(1, total_key, 4.4), "ding", 0.18), (3, L.at(3, ans_key, 1.0), "ding", 0.2)]

    L = lesson(name, lines, hook, [hook_, points, shape, answer], events, {**QUIZ_SUBS, **(subs or {})}, seed)
    return L


def v9() -> kit.Lesson:
    return quiz("quiz-1nt", "V9", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Sixteen.",
        "The shape is four, three, three, three. Balanced, with every major shorter than five cards.",
        "Fifteen to seventeen and balanced? Open one notrump.",
    ], ("What do you open", "with this hand?"), 0, "BALANCED 4-3-3-3", None, "16", "open")


def v10() -> kit.Lesson:
    return quiz("quiz-1s", "V10", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Thirteen.",
        "Spades are your longest suit, five of them. A five-card major opens at the one level.",
        "Open one spade.",
    ], ("What do you open", "with this hand?"), 1, "FIVE SPADES", "S", "13", "open")


def v11() -> kit.Lesson:
    return quiz("quiz-1c", "V11", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Thirteen.",
        "Every major is shorter than five cards, so look to the minors. You hold three clubs and three diamonds.",
        "With three of each minor, open the short club. One club.",
    ], ("What do you open", "with this hand?"), 2, "3 CLUBS · 3 DIAMONDS", None, "13", "short")


def v12() -> kit.Lesson:
    return quiz("quiz-pass", "V12", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Eight.",
        "Opening takes about thirteen. Your longest suit has four cards, too short to open on shape.",
        "Pass.",
    ], ("What do you open", "with this hand?"), 3, "8 POINTS · LONGEST SUIT 4", "H", "8", "pass")


def v13() -> kit.Lesson:
    return quiz("quiz-1h", "V13", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Twelve. Borderline.",
        "Add your two longest suits, five hearts and four spades. Twelve plus nine is twenty-one.",
        "Twenty or more passes the Rule of Twenty. Open your longest suit, one heart.",
    ], ("What do you open", "with this hand?"), 4, "12 + 5 + 4 = 21", None, "12", "open",
        {"twelve plus nine is twenty-one": "12 + 9 = 21", "twenty or more": "20 or more", "rule of twenty": "Rule of 20"})


def v14() -> kit.Lesson:
    return quiz("quiz-1d", "V14", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Thirteen.",
        "Diamonds are your longest suit, five of them. Hearts have four.",
        "Open your longest suit first. One diamond.",
    ], ("What do you open", "with this hand?"), 0, "FIVE DIAMONDS", "D", "13", "first")


# ---------------------------------------------------------------- V15: Stayman

def v15() -> kit.Lesson:
    lines = [
        "Partner opens one notrump. What now?",
        "You hold ten points and four spades.",
        "Eight or more with a four-card major? Bid two clubs. That's Stayman, asking for a major.",
        "Partner names a four-card major if there is one. Here, two spades.",
        "Ten plus partner's fifteen to seventeen is game. Bid four spades.",
    ]
    hand = LESSON_HANDS["V15"]
    sl = row_slots(hand)

    def hook(t, dur, layer):
        draw_rows(layer, sl, bob=2.5 * wave(t, 1.6))
        auction(layer, 1330, [("1NT", "PARTNER", 1.0), ("?", "YOU", 1.0)], pitch=260)
        ring_chip(layer, 1330, GOLD, 0.6 + 0.4 * abs(wave(t, 0.9)), x=540 + 130, w=182, h=76)

    def count(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GOLD, OUT(seg(t, 0.8, 1.3))) if c[1] == "S" else None,
                  dim=lambda c: 0.45 * OUT(seg(t, 0.8, 1.3)) if c[1] != "S" else 0.0)
        tally(layer, "10 POINTS · 4 SPADES", pop=seg(t, 0.2, 0.7))

    def ask(t, dur, layer):
        draw_rows(layer, sl)
        tb = L.at(2, "bid", 2.4)
        auction(layer, 330, [("1NT", "PARTNER", 1.0), ("2♣", "YOU", seg(t, tb, tb + 0.5))])
        ts = L.at(2, "stayman", 4.6)
        tally(layer, "STAYMAN: ASKS FOR A MAJOR", 445, 44, GOLD, pop=seg(t, ts, ts + 0.5))

    def reply(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GREEN, OUT(seg(t, 2.6, 3.1))) if c[1] == "S" else None)
        th = L.at(3, "here", 3.0)
        auction(layer, 330, [("1NT", "PARTNER", 1.0), ("2♣", "YOU", 1.0), ("2♠", "PARTNER", seg(t, th, th + 0.5))])

    def game(t, dur, layer):
        draw_rows(layer, sl)
        tb = L.at(4, "bid", 2.6)
        auction(layer, 330, [("1NT", "PARTNER", 1.0), ("2♣", "YOU", 1.0), ("2♠", "PARTNER", 1.0),
                             ("4♠", "YOU", seg(t, tb, tb + 0.5))])
        tg = L.at(4, "game", 1.9)
        tally(layer, "25 TO 27 POINTS = GAME", 445, 46, GREEN, pop=seg(t, tg, tg + 0.5))

    def events():
        return [(2, L.at(2, "bid", 2.4), "click", 0.4), (3, L.at(3, "here", 3.0), "click", 0.4),
                (4, L.at(4, "game", 1.9), "ding", 0.18), (4, L.at(4, "bid", 2.6), "click", 0.4)]

    L = lesson("bridge-stayman", lines, ("Partner opens 1NT.", "What now?"), [hook, count, ask, reply, game], events,
               {"fifteen to seventeen": "15 to 17", "one notrump": "1NT", "ten plus": "10 plus", "ten": "10",
                "eight": "8", "two clubs": "2 clubs", "two spades": "2 spades", "four spades": "4 spades"}, 1)
    return L


# ---------------------------------------------------------------- V16: support points

def v16() -> kit.Lesson:
    lines = [
        "Partner opens one heart. Count your support points.",
        "You hold four hearts, a fit. Your high-card points: five.",
        "A singleton adds three. That makes eight support points.",
        "Six to ten support points is a simple raise. Bid two hearts.",
    ]
    hand = LESSON_HANDS["V16"]
    sl = row_slots(hand)

    def hook(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GOLD, 0.5 + 0.5 * abs(wave(t, 1.1))) if c == "5C" else None,
                  bob=2.5 * wave(t, 1.6))
        auction(layer, 1330, [("1♥", "PARTNER", 1.0), ("?", "YOU", 1.0)], pitch=260)
        ring_chip(layer, 1330, GOLD, 0.6 + 0.4 * abs(wave(t, 0.9)), x=540 + 130, w=182, h=76)

    def fit(t, dur, layer):
        tf = L.at(1, "hearts", 1.2)
        honors = [c for c, _, _ in sl if c[0] in "AKQJ"]
        def rings(c):
            g = OUT(seg(t, 3.0, 3.5))
            if c in honors and g > 0.01:
                return GOLD, g
            return (GREEN, OUT(seg(t, tf, tf + 0.5))) if c[1] == "H" else None
        draw_rows(layer, sl, rings=rings)
        tally(layer, "4 HEARTS = A FIT", 370, 46, GREEN, pop=seg(t, tf, tf + 0.5))
        tp = L.at(1, "five", 3.6)
        tally(layer, "5 POINTS", 455, 50, GOLD, pop=seg(t, tp, tp + 0.5))

    def single(t, dur, layer):
        ts = L.at(2, "singleton", 0.5)
        draw_rows(layer, sl, rings=lambda c: (GOLD, OUT(seg(t, ts, ts + 0.5))) if c == "5C" else None)
        cx, cy = [(x, y) for c, x, y in sl if c == "5C"][0]
        kit.pill(layer, "+3", cx + ROW_W / 2 + 60, cy, 46, GOLD, INK, pop=seg(t, ts + 0.2, ts + 0.7))
        te = L.at(2, "eight", 2.6)
        tally(layer, "5 + 3 = 8", 455, 56, GREEN, pop=seg(t, te, te + 0.5))
        tally(layer, "SUPPORT POINTS", 370, 40, (16, 30, 26), pop=seg(t, 0.1, 0.6))

    def raise_(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GREEN, 1.0) if c[1] == "H" else None)
        tb = L.at(3, "bid", 2.8)
        auction(layer, 330, [("1♥", "PARTNER", 1.0), ("2♥", "YOU", seg(t, tb, tb + 0.5))])
        tally(layer, "6 TO 10 = SIMPLE RAISE", 445, 46, GREEN, pop=seg(t, 0.3, 0.8))

    def events():
        return [(1, L.at(1, "five", 3.6), "ding", 0.15), (2, L.at(2, "singleton", 0.5), "click", 0.4),
                (2, L.at(2, "eight", 2.6), "ding", 0.18), (3, L.at(3, "bid", 2.8), "click", 0.4)]

    L = lesson("bridge-support-points", lines, ("Support points", "with a fit."), [hook, fit, single, raise_], events,
               {"one heart": "1 heart", "six to ten": "6 to 10", "three": "3", "eight": "8", "five": "5",
                "two hearts": "2 hearts"}, 2)
    return L


# ---------------------------------------------------------------- V17: the 1-level response

def v17() -> kit.Lesson:
    lines = [
        "Partner opens one club. Do you answer?",
        "Count your points: six. Six or more means respond.",
        "You have four spades, so bid one spade.",
        "A new suit is forcing for one round, so partner bids again.",
        "Five points or fewer? Pass.",
    ]
    hand = LESSON_HANDS["V17"]
    sl = row_slots(hand)
    honors = [c for c, _, _ in sl if c[0] in "AKQJ"]

    def hook(t, dur, layer):
        draw_rows(layer, sl, bob=2.5 * wave(t, 1.6))
        auction(layer, 1330, [("1♣", "PARTNER", 1.0), ("?", "YOU", 1.0)], pitch=260)
        ring_chip(layer, 1330, GOLD, 0.6 + 0.4 * abs(wave(t, 0.9)), x=540 + 130, w=182, h=76)

    def count(t, dur, layer):
        tk = L.at(1, "six", 1.4)
        draw_rows(layer, sl, rings=lambda c: (GOLD, OUT(seg(t, 0.5, 1.0))) if c in honors else None,
                  dim=lambda c: 0.55 * OUT(seg(t, 0.5, 1.0)) if c not in honors else 0.0)
        tally(layer, "6 POINTS = RESPOND", pop=seg(t, tk, tk + 0.5))

    def bid(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GOLD, 1.0) if c[1] == "S" else None)
        tb = L.at(2, "bid", 2.0)
        auction(layer, 330, [("1♣", "PARTNER", 1.0), ("1♠", "YOU", seg(t, tb, tb + 0.5))])

    def forcing(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GOLD, 1.0) if c[1] == "S" else None)
        tp = L.at(3, "partner", 2.6)
        auction(layer, 330, [("1♣", "PARTNER", 1.0), ("1♠", "YOU", 1.0), ("?", "PARTNER", seg(t, tp, tp + 0.5))])
        tally(layer, "FORCING FOR ONE ROUND", 445, 44, GOLD, pop=seg(t, 0.4, 0.9))

    def weak(t, dur, layer):
        draw_rows(layer, sl, dim=lambda c: 0.4)
        tf = L.at(4, "pass", 1.6)
        tally(layer, "5 POINTS OR FEWER", 340, 46, GOLD, pop=seg(t, 0.2, 0.7))
        chip(layer, "Pass", 540, 445, pop=seg(t, tf, tf + 0.5), h=110)

    def events():
        return [(1, L.at(1, "six", 1.4), "ding", 0.18), (2, L.at(2, "bid", 2.0), "click", 0.4),
                (3, L.at(3, "partner", 2.6), "click", 0.4), (4, L.at(4, "pass", 1.6), "click", 0.4)]

    L = lesson("bridge-response", lines, ("Partner opens one club.", "Do you answer?"), [hook, count, bid, forcing, weak],
               events, {"one club": "1 club", "one spade": "1 spade", "six": "6", "five": "5", "four": "4"}, 3)
    return L


# ---------------------------------------------------------------- V18: counting losers

def v18() -> kit.Lesson:
    lines = [
        "In four hearts you can lose three tricks. Count your losers.",
        "Check each suit's top three cards. Every missing ace, king or queen is a loser.",
        "Spades, zero. Hearts, zero. Diamonds, two. Clubs, two. That's four.",
        "One too many. Dummy has two diamonds, so ruff your third diamond there.",
        "Three losers. Four hearts makes.",
    ]
    w, gap, pitch, y0 = 72, 6, 130, 730
    you_sl = {s: [r + s for r, x in cards_of(V18_YOU) if x == s] for s in "SHDC"}
    dm_sl = {s: [r + s for r, x in cards_of(V18_DUMMY) if x == s] for s in "SHDC"}
    lose = top_three_losers(V18_YOU, V18_DUMMY)

    def board(layer, badges: dict[str, tuple[int, float, tuple]] | None = None, dim=None, rings=None):
        kit.pill(layer, "YOU", 275, 638, 36, (16, 30, 26), CREAM, alpha=0.92)
        kit.pill(layer, "DUMMY", 775, 638, 36, (16, 30, 26), CREAM, alpha=0.92)
        for si, s in enumerate("SHDC"):
            y = y0 + si * pitch
            for j, c in enumerate(you_sl[s]):
                x = 460 - w / 2 - (len(you_sl[s]) - 1 - j) * (w + gap)
                put(layer, c, x, y, w, dim=dim(c) if dim else 0.0)
                if rings and rings(c):
                    ring(layer, x, y, w, *rings(c))
            for j, c in enumerate(dm_sl[s]):
                x = 620 + w / 2 + j * (w + gap)
                put(layer, c, x, y, w, dim=dim(c) if dim else 0.0)
                if rings and rings(c):
                    ring(layer, x, y, w, *rings(c))
            suit_tag(layer, s, y, x=508)
            if badges and s in badges:
                n, pop, color = badges[s]
                kit.pill(layer, str(n), 586, y, 34, color, pop=pop)

    def contract(layer, pop=1.0, y=420):
        chip(layer, "4♥", 300, y, pop=pop, h=96)
        kit.pill(layer, "LOSE UP TO 3", 640, y, 40, GOLD, INK, pop=pop)

    def hook(t, dur, layer):
        board(layer)
        contract(layer, y=545)
        ring_chip(layer, 545, GOLD, 0.5 + 0.5 * abs(wave(t, 1.0)), x=300, w=230, h=96)

    def rule(t, dur, layer):
        board(layer, rings=lambda c: (GOLD, 0.9) if c[0] in "AKQ" else None)
        contract(layer)

    def count(t, dur, layer):
        badges, total = {}, 0
        for s, word, dflt in (("S", "spades", 0.4), ("H", "hearts", 1.5), ("D", "diamonds", 2.6), ("C", "clubs", 3.8)):
            tw = L.at(2, word, dflt)
            p = seg(t, tw, tw + 0.5)
            if p > 0:
                badges[s] = (lose[s], p, GREEN if lose[s] == 0 else RED)
            if p > 0.5:
                total += lose[s]
        board(layer, badges)
        contract(layer)
        tally(layer, f"{total} LOSERS", 545, 48, RED if total > 3 else GREEN, pop=seg(t, 0.3, 0.8))

    def ruff(t, dur, layer):
        tr = L.at(3, "ruff", 3.0)
        p = seg(t, tr, tr + 0.7)
        badges = {"S": (0, 1.0, GREEN), "H": (0, 1.0, GREEN), "D": (1 if p > 0.8 else 2, 1.0, GREEN if p > 0.8 else RED),
                  "C": (2, 1.0, RED)}
        dia = set(you_sl["D"] + dm_sl["D"])
        th = L.at(3, "dummy", 1.0)
        board(layer, badges, dim=lambda c: 0.5 if c[1] != "D" else 0.0,
              rings=lambda c: (GOLD, OUT(seg(t, th, th + 0.5))) if c in dm_sl["D"] else (
                  (GREEN, OUT(p)) if c == "2D" else None))
        contract(layer)
        tally(layer, "3 LOSERS" if p > 0.8 else "4 LOSERS", 545, 48, GREEN if p > 0.8 else RED, pop=1.0)
        if p > 0:
            kit.arrow(layer, 424, y0 + 2 * pitch + 66, 656, y0 + 2 * pitch + 66, GREEN, p, width=10)
        kit.pill(layer, "RUFF IN DUMMY", 540, y0 + 3 * pitch + 85, 34, GREEN, pop=seg(t, tr + 0.3, tr + 0.8))

    def done(t, dur, layer):
        badges = {"S": (0, 1.0, GREEN), "H": (0, 1.0, GREEN), "D": (1, 1.0, GREEN), "C": (2, 1.0, RED)}
        board(layer, badges)
        contract(layer)
        tm = L.at(4, "makes", 1.9)
        tally(layer, "3 LOSERS", 545, 48, GREEN, pop=1.0)
        kit.check(layer, 880, 420, 40, GREEN, seg(t, tm, tm + 0.6))

    def events():
        ev = [(2, L.at(2, w_, d), "click", 0.35) for w_, d in (("spades", 0.4), ("hearts", 1.5), ("diamonds", 2.6),
                                                                 ("clubs", 3.8))]
        return ev + [(3, L.at(3, "ruff", 3.0), "ding", 0.18), (4, L.at(4, "makes", 1.9), "ding", 0.2)]

    L = lesson("bridge-losers", lines, ("Count your losers", "in a suit contract."), [hook, rule, count, ruff, done],
               events, {"zero": "0", "two": "2", "four": "4", "three": "3"}, 4)
    return L


# ---------------------------------------------------------------- V19: lead partner's suit

def v19() -> kit.Lesson:
    lines = [
        "Partner bid hearts. What do you lead?",
        "Partner showed hearts in the auction. Their suit is usually the friendliest lead.",
        "Your spades are all small, so hearts look better.",
        "King and queen, touching honors. Lead the king.",
    ]
    hand = LESSON_HANDS["V19"]
    sl = row_slots(hand)
    K_AT = (400, 400)

    def hook(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GOLD, 0.5 + 0.5 * abs(wave(t, 1.1))) if c[1] == "H" else None,
                  bob=2.5 * wave(t, 1.6))
        auction(layer, 1330, [("1♥", "PARTNER", 1.0)])

    def suit(t, dur, layer):
        draw_rows(layer, sl, rings=lambda c: (GREEN, OUT(seg(t, 0.4, 0.9))) if c[1] == "H" else None,
                  dim=lambda c: 0.45 * OUT(seg(t, 0.4, 0.9)) if c[1] != "H" else 0.0)
        tally(layer, "PARTNER'S SUIT", 440, 50, GREEN, pop=seg(t, 0.3, 0.8))

    def small(t, dur, layer):
        ts = L.at(2, "spades", 0.4)
        draw_rows(layer, sl, rings=lambda c: (GREEN, 1.0) if c[1] == "H" else None,
                  dim=lambda c: 0.45 if c[1] != "H" and c[1] != "S" else (0.0 if c[1] == "H" else 0.0))
        kit.pill(layer, "ALL SMALL", 540, 450, 40, RED, pop=seg(t, ts + 0.6, ts + 1.1))
        for j, (code, x, y) in enumerate([s for s in sl if s[0][1] == "S"]):
            ring(layer, x, y, ROW_W, RED, 0.8 * OUT(seg(t, ts + 0.6, ts + 1.1)))

    def lead(t, dur, layer):
        tk = L.at(3, "lead", 3.0)
        p = seg(t, tk - 0.2, tk + 0.5)
        draw_rows(layer, [s for s in sl if s[0] != "KH"], rings=lambda c: (GOLD, 1.0) if c in ("QH",) else None,
                  dim=lambda c: 0.45 if c[1] != "H" else 0.0)
        kx, ky = [(x, y) for c, x, y in sl if c == "KH"][0]
        if p <= 0:
            put(layer, "KH", kx, ky, ROW_W)
            ring(layer, kx, ky, ROW_W, GOLD, 1.0)
        else:
            x, y = kit.fly(p, (kx, ky), K_AT, arc=-60)
            put(layer, "KH", x, y, 140)
        kit.pill(layer, "LEAD THE KING", 760, 400, 44, GOLD, INK, pop=seg(t, tk + 0.3, tk + 0.8))

    def events():
        return [(3, L.at(3, "lead", 3.0), "click", 0.45), (1, 0.6, "ding", 0.15)]

    L = lesson("bridge-partner-suit", lines, ("Partner bid hearts.", "What do you lead?"), [hook, suit, small, lead], events,
               {}, 0)
    return L


# ---------------------------------------------------------------- V20: second hand low

def v20() -> kit.Lesson:
    lines = [
        "When should a defender play second hand low?",
        "Declarer leads a small club toward dummy's ace and jack.",
        "Rise with your king, and the ace captures it.",
        "Play low instead. The ace makes your king the top club. The jack loses to your king.",
        "Second hand low keeps your honor working.",
    ]
    w = 110
    DUM = {"AC": (420, 540), "JC": (540, 540), "5C": (660, 540)}
    YOU = {"KC": (410, 1160), "8C": (540, 1160), "2C": (670, 1160)}
    N_AT, W_AT, S_AT = (540, 730), (380, 860), (540, 990)

    def labels(layer):
        kit.pill(layer, "DUMMY", 135, 540, 32, (16, 30, 26), CREAM, alpha=0.92)
        kit.pill(layer, "YOU", 135, 1160, 32, (16, 30, 26), CREAM, alpha=0.92)
        kit.pill(layer, "DECLARER", 810, 990, 32, (16, 30, 26), CREAM, alpha=0.92)

    def cards(layer, gone=(), lift=None, extra=()):
        for table in (DUM, YOU):
            for c, (x, y) in table.items():
                if c in gone:
                    continue
                put(layer, c, x, y - (30 if c == lift else 0), w)

    def fly_card(layer, code, a, b, p, wd=w, arc=40):
        if p <= 0:
            return
        x, y = kit.fly(p, a, b, arc=arc)
        put(layer, code, x, y, wd, alpha=min(1, p * 3))

    def hook(t, dur, layer):
        labels(layer)
        cards(layer, lift="2C")
        put(layer, "4C", *S_AT, w)
        ring(layer, YOU["2C"][0], YOU["2C"][1] - 30, w, GREEN, 0.6 + 0.4 * abs(wave(t, 1.0)))

    def lead(t, dur, layer):
        labels(layer)
        cards(layer)
        tl = L.at(1, "leads", 0.6)
        fly_card(layer, "4C", (810, 990), S_AT, seg(t, tl, tl + 0.6))
        kit.arrow(layer, 540, 900, 540, 640, GOLD, seg(t, tl + 0.8, tl + 1.5), width=16)

    def rise(t, dur, layer):
        labels(layer)
        tk, ta = L.at(2, "king", 0.8), L.at(2, "ace", 2.4)
        cards(layer, gone=("KC", "AC"))
        put(layer, "4C", *S_AT, w)
        fly_card(layer, "KC", YOU["KC"], W_AT, seg(t, tk, tk + 0.6))
        fly_card(layer, "AC", DUM["AC"], N_AT, seg(t, ta, ta + 0.6))
        pc = seg(t, ta + 0.5, ta + 1.0)
        if pc > 0:
            kit.cross(layer, W_AT[0] + w / 2, W_AT[1] - w * CH / 2, 34, RED, pc)

    def low(t, dur, layer):
        labels(layer)
        tl, ta, tj = L.at(3, "low", 0.6), L.at(3, "ace", 2.0), L.at(3, "jack", 4.4)
        on_ace = seg(t, ta, ta + 0.5) * (1 - seg(t, tj - 0.3, tj))
        on_jack = seg(t, tj, tj + 0.5)
        gone = ["2C"] + (["AC"] if on_ace > 0.05 or on_jack > 0.05 else []) + (["JC"] if on_jack > 0.05 else [])
        cards(layer, gone=gone)
        put(layer, "4C", *S_AT, w)
        fly_card(layer, "2C", YOU["2C"], W_AT, seg(t, tl, tl + 0.6))
        if on_jack < 0.05:
            fly_card(layer, "AC", DUM["AC"], N_AT, seg(t, ta, ta + 0.6) * (1 - seg(t, tj - 0.3, tj)))
        if on_jack > 0.05:
            fly_card(layer, "JC", DUM["JC"], N_AT, seg(t, tj, tj + 0.6))
        k = YOU["KC"]
        ring(layer, k[0], k[1], w, GOLD, OUT(seg(t, ta + 0.4, ta + 0.9)))
        kit.check(layer, k[0] + w / 2 + 8, k[1] - w * CH / 2, 32, GREEN, seg(t, ta + 0.7, ta + 1.2))

    def keep(t, dur, layer):
        labels(layer)
        cards(layer, gone=("2C",))
        put(layer, "2C", *W_AT, w)
        put(layer, "4C", *S_AT, w)
        k = YOU["KC"]
        ring(layer, k[0], k[1], w, GOLD, 1.0)
        kit.check(layer, k[0] + w / 2 + 8, k[1] - w * CH / 2, 32, GREEN, 1.0)
        tk = L.at(4, "keeps", 0.8)
        kit.pill(layer, "SECOND HAND LOW", 540, 360, 46, GOLD, INK, pop=seg(t, tk - 0.4, tk + 0.1))

    def events():
        return [(1, L.at(1, "leads", 0.6) + 0.4, "click", 0.4), (2, L.at(2, "king", 0.8) + 0.3, "click", 0.4),
                (2, L.at(2, "ace", 2.4) + 0.3, "click", 0.4), (3, L.at(3, "low", 0.6) + 0.3, "click", 0.4),
                (3, L.at(3, "ace", 2.0) + 0.3, "click", 0.4), (3, L.at(3, "jack", 4.4) + 0.3, "click", 0.4),
                (3, L.at(3, "ace", 2.0) + 0.6, "ding", 0.18)]

    L = lesson("bridge-second-hand", lines, ("Second hand low", "keeps your king."), [hook, lead, rise, low, keep],
               events, {}, 1)
    return L


SHORTS = {
    "V1": (v1, "Count bridge points in 20 seconds"),
    "V2": (v2, "How a bridge trick works in 25 seconds"),
    "V3": (v3, "What trump means in bridge in 30 seconds"),
    "V4": (v4, "The bridge bidding ladder in 30 seconds"),
    "V5": (v5, "Bridge opening bids in 25 seconds"),
    "V6": (v6, "Bridge game contracts in 25 seconds"),
    "V7": (v7, "The bridge finesse in 25 seconds"),
    "V8": (v8, "The bridge opening lead in 25 seconds"),
    "V9": (v9, "What do you open with 16 points"),
    "V10": (v10, "What do you open with five spades"),
    "V11": (v11, "What do you open with three clubs and three diamonds"),
    "V12": (v12, "What do you open with 8 points"),
    "V13": (v13, "What do you open with 12 points"),
    "V14": (v14, "What do you open with five diamonds"),
    "V15": (v15, "Stayman after partner opens 1NT"),
    "V16": (v16, "Support points with a fit"),
    "V17": (v17, "Respond with 6 points"),
    "V18": (v18, "Count your losers"),
    "V19": (v19, "Lead partner's suit"),
    "V20": (v20, "Second hand low"),
}


CAPTIONS = {
    "V1": ("How to count high-card points in contract bridge: ace 4, king 3, queen 2, jack 1. 12 or more and you can "
           "usually open.", "#bridge #contractbridge #learnbridge #bridgetips #cardgames"),
    "V2": ("How a trick works in contract bridge: one card from each player, follow suit if you can, and the highest "
           "card of the suit led wins.", "#bridge #contractbridge #learnbridge #cardgames #bridgegame"),
    "V3": ("What trump means in contract bridge: any trump beats every other suit, but only once you're out of the "
           "suit led.", "#bridge #contractbridge #learnbridge #bridgetips #cardgames"),
    "V4": ("The bridge bidding ladder: clubs, diamonds, hearts, spades, then notrump. Every bid has to beat the last, "
           "and three passes end the auction.", "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V5": ("What to open in bridge, in Standard American: pass under 12, 1NT with 15 to 17 balanced, a 5-card major, "
           "or your longer minor.", "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V6": ("What game means in contract bridge: 3NT needs 9 tricks, 4 of a major 10, 5 of a minor 11. About 25 "
           "points between you is the usual guide.", "#bridge #contractbridge #learnbridge #bridgebidding #cardgames"),
    "V7": ("The finesse in contract bridge: with the ace and queen in dummy, lead toward them. When the king sits on "
           "your left, the queen wins.", "#bridge #contractbridge #bridgeplay #learnbridge #bridgetips"),
    "V8": ("The opening lead in bridge: with three touching honors, lead the top one. Once the ace is gone, the rest "
           "of your sequence wins.", "#bridge #contractbridge #bridgedefense #learnbridge #bridgetips"),
    "V9": ("What do you open with 16 points and a balanced 4-3-3-3 hand? One notrump: 15 to 17 points and balanced, "
           "with every major shorter than five cards.", "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V10": ("What do you open with 13 points and five spades? One spade: open a five-card major, your longest suit.",
            "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V11": ("What do you open with 13 points, three clubs and three diamonds? One club, the short club: with three of "
            "each minor and every major shorter than five cards, open your club.",
            "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V12": ("What do you open with 8 points and a longest suit of four cards? Pass: opening takes about 13 points, or "
            "a long suit.", "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V13": ("What do you open with 12 points, five hearts and four spades? One heart: 12 plus your two longest suits "
            "(5 + 4) makes 21, and 20 or more passes the Rule of 20.",
            "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V14": ("What do you open with 13 points, five diamonds and four hearts? One diamond: open your longest suit first.",
            "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V15": ("Stayman in Standard American: partner opens 1NT, you hold 8 or more points and a four-card major, so bid 2 "
            "clubs to ask. Partner names a four-card major if there is one.",
            "#bridge #bridgebidding #stayman #learnbridge #bridgetips"),
    "V16": ("Support points in contract bridge: with a fit for partner's major, add 3 for a singleton, 5 for a void and "
            "1 for a doubleton to your high-card points. 6 to 10 is a simple raise.",
            "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V17": ("Responding to a one-level opening in Standard American: with 6 or more points, bid a new suit at the one "
            "level. It is forcing for one round, so partner bids again.",
            "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V18": ("Counting losers in a suit contract: check the top three cards of each suit and count each missing ace, "
            "king or queen as a loser. Four hearts allows three, and ruffing in dummy can remove one.",
            "#bridge #bridgeplay #contractbridge #learnbridge #bridgetips"),
    "V19": ("What to lead when partner bid a suit: usually that suit. With king and queen, lead the king, the top of "
            "your touching honors.", "#bridge #bridgedefense #contractbridge #learnbridge #bridgetips"),
    "V20": ("Second hand low for defenders: when declarer leads a small card toward dummy's ace and jack, play low and "
            "your king stays a winner.", "#bridge #bridgedefense #contractbridge #learnbridge #bridgetips"),
}


def caption_txt(key: str) -> str:
    text, tags = CAPTIONS[key]
    return (
        "POST AS: Video (upload video.mp4).\n\n"
        f"CAPTION (paste as is):\n{text} Save this for bridge night.\n\n"
        f'I built {B.P.NAME} to practice this. Search "Bridge Trainer Learn and Bid" on the App Store, '
        "it's free to start.\n\n"
        f"{tags}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{B.P.PINNED.replace('on slide 4', 'in the video')}\n\n"
        f"REPLY to every \"app\" or \"name?\" comment:\n{B.P.REPLY}\n\n"
        "SOUND: keep the video's own audio (voice and score are original). Add nothing from the library.\n\n"
        "BEFORE POSTING (TikTok's Next button can publish straight away, so set these on the post screen first):\n"
        "More options > Disclose post content > Your brand.\n"
        "More options > AI-generated content: on (the narration is a synthetic voice).\n"
    )


def caption_narrow(base: Image.Image, group, t: float, alpha: float, maxw: int = 800) -> None:
    """The engine's word-by-word caption (render.caption) wrapped to `maxw`, so a line stops short of TikTok's right rail.

    Same type, colours and shadow; only the wrap width changes (the engine wraps at 880 to 900). V9 to V20 use it.
    """
    f = B.font(64, "Bold", serif=True)
    d = ImageDraw.Draw(base)
    space = d.textlength(" ", font=f)
    total = sum(d.textlength(wd[2], font=f) for wd in group) + space * (len(group) - 1)
    need = math.ceil(total / maxw)
    for slack in range(40, 400, 20):  # balanced rows, no orphan words
        limit = min(total / need + slack, maxw + 20)
        rows, row, width = [], [], 0.0
        for wd in group:
            w = d.textlength(wd[2], font=f)
            if row and width + space + w > limit:
                rows.append((row, width))
                row, width = [], 0.0
            width += (space if row else 0) + w
            row.append((wd, w))
        rows.append((row, width))
        if len(rows) <= need:
            break
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    lh = 84
    y = 1370 - len(rows) * lh // 2
    for row, width in rows:
        x = 540 - width / 2
        for (s, e, text), w in row:
            fill = R.AMBER if s <= t < e else CREAM
            a = int(255 * alpha)
            ld.text((x, y), text, font=f, fill=fill + (a,), stroke_width=5, stroke_fill=INK + (a,))
            x += w + space
        y += lh
    sh = layer.getchannel("A").filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.5))
    shadow = Image.new("RGBA", base.size, INK + (0,))
    shadow.putalpha(sh)
    base.alpha_composite(shadow, (0, 4))
    base.alpha_composite(layer)


def cap_size(path: pathlib.Path, limit: float = 9.2e6) -> None:
    """TikTok uploads here stay under 9.5 MB: squeeze the video track when the engine's CRF 23 lands above `limit`."""
    if path.stat().st_size <= limit:
        return
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                           capture_output=True, text=True, check=True)
    secs = float(probe.stdout)
    kbps = int((limit * 0.97 * 8 / secs) / 1000 - 200)
    tmp = path.with_suffix(".tmp.mp4")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(path), "-c:a", "copy", "-c:v", "libx264", "-preset", "slow",
                    "-b:v", f"{kbps}k", "-maxrate", f"{int(kbps * 1.4)}k", "-bufsize", f"{kbps * 2}k", "-pix_fmt", "yuv420p",
                    "-movflags", "+faststart", str(tmp)], check=True)
    tmp.replace(path)
    print(f"capped {path.name} to {path.stat().st_size / 1e6:.2f} MB at {kbps} kbps video")


def main() -> None:
    argv = sys.argv[1:]
    outdir = OUTDIR
    if "--out" in argv:
        k = argv.index("--out")
        outdir = pathlib.Path(argv[k + 1])
        del argv[k:k + 2]
    key = argv[0]
    if key == "check":
        print(check_hands())
        print(check_against_app())
        if "--deal" in argv:
            found = deal_candidates()
            for k, (hand, ans) in QUIZ_HANDS.items():
                print(f"{k} {hand} {'is' if hand in found[ans] else 'is NOT'} among the dealt {ans} candidates")
        return
    if key == "captions":
        for k, (_, title) in SHORTS.items():
            folder = outdir / f"{k} {title}"
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "caption.txt").write_text(caption_txt(k))
        return
    make, title = SHORTS[key]
    if int(key[1:]) >= 9:
        R.caption = caption_narrow
    if len(argv) < 2 or argv[1].startswith("--"):
        folder = outdir / f"{key} {title}"
        folder.mkdir(parents=True, exist_ok=True)
        argv.insert(1, str(folder / "video.mp4"))
    out = pathlib.Path(argv[1])
    sys.argv = argv  # the engine reads [out, --still ...] from argv[1:], after the key
    kit.run(make())
    if "--still" not in argv:
        cap_size(out)


if __name__ == "__main__":
    main()
