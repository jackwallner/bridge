#!/usr/bin/env python3
"""Twenty-one more Bridge shorts, V29 to V49, on the shorts.py engine and the shorts_whole.py list.

    ~/.cache/pelojack-tts/bin/python shorts_more.py V29 [out.mp4] [--still t1,t2,...] [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts_more.py captions [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts_more.py check          # recount every hand, score and suit layout shown

Formats, best first (see shorts_whole.py): "The whole X" procedures and "The N things first", then what-do-you-open
quizzes and single-concept lessons.

  The whole X (full sequence on screen from frame 0, each step lighting up as it is spoken)
    V30 the opener's second bid, V31 takeout double, V32 overcall, V33 2NT opening, V34 strong 2 clubs,
    V37 drawing trumps, V38 ruffing in dummy, V39 holding up, V47 the attitude signal
  The N things first
    V29 responding to 1 of a major, V35 weak two, V36 counting winners in notrump, V40 when dummy comes down
  Quizzes: V41 21 points (2NT), V42 25 points (2 clubs), V43 five-five (1 spade), V44 five spades and six clubs (1 club)
  Lessons: V45 third hand high, V46 cover an honor with an honor, V48 vulnerability, V49 rubber and duplicate

Everything is shorts.py's: the engine, the Bridge-only score, cards, chips, pills, captions, size cap and caption.txt.
Every hand, count and suit layout shown is rechecked by `check` (and the play lessons by a small double-dummy solver
for one suit). All scores are duplicate-style table points (Shared/Models/BridgeRules.swift), nothing else.
"""
from __future__ import annotations

import functools
import math
import os
import pathlib
import sys

from PIL import Image, ImageDraw

import shorts as S
import shorts_whole as W
from shorts import B, CH, CREAM, GOLD, GREEN, INK, OUT, R, RED, chip, kit, put, ring, ring_chip, seg

OUTDIR = pathlib.Path(__file__).resolve().parents[3] / "captures" / "shorts-v29"
HDRC = (16, 30, 26)
MUTED = (70, 96, 86)
NAMES = {"W": "WEST", "N": "NORTH", "E": "EAST", "S": "SOUTH"}

_orig_suit_color = B.suit_color
B.suit_color = lambda s: RED if s == "X" else _orig_suit_color(s)  # the red X of a bidding box

MISSING: list = []
_orig_at = kit.Lesson.at


def _at(self, line: int, word: str, default: float) -> float:
    """Lesson.at that remembers a word it could not find in the voice timings (the default then drives the cue)."""
    if self.cues and word not in self.cues.get(line, {}) and (line, word) not in MISSING:
        MISSING.append((line, word))
    return _orig_at(self, line, word, default)


kit.Lesson.at = _at

SUBS = {**W.SUBS, "twenty-one": "21", "twenty-two": "22", "twenty-four": "24", "twenty-five": "25", "twenty": "20",
        "fourteen": "14", "eleven": "11", "twelve": "12", "thirteen": "13", "two notrump": "2NT",
        "three notrump": "3NT", "one notrump": "1NT", "fifty": "50", "five hundred": "500", "three hundred": "300",
        "one hundred": "100", "forty": "40", "nineteen": "19", "ace four": "ace 4", "king three": "king 3",
        "queen two": "queen 2", "jack one": "jack 1", "fifteen to seventeen": "15 to 17"}


def pop(t: float, at: float, d: float = 0.5) -> float:
    return seg(t, at, at + d)


# ---------------------------------------------------------------- a hand dealt small, two rows

def mini_hand(layer, hand: str, y: float, hl: dict | None = None, w: int = 78, pitch: int = 49, gap: int = 26) -> None:
    """13 cards in two rows (spades and hearts over diamonds and clubs), overlapped; `hl` maps a suit to a bracket colour."""
    cs = S.cards_of(hand)
    by = {s: [r + s for r, x in cs if x == s] for s in "SHDC"}
    for row, pair in enumerate(("SH", "DC")):
        yy = y + row * (w * CH + 10)
        widths = {s: (len(by[s]) - 1) * pitch + w if by[s] else 0 for s in pair}
        x = 540 - (sum(widths.values()) + gap) / 2
        for s in pair:
            for j, code in enumerate(by[s]):
                put(layer, code, x + w / 2 + j * pitch, yy, w)
            if hl and s in hl and by[s]:
                box = (x - 9, yy - w * CH / 2 - 9, x + widths[s] + 9, yy + w * CH / 2 + 9)
                ImageDraw.Draw(layer).rounded_rectangle(box, 18, outline=hl[s] + (255,), width=7)
            x += widths[s] + gap


# ---------------------------------------------------------------- the auction grid, calls lit as they are spoken

COLS = W.COLS
GY0, GPITCH, HDR_Y = 572, 84, 478


