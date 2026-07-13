import Foundation

/// The Mahj+ extra practice sets: one per beginner room. Same mechanics the
/// room already teaches, just more reps, so upgrading adds volume rather than
/// taking anything away from the free rooms.
///
/// LEGAL: every rack and deal below is an ORIGINAL teaching hand built to
/// illustrate a category family. None is copied from any real NMJL card.
enum PlusContent {

    // MARK: - The Tile Room: more reps

    static let tileExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-tq-set-size",
            prompt: "How many tiles are in a standard American Mah Jongg set?",
            choices: ["136", "144", "152", "160"],
            answerIndex: 2,
            explanation: "152: the 144 base tiles (suits, winds, dragons, flowers) plus the 8 jokers that make American mahj its own game."
        ),
        QuizQuestion(
            id: "plus-tq-green-dragon",
            prompt: "The Green Dragon belongs with which suit?",
            tiles: [.dragon(.green), .b(4)],
            choices: ["Craks", "Bams", "Dots", "It floats between all three"],
            answerIndex: 1,
            explanation: "Green goes with Bams. Red goes with Craks, Soap goes with Dots. When a hand wants a dragon in a suit, the card means THAT suit's dragon."
        ),
        QuizQuestion(
            id: "plus-tq-kong",
            prompt: "What is a kong?",
            tiles: [.d(3), .d(3), .d(3), .d(3)],
            choices: ["3 identical tiles", "4 identical tiles", "5 identical tiles", "Any four tiles in a row"],
            answerIndex: 1,
            explanation: "Four identical tiles. Pung is 3, kong is 4, quint is 5 (and a quint always needs a joker, since only 4 of each tile exist)."
        ),
        QuizQuestion(
            id: "plus-tq-expose",
            prompt: "You call a discard to complete a pung. What happens to those tiles?",
            choices: [
                "They stay hidden on your rack",
                "They go face up on top of your rack for the rest of the hand",
                "You show them once, then hide them",
                "You hand them to the discarder",
            ],
            answerIndex: 1,
            explanation: "They stay face up on your rack for good. That is why calling is a commitment: everyone can see your section, and you cannot switch to a concealed hand afterward."
        ),
        QuizQuestion(
            id: "plus-tq-priority",
            prompt: "One player calls a discard for a pung, another calls the same tile for mah jongg. Who gets it?",
            choices: ["Whoever spoke first", "The player closest to the discarder's right", "The mah jongg caller", "Nobody, the tile is dead"],
            answerIndex: 2,
            explanation: "Mah jongg always wins the tile. A winning hand outranks any exposure call, no matter who called first or where they sit."
        ),
        QuizQuestion(
            id: "plus-tq-wind-count",
            prompt: "How many East wind tiles are in the set?",
            tiles: [.wind(.east)],
            choices: ["1", "2", "4", "8"],
            answerIndex: 2,
            explanation: "Four of each wind, the same as every other tile. That is worth knowing: if three Easts are already visible, the fourth is the last one alive."
        ),
        QuizQuestion(
            id: "plus-tq-pair-call",
            prompt: "You need one tile to complete a PAIR and it gets discarded. Can you call it?",
            choices: [
                "Yes, any tile you need can be called",
                "No, unless that tile completes your mah jongg",
                "Only if you expose the pair",
                "Only during the Charleston",
            ],
            answerIndex: 1,
            explanation: "Discards can only be called to make a group of 3 or more, or to win. A pair is not an exposure, so the only way to claim a discard for a pair is if it is your winning tile."
        ),
        QuizQuestion(
            id: "plus-tq-dead-hand",
            prompt: "You expose a pung that fits no hand on the card. What happens?",
            choices: [
                "Nothing, you just take it back",
                "You lose a turn",
                "Your hand is dead and you sit out the rest of the round",
                "You swap it for a joker",
            ],
            answerIndex: 2,
            explanation: "Dead hand. Every exposure has to belong to a real hand on the card, so look before you call. You keep discarding but you can no longer win the round."
        ),
    ]

    // MARK: - The Card Room: more racks

    static let extraRackReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "plus-hm-odds",
            tiles: [.c(1), .c(1), .c(3), .c(3), .c(3), .d(5), .d(5), .d(7), .b(9), .b(9), .flower, .flower, .joker],
            choices: [.odds13579, .consecutiveRun, .likeNumbers, .threeSixNine],
            answer: .odds13579,
            explanation: "Every number tile is odd: 1s, 3s, 5s, 7s, 9s, with a pung of 3 Craks already down. Two flowers and a joker go anywhere. This is a 13579 rack."
        ),
        HandMatchQuestion(
            id: "plus-hm-consec",
            tiles: [.c(4), .c(5), .c(6), .c(6), .b(5), .b(6), .b(7), .d(6), .d(7), .d(8), .flower, .joker, .wind(.north)],
            choices: [.consecutiveRun, .threeSixNine, .evens2468, .odds13579],
            answer: .consecutiveRun,
            explanation: "4-5-6, 5-6-7, 6-7-8: three stepped runs, one per suit. The mix of odds and evens kills both 13579 and 2468, and the 4s, 5s, 7s and 8s kill 369."
        ),
        HandMatchQuestion(
            id: "plus-hm-winds",
            tiles: [.wind(.east), .wind(.east), .wind(.east), .wind(.north), .wind(.north), .wind(.west), .wind(.south), .wind(.south), .dragon(.red), .dragon(.red), .dragon(.green), .flower, .joker],
            choices: [.windsDragons, .singlesAndPairs, .likeNumbers, .year],
            answer: .windsDragons,
            explanation: "Eight winds, a pung of Easts, and three dragons, with not one number tile on the rack. Nothing else on the card can use this. Winds and Dragons it is."
        ),
        HandMatchQuestion(
            id: "plus-hm-year",
            tiles: [.c(2), .c(2), .dragon(.soap), .dragon(.soap), .b(2), .b(6), .b(6), .d(2), .flower, .flower, .flower, .joker, .c(9)],
            choices: [.year, .evens2468, .likeNumbers, .threeSixNine],
            answer: .year,
            explanation: "The soaps are the tell. Soap stands in for zero, so 2s, Soaps, and 6s spell out the year, and three flowers is exactly the flower load a year hand wants. 2468 is the decoy."
        ),
        HandMatchQuestion(
            id: "plus-hm-quints",
            tiles: [.joker, .joker, .joker, .joker, .c(3), .c(3), .c(3), .b(3), .b(3), .b(3), .flower, .d(9), .wind(.east)],
            choices: [.quints, .likeNumbers, .odds13579, .threeSixNine],
            answer: .quints,
            explanation: "Two pungs of 3s and FOUR jokers. Any Like Numbers would waste them: those jokers turn both pungs into quints, and Quints hands pay far more. Joker-rich racks look up, not sideways."
        ),
        HandMatchQuestion(
            id: "plus-hm-sp",
            tiles: [.c(2), .c(2), .c(4), .c(4), .b(6), .b(6), .b(8), .b(8), .d(2), .d(2), .dragon(.green), .dragon(.green), .wind(.east)],
            choices: [.singlesAndPairs, .evens2468, .consecutiveRun, .quints],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs and zero jokers. 2468 is the obvious read and a fine backup, but a rack that is already ALL pairs is most of a Singles and Pairs hand, which pays the most on the card."
        ),
    ]

    // MARK: - The Charleston Room: more passes

    static let extraPasses: [CharlestonScenario] = [
        CharlestonScenario(
            id: "plus-ch-first-right",
            situation: "First Charleston, pass RIGHT. Your odds are stacking up nicely. Pick 3.",
            deal: [.c(1), .c(1), .c(3), .c(5), .c(5), .b(1), .b(3), .b(5), .d(2), .d(4), .d(8), .flower, .joker],
            recommendedPass: [.d(2), .d(4), .d(8)],
            reasoning: "Eight odd tiles with two pairs already: this hand wants 13579. The three even Dots serve nothing you are building, so they go together on the very first pass, before anyone has committed.",
            tip: "The first pass is the cheapest one you will make. Ship your obvious misfits now, while the table is still blind."
        ),
        CharlestonScenario(
            id: "plus-ch-blind-pass",
            situation: "Second Charleston, pass LEFT. You are all-in on evens. Pick 3.",
            deal: [.b(2), .b(4), .b(6), .b(8), .c(2), .c(4), .c(6), .d(8), .d(3), .wind(.west), .wind(.south), .flower, .joker],
            recommendedPass: [.wind(.west), .wind(.south), .d(3)],
            reasoning: "Seven evens across two suits is a real 2468 spine. The two lonely winds do nothing outside Winds and Dragons, and the 3 Dot is your only odd number tile. Those three leave without a second thought.",
            tip: "In the second Charleston you may pass 1 to 3 tiles you have not looked at (the blind pass) to avoid breaking a hand you like. Only blind-pass tiles you can afford to lose."
        ),
        CharlestonScenario(
            id: "plus-ch-courtesy",
            situation: "Courtesy pass, 3 tiles across. You are locked into 369. Pick 3.",
            deal: [.c(3), .c(3), .c(6), .c(6), .c(6), .b(9), .b(9), .d(3), .d(7), .b(4), .b(5), .flower, .joker],
            recommendedPass: [.b(4), .b(5), .d(7)],
            reasoning: "The courtesy pass is optional and both players must agree on the count. With a pung of 6 Craks and pairs of 3s and 9s you are deep in 369, so the only tiles that do nothing are 4 Bam, 5 Bam, and 7 Dot.",
            tip: "The courtesy pass is a negotiation: you can agree on 0, 1, 2, or 3 tiles. If your hand is set, offer fewer, or none."
        ),
        CharlestonScenario(
            id: "plus-ch-keep-flowers",
            situation: "First Charleston, pass ACROSS. You hold two flowers and they look like spares. Pick 3.",
            deal: [.c(5), .c(5), .c(7), .c(9), .b(5), .b(7), .b(9), .d(1), .d(6), .d(2), .d(4), .flower, .flower],
            recommendedPass: [.d(2), .d(4), .d(6)],
            reasoning: "Seven odd tiles and a pair of 5 Craks: this is a 13579 hand. The even Dots (2, 4, 6) are the passes. Do NOT ship the flowers to make the choice easier. Most sections on the card want flowers, and you cannot get them back once they are gone.",
            tip: "Flowers are the last thing you pass. They fit almost every section, so passing one is passing a tile your own hand probably needs later."
        ),
    ]

    // MARK: - The Table Room: more calls

    static let extraJudgment: [Flashcard] = [
        Flashcard(
            id: "plus-kd-fourth-tile",
            frontTitle: "An opponent has an exposed PUNG of 6 Dots.",
            frontTiles: [.d(6), .d(6), .d(6)],
            frontSubtitle: "You just drew the fourth 6 Dot. Keep or throw?",
            backTitle: "Hold It",
            backBody: "A pung on the rack often wants to become a kong. The fourth copy is the exact tile they are waiting for, and it is worthless to you. Sit on it and throw something the table has already seen.",
            choice: CardChoice("Hold it", "Throw it", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-kd-lone-wind",
            frontTitle: "Turn 3. You hold one North and no other winds.",
            frontTiles: [.wind(.north)],
            frontSubtitle: "Nobody has exposed a wind. Keep or throw?",
            backTitle: "Throw It",
            backBody: "A lone wind only serves Winds and Dragons, a section you are clearly not in. Early, before anyone commits, it is close to a free discard. The same tile late, after someone exposes winds, is a live grenade.",
            choice: CardChoice("Keep it", "Throw it", answerIndex: 1)
        ),
        Flashcard(
            id: "plus-kd-commit",
            frontTitle: "You are 3 tiles from a 2468 hand and 4 from a Consecutive Run.",
            frontTiles: [.c(2), .c(4), .b(6), .b(8)],
            frontSubtitle: "Chase both, or pick one?",
            backTitle: "Commit To The Shorter Road",
            backBody: "Straddling two sections means every draw helps only half your hand and you never get close to either. Count the tiles you still need, commit to the smaller number, and turn the other section's tiles into discards.",
            choice: CardChoice("Commit to 2468", "Keep both alive", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-kd-safe-discard",
            frontTitle: "Late game. You must discard: a spare flower, or a wind already thrown twice?",
            frontTiles: [.flower, .wind(.south)],
            frontSubtitle: "Which is the safer throw?",
            backTitle: "The Twice-Thrown Wind",
            backBody: "A tile the table has already passed on twice is close to proven safe, and only one copy is left anyway. Flowers are the opposite: nearly every section wants them, so a late flower is one of the most dangerous tiles you can put down.",
            choice: CardChoice("The spare flower", "The twice-thrown wind", answerIndex: 1)
        ),
        Flashcard(
            id: "plus-kd-dont-call",
            frontTitle: "Turn 4. Calling this discard gives you a pung for a hand you are only half on.",
            frontTiles: [.b(5), .b(5), .b(5)],
            frontSubtitle: "Your other option: a concealed hand you are 2 tiles from. Call it?",
            backTitle: "Let It Go",
            backBody: "Calling exposes the group for good and locks you out of every concealed hand on the card. Trading a hand you are 2 tiles from for a hand you are half on is a bad trade, no matter how satisfying the call feels.",
            choice: CardChoice("Call it and expose", "Let it go", answerIndex: 1)
        ),
        Flashcard(
            id: "plus-kd-count-tiles",
            frontTitle: "You need a pung of 5 Bams.",
            frontTiles: [.b(5), .b(5)],
            frontSubtitle: "Two are in the discards, one is exposed on a rack. Keep chasing?",
            backTitle: "Switch Hands",
            backBody: "Only four of any tile exist. Three are gone, so exactly one 5 Bam is alive and a pung is now impossible without a joker. Count the dead tiles before you count on a group: the discard pile tells you which hands are already over.",
            choice: CardChoice("Keep chasing the pung", "Switch to a hand that does not need 5 Bams", answerIndex: 1)
        ),
    ]
}
