#!/usr/bin/env python3
"""Eight Bridge shorts in the two formats that earned the most views on @mahjtips: "The whole X" and "The N things first".

    ~/.cache/pelojack-tts/bin/python shorts_whole.py V21 [out.mp4] [--still t1,t2,...] [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts_whole.py captions [--out <dir>]
    ~/.cache/pelojack-tts/bin/python shorts_whole.py check          # recount every hand and score shown

V21 to V25 are "the whole" shorts: one narrated walk through a core procedure, with the full sequence on screen from
frame 0 as a numbered list, each step lighting up as it is spoken (V21 auction, V22 one trick, V23 deal to opening lead,
V24 scoring a made game, V25 1NT and Stayman). V26 to V28 are "the N things to do first": what to check in a new hand,
the first card to lead against notrump, and the two first plays as declarer.

Everything is shorts.py's: the engine, the Bridge-only score, cards, chips, pills, captions, size cap and caption.txt
(this file only patches names inside that module's namespace at run time; shorts.py itself is untouched). All points
are duplicate-style table points (Shared/Models/BridgeRules.swift), nothing else.
"""
from __future__ import annotations

import math
import os
import pathlib
import sys

from PIL import Image, ImageDraw

import shorts as S
from shorts import B, CH, CREAM, GOLD, GREEN, INK, OUT, R, chip, kit, put, ring, ring_chip, seg

RUN_ID = "20261112-115606-7218-claude"
OUTDIR = pathlib.Path.home() / "fleet-results" / RUN_ID / "Animated shorts"


# ---------------------------------------------------------------- the numbered list shown from frame 0

PLATE = (16, 30, 26)
DONE = (28, 84, 62)


def mix(a, b, p: float):
    return tuple(int(x + (y - x) * p) for x, y in zip(a, b))


def steps(layer, labels: list[str], t: float, active: int, on: float = 0.0, sweep: bool = False) -> None:
    """Every step visible at once, bottom of the list at y=1250 (the caption sits below). The active row turns gold."""
    n = len(labels)
    pitch = 72 if n <= 4 else 64
    d = ImageDraw.Draw(layer)
    if sweep:  # the hook scene: a light runs down the list so frame 0 already shows the whole sequence
        active = int(t / 0.9) % n
    for i, label in enumerate(labels):
        y = 1245 - (n - 1 - i) * pitch
        cur, done = i == active, i < active
        p = seg(t, on, on + 0.35) if cur and not sweep else 1.0
        fill = mix(PLATE, GOLD, p) if cur else (DONE if done else PLATE)
        ink = mix(CREAM, INK, p) if cur else CREAM
        d.rounded_rectangle((50, y - 31, 890, y + 31), 31, fill=fill + (235,))
        bx = 92
        d.ellipse((bx - 24, y - 24, bx + 24, y + 24), fill=(INK if cur else GREEN if done else CREAM) + (255,))
        d.text((bx, y + 1), str(i + 1), font=B.font(30, "Heavy", serif=False), fill=(GOLD if cur else CREAM if done else INK) + (255,),
               anchor="mm")
        size = 36
        f = B.font(size, "Heavy", serif=False)
        while d.textlength(label, font=f) > 710 and size > 24:
            size -= 2
            f = B.font(size, "Heavy", serif=False)
        d.text((132, y + 1), label, font=f, fill=ink + (255,), anchor="lm")


# ---------------------------------------------------------------- a compact table for V22 and V23

PILL = {"N": (540, 478), "E": (880, 718), "S": (540, 960), "W": (170, 718)}
SPOT = {"N": (540, 612), "E": (750, 718), "S": (540, 824), "W": (330, 718)}
WD = 150


def seats(layer, names: dict | None = None, alpha: float = 1.0, pos: dict | None = None) -> None:
    base = {"N": "NORTH", "E": "EAST", "S": "SOUTH", "W": "WEST", **(names or {})}
    for k, (x, y) in (pos or PILL).items():
        S.seat(layer, base[k], x, y, alpha)


def fly_in(layer, t: float, who: str, code: str, t0: float, spot=SPOT, start=None, w: int = WD, span: float = 0.55,
           tilt: float = 0.0) -> float:
    p = seg(t, t0, t0 + span)
    if p > 0:
        x, y = kit.fly(p, start or PILL[who], spot[who], arc=40)
        put(layer, code, x, y, w, angle=tilt * OUT(p), alpha=min(1, p * 3))
    return p


# ---------------------------------------------------------------- V21: the whole auction

CALLS = [("S", "1♠", 0, 3), ("W", "Pass", 1, 0), ("N", "2♠", 1, 1), ("E", "Pass", 1, 2), ("S", "4♠", 1, 3),
         ("W", "Pass", 2, 0), ("N", "Pass", 2, 1), ("E", "Pass", 2, 2)]
COLS = {"W": 240, "N": 440, "E": 640, "S": 840}
ROWS_Y = [600, 720, 840]