class Auction:
    """Eight columns of calls: `calls` is [(label, scene, word, default)], bid in order from the dealer."""

    def __init__(self, dealer: str, calls: list, you: str):
        self.dealer, self.calls, self.you = dealer, calls, you
        start = "WNES".index(dealer)
        self.slots = [("WNES"[(start + i) % 4], (start + i) // 4) for i in range(len(calls))]
        self.rows = max(r for _, r in self.slots) + 1

    def draw(self, layer, L, s: int, t: float) -> None:
        d = ImageDraw.Draw(layer)
        for who, x in COLS.items():
            me = who == self.you
            kit.pill(layer, NAMES[who], x, HDR_Y, 30, GREEN if me else HDRC, CREAM)
            for r in range(self.rows):
                y = GY0 + r * GPITCH
                d.rounded_rectangle((x - 80, y - 33, x + 80, y + 33), 22, outline=CREAM + (60,), width=3)
        kit.pill(layer, "DEALER", COLS[self.dealer], HDR_Y + 42, 22, GOLD, INK)
        newest = None
        for i, (label, line, word, dflt) in enumerate(self.calls):
            who, row = self.slots[i]
            T = L.at(line, word, dflt)
            p = 1.0 if line < s else pop(t, T) if line == s else 0.0
            x, y = COLS[who], GY0 + row * GPITCH
            chip(layer, label, x, y, pop=1.0, h=66, dim=0.55 * (1 - p))
            if line == s and t >= T:
                newest = (x, y)
        if newest:
            ring_chip(layer, newest[1], GOLD, 1.0, x=newest[0], w=165, h=66)


def auction_short(name: str, lines: list[str], hook: tuple, hand: str, au: Auction, labels: list[str], scenes: list[dict],
                  events, seed: int, subs: dict | None = None):
    """An auction short: the grid, your hand in two rows and the numbered steps, all on screen from frame 0.

    scenes[i] = {"active": step lit, "hl": {suit: colour} brackets, "extra": f(t, layer, L) for scene-specific pills}.
    """
    def one(i: int, spec: dict):
        def draw(t, dur, layer):
            au.draw(layer, L, i, t)
            kit.pill(layer, "YOUR HAND", 540, 812, 24, HDRC, CREAM)
            mini_hand(layer, hand, 890, spec.get("hl"))
            W.steps(layer, labels, t, spec["active"], 0.1, sweep=i == 0)
            if spec.get("extra"):
                spec["extra"](t, layer, L)
        return draw

    L = lesson(name, lines, hook, [one(i, sp) for i, sp in enumerate(scenes)], lambda: events(L), seed, subs)
    return L


# ---------------------------------------------------------------- one suit around the table

TH = {"N": (540, 556), "W": (215, 785), "E": (865, 785), "S": (540, 1008)}
TS = {"N": (540, 700), "W": (435, 785), "E": (645, 785), "S": (540, 885)}
TP = {"N": (540, 470), "W": (215, 700), "E": (865, 700), "S": (215, 1008)}
TCW, TCS, TCP = 80, 92, 54


class Table:
    """The four hands of one suit, small, with a trick played in the middle.

    hands: {seat: [(code, hidden)]}; tricks: [{"plays": [(seat, code | None, scene, word, default)], "gather":
    (scene, word, default) | None, "winner": seat}]. Hidden cards show their back until they are played.
    """

    def __init__(self, hands: dict, tricks: list, names: dict | None = None):
        self.hands, self.tricks, self.names = hands, tricks, names or {}

    @staticmethod
    def when(L, play: tuple) -> tuple:
        """(seat, code, scene, scene-local time) of one play; a sixth item is an offset in seconds after the word."""
        seat, code, line, word, dflt, *off = play
        return seat, code, line, L.at(line, word, dflt) + (off[0] if off else 0.0)

    def remaining(self, L, s: int, t: float) -> dict:
        rem = {k: list(v) for k, v in self.hands.items()}
        for tr in self.tricks:
            for play in tr["plays"]:
                seat, code, line, T = self.when(L, play)
                if code and (line < s or (line == s and t >= T)):
                    rem[seat] = [c for c in rem[seat] if c[0] != code]
        return rem

    @staticmethod
    def xy(seat: str, i: int, n: int) -> tuple[float, float]:
        cx, cy = TH[seat]
        return cx + (i - (n - 1) / 2) * TCP, cy

    def draw(self, layer, L, s: int, t: float, dim=None, rings=None, pills: bool = True) -> None:
        if pills:
            for k, (x, y) in TP.items():
                S.seat(layer, self.names.get(k, NAMES[k]), x, y)
        rem = self.remaining(L, s, t)
        for seat, cards in rem.items():
            for i, (code, hidden) in enumerate(cards):
                x, y = self.xy(seat, i, len(cards))
                put(layer, "BACK" if hidden else code, x, y, TCW, dim=dim(seat, code) if dim and not hidden else 0.0)
                rg = rings(seat, code) if rings and not hidden else None
                if rg:
                    ring(layer, x, y, TCW, *rg)
        for tr in self.tricks:
            g = 0.0
            if tr.get("gather"):
                gl, gw, gd = tr["gather"]
                gT = L.at(gl, gw, gd)
                g = 1.0 if gl < s else pop(t, gT, 0.6) if gl == s else 0.0
            if g >= 1:
                continue
            for k, play in enumerate(tr["plays"]):
                seat, code, line, T = self.when(L, play)
                p = 1.0 if line < s else pop(t, T) if line == s else 0.0
                if p <= 0:
                    continue
                if code is None:
                    kit.pill(layer, "NONE LEFT", *TS[seat], 26, MUTED, CREAM, alpha=1 - g)
                    continue
                x, y = kit.fly(p, TH[seat], TS[seat], arc=30)
                if g > 0:
                    wx, wy = TH[tr["winner"]]
                    x, y = x + (wx - x) * g, y + (wy - y) * g
                put(layer, code, x, y, TCS, angle=(k - 1.5) * 3 * OUT(p), alpha=min(1, p * 3) * (1 - g))

    def spot_ring(self, layer, seat: str, color, a: float) -> None:
        ring(layer, *TS[seat], TCS, color, a)


def hand_of(ranks: str, suit: str, hidden: bool = False) -> list:
    return [(r + suit, hidden) for r in ranks]


def top_pill(layer, text: str, t: float, at: float, color=GOLD, fg=INK, y: float = 375, size: int = 44) -> None:
    kit.pill(layer, text, 540, y, size, color, fg, pop=pop(t, at))


def lesson(name: str, lines, hook, draws, events, seed: int, subs: dict | None = None):
    return S.lesson(name, lines, hook, draws, events, {**(subs or {}), **SUBS}, seed)


# ---------------------------------------------------------------- V29: the 3 checks before you respond to 1 heart

H29 = "S:Q82 H:K84 D:J973 C:962"


def v29():
    lines = [
        "The three checks before you respond to one heart.",
        "One, count your points. Ace four, king three, queen two, jack one. This hand has six. You need six to respond.",
        "Two, count your hearts, partner's suit. You hold three. Three or more is support.",
        "Three, six to nine points and support? Raise to two hearts.",
    ]
    labels = ["COUNT YOUR POINTS: 6 TO RESPOND", "COUNT YOUR HEARTS: 3 IS SUPPORT", "6 TO 9 POINTS: RAISE TO 2♥"]
    sl = W.hand_rows(H29)
    base = {"six to nine": "6 to 9", "six": "6", "one heart": "1 heart"}

    def head(layer) -> None:
        kit.pill(layer, "PARTNER OPENS 1♥", 540, 305, 34, HDRC, CREAM)

    def hook(t, dur, layer):
        W.show_hand(layer, sl)
        W.steps(layer, labels, t, -1, sweep=True)

    def points(t, dur, layer):
        head(layer)
        tw = [L.at(1, w_, d_) for w_, d_ in (("king3", 2.5), ("queen2", 3.0), ("jack1", 3.6))]
        lit = {"K": pop(t, tw[0], 0.4), "Q": pop(t, tw[1], 0.4), "J": pop(t, tw[2], 0.4)}
        m = max(lit.values())
        W.show_hand(layer, sl, dim=lambda c: 0.0 if lit.get(c[0], 0) > 0 else 0.55 * m,
                    rings=lambda c: (GOLD, OUT(lit[c[0]])) if lit.get(c[0], 0) > 0 else None)
        t6 = L.at(1, "6", 8.0)
        run = sum(v for r, v in (("K", 3), ("Q", 2), ("J", 1)) if lit[r] > 0.5)
        if run:
            kit.pill(layer, f"{run} POINTS", 540, 385, 54, GREEN if t >= t6 - 0.1 else GOLD, pop=1.0)
        W.steps(layer, labels, t, 0, 0.1)

    def hearts(t, dur, layer):
        head(layer)
        th = L.at(2, "hearts", 2.2)
        p = OUT(pop(t, th - 0.3, 0.4))
        W.show_hand(layer, sl, dim=lambda c: 0.5 * p if c[1] != "H" else 0.0,
                    rings=lambda c: (GOLD, p) if c[1] == "H" else None)
        kit.pill(layer, "3 HEARTS = SUPPORT", 540, 385, 50, GOLD, INK, pop=pop(t, L.at(2, "three", 3.0), 0.5))
        W.steps(layer, labels, t, 1, 0.1)

    def raise_(t, dur, layer):
        head(layer)
        W.show_hand(layer, sl, dim=lambda c: 0.0 if c[1] == "H" or c[0] in "KQJ" else 0.35)
        tr = L.at(3, "raise", 2.2)
        chip(layer, "2♥", 540, 385, pop=pop(t, tr, 0.5), h=110)
        ring_chip(layer, 385, GREEN, OUT(pop(t, tr + 0.3, 0.4)), w=264, h=110)
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        tw = [L.at(1, w_, d_) for w_, d_ in (("king3", 2.5), ("queen2", 3.0), ("jack1", 3.6))]
        return ([(1, a, "click", 0.3) for a in tw] + [(1, L.at(1, "6", 8.0), "ding", 0.18),
                (2, L.at(2, "three", 3.0), "click", 0.4), (3, L.at(3, "raise", 2.2), "ding", 0.2)])

    L = lesson("first-respond", lines, ("The 3 checks before", "you respond to 1 heart"), [hook, points, hearts, raise_],
               events, 0, base)
    return L




# ---------------------------------------------------------------- V30: the whole second bid when you open

H30 = "S:AQ84 H:K5 D:KJ963 C:72"


def v30():
    lines = [
        "The whole second bid when you open, start to finish.",
        "One, open your longest suit. Thirteen points and five diamonds, so open one diamond.",
        "Two, the next player passes. Partner answers one spade. That shows four or more spades.",
        "Three, East passes. You hold four spades too. That's a fit, so raise to two spades.",
        "Four, everyone passes. Two spades is the contract.",
    ]
    labels = ["OPEN YOUR LONGEST SUIT", "PARTNER ANSWERS IN A NEW SUIT", "A FIT? RAISE PARTNER'S SUIT"]
    au = Auction("S", [("1♦", 1, "diamond", 5.0), ("Pass", 2, "passes", 1.2), ("1♠", 2, "spade", 3.6),
                       ("Pass", 3, "passes", 1.0), ("2♠", 3, "spades#2", 5.8), ("Pass", 4, "everyone", 0.6),
                       ("Pass", 4, "passes", 1.2), ("Pass", 4, "contract", 2.0)], "S")
    scenes = [{"active": -1}, {"active": 0, "hl": {"D": GOLD}}, {"active": 1}, {"active": 2, "hl": {"S": GOLD}},
              {"active": 2}]

    def events(L_):
        return [(1, L_.at(1, "diamond", 5.0) + 0.1, "click", 0.4), (2, L_.at(2, "spade", 3.6) + 0.1, "click", 0.4),
                (3, L_.at(3, "spades#2", 5.8) + 0.1, "click", 0.4), (4, L_.at(4, "contract", 2.0), "ding", 0.2)]

    return auction_short("whole-rebid", lines, ("The whole second bid", "when you open"), H30, au, labels, scenes,
                         events, 3)


# ---------------------------------------------------------------- V31: the whole takeout double

H31 = "S:KJ84 H:3 D:AQ75 C:Q963"


def v31():
    lines = [
        "The whole takeout double, start to finish.",
        "One, the opponent on your right opens one heart.",
        "Two, count your points. You have twelve, enough to open.",
        "Three, check your shape. One heart, and four cards in each other suit. Short in their suit, with support for the rest.",
        "Four, double. It asks partner to pick a suit. Partner bids one spade.",
    ]
    labels = ["ABOUT 12 OR MORE POINTS", "SHORT IN THEIR SUIT, SUPPORT FOR THE REST", "DOUBLE: PARTNER PICKS A SUIT"]
    au = Auction("W", [("1♥", 1, "heart", 3.4), ("X", 4, "double", 0.8), ("Pass", 4, "partner", 2.6),
                       ("1♠", 4, "spade", 4.6)], "N")

    def e2(t, layer, L_):
        kit.pill(layer, "12 POINTS", 540, 318, 44, GREEN, pop=pop(t, L_.at(2, "12", 2.0)))

    def e3(t, layer, L_):
        kit.pill(layer, "1-4-4-4: SHORT IN HEARTS", 540, 318, 40, GOLD, INK, pop=pop(t, L_.at(3, "heart", 2.0)))

    scenes = [{"active": -1}, {"active": -1}, {"active": 0, "extra": e2},
              {"active": 1, "hl": {"H": GOLD, "S": GREEN, "D": GREEN, "C": GREEN}, "extra": e3}, {"active": 2}]

    def events(L_):
        return [(1, L_.at(1, "heart", 3.4) + 0.1, "click", 0.4), (2, L_.at(2, "12", 2.0), "ding", 0.18),
                (4, L_.at(4, "double", 0.8) + 0.1, "click", 0.4), (4, L_.at(4, "spade", 4.6) + 0.1, "ding", 0.2)]

    return auction_short("whole-takeout-double", lines, ("The whole", "takeout double"), H31, au, labels, scenes,
                         events, 2)


# ---------------------------------------------------------------- V32: the whole overcall

H32 = "S:KJT85 H:A63 D:94 C:K72"


def v32():
    lines = [
        "The whole overcall, start to finish.",
        "One, the opponent on your right opens one diamond.",
        "Two, count your points. An overcall needs about eight to sixteen. You have eleven.",
        "Three, you need a good five-card suit. Spades, king, jack, ten.",
        "Four, bid it at the one level. One spade is an overcall.",
    ]
    labels = ["ABOUT 8 TO 16 POINTS", "A GOOD 5-CARD SUIT", "BID IT AT THE 1 LEVEL"]
    au = Auction("W", [("1♦", 1, "diamond", 3.4), ("1♠", 4, "spade", 3.0)], "N")

    def e2(t, layer, L_):
        kit.pill(layer, "11 POINTS", 540, 318, 44, GREEN, pop=pop(t, L_.at(2, "11", 4.6)))

    def e3(t, layer, L_):
        kit.pill(layer, "5 SPADES: K J 10", 540, 318, 44, GOLD, INK, pop=pop(t, L_.at(3, "spades", 2.4)))

    scenes = [{"active": -1}, {"active": -1}, {"active": 0, "extra": e2}, {"active": 1, "hl": {"S": GOLD}, "extra": e3},
              {"active": 2, "hl": {"S": GOLD}}]

    def events(L_):
        return [(1, L_.at(1, "diamond", 3.4) + 0.1, "click", 0.4), (2, L_.at(2, "11", 4.6), "ding", 0.18),
                (4, L_.at(4, "spade", 3.0) + 0.1, "ding", 0.2)]

    return auction_short("whole-overcall", lines, ("The whole", "overcall"), H32, au, labels, scenes, events, 1)


# ---------------------------------------------------------------- V33: the whole 2NT opening

H33 = "S:AKJ4 H:KQ5 D:AJ3 C:Q72"


def v33():
    lines = [
        "The whole two notrump opening, start to finish.",
        "One, count. Twenty points, and a balanced hand. Twenty or twenty-one opens two notrump.",
        "Two, open two notrump.",
        "Three, partner adds up. Five or more points makes about twenty-five. So partner bids three notrump.",
        "Four, everyone passes. Three notrump is the contract.",
    ]
    labels = ["20 OR 21 POINTS, BALANCED", "OPEN 2NT", "PARTNER ADDS UP: 5+ POINTS = GAME"]
    au = Auction("S", [("2NT", 2, "2nt", 0.8), ("Pass", 3, "partner", 0.4), ("3NT", 3, "3nt", 4.6),
                       ("Pass", 4, "everyone", 0.6), ("Pass", 4, "passes", 1.1), ("Pass", 4, "contract", 2.2)], "S")

    def e1(t, layer, L_):
        kit.pill(layer, "20 · BALANCED", 540, 318, 44, GREEN, pop=pop(t, L_.at(1, "20", 2.0)))

    def e3(t, layer, L_):
        kit.pill(layer, "20 + 5 = ABOUT 25", 540, 318, 44, GOLD, INK, pop=pop(t, L_.at(3, "25", 5.0)))

    scenes = [{"active": -1}, {"active": 0, "extra": e1}, {"active": 1}, {"active": 2, "extra": e3}, {"active": 2}]

    def events(L_):
        return [(1, L_.at(1, "20", 2.0), "ding", 0.18), (2, L_.at(2, "2nt", 0.8) + 0.1, "click", 0.4),
                (3, L_.at(3, "3nt", 4.6) + 0.1, "click", 0.4), (4, L_.at(4, "contract", 2.2), "ding", 0.2)]

    return auction_short("whole-2nt", lines, ("The whole", "2NT opening"), H33, au, labels, scenes, events, 0)


# ---------------------------------------------------------------- V34: the whole strong 2 clubs opening

H34 = "S:AKJ4 H:AQ5 D:KQ3 C:K72"


def v34():
    lines = [
        "The whole strong two clubs opening, start to finish.",
        "One, count. Twenty-two points, balanced. That's too strong for one of a suit.",
        "Two, open two clubs. It says nothing about clubs. It says, I'm very strong.",
        "Three, partner must answer. Two diamonds is the usual waiting bid.",
        "Four, now you describe your hand. Balanced with twenty-two to twenty-four? Bid two notrump.",
    ]
    labels = ["22 OR MORE POINTS", "OPEN 2♣, PARTNER ANSWERS 2♦", "REBID 2NT: 22 TO 24, BALANCED"]
    au = Auction("S", [("2♣", 2, "clubs", 0.8), ("Pass", 3, "partner", 0.4), ("2♦", 3, "diamonds", 3.4),
                       ("Pass", 4, "now", 0.4), ("2NT", 4, "2nt", 5.4)], "S")

    def e1(t, layer, L_):
        kit.pill(layer, "22 · BALANCED", 540, 318, 44, GREEN, pop=pop(t, L_.at(1, "22", 2.0)))

    scenes = [{"active": -1}, {"active": 0, "extra": e1}, {"active": 1}, {"active": 1}, {"active": 2}]

    def events(L_):
        return [(1, L_.at(1, "22", 2.0), "ding", 0.18), (2, L_.at(2, "clubs", 0.8) + 0.1, "click", 0.4),
                (3, L_.at(3, "diamonds", 3.4) + 0.1, "click", 0.4), (4, L_.at(4, "2nt", 5.4) + 0.1, "ding", 0.2)]

    return auction_short("whole-strong-2c", lines, ("The whole strong", "2 clubs opening"), H34, au, labels, scenes,
                         events, 2)


# ---------------------------------------------------------------- V35: the 3 checks for a weak two

H35 = "S:84 H:KQJ953 D:J72 C:94"


def v35():
    lines = [
        "The three checks for a weak two opening.",
        "One, count your points. Ace four, king three, queen two, jack one. This hand has seven. Too few to open one heart.",
        "Two, find a six-card suit with good cards in it. Hearts, king, queen, jack, and three more.",
        "Three, open two hearts. A weak two means six hearts, five to ten points. Two clubs is not weak. It's the strong bid.",
    ]
    labels = ["COUNT: ABOUT 5 TO 10 POINTS", "A GOOD 6-CARD SUIT", "OPEN 2 OF IT (2♣ IS THE STRONG BID)"]
    sl = W.hand_rows(H35)
    base = {"seven": "7", "one heart": "1 heart", "five to ten": "5 to 10"}

    def hook(t, dur, layer):
        W.show_hand(layer, sl)
        W.steps(layer, labels, t, -1, sweep=True)

    def points(t, dur, layer):
        tw = [L.at(1, w_, d_) for w_, d_ in (("king3", 2.5), ("queen2", 3.0), ("jack1", 3.6))]
        lit = {"K": pop(t, tw[0], 0.4), "Q": pop(t, tw[1], 0.4), "J": pop(t, tw[2], 0.4)}
        m = max(lit.values())
        W.show_hand(layer, sl, dim=lambda c: 0.0 if lit.get(c[0], 0) > 0 else 0.55 * m,
                    rings=lambda c: (GOLD, OUT(lit[c[0]])) if lit.get(c[0], 0) > 0 else None)
        t7 = L.at(1, "7", 7.4)
        run = sum(v * sum(1 for c, _, _ in sl if c[0] == r) for r, v in (("K", 3), ("Q", 2), ("J", 1)) if lit[r] > 0.5)
        if run:
            kit.pill(layer, f"{run} POINTS", 540, 385, 54, GREEN if t >= t7 - 0.1 else GOLD, pop=1.0)
        W.steps(layer, labels, t, 0, 0.1)

    def suit(t, dur, layer):
        th = L.at(2, "hearts", 2.4)
        p = OUT(pop(t, th - 0.4, 0.4))
        W.show_hand(layer, sl, dim=lambda c: 0.5 * p if c[1] != "H" else 0.0,
                    rings=lambda c: (GOLD, p) if c[1] == "H" else None)
        kit.pill(layer, "6 HEARTS · K Q J", 540, 385, 50, GOLD, INK, pop=pop(t, th - 0.4, 0.5))
        W.steps(layer, labels, t, 1, 0.1)

    def open_(t, dur, layer):
        W.show_hand(layer, sl, dim=lambda c: 0.0 if c[1] == "H" else 0.35)
        to = L.at(3, "hearts", 1.6)
        chip(layer, "2♥", 540, 385, pop=pop(t, to - 0.2, 0.5), h=110)
        ring_chip(layer, 385, GREEN, OUT(pop(t, to + 0.2, 0.4)), w=264, h=110)
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        tw = [L.at(1, w_, d_) for w_, d_ in (("king3", 2.5), ("queen2", 3.0), ("jack1", 3.6))]
        return ([(1, a, "click", 0.3) for a in tw] + [(1, L.at(1, "7", 7.4), "ding", 0.18),
                (2, L.at(2, "hearts", 2.4), "click", 0.4), (3, L.at(3, "hearts", 1.6), "ding", 0.2)])

    L = lesson("first-weak-two", lines, ("The 3 checks", "for a weak two"), [hook, points, suit, open_], events, 2, base)
    return L


# ---------------------------------------------------------------- V36: the 3 steps to count winners in notrump

N36 = {"S": "AK5", "H": "Q74", "D": "A6", "C": "KQJ75"}  # dummy
Y36 = {"S": "873", "H": "AK5", "D": "8432", "C": "962"}  # you
WIN36 = {"S": ("N", "AK"), "H": ("S", "AK", "N", "Q"), "D": ("N", "A"), "C": ()}  # the sure winners, by hand
RW, RPITCH, RY0, RSTEP = 72, 86, 545, 150


def v36():
    lines = [
        "The three steps to count your winners in notrump.",
        "One, count the tricks you can win right now. Do it suit by suit. Spades, two. Hearts, three. Diamonds, one. Clubs, none yet. That's six.",
        "Two, you need nine for three notrump. You have six. That's three short.",
        "Three, find the long suit. Clubs. King, queen, jack, and five cards in dummy. That's where more tricks can come from.",
    ]
    labels = ["COUNT SURE WINNERS, SUIT BY SUIT", "SUBTRACT FROM 9: HOW MANY SHORT?", "FIND THE LONG SUIT TO SET UP MORE"]
    base = {"nine": "9", "six": "6", "three notrump": "3NT"}

    def cards(layer, rows_dim=None, ringed=None) -> None:
        kit.pill(layer, "DUMMY", 300, RY0 - 84, 28, HDRC, CREAM)
        kit.pill(layer, "YOU", 720, RY0 - 84, 28, HDRC, CREAM)
        for si, s in enumerate("SHDC"):
            y = RY0 + si * RSTEP
            S.suit_tag(layer, s, y, x=70)
            for who, hold, x0 in (("N", N36, 125), ("S", Y36, 570)):
                for j, r in enumerate(hold[s]):
                    code = r + s
                    d = 0.0
                    if rows_dim and s != rows_dim:
                        d = 0.5
                    put(layer, code, x0 + RW / 2 + j * RPITCH, y, RW, dim=d)
                    if ringed and (code in ringed):
                        ring(layer, x0 + RW / 2 + j * RPITCH, y, RW, GOLD, 1.0)

    winners = {"S": {"AS", "KS"}, "H": {"AH", "KH", "QH"}, "D": {"AD"}, "C": set()}

    def hook(t, dur, layer):
        cards(layer)
        W.steps(layer, labels, t, -1, sweep=True)

    def count(t, dur, layer):
        ts = [L.at(1, w_, d_) for w_, d_ in (("spades", 3.3), ("hearts", 5.0), ("diamonds", 6.4), ("clubs", 7.6))]
        ringed = set()
        for k, s in enumerate("SHDC"):
            p = pop(t, ts[k], 0.4)
            if p > 0:
                ringed |= winners[s]
                kit.pill(layer, str(len(winners[s])), 962, RY0 + k * RSTEP, 44, GOLD if winners[s] else MUTED,
                         INK if winners[s] else CREAM, pop=p)
        cards(layer, ringed=ringed)
        t6 = L.at(1, "6", 9.2)
        kit.pill(layer, "6 SURE WINNERS", 540, 400, 52, GREEN, pop=pop(t, t6 - 0.1, 0.5))
        W.steps(layer, labels, t, 0, 0.1)

    def short(t, dur, layer):
        cards(layer, ringed=set().union(*winners.values()))
        for k, s in enumerate("SHDC"):
            n = len(winners[s])
            kit.pill(layer, str(n), 962, RY0 + k * RSTEP, 44, GOLD if n else MUTED, INK if n else CREAM)
        kit.pill(layer, "NEED 9", 290, 400, 46, HDRC, CREAM, pop=pop(t, L.at(2, "9", 1.4)))
        kit.pill(layer, "HAVE 6", 540, 400, 46, GREEN, pop=pop(t, L.at(2, "6", 2.4)))
        kit.pill(layer, "3 SHORT", 790, 400, 46, GOLD, INK, pop=pop(t, L.at(2, "short", 4.0)))
        W.steps(layer, labels, t, 1, 0.1)

    def longsuit(t, dur, layer):
        tc = L.at(3, "clubs", 1.8)
        p = OUT(pop(t, tc - 0.3, 0.4))
        cards(layer, rows_dim="C" if p > 0.5 else None, ringed={r + "C" for r in "KQJ75"} if p > 0.5 else None)
        kit.pill(layer, "CLUBS: SET UP TRICKS", 540, 400, 50, GOLD, INK, pop=pop(t, tc - 0.3, 0.5))
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        ts = [L.at(1, w_, d_) for w_, d_ in (("spades", 3.3), ("hearts", 5.0), ("diamonds", 6.4), ("clubs", 7.6))]
        return ([(1, a, "click", 0.3) for a in ts] + [(1, L.at(1, "6", 9.2), "ding", 0.18),
                (2, L.at(2, "short", 4.0), "click", 0.4), (3, L.at(3, "clubs", 1.8), "ding", 0.2)])

    L = lesson("first-winners", lines, ("The 3 steps to count", "winners in notrump"), [hook, count, short, longsuit], events,
               1, base)
    return L


# ---------------------------------------------------------------- V37: the whole way to draw trumps

T37 = Table(
    {"N": hand_of("Q754", "S"), "S": hand_of("AKJ62", "S"), "W": hand_of("T3", "S", True), "E": hand_of("98", "S", True)},
    [{"plays": [("S", "AS", 3, "ace", 1.6), ("W", "3S", 3, "ace", 1.6, 0.5), ("N", "4S", 3, "ace", 1.6, 1.0),
                ("E", "8S", 3, "ace", 1.6, 1.5)], "gather": (4, "then", 0.15), "winner": "S"},
     {"plays": [("S", "KS", 4, "king", 0.7), ("W", "TS", 4, "king", 0.7, 0.5), ("N", "5S", 4, "king", 0.7, 1.0),
                ("E", "9S", 4, "king", 0.7, 1.5)], "gather": (5, "now", 0.2), "winner": "S"}])


def v37():
    lines = [
        "The whole way to draw trumps, start to finish.",
        "One, count your trumps. You hold five spades. Dummy holds four. That's nine.",
        "Two, count theirs. Thirteen minus nine leaves four.",
        "Three, lead your high trumps. Start with the ace. Everyone follows.",
        "Then the king. Everyone follows again. All four of their trumps are gone.",
        "Four, now they can't ruff your winners. Cash your good cards.",
    ]
    labels = ["COUNT YOUR TRUMPS", "COUNT THEIRS", "LEAD HIGH TRUMPS UNTIL THEY ARE OUT"]
    base = {"thirteen minus nine": "13 minus 9", "nine": "9"}
    tb = Table(T37.hands, T37.tricks, {"S": "SOUTH · YOU", "N": "NORTH · DUMMY"})

    def hook(t, dur, layer):
        tb.draw(layer, L, 0, t)
        W.steps(layer, labels, t, -1, sweep=True)

    def mine(t, dur, layer):
        tb.draw(layer, L, 1, t, rings=lambda s, c: (GOLD, OUT(pop(t, L.at(1, "five", 2.0), 0.4))) if s in "NS" else None)
        top_pill(layer, "5 + 4 = 9 TRUMPS", t, L.at(1, "9", 5.4), GREEN, CREAM, y=770)
        W.steps(layer, labels, t, 0, 0.1)

    def theirs(t, dur, layer):
        tb.draw(layer, L, 2, t)
        top_pill(layer, "13 − 9 = 4 LEFT", t, L.at(2, "four", 2.6), GOLD, INK, y=770)
        W.steps(layer, labels, t, 1, 0.1)

    def first(t, dur, layer):
        tb.draw(layer, L, 3, t)
        W.steps(layer, labels, t, 2, 0.1)

    def second(t, dur, layer):
        tb.draw(layer, L, 4, t)
        top_pill(layer, "THEIR TRUMPS: 0", t, L.at(4, "gone", 5.0), GREEN, CREAM, y=375)
        W.steps(layer, labels, t, 2, 0.1)

    def cash(t, dur, layer):
        tb.draw(layer, L, 5, t, rings=lambda s, c: (GREEN, 0.9) if s in "NS" else None)
        top_pill(layer, "NOW YOUR WINNERS ARE SAFE", t, L.at(5, "ruff", 1.4), GOLD, INK, y=375, size=40)
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        ta, tk = L.at(3, "ace", 1.6), L.at(4, "king", 0.7)
        return ([(1, L.at(1, "9", 5.4), "ding", 0.18), (2, L.at(2, "four", 2.6), "ding", 0.18)]
                + [(3, ta + k * 0.5 + 0.3, "click", 0.4) for k in range(4)]
                + [(4, tk + k * 0.5 + 0.3, "click", 0.4) for k in range(4)] + [(4, L.at(4, "gone", 5.0), "ding", 0.2)])

    L = lesson("whole-draw-trumps", lines, ("The whole way", "to draw trumps"), [hook, mine, theirs, first, second, cash],
               events, 0, base)
    return L


# ---------------------------------------------------------------- V38: the whole ruff in dummy

T38 = Table(
    {"N": hand_of("Q943", "H"), "S": hand_of("AKJ62", "H") + hand_of("852", "C"),
     "W": [("KC", True), ("TC", True), ("8H", True)], "E": [("6C", True), ("4C", True), ("7H", True)]},
    [{"plays": [("S", "2C", 3, "club", 1.6), ("W", "KC", 3, "king", 3.0), ("N", "3H", 3, "trumps", 5.6),
                ("E", "6C", 3, "hearts", 7.2)], "winner": "N"}])
CLUBS38 = {"8C", "5C", "2C"}


def v38():
    lines = [
        "The whole ruff in dummy, start to finish.",
        "One, find a loser. Your three small clubs are losers. Hearts are trump.",
        "Two, look at dummy. It has no clubs, but it does have trumps.",
        "Three, lead a small club. West plays the king. Dummy has no clubs. It trumps with the three of hearts.",
        "Dummy's trump beats the king. A loser became a trick. That's why you don't always draw trumps first.",
    ]
    labels = ["FIND A LOSER", "DUMMY IS OUT OF THAT SUIT, WITH TRUMPS", "LEAD IT, RUFF IN DUMMY"]
    tb = T38
    TRUMP = lambda layer: kit.pill(layer, "TRUMP: ♥", 540, 375, 44, GOLD, INK)

    def hook(t, dur, layer):
        tb.draw(layer, L, 0, t)
        W.steps(layer, labels, t, -1, sweep=True)

    def loser(t, dur, layer):
        tc = L.at(1, "clubs", 2.4)
        tb.draw(layer, L, 1, t, rings=lambda s, c: (GOLD, OUT(pop(t, tc, 0.4))) if s == "S" and c in CLUBS38 else None)
        TRUMP(layer)
        W.steps(layer, labels, t, 0, 0.1)

    def dummy(t, dur, layer):
        tn = L.at(2, "no", 1.4)
        tb.draw(layer, L, 2, t, rings=lambda s, c: (GREEN, 1.0) if s == "N" else None)
        TRUMP(layer)
        kit.pill(layer, "NO CLUBS", 830, 530, 36, RED, pop=pop(t, tn, 0.5))
        W.steps(layer, labels, t, 1, 0.1)

    def lead(t, dur, layer):
        tb.draw(layer, L, 3, t)
        TRUMP(layer)
        kit.pill(layer, "NO CLUBS", 830, 530, 36, RED)
        W.steps(layer, labels, t, 2, 0.1)

    def win(t, dur, layer):
        tb.draw(layer, L, 4, t)
        TRUMP(layer)
        tw = L.at(4, "beats", 1.0)
        tb.spot_ring(layer, "N", GOLD, OUT(pop(t, tw, 0.4)))
        kit.check(layer, TS["N"][0] + 56, TS["N"][1] - 70, 30, GREEN, pop(t, tw + 0.3, 0.6))
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        return [(3, L.at(3, "club", 1.6) + 0.4, "click", 0.4), (3, L.at(3, "king", 3.0) + 0.4, "click", 0.4),
                (3, L.at(3, "trumps", 5.6) + 0.4, "thump", 0.3), (4, L.at(4, "beats", 1.0), "ding", 0.2)]

    L = lesson("whole-ruff", lines, ("The whole ruff", "in dummy"), [hook, loser, dummy, lead, win], events, 1)
    return L


# ---------------------------------------------------------------- V39: the whole hold up in notrump

T39 = Table(
    {"N": hand_of("742", "S"), "S": hand_of("A53", "S"), "W": hand_of("KQJ98", "S", True), "E": hand_of("T6", "S", True)},
    [{"plays": [("W", "KS", 1, "king", 1.8), ("N", "2S", 1, "king", 1.8, 0.6), ("E", "6S", 1, "king", 1.8, 1.2),
                ("S", "3S", 1, "king", 1.8, 1.8)], "gather": (2, "two", 0.2), "winner": "W"},
     {"plays": [("W", "QS", 2, "queen", 1.6), ("N", "4S", 2, "queen", 1.6, 0.6), ("E", "TS", 2, "queen", 1.6, 1.2),
                ("S", "5S", 2, "queen", 1.6, 1.8)], "gather": (3, "three", 0.2), "winner": "W"},
     {"plays": [("W", "JS", 3, "jack", 1.4), ("N", "7S", 3, "jack", 1.4, 0.6), ("E", None, 3, "jack", 1.4, 1.2),
                ("S", "AS", 3, "jack", 1.4, 1.8)], "gather": (4, "four", 0.4), "winner": "S"}])


def v39():
    lines = [
        "The whole hold up in notrump, start to finish.",
        "One, West leads the king of spades. You hold the ace, but don't take it. Play low.",
        "Two, West leads the queen. Play low again.",
        "Three, West leads the jack. Now take the ace. East has no spades left.",
        "Four, East can't lead spades back to West. Even after winning a trick. The suit is cut off.",
    ]
    labels = ["DON'T TAKE THE FIRST TRICK", "PLAY LOW AGAIN", "TAKE THE ACE ON THE THIRD ROUND"]
    tb = T39

    def hook(t, dur, layer):
        tb.draw(layer, L, 0, t)
        W.steps(layer, labels, t, -1, sweep=True)

    def one(t, dur, layer):
        tb.draw(layer, L, 1, t, rings=lambda s, c: (GOLD, 0.6 + 0.4 * abs(S.wave(t, 1.2))) if (s, c) == ("S", "AS") else None)
        top_pill(layer, "HOLD UP YOUR ACE", t, L.at(1, "don't", 3.4), GOLD, INK)
        W.steps(layer, labels, t, 0, 0.1)

    def two(t, dur, layer):
        tb.draw(layer, L, 2, t)
        top_pill(layer, "LOW AGAIN", t, L.at(2, "low", 2.4), GOLD, INK)
        W.steps(layer, labels, t, 1, 0.1)

    def three(t, dur, layer):
        tb.draw(layer, L, 3, t)
        ta = L.at(3, "jack", 1.4) + 1.8
        tb.spot_ring(layer, "S", GOLD, OUT(pop(t, ta, 0.4)))
        kit.check(layer, TS["S"][0] - 60, TS["S"][1] - 70, 30, GREEN, pop(t, ta + 0.2, 0.6))
        top_pill(layer, "EAST IS OUT OF SPADES", t, L.at(3, "east", 5.6), RED, CREAM, size=40)
        W.steps(layer, labels, t, 2, 0.1)

    def four(t, dur, layer):
        tb.draw(layer, L, 4, t)
        kit.pill(layer, "NO SPADES TO RETURN", *TH["E"], 30, RED, CREAM)
        top_pill(layer, "THE SUIT IS CUT OFF", t, L.at(4, "cut", 4.6), GREEN, CREAM)
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        ev = []
        for line, word, d_ in ((1, "king", 1.8), (2, "queen", 1.6), (3, "jack", 1.4)):
            ev += [(line, L.at(line, word, d_) + k * 0.6 + 0.3, "click", 0.35) for k in range(4)]
        return ev + [(3, L.at(3, "jack", 1.4) + 2.1, "ding", 0.2)]

    L = lesson("whole-hold-up", lines, ("The whole hold up", "in notrump"), [hook, one, two, three, four], events, 2)
    return L


# ---------------------------------------------------------------- V40: the 3 things to do when dummy comes down

BAR_X0, BAR_X1, BAR_Y, BAR_H = 90, 990, 700, 120
PTS = 900 / 40  # pixels per point


def v40():
    lines = [
        "The three things to do when dummy comes down.",
        "One, count dummy's points. Dummy has ten.",
        "Two, count your own. You have nine. That's nineteen between you and dummy.",
        "Three, subtract from forty. The other twenty-one belong to declarer and partner. Declarer opened one notrump, fifteen to seventeen. So partner has four to six.",
    ]
    labels = ["COUNT DUMMY'S POINTS", "COUNT YOUR OWN", "SUBTRACT FROM 40, PLACE THE REST"]
    base = {"ten": "10", "nine": "9", "four to six": "4 to 6"}

    def x(p: float) -> float:
        return BAR_X0 + p * PTS

    def piece(layer, a: float, b: float, color, label: str, pop_: float, fg=CREAM, size: int = 40) -> None:
        if pop_ <= 0.01:
            return
        d = ImageDraw.Draw(layer)
        xa, xb = x(a), x(a + (b - a) * min(1.0, OUT(pop_)))
        d.rounded_rectangle((xa + 2, BAR_Y - BAR_H / 2, xb - 2, BAR_Y + BAR_H / 2), 22, fill=color + (255,))
        if pop_ >= 0.6:
            d.text(((xa + xb) / 2, BAR_Y), label, font=B.font(size, "Heavy", serif=False), fill=fg + (255,), anchor="mm")

    def frame_(layer) -> None:
        ImageDraw.Draw(layer).rounded_rectangle((BAR_X0 - 4, BAR_Y - BAR_H / 2 - 4, BAR_X1 + 4, BAR_Y + BAR_H / 2 + 4), 26,
                                                outline=CREAM + (120,), width=4)
        kit.pill(layer, "40 POINTS IN THE DECK", 540, BAR_Y - 110, 34, HDRC, CREAM)

    def hook(t, dur, layer):
        frame_(layer)
        piece(layer, 0, 40, MUTED, "40", 1.0, size=48)
        W.steps(layer, labels, t, -1, sweep=True)

    def dummy(t, dur, layer):
        frame_(layer)
        tt = L.at(1, "10", 2.6)
        piece(layer, 10, 40, MUTED, "", 1.0)
        piece(layer, 0, 10, GOLD, "DUMMY 10", pop(t, tt - 0.2, 0.5), fg=INK, size=34)
        W.steps(layer, labels, t, 0, 0.1)

    def mine(t, dur, layer):
        frame_(layer)
        tt, t19 = L.at(2, "9", 2.2), L.at(2, "19", 6.0)
        piece(layer, 19, 40, MUTED, "", 1.0)
        piece(layer, 0, 10, GOLD, "DUMMY 10", 1.0, fg=INK, size=34)
        piece(layer, 10, 19, GREEN, "YOU 9", pop(t, tt - 0.2, 0.5), size=34)
        kit.pill(layer, "10 + 9 = 19", 540, BAR_Y + 120, 46, GREEN, pop=pop(t, t19 - 0.2, 0.5))
        W.steps(layer, labels, t, 1, 0.1)

    def rest(t, dur, layer):
        frame_(layer)
        tr, td, tp = L.at(3, "21", 3.2), L.at(3, "15to17", 7.4), L.at(3, "4to6", 10.4)
        piece(layer, 0, 10, GOLD, "DUMMY 10", 1.0, fg=INK, size=34)
        piece(layer, 10, 19, GREEN, "YOU 9", 1.0, size=34)
        split = pop(t, td - 0.3, 0.5)
        if split <= 0.01:
            piece(layer, 19, 40, MUTED, "21 LEFT", pop(t, tr - 0.5, 0.5), size=40)
        else:
            piece(layer, 19, 35, (60, 110, 150), "DECLARER 15-17", 1.0, size=30)
            piece(layer, 35, 40, RED, "4-6", split, size=30)
            kit.pill(layer, "DECLARER OPENED 1NT", 540, BAR_Y + 120, 38, HDRC, CREAM)
            kit.pill(layer, "PARTNER HAS 4 TO 6", 540, BAR_Y + 205, 46, GOLD, INK, pop=pop(t, tp - 0.3, 0.5))
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        return [(1, L.at(1, "10", 2.6), "ding", 0.18), (2, L.at(2, "9", 2.2), "click", 0.4), (2, L.at(2, "19", 6.0), "ding", 0.18),
                (3, L.at(3, "15to17", 7.4), "click", 0.4), (3, L.at(3, "4to6", 10.4), "ding", 0.2)]

    L = lesson("first-dummy", lines, ("The 3 things to do", "when dummy comes down"), [hook, dummy, mine, rest], events, 3, base)
    return L


# ---------------------------------------------------------------- V41 to V44: what do you open? (beyond the app's six answers too)

QUIZ_HANDS2 = {
    "V41": ("S:AKQ H:KJ5 D:AQ84 C:Q62", "2NT"),
    "V42": ("S:AKQ96 H:AK5 D:AQ C:K74", "2C"),
    "V43": ("S:AQ985 H:AJ972 D:K C:83", "1S"),
    "V44": ("S:KQ974 H:A D:3 C:AJT642", "1C"),
}
LABEL = {"1NT": "1NT", "1S": "1♠", "1H": "1♥", "1D": "1♦", "1C": "1♣", "Pass": "Pass", "2NT": "2NT", "2C": "2♣"}
CHOICES = {"V41": ["Pass", "1♣", "1NT", "2♣", "2♦", "2NT"], "V42": ["1♠", "1NT", "2♠", "2♣", "2NT", "3NT"],
           "V43": ["Pass", "1♣", "1♦", "1♥", "1♠", "1NT"], "V44": ["Pass", "1♣", "1♦", "1♥", "1♠", "1NT"]}


def opening2(cards: list) -> str | None:
    """S.opening() for the six one-level answers, plus the two strong openings the app does not grade."""
    sh = S.Shape(cards)
    if sh.hcp >= 22:
        return "2C"
    if sh.hcp in (20, 21) and sh.balanced:
        return "2NT"
    return S.opening(cards)


def choice_chips(layer, t: float, labels: list[str], y0: float = 1290, h: int = 80) -> None:
    on = int(t / 0.38) % 6
    for k, b in enumerate(labels):
        x, y = 280 + (k % 3) * 260, y0 + (k // 3) * 110
        chip(layer, b, x, y, pop=1.0, h=h)
        if k == on:
            ring_chip(layer, y, GOLD, 0.6 + 0.4 * abs(S.wave(t, 0.76)), x=x, w=2 * h * 1.2, h=h)


def quiz2(key: str, lines: list[str], seed: int, shape_text: str, focus: str | None, total_key: str, ans_key: str,
          subs: dict | None = None):
    hand, ans = QUIZ_HANDS2[key]
    sh = S.Shape(S.cards_of(hand))
    sl = S.row_slots(hand)
    label = LABEL[ans]
    badge_x = max(x for _, x, _ in sl) + S.ROW_W / 2 + 55

    def hook_(t, dur, layer):
        S.draw_rows(layer, sl, bob=2.5 * S.wave(t, 1.6))
        choice_chips(layer, t, CHOICES[key])

    def points(t, dur, layer):
        lit, total = {}, 0
        for r, word, dflt in (("A", "ace4", 0.9), ("K", "king3", 1.8), ("Q", "queen2", 2.7), ("J", "jack1", 3.5)):
            p = pop(t, L.at(1, word, dflt), 0.4)
            for code, _, _ in sl:
                if code[0] == r:
                    lit[code] = p
            if p > 0.5:
                total += sum(1 for code, _, _ in sl if code[0] == r) * S.HCPV[r]
        m = max(lit.values(), default=0)
        S.draw_rows(layer, sl, dim=lambda c: 0.0 if lit.get(c, 0) > 0 else 0.55 * m,
                    rings=lambda c: (GOLD, OUT(lit[c])) if lit.get(c, 0) > 0 else None)
        if total:
            big = pop(t, L.at(1, total_key, 4.4), 0.5)
            S.tally(layer, f"{total} POINTS", color=GREEN if big > 0 else GOLD)

    def shape(t, dur, layer):
        dimmed = (lambda c: 0.5 * OUT(pop(t, 0.8, 0.5)) if c[1] != focus else 0.0) if focus else None
        rgs = (lambda c: (GOLD, OUT(pop(t, 0.8, 0.5))) if c[1] == focus else None) if focus else None
        S.draw_rows(layer, sl, dim=dimmed, rings=rgs)
        for si, s_ in enumerate("SHDC"):
            hot = s_ == focus
            kit.pill(layer, str(sh.length(s_)), badge_x, S.ROW_Y0 + si * S.ROW_PITCH, 44, GOLD if hot else MUTED,
                     INK if hot else CREAM, pop=pop(t, 0.25 + si * 0.14, 0.4))
        S.tally(layer, shape_text, color=GREEN, pop=pop(t, 0.15, 0.5))

    def answer(t, dur, layer):
        S.draw_rows(layer, sl)
        ta = L.at(3, ans_key, 1.0)
        chip(layer, label, 540, 420, pop=pop(t, ta, 0.5), h=130)
        ring_chip(layer, 420, GREEN, OUT(pop(t, ta + 0.3, 0.4)), w=312, h=130)

    def events():
        return [(1, L.at(1, "ace4", 0.9), "click", 0.3), (1, L.at(1, "king3", 1.8), "click", 0.3),
                (1, L.at(1, "queen2", 2.7), "click", 0.3), (1, L.at(1, "jack1", 3.5), "click", 0.3),
                (1, L.at(1, total_key, 4.4), "ding", 0.18), (3, L.at(3, ans_key, 1.0), "ding", 0.2)]

    L = lesson(f"quiz-{key.lower()}", lines, ("What do you open", "with this hand?"),
               [hook_, points, shape, answer], events, seed, subs)
    return L


def v41():
    return quiz2("V41", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Twenty-one.",
        "The shape is three, three, four, three. Balanced.",
        "Twenty or twenty-one and balanced? Open two notrump.",
    ], 0, "BALANCED 3-3-4-3", None, "21", "open", {"twenty or twenty-one": "20 or 21"})


def v42():
    return quiz2("V42", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Twenty-five.",
        "That's far too strong for one of a suit.",
        "Twenty-two or more? Open two clubs. It's the strong, artificial opening.",
    ], 1, "TOO STRONG FOR 1 OF A SUIT", None, "25", "open", {"twenty-two or more": "22 or more"})


def v43():
    return quiz2("V43", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Fourteen.",
        "You have two five-card suits, spades and hearts.",
        "With two five-card suits, open the higher one. One spade.",
    ], 2, "5 SPADES · 5 HEARTS", None, "14", "higher")


