# Flashcard deck (signature interaction)

`FlashcardDrillView` is a Sideline-style swipe deck: tap flips the card, and
only a flipped card can be swiped — right = "got it" (leaves the deck), left =
"again" (returns at the back). Pre-flip drags rubber-band. Undo lives in the
toolbar. Cards with a `CardChoice` show two answer buttons on the front
(choose, graded flip, held result, explicit Next). Their answer determines the
grade and whether the card returns; swipe direction never overrides it. Gesture
gotcha: the deck uses ONE
`DragGesture(minimumDistance: 0)` that treats a <10pt release as the flip
tap — a separate `.onTapGesture` loses arbitration against the drag and
silently never fires. Don't "simplify" it back to `onTapGesture`.

**Flip gotcha (fixed 2026-07-12):** the whole card must rotate as ONE unit —
`FlipRotation` is `Animatable` and swaps faces exactly at 90° while the card is
edge-on. Never rotate the text faces inside a static card background; that's
what made text detach from the card. `MahjCardFace` carries the mahjong-card
chrome (ivory surface, double frame, eyebrow, watermark) — both faces use it.
