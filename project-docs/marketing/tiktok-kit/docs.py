#!/usr/bin/env python3
"""Write the kit's daily checklist and print both handouts to PDF in the kit folder.

    python3 docs.py [--warmup 2026-11-03] [--out <dir>]

Day 01 starts the day after the 7-day warmup. PDFs print with headless Chrome
on a throwaway profile, so Jack's own Chrome is untouched.
"""
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import subprocess
import tempfile

import build_kit as K
import posts as P

HERE = pathlib.Path(__file__).resolve().parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def day(d: dt.date) -> str:
    return d.strftime("%a %b ") + str(d.day)


def checklist(warmup: dt.date) -> str:
    head = (HERE / "checklist.template.html").read_text()
    rows = []
    for i in range(7):
        extra = " + one non-promo post on each" if i >= 4 else ""
        if i == 6:
            extra += ". Check: For You is mostly bridge and card games"
        rows.append(f'<tr><td class="cb"></td><td><b>W{i + 1}</b></td><td>{day(warmup + dt.timedelta(i))}</td>'
                    f'<td colspan="3">Scroll 10 min on A and B, twice{extra}</td></tr>')
    posts = K.schedule()
    days = []
    for n in range(14):
        cells = "".join(f'<td>{p["id"]} <span>{P.FORMATS[p["fmt"]]}</span></td>' for p in posts[n * 3:n * 3 + 3])
        days.append(f'<tr><td class="cb"></td><td><b>Day {n + 1:02d}</b></td>'
                    f'<td>{day(warmup + dt.timedelta(7 + n))}</td>{cells}</tr>')
    return head.replace("{{WARMUP}}", "".join(rows)).replace("{{DAYS}}", "".join(days))


def pdf(html: pathlib.Path, out: pathlib.Path) -> None:
    with tempfile.TemporaryDirectory() as profile:
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", f"--user-data-dir={profile}",
                        "--no-pdf-header-footer", f"--print-to-pdf={out}", html.as_uri()],
                       check=True, capture_output=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--warmup", default="2026-11-03", help="first warmup day")
    ap.add_argument("--out", default=str(K.ICLOUD))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    (HERE / "checklist.html").write_text(checklist(dt.date.fromisoformat(args.warmup)))
    pdf(HERE / "checklist.html", out / "Daily checklist.pdf")
    pdf(HERE / "guide.html", out / "Posting guide.pdf")
    print(f"wrote Daily checklist.pdf and Posting guide.pdf to {out}")


if __name__ == "__main__":
    main()