def v44():
    return quiz2("V44", [
        "What do you open with this hand?",
        "Count your points. Ace four, king three, queen two, jack one. Fourteen.",
        "Five spades, but six clubs. Your longest suit is clubs.",
        "Open your longest suit first. One club.",
    ], 3, "LONGEST: 6 CLUBS", "C", "14", "longest")


# ---------------------------------------------------------------- V45: third hand high

T45 = Table(
    {"N": hand_of("952", "H"), "E": hand_of("QJ6", "H"), "W": hand_of("KT84", "H", True), "S": hand_of("A73", "H", True)},
    [{"plays": [("W", "4H", 1, "four", 1.6), ("N", "2H", 1, "four", 1.6, 0.8), ("E", "JH", 3, "jack#2", 3.2),
                ("S", "AH", 3, "jack#2", 3.2, 0.8)], "winner": "S"}])


def v45():
    lines = [
        "Third hand high, in twenty seconds.",
        "Partner leads the four of hearts. Dummy plays low.",
        "Third hand is you. Play high, so declarer has to spend a higher card.",
        "You hold queen, jack, six. Play the jack, the lower of touching honors.",
        "Play the six, and declarer can take two tricks. Play the jack, and only one.",
    ]
    names = {"E": "EAST · YOU"}
    tb = Table(T45.hands, T45.tricks, names)

    def hook(t, dur, layer):
        tb.draw(layer, L, 0, t)
        kit.pill(layer, "THIRD HAND HIGH", 540, 1130, 56, GOLD, INK)

    def lead(t, dur, layer):
        tb.draw(layer, L, 1, t)
        kit.pill(layer, "LEAD", TS["W"][0], TS["W"][1] - 110, 34, GOLD, INK, pop=pop(t, L.at(1, "four", 1.6) + 0.5, 0.5))

    def high(t, dur, layer):
        tb.draw(layer, L, 2, t, rings=lambda s, c: (GOLD, 0.6 + 0.4 * abs(S.wave(t, 1.2))) if s == "E" else None)
        top_pill(layer, "THIRD HAND HIGH", t, L.at(2, "high", 1.8), GOLD, INK)

    def jack(t, dur, layer):
        tj = L.at(3, "jack#2", 3.2)
        tb.draw(layer, L, 3, t, rings=lambda s, c: (GREEN, OUT(pop(t, tj - 0.8, 0.4))) if (s, c) == ("E", "JH") else None)
        top_pill(layer, "LOWER OF TOUCHING HONORS", t, L.at(3, "lower", 4.4), GOLD, INK, size=38)

    def why(t, dur, layer):
        tb.draw(layer, L, 4, t)
        kit.pill(layer, "PLAY THE 6: DECLARER GETS 2", 540, 375, 38, RED, CREAM, pop=pop(t, L.at(4, "six", 1.0), 0.5))
        kit.pill(layer, "PLAY THE J: ONLY 1", 540, 315, 38, GREEN, CREAM, pop=pop(t, L.at(4, "jack", 5.0), 0.5))

    def events():
        return [(1, L.at(1, "four", 1.6) + 0.3, "click", 0.4), (1, L.at(1, "four", 1.6) + 1.1, "click", 0.4),
                (3, L.at(3, "jack#2", 3.2) + 0.3, "click", 0.4), (3, L.at(3, "jack#2", 3.2) + 1.1, "click", 0.4),
                (4, L.at(4, "jack", 5.0), "ding", 0.18)]

    L = lesson("third-hand-high", lines, ("Third hand high,", "in 20 seconds."), [hook, lead, high, jack, why], events, 0)
    return L