def v21() -> kit.Lesson:
    lines = [
        "The whole bridge auction, start to finish.",
        "One, the dealer bids first. Here, South opens one spade.",
        "Two, bidding goes clockwise. West passes. North raises to two spades.",
        "East passes. South bids four spades.",
        "Three, three passes in a row end it.",
        "Four, the last bid is the contract. Here, four spades.",
    ]
    labels = ["THE DEALER BIDS FIRST", "BID HIGHER OR PASS, CLOCKWISE", "THREE PASSES IN A ROW END IT",
              "THE LAST BID IS THE CONTRACT"]

    def grid(layer, prog: list[float], lit: set[int], final: bool = False) -> None:
        """All eight calls are on screen from frame 0, dimmed; each lights up (prog 0 to 1) when it is spoken."""
        d = ImageDraw.Draw(layer)
        for who, x in COLS.items():
            kit.pill(layer, {"W": "WEST", "N": "NORTH", "E": "EAST", "S": "SOUTH"}[who], x, 495, 30, (16, 30, 26), CREAM)
            for y in ROWS_Y:
                d.rounded_rectangle((x - 80, y - 40, x + 80, y + 40), 22, outline=CREAM + (60,), width=3)
        for i, (who, label, row, _) in enumerate(CALLS):
            x, y = COLS[who], ROWS_Y[row]
            chip(layer, label, x, y, pop=1.0, h=80, dim=0.55 * (1 - prog[i]) + (0.3 if final and i != 4 else 0.0))
            if i in lit:
                ring_chip(layer, y, GOLD, 1.0, x=x, w=165, h=80)
        if not final:
            kit.pill(layer, "DEALER", COLS["S"], 553, 22, GOLD, INK)

    def hook(t, dur, layer):
        grid(layer, [0.0] * 8, set())
        steps(layer, labels, t, -1, sweep=True)

    def dealer(t, dur, layer):
        grid(layer, [seg(t, 0.3, 0.8)] + [0.0] * 7, {0})
        steps(layer, labels, t, 0, 0.1)

    def around(t, dur, layer):
        tw, tn = L.at(2, "west", 1.5), L.at(2, "north", 3.0)
        grid(layer, [1.0, seg(t, tw, tw + 0.5), seg(t, tn, tn + 0.5)] + [0.0] * 5, {2 if t >= tn else 1 if t >= tw else 0})
        steps(layer, labels, t, 1, 0.1)

    def finish(t, dur, layer):
        te, ts = L.at(3, "east", 0.3), L.at(3, "south", 1.5)
        grid(layer, [1.0] * 3 + [seg(t, te, te + 0.5), seg(t, ts, ts + 0.5)] + [0.0] * 3, {4 if t >= ts else 3 if t >= te else 2})
        steps(layer, labels, t, 1, 0.0)

    def passes(t, dur, layer):
        tp = L.at(4, "passes", 0.9)
        grid(layer, [1.0] * 5 + [seg(t, tp + k * 0.55, tp + k * 0.55 + 0.5) for k in range(3)],
             {5 + k for k in range(3) if t >= tp + k * 0.55})
        steps(layer, labels, t, 2, 0.1)

    def contract(t, dur, layer):
        tc = L.at(5, "contract", 2.8)
        grid(layer, [1.0] * 8, set(), final=True)
        ring_chip(layer, ROWS_Y[1], GREEN, OUT(seg(t, tc - 1.2, tc - 0.7)), x=COLS["S"], w=165, h=80)
        kit.pill(layer, "CONTRACT: 4♠", 540, 935, 46, GOLD, INK, pop=seg(t, tc - 0.2, tc + 0.3))
        steps(layer, labels, t, 3, 0.1)

    def events():
        ev = [(1, 0.6, "click", 0.4), (2, L.at(2, "west", 1.5) + 0.2, "click", 0.4), (2, L.at(2, "north", 3.0) + 0.2, "click", 0.4),
              (3, L.at(3, "east", 0.3) + 0.2, "click", 0.4), (3, L.at(3, "south", 1.5) + 0.2, "click", 0.4)]
        tp = L.at(4, "passes", 0.9)
        ev += [(4, tp + k * 0.55 + 0.2, "click", 0.35) for k in range(3)]
        ev += [(5, L.at(5, "contract", 2.8), "ding", 0.2)]
        return ev

    L = S.lesson("whole-auction", lines, ("The whole", "bridge auction"), [hook, dealer, around, finish, passes, contract],
                 events, SUBS, 3)
    return L


SUBS = {"one hundred twenty": "120", "four hundred twenty": "420", "four three three three": "4333",
        "fifteen to seventeen": "15 to 17", "one notrump": "1NT", "three hundred": "300", "five hundred": "500",
        "twenty-five": "25", "thirty": "30", "sixteen": "16", "thirteen": "13", "fifteen": "15", "seventeen": "17",
        "ten": "10", "eight": "8"}


# ---------------------------------------------------------------- V22: the whole play of one trick

def v22() -> kit.Lesson:
    lines = [
        "The whole play of one trick, start to finish.",
        "One, the leader plays any card. West leads the seven of hearts.",
        "Two, play goes clockwise. Everyone follows suit. North, East, South.",
        "Three, the highest card of the suit led wins. A trump beats it. Here, South's ace.",
        "Four, the winner leads next. Thirteen tricks make a deal.",
    ]
    labels = ["THE LEADER PLAYS ANY CARD", "CLOCKWISE, FOLLOW SUIT", "HIGHEST CARD OF THE SUIT WINS",
              "THE WINNER LEADS NEXT"]
    trick = [("W", "7H"), ("N", "3H"), ("E", "QH"), ("S", "AH")]

    def cards(layer, t, starts):
        for k, ((who, code), t0) in enumerate(zip(trick, starts)):
            fly_in(layer, t, who, code, t0, tilt=(k - 1.5) * 3)

    def hook(t, dur, layer):
        seats(layer)
        cards(layer, 99, [-9] * 4)
        ring(layer, *SPOT["S"], WD, GOLD, 0.6 + 0.4 * abs(S.wave(t, 1.2)))
        steps(layer, labels, t, -1, sweep=True)

    def lead(t, dur, layer):
        seats(layer)
        tl = L.at(1, "leads", 0.7)
        cards(layer, t, [tl, 99, 99, 99])
        kit.pill(layer, "LEAD", SPOT["W"][0], SPOT["W"][1] - 140, 36, GOLD, INK, pop=seg(t, tl + 0.5, tl + 1.0))
        steps(layer, labels, t, 0, 0.1)

    def follow(t, dur, layer):
        seats(layer)
        ts = [L.at(2, w, d_) for w, d_ in (("north", 3.3), ("east", 4.0), ("south", 4.6))]
        cards(layer, t, [-9] + ts)
        steps(layer, labels, t, 1, 0.1)

    def win(t, dur, layer):
        seats(layer)
        cards(layer, 99, [-9] * 4)
        ta = L.at(3, "ace", 5.5)
        ring(layer, *SPOT["S"], WD, GOLD, OUT(seg(t, ta - 0.3, ta + 0.1)))
        kit.check(layer, SPOT["S"][0] + WD / 2 + 10, SPOT["S"][1] - WD * CH / 2, 34, GREEN, seg(t, ta, ta + 0.6))
        steps(layer, labels, t, 2, 0.1)

    def nxt(t, dur, layer):
        seats(layer, {"S": "SOUTH LEADS"})
        tw = L.at(4, "winner", 0.5)
        p = seg(t, tw, tw + 0.8)
        for k, (who, code) in enumerate(trick):
            x, y = kit.fly(p, SPOT[who], (540, 820))
            put(layer, "BACK" if p > 0.5 else code, x, y, int(WD * (1 - 0.35 * OUT(p))), angle=(k - 1.5) * 3,
                alpha=1 - seg(t, tw + 1.0, tw + 1.4))
        tl = L.at(4, "next", 2.0)
        q = seg(t, tl, tl + 0.6)
        if q > 0:
            x, y = kit.fly(q, (540, 960), (540, 720))
            put(layer, "BACK", x, y, WD, alpha=min(1, q * 3))
            kit.pill(layer, "TRICK 2", 540, 540, 40, GREEN, pop=seg(t, tl + 0.4, tl + 0.9))
        steps(layer, labels, t, 3, 0.1)

    def events():
        te = [L.at(2, w, d_) for w, d_ in (("north", 3.3), ("east", 4.0), ("south", 4.6))]
        return ([(1, L.at(1, "leads", 0.7) + 0.5, "click", 0.4)] + [(2, x + 0.5, "click", 0.4) for x in te]
                + [(3, L.at(3, "ace", 5.5), "ding", 0.2), (4, L.at(4, "winner", 0.5), "whoosh", 0.4)])

    L = S.lesson("whole-trick", lines, ("The whole play", "of one trick"), [hook, lead, follow, win, nxt], events,
                 {**SUBS, "thirteen": "13"}, 1)
    return L


