#!/usr/bin/env python3
"""The kit's extra sets, ported from the Mahj kit's extras.

    python3 extras.py [carousels|more|instagram|all] [--out <dir>]

carousels  Five 7-slide carousels in the Mahj "Oct 29" mold: a headline over big cards, one idea
           per numbered slide, the app on the last slide. Into "Bridge carousels".
more       Five more listicles in A1's mold, into "More like A1".
instagram  3:4 (1080x1440) cuts of three kit posts with Instagram captions, into
           "Instagram carousels". Kit slides keep their content inside SAFE, which fits a
           1440-tall window, so a fixed crop holds everything.
"""
from __future__ import annotations

import argparse
import pathlib

from PIL import Image, ImageDraw

import build_kit as B
import posts as P

AMBER = (255, 204, 112)
GOLD, GREEN, RED = (232, 170, 60), (70, 150, 96), (204, 74, 62)
CH = 1.42
TAGS = "#bridge #contractbridge #bridgegame #learnbridge #cardgames"


# ---------------------------------------------------------------- pieces

def put(im: Image.Image, code: str, x: float, y: float, w: int, angle: float = 0.0) -> None:
    c = B.card(code[0], code[1], w)
    if angle:
        c = c.rotate(angle, Image.BICUBIC, expand=True)
    B.shadow(im, c, (int(x - c.width / 2), int(y - c.height / 2)), blur=10, alpha=110, drop=10)


def back(im: Image.Image, x: float, y: float, w: int) -> None:
    h = int(w * CH)
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(c)
    d.rounded_rectangle((0, 0, w - 1, h - 1), int(w * 0.12), fill=(255, 253, 248))
    m = max(6, w // 12)
    d.rounded_rectangle((m, m, w - 1 - m, h - 1 - m), int(w * 0.08), fill=(26, 104, 88))
    B.shadow(im, c, (int(x - w / 2), int(y - h / 2)), blur=10, alpha=110, drop=10)


def row(im: Image.Image, cards: list[str | None], cy: float, w: int, gap: int = 14) -> list[float]:
    n = len(cards)
    xs = [B.CX + (k - (n - 1) / 2) * (w + gap) for k in range(n)]
    for c, x in zip(cards, xs):
        if c == "BACK":
            back(im, x, cy, w)
        elif c:
            put(im, c, x, cy, w)
    return xs


def ring(im: Image.Image, x: float, y: float, w: int, color) -> None:
    bw, bh = w + 24, int(w * CH) + 24
    ImageDraw.Draw(im).rounded_rectangle((x - bw / 2, y - bh / 2, x + bw / 2, y + bh / 2), int(w * 0.16),
                                         outline=color + (255,), width=9)


def pill(im: Image.Image, s: str, x: float, y: float, size: int, bg, fg=(255, 255, 255)) -> None:
    f = B.font(size, "Heavy")
    d = ImageDraw.Draw(im)
    w = d.textlength(s, font=f)
    h = size * 1.5
    d.rounded_rectangle((x - w / 2 - h * 0.45, y - h / 2, x + w / 2 + h * 0.45, y + h / 2), int(h / 2), fill=bg + (255,))
    d.text((x, y + size * 0.04), s, font=f, fill=fg + (255,), anchor="mm")


def headline(im: Image.Image, lines: list[str], top: int, size: int = 104) -> int:
    """The shorts' headline look: serif Black, cream with an ink stroke, last line amber."""
    d = ImageDraw.Draw(im)
    f = B.font(size, "Black", serif=True)
    while max(d.textlength(ln, font=f) for ln in lines) > 880:
        size -= 4
        f = B.font(size, "Black", serif=True)
    y = top
    for k, ln in enumerate(lines):
        fill = AMBER if k == len(lines) - 1 and len(lines) > 1 else B.CREAM
        d.text((B.CX, y), ln, font=f, fill=fill + (255,), anchor="mt", stroke_width=9, stroke_fill=B.INK + (255,))
        y += int(size * 1.12)
    return y


def body(im: Image.Image, text: str, center_y: int, size: int = 56) -> int:
    d = ImageDraw.Draw(im)
    f = B.font(size, "Semibold")
    return B.text_boxes(im, B.wrap(d, text, f, 820), f, center_y)


def numbered(seed: int, n: int, title: str) -> Image.Image:
    im = B.felt(seed).copy()
    d = ImageDraw.Draw(im)
    r, cx, cy = 54, B.SAFE[0] + 70, 250
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=B.INK + (255,))
    d.text((cx, cy + 2), str(n), font=B.font(62, "Heavy"), fill=AMBER + (255,), anchor="mm")
    size = 96
    f = B.font(size, "Black", serif=True)
    while d.textlength(title, font=f) > 740:
        size -= 4
        f = B.font(size, "Black", serif=True)
    d.text((cx + 90, cy), title, font=f, fill=B.CREAM + (255,), anchor="lm", stroke_width=8, stroke_fill=B.INK + (255,))
    return im


