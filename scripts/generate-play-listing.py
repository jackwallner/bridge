#!/usr/bin/env python3
"""Render Bridge Play metadata, preserving the private live-listing snapshot."""
from __future__ import annotations

import json
from pathlib import Path

from play_listing_data import L

ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / 'android/play-assets/metadata/android'
FIELDS = {'title': 'title.txt', 'shortDescription': 'short_description.txt', 'fullDescription': 'full_description.txt'}


def main() -> None:
    live = {item['language']: item for item in json.loads((ROOT / '.play-live-listing.json').read_text())['listings']}
    english = live['en-US']
    listings = {loc: dict(english) for loc in ('en-GB', 'en-AU', 'en-CA', 'en-IN')}
    for loc, listing in listings.items():
        listing['shortDescription'] = 'Learn bridge: count points, choose opening bids and practise card play.' if loc in ('en-GB', 'en-AU', 'en-IN') else 'Learn bridge: count points, choose opening bids and practice card play.'
        if loc in ('en-GB', 'en-AU', 'en-IN'):
            listing['fullDescription'] = english['fullDescription'].replace('Defense', 'Defence').replace('defense', 'defence').replace('canceled', 'cancelled')
    for loc, values in L.items():
        title, short, intro, eng, rooms_h, rooms, plus_h, plus, priv_h, priv, sub, privacy, terms, disc, _ = values
        full = '\n\n'.join([intro, eng, rooms_h, *rooms, plus_h, '\n'.join('- ' + line for line in plus), priv_h, priv, sub,
            privacy + ': https://jackwallner.github.io/bridge/android-privacy.html',
            terms + ': https://jackwallner.github.io/bridge/android-terms.html', disc])
        listings[loc] = dict(title=title, shortDescription=short, fullDescription=full)
    listings.update(live)
    for loc, listing in listings.items():
        folder = METADATA / loc
        folder.mkdir(parents=True, exist_ok=True)
        for field, filename in FIELDS.items():
            (folder / filename).write_text(listing[field], encoding='utf-8')
    print(f'Wrote {len(listings)} locales; preserved {len(live)} live listings.')


if __name__ == '__main__':
    main()
