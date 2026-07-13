import Foundation

/// The Table Room's advanced tier: Charleston judgment calls, defensive play,
/// and expert rack reading for players who already know the sections.
///
/// LEGAL: Every hand below is an ORIGINAL teaching hand built to illustrate a
/// category family. None of them is copied from any real NMJL card (the card is
/// copyrighted, and the reading skills transfer regardless). Winds, dragons, and
/// soaps are used only to teach how sections read at the table.
enum ProContent {

    // MARK: - Advanced Charleston

    static let advancedCharleston: [CharlestonScenario] = [
        CharlestonScenario(
            id: "pro-ch-two-sections",
            situation: "First Charleston, pass RIGHT. Your craks scream odds, your bams start a run. Pick 3.",
            deal: [.c(3), .c(3), .c(5), .c(5), .c(7), .c(9), .b(5), .b(6), .b(7), .d(2), .d(8), .flower, .joker],
            recommendedPass: [.b(6), .d(2), .d(8)],
            reasoning: "Count both roads. The odds side has six tiles with two pairs (3s and 5s); the run side has just three (5-6-7 Bam). Commit to 13579. Keep 5 Bam and 7 Bam since they are odd, and pass the even tiles that fit neither pair: 6 Bam plus the 2 Dot and 8 Dot.",
            tip: "When two sections compete, follow the count. The longer, paired side wins; the shorter side becomes your passes."
        ),
        CharlestonScenario(
            id: "pro-ch-keep-pair",
            situation: "First Charleston, pass RIGHT. You are deep in 2468, but you also hold a spare pair of Red Dragons. Pick 3.",
            deal: [.c(2), .c(4), .c(6), .b(2), .b(4), .b(6), .dragon(.red), .dragon(.red), .d(3), .d(5), .d(7), .flower, .joker],
            recommendedPass: [.d(3), .d(5), .d(7)],
            reasoning: "The three odd Dots (3, 5, 7) fit none of your even plan, so they are clean passes. Do NOT break the Red pair to make an easier bundle. Jokers can never build a pair, so natural pairs are precious, and shipping a pair could hand a neighbor half of a Singles and Pairs hand. Keep the Reds as a Winds and Dragons escape hatch.",
            tip: "Hold natural pairs by default. Jokers cannot make pairs, and a pair you pass can complete an opponent."
        ),
        CharlestonScenario(
            id: "pro-ch-pass-pair",
            situation: "First Charleston, pass RIGHT. Eight even tiles plus a lonely pair of Norths. Pick 3.",
            deal: [.c(2), .c(4), .c(6), .c(8), .b(2), .b(4), .b(6), .b(8), .wind(.north), .wind(.north), .d(5), .flower, .joker],
            recommendedPass: [.wind(.north), .wind(.north), .d(5)],
            reasoning: "Usually you protect pairs, but this one earns an exception. Eight evens lock you into 2468, and a pair of Norths serves only Winds and Dragons, a section you are clearly not playing. It is the very first pass, so opponents have not committed yet and the feed risk is low. Ship both Norths and the odd 5 Dot.",
            tip: "Hold pairs by default, but a pair that fits none of your target section is fair to pass early, before opponents lock in."
        ),
        CharlestonScenario(
            id: "pro-ch-369-vs-run",
            situation: "First Charleston, pass ACROSS. Your hand reads as both 369 and Consecutive Run. Pick 3.",
            deal: [.c(3), .c(6), .c(9), .b(3), .b(6), .b(9), .d(6), .d(6), .b(4), .b(5), .c(2), .flower, .joker],
            recommendedPass: [.b(4), .b(5), .c(2)],
            reasoning: "369 and Run overlap because 3, 6, and 9 live in both. So count the pure tiles. Eight of your number tiles are 3s, 6s, or 9s, including a 6 Dot pair; only 4 Bam and 5 Bam are run-only. Commit to 369, keep the 6 Dot pair, and pass the two run-only bams plus the stray 2 Crak.",
            tip: "When 369 and Run overlap, count the tiles that fit ONLY one of them. Commit to whichever has more locked in."
        ),
        CharlestonScenario(
            id: "pro-ch-second-stop",
            situation: "Second Charleston, pass LEFT. Your hand is nearly built with seven 6s. You would rather stop, but the table voted to continue. Pick 3.",
            deal: [.c(6), .c(6), .b(6), .b(6), .b(6), .d(6), .d(6), .c(9), .d(3), .flower, .flower, .wind(.north), .joker],
            recommendedPass: [.c(9), .d(3), .wind(.north)],
            reasoning: "Seven 6s means Any Like Numbers is almost done, and this is exactly the hand you want to STOP the second Charleston with: extra passing helps the weak hands more than yours. Since it is proceeding, part with the tiles that do nothing for sixes: the lone 9 Crak, 3 Dot, and North. Keep both flowers; they slot into most hands.",
            tip: "When your hand is ahead after round one, vote to stop the second Charleston. More passing bails out your opponents."
        ),
        CharlestonScenario(
            id: "pro-ch-defend-late",
            situation: "Last pass of the Charleston, going LEFT. Your left neighbor has already passed you three winds this round, so they clearly are not on Winds and Dragons. Pick 3.",
            deal: [.c(4), .c(5), .c(6), .b(5), .b(6), .b(7), .d(6), .d(6), .b(2), .d(9), .wind(.east), .flower, .joker],
            recommendedPass: [.b(2), .d(9), .wind(.east)],
            reasoning: "Your run is set (4-5-6 and 5-6-7 with a 6 Dot pair), so any three strays go. But your LAST pass is also defense. Your left neighbor keeps dumping winds, so an East going back to them is the safest tile you own: it cannot be in a section they already rejected. Pair it with the two other strays, 2 Bam and 9 Dot.",
            tip: "Your final pass is a defensive tool. Feed a neighbor the kind of tile they have already shown they do not want."
        ),
    ]

