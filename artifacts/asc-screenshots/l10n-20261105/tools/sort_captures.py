#!/usr/bin/env python3
"""Sort named XCTest attachments into locale and device directories."""
import json
import re
import shutil
import sys
from pathlib import Path

attachments, raw, set_name, locales_file = map(Path, sys.argv[1:])
set_name = str(set_name)
scenes = {
    'phone': ['opening_answered', 'lead_answered', 'play_answered', 'declarer_room', 'defense_room', 'card_room'],
    'ipad': ['quick', 'opening', 'lead', 'home', 'card_room'],
}[set_name]
locales = json.loads(locales_file.read_text())
manifest = json.loads((attachments / 'manifest.json').read_text())
found = {}
for test in manifest:
    for item in test.get('attachments', []):
        name = item.get('suggestedHumanReadableName', '')
        for locale in locales:
            for scene in scenes:
                token = locale['store_locale'] + '__' + scene
                if re.match(re.escape(token) + r'_\d+_', name):
                    found[(locale['store_locale'], scene)] = attachments / item['exportedFileName']
missing = []
for locale in locales:
    for scene in scenes:
        key = locale['store_locale'], scene
        if key not in found:
            missing.append(f'{key[0]}__{scene}')
            continue
        target = raw / key[0] / set_name / (scene + '.png')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(found[key], target)
print(f'{set_name}: sorted {len(found)} captures')
if missing:
    raise SystemExit('missing attachments: ' + ', '.join(missing))