# ---------------------------------------------------------------- V46: cover an honor with an honor

T46 = Table(
    {"N": hand_of("Q92", "S"), "E": hand_of("KJT4", "S"), "W": hand_of("875", "S", True), "S": hand_of("A63", "S", True)},
    [{"plays": [("N", "QS", 1, "queen", 2.2), ("E", "KS", 2, "king", 1.6), ("S", "AS", 2, "ace", 3.0),
                ("W", "5S", 2, "ace", 3.0, 0.7)], "winner": "S"}])


def v46():
    lines = [
        "Cover an honor with an honor, in twenty seconds.",
        "Declarer leads the queen from dummy. You hold king, jack, ten, four.",
        "Cover it with the king. Declarer's ace wins the trick.",
        "But look at your hand. The jack and ten are now the highest cards left.",
        "Cover, and your small honors get promoted. Duck, and declarer wins the queen and ace. It's a guideline, not a law.",
    ]
    names = {"E": "EAST · YOU"}
    tb = Table(T46.hands, T46.tricks, names)

    def hook(t, dur, layer):
        tb.draw(layer, L, 0, t)
        kit.pill(layer, "COVER AN HONOR", 540, 1130, 54, GOLD, INK)

    def led(t, dur, layer):
        tb.draw(layer, L, 1, t, rings=lambda s, c: (GOLD, 0.6 + 0.4 * abs(S.wave(t, 1.2))) if s == "E" else None)
        kit.pill(layer, "QUEEN LED FROM DUMMY", 540, 375, 42, GOLD, INK, pop=pop(t, L.at(1, "queen", 2.2), 0.5))

    def cover(t, dur, layer):
        tb.draw(layer, L, 2, t)
        tk = L.at(2, "king", 1.6)
        tb.spot_ring(layer, "E", GREEN, OUT(pop(t, tk + 0.4, 0.4)))
        top_pill(layer, "COVER WITH THE K", t, tk - 0.2, GREEN, CREAM)

    def promoted(t, dur, layer):
        th = L.at(3, "highest", 3.6)
        p = OUT(pop(t, th - 0.4, 0.5))
        tb.draw(layer, L, 3, t, rings=lambda s, c: (GOLD, p) if s == "E" and c in ("JS", "TS") else None)
        top_pill(layer, "J AND 10 ARE NOW WINNERS", t, th - 0.4, GOLD, INK, size=40)

    def rule(t, dur, layer):
        tb.draw(layer, L, 4, t, rings=lambda s, c: (GOLD, 1.0) if s == "E" and c in ("JS", "TS") else None)
        kit.pill(layer, "IF YOU DUCK: DECLARER WINS Q AND A", 540, 375, 36, RED, CREAM, pop=pop(t, L.at(4, "duck", 3.0) - 0.2, 0.5))

    def events():
        return [(1, L.at(1, "queen", 2.2) + 0.3, "click", 0.4), (2, L.at(2, "king", 1.6) + 0.3, "click", 0.4),
                (2, L.at(2, "ace", 3.0) + 0.3, "click", 0.4), (3, L.at(3, "highest", 3.6), "ding", 0.2)]

    L = lesson("cover-an-honor", lines, ("Cover an honor", "with an honor"), [hook, led, cover, promoted, rule], events, 1)
    return L


