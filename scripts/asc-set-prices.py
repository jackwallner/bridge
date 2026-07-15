#!/usr/bin/env python3
"""Set Bridge Trainer subscription prices in every territory from the USA base.

Adapted from Queasy's asc-equalize-sub-prices.py. Takes the target USA price
point per subscription, fetches Apple's equalizations, and posts a
subscriptionPrice for every territory (price change, REPLACE_EXISTING
semantics).

Usage: source ~/.baseball_credentials && python3 scripts/asc-set-prices.py
"""

import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

BUNDLE = "com.jackwallner.bridge"
USA_PRICES = {
    "com.jackwallner.bridge.monthly": "1.99",
    "com.jackwallner.bridge.yearly": "9.99",
}


def main() -> None:
    c = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(c, BUNDLE)
    group = c.get(f"/apps/{app['id']}/subscriptionGroups")["data"][0]

    for sub in c.get(f"/subscriptionGroups/{group['id']}/subscriptions")["data"]:
        pid = sub["attributes"]["productId"]
        if pid not in USA_PRICES:
            continue
        sub_id = sub["id"]

        points = asc_lib.list_all(
            c, f"/subscriptions/{sub_id}/pricePoints?filter[territory]=USA&limit=200"
        )
        usa_point = next(
            p for p in points if p["attributes"]["customerPrice"] == USA_PRICES[pid]
        )

        eq = asc_lib.list_all(
            c,
            f"/subscriptionPricePoints/{urllib.parse.quote(usa_point['id'], safe='')}"
            "/equalizations?include=territory&limit=200",
        )
        created = 0
        failed = 0
        for point in eq + [usa_point]:
            terr = (point.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if point is usa_point:
                terr = "USA"
            if not terr:
                continue
            try:
                c.post(
                    "/subscriptionPrices",
                    {
                        "data": {
                            "type": "subscriptionPrices",
                            "relationships": {
                                "subscription": {"data": {"type": "subscriptions", "id": sub_id}},
                                "subscriptionPricePoint": {
                                    "data": {"type": "subscriptionPricePoints", "id": point["id"]}
                                },
                            },
                        }
                    },
                )
                created += 1
            except RuntimeError as e:
                failed += 1
                print(f"  {terr}: {e}", file=sys.stderr)
        print(f"{pid}: posted {created} territory prices ({failed} failed)")

    print("done")


if __name__ == "__main__":
    main()
