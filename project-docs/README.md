# Project documentation

Developer notes and historical audits for this repository. The published site remains in the docs directory.

## Audits

- [aso827.md](audits/aso827.md): Bridge Trainer ASO Audit
- [audit823.md](audits/audit823.md): Bridge Trainer audit
- [ios27Bridge.md](audits/ios27Bridge.md): iOS 27 compatibility audit: Bridge
- [mahj-parity-audit-1020.md](audits/mahj-parity-audit-1020.md): Bridge vs Mahj feature audit and mastery UI
- [state-machines-2026-11-06.md](audits/state-machines-2026-11-06.md): State machine audit: reminders, flashcard undo, Game Night lapse, weekly gain (repro suite alongside)
- [state-machines-2026-11-06-review.md](audits/state-machines-2026-11-06-review.md): Independent review of that audit: 1 confirmed, 3 minor, Game Night lapse ranked first
- [state-machines-2026-11-06-fixes.md](audits/state-machines-2026-11-06-fixes.md): Fixes for the reviewed claims: 5 fixed, 0 held, 0 skipped, 3 product calls held for Jack, SM-3 reworked after the verify
- [state-machines-2026-11-06-verify.md](audits/state-machines-2026-11-06-verify.md): Regression check of the reworked fixes: all 5 work, failed only because P6, an unverified item, was skipped instead of held for Jack

## ASO

- [ASO](aso/README.md): Dated App Store metadata research and updates

## Marketing

- [tiktok-kit](marketing/tiktok-kit/): Bridge TikTok kit, rendered to iCloud `Bridge TikTok Kit`: `build_kit.py` (42 slideshows, 14 days), `shorts.py` (8 animated shorts on the Mahj shorts engine), `extras.py` (extra carousels, More like A1, Instagram 3:4), `docs.py` (checklist and posting guide PDFs)
