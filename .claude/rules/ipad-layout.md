---
paths:
  - "Bridge/Views/Components/CenteringScrollView.swift"
  - "Bridge/Views/Components/QuestionUI.swift"
  - "Bridge/Views/Drills/FlashcardDrillView.swift"
  - "Bridge/Views/HomeView.swift"
  - "project.yml"
---

# Bridge Trainer: iPad layout

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## iPad (1.2)

iPad support is free: `TARGETED_DEVICE_FAMILY "1,2"`, portrait and landscape,
adaptive Home columns, drill grids, and readable content widths.

Every drill body is a scroll view, so a question that underfills the viewport
was pinned to the top and left the bottom half of a 13-inch iPad empty.
`CenteringScrollView` centres short content and leaves taller content scrolling
untouched (minHeight, not height). Keep its `maxWidth: .infinity`: a plain
ScrollView centres narrow content for you, an explicitly framed one does not.
The room eyebrow lives INSIDE `QuestionPager` so it centres with the question,
and the flashcard deck is capped at 520pt wide so a card still looks like a
card.