    // MARK: - Defensive play quiz

    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "pro-def-read-like",
            prompt: "An opponent exposes a pung of 6 Bams AND a pung of 6 Craks. What are they most likely building?",
            tiles: [.b(6), .b(6), .b(6), .c(6), .c(6), .c(6)],
            choices: ["Any Like Numbers", "2468 (Evens)", "Winds & Dragons"],
            answerIndex: 0,
            explanation: "The same number in two different suits is the fingerprint of Any Like Numbers. A 2468 hand usually keeps one suit per number, so two suits of 6 points at Like Numbers. Stop feeding them any 6."
        ),
        QuizQuestion(
            id: "pro-def-read-369",
            prompt: "An opponent exposes a pung of 3 Dots and a pung of 9 Dots. Which section is that?",
            tiles: [.d(3), .d(3), .d(3), .d(9), .d(9), .d(9)],
            choices: ["Consecutive Run", "369", "Quints"],
            answerIndex: 1,
            explanation: "3 and 9 sit too far apart to belong to one run, so Consecutive Run is out. Threes and nines together are a 369 tell. Treat 3s, 6s, and 9s as hot tiles against this player."
        ),
        QuizQuestion(
            id: "pro-def-count-copies",
            prompt: "You need the last North for your pung. Two Norths sit in the discards and one is exposed on a rack. How many can still reach you?",
            tiles: [.wind(.north), .wind(.north), .wind(.north)],
            choices: ["Two", "One at most", "Three", "None, it is truly impossible"],
            answerIndex: 1,
            explanation: "Only four of any tile exist. Three Norths are already visible, so at most one is left, and it could be buried in the wall or stuck in a hand. Treat the pung as fragile and start lining up a backup."
        ),
        QuizQuestion(
            id: "pro-def-quints-dead",
            prompt: "You are chasing a quint (five of a kind) of 5 Dots using jokers. Three 5 Dots are already visible around the table. Keep pushing?",
            tiles: [.d(5), .d(5), .d(5)],
            choices: ["Yes, jokers will cover it", "No, it is effectively dead", "Only if you draw two more jokers first"],
            answerIndex: 1,
            explanation: "A quint needs five tiles, and only four 5 Dots exist. With three gone, you would have to build almost the whole group from jokers. That is a fantasy, not a plan. Count the naturals before you chase any quint, and fold this one."
        ),
        QuizQuestion(
            id: "pro-def-safe-discard",
            prompt: "One opponent is clearly on Winds & Dragons: every exposure is winds and dragons. Which discard is safest against them?",
            tiles: [.wind(.north), .wind(.north), .wind(.north), .dragon(.red), .dragon(.red), .dragon(.red)],
            choices: ["A 5 Bam", "North wind", "Red dragon", "Soap"],
            answerIndex: 0,
            explanation: "Their hand is built from winds and dragons, so a plain number tile cannot help them win. The 5 Bam is safe. Hold your winds, dragons, and soaps, and feed them harmless numbers."
        ),
        QuizQuestion(
            id: "pro-def-hot-tile",
            prompt: "An opponent has exposed a pung of 6 Bams and a pung of 8 Bams and is waiting for a tile. Which discard is most dangerous?",
            tiles: [.b(6), .b(6), .b(6), .b(8), .b(8), .b(8)],
            choices: ["7 Bam", "2 Crak", "North", "Soap"],
            answerIndex: 0,
            explanation: "Pungs of 6 and 8 Bam scream a 6-7-8 run in bams. The 7 Bam is the bridge they are missing, likely their winning tile. Hold it and throw something unrelated."
        ),
        QuizQuestion(
            id: "pro-def-break-hand",
            prompt: "Your hand is hopeless, and an opponent is one tile away from mah jongg on an obvious hand. What is the right play?",
            tiles: [],
            choices: ["Draw and hope your own hand comes together", "Switch to defense: discard only tiles they cannot use, even if it breaks your hand", "Discard fast to end the game sooner"],
            answerIndex: 1,
            explanation: "If you cannot win, your job is to not deal the winning tile. Break your own hand and throw tiles their exposures prove are safe. A blocked win is a good outcome when yours is dead."
        ),
        QuizQuestion(
            id: "pro-def-joker-swap",
            prompt: "An opponent has an exposed pung of 3 Craks made with two real tiles and one joker. You hold a real 3 Crak. On your turn you may:",
            tiles: [.c(3), .c(3), .joker],
            choices: ["Call the joker off the discard pile", "Swap your real 3 Crak for the joker and take the joker into your hand", "Nothing, exposed jokers are frozen"],
            answerIndex: 1,
            explanation: "This is the joker exchange. On your turn, before you discard, you may redeem an exposed joker by giving the matching natural tile, and the joker comes into your hand. A free joker is a huge tempo swing, so watch for these."
        ),
        QuizQuestion(
            id: "pro-def-track-jokers",
            prompt: "Why bother tracking the jokers sitting in opponents' exposures?",
            tiles: [],
            choices: ["Any player can redeem them with the matching tile, so plan to grab them", "They score bonus points at the end", "They stop you from using your own jokers"],
            answerIndex: 0,
            explanation: "Exposed jokers are up for grabs. A single spare natural tile can pull one into your hand on your turn. Knowing which jokers are live tells you when a swap is waiting for you."
        ),
        QuizQuestion(
            id: "pro-def-dead-joker",
            prompt: "An opponent discards a joker. Can you claim it to help your hand?",
            tiles: [.joker],
            choices: ["Yes, call it for a pung", "Yes, but only to make an exposure", "No, a discarded joker is dead and cannot be called"],
            answerIndex: 2,
            explanation: "Once a joker hits the discards it is dead. No one can call it or pick it up; it just sits there as a thrown tile. Jokers only come from the wall or from swapping an exposed one."
        ),
    ]

    // MARK: - Expert rack reading

    static let expertRackReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "pro-rack-1",
            tiles: [.c(4), .c(5), .c(6), .b(6), .b(7), .b(8), .d(3), .d(6), .d(9), .d(9), .b(9), .flower, .joker],
            choices: [.consecutiveRun, .threeSixNine, .evens2468],
            answer: .consecutiveRun,
            explanation: "369 is the decoy: you have 3s, 6s, and 9s scattered around. But 4 Crak, 5 Crak, 7 Bam, and 8 Bam are dead weight for 369, while they finish 4-5-6 and 6-7-8 runs in two suits. Stepping numbers in every suit make this Consecutive Run."
        ),
        HandMatchQuestion(
            id: "pro-rack-2",
            tiles: [.c(3), .c(3), .c(6), .c(6), .d(9), .d(9), .b(3), .b(6), .b(9), .b(4), .b(5), .flower, .joker],
            choices: [.threeSixNine, .consecutiveRun, .likeNumbers],
            answer: .threeSixNine,
            explanation: "Consecutive Run is the decoy, tempted by the 3-4-5-6 in bams. But 4 Bam and 5 Bam are the only run-only tiles here. Everything else is a 3, 6, or 9, including three pairs. Count the pure tiles and this is 369."
        ),
        HandMatchQuestion(
            id: "pro-rack-3",
            tiles: [.c(2), .c(2), .c(4), .c(8), .b(6), .b(6), .b(8), .b(4), .d(2), .d(4), .d(8), .flower, .joker],
            choices: [.evens2468, .year, .likeNumbers],
            answer: .evens2468,
            explanation: "Year is the decoy because of the 2s, 6s, and flowers. But a year hand needs soaps as its zeros, and there are none. With 4s and 8s in the mix, tiles a year hand never uses, this is a straight 2468."
        ),
        HandMatchQuestion(
            id: "pro-rack-4",
            tiles: [.c(2), .c(2), .b(2), .b(2), .dragon(.soap), .dragon(.soap), .d(6), .d(6), .b(6), .flower, .flower, .flower, .joker],
            choices: [.year, .evens2468, .windsDragons],
            answer: .year,
            explanation: "2468 is the decoy since 2s and 6s are even. But the soaps are the giveaway: they stand in for the zeros in 2, 0, 2, 6. With no 4s or 8s and a fistful of flowers, this is a Year hand."
        ),
        HandMatchQuestion(
            id: "pro-rack-5",
            tiles: [.c(1), .c(1), .c(3), .c(3), .b(5), .b(5), .b(5), .d(7), .d(9), .d(9), .b(1), .flower, .joker],
            choices: [.odds13579, .singlesAndPairs, .consecutiveRun],
            answer: .odds13579,
            explanation: "Singles and Pairs is the decoy, since you have several pairs. But that section allows only singles and pairs and no jokers, and this rack has a pung of 5 Bams plus a joker. Both break the S and P rules, so read it as 13579."
        ),
        HandMatchQuestion(
            id: "pro-rack-6",
            tiles: [.c(1), .c(1), .b(2), .b(2), .d(3), .d(3), .c(4), .c(4), .b(5), .b(5), .d(6), .d(6), .wind(.north)],
            choices: [.singlesAndPairs, .odds13579, .evens2468],
            answer: .singlesAndPairs,
            explanation: "13579 is the decoy off the 1s, 3s, and 5s, but the 2, 4, and 6 pairs kill any odd-only hand. Six natural pairs across mixed numbers with zero jokers is the textbook Singles and Pairs shape. The lone North is your first pass."
        ),
        HandMatchQuestion(
            id: "pro-rack-7",
            tiles: [.c(7), .c(7), .b(7), .b(7), .b(7), .d(7), .d(7), .d(7), .c(2), .b(9), .d(9), .flower, .joker],
            choices: [.likeNumbers, .quints, .consecutiveRun],
            answer: .likeNumbers,
            explanation: "Quints is the decoy, dreaming of five 7s in a suit. But a quint needs heavy joker support, and you hold just one joker. Eight 7s spread across all three suits is a straight shot at Any Like Numbers instead."
        ),
        HandMatchQuestion(
            id: "pro-rack-8",
            tiles: [.dragon(.soap), .dragon(.soap), .dragon(.red), .dragon(.red), .dragon(.green), .dragon(.green), .wind(.north), .wind(.north), .wind(.east), .c(2), .d(2), .flower, .joker],
            choices: [.windsDragons, .year, .singlesAndPairs],
            answer: .windsDragons,
            explanation: "Year is the decoy: the soaps and 2s hint at 2, 0, 2, 6. But year hands use no winds, and you are holding three of them alongside all three dragons. Three dragon pairs plus winds is Winds and Dragons."
        ),
    ]
}
