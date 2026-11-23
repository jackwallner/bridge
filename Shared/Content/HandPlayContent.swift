import Foundation

/// The authored deals for Play a Hand. South declares every one. Each trick
/// is listed from its leader clockwise; `HandPlayEngineTests` checks that the
/// line is legal, complete, makes the contract, and that South's coached
/// calls agree with `HandGenerator` and `BiddingEngine`.
enum HandPlayContent {
    static let deals: [HandPlayDeal] = [holdUp, drawTrumps, ruffFirst, finesse]

    static func deal(id: String) -> HandPlayDeal? {
        deals.first { $0.id == id }
    }

    // MARK: - 3NT: hold up the ace

    static let holdUp = HandPlayDeal(
        id: "handplay-hold-up",
        title: "Hold Up the Ace",
        north: "♠852 ♥642 ♦AK3 ♣KQJT",
        east: "♠93 ♥JT98 ♦J76 ♣A872",
        south: "♠A74 ♥AKQ3 ♦Q52 ♣943",
        west: "♠KQJT6 ♥75 ♦T984 ♣65",
        calls: ["1NT", "P", "3NT", "P", "P", "P"],
        coachedCalls: [0: .opening],
        tricks: [
            "♠K ♠2 ♠9 ♠4",
            "♠Q ♠5 ♠3 ♠7",
            "♠J ♠8 ♦6 ♠A",
            "♣3 ♣5 ♣K ♣A",
            "♥J ♥K ♥5 ♥2",
            "♣4 ♣6 ♣Q ♣2",
            "♣J ♣7 ♣9 ♦4",
            "♣T ♣8 ♦2 ♦8",
            "♦3 ♦7 ♦Q ♦9",
            "♦5 ♦T ♦A ♦J",
            "♦K ♥8 ♥3 ♥7",
            "♥4 ♥9 ♥A ♠6",
            "♥Q ♠T ♥6 ♥T",
        ],
        decisions: [
            PlayDecision(
                trick: 0,
                reason: "Duck. You can afford to lose two spades and the A♣ and still take ten tricks, and every spade you let go is one fewer the defenders can lead back later.",
                cardNotes: ["♠A": "Win now and a defender who gets in with the A♣ may still have a spade to lead to partner's winners."]
            ),
            PlayDecision(
                trick: 1,
                reason: "Duck again. A second duck still costs nothing, and it leaves East with no spade if East started with two.",
                cardNotes: ["♠A": "Win now and East may still hold a spade to lead back after taking the A♣."]
            ),
            PlayDecision(
                trick: 3,
                reason: "Lead a club. Knocking out the A♣ turns dummy's clubs into three tricks while you still hold every other suit.",
                suitNotes: [
                    .hearts: "Cashing hearts wins nothing extra and can set up the defenders' long hearts. The tricks you need are in clubs.",
                    .diamonds: "Cashing diamonds wins nothing extra and can set up the defenders' long diamonds. The tricks you need are in clubs.",
                ]
            ),
        ]
    )

    // MARK: - 4♠: draw trumps