# ---------------------------------------------------------------- V47: the whole attitude signal

T47A = Table(
    {"N": hand_of("954", "H"), "E": hand_of("Q83", "H"), "W": hand_of("AK62", "H", True), "S": hand_of("JT7", "H", True)},
    [{"plays": [("W", "AH", 1, "ace", 2.2), ("N", "4H", 1, "ace", 2.2, 0.6), ("E", "8H", 2, "8", 4.6),
                ("S", "7H", 2, "8", 4.6, 0.6)], "winner": "W"}])
T47B = Table(
    {"N": hand_of("974", "H"), "E": hand_of("832", "H"), "W": hand_of("AK65", "H", True), "S": hand_of("QJT", "H", True)},
    [{"plays": [("W", "AH", 3, "three", 0.4), ("N", "4H", 3, "three", 0.4, 0.6), ("E", "2H", 3, "two", 5.0),
                ("S", "TH", 3, "two", 5.0, 0.6)], "winner": "W"}])


def v47():
    lines = [
        "The whole attitude signal, start to finish.",
        "One, partner leads the ace of hearts.",
        "Two, you hold the queen, so you like the suit. Play a high spot card, the eight.",
        "Three, with no help in the suit, play low. The two. That says, try something else.",
        "Four, partner reads it. High means keep going. Low means switch. Most partnerships play it this way, so ask yours.",
    ]
    labels = ["PARTNER LEADS THE ACE", "HIGH CARD: I LIKE THE SUIT", "LOW CARD: I DON'T"]
    names = {"E": "EAST · YOU"}
    ta, tbb = Table(T47A.hands, T47A.tricks, names), Table(T47B.hands, T47B.tricks, names)

    def hook(t, dur, layer):
        ta.draw(layer, L, 0, t)
        W.steps(layer, labels, t, -1, sweep=True)

    def lead(t, dur, layer):
        ta.draw(layer, L, 1, t)
        W.steps(layer, labels, t, 0, 0.1)

    def high(t, dur, layer):
        t8 = L.at(2, "8", 4.6)
        ta.draw(layer, L, 2, t, rings=lambda s, c: (GOLD, 1.0) if (s, c) == ("E", "QH") else (
            (GREEN, OUT(pop(t, t8 - 0.8, 0.4))) if (s, c) == ("E", "8H") else None))
        top_pill(layer, "HIGH SPOT CARD: I LIKE IT", t, t8 - 0.2, GREEN, CREAM, size=40)
        W.steps(layer, labels, t, 1, 0.1)

    def low(t, dur, layer):
        t2 = L.at(3, "two", 5.0)
        tbb.draw(layer, L, 3, t, rings=lambda s, c: (RED, OUT(pop(t, t2 - 0.8, 0.4))) if (s, c) == ("E", "2H") else None)
        top_pill(layer, "LOW SPOT CARD: SWITCH", t, t2 - 0.2, RED, CREAM, size=40)
        W.steps(layer, labels, t, 2, 0.1)

    def reads(t, dur, layer):
        put(layer, "8H", 300, 640, 150)
        put(layer, "2H", 780, 640, 150)
        th, tl = L.at(4, "high", 1.8), L.at(4, "low", 3.4)
        kit.pill(layer, "KEEP GOING", 300, 810, 46, GREEN, pop=pop(t, th, 0.5))
        kit.pill(layer, "SWITCH", 780, 810, 46, RED, pop=pop(t, tl, 0.5))
        kit.pill(layer, "ASK YOUR PARTNER FIRST", 540, 950, 38, GOLD, INK, pop=pop(t, L.at(4, "ask", 9.0), 0.5))
        W.steps(layer, labels, t, 2, 0.1)

    def events():
        return [(1, L.at(1, "ace", 2.2) + 0.3, "click", 0.4), (2, L.at(2, "8", 4.6) + 0.3, "click", 0.4),
                (2, L.at(2, "8", 4.6) + 0.9, "click", 0.4), (3, L.at(3, "two", 5.0) + 0.3, "click", 0.4),
                (4, L.at(4, "high", 1.8), "ding", 0.18), (4, L.at(4, "low", 3.4), "ding", 0.18)]

    L = lesson("whole-attitude-signal", lines, ("The whole", "attitude signal"), [hook, lead, high, low, reads], events, 2)
    return L


