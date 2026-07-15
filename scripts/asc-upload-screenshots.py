#!/usr/bin/env python3
"""Upload fastlane/screenshots/<locale>/*.png to the draft ASC version.

iPhone-only app: everything goes to the 6.9" display type (APP_IPHONE_67),
which accepts 1320x2868. Existing shots in the set are replaced.

    python3 scripts/asc-upload-screenshots.py [--locale en-US]
"""
from __future__ import annotations

import argparse
import hashlib
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib as L

BUNDLE = "com.jackwallner.bridge"
DISPLAY_TYPE = "APP_IPHONE_67"


def upload(c: L.ASCClient, set_id: str, png: Path) -> None:
    blob = png.read_bytes()
    created = c.post(
        "/appScreenshots",
        {
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileSize": len(blob), "fileName": png.name},
                "relationships": {
                    "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
                },
            }
        },
    )["data"]
    for op in created["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]: op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op["requestHeaders"]:
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req, timeout=300).read()
    c.patch(
        f"/appScreenshots/{created['id']}",
        {
            "data": {
                "type": "appScreenshots",
                "id": created["id"],
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": hashlib.md5(blob).hexdigest(),
                },
            }
        },
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--locale", default="en-US")
    args = ap.parse_args()

    shots = sorted((L.ROOT / "fastlane/screenshots" / args.locale).glob("*.png"))
    if not shots:
        raise SystemExit(f"error: no screenshots for {args.locale}")

    c = L.ASCClient(L.bearer_token(*L.load_credentials()))
    app_id = L.find_app(c, BUNDLE)["id"]
    version = L.ensure_draft_version(c, app_id, None)
    locs = {
        x["attributes"]["locale"]: x
        for x in L.list_all(c, f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations")
    }
    loc = locs[args.locale]

    sets = {
        s["attributes"]["screenshotDisplayType"]: s
        for s in L.list_all(c, f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
    }
    if DISPLAY_TYPE in sets:
        set_id = sets[DISPLAY_TYPE]["id"]
        for old in L.list_all(c, f"/appScreenshotSets/{set_id}/appScreenshots"):
            c.request("DELETE", f"/appScreenshots/{old['id']}")
    else:
        set_id = c.post(
            "/appScreenshotSets",
            {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                        }
                    },
                }
            },
        )["data"]["id"]

    for png in shots:
        upload(c, set_id, png)
        print(f"uploaded {png.name}")
    print(f"\n{len(shots)} screenshot(s) on {args.locale} / {DISPLAY_TYPE} (version {version['attributes']['versionString']})")


if __name__ == "__main__":
    main()