    static let drawTrumps = HandPlayDeal(
        id: "handplay-draw-trumps",
        title: "Draw Trumps First",
        north: "♠J87 ♥A9654 ♦843 ♣Q6",
        east: "♠95 ♥T7 ♦976 ♣K97543",
        south: "♠AKQ64 ♥KQ3 ♦A52 ♣J2",
        west: "♠T32 ♥J82 ♦KQJT ♣AT8",
        calls: ["1S", "P", "2S", "P", "4S", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.spades))],
        tricks: [
            "♦K ♦3 ♦6 ♦A",
            "♠A ♠2 ♠7 ♠5",
            "♠K ♠3 ♠8 ♠9",
            "♠Q ♠T ♠J ♣3",
            "♥K ♥2 ♥4 ♥7",
            "♥Q ♥8 ♥5 ♥T",
            "♥3 ♥J ♥A ♣4",
            "♥9 ♣5 ♦2 ♦T",
            "♥6 ♣7 ♦5 ♦J",
            "♦8 ♦7 ♠4 ♦Q",
            "♠6 ♣8 ♦4 ♦9",
            "♣2 ♣A ♣6 ♣9",
            "♣T ♣Q ♣K ♣J",
        ],
        decisions: [
            PlayDecision(
                trick: 0,
                reason: "Win the A♦. Your diamond losers can go away later on dummy's long hearts, so ducking only gives the defenders a trick."
            ),
            PlayDecision(
                trick: 1,
                reason: "Draw trumps. Once the defenders have none, your hearts and dummy's long hearts are safe from a ruff.",
                cardNotes: [
                    "♠6": "Lead from the top. The A♠, K and Q draw trumps without letting a defender's 10♠ or 9 win a trick.",
                    "♠4": "Lead from the top. The A♠, K and Q draw trumps without letting a defender's 10♠ or 9 win a trick.",
                ],
                suitNotes: [
                    .hearts: "Hearts before trumps lets a defender with two hearts ruff the third round. Draw trumps first.",
                    .diamonds: "Your diamond and club losers can wait for dummy's hearts. Draw trumps first so the hearts are safe.",
                    .clubs: "Your diamond and club losers can wait for dummy's hearts. Draw trumps first so the hearts are safe.",
                ]
            ),
            PlayDecision(
                trick: 2,
                reason: "Keep drawing trumps until the defenders have none.",
                cardNotes: [
                    "♠6": "Lead from the top. The A♠, K and Q draw trumps without letting a defender's 10♠ or 9 win a trick.",
                    "♠4": "Lead from the top. The A♠, K and Q draw trumps without letting a defender's 10♠ or 9 win a trick.",
                ],
                suitNotes: [
                    .hearts: "The defenders still hold trumps, and one of them can ruff a heart. Draw trumps first.",
                    .diamonds: "Your diamond and club losers can wait for dummy's hearts. Draw trumps first so the hearts are safe.",
                    .clubs: "Your diamond and club losers can wait for dummy's hearts. Draw trumps first so the hearts are safe.",
                ]
            ),
            PlayDecision(
                trick: 3,
                reason: "West still holds the 10♠. Draw it before you run the hearts.",
                cardNotes: [
                    "♠6": "Lead the Q♠. A low spade lets West's 10♠ win a trick it never had to.",
                    "♠4": "Lead the Q♠. A low spade lets West's 10♠ win a trick it never had to.",
                ],
                suitNotes: [
                    .hearts: "West's last trump would ruff dummy's long hearts. Draw it first.",
                    .diamonds: "West's last trump would ruff dummy's long hearts. Draw it first.",
                    .clubs: "West's last trump would ruff dummy's long hearts. Draw it first.",
                ]
            ),
        ]
    )

    // MARK: - 4♥: ruff before you draw trumps

    static let ruffFirst = HandPlayDeal(
        id: "handplay-ruff-first",
        title: "Ruff Before Trumps",
        north: "♠73 ♥Q94 ♦8654 ♣A964",
        east: "♠K985 ♥T32 ♦Q2 ♣T753",
        south: "♠A64 ♥AKJ75 ♦AK3 ♣82",
        west: "♠QJT2 ♥86 ♦JT97 ♣KQJ",
        calls: ["1H", "P", "2H", "P", "4H", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.hearts))],
        tricks: [
            "♥8 ♥4 ♥T ♥J",
            "♠A ♠2 ♠3 ♠5",
            "♠4 ♠T ♠7 ♠8",
            "♥6 ♥9 ♥3 ♥5",
            "♦4 ♦2 ♦A ♦7",
            "♠6 ♠J ♥Q ♠9",
            "♦5 ♦Q ♦K ♦9",
            "♥A ♠Q ♣4 ♥2",
            "♥K ♣J ♣6 ♣3",
            "♥7 ♦T ♦6 ♣5",
            "♣2 ♣Q ♣A ♣7",
            "♦8 ♣T ♦3 ♦J",
            "♣K ♣9 ♠K ♣8",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Play the A♠ and then another spade. You have one spade too many, and dummy's trumps are what will ruff it.",
                cardNotes: ["♦3": "The 3♦ gives the defenders a diamond trick and the lead, and they will lead trumps. Start the spades."],
                suitNotes: [
                    .hearts: "Each round of trumps takes one from dummy, and the defenders will lead more when they get in. Start the spades before you touch trumps.",
                ],
                alsoFine: ["♠6", "♠4", "♦A", "♦K", "♣8", "♣2"]
            ),
            PlayDecision(
                trick: 2,
                reason: "Give up a spade now. Dummy is out of spades, so the next one can be ruffed.",
                cardNotes: ["♦3": "The 3♦ gives up a diamond trick you do not have to lose. Give up the spade instead."],
                suitNotes: [
                    .hearts: "Each round of trumps takes one from dummy, and the defenders will lead more when they get in. Give up the spade first.",
                ],
                alsoFine: ["♦A", "♦K", "♣8", "♣2"]
            ),
            PlayDecision(
                trick: 5,
                reason: "Lead your last spade and ruff it in dummy. That ruff is the tenth trick.",
                suitNotes: [
                    .hearts: "Dummy's last trump is the Q♥, and a round of trumps now would take it. Ruff the spade first.",
                    .diamonds: "Ruff the spade while dummy still has the Q♥. That ruff is the tenth trick.",
                    .clubs: "Ruff the spade while dummy still has the Q♥. That ruff is the tenth trick.",
                ],
                alsoFine: ["♦K"]
            ),
            PlayDecision(
                trick: 5,
                seat: .north,
                reason: "Ruff with the Q♥. That ruff is the trick the whole plan was built for.",
                suitNotes: [
                    .diamonds: "A discard throws away the extra trick. Ruff with the Q♥.",
                    .clubs: "A discard throws away the extra trick. Ruff with the Q♥.",
                ]
            ),
        ]
    )

    // MARK: - 2♠: the finesse

    static let finesse = HandPlayDeal(
        id: "handplay-finesse",
        title: "Take the Finesse",
        north: "♠962 ♥754 ♦AK53 ♣874",
        east: "♠A8 ♥KT98 ♦74 ♣QT632",
        south: "♠KQJ74 ♥AQ3 ♦862 ♣J5",
        west: "♠T53 ♥J62 ♦QJT9 ♣AK9",
        calls: ["1S", "P", "2S", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.spades))],
        tricks: [
            "♣A ♣4 ♣3 ♣5",
            "♣K ♣7 ♣2 ♣J",
            "♣9 ♣8 ♣T ♠4",
            "♠K ♠3 ♠2 ♠A",
            "♦7 ♦2 ♦9 ♦K",
            "♥4 ♥8 ♥Q ♥2",
            "♠Q ♠5 ♠6 ♠8",
            "♠J ♠T ♠9 ♥9",
            "♥A ♥6 ♥5 ♥T",
            "♦6 ♦T ♦A ♦4",
            "♦3 ♣6 ♦8 ♦J",
            "♦Q ♦5 ♣Q ♠7",
            "♥3 ♥J ♥7 ♥K",
        ],
        decisions: [
            PlayDecision(
                trick: 3,
                reason: "Lead the K♠. Your K-Q-J knock out the ace and draw the defenders' trumps.",
                cardNotes: [
                    "♠7": "Lead the K♠. A low spade can lose to a defender's 10 or 8 for nothing.",
                ],
                suitNotes: [
                    .hearts: "Lead hearts from dummy, toward your A-Q, so East has to play before you.",
                ],
                alsoFine: ["♦8", "♦6", "♦2"]
            ),
            PlayDecision(
                trick: 5,
                seat: .north,
                reason: "Lead a heart from dummy toward your A-Q. If East holds the K♥, the Q♥ wins.",
                suitNotes: [
                    .diamonds: "The A♦ is dummy's last way in. Use this lead for the heart finesse.",
                ],
                alsoFine: ["♠9", "♠6"]
            ),
            PlayDecision(
                trick: 5,
                reason: "Play the Q♥. East played before you, so the queen wins whenever East holds the king.",
                cardNotes: [
                    "♥A": "The A♥ wins now, but East's K♥ then beats your Q♥ later. The queen wins two heart tricks whenever East holds the king.",
                    "♥3": "Ducking gives up a heart trick for nothing. Try the Q♥: it wins whenever East holds the king.",
                ]
            ),
        ]
    )
}
