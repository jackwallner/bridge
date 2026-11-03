#!/usr/bin/env python3
"""Render the Bridge TikTok slideshow kit into iCloud Drive.

    python3 build_kit.py [--out <dir>] [--only A1,C2]

Port of the Mahj kit (~/mahj/project-docs/marketing/tiktok-kit/build_kit.py).
Slides are 1080x1920 JPEGs. Backgrounds (card-table felt) and playing cards
are drawn here in the app's card style; every screen on slide 4 is a real
Bridge Trainer capture. All content stays inside the TikTok safe area (SAFE):
the top bar, the right icon rail and the bottom caption block cover the rest.
"""
from __future__ import annotations

import argparse
import csv
import functools
import pathlib
import random
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import posts as P

HERE = pathlib.Path(__file__).resolve().parent
CAPS = pathlib.Path.home() / "ios/appstore-screenshots/captures/bridge/refresh-20260916"
ICON = pathlib.Path.home() / "bridge/Bridge/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
ICLOUD = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/Bridge TikTok Kit"
W, H = 1080, 1920
SAFE = (60, 150, 950, 1500)  # left, top, right, bottom
CX = (SAFE[0] + SAFE[2]) // 2
FONT = "/System/Library/Fonts/SFNS.ttf"
SERIF = "/System/Library/Fonts/NewYork.ttf"
CREAM, INK, JADE, MUTED = (248, 243, 232), (34, 40, 36), (26, 104, 88), (96, 102, 92)
CARD_RED, CARD_BLACK = (196, 48, 40), (28, 28, 30)
# Card-table felts: jade, navy, burgundy, forest, slate.
FELTS = [(30, 98, 82), (34, 52, 92), (110, 34, 44), (38, 84, 52), (56, 66, 78)]
SUITS = {"S": "♠", "H": "♥", "D": "♦", "C": "♣"}
RANKS = "AKQJT98765432"
HCP = {"A": 4, "K": 3, "Q": 2, "J": 1}

SHOTS = {
    "quick": "01-quick-session.png", "quick_answered": "01-quick-session-answered.png",
    "card_room_answered": "01-card-room-answered.png",
    "opening": "02-opening.png", "opening_answered": "02-opening-answered.png",
    "lead": "03-lead-or-hold.png", "lead_answered": "03-lead-or-hold-answered.png",
    "declarer": "04-declarer.png", "declarer_answered": "04-declarer-answered.png",
    "card_room": "05-card-room.png", "home": "05-home.png", "auction_room": "06-auction-room.png",
    "declarer_room": "07-declarer-room.png", "defense_room": "08-defense-room.png",
    "session": "08-session.png",
}


