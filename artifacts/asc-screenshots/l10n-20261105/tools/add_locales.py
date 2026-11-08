#!/usr/bin/env python3
"""Add every app.json target missing from BridgeScreenshots/LocalizedCaptureLocales.json, strings read from the catalog."""
import json
from pathlib import Path

kit = Path(__file__).resolve().parent.parent
repo = kit.parents[2]
path = repo / 'BridgeScreenshots/LocalizedCaptureLocales.json'
locales = json.loads(path.read_text())
catalog = json.loads((repo / 'Bridge/Localizable.xcstrings').read_text())['strings']
have = {item['store_locale'] for item in locales}
keys = list(locales[0]['strings'])
for target in json.loads((kit / 'app.json').read_text())['targets']:
    if target['store_locale'] in have:
        continue
    strings = {k: catalog[k]['localizations'][target['lang']]['stringUnit']['value'] for k in keys}
    locales.append({'store_locale': target['store_locale'], 'lang': target['lang'], 'apple_locale': target['apple_locale'], 'strings': strings})
    print('added', target['store_locale'])
path.write_text(json.dumps(locales, ensure_ascii=False, indent=2) + '\n')
