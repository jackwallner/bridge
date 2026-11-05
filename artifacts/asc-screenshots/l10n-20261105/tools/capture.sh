#!/bin/bash
set -euo pipefail
kit=$(cd "$(dirname "$0")/.." && pwd)
repo=$(git -C "$kit" rev-parse --show-toplevel)
locales="$repo/BridgeScreenshots/LocalizedCaptureLocales.json"
backup=$(mktemp)
idfile=$(mktemp)
cp "$locales" "$backup"
trap 'cp "$backup" "$locales"; rm -f "$backup" "$idfile"' EXIT
python3 - "$backup" "$locales" "$@" <<'PY'
import json, sys
from pathlib import Path
source, target, *wanted = sys.argv[1:]
locales = json.loads(Path(source).read_text())
valid = {item['store_locale'] for item in locales}
if set(wanted) - valid:
    raise SystemExit('unknown locales: ' + ', '.join(sorted(set(wanted) - valid)))
if wanted:
    locales = [item for item in locales if item['store_locale'] in {'en-US', *wanted}]
Path(target).write_text(json.dumps(locales, ensure_ascii=False, indent=2) + '\n')
PY
failed=0
for spec in 'phone|iPhone 17 Pro Max' 'ipad|iPad Pro 13-inch (M5)'; do
  set_name=${spec%%|*}
  device=${spec#*|}
  : > "$idfile"
  gh-sim -C "$repo" test --scheme Screenshots --device "$device" \
    --only BridgeScreenshots/ScreenshotTests/testCaptureLocalizedSet --id-file "$idfile" || failed=1
  id=$(cat "$idfile")
  if [ -n "$id" ]; then
    python3 "$kit/tools/sort_captures.py" "$HOME/.gh-sim/results/$id/attachments" "$kit/raw" "$set_name" "$locales" || failed=1
  else
    failed=1
  fi
done
exit "$failed"
