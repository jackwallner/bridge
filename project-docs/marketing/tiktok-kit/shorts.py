#!/usr/bin/env python3
"""Eight animated Bridge lesson shorts on the Mahj shorts engine.

    python3 shorts.py V1 [out.mp4] [--still t1,t2,...]
    python3 shorts.py all [--out <dir>]

The engine (~/ios/growth/animated-shorts-2026-10-27/render.py, with the lesson helpers in
~/ios/growth/tiktok-2026-10-29/kit.py) paints each scene with a watercolour pass, speaks the
lines with Kokoro, captions them word by word and adds its own synthesized score. This file
loads this kit's build_kit first, so the engine draws Bridge felt, icon and captures; cards
are this kit's drawn cards, laid on top crisp after the paint pass.
"""
from __future__ import annotations

import functools
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

import build_kit as B

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(pathlib.Path.home() / "ios/growth/tiktok-2026-10-29"))
B.cloth = B.felt  # the engine's end card and backgrounds read K.cloth
import kit  # noqa: E402
from kit import GOLD, GREEN, OUT, RED, bell, seg  # noqa: E402

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


def ring(layer, x: float, y: float, w: int, color, alpha: float) -> None:
    if alpha <= 0.01:
        return
    bw, bh = w + 22, int(w * CH) + 22
    box = (x - bw / 2, y - bh / 2, x + bw / 2, y + bh / 2)
    g = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).rounded_rectangle(box, int(w * 0.16), outline=color + (int(200 * alpha),), width=18)
    layer.alpha_composite(g.filter(ImageFilter.GaussianBlur(10)))
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
    sh = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((box[0], box[1] + 8, box[2], box[3] + 8), int(hh * 0.22),
                                         fill=(10, 20, 16, int(110 * (1 - dim))))
    layer.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    d.rounded_rectangle(box, int(hh * 0.22), fill=fill + (a,))
    color = CREAM if passing else B.suit_color(label)
    d.text((x, y + hh * 0.02), label, font=f, fill=color + (a,), anchor="mm")


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


SHORTS = {
    "V1": (v1, "Count bridge points in 20 seconds"),
    "V2": (v2, "How a bridge trick works in 25 seconds"),
    "V3": (v3, "What trump means in bridge in 30 seconds"),
    "V4": (v4, "The bridge bidding ladder in 30 seconds"),
    "V5": (v5, "Bridge opening bids in 25 seconds"),
    "V6": (v6, "Bridge game contracts in 25 seconds"),
    "V7": (v7, "The bridge finesse in 25 seconds"),
    "V8": (v8, "The bridge opening lead in 25 seconds"),
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


def main() -> None:
    key = sys.argv[1]
    if key == "captions":
        for k, (_, title) in SHORTS.items():
            folder = OUTDIR / f"{k} {title}"
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "caption.txt").write_text(caption_txt(k))
        return
    make, title = SHORTS[key]
    out_given = len(sys.argv) > 2 and not sys.argv[2].startswith("--")
    if not out_given:
        folder = OUTDIR / f"{key} {title}"
        folder.mkdir(parents=True, exist_ok=True)
        sys.argv.insert(2, str(folder / "video.mp4"))
    sys.argv = sys.argv[1:]  # the engine reads [out, --still ...] from argv[1:]
    kit.run(make())


if __name__ == "__main__":
    main()