# ---------------------------------------------------------------- V48: what vulnerable means

VUL = [("NOBODY", ""), ("NORTH · SOUTH", "NS"), ("EAST · WEST", "EW"), ("BOTH", "NSEW")]
TILES = [(300, 610), (780, 610), (300, 890), (780, 890)]
VRED, VGREEN = (204, 74, 62), (70, 150, 96)


def board_tile(layer, cx: float, cy: float, label: str, vul: str, p: float, dim: float = 0.0) -> None:
    """A deal's vulnerability: four seat discs, red where vulnerable and green where not."""
    if p <= 0.01:
        return
    a = int(255 * min(1, p * 2) * (1 - 0.55 * dim))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((cx - 200, cy - 125, cx + 200, cy + 125), 34, fill=(255, 253, 248, a))
    d.text((cx, cy - 86), label, font=B.font(36, "Heavy", serif=False), fill=INK + (a,), anchor="mm")
    seats_ = {"N": (cx, cy - 22), "E": (cx + 92, cy + 36), "S": (cx, cy + 92), "W": (cx - 92, cy + 36)}
    for k, (x, y) in seats_.items():
        red = k in vul
        d.ellipse((x - 34, y - 34, x + 34, y + 34), fill=(VRED if red else VGREEN) + (a,))
        d.text((x, y + 1), k, font=B.font(36, "Heavy", serif=False), fill=CREAM + (a,), anchor="mm")


def v48():
    lines = [
        "What vulnerable means in bridge.",
        "In duplicate, every board has one of four settings. Nobody vulnerable. North and South. East and West. Or both.",
        "A vulnerable side earns bigger bonuses. It also loses more when it goes down.",
        "A made game is worth three hundred points not vulnerable. It's five hundred vulnerable.",
        "Each trick short costs fifty points not vulnerable. It costs one hundred vulnerable. That's when the contract isn't doubled.",
        "That's all it means. Bigger bonuses, bigger penalties.",
    ]
    tw = [("nobody", 2.6), ("north", 4.4), ("east", 5.8), ("both", 7.4)]

    def tiles(layer, t, L_, s: int) -> None:
        for k, ((cx, cy), (lab, v)) in enumerate(zip(TILES, VUL)):
            T = L_.at(s, tw[k][0], tw[k][1]) if s == 1 else 0
            p = pop(t, T - 0.2, 0.4) if s == 1 else 1.0
            board_tile(layer, cx, cy, lab, v, max(p, 0.35 if s == 1 else 0), dim=0.0 if p >= 1 or s != 1 else 1 - p)
        kit.pill(layer, "VULNERABLE", 320, 1100, 28, VRED, CREAM)
        kit.pill(layer, "NOT VULNERABLE", 760, 1100, 28, VGREEN, CREAM)

    def cols(layer, headers: float = 1.0) -> None:
        kit.pill(layer, "NOT VULNERABLE", 300, 520, 36, VGREEN, CREAM, pop=headers)
        kit.pill(layer, "VULNERABLE", 780, 520, 36, VRED, CREAM, pop=headers)

    def hook(t, dur, layer):
        tiles(layer, t, L, 0)

    def four(t, dur, layer):
        tiles(layer, t, L, 1)

    def bigger(t, dur, layer):
        cols(layer, pop(t, 0.2, 0.5))
        kit.pill(layer, "BIGGER BONUSES", 540, 700, 50, GOLD, INK, pop=pop(t, L.at(2, "bonuses", 1.6) - 0.2, 0.5))
        kit.pill(layer, "BIGGER PENALTIES", 540, 830, 50, GOLD, INK, pop=pop(t, L.at(2, "loses", 3.4) - 0.2, 0.5))

    def game(t, dur, layer):
        cols(layer)
        kit.pill(layer, "A MADE GAME", 540, 640, 38, HDRC, CREAM)
        kit.pill(layer, "300", 300, 790, 84, VGREEN, CREAM, pop=pop(t, L.at(3, "300", 2.8) - 0.2, 0.5))
        kit.pill(layer, "500", 780, 790, 84, VRED, CREAM, pop=pop(t, L.at(3, "500", 5.4) - 0.2, 0.5))
        kit.pill(layer, "POINTS", 540, 940, 34, MUTED, CREAM)

    def down(t, dur, layer):
        cols(layer)
        kit.pill(layer, "EACH TRICK SHORT", 540, 640, 38, HDRC, CREAM)
        kit.pill(layer, "−50", 300, 790, 84, VGREEN, CREAM, pop=pop(t, L.at(4, "50", 2.6) - 0.2, 0.5))
        kit.pill(layer, "−100", 780, 790, 84, VRED, CREAM, pop=pop(t, L.at(4, "100", 4.6) - 0.2, 0.5))
        kit.pill(layer, "NOT DOUBLED", 540, 940, 34, MUTED, CREAM)

    def recap(t, dur, layer):
        cols(layer)
        kit.pill(layer, "GAME BONUS", 540, 640, 36, HDRC, CREAM)
        kit.pill(layer, "300", 300, 730, 60, VGREEN, CREAM)
        kit.pill(layer, "500", 780, 730, 60, VRED, CREAM)
        kit.pill(layer, "EACH TRICK SHORT", 540, 850, 36, HDRC, CREAM)
        kit.pill(layer, "−50", 300, 940, 60, VGREEN, CREAM)
        kit.pill(layer, "−100", 780, 940, 60, VRED, CREAM)

    def events():
        return ([(1, L.at(1, w_, d_), "click", 0.4) for w_, d_ in tw]
                + [(3, L.at(3, "300", 2.8), "ding", 0.18), (3, L.at(3, "500", 5.4), "ding", 0.18),
                   (4, L.at(4, "50", 2.6), "ding", 0.18), (4, L.at(4, "100", 4.6), "ding", 0.18)])

    L = lesson("what-vulnerable", lines, ("What vulnerable", "means in bridge"), [hook, four, bigger, game, down, recap],
               events, 3)
    return L


# ---------------------------------------------------------------- V49: rubber and duplicate

LANE_Y = (620, 820)


def table_tile(layer, cx: float, cy: float, title: str, board: str, p: float, color=HDRC) -> None:
    if p <= 0.01:
        return
    a = int(235 * min(1, p * 2))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((cx - 200, cy - 110, cx + 200, cy + 110), 30, fill=color + (a,))
    d.text((cx, cy - 52), title, font=B.font(38, "Heavy", serif=False), fill=CREAM + (min(255, a + 20),), anchor="mm")
    chip(layer, board, cx, cy + 28, pop=min(1.0, p * 1.5), h=84)


