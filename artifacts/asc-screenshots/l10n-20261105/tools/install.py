#!/usr/bin/env python3
"""Install reviewed frames without changing other screenshots or subfolders."""
import json
import shutil
from pathlib import Path

kit = Path(__file__).resolve().parent.parent
repo = kit.parents[2]
app = json.loads((kit / 'app.json').read_text())
config = json.loads((kit / 'frames.json').read_text())
copies = []
for target in app['targets']:
    locale = target['store_locale']
    destination = repo / 'fastlane/screenshots' / locale
    for name, group in config['sets'].items():
        for frame in group['frames']:
            filename = frame['file']
            if Path(filename).name != filename:
                raise ValueError(f'invalid filename: {filename}')
            source = kit / 'out' / locale / name / filename
            if not source.is_file():
                raise FileNotFoundError(source)
            copies.append((source, destination / filename))
for source, destination in copies:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
print(f'installed {len(copies)} reviewed frames')