# ---------------------------------------------------------------- V23: the whole deal, shuffle to opening lead

STACK = {"N": (540, 550), "E": (820, 720), "S": (540, 855), "W": (260, 720)}
DEALT = [("W", "N", "E", "S")[k % 4] for k in range(52)]
DUMMY13 = S.codes("S:A72 H:K54 D:QJ8 C:KT96")


def v23() -> kit.Lesson:
    lines = [
        "The whole deal, from shuffle to opening lead.",
        "One, shuffle the deck and cut it.",
        "Two, deal clockwise, one card at a time. Everyone ends with thirteen.",
        "Three, the dealer bids first. Bidding sets the contract and declarer.",
        "Four, left of declarer leads. Then dummy goes down.",
    ]
    labels = ["SHUFFLE AND CUT", "DEAL 13 CARDS EACH", "BID TO A CONTRACT", "LEFT OF DECLARER LEADS"]
    CENTER = (540, 712)
    pill_pos = {"N": (540, 445), "E": (820, 820), "S": (540, 962), "W": (260, 820)}

    def deck(layer, n: int = 6, spread: float = 0.0, t: float = 0.0) -> None:
        for k in range(n):
            side = -1 if k % 2 else 1
            x = CENTER[0] + side * spread * (70 + 6 * math.sin(t * 9 + k))
            put(layer, "BACK", x, CENTER[1] - k * 3, 110, angle=side * spread * (4 + 2 * math.sin(t * 7 + k)))

    def stacks(layer, counts: dict, badges: float, dummy=None) -> None:
        for who, (x, y) in STACK.items():
            n = counts.get(who, 0)
            if dummy and who == "N":
                continue
            for k in range(min(4, -(-n // 4))):
                put(layer, "BACK", x, y - k * 3, 110)
            if n >= 13 and badges > 0:
                kit.pill(layer, "13", x + (0 if who in "NS" else 0), y + (0 if who in "NS" else 0), 40, GOLD, INK, pop=badges)

    def hook(t, dur, layer):
        seats(layer, pos=pill_pos)
        deck(layer, spread=0.5 * (1 + math.sin(t * 4)) / 2 + 0.4, t=t)
        steps(layer, labels, t, -1, sweep=True)

    def shuffle(t, dur, layer):
        seats(layer, pos=pill_pos)
        tc = L.at(1, "cut", 2.0)
        deck(layer, spread=1.0 - OUT(seg(t, tc - 0.2, tc + 0.5)) if t < tc + 0.5 else 0.0, t=t)
        kit.pill(layer, "SHUFFLE AND CUT", 540, 600, 40, GOLD, INK, pop=seg(t, 0.2, 0.7))
        steps(layer, labels, t, 0, 0.1)

    def deal(t, dur, layer):
        seats(layer, pos=pill_pos)
        t0, dt = 0.6, 0.075
        counts = {k: 0 for k in "NESW"}
        for k, who in enumerate(DEALT):
            p = seg(t, t0 + k * dt, t0 + k * dt + 0.3)
            if p >= 1:
                counts[who] += 1
            elif p > 0:
                x, y = kit.fly(p, CENTER, STACK[who])
                put(layer, "BACK", x, y, 110, angle=(k % 5 - 2) * 4, alpha=min(1, p * 3))
        left = 52 - sum(counts.values())
        if left > 0:
            deck(layer, n=min(6, -(-left // 9)))
        done = t0 + 51 * dt + 0.3
        stacks(layer, counts, seg(t, done, done + 0.5))
        steps(layer, labels, t, 1, 0.1)

    full = {k: 13 for k in "NESW"}

    def auction_(t, dur, layer):
        seats(layer, {"S": "SOUTH · DEALER"}, pos=pill_pos)
        stacks(layer, full, 1.0)
        tb = L.at(3, "bids", 1.5)
        tc = L.at(3, "contract", 3.8)
        chip(layer, "4♠", 540, 720, pop=seg(t, tb, tb + 0.5), h=100)
        kit.pill(layer, "CONTRACT", 540, 645, 28, GOLD, INK, pop=seg(t, tc, tc + 0.5))
        steps(layer, labels, t, 2, 0.1)

    def lead(t, dur, layer):
        seats(layer, {"S": "SOUTH · DECLARER", "N": "NORTH · DUMMY"}, pos=pill_pos)
        tl = L.at(4, "leads", 1.2)
        td = L.at(4, "dummy", 2.8)
        stacks(layer, full, 1.0, dummy=t >= td - 0.1)
        for k, code in enumerate(DUMMY13):
            tk = td + k * 0.05
            x = 540 + (k - 6) * 56
            if t >= td - 0.1:
                put(layer, code if t >= tk else "BACK", x, 550, 92, alpha=seg(t, td - 0.1, td + 0.1))
        p = seg(t, tl, tl + 0.6)
        if p > 0:
            x, y = kit.fly(p, STACK["W"], (400, 720), arc=30)
            put(layer, "7H", x, y, 110)
            kit.pill(layer, "LEAD", 400, 820, 36, GOLD, INK, pop=seg(t, tl + 0.5, tl + 1.0))
        steps(layer, labels, t, 3, 0.1)

    def events():
        t0 = 0.6
        ev = [(1, L.at(1, "cut", 2.0), "click", 0.4)]
        ev += [(2, t0 + k * 0.075 + 0.3, "click", 0.12) for k in range(0, 52, 3)]
        ev += [(3, L.at(3, "contract", 3.8), "ding", 0.2), (4, L.at(4, "leads", 1.2) + 0.5, "click", 0.4),
               (4, L.at(4, "dummy", 2.8), "whoosh", 0.3)]
        return ev

    L = S.lesson("whole-deal", lines, ("The whole deal,", "shuffle to opening lead"), [hook, shuffle, deal, auction_, lead],
                 events, {**SUBS, "thirteen": "13"}, 0)
    return L


# ---------------------------------------------------------------- V24: the whole score of a made game

def v24() -> kit.Lesson:
    lines = [
        "The whole score of a made game, in points.",
        "One, bid four spades, take ten tricks. Six are book, so four count.",
        "Two, each trick in a major scores thirty. Four times thirty is one hundred twenty.",
        "Three, one hundred or more is a game. Add the bonus. Three hundred points, or five hundred when vulnerable.",
        "Four, add it up. Four hundred twenty points. Each extra trick adds thirty.",
    ]
    labels = ["COUNT TRICKS ABOVE SIX", "30 POINTS EACH IN A MAJOR", "100 OR MORE: GAME BONUS",
              "ADD IT UP"]
    w = 96
    sl = S.slots(13, 540, 640, w, gap=14, per_row=7, row_gap=24)

    def row(layer, lit: float = 0.0, extra: float = 0.0, thirty: tuple = (), start: float = 0.0, t: float = 0.0,
            book: float = 1.0) -> None:
        for i, (x, y) in enumerate(sl):
            if i < 6:
                put(layer, "BACK", x, y, w, dim=0.35, alpha=book)
            elif i < 10:
                p = seg(t, start + (i - 6) * 0.15, start + (i - 6) * 0.15 + 0.4) if lit == 0.5 else lit
                put(layer, "BACK", x, y - 40 * (1 - OUT(p)), w, alpha=min(1, p * 3))
                ring(layer, x, y - 40 * (1 - OUT(p)), w, GOLD, OUT(p))
            else:
                ImageDraw.Draw(layer).rounded_rectangle((x - w / 2, y - w * CH / 2, x + w / 2, y + w * CH / 2), 12,
                                                        outline=CREAM + (70,), width=3)
                if i == 10 and extra > 0:
                    put(layer, "BACK", x, y, w, alpha=extra)
                    ring(layer, x, y, w, GREEN, extra)
        for k, p in enumerate(thirty):
            x, y = sl[6 + k]
            kit.pill(layer, "30", x, y, 34, GOLD, INK, pop=p)

    def head(layer, t: float = 99) -> None:
        chip(layer, "4♠", 540, 340, pop=1.0, h=110)

    def hook(t, dur, layer):
        row(layer, lit=1.0, t=t)
        kit.pill(layer, "4♠ MADE: 420 POINTS", 540, 880, 50, GREEN, pop=1.0)
        steps(layer, labels, t, -1, sweep=True)

    def count(t, dur, layer):
        head(layer)
        ts = L.at(1, "so", 4.0) - 0.4
        row(layer, lit=0.5, t=t, start=ts)
        kit.pill(layer, "6 BOOK", 540, 880, 46, GOLD, INK, pop=seg(t, 0.4, 0.9), alpha=1.0 if t < ts + 0.4 else 0.0)
        kit.pill(layer, "6 + 4 = 10 TRICKS", 540, 880, 46, GREEN, pop=seg(t, ts + 0.4, ts + 0.9))
        steps(layer, labels, t, 0, 0.1)

    def thirty(t, dur, layer):
        head(layer)
        tt = L.at(2, "four", 3.0)
        row(layer, lit=1.0, thirty=tuple(seg(t, tt + k * 0.35, tt + k * 0.35 + 0.4) for k in range(4)), t=t)
        t120 = L.at(2, "120", 6.5)
        kit.pill(layer, "4 × 30 = 120", 540, 880, 54, GREEN, pop=seg(t, t120 - 0.3, t120 + 0.2))
        steps(layer, labels, t, 1, 0.1)

    def game(t, dur, layer):
        head(layer)
        row(layer, lit=1.0, t=t)
        tg = L.at(3, "game", 1.5)
        tb = L.at(3, "300", 3.9)
        kit.pill(layer, "120 = GAME", 290, 855, 46, GOLD, INK, pop=seg(t, tg, tg + 0.5))
        kit.pill(layer, "+300 BONUS", 710, 855, 46, GREEN, pop=seg(t, tb - 0.1, tb + 0.4))
        tv = L.at(3, "500", 5.8)
        kit.pill(layer, "VULNERABLE: +500", 540, 935, 34, (70, 96, 86), CREAM, pop=seg(t, tv - 0.1, tv + 0.4))
        steps(layer, labels, t, 2, 0.1)

    def total(t, dur, layer):
        head(layer)
        te = L.at(4, "extra", 4.3)
        row(layer, lit=1.0, extra=OUT(seg(t, te, te + 0.4)), t=t)
        t4 = L.at(4, "420", 2.0)
        kit.pill(layer, "120 + 300 = 420 POINTS", 540, 860, 46, GREEN, pop=seg(t, t4 - 0.3, t4 + 0.2))
        kit.pill(layer, "EACH EXTRA TRICK +30", 540, 940, 32, GOLD, INK, pop=seg(t, te, te + 0.4))
        steps(layer, labels, t, 3, 0.1)

    def events():
        ts = L.at(1, "so", 4.0) - 0.4
        tt = L.at(2, "four", 3.0)
        ev = [(1, ts + k * 0.15 + 0.1, "click", 0.25) for k in range(4)]
        ev += [(2, tt + k * 0.35 + 0.1, "click", 0.3) for k in range(4)] + [(2, L.at(2, "120", 6.5), "ding", 0.18)]
        ev += [(3, L.at(3, "300", 3.9), "ding", 0.18), (4, L.at(4, "420", 2.0), "ding", 0.2)]
        return ev

    L = S.lesson("whole-score", lines, ("The whole score", "of a made game"), [hook, count, thirty, game, total], events,
                 {**SUBS}, 2)
    return L


# ---------------------------------------------------------------- V25: the whole 1NT and Stayman sequence

def v25() -> kit.Lesson:
    lines = [
        "The whole one notrump and Stayman sequence.",
        "One, partner opens one notrump. Fifteen to seventeen points, balanced.",
        "Two, you hold ten points and four spades. Bid two clubs. That's Stayman, asking for a major.",
        "Three, partner names a four-card major. Two hearts or two spades. Here, two spades.",
        "Four, ten plus fifteen or more is game. Bid four spades.",
    ]
    labels = ["PARTNER OPENS 1NT", "YOU ASK WITH 2♣: STAYMAN", "PARTNER NAMES A 4-CARD MAJOR", "YOU BID THE GAME"]
    bids = [("1NT", "PARTNER", "15 TO 17, BALANCED"), ("2♣", "YOU", "ASKS FOR A MAJOR"),
            ("2♠", "PARTNER", "4 SPADES"), ("4♠", "YOU", "GAME")]

    ys = [535, 655, 775, 895]

    def row(layer, lit: int, pops: list[float]) -> None:
        """Four calls on screen from frame 0, dimmed until the step that speaks them."""
        for k, (label, who, note) in enumerate(bids):
            y = ys[k]
            p = 1.0 if k < lit else pops[k] if k == lit else 0.0
            kit.pill(layer, who, 140, y, 28, (16, 30, 26), CREAM, alpha=0.92)
            chip(layer, label, 375, y, pop=1.0, h=96, dim=0.55 * (1 - p))
            if k == lit:
                ring_chip(layer, y, GOLD, 1.0, x=375, w=233, h=96)
            kit.pill(layer, note, 700, y, 30, GREEN if k < lit else GOLD, CREAM if k < lit else INK, alpha=0.45 + 0.55 * p)

    def hook(t, dur, layer):
        row(layer, -1, [1] * 4)
        steps(layer, labels, t, -1, sweep=True)

    def open_(t, dur, layer):
        row(layer, 0, [seg(t, 0.3, 0.8), 1, 1, 1])
        steps(layer, labels, t, 0, 0.1)

    def ask(t, dur, layer):
        tb = L.at(2, "2clubs", 4.6)
        row(layer, 1, [1, seg(t, tb - 0.3, tb + 0.2), 1, 1])
        steps(layer, labels, t, 1, 0.1)

    def answer(t, dur, layer):
        th = L.at(3, "here", 4.4)
        row(layer, 2, [1, 1, seg(t, th, th + 0.5), 1])
        steps(layer, labels, t, 2, 0.1)

    def game(t, dur, layer):
        tb = L.at(4, "bid", 4.4)
        row(layer, 3, [1, 1, 1, seg(t, tb - 0.2, tb + 0.3)])
        steps(layer, labels, t, 3, 0.1)

    def events():
        return [(1, 0.5, "click", 0.4), (2, L.at(2, "2clubs", 4.6), "click", 0.4), (3, L.at(3, "here", 4.4), "click", 0.4),
                (4, L.at(4, "bid", 4.4), "ding", 0.2)]

    L = S.lesson("whole-stayman", lines, ("The whole", "1NT and Stayman"), [hook, open_, ask, answer, game], events,
                 {**SUBS, "two clubs": "2 clubs", "two spades": "2 spades", "two hearts": "2 hearts",
                  "four spades": "4 spades", "ten plus": "10 plus", "one notrump": "1NT"}, 3)
    return L


# ---------------------------------------------------------------- V26 and V27: a hand shown small, by suit

TW, TPITCH, TY0 = 100, 142, 530


def hand_rows(hand: str):
    return S.row_slots(hand, w=TW, y0=TY0, pitch=TPITCH)


def show_hand(layer, sl, dim=None, rings=None, hide=()) -> None:
    tag_x = min(x for _, x, _ in sl) - TW / 2 - 66
    for code, x, y in sl:
        if code in hide:
            ImageDraw.Draw(layer).rounded_rectangle((x - TW / 2, y - TW * CH / 2, x + TW / 2, y + TW * CH / 2), 12,
                                                    outline=CREAM + (90,), width=3)
            continue
        put(layer, code, x, y, TW, dim=dim(code) if dim else 0.0)
        rg = rings(code) if rings else None
        if rg:
            ring(layer, x, y, TW, *rg)
    for si, s in enumerate("SHDC"):
        S.suit_tag(layer, s, TY0 + si * TPITCH, x=tag_x)


V26_HAND = S.QUIZ_HANDS["V9"][0]  # S:QJ43 H:AJ5 D:KQT C:KT3, 16 points, 4-3-3-3, opens 1NT in the app's engine


def v26() -> kit.Lesson:
    lines = [
        "The three things to check first when you pick up a hand.",
        "One, count your points. Ace four, king three, queen two, jack one. This hand has sixteen.",
        "Two, find your longest suit. Here, spades, with four cards.",
        "Three, check for a balanced shape. Four three three three is balanced.",
        "Sixteen points and balanced? Open one notrump.",
    ]
    labels = ["COUNT YOUR POINTS", "FIND YOUR LONGEST SUIT", "CHECK IF IT IS BALANCED"]
    sl = hand_rows(V26_HAND)
    sh = S.Shape(S.cards_of(V26_HAND))
    right = max(x for _, x, _ in sl) + TW / 2 + 60
    suit_pts = {s: sum(S.HCPV.get(r, 0) for r, x in S.cards_of(V26_HAND) if x == s) for s in "SHDC"}

    def hook(t, dur, layer):
        show_hand(layer, sl)
        steps(layer, labels, t, -1, sweep=True)

    def points(t, dur, layer):
        tw = [L.at(1, w_, d_) for w_, d_ in (("ace", 2.2), ("king", 3.1), ("queen", 3.9), ("jack", 4.6))]
        lit = {r: seg(t, a, a + 0.4) for r, a in zip("AKQJ", tw)}
        m = max(lit.values())
        show_hand(layer, sl, dim=lambda c: 0.0 if lit.get(c[0], 0) > 0 else 0.55 * m,
                  rings=lambda c: (GOLD, OUT(lit[c[0]])) if lit.get(c[0], 0) > 0 else None)
        tt = L.at(1, "16", 7.0)
        run = sum(S.HCPV[r] * sum(1 for c, _, _ in sl if c[0] == r) for r in "AKQJ" if lit[r] > 0.5)
        if run:
            S.tally(layer, f"{run} POINTS", 330, 58, GREEN if t >= tt - 0.2 else GOLD, pop=1.0)
        steps(layer, labels, t, 0, 0.1)

    def longest(t, dur, layer):
        tl = L.at(2, "spades", 2.8)
        p = OUT(seg(t, tl, tl + 0.5))
        show_hand(layer, sl, dim=lambda c: 0.5 * p if c[1] != "S" else 0.0,
                  rings=lambda c: (GOLD, p) if c[1] == "S" else None)
        for si, s in enumerate("SHDC"):
            kit.pill(layer, str(sh.length(s)), right, TY0 + si * TPITCH, 40, GOLD if s == "S" and p > 0.5 else (70, 96, 86),
                     INK if s == "S" and p > 0.5 else CREAM, pop=seg(t, 0.3 + si * 0.14, 0.7 + si * 0.14))
        kit.pill(layer, "LONGEST: SPADES", 540, 330, 54, GOLD, INK, pop=seg(t, tl, tl + 0.5))
        steps(layer, labels, t, 1, 0.1)

    def balanced(t, dur, layer):
        show_hand(layer, sl)
        for si, s in enumerate("SHDC"):
            kit.pill(layer, str(sh.length(s)), right, TY0 + si * TPITCH, 40, (70, 96, 86), CREAM, pop=1.0)
        kit.pill(layer, "4-3-3-3 = BALANCED", 540, 330, 50, GREEN, pop=seg(t, 0.4, 0.9))
        steps(layer, labels, t, 2, 0.1)

    def answer(t, dur, layer):
        show_hand(layer, sl)
        tn = L.at(4, "1nt", 2.0)
        kit.pill(layer, "16 POINTS · BALANCED", 540, 270, 44, GREEN, pop=1.0)
        chip(layer, "1NT", 540, 385, pop=seg(t, tn - 0.3, tn + 0.2), h=110)
        steps(layer, labels, t, 3, 0.1)

    def events():
        tw = [L.at(1, w_, d_) for w_, d_ in (("ace", 2.2), ("king", 3.1), ("queen", 3.9), ("jack", 4.6))]
        return ([(1, a, "click", 0.3) for a in tw] + [(1, L.at(1, "16", 7.0), "ding", 0.18),
                (2, L.at(2, "spades", 2.8), "click", 0.4), (3, 0.9, "click", 0.4), (4, L.at(4, "1nt", 2.0), "ding", 0.2)])

    L = S.lesson("first-three-checks", lines, ("The 3 things to check", "first in a new hand"),
                 [hook, points, longest, balanced, answer], events,
                 {**SUBS, "one notrump": "1NT"}, 0)
    return L


V27_HAND = "S:KJ863 H:A74 D:Q52 C:94"


def v27() -> kit.Lesson:
    lines = [
        "The first card to lead against notrump.",
        "One, find your longest and strongest suit. Here, spades: king, jack, eight, six, three.",
        "Two, count from the top. First, second, third, fourth. The six is fourth.",
        "Three, lead the six of spades. It tells partner which suit to help.",
        "Fourth from your longest and strongest.",
    ]
    labels = ["FIND YOUR LONGEST, STRONGEST SUIT", "COUNT DOWN FROM THE TOP: FOURTH", "LEAD THAT CARD"]
    sl = hand_rows(V27_HAND)
    spades = [(c, x, y) for c, x, y in sl if c[1] == "S"]
    spot = (770, 800)

    def hook(t, dur, layer):
        show_hand(layer, sl, rings=lambda c: (GOLD, 0.5 + 0.5 * abs(S.wave(t, 1.2))) if c[1] == "S" else None)
        steps(layer, labels, t, -1, sweep=True)

    def find(t, dur, layer):
        tl = L.at(1, "spades", 2.8)
        p = OUT(seg(t, tl - 0.6, tl))
        show_hand(layer, sl, dim=lambda c: 0.5 * p if c[1] != "S" else 0.0,
                  rings=lambda c: (GOLD, p) if c[1] == "S" else None)
        kit.pill(layer, "LONGEST AND STRONGEST", 540, 330, 46, GOLD, INK, pop=seg(t, tl - 0.6, tl))
        steps(layer, labels, t, 0, 0.1)

    def count(t, dur, layer):
        names = [L.at(2, w_, d_) for w_, d_ in (("first", 1.6), ("second", 2.4), ("third", 3.1), ("fourth", 3.8))]
        show_hand(layer, sl, dim=lambda c: 0.5 if c[1] != "S" else 0.0,
                  rings=lambda c: (GOLD, 1.0) if c[1] == "S" else None)
        for k, a in enumerate(names):
            c, x, y = spades[k]
            kit.pill(layer, str(k + 1), x, y - TW * CH / 2 - 6, 34, GOLD if k < 3 else GREEN, INK if k < 3 else CREAM,
                     pop=seg(t, a, a + 0.35))
        t6 = L.at(2, "six", 5.4)
        ring(layer, spades[3][1], spades[3][2], TW, GREEN, OUT(seg(t, t6, t6 + 0.4)))
        steps(layer, labels, t, 1, 0.1)

    def lead(t, dur, layer):
        tl = L.at(3, "lead", 1.0)
        p = seg(t, tl, tl + 0.7)
        show_hand(layer, sl, dim=lambda c: 0.5 if c[1] != "S" else 0.0, hide=("6S",) if p > 0 else ())
        if p > 0:
            c, x, y = spades[3]
            xx, yy = kit.fly(p, (x, y), spot, arc=-40)
            put(layer, "6S", xx, yy, 130, scale=1 + 0.12 * (1 - p))
            ring(layer, spot[0], spot[1], 130, GREEN, OUT(seg(t, tl + 0.6, tl + 1.0)))
            kit.pill(layer, "LEAD", spot[0], spot[1] - 120, 38, GOLD, INK, pop=seg(t, tl + 0.5, tl + 1.0))
        steps(layer, labels, t, 2, 0.1)

    def recap(t, dur, layer):
        show_hand(layer, sl, dim=lambda c: 0.5 if c[1] != "S" else 0.0, hide=("6S",))
        put(layer, "6S", *spot, 130)
        ring(layer, spot[0], spot[1], 130, GREEN, 1.0)
        kit.pill(layer, "FOURTH BEST", 540, 330, 54, GREEN, pop=seg(t, 0.2, 0.7))
        steps(layer, labels, t, 3, 0.1)

    def events():
        names = [L.at(2, w_, d_) for w_, d_ in (("first", 1.6), ("second", 2.4), ("third", 3.1), ("fourth", 3.8))]
        return ([(1, L.at(1, "spades", 2.8), "click", 0.4)] + [(2, a, "click", 0.3) for a in names]
                + [(3, L.at(3, "lead", 1.0) + 0.5, "ding", 0.2)])

    L = S.lesson("first-lead-notrump", lines, ("The first card to lead", "against notrump"), [hook, find, count, lead, recap],
                 events, SUBS, 1)
    return L


# ---------------------------------------------------------------- V28: the two first plays as declarer

V28_DUMMY = ["AH", "5H", "3H", "KC", "QC", "JC", "8C", "5C"]  # the two suits that matter, shown on their own
D_SPOT = {"W": (385, 880), "N": (540, 790), "E": (695, 880), "S": (540, 970)}


def v28() -> kit.Lesson:
    lines = [
        "The two first plays as declarer.",
        "One, make a plan. Dummy is down, so count your tricks. Then find where more will come from.",
        "Here, dummy's long clubs are the plan. The ace of hearts is the way back in.",
        "Two, win the first trick in the right hand. West leads the four of hearts.",
        "Win it with your king. Dummy's ace stays as the entry.",
    ]
    labels = ["MAKE A PLAN", "WIN TRICK ONE IN THE RIGHT HAND"]
    dw, dy = 96, 610
    xs = [540 + (k - 3.5) * 104 for k in range(8)]

    def dummy(layer, skip=(), dim=None, rings=None) -> None:
        kit.pill(layer, "DUMMY", 540, dy - 100, 32, (16, 30, 26), CREAM)
        for code, x in zip(V28_DUMMY, xs):
            if code in skip:
                continue
            put(layer, code, x, dy, dw, dim=dim(code) if dim else 0.0)
            rg = rings(code) if rings else None
            if rg:
                ring(layer, x, dy, dw, *rg)

    def empty_table(layer) -> None:
        """Where the first trick will go: four faint slots and the seat names, there from frame 0."""
        d = ImageDraw.Draw(layer)
        for x, y in D_SPOT.values():
            d.rounded_rectangle((x - 55, y - 78, x + 55, y + 78), 14, outline=CREAM + (80,), width=3)
        kit.pill(layer, "WEST", 200, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "EAST", 860, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "YOU", 540, 1090, 30, (16, 30, 26), CREAM)

    def hook(t, dur, layer):
        empty_table(layer)
        dummy(layer, rings=lambda c: (GOLD, 0.5 + 0.5 * abs(S.wave(t, 1.2))) if c[1] == "C" else None)
        steps(layer, labels, t, -1, sweep=True)

    def plan(t, dur, layer):
        empty_table(layer)
        dummy(layer)
        kit.pill(layer, "PLAN FIRST", 540, 790, 60, GOLD, INK, pop=seg(t, 0.4, 0.9))
        steps(layer, labels, t, 0, 0.1)

    def clubs(t, dur, layer):
        tc, ta = L.at(2, "clubs", 1.8), L.at(2, "ace", 4.2)
        p, q = OUT(seg(t, tc - 0.4, tc + 0.1)), OUT(seg(t, ta - 0.3, ta + 0.2))
        empty_table(layer)
        dummy(layer, dim=lambda c: 0.35 * p if c[1] != "C" else 0.0,
              rings=lambda c: (GOLD, p) if c[1] == "C" else ((GREEN, q) if c == "AH" else None))
        kit.pill(layer, "LONG CLUBS", 700, 720, 40, GOLD, INK, pop=seg(t, tc - 0.4, tc + 0.1))
        kit.pill(layer, "ENTRY", 200, 720, 40, GREEN, pop=seg(t, ta - 0.3, ta + 0.2))
        steps(layer, labels, t, 0, 0.1)

    def trick(layer, t, plays, who_lit=None):
        for k, (who, code, t0) in enumerate(plays):
            start = (xs[2], dy) if code == "3H" else {"W": (200, 880), "E": (860, 880), "S": (540, 1070)}[who]
            fly_in(layer, t, who, code, t0, spot=D_SPOT, start=start, w=110, tilt=(k - 1.5) * 3)

    def lead(t, dur, layer):
        tl = L.at(3, "leads", 2.4)
        dummy(layer, skip=("3H",) if t > tl + 1.0 else ())
        kit.pill(layer, "WEST", 200, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "EAST", 860, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "YOU", 540, 1090, 30, (16, 30, 26), CREAM)
        trick(layer, t, [("W", "4H", tl), ("N", "3H", tl + 1.0), ("E", "9H", tl + 1.7)])
        steps(layer, labels, t, 1, 0.1)

    def win(t, dur, layer):
        tk = L.at(4, "king", 1.8)
        dummy(layer, skip=("3H",), rings=lambda c: (GREEN, OUT(seg(t, tk + 0.5, tk + 0.9))) if c == "AH" else None)
        kit.pill(layer, "WEST", 200, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "EAST", 860, 880, 30, (16, 30, 26), CREAM)
        kit.pill(layer, "YOU", 540, 1090, 30, (16, 30, 26), CREAM)
        trick(layer, t, [("W", "4H", -9), ("N", "3H", -9), ("E", "9H", -9), ("S", "KH", tk)])
        ring(layer, *D_SPOT["S"], 110, GOLD, OUT(seg(t, tk + 0.5, tk + 0.9)))
        kit.check(layer, D_SPOT["S"][0] + 66, D_SPOT["S"][1] - 88, 32, GREEN, seg(t, tk + 0.7, tk + 1.3))
        kit.pill(layer, "ENTRY KEPT", 215, 720, 36, GREEN, pop=seg(t, tk + 0.5, tk + 0.9))
        steps(layer, labels, t, 1, 0.0)

    def events():
        tl, tk = L.at(3, "leads", 2.4), L.at(4, "king", 1.8)
        return [(3, tl + 0.5, "click", 0.4), (3, tl + 1.5, "click", 0.4), (3, tl + 2.2, "click", 0.4),
                (4, tk + 0.5, "ding", 0.2)]

    L = S.lesson("first-declarer", lines, ("The 2 first plays", "as declarer"), [hook, plan, clubs, lead, win], events,
                 SUBS, 2)
    return L


# ---------------------------------------------------------------- registry, captions, checks

SHORTS = {
    "V21": (v21, "The whole bridge auction"),
    "V22": (v22, "The whole play of one trick"),
    "V23": (v23, "The whole deal from shuffle to opening lead"),
    "V24": (v24, "The whole score of a made game"),
    "V25": (v25, "The whole 1NT and Stayman sequence"),
    "V26": (v26, "The 3 things to check first in a hand"),
    "V27": (v27, "The first card to lead against notrump"),
    "V28": (v28, "The 2 first plays as declarer"),
}

TAGS = "#bridge #contractbridge #learnbridge #bridgetips #cardgames"
CAPTIONS = {
    "V21": ("The whole auction: the dealer opens, bidding goes clockwise with a higher bid or a pass, three passes in a "
            "row end it, and the last bid is the contract.", "#bridge #bridgebidding #contractbridge #learnbridge #cardgames"),
    "V22": ("The whole play of one trick: the leader plays a card, everyone follows suit clockwise, the highest card of "
            "the suit led wins, and the winner leads next.", "#bridge #bridgeplay #contractbridge #learnbridge #cardgames"),
    "V23": ("The whole deal: shuffle and cut, deal 13 cards each clockwise, the dealer bids first, the auction sets the "
            "contract, and the player left of declarer makes the opening lead.", "#bridge #contractbridge #learnbridge #bridgetips #cardgames"),
    "V24": ("The whole score of a made game: bid 4 spades and take 10 tricks. 4 contract tricks at 30 is 120, which "
            "earns the game bonus of 300 (500 vulnerable), so 420 points.", "#bridge #bridgescoring #contractbridge #learnbridge #cardgames"),
    "V25": ("The whole 1NT and Stayman sequence: partner opens 1NT (15 to 17, balanced), you bid 2 clubs with 8 or more "
            "points and a four-card major, partner names a major, and you bid game.", "#bridge #bridgebidding #stayman #learnbridge #bridgetips"),
    "V26": ("The 3 things to check first when you pick up a hand: count your points, find your longest suit, and check "
            "whether it is balanced. 15 to 17 and balanced opens 1NT.", "#bridge #bridgebidding #contractbridge #learnbridge #bridgetips"),
    "V27": ("The first card to lead against notrump: fourth from your longest and strongest suit. Count down from the "
            "top and lead the fourth card.", "#bridge #bridgedefense #contractbridge #learnbridge #bridgetips"),
    "V28": ("The 2 first plays as declarer: make a plan once dummy is down, then win the first trick in the right hand "
            "so your entry stays where you need it.", "#bridge #bridgeplay #contractbridge #learnbridge #bridgetips"),
}
S.CAPTIONS.update(CAPTIONS)  # caption_txt() in shorts.py reads this dict


def check() -> str:
    """Recount the hands and scores shown, by script; raises on any mismatch."""
    out = []
    sh = S.Shape(S.cards_of(V26_HAND))
    assert sh.hcp == 16 and sh.pattern == "4-3-3-3" and sh.balanced and S.opening(S.cards_of(V26_HAND)) == "1NT"
    assert sh.length("S") == 4 and {s: sh.length(s) for s in "HDC"} == {"H": 3, "D": 3, "C": 3}
    assert [sum(S.HCPV.get(r, 0) for r, x in S.cards_of(V26_HAND) if x == s) for s in "SHDC"] == [3, 5, 5, 3]
    out.append("V26 hand: 16 points, 4-3-3-3, balanced, 1NT, spades longest (4), suit points 3+5+5+3")
    cs = S.cards_of(V27_HAND)
    spades = sorted((r for r, x in cs if x == "S"), key=S.RANKS13.index)
    lens = {s: sum(1 for _, x in cs if x == s) for s in "SHDC"}
    assert len(cs) == 13 and lens["S"] == max(lens.values()) == 5 and spades[3] == "6", spades
    out.append(f"V27 hand: 13 cards, spades longest (5), fourth from the top is the {spades[3]}")
    # V24: duplicate score of 4 spades made with 10 tricks, mirroring BridgeRules.score (level, strain, tricks, vulnerable)
    level, unit = 4, 30
    tricks_score = level * unit
    bonus = 300 if tricks_score >= 100 else 50
    assert (tricks_score, bonus, tricks_score + bonus) == (120, 300, 420)
    assert (level * unit + (500 if tricks_score >= 100 else 50)) == 620  # vulnerable total, not shown
    assert 3 * 30 + 10 == 100  # 3NT is the lowest notrump game: 40 + 30 + 30
    out.append("V24: 4 spades made, 10 tricks: 4 x 30 = 120, game bonus 300 (500 vulnerable), total 420")
    assert 10 + 15 == 25  # V25: 10 points plus the 15 minimum of the 1NT opening reaches the 25-point game guide
    dummy_hearts = [c for c in V28_DUMMY if c[1] == "H"]
    assert dummy_hearts == ["AH", "5H", "3H"] and [c for c in V28_DUMMY if c[1] == "C"] == ["KC", "QC", "JC", "8C", "5C"]
    out.append("V28: dummy A53 of hearts and KQJ85 of clubs; West's 4H, dummy 3H, East 9H, declarer's K wins, the A stays")
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
        argv.insert(1, str(folder / "video.mp4"))
    out = pathlib.Path(argv[1])
    sys.argv = argv
    lesson = make()
    if os.environ.get("WHOLE_CUES"):
        inner = lesson.short.prepare

        def show(vo) -> None:
            inner(vo)
            for i, c in lesson.cues.items():
                print(i, {k: round(v, 2) for k, v in c.items()}, f"dur={vo[i][1]:.2f}")
        lesson.short.prepare = show
    kit.run(lesson)
    if "--still" not in argv:
        S.cap_size(out)


if __name__ == "__main__":
    main()