def hook(seed: int, lines: list[str], cards: list[str]) -> Image.Image:
    im = B.felt(seed).copy()
    headline(im, lines, 230)
    for k, c in enumerate(cards[:5]):
        x = 230 + (k % 3) * 310 + (155 if k >= 3 else 0)
        put(im, c, x, 900 + (k // 3) * 340, 200, (-8, 6, -4, 8, -6)[k])
    pill(im, "swipe →", B.CX, 1440, 40, (22, 22, 22))
    return im


def save(slides: list[Image.Image], folder: pathlib.Path, caption: str) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.jpg"):
        old.unlink()
    for n, s in enumerate(slides, 1):
        s.convert("RGB").save(folder / f"{n}.jpg", quality=93)
    (folder / "caption.txt").write_text(caption)


def caption_txt(title: str, text: str, question: str, where: str = "the last slide") -> str:
    return (
        f"TITLE (photo mode title field):\n{title}\n\n"
        f"CAPTION (paste as is):\n{text} {question}\n\n"
        f'The app on {where} is {P.NAME}. I built it. Search "Bridge Trainer Learn and Bid" on the App Store, '
        "it's free to start.\n\n"
        f"{TAGS}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{P.PINNED.replace('slide 4', where)}\n\n"
        f"REPLY to every \"app\" or \"name?\" comment:\n{P.REPLY}\n\n"
        "BEFORE POSTING: More options > Disclose post content > Your brand.\n"
        "SOUND (Commercial Music Library): Soft acoustic or lo-fi. Pick one showing a trending arrow.\n"
    )


# ---------------------------------------------------------------- carousels

def x1(out: pathlib.Path) -> None:
    seed = 0
    s1 = hook(seed, ["5 bridge words that", "confuse beginners"], ["AS", "KH", "QD", "JC", "TS"])
    s2 = numbered(seed, 1, "Trick")
    row(s2, ["7H", "3H", "QH", "AH"], 760, 190)
    body(s2, "One card from each player, 4 in all. The highest card of the suit led wins it.", 1200)
    s3 = numbered(seed, 2, "Trump")
    xs = row(s3, ["AD", "2S"], 760, 230, 60)
    ring(s3, xs[1], 760, 230, GOLD)
    body(s3, "The suit named in the contract. With spades trump, the 2 of spades beats the ace of diamonds.", 1200)
    s4 = numbered(seed, 3, "Dummy")
    for k, c in enumerate(["AS", "KS", "7S"]):
        put(s4, c, 300, 560 + k * 90, 150)
    for k, c in enumerate(["QH", "9H"]):
        put(s4, c, 470, 560 + k * 90, 150)
    for k, c in enumerate(["KD", "8D", "6D", "2D"]):
        put(s4, c, 640, 560 + k * 90, 150)
    for k, c in enumerate(["JC", "5C", "4C", "3C"]):
        put(s4, c, 810, 560 + k * 90, 150)
    body(s4, "Declarer's partner. After the opening lead, dummy's cards go face up and declarer plays them.", 1240)
    s5 = numbered(seed, 4, "Book")
    row(s5, ["BACK"] * 6, 760, 120, 16)
    body(s5, "The first 6 tricks. A 1-level bid means book plus 1, so 7 tricks.", 1200)
    s6 = numbered(seed, 5, "Void")
    row(s6, ["AS", "QS", "9S", "8S", "4S", None, "KD", "JD", "7D", "3D"], 760, 84, 6)
    pill(s6, "NO HEARTS", B.CX, 560, 44, RED)
    body(s6, "No cards at all in a suit. A void lets you trump that suit right away.", 1200)
    s7 = B.app_slide("Every word here gets drilled in the app I built, a few minutes a day.", ("card_room", "quick_answered"))
    save([s1, s2, s3, s4, s5, s6, s7], out / "X1 5 bridge words that confuse beginners",
         caption_txt("5 bridge words that confuse beginners",
                     "The contract bridge words every beginner asks about: trick, trump, dummy, book and void.",
                     "Which one confused you most?"))


def x2(out: pathlib.Path) -> None:
    seed = 1
    s1 = hook(seed, ["Bridge point count,", "made simple"], ["AH", "KS", "QC", "JD", "AC"])
    slides = [s1]
    for n, (rank, pts, suits) in enumerate((("A", 4, "SHDC"), ("K", 3, "SHDC"), ("Q", 2, "SHDC"), ("J", 1, "SHDC")), 1):
        name = {"A": "Ace", "K": "King", "Q": "Queen", "J": "Jack"}[rank]
        s = numbered(seed, n, f"{name}: {pts}")
        row(s, [rank + x for x in suits], 760, 180, 24)
        body(s, {"A": "Each ace is worth 4 points. All 4 aces make 16 of the deck's 40.",
                 "K": "Each king is worth 3.",
                 "Q": "Each queen is worth 2.",
                 "J": "Each jack is worth 1. Every other card counts zero."}[rank], 1200)
        slides.append(s)
    s6 = numbered(seed, 5, "Add them up")
    hi = B.hand_image("S:AQ74 H:K93 D:J82 C:Q65", 860)
    s6.alpha_composite(hi, ((B.W - hi.width) // 2, 560))
    body(s6, "4 + 2 + 3 + 1 + 2 = 12. With 12 or more, you can usually open the bidding.", 1200)
    slides.append(s6)
    slides.append(B.app_slide("I built an app that drills point counting until it's automatic.", ("opening", "opening_answered")))
    save(slides, out / "X2 Bridge point count made simple",
         caption_txt("Bridge point count, made simple",
                     "How to count high-card points in contract bridge: ace 4, king 3, queen 2, jack 1.",
                     "How fast can you count a hand?"))


def x3(out: pathlib.Path) -> None:
    seed = 2
    messy = ["7D", "QS", "3C", "KH", "9S", "JD", "6C", "AS", "2D", "9H", "4S", "QC", "5C"]
    s1 = hook(seed, ["Sort your bridge hand,", "read it faster"], ["QS", "KH", "JD", "AS", "QC"])
    s2 = numbered(seed, 1, "Group the suits")
    hi = B.hand_image(" ".join(f"{s}:{''.join(c[0] for c in messy if c[1] == s)}" for s in "SHDC"), 860)
    row(s2, messy[:7], 640, 110, 10)
    row(s2, messy[7:], 820, 110, 10)
    body(s2, "Deal yourself in, then pull each suit together before anything else.", 1200)
    s3 = numbered(seed, 2, "Spades first")
    s3.alpha_composite(hi, ((B.W - hi.width) // 2, 560))
    body(s3, "Spades, hearts, diamonds, clubs: the same order the auction ranks them, top down.", 1200)
    s4 = numbered(seed, 3, "High to low")
    s4.alpha_composite(hi, ((B.W - hi.width) // 2, 560))
    body(s4, "Honors on the left of each suit. Your points jump out at a glance.", 1200)
    s5 = numbered(seed, 4, "Count the lengths")
    s5.alpha_composite(hi, ((B.W - hi.width) // 2, 560))
    pill(s5, "4  ·  2  ·  3  ·  4", B.CX, 980, 52, (22, 22, 22))
    body(s5, "4 spades, 2 hearts, 3 diamonds, 4 clubs. Shape tells you what to bid.", 1220)
    s6 = numbered(seed, 5, "Count the points")
    s6.alpha_composite(hi, ((B.W - hi.width) // 2, 560))
    pill(s6, "12 POINTS", B.CX, 980, 52, GREEN)
    body(s6, "Ace 4, king 3, two queens 4, jack 1. That's 12, enough to open.", 1220)
    s7 = B.app_slide("Practice reading hands like this in the app I built.", ("opening", "home"))
    save([s1, s2, s3, s4, s5, s6, s7], out / "X3 Sort your bridge hand read it faster",
         caption_txt("Sort your bridge hand, read it faster",
                     "A 5-step routine for sorting your contract bridge hand: suits, colors, high to low, lengths and points.",
                     "How do you sort yours?"))


def x4(out: pathlib.Path) -> None:
    seed = 3
    s1 = hook(seed, ["How bridge scoring", "works, in 5 slides"], ["AC", "KD", "QH", "JS", "AH"])
    s2 = numbered(seed, 1, "Minors: 20")
    row(s2, ["AC", "AD"], 760, 220, 60)
    body(s2, "Each trick you bid in clubs or diamonds scores 20.", 1200)
    s3 = numbered(seed, 2, "Majors: 30")
    row(s3, ["AH", "AS"], 760, 220, 60)
    body(s3, "Each trick you bid in hearts or spades scores 30.", 1200)
    s4 = numbered(seed, 3, "Notrump: 40, 30")
    pill(s4, "1NT", B.CX, 760, 90, (255, 253, 248), B.INK)
    body(s4, "The first notrump trick scores 40, and each one after that scores 30.", 1200)
    s5 = numbered(seed, 4, "Game: 100")
    for k, (bid, sums) in enumerate((("3NT", "40 + 30 + 30"), ("4♥", "4 × 30 = 120"), ("5♣", "5 × 20"))):
        pill(s5, bid, 300, 560 + k * 170, 64, (255, 253, 248), B.suit_color(bid) if bid != "3NT" else B.INK)
        pill(s5, sums, 680, 560 + k * 170, 44, (22, 22, 22))
    body(s5, "Bid and make 100 trick points and you score game, plus a bonus.", 1200)
    s6 = numbered(seed, 5, "Slams")
    row(s6, ["BACK"] * 6, 680, 110, 14)
    row(s6, ["BACK"] * 6, 900, 110, 14)
    body(s6, "12 tricks is a small slam, all 13 a grand slam. Both earn big bonuses.", 1220)
    s7 = B.app_slide("The app I built walks you through contracts and scoring, hand by hand.", ("card_room", "card_room_answered"))
    save([s1, s2, s3, s4, s5, s6, s7], out / "X4 How bridge scoring works",
         caption_txt("How bridge scoring works, in 5 slides",
                     "Contract bridge trick scores for beginners: minors 20, majors 30, notrump 40 then 30, and why game is 100.",
                     "Did anyone ever explain this to you?"))


def x5(out: pathlib.Path) -> None:
    seed = 4
    s1 = hook(seed, ["Your 5-step plan", "as declarer"], ["AS", "KS", "QH", "JH", "AD"])
    s2 = numbered(seed, 1, "Stop")
    pill(s2, "BEFORE TRICK 1", B.CX, 760, 60, RED)
    body(s2, "When dummy goes down, don't play yet. Thank partner, then look.", 1200)
    s3 = numbered(seed, 2, "Count winners")
    xs = row(s3, ["AS", "KS", "AH", "AD", "KD"], 760, 150, 18)
    for x in xs:
        ring(s3, x, 760, 150, GREEN)
    body(s3, "Count the tricks you can take right now, without giving up the lead.", 1200)
    s4 = numbered(seed, 3, "Find the gap")
    pill(s4, "5 SURE  ·  NEED 9", B.CX, 760, 56, (22, 22, 22))
    body(s4, "The gap is your job for this hand. In 3NT with 5 winners, you need 4 more.", 1200)
    s5 = numbered(seed, 4, "Find the extras")
    row(s5, ["AH", "QH"], 760, 190, 40)
    body(s5, "A long suit to set up, a finesse, or ruffs in dummy. Pick the plan that covers the gap.", 1200)
    s6 = numbered(seed, 5, "Then play")
    put(s6, "4S", B.CX, 760, 220)
    body(s6, "Now play to trick one, with the whole hand already planned. Save this.", 1200)
    s7 = B.app_slide("I built a declarer room in the app for exactly this.", ("declarer", "declarer_answered"))
    save([s1, s2, s3, s4, s5, s6, s7], out / "X5 Your 5-step plan as declarer",
         caption_txt("Your 5-step plan as declarer",
                     "A simple contract bridge declarer plan: stop, count winners, compare to the contract, find extra tricks, then play.",
                     "Which step do you skip?"))


# ---------------------------------------------------------------- more like A1

MORE = [
    dict(id="A7", seed=7, hook="5 things I wish I knew about bridge bidding",
         s2="1. Every bid describes your hand to partner. Think of it as a conversation.",
         s3="2. An opening of 1♥ or 1♠ promises 5 cards in most beginner systems.",
         s4="3. Add your points to partner's. About 25 together usually means game.",
         s5="4. With 6 or more points, answer partner's opening.\n5. Agree on your system before you play. Save this.",
         shots=("auction_room", "opening_answered"), hand="S:KQT83 H:A5 D:K74 C:962",
         caption="Everything I'd tell a friend about contract bridge bidding: describing your hand, 5-card majors, 25 points and responding."),
    dict(id="A8", seed=8, hook="5 things I wish I knew about playing declarer",
         s2="1. Make a plan before you play from dummy. The first trick is often the most important.",
         s3="2. Count your sure winners. The gap to your contract is the job.",
         s4="3. Draw trumps early, unless you need them for ruffs in dummy.",
         s5="4. Play the high cards from the short side first.\n5. Keep a way back to your winners. Save this.",
         shots=("declarer", "declarer_answered"), hand="S:AK74 H:KQ3 D:A82 C:J65",
         caption="Everything I'd tell a friend about playing a bridge hand as declarer: the plan, counting winners, trumps and entries."),
    dict(id="A9", seed=9, hook="5 things I wish I knew about bridge defense",
         s2="1. Second hand low. When declarer leads, usually play low.",
         s3="2. Third hand high. When partner leads low, play your high card.",
         s4="3. Return partner's suit unless you have a clear reason not to.",
         s5="4. Count declarer's tricks along with your own.\n5. Hold on to the suit declarer is setting up. Save this.",
         shots=("lead", "lead_answered"), hand="S:Q97 H:KJ5 D:A863 C:T42",
         caption="Everything I'd tell a friend about bridge defense: second hand low, third hand high, returning partner's suit and counting."),
    dict(id="A10", seed=10, hook="5 things I wish I knew about the opening lead",
         s2="1. The player on declarer's left makes it, before dummy is seen.",
         s3="2. With touching honors like K-Q-J, lead the top one.",
         s4="3. If partner bid a suit, leading it is usually a good start.",
         s5="4. Against notrump, many players lead their longest suit.\n5. Against a suit contract, think twice before leading away from a king. Save this.",
         shots=("lead", "lead_answered"), hand="S:KQJ5 H:874 D:962 C:A73",
         caption="Everything I'd tell a friend about the opening lead in bridge: who leads, sequences, partner's suit and leads against notrump."),
    dict(id="A11", seed=11, hook="5 things I wish I knew about bridge partners",
         s2="1. You win and lose together, so you plan together.",
         s3="2. Agree on a few basics first: 5-card majors and your 1NT range.",
         s4="3. Trust partner's bids. They're telling you what they hold.",
         s5="4. Keep post-mortems short and kind.\n5. Thank partner after every session. Save this.",
         shots=("home", "auction_room"), hand="S:A86 H:KQ74 D:Q52 C:K93",
         caption="Everything I'd tell a friend about having a bridge partner: agreements, trust and keeping it friendly."),
]


def more(out: pathlib.Path) -> None:
    for p in MORE:
        post = dict(p, fmt="A", tags=P.TAGS[:4], sound="cozy")
        slides = [B.hook_slide(post, p["seed"]), B.card_slide(p["seed"], p["s2"], p["hand"]),
                  B.card_slide(p["seed"], p["s3"], None), B.app_slide(p["s4"], p["shots"]),
                  B.card_slide(p["seed"], p["s5"], None)]
        save(slides, out / f"{p['id']} {p['hook']}", B.caption_txt(post, "comment"))


# ---------------------------------------------------------------- instagram

IG = [("A1", "1 First bridge night"), ("D1", "2 Opening bids"), ("C1", "3 Point count quiz")]
CROP = (0, 110, 1080, 1550)  # SAFE (150 to 1500) plus margin, 1440 tall


def instagram(out: pathlib.Path) -> None:
    by_id = {p["id"]: p for p in P.POSTS}
    for pid, name in IG:
        post = by_id[pid]
        src = next(B.ICLOUD.glob(f"Day */* - {pid} *"))
        slides = [Image.open(src / f"{n}.jpg").crop(CROP) for n in range(1, 6)]
        caption = (f"{post['caption']} {post.get('question', P.QUESTIONS[post['fmt']])}\n\n"
                   f"The app on slide 4 is {P.NAME}. I made it for new players, link in bio, free to start.\n\n"
                   f"{' '.join(post['tags'])}")
        save(slides, out / name, caption)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("what", nargs="?", default="all", choices=["carousels", "more", "instagram", "all"])
    ap.add_argument("--out", default=str(B.ICLOUD))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    if args.what in ("carousels", "all"):
        for make in (x1, x2, x3, x4, x5):
            make(out / "Bridge carousels")
    if args.what in ("more", "all"):
        more(out / "More like A1")
    if args.what in ("instagram", "all"):
        instagram(out / "Instagram carousels")
    print(f"wrote {args.what} to {out}")


if __name__ == "__main__":
    main()