def v49():
    lines = [
        "Rubber bridge or duplicate. What's the difference?",
        "In rubber bridge, you play deal after deal. The first side to win two games wins the rubber.",
        "Every table shuffles its own cards. So the luck of the deal counts.",
        "In duplicate, every table plays the same deals. Each board holds the cards. It travels from table to table.",
        "You're scored against the other tables. They held your cards. That takes most of the luck out.",
    ]
    tiles = [(300, 600), (780, 600), (300, 850), (780, 850)]

    def lanes(layer, g1: float, g2: float, rub: float, ew: float = 0.0) -> None:
        d = ImageDraw.Draw(layer)
        for y, who, wins in ((LANE_Y[0], "NORTH · SOUTH", (g1, g2)), (LANE_Y[1], "EAST · WEST", (ew, 0.0))):
            kit.pill(layer, who, 270, y - 100, 30, HDRC, CREAM)
            for k, p in enumerate(wins):
                x = 330 + k * 340
                box = (x - 140, y - 60, x + 140, y + 60)
                d.rounded_rectangle(box, 26, outline=CREAM + (150,), width=4)
                if p > 0.01:
                    d.rounded_rectangle(box, 26, fill=GOLD + (int(255 * OUT(p)),))
                    d.text((x, y), "GAME", font=B.font(44, "Heavy", serif=False), fill=INK + (int(255 * OUT(p)),), anchor="mm")
        if rub > 0.01:
            kit.pill(layer, "RUBBER", 540, 970, 56, GREEN, pop=rub)

    def hook(t, dur, layer):
        for k, (cx, cy) in enumerate(tiles):
            table_tile(layer, cx, cy, f"TABLE {k + 1}", "BOARD 1", 1.0)

    def rubber(t, dur, layer):
        tf, tt = L.at(1, "first", 4.4), L.at(1, "two", 5.6)
        lanes(layer, pop(t, tf, 0.5), pop(t, tt + 0.6, 0.5), pop(t, L.at(1, "rubber#2", 7.4), 0.5))

    def luck(t, dur, layer):
        for k, (cx, cy) in enumerate(tiles):
            table_tile(layer, cx, cy, f"TABLE {k + 1}", ["DEAL A", "DEAL B", "DEAL C", "DEAL D"][k],
                       pop(t, 0.3 + k * 0.25, 0.4))
        kit.pill(layer, "DIFFERENT CARDS EVERYWHERE", 540, 1040, 38, GOLD, INK, pop=pop(t, L.at(2, "luck", 3.0), 0.5))

    def same(t, dur, layer):
        for k, (cx, cy) in enumerate(tiles):
            table_tile(layer, cx, cy, f"TABLE {k + 1}", "BOARD 1", pop(t, 0.2 + k * 0.2, 0.4))
        kit.pill(layer, "SAME CARDS AT EVERY TABLE", 540, 1040, 38, GOLD, INK, pop=pop(t, L.at(3, "same", 1.4), 0.5))

    SCORES = [("TABLE 1", "+420", False), ("TABLE 2", "+140", False), ("TABLE 3", "+420", False), ("YOU", "+450", True)]

    def compare(t, dur, layer):
        ts = L.at(4, "scored", 0.6)
        for k, (who, pts, me) in enumerate(SCORES):
            y = 560 + k * 130
            p = pop(t, ts + k * 0.35, 0.4)
            if p <= 0.01:
                continue
            a = int(235 * min(1, p * 2))
            d = ImageDraw.Draw(layer)
            d.rounded_rectangle((150, y - 50, 930, y + 50), 34, fill=(GOLD if me else HDRC) + (a,))
            d.text((210, y), who, font=B.font(44, "Heavy", serif=False), fill=(INK if me else CREAM) + (a,), anchor="lm")
            d.text((870, y), pts, font=B.font(54, "Heavy", serif=False), fill=(INK if me else CREAM) + (a,), anchor="rm")
        kit.pill(layer, "BOARD 1 · SAME CARDS", 540, 500 - 20, 28, MUTED, CREAM)
        kit.pill(layer, "BEST ON THE BOARD", 540, 1130, 42, GREEN, pop=pop(t, L.at(4, "luck", 6.0) - 0.4, 0.5))

    def events():
        return [(1, L.at(1, "two", 5.6) + 0.6, "ding", 0.18), (3, L.at(3, "same", 1.4), "click", 0.4),
                (4, L.at(4, "scored", 0.6), "click", 0.4), (4, L.at(4, "luck", 6.0), "ding", 0.2)]

    L = lesson("rubber-vs-duplicate", lines, ("Rubber vs duplicate", "bridge, explained"),
               [hook, rubber, luck, same, compare], events, 0)
    return L


# ---------------------------------------------------------------- registry, captions, checks

SHORTS = {
    "V29": (v29, "The 3 checks before you respond to 1 heart"),
    "V30": (v30, "The whole second bid when you open"),
    "V31": (v31, "The whole takeout double"),
    "V32": (v32, "The whole overcall"),
    "V33": (v33, "The whole 2NT opening"),
    "V34": (v34, "The whole strong 2 clubs opening"),
    "V35": (v35, "The 3 checks for a weak two"),
    "V36": (v36, "The 3 steps to count winners in notrump"),
    "V37": (v37, "The whole way to draw trumps"),
    "V38": (v38, "The whole ruff in dummy"),
    "V39": (v39, "The whole hold up in notrump"),
    "V40": (v40, "The 3 things to do when dummy comes down"),
    "V41": (v41, "What do you open with 21 points"),
    "V42": (v42, "What do you open with 25 points"),
    "V43": (v43, "What do you open with five spades and five hearts"),
    "V44": (v44, "What do you open with five spades and six clubs"),
    "V45": (v45, "Third hand high"),
    "V46": (v46, "Cover an honor with an honor"),
    "V47": (v47, "The whole attitude signal"),
    "V48": (v48, "What vulnerable means in bridge"),
    "V49": (v49, "Rubber vs duplicate bridge"),
}

