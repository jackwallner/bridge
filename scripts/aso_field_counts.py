#!/usr/bin/env python3
"""Print per-locale character counts for App Store text fields against their limits.

Usage: scripts/aso_field_counts.py tr nl-NL ...   (no args: every locale)
Pair with scripts/validate_aso_metadata.py for the duplicate-token checks.
"""

from __future__ import annotations

import sys
from pathlib import Path

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170, "description": 4000}
ROOT = Path(__file__).resolve().parents[1] / "fastlane" / "metadata"


def main(argv: list[str]) -> int:
    locales = argv or sorted(p.name for p in ROOT.iterdir() if (p / "name.txt").exists())
    over = 0
    for locale in locales:
        cells = []
        for field, limit in LIMITS.items():
            count = len((ROOT / locale / f"{field}.txt").read_text(encoding="utf-8").rstrip("\n"))
            over += count > limit
            cells.append(f"{field} {count}/{limit}")
        print(f"{locale:8} " + "  ".join(cells))
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
