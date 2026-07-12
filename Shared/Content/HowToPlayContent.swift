import Foundation

/// One page of the How to Play quick start. All example tiles are original
/// teaching arrangements, never hands from the NMJL card.
struct HowToPlayPage: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let tiles: [Tile]
    let tip: String?

    init(id: String, icon: String, title: String, body: String, tiles: [Tile] = [], tip: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.tiles = tiles
        self.tip = tip
    }
}

/// The five-minute primer for players who picked "brand new" in onboarding.
/// Original teaching content only; the real card and its hands stay with the
/// NMJL.
enum HowToPlayContent {
    static let pages: [HowToPlayPage] = [
        HowToPlayPage(
            id: "htp-goal",
            icon: "flag.checkered",
            title: "The goal",
            body: "Every player races to build a 14-tile hand that exactly matches one of the hands printed on the yearly card. Thirteen tiles live on your rack; the fourteenth is the tile you draw or call that completes the pattern. Complete it first and you call mahj.",
            tiles: [.c(3), .c(3), .c(3)],
            tip: "Three of a kind is a pung. Most hands are built from groups like this."
        ),
        HowToPlayPage(
            id: "htp-tiles",
            icon: "square.grid.3x3.fill",
            title: "Meet the tiles",
            body: "Three suits run 1 through 9: craks (red), bams (green), and dots (blue). Winds are printed N, E, W, S. Each dragon belongs with a suit: red with craks, green with bams, and the blank soap with dots. Flowers are bonus tiles, and jokers stand in for tiles inside bigger groups.",
            tiles: [.c(5), .b(5), .d(5), .wind(.north), .dragon(.red), .flower, .joker]
        ),
        HowToPlayPage(
            id: "htp-card",
            icon: "menucard.fill",
            title: "Read the card",
            body: "The card groups its hands into sections, like even numbers or runs. You never memorize every hand. You learn to spot which section your rack is drifting toward, pick a target, and chase it.",
            tiles: [.c(2), .c(4), .b(6), .d(8)],
            tip: "All even numbers? That rack is whispering which section to check first."
        ),
        HowToPlayPage(
            id: "htp-charleston",
            icon: "arrow.left.arrow.right",
            title: "The Charleston",
            body: "Before play begins, everyone passes three unwanted tiles: right, across, then left, with an optional second round. Jokers never pass. The Charleston is how a messy deal turns into a plan.",
            tiles: [.b(1), .d(9), .wind(.west)],
            tip: "Pass tiles that fit no section you are chasing. Never pass a joker."
        ),
        HowToPlayPage(
            id: "htp-turn",
            icon: "hand.draw.fill",
            title: "Play a turn",
            body: "On your turn, draw a tile, then keep it or discard one face up. You may call a discard for a pung, kong, or quint and expose that group. Pairs and single tiles can only be called when the discard completes mahj, and hands marked concealed cannot call except for mahj. Match your whole hand to the card and you win.",
            tiles: [.d(7), .d(7), .d(7), .joker],
            tip: "A joker can sit inside a pung or bigger group, never alone as a pair partner."
        ),
        HowToPlayPage(
            id: "htp-ready",
            icon: "checkmark.seal.fill",
            title: "You're ready to train",
            body: "That's the whole shape of the game: build toward the card, survive the Charleston, and read racks fast. The drills teach each skill one room at a time, five minutes at a stretch."
        ),
    ]
}