def font(size: int, weight: str = "Bold", serif: bool = False) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(SERIF if serif else FONT, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:  # noqa: BLE001
        pass
    return f


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split():
            trial = f"{cur} {word}".strip()
            if draw.textlength(trial, font=f) <= width:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadow(base: Image.Image, img: Image.Image, xy: tuple[int, int], blur: int = 18,
           alpha: int = 80, drop: int = 10) -> None:
    """Paste img with a soft shadow shaped like its own alpha."""
    pad = blur * 3
    sh = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    a = img.getchannel("A").point(lambda v: v * alpha // 255)
    sh.paste((0, 0, 0, 255), (pad, pad), a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh, (xy[0] - pad, xy[1] - pad + drop))
    base.alpha_composite(img, xy)


def felt(seed: int) -> Image.Image:
    """A card-table felt with a fine nap and a soft vignette, seeded per post."""
    rng = np.random.default_rng(seed)
    color = np.array(FELTS[seed % len(FELTS)], dtype=float)
    nap = rng.normal(0, 4.5, (H // 2, W // 2))
    nap = np.kron(nap, np.ones((2, 2)))[:H, :W]
    img = np.broadcast_to(color, (H, W, 3)) + nap[..., None]
    yy, xx = np.mgrid[0:H, 0:W]
    vignette = 1 - 0.16 * (((xx - W / 2) / W) ** 2 + ((yy - H / 2) / H) ** 2) * 4
    img = img * vignette[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype("uint8")).convert("RGBA")


# ---------------------------------------------------------------- cards

def parse_hand(hand: str) -> list[tuple[str, str]]:
    """'S:AQ74 H:K93 ...' to [(rank, suit)], spades first, high to low, like the app."""
    cards = []
    for part in hand.split():
        suit, ranks = part.split(":")
        cards += [(r, suit) for r in sorted(ranks, key=RANKS.index)]
    return cards


def hcp(hand: str) -> int:
    return sum(HCP.get(r, 0) for r, _ in parse_hand(hand))


@functools.cache
def card(rank: str, suit: str, width: int) -> Image.Image:
    """A face-up card in the app's style: cream face, serif rank over the suit pip."""
    h = int(width * 1.42)
    im = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, width - 1, h - 1), int(width * 0.12), fill=(255, 253, 248),
                        outline=(214, 206, 190), width=max(2, width // 50))
    color = CARD_RED if suit in "HD" else CARD_BLACK
    label = "10" if rank == "T" else rank
    rf = font(int(width * (0.46 if label == "10" else 0.52)), "Bold", serif=True)
    d.text((width / 2, h * 0.34), label, font=rf, fill=color, anchor="mm")
    d.text((width / 2, h * 0.70), SUITS[suit], font=font(int(width * 0.46)), fill=color, anchor="mm")
    return im


def hand_image(hand: str, width: int) -> Image.Image:
    """13 cards in two rows (7 over 6), as the app deals a hand."""
    cards = parse_hand(hand)
    gap = 12
    cw = (width - 6 * gap) // 7
    ch = int(cw * 1.42)
    im = Image.new("RGBA", (width, ch * 2 + 22), (0, 0, 0, 0))
    for row, chunk in enumerate((cards[:7], cards[7:])):
        x0 = (width - (len(chunk) * cw + (len(chunk) - 1) * gap)) // 2
        for i, (r, s) in enumerate(chunk):
            shadow(im, card(r, s, cw), (x0 + i * (cw + gap), row * (ch + 22)), blur=5, alpha=50, drop=4)
    return im


def text_boxes(im: Image.Image, lines: list[str], f, center_y: int, pad: int = 24) -> int:
    """TikTok's native 'classic' caption look: dark text on white rounded boxes."""
    d = ImageDraw.Draw(im)
    lh = f.size + 2 * 12
    y = center_y - len(lines) * lh // 2
    for line in lines:
        w = d.textlength(line, font=f)
        x = CX - w / 2
        d.rounded_rectangle((x - pad, y, x + w + pad, y + lh + 2), 18, fill=(255, 255, 255))
        d.text((x, y + 6), line, font=f, fill=(22, 22, 22))
        y += lh
    return y


def pill(im: Image.Image, label: str, y: int, size: int = 38) -> None:
    d = ImageDraw.Draw(im)
    f = font(size, "Semibold")
    lw = d.textlength(label, font=f)
    d.rounded_rectangle((CX - lw / 2 - 30, y, CX + lw / 2 + 30, y + size + 34), (size + 34) // 2, fill=(22, 22, 22))
    d.text((CX, y + (size + 34) / 2), label, font=f, fill=(255, 255, 255), anchor="mm")


def deal(seed: int, n: int) -> list[tuple[str, str]]:
    deck = [(r, s) for s in "SHDC" for r in RANKS]
    rng = random.Random(seed)
    picks = rng.sample(deck, n)
    for honor in (("A", "S"), ("K", "H"), ("Q", "D")):  # a few faces so the fan reads as bridge
        if honor not in picks:
            picks[rng.randrange(n)] = honor
    return picks


def hook_slide(post: dict, seed: int) -> Image.Image:
    im = felt(seed)
    rng = random.Random(seed)
    cards = parse_hand(post["hand"]) if post.get("hand") else deal(seed, 13)
    cards = rng.sample(cards, 7)
    cw = 190
    for i, (r, s) in enumerate(cards):
        row, col = (0, i) if i < 4 else (1, i - 4)
        x = SAFE[0] + 30 + col * 215 + (107 if row else 0) + rng.randint(-12, 12)
        y = 920 + row * 270 + rng.randint(-16, 16)
        t = card(r, s, cw).rotate(rng.uniform(-9, 9), resample=Image.BICUBIC, expand=True)
        shadow(im, t, (x, y), blur=12, alpha=120, drop=10)
    f = font(76)
    lines = wrap(ImageDraw.Draw(im), post["hook"], f, 800)
    y = text_boxes(im, lines, f, 540)
    pill(im, "swipe →", y + 30)
    return im.convert("RGB")


def hand_card(im: Image.Image, hand: str, top: int) -> int:
    """The hand on a cream panel. Returns the panel's bottom edge."""
    inner = SAFE[2] - SAFE[0] - 60
    hi = hand_image(hand, inner)
    panel = Image.new("RGBA", (SAFE[2] - SAFE[0], hi.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle((0, 0, panel.width - 1, panel.height - 1), 40, fill=(*CREAM, 250))
    shadow(im, panel, (SAFE[0], top), blur=22, alpha=70, drop=12)
    im.alpha_composite(hi, (SAFE[0] + 30, top + 30))
    return top + panel.height


def quiz_slide(post: dict, seed: int) -> Image.Image:
    """Quiz hook: the hand and lettered options on slide 1, so answering takes one comment."""
    im = felt(seed)
    d = ImageDraw.Draw(im)
    f = font(72)
    y = text_boxes(im, wrap(d, post["quiz_q"], f, 820), f, SAFE[1] + 200)
    y = hand_card(im, post["hand"], y + 50) + 40
    lf, of = font(50), font(48, "Semibold")
    cw, ch, gap = (SAFE[2] - SAFE[0] - 30) // 2, 112, 30
    for i, opt in enumerate(post["options"]):
        x0 = SAFE[0] + (i % 2) * (cw + gap)
        y0 = y + (i // 2) * (ch + 24)
        chip = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        ImageDraw.Draw(chip).rounded_rectangle((0, 0, cw - 1, ch - 1), 30, fill=(255, 255, 255, 250))
        shadow(im, chip, (x0, y0), blur=12, alpha=60, drop=6)
        d.text((x0 + 30, y0 + ch / 2), "ABCD"[i], font=lf, fill=JADE, anchor="lm")
        d.text((x0 + 90, y0 + ch / 2), opt, font=of, fill=suit_color(opt), anchor="lm")
    y += 2 * ch + 24 + 44
    pill(im, "Comment A, B, C or D. Answer on slide 3 →", y, 40)
    return im.convert("RGB")


def suit_color(s: str) -> tuple[int, int, int]:
    return CARD_RED if ("♥" in s or "♦" in s) else INK


def card_slide(seed: int, text: str, hand: str | None) -> Image.Image:
    im = felt(seed)
    d = ImageDraw.Draw(im)
    f = font(62, "Semibold")
    inner = SAFE[2] - SAFE[0] - 110
    lines = wrap(d, text, f, inner)
    lh = f.size + 20
    hi = hand_image(hand, inner + 30) if hand else None
    card_h = len(lines) * lh + 120 + ((hi.height + 44) if hi else 0)
    top = max(SAFE[1] + 40, (SAFE[1] + SAFE[3]) // 2 - card_h // 2 - 40)
    panel = Image.new("RGBA", (SAFE[2] - SAFE[0], card_h), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle((0, 0, panel.width - 1, card_h - 1), 40, fill=(*CREAM, 250))
    shadow(im, panel, (SAFE[0], top), blur=22, alpha=70, drop=12)
    y = top + 60
    if hi:
        im.alpha_composite(hi, (SAFE[0] + 40, y))
        y += hi.height + 44
    for line in lines:
        d.text((SAFE[0] + 55, y), line, font=f, fill=INK)
        y += lh
    return im.convert("RGB")


def app_slide(text: str, shots: tuple[str, str]) -> Image.Image:
    im = Image.new("RGBA", (W, H), (*CREAM, 255))
    d = ImageDraw.Draw(im)
    f = font(54, "Semibold")
    lines = wrap(d, text, f, SAFE[2] - SAFE[0] - 20)
    y = SAFE[1] + 40
    for line in lines:
        d.text((CX - d.textlength(line, font=f) / 2, y), line, font=f, fill=INK)
        y += f.size + 14
    badge_top = SAFE[3] - 150
    sw, gap = 425, 36
    shot_top = y + 50
    shot_h = badge_top - 50 - shot_top
    for i, key in enumerate(shots):
        s = Image.open(CAPS / SHOTS[key]).convert("RGB")
        s = s.resize((sw, int(s.height * sw / s.width)), Image.LANCZOS)
        s = s.crop((0, 0, sw, min(s.height, shot_h)))
        shadow(im, rounded(s, 36), (CX - sw - gap // 2 + i * (sw + gap), shot_top), blur=22, alpha=70)
    icon = rounded(Image.open(ICON).convert("RGB").resize((120, 120), Image.LANCZOS), 27)
    nf, sf = font(46), font(30, "Regular")
    name, sub = "Bridge Trainer", "Free to start on the App Store · I made it"
    tw = max(d.textlength(name, font=nf), d.textlength(sub, font=sf))
    x = int(CX - (120 + 26 + tw) / 2)
    shadow(im, icon, (x, badge_top), blur=10, alpha=60, drop=5)
    d.text((x + 146, badge_top + 14), name, font=nf, fill=INK)
    d.text((x + 146, badge_top + 72), sub, font=sf, fill=MUTED)
    return im.convert("RGB")


def check_posts() -> None:
    """Fail the build on a bad hand, a wrong quiz key, or an em dash."""
    assert len(P.POSTS) == 42 and len({p["id"] for p in P.POSTS}) == 42
    for p in P.POSTS:
        assert "—" not in repr(p), p["id"]
        assert all(k in SHOTS for k in p["shots"]), p["id"]
        if p.get("hand"):
            cards = parse_hand(p["hand"])
            assert len(cards) == 13 and len(set(cards)) == 13, p["id"]
        if p.get("options"):
            assert p["answer"] in p["options"], p["id"]
            letter = "ABCD"[p["options"].index(p["answer"])]
            assert p["s3"].startswith(f"Answer: {letter}"), p["id"]
    expected = {"C1": 12, "C2": 12, "C3": 15, "C4": 6, "C5": 10, "C6": 10}
    for p in P.POSTS:
        if p["id"] in expected:
            assert hcp(p["hand"]) == expected[p["id"]], (p["id"], hcp(p["hand"]))


def schedule() -> list[dict]:
    by_fmt = {k: [p for p in P.POSTS if p["fmt"] == k] for k in P.FORMATS}
    return [by_fmt[k][r] for r in range(6) for k in P.FORMATS]


def cta_variant(post: dict) -> str:
    """Alternate the two CTAs inside each format: 3 posts each, so formats compare fairly."""
    same = [p["id"] for p in P.POSTS if p["fmt"] == post["fmt"]]
    return "comment" if same.index(post["id"]) % 2 == 0 else "name"


def caption_txt(post: dict, cta: str) -> str:
    tags = " ".join(post["tags"])
    return (
        f"TITLE (photo mode title field):\n{post['hook']}\n\n"
        f"CAPTION (paste as is):\n{post['caption']} {post.get('question', P.QUESTIONS[post['fmt']])}\n\n"
        f"{P.CTAS[cta]}\n\n{tags}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{P.PINNED}\n\n"
        f"REPLY to every \"app\" or \"name?\" comment:\n{P.REPLY}\n\n"
        f"BEFORE POSTING: More options > Disclose post content > Your brand.\n"
        f"SOUND (Commercial Music Library): {P.SOUNDS[post['sound']]}\n\n"
        f"FORMAT: {post['fmt']} {P.FORMATS[post['fmt']]}   CTA: {cta}\n"
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ICLOUD))
    ap.add_argument("--only", help="render just these post ids, comma separated (for QA)")
    args = ap.parse_args()
    check_posts()
    out = pathlib.Path(args.out)
    only = set(args.only.split(",")) if args.only else None
    slots = ["1 Morning", "2 Midday", "3 Evening"]
    if out.exists() and not only:
        for child in out.glob("Day *"):
            shutil.rmtree(child)
    rows = []
    for i, post in enumerate(schedule()):
        day, slot = i // 3 + 1, slots[i % 3]
        cta = cta_variant(post)
        rows.append({"day": day, "slot": slot, "post": post["id"],
                     "format": f"{post['fmt']} {P.FORMATS[post['fmt']]}", "cta": cta,
                     "hook": post["hook"], "account": "A" if (i % 3) != 1 else "B",
                     "views_24h": "", "views_72h": "", "saves": "", "app_comments": "",
                     "profile_views": "", "trials_next_72h": "", "call": ""})
        if only and post["id"] not in only:
            continue
        folder = out / f"Day {day:02d}" / f"{slot} - {post['id']} {P.FORMATS[post['fmt']]}"
        folder.mkdir(parents=True, exist_ok=True)
        hand = post.get("hand")
        quiz = post["fmt"] == "C"
        slides = [
            quiz_slide(post, i) if quiz else hook_slide(post, i),
            card_slide(i, post["s2"], hand if quiz or post.get("hand_slide", 2) == 2 else None),
            card_slide(i, post["s3"], hand if not quiz and post.get("hand_slide") == 3 else None),
            app_slide(post["s4"], post["shots"]),
            card_slide(i, post["s5"], None),
        ]
        for n, s in enumerate(slides, 1):
            s.save(folder / f"{n}.jpg", quality=92)
        (folder / "caption.txt").write_text(caption_txt(post, cta))
    if not only:
        with open(out / "Tracker.csv", "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)
    print(f"wrote {len(only) if only else len(rows)} posts to {out}")


if __name__ == "__main__":
    main()
