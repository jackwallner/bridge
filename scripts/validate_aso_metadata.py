#!/usr/bin/env python3
"""Validate App Store text fields for selected fastlane locales."""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIELD_LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
}
FIELDS = tuple(FIELD_LIMITS)
TOKEN_PATTERN = re.compile(r"[^\W_]+", re.UNICODE)

def normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    return "".join(char for char in decomposed if not unicodedata.combining(char))


def visible_tokens(value: str) -> set[str]:
    return {normalize(token) for token in TOKEN_PATTERN.findall(value)}


def keyword_tokens(value: str) -> list[str]:
    tokens: list[str] = []
    for phrase in value.split(","):
        if contains_no_space_script(phrase):
            tokens.append(normalize(phrase.strip()))
        else:
            tokens.extend(normalize(token) for token in TOKEN_PATTERN.findall(phrase))
    return tokens


def contains_no_space_script(value: str) -> bool:
    return any(
        "CJK" in unicodedata.name(char, "")
        or "HIRAGANA" in unicodedata.name(char, "")
        or "KATAKANA" in unicodedata.name(char, "")
        or "THAI" in unicodedata.name(char, "")
        for char in value
    )


def read_field(locale: str, field: str) -> str:
    path = ROOT / "fastlane" / "metadata" / locale / f"{field}.txt"
    if not path.is_file():
        raise FileNotFoundError(path)
    raw = path.read_text(encoding="utf-8")
    return raw[:-1] if raw.endswith("\n") else raw


def validate_locale(locale: str) -> list[str]:
    errors: list[str] = []
    values: dict[str, str] = {}
    for field in FIELDS:
        try:
            value = read_field(locale, field)
        except FileNotFoundError as error:
            errors.append(str(error))
            continue
        values[field] = value
        limit = FIELD_LIMITS[field]
        if len(value) > limit:
            errors.append(f"{locale}/{field}: {len(value)} characters, limit {limit}")
        if not value:
            errors.append(f"{locale}/{field}: empty value")
        if value != value.strip():
            errors.append(f"{locale}/{field}: leading or trailing whitespace")
        if "\u2014" in value:
            errors.append(f"{locale}/{field}: contains an em dash")

    keywords = values.get("keywords")
    name = values.get("name")
    subtitle = values.get("subtitle")
    if keywords is None or name is None or subtitle is None:
        return errors

    tokens = keyword_tokens(keywords)
    seen: set[str] = set()
    for token in tokens:
        if token in seen:
            errors.append(f"{locale}/keywords: duplicate token {token!r}")
        seen.add(token)

    visible = visible_tokens(f"{name} {subtitle}")
    visible_text = normalize(f"{name} {subtitle}")
    for token in sorted(set(tokens)):
        if token in visible:
            errors.append(f"{locale}/keywords: token {token!r} repeats name or subtitle")
        elif contains_no_space_script(token) and token in visible_text:
            errors.append(f"{locale}/keywords: token {token!r} repeats name or subtitle")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    choices = sorted(path.name for path in (ROOT / "fastlane/metadata").iterdir() if path.is_dir())
    parser.add_argument("locales", nargs="+", choices=choices)
    args = parser.parse_args()

    failures = 0
    for locale in args.locales:
        errors = validate_locale(locale)
        if errors:
            failures += len(errors)
            for error in errors:
                print(error, file=sys.stderr)
        else:
            print(f"{locale}: OK")
    if failures:
        print(f"Validation failed with {failures} issue(s).", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
