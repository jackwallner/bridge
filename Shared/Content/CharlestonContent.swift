import Foundation

/// The Charleston Room: rules and strategy for the passing phase,
/// plus interactive "pick 3 to pass" scenarios.
enum CharlestonContent {

    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "ch-what",
            frontTitle: "What is the Charleston?",
            frontSubtitle: "The part that scares everyone",
            backTitle: "The Charleston",
            backBody: "Before play starts, everyone passes tiles: three passes (right, across, left), an optional second round (left, across, right), then an optional courtesy pass across. You always pass exactly 3 tiles. It exists so you can trade junk for a real hand."
        ),
        Flashcard(
            id: "ch-first-look",
            frontTitle: "Before Your First Pass",
            frontSubtitle: "What do you do with a fresh deal?",
            backTitle: "Sort, Then Shortlist",
            backBody: "Rack your tiles by suit and number, then shortlist 2-3 card sections your deal leans toward. Don't marry one hand yet: pass the tiles that help NONE of your shortlist."
        ),
        Flashcard(
            id: "ch-jokers",
            frontTitle: "Jokers in the Charleston",
            frontSubtitle: "Rule, not suggestion",
            backTitle: "Never. It's Illegal.",
            backBody: "Jokers may never be passed in the Charleston or courtesy pass. If you're ever handed one, someone broke the rules. (Flowers CAN be passed, but usually shouldn't be early.)"
        ),
        Flashcard(
            id: "ch-flowers",
            frontTitle: "Should You Pass Flowers?",
            frontSubtitle: "They look useless...",
            backTitle: "Hold Them Early",
            backBody: "Flowers appear in sections all over the card, so a flower is rarely dead. Early in the Charleston, keep them. If you're deep into a hand with no F in it, they become passes."
        ),
        Flashcard(
            id: "ch-pairs",
            frontTitle: "Breaking Up Pairs",
            frontSubtitle: "You need 3 tiles to pass, and...",
            backTitle: "Don't Break Pairs",
            backBody: "Pairs are gold: jokers can't make them, so natural pairs anchor hands. Pass lone strays (single winds, isolated numbers) before you ever split a pair, even a pair you're not sure you'll use."
        ),
        Flashcard(
            id: "ch-blind",
            frontTitle: "The Blind Pass",
            frontSubtitle: "a.k.a. stealing",
            backTitle: "Blind Pass",
            backBody: "On the LAST pass of either Charleston, if you don't want to give up 3 tiles, you may pass 1-3 of the tiles being passed TO you without looking at them. Great when your hand is already tight."
        ),
        Flashcard(
            id: "ch-stop",
            frontTitle: "Stopping the Second Charleston",
            frontSubtitle: "You have this power",
            backTitle: "Anyone Can Stop It",
            backBody: "The second Charleston only happens if ALL players agree. If your hand is already strong after round one, say stop: extra passing mostly helps the players with bad hands."
        ),
        Flashcard(
            id: "ch-courtesy",
            frontTitle: "The Courtesy Pass",
            frontSubtitle: "The final exchange",
            backTitle: "Courtesy Pass",
            backBody: "After the Charleston, you and the player across can swap 0-3 tiles: you exchange the SAME number, agreed out loud ('two?'). Ask for fewer if your hand is close."
        ),
        Flashcard(
            id: "ch-watch",
            frontTitle: "Read the Incoming Tiles",
            frontSubtitle: "Free information",
            backTitle: "Passes Tell Stories",
            backBody: "Whatever arrives is what a neighbor DIDN'T need. Three winds from your right? They're not on Winds & Dragons. Also note what never comes back: those tiles are being collected."
        ),
        Flashcard(
            id: "ch-telegraph",
            frontTitle: "Don't Telegraph",
            frontSubtitle: "Passing has a defense side too",
            backTitle: "Split Related Tiles",
            backBody: "Avoid passing three tiles from the same section in one bundle (say, 2C 4C 6C): you might be handing one opponent a head start. Split related discards across different passes."
        ),
    ]

    static let scenarios: [CharlestonScenario] = [
        CharlestonScenario(
            id: "cs-evens",
            situation: "First Charleston, pass RIGHT. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .c(4), .c(4), .b(6), .b(6), .b(8), .d(8), .flower, .joker, .c(5), .b(7), .wind(.north)],
            recommendedPass: [.c(5), .b(7), .wind(.north)],
            reasoning: "This deal leans hard into 2468: three even pairs plus two more evens working on it, and a flower and a joker that fit anywhere. The 5 Crak, 7 Bam and lone North help none of that. The joker can never be passed, and the flower should stay early.",
            tip: "First pass: dump the tiles that fit NONE of your 2-3 candidate sections."
        ),
        CharlestonScenario(
            id: "cs-winds",
            situation: "First Charleston, pass RIGHT. Pick 3 tiles to pass.",
            deal: [.wind(.north), .wind(.north), .wind(.north), .wind(.east), .wind(.west), .wind(.west), .wind(.south), .dragon(.red), .c(3), .d(6), .b(9), .flower, .joker],
            recommendedPass: [.c(3), .d(6), .b(9)],
            reasoning: "Seven winds and a dragon: this is a Winds & Dragons hand. The three scattered number tiles (3C, 6D, 9B) are strays in three different suits; they can't grow into anything together. Easy passes.",
            tip: "A pung of winds is a commitment. Once you have one, feed it."
        ),
        CharlestonScenario(
            id: "cs-run",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.c(4), .c(5), .c(6), .b(5), .b(6), .b(7), .d(6), .d(6), .c(1), .d(9), .wind(.north), .flower, .joker],
            recommendedPass: [.c(1), .d(9), .wind(.north)],
            reasoning: "Middle numbers 4-7 in every suit: a Consecutive Run dream. A 1 and a 9 can't join a 4-5-6-7 run, and the lone North is dead weight. Keep the 6 Dot pair: pairs anchor hands.",
            tip: "For Consecutive Run hands, middle numbers (4-7) are the most flexible tiles in the game."
        ),
        CharlestonScenario(
            id: "cs-pairs",
            situation: "First Charleston, pass LEFT. Pick 3 tiles to pass.",
            deal: [.c(3), .c(3), .b(7), .b(7), .d(9), .d(9), .c(5), .b(1), .wind(.west), .d(4), .c(8), .flower, .joker],
            recommendedPass: [.d(4), .c(8), .wind(.west)],
            reasoning: "Three natural pairs of odd numbers point at 13579 (or even Singles & Pairs). Keep every odd tile: the 5C and 1B still fit odd hands. Pass the evens (4D, 8C) and the lone wind. Never break the pairs.",
            tip: "Tiles that fit your section stay, even unpaired. Pass tiles from the WRONG number family first."
        ),
        CharlestonScenario(
            id: "cs-junk",
            situation: "First Charleston, pass RIGHT. Nothing looks good. Pick 3.",
            deal: [.wind(.west), .wind(.west), .wind(.north), .wind(.east), .wind(.south), .c(2), .b(5), .d(8), .c(9), .d(1), .joker, .joker, .flower],
            recommendedPass: [.d(1), .c(9), .b(5)],
            reasoning: "Five winds plus two jokers: leaning Winds & Dragons. All five number tiles are strays, so any three of them is a fine pass; we'd keep the 2C and 8D since even tiles give you a 2468 escape route if the winds dry up. Jokers can never be passed.",
            tip: "With a junk deal, pass strays but keep tiles that preserve a second option."
        ),
        CharlestonScenario(
            id: "cs-flowers",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.flower, .flower, .flower, .b(2), .b(4), .b(6), .b(8), .b(8), .d(2), .c(9), .wind(.north), .joker, .c(5)],
            recommendedPass: [.c(9), .c(5), .wind(.north)],
            reasoning: "Three flowers plus a wall of even bams: this deal wants an evens or year hand, and flowers feature in both. The odd craks (9C, 5C) and lone North contribute nothing. Whatever you do, don't pass the flowers.",
            tip: "Flowers are the most re-usable tiles on the card. Early passes should almost never include one."
        ),
        CharlestonScenario(
            id: "cs-like",
            situation: "Second Charleston, pass LEFT. Pick 3 tiles to pass.",
            deal: [.c(6), .c(6), .b(6), .b(6), .b(6), .d(6), .d(6), .c(4), .b(8), .wind(.north), .wind(.east), .flower, .joker],
            recommendedPass: [.c(4), .b(8), .wind(.north)],
            reasoning: "SEVEN sixes: Any Like Numbers is nearly built, and 6s keep 369 open as a backup. The 4C and 8B are decoys ('but they're even!'): you're not playing 2468 with seven sixes. Either lone wind plus the two stray numbers is the right bundle.",
            tip: "Count your longest section, not your prettiest. Seven of one number beats four scattered evens."
        ),
        CharlestonScenario(
            id: "cs-commit",
            situation: "First Charleston, pass RIGHT. Two sections look possible. Pick 3.",
            deal: [.c(2), .c(2), .c(4), .c(6), .c(8), .b(3), .b(5), .b(7), .b(9), .flower, .joker, .wind(.north), .wind(.west)],
            recommendedPass: [.b(3), .b(5), .wind(.north)],
            reasoning: "Evens in craks (five tiles with a pair) vs odds in bams (four loners): follow the count and commit to 2468. But don't ship 3B-5B-7B in one bundle to one player: that's a 13579 care package. Send two odds plus a lone wind; the rest go out over later passes.",
            tip: "When two sections compete, commit to the longer one, and split the losers' tiles across different passes."
        ),
        CharlestonScenario(
            id: "cs-year",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .b(2), .dragon(.soap), .dragon(.soap), .b(6), .d(6), .flower, .flower, .c(7), .d(3), .wind(.south), .joker],
            recommendedPass: [.c(7), .d(3), .wind(.south)],
            reasoning: "2s, soaps, 6s, flowers: every ingredient of a 2026 year hand. New players pass soaps constantly ('weird blank tile'), but here they're your zeros. The 7C, 3D and lone South are the only tiles with no job.",
            tip: "Before passing a soap, check the year hands. That blank tile is a zero."
        ),
    ]
}