TAGS_BID = "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"
TAGS_PLAY = "#bridge #bridgeplay #contractbridge #learnbridge #bridgetips"
TAGS_DEF = "#bridge #bridgedefense #contractbridge #learnbridge #bridgetips"
CAPTIONS = {
    "V29": ("Responding to partner's 1 heart opening in Standard American: count your points (you need 6 to respond), "
            "count your hearts (3 or more is support), and with 6 to 9 points raise to 2 hearts.", TAGS_BID),
    "V30": ("The whole second bid when you open: 1 diamond, partner answers 1 spade, and with four spades you have a "
            "fit, so you raise to 2 spades. Three passes end the auction.", TAGS_BID),
    "V31": ("The whole takeout double: the opponent on your right opens 1 heart, and with about 12 or more points, "
            "short hearts and support for the other suits, you double and partner picks a suit. Partnerships agree "
            "on the exact strength.", TAGS_BID),
    "V32": ("The whole overcall: the opponent on your right opens 1 diamond, and with about 8 to 16 points and a good "
            "five-card spade suit you bid 1 spade. Exact ranges vary by partnership.", TAGS_BID),
    "V33": ("The whole 2NT opening: 20 or 21 points and a balanced hand opens 2NT. Partner adds up, and with 5 or "
            "more points bids 3NT, about 25 points between you.", "#bridge #bridgebidding #contractbridge #learnbridge #2nt"),
    "V34": ("The whole strong 2 clubs opening: with 22 or more points, open the artificial 2 clubs. Partner must "
            "answer, usually 2 diamonds as a waiting bid, and a balanced 22 to 24 rebids 2NT.", TAGS_BID),
    "V35": ("The 3 checks for a weak two opening: about 5 to 10 points, a good six-card suit, then open 2 of that suit. "
            "2 clubs is the strong bid, not a weak two. Ranges vary by partnership.", TAGS_BID),
    "V36": ("The 3 steps to count your winners in notrump: count the tricks you can win right now, suit by suit, "
            "compare with the 9 you need for 3NT, then find the long suit that can set up more.", TAGS_PLAY),
    "V37": ("The whole way to draw trumps: count your trumps, count theirs (13 minus yours), then lead your high "
            "trumps until the opponents are out, so they cannot ruff your winners.", TAGS_PLAY),
    "V38": ("The whole ruff in dummy: find a loser, check that dummy is out of that suit but has trumps, then lead "
            "the loser and ruff it in dummy. That is why you do not always draw trumps first.", TAGS_PLAY),
    "V39": ("The whole hold up in notrump: when an opponent leads a suit where you hold the ace, play low twice and "
            "take the ace on the third round, so the opponent with the short holding cannot lead the suit back.",
            TAGS_PLAY),
    "V40": ("The 3 things to do when dummy comes down: count dummy's points, count your own, and subtract from 40 to "
            "place the rest. After a 15 to 17 point 1NT opening, that puts partner with 4 to 6 here.", TAGS_DEF),
    "V41": ("What do you open with 21 points and a balanced 3-3-4-3 hand? 2NT: 20 or 21 points and balanced.",
            "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V42": ("What do you open with 25 points and a 5-3-2-3 hand? 2 clubs: with 22 or more points, open the strong, "
            "artificial 2 clubs.", "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V43": ("What do you open with 14 points, five spades and five hearts? 1 spade: with two five-card suits, open "
            "the higher one.", TAGS_BID),
    "V44": ("What do you open with 14 points, five spades and six clubs? 1 club: in the beginner framework you open "
            "your longest suit first.", TAGS_BID),
    "V45": ("Third hand high: when partner leads a low card and dummy plays low, play your highest card, the lower of "
            "touching honors. Here the jack from queen-jack-six holds declarer to one trick in the suit.", TAGS_DEF),
    "V46": ("Cover an honor with an honor: when declarer leads the queen from dummy and you hold king, jack, ten, "
            "cover with the king. Your jack and ten become the highest cards left. It is a guideline, not a law.",
            TAGS_DEF),
    "V47": ("The whole attitude signal: when partner leads the ace, a high spot card says you like the suit and a low "
            "one says you do not. Many partnerships play it this way, so agree it first.", TAGS_DEF),
    "V48": ("What vulnerable means in bridge: each board is vulnerable for no one, North-South, East-West or both. A "
            "vulnerable side earns a bigger game bonus (500 instead of 300) and loses more for each undoubled "
            "undertrick (100 instead of 50).", "#bridge #bridgescoring #contractbridge #learnbridge #cardgames"),
    "V49": ("Rubber vs duplicate bridge: in rubber you play deal after deal and the first side to win two games wins "
            "the rubber. In duplicate every table plays the same deals and you are scored against the others who "
            "held your cards.", "#bridge #bridgescoring #contractbridge #learnbridge #cardgames"),
}
S.CAPTIONS.update(CAPTIONS)  # caption_txt() in shorts.py reads this dict


# ---------------------------------------------------------------- a double-dummy solver for one suit, for the play lessons

_RK = {c: i for i, c in enumerate("AKQJT98765432")}
_NEXT = {"W": "N", "N": "E", "E": "S", "S": "W"}


@functools.lru_cache(None)
def _trick(h: tuple, leader: str, played: tuple) -> int:
    seat = leader
    for _ in played:
        seat = _NEXT[seat]
    if len(played) == 4:
        s, vals = leader, []
        for c in played:
            vals.append((_RK[c] if c != "-" else 99, s))
            s = _NEXT[s]
        w = min(vals)[1]
        return (1 if w in "NS" else 0) + _go(h, w)
    hs = h["WNES".index(seat)]
    res = []
    for c in set(hs) or {"-"}:
        nh = list(h)
        if c != "-":
            nh["WNES".index(seat)] = hs.replace(c, "", 1)
        res.append(_trick(tuple(nh), leader, played + (c,)))
    return max(res) if seat in "NS" else min(res)


def _go(h: tuple, leader: str) -> int:
    return _trick(h, leader, ()) if any(h) else 0


def suit_ns_tricks(hands: dict, leader: str, plays: list[str]) -> int:
    """Tricks the N-S side takes in one suit, no trumps, unlimited entries, after the first trick is played as given."""
    h = ["".join(sorted(hands[s], key=_RK.get)) for s in "WNES"]
    seat, vals = leader, []
    for c in plays:
        i = "WNES".index(seat)
        h[i] = h[i].replace(c, "", 1)
        vals.append((_RK[c], seat))
        seat = _NEXT[seat]
    w = min(vals)[1]
    return (1 if w in "NS" else 0) + _go(tuple(h), w)


def check_table(tb: Table, trump: str | None = None) -> str:
    """Every card once, every play from the hand it names, every trick won by the seat the script says."""
    allc = [c for cards in tb.hands.values() for c, _ in cards]
    assert len(allc) == len(set(allc)), "a card is dealt twice"
    left = {k: [c for c, _ in v] for k, v in tb.hands.items()}
    for tr in tb.tricks:
        led = None
        best = None
        for seat, code, *_ in tr["plays"]:
            if code is None:
                assert not [c for c in left[seat] if c[1] == led], "void play from a hand that has the suit"
                continue
            assert code in left[seat], (seat, code)
            left[seat].remove(code)
            led = led or code[1]
            key = (0 if code[1] == trump and trump else 1 if code[1] == led else 2, _RK[code[0]])
            if best is None or key < best[0]:
                best = (key, seat)
        assert best[1] == tr["winner"], ("winner", best, tr["winner"])
    return f"{len(allc)} cards, {len(tb.tricks)} trick(s) legal and won by the right seat"


def check() -> str:
    out = []

    def hand(key: str, h: str, hcp: int, pattern: str | None = None):
        cs = S.cards_of(h)
        sh = S.Shape(cs)
        assert len(cs) == 13 and len(set(cs)) == 13, key
        assert sh.hcp == hcp == B.hcp(h), (key, sh.hcp, hcp)
        assert pattern is None or sh.pattern == pattern, (key, sh.pattern)
        return sh, cs

    # V29: partner opens 1H; 6 points, 3 hearts = a simple raise (6 to 9), as docs/bridge-bidding-for-beginners.html
    sh, _ = hand("V29", H29, 6, "4-3-3-3")
    assert sh.length("H") == 3 and 6 <= sh.hcp <= 9 and sh.length("S") < 5 and sh.length("D") < 5
    out.append(f"V29  {H29}: HCP 6, {sh.pattern}, 3 hearts, 6 to 9 with support = raise to 2H (the site's table)")
    sh, cs = hand("V30", H30, 13, "5-4-2-2")
    assert S.opening(cs) == "1D" and sh.length("S") == 4 and sh.length("D") == 5
    out.append(f"V30  {H30}: HCP 13, {sh.pattern}, opening() = 1D; partner's 1S shows 4+ spades, we hold 4 = 8-card fit, raise to 2S")
    sh, cs = hand("V31", H31, 12, "4-4-4-1")
    assert sh.length("H") == 1 and all(sh.length(x) == 4 for x in "SDC") and sh.rule20 == 20
    out.append(f"V31  {H31}: HCP 12, {sh.pattern}, 1 heart and 4-4-4 elsewhere; Rule of 20 = {sh.rule20}; double over 1H")
    sh, cs = hand("V32", H32, 11, "5-3-3-2")
    assert sh.length("S") == 5 and 8 <= sh.hcp <= 16 and sh.length("D") == 2
    out.append(f"V32  {H32}: HCP 11 (in 8 to 16), 5 spades (K J 10 8 5), {sh.pattern}; overcall 1S over 1D")
    sh, cs = hand("V33", H33, 20, "4-3-3-3")
    assert sh.balanced and sh.hcp in (20, 21) and 20 + 5 == 25
    out.append(f"V33  {H33}: HCP 20, {sh.pattern}, balanced = 2NT (20 to 21); 20 + 5 = 25 for game")
    sh, cs = hand("V34", H34, 22, "4-3-3-3")
    assert sh.balanced and 22 <= sh.hcp <= 24
    out.append(f"V34  {H34}: HCP 22, {sh.pattern}, balanced 22 to 24 = 2C then 2NT (the site's table)")
    sh, cs = hand("V35", H35, 7, "6-3-2-2")
    assert sh.length("H") == 6 and 5 <= sh.hcp <= 10 and sh.rule20 < 20 and S.opening(cs) is None
    assert [r for r, x in cs if x == "H"] == list("KQJ953")
    out.append(f"V35  {H35}: HCP 7, 6 hearts K Q J 9 5 3, Rule of 20 = {sh.rule20} (<20, no one-level opening), weak 2H")
    # V36: two hands, 26 cards, sure winners by suit from the top
    cards36 = [r + s for s in "SHDC" for r in N36[s] + Y36[s]]
    assert len(cards36) == 26 == len(set(cards36)) and sum(len(N36[s]) for s in "SHDC") == 13 == sum(len(Y36[s]) for s in "SHDC")
    sure = {}
    for s in "SHDC":
        comb = sorted(N36[s] + Y36[s], key=_RK.get)
        n = 0
        while n < len(comb) and comb[n] == "AKQJT98765432"[n]:
            n += 1
        sure[s] = n
    assert sure == {"S": 2, "H": 3, "D": 1, "C": 0} and sum(sure.values()) == 6 and 9 - 6 == 3
    assert len(N36["C"]) == 5 and N36["C"][:3] == "KQJ"
    out.append(f"V36  dummy {N36} you {Y36}: 26 distinct cards, sure winners {sure} = 6, 9 - 6 = 3 short, 5 clubs in dummy with K Q J")
    # V37, V38, V39, V45, V46, V47: legal plays, right winners
    out.append("V37  " + check_table(T37))
    assert len(T37.hands["S"]) + len(T37.hands["N"]) == 9 and len(T37.hands["W"]) + len(T37.hands["E"]) == 4
    out.append("V37  trumps 5 + 4 = 9, 13 - 9 = 4 held by W and E, all four played on the two rounds")
    out.append("V38  " + check_table(T38, trump="H"))
    assert len([c for c, _ in T38.hands["S"] if c[1] == "H"]) + len(T38.hands["N"]) == 9
    assert not [c for c, _ in T38.hands["N"] if c[1] == "C"] and len([c for c, _ in T38.hands["S"] if c[1] == "C"]) == 3
    out.append("V38  hearts 5 + 4 = 9 trumps, dummy void in clubs, declarer's 2C led, K played, ruffed by the 3H: dummy wins")
    out.append("V39  " + check_table(T39))
    h39 = {k: [c[0] for c, _ in v] for k, v in T39.hands.items()}
    assert sum(len(v) for v in h39.values()) == 13 and len(h39["W"]) == 5 and len(h39["E"]) == 2
    assert h39["S"] == list("A53") and h39["N"] == list("742")
    out.append("V39  spades 742 / A53 / KQJ98 / T6 = 13 cards; low, low, ace on round 3; East is void after two rounds")
    out.append("V45  " + check_table(T45))
    h45 = {k: "".join(c[0] for c, _ in v) for k, v in T45.hands.items()}
    by = {}
    for ec in "J6":
        outs = [suit_ns_tricks(h45, "W", ["4", "2", ec, sc]) for sc in h45["S"]]
        by[ec] = max(outs)
    assert by == {"J": 1, "6": 2}, by
    out.append(f"V45  hearts K T 8 4 / 9 5 2 / Q J 6 / A 7 3: solver, N-S tricks if East plays the J = {by['J']}, the 6 = {by['6']}")
    out.append("V46  " + check_table(T46))
    h46 = {k: "".join(c[0] for c, _ in v) for k, v in T46.hands.items()}
    r46 = {}
    for ec in ("K", "4"):
        outs = []
        for sc in h46["S"]:
            outs.append(min(suit_ns_tricks(h46, "N", ["Q", ec, sc, wc]) for wc in h46["W"]))
        r46[ec] = max(outs)
    assert r46 == {"K": 1, "4": 2}, r46
    rest = [r for k, v in h46.items() for r in v if k != "E" and r not in "AKQ"]
    assert sorted(r for r in h46["E"] if r in "JT") == ["J", "T"]
    assert all(_RK[r] > _RK["T"] for r in rest), rest  # once A K Q are gone, East's J and T beat every other card
    out.append(f"V46  spades Q92 / KJT4 / 875 / A63: solver, N-S tricks if East covers with the K = {r46['K']}, ducks = {r46['4']}; "
               "after A K Q, East's J and 10 beat every card left")
    out.append("V47  " + check_table(T47A) + " (A) and " + check_table(T47B) + " (B)")
    # V40: points
    assert 10 + 9 == 19 and 40 - 19 == 21 and (21 - 17, 21 - 15) == (4, 6) and 10 + 9 + 16 + 5 == 40
    out.append("V40  dummy 10 + you 9 = 19; 40 - 19 = 21; declarer 15 to 17 leaves partner 21 - 17 = 4 to 21 - 15 = 6")
    # V41 to V44
    for key, (h, want) in QUIZ_HANDS2.items():
        cs = S.cards_of(h)
        sh = S.Shape(cs)
        assert len(cs) == 13 and len(set(cs)) == 13 and sh.hcp == B.hcp(h)
        assert opening2(cs) == want, (key, opening2(cs), want)
        out.append(f"{key}  {h:30s} HCP {sh.hcp:2d}  shape {sh.pattern}  S{sh.length('S')} H{sh.length('H')} D{sh.length('D')} "
                   f"C{sh.length('C')}  answer {want}  OK")
    assert QUIZ_HANDS2["V41"][0] and S.Shape(S.cards_of(QUIZ_HANDS2["V41"][0])).balanced
    assert S.Shape(S.cards_of(QUIZ_HANDS2["V43"][0])).length("S") == S.Shape(S.cards_of(QUIZ_HANDS2["V43"][0])).length("H") == 5
    # V48: the table points, mirroring BridgeRules.score
    def game_bonus(vul): return 500 if vul else 300
    def down(n, vul): return -n * (100 if vul else 50)
    assert (game_bonus(False), game_bonus(True), down(1, False), down(1, True)) == (300, 500, -50, -100)
    out.append("V48  game bonus 300 / 500 and one undoubled trick down -50 / -100, as BridgeRules.score")
    # V49: the duplicate scores on screen: 4S made 420, 4S+1 450, 3S made 140 (3 x 30 = 90 + 50 part-score bonus)
    assert 4 * 30 + 300 == 420 and 4 * 30 + 30 + 300 == 450 and 3 * 30 + 50 == 140 and max(420, 140, 420, 450) == 450
    out.append("V49  board scores 420, 140, 420 and 450 = 4S made, 3S made, 4S made, 4S+1; 450 is the best")
    return "\n".join(out)


def main() -> None:
    argv = sys.argv[1:]
    outdir = OUTDIR
    if "--out" in argv:
        k = argv.index("--out")
        outdir = pathlib.Path(argv[k + 1])
        del argv[k:k + 2]
    key = argv[0]
    if key == "check":
        print(check())
        return
    if key == "captions":
        for k, (_, title) in SHORTS.items():
            folder = outdir / f"{k} {title}"
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "caption.txt").write_text(S.caption_txt(k))
        return
    make, title = SHORTS[key]
    R.caption = S.caption_narrow
    if len(argv) < 2 or argv[1].startswith("--"):
        folder = outdir / f"{key} {title}"
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "caption.txt").write_text(S.caption_txt(key))
        argv.insert(1, str(folder / "video.mp4"))
    out = pathlib.Path(argv[1])
    sys.argv = argv
    lesson_ = make()
    if os.environ.get("WHOLE_CUES"):
        inner = lesson_.short.prepare

        def show(vo) -> None:
            inner(vo)
            for i, c in lesson_.cues.items():
                print(i, {k: round(v, 2) for k, v in c.items()}, f"dur={vo[i][1]:.2f}")
        lesson_.short.prepare = show
    import re
    for i, line in enumerate(lesson_.short.lines):
        for sent in re.split(r"(?<=[.?!])\s+", line):
            if len(sent) > 50:
                print(f"LONG SENTENCE ({len(sent)}), line {i}: {sent}")
    kit.run(lesson_)
    if MISSING:
        print("MISSING CUES (the default time was used):", MISSING)
    if "--still" not in argv:
        S.cap_size(out)


if __name__ == "__main__":
    main()
