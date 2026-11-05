#!/bin/bash
set -euo pipefail
kit=$(cd "$(dirname "$0")/.." && pwd)
repo=$(git -C "$kit" rev-parse --show-toplevel)
python="$kit/.venv/bin/python"
failed=0
while IFS='|' read -r locale lang; do
  echo "Composing $locale"
  if ! "$python" "$kit/tools/reskin.py" --config "$kit/frames.json" --raw-root "$kit/raw" --headers "$kit/copy/headers.json" --locale "$locale" --out "$kit/out"; then
    failed=1
    continue
  fi
  "$python" "$kit/tools/gate.py" --config "$kit/frames.json" --raw-root "$kit/raw" --headers "$kit/copy/headers.json" --out-root "$kit/out" --locale "$locale" --catalog "$repo/Bridge/Localizable.xcstrings" --lang "$lang" || failed=1
  "$python" "$kit/tools/sheet.py" --config "$kit/frames.json" --locale "$locale" --out-root "$kit/out" || failed=1
done < <(python3 - "$kit/app.json" "$@" <<'PY'
import json, sys
from pathlib import Path
app = json.loads(Path(sys.argv[1]).read_text())
wanted = set(sys.argv[2:])
valid = {item['store_locale'] for item in app['targets']}
if wanted - valid:
    raise SystemExit('unknown locales: ' + ', '.join(sorted(wanted - valid)))
for item in app['targets']:
    if not wanted or item['store_locale'] in wanted:
        print(item['store_locale'] + '|' + item['lang'])
PY
)
mkdir -p "$kit/sheets"
if compgen -G "$kit/out/sheets/*.jpg" >/dev/null; then
  cp "$kit/out/sheets/"*.jpg "$kit/sheets/"
fi
exit "$failed"
