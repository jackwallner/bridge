import Foundation

/// The authored deals for Play a Hand. South declares every one. Each trick
/// is listed from its leader clockwise; `HandPlayEngineTests` checks that the
/// line is legal, complete, makes the contract, and that South's coached
/// calls agree with `HandGenerator` and `BiddingEngine`.
enum HandPlayContent {
    /// Rotation order. New deals go at the end: `HandPlayStore` keeps the
    /// player's place by index.
    static let deals: [HandPlayDeal] = [
        holdUp, drawTrumps, ruffFirst, finesse,
        leadToward, unblock, discardFirst, duckARound,
        playForTheDrop, finesseTwice, ruffHigh, nineTricks,
    ]

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

    // MARK: - 2♥: lead toward the king

    static let leadToward = HandPlayDeal(
        id: "handplay-lead-toward",
        title: "Lead Toward the King",
        north: "♠Q963 ♥K4 ♦853 ♣8752",
        east: "♠KJ2 ♥763 ♦QJT9 ♣AJ9",
        south: "♠A84 ♥AQT952 ♦74 ♣K6",
        west: "♠T75 ♥J8 ♦AK62 ♣QT43",
        calls: ["1H", "P", "1S", "P", "2H", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterOneSpade)],
        tricks: [
            "♦A ♦3 ♦Q ♦4",
            "♦K ♦5 ♦9 ♦7",
            "♦6 ♦8 ♦T ♥5",
            "♥2 ♥8 ♥K ♥3",
            "♣2 ♣9 ♣K ♣3",
            "♥A ♥J ♥4 ♥6",
            "♥Q ♣4 ♣5 ♥7",
            "♥T ♦2 ♣7 ♦J",
            "♥9 ♣T ♣8 ♣J",
            "♠A ♠5 ♠3 ♠2",
            "♠4 ♠7 ♠Q ♠K",
            "♠J ♠8 ♠T ♠9",
            "♣A ♣6 ♣Q ♠6",
        ],
        decisions: [
            PlayDecision(
                trick: 3,
                reason: "Lead a trump to dummy's K♥. It is dummy's only way in, and you want the next club led from dummy.",
                cardNotes: [
                    "♣K": "Lead the K♣ and whoever holds the A♣ takes it. Lead toward the king from dummy instead: if East holds the ace, the king scores.",
                    "♣6": "A low club from your hand gives up a trick and leaves the K♣ open to the ace. Lead toward it from dummy instead.",
                ],
                suitNotes: [
                    .spades: "A low spade gives the defenders the lead for nothing. Get to dummy with the K♥ and lead a club from there.",
                ],
                alsoFine: ["♥A", "♥Q", "♥T", "♥9", "♠A"]
            ),
            PlayDecision(
                trick: 4,
                seat: .north,
                reason: "Lead a club toward your K♣. If East holds the A♣, the king wins when East plays low, and it becomes a winner if East takes the ace.",
                suitNotes: [
                    .spades: "The club lead toward your K♣ is the reason you came to dummy. Lead it now.",
                    .hearts: "Dummy's last trump takes you back to your hand, and dummy has no other way in. Lead the club now.",
                ]
            ),
            PlayDecision(
                trick: 4,
                reason: "Play the K♣. East has already played low, so the king wins unless West holds the ace.",
                cardNotes: [
                    "♣6": "Ducking wastes the lead from dummy. Play the K♣ now: it wins whenever East holds the ace.",
                ]
            ),
        ]
    )

    // MARK: - 3NT: unblock the suit

    static let unblock = HandPlayDeal(
        id: "handplay-unblock",
        title: "Unblock the Suit",
        north: "♠QJ4 ♥652 ♦AQJ52 ♣Q3",
        east: "♠32 ♥JT93 ♦764 ♣AT85",
        south: "♠A95 ♥AK4 ♦K3 ♣J9742",
        west: "♠KT876 ♥Q87 ♦T98 ♣K6",
        calls: ["1NT", "P", "3NT", "P", "P", "P"],
        coachedCalls: [0: .opening],
        tricks: [
            "♠7 ♠J ♠2 ♠5",
            "♦2 ♦4 ♦K ♦8",
            "♦3 ♦9 ♦A ♦6",
            "♦Q ♦7 ♣2 ♦T",
            "♦J ♣5 ♣4 ♠6",
            "♦5 ♥3 ♣7 ♠8",
            "♥2 ♥9 ♥A ♥7",
            "♥K ♥8 ♥5 ♥T",
            "♠A ♠T ♠4 ♠3",
            "♥4 ♥Q ♥6 ♥J",
            "♠K ♠Q ♣8 ♠9",
            "♣6 ♣3 ♣A ♣9",
            "♣T ♣J ♣K ♣Q",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                seat: .north,
                reason: "Lead low to your K♦ first. Play the high card from the short hand first, so the last diamonds are left in the long hand.",
                cardNotes: [
                    "♦A": "Cash the A♦ first and your K♦ is left alone in your hand. It wins the second round, and dummy has no way back in for the rest.",
                    "♦Q": "The Q♦ from dummy leaves your K♦ in the way, and you would have to overtake to unblock it. Lead low to the king first.",
                ],
                suitNotes: [
                    .spades: "A spade gives West a trick and a head start on the spades. Start the diamonds.",
                    .clubs: "A club gives the defenders the lead for nothing. Start the diamonds, high card from the short hand first.",
                ],
                alsoFine: ["♦5", "♥6", "♥5", "♥2"]
            ),
            PlayDecision(
                trick: 2,
                reason: "Now lead the 3♦ to dummy. With your king out of the way, the rest of the diamonds run from dummy.",
                cardNotes: [
                    "♠9": "The 9♠ gives West a cheap spade trick and the lead. Get to dummy with the 3♦.",
                    "♥4": "The 4♥ hands the defenders the lead for nothing. Get to dummy with the 3♦.",
                ],
                suitNotes: [
                    .clubs: "A club gives the defenders the lead, and they have spades to set up. Get to dummy with the 3♦ and run the diamonds.",
                ],
                alsoFine: ["♠A", "♥A", "♥K"]
            ),
            PlayDecision(
                trick: 3,
                reason: "Discard a club. Your A♠, A♥ and K♥ are three of your nine tricks, so keep them.",
                suitNotes: [
                    .spades: "Your A♠ is one of your nine tricks. Throw a club instead.",
                    .hearts: "Your A♥ and K♥ are two of your nine tricks. Throw a club instead.",
                ],
                alsoFine: ["♠9", "♥4"]
            ),
        ]
    )

    // MARK: - 4♥: discard before trumps

    static let discardFirst = HandPlayDeal(
        id: "handplay-discard-first",
        title: "Discard Before Trumps",
        north: "♠765 ♥852 ♦AKQ4 ♣753",
        east: "♠432 ♥A74 ♦7652 ♣AQ8",
        south: "♠AKQ ♥KQJT9 ♦3 ♣J642",
        west: "♠JT98 ♥63 ♦JT98 ♣KT9",
        calls: ["1H", "P", "2H", "P", "3H", "P", "4H", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.hearts))],
        tricks: [
            "♠J ♠5 ♠2 ♠A",
            "♦3 ♦8 ♦A ♦2",
            "♦K ♦5 ♣2 ♦9",
            "♦Q ♦6 ♣4 ♦T",
            "♥2 ♥A ♥9 ♥3",
            "♣A ♣6 ♣9 ♣3",
            "♣8 ♣J ♣K ♣5",
            "♣T ♣7 ♣Q ♥T",
            "♥Q ♥6 ♥5 ♥7",
            "♥J ♦J ♥8 ♥4",
            "♥K ♠8 ♦4 ♦7",
            "♠K ♠9 ♠6 ♠3",
            "♠Q ♠T ♠7 ♠4",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Cross to dummy with the 3♦. Before you touch trumps, use dummy's diamonds to discard your club losers.",
                suitNotes: [
                    .hearts: "A trump now lets the defenders win the A♥ and take three clubs. Get rid of your club losers on dummy's diamonds first.",
                    .clubs: "Leading clubs yourself only hands the defenders their club tricks. Discard your losers on dummy's diamonds first.",
                ],
                alsoFine: ["♠K", "♠Q"]
            ),
            PlayDecision(
                trick: 2,
                seat: .north,
                reason: "Cash the K♦ and discard a club. Each club you throw away now is one the defenders cannot take later.",
                cardNotes: [
                    "♦4": "The 4♦ is not a winner. Cash the K♦ and Q♦ to throw your clubs.",
                ],
                suitNotes: [
                    .hearts: "A trump now lets the defenders win the A♥ and cash their clubs. Take your discards first.",
                    .spades: "Going back to your hand leaves dummy's K♦ and Q♦ stranded, because dummy has no other way in. Cash them now.",
                    .clubs: "A club hands the defenders their club tricks. Cash the K♦ and Q♦ first.",
                ]
            ),
            PlayDecision(
                trick: 2,
                reason: "Throw a club. Your spades and hearts are all winners, and each club you discard is a loser gone.",
                suitNotes: [
                    .spades: "Your spades are winners. Throw a club, a loser, instead.",
                    .hearts: "Ruffing dummy's winner wastes a trump and keeps your club loser. Throw a club instead.",
                ]
            ),
        ]
    )

    // MARK: - 1NT: duck a round

    static let duckARound = HandPlayDeal(
        id: "handplay-duck",
        title: "Duck a Round",
        north: "♠976 ♥T84 ♦AK654 ♣93",
        east: "♠32 ♥KJ632 ♦J97 ♣AQT",
        south: "♠AK4 ♥AQ5 ♦32 ♣K8742",
        west: "♠QJT85 ♥97 ♦QT8 ♣J65",
        calls: ["1NT", "P", "P", "P"],
        coachedCalls: [0: .opening],
        tricks: [
            "♠Q ♠6 ♠2 ♠A",
            "♦2 ♦8 ♦4 ♦9",
            "♠3 ♠K ♠5 ♠7",
            "♦3 ♦T ♦A ♦7",
            "♦K ♦J ♣2 ♦Q",
            "♦6 ♥2 ♣4 ♠8",
            "♦5 ♥3 ♣7 ♣5",
            "♥4 ♥6 ♥A ♥7",
            "♥Q ♥9 ♥8 ♥K",
            "♥J ♥5 ♣6 ♥T",
            "♣A ♣8 ♣J ♣3",
            "♣Q ♣K ♠T ♣9",
            "♠4 ♠J ♠9 ♣T",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Lead a diamond now, while you still hold two. Dummy has no way in outside diamonds, so your diamonds are the only route there.",
                cardNotes: [
                    "♠K": "Keep the K♠ to stop West's spades. Start the diamonds.",
                    "♠4": "The 4♠ hands West the lead to keep pushing spades. Start the diamonds.",
                ],
                suitNotes: [
                    .hearts: "A heart gives up the lead for nothing. Start the diamonds while you hold two.",
                    .clubs: "A club gives up the lead for nothing. Start the diamonds while you hold two.",
                ],
                alsoFine: ["♥A"]
            ),
            PlayDecision(
                trick: 1,
                seat: .north,
                reason: "Duck. Let the defenders win this diamond. Your last diamond takes you back to dummy later, and then the A♦ and K♦ clear the suit.",
                cardNotes: [
                    "♦A": "Win now and the third round goes to the defenders, leaving dummy with two winners it has no way to reach.",
                    "♦K": "Win now and the third round goes to the defenders, leaving dummy with two winners it has no way to reach.",
                ]
            ),
            PlayDecision(
                trick: 3,
                reason: "Lead your last diamond to dummy. Then cash the A♦ and K♦: once the defenders' diamonds are gone, dummy's last two are winners too.",
                cardNotes: [
                    "♠4": "The 4♠ gives West the lead and the spades. Get to dummy with your last diamond.",
                ],
                suitNotes: [
                    .hearts: "A heart gives up the lead for nothing. Get to dummy with your last diamond.",
                    .clubs: "A club gives up the lead for nothing. Get to dummy with your last diamond.",
                ],
                alsoFine: ["♥A"]
            ),
        ]
    )

    // MARK: - 4♠: play for the drop

    static let playForTheDrop = HandPlayDeal(
        id: "handplay-drop",
        title: "Play for the Drop",
        north: "♠T75 ♥Q42 ♦QJ3 ♣J862",
        east: "♠98 ♥KJ763 ♦652 ♣T95",
        south: "♠AKJ642 ♥A5 ♦AK4 ♣73",
        west: "♠Q3 ♥T98 ♦T987 ♣AKQ4",
        calls: ["1S", "P", "2S", "P", "4S", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.spades))],
        tricks: [
            "♣A ♣2 ♣9 ♣3",
            "♣K ♣6 ♣5 ♣7",
            "♣Q ♣8 ♣T ♠2",
            "♠A ♠3 ♠5 ♠8",
            "♠K ♠Q ♠7 ♠9",
            "♦A ♦7 ♦3 ♦2",
            "♦K ♦8 ♦J ♦5",
            "♦4 ♦9 ♦Q ♦6",
            "♥2 ♥3 ♥A ♥8",
            "♥5 ♥9 ♥Q ♥K",
            "♥J ♠4 ♥T ♥4",
            "♠J ♦T ♠T ♥7",
            "♠6 ♣4 ♣J ♥6",
        ],
        decisions: [
            PlayDecision(
                trick: 2,
                reason: "Ruff with a low trump. Keep the A♠ and K♠ to draw trumps.",
                cardNotes: [
                    "♠A": "Ruffing with the A♠ leaves you without it to draw trumps, and the Q♠ can score. Ruff low.",
                    "♠K": "Ruffing with the K♠ leaves you without it to draw trumps, and the Q♠ can score. Ruff low.",
                    "♥A": "The A♥ is a winner. Ruff low instead.",
                ],
                suitNotes: [
                    .diamonds: "Your diamonds are all winners. Ruff low, and keep them.",
                ],
                alsoFine: ["♥5", "♠J"]
            ),
            PlayDecision(
                trick: 3,
                reason: "Lead the A♠. Cash your top trumps first and give the Q♠ a chance to fall.",
                cardNotes: [
                    "♠J": "The J♠ loses to the queen when a defender holds it. Cash the A♠ first.",
                    "♠6": "A low trump gives the defenders a cheap trick. Cash the A♠ first.",
                    "♠4": "A low trump gives the defenders a cheap trick. Cash the A♠ first.",
                ],
                suitNotes: [
                    .hearts: "Draw trumps before you cash side winners, so the defenders cannot ruff them.",
                    .diamonds: "Draw trumps before you cash side winners, so the defenders cannot ruff them.",
                ]
            ),
            PlayDecision(
                trick: 4,
                reason: "Cash the K♠. With nine trumps missing the queen, playing for it to fall wins more often than a finesse.",
                cardNotes: [
                    "♠J": "Leading the J♠ loses to the queen when West holds it. Cash the K♠: it drops the queen whenever the trumps split 2-2.",
                    "♠6": "A low trump lets the Q♠ win a trick. Cash the K♠ instead.",
                    "♠4": "A low trump lets the Q♠ win a trick. Cash the K♠ instead.",
                    "♦4": "Crossing to dummy to finesse the J♠ wins only when East holds the queen. With nine trumps the K♠ is the better play.",
                    "♥5": "The 5♥ gives up the lead with a trump still out. Cash the K♠ first.",
                ],
                alsoFine: ["♦A", "♦K", "♥A"]
            ),
        ]
    )

    // MARK: - 3NT: finesse twice

    static let finesseTwice = HandPlayDeal(
        id: "handplay-finesse-twice",
        title: "Finesse Twice",
        north: "♠AK63 ♥95 ♦863 ♣AK75",
        east: "♠QJT752 ♥42 ♦K54 ♣83",
        south: "♠84 ♥AK763 ♦AQJ ♣642",
        west: "♠9 ♥QJT8 ♦T972 ♣QJT9",
        calls: ["1H", "P", "1S", "P", "1NT", "P", "3NT", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterOneSpade)],
        tricks: [
            "♣Q ♣A ♣3 ♣2",
            "♦3 ♦4 ♦J ♦2",
            "♠4 ♠9 ♠A ♠2",
            "♦6 ♦5 ♦Q ♦7",
            "♦A ♦9 ♦8 ♦K",
            "♥A ♥8 ♥5 ♥2",
            "♥K ♥T ♥9 ♥4",
            "♠8 ♣9 ♠K ♠5",
            "♣K ♣8 ♣4 ♣T",
            "♣5 ♠7 ♣6 ♣J",
            "♥Q ♣7 ♠T ♥7",
            "♥J ♠3 ♠J ♥6",
            "♦T ♠6 ♠Q ♥3",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Play the J♦. East played before you, so the jack wins whenever East holds the king.",
                cardNotes: [
                    "♦A": "The A♦ wins now, but then the king beats your queen later. The finesse wins all three diamonds whenever East holds the K♦.",
                ]
            ),
            PlayDecision(
                trick: 2,
                reason: "Go back to dummy and lead diamonds again. The finesse has to be taken from dummy each time.",
                cardNotes: [
                    "♦A": "Cashing the A♦ now leaves the king to beat your queen. Get back to dummy and repeat the finesse.",
                    "♦Q": "The Q♦ from your hand lets East win the K♦. Lead toward your Q♦ from dummy instead.",
                ],
                suitNotes: [
                    .hearts: "A low heart gives up the lead for nothing. Get back to dummy with a spade or a club.",
                ],
                alsoFine: ["♣6", "♣4", "♥A", "♥K"]
            ),
            PlayDecision(
                trick: 3,
                reason: "Play the Q♦. The finesse worked once, and it works again for the same reason: East played before you.",
                cardNotes: [
                    "♦A": "Cash the A♦ now and East's king, if East has it, beats your queen later. Repeat the finesse with the Q♦.",
                ]
            ),
        ]
    )

    // MARK: - 4♠: ruff high

    static let ruffHigh = HandPlayDeal(
        id: "handplay-ruff-high",
        title: "Ruff High",
        north: "♠KJ4 ♥Q763 ♦76 ♣Q983",
        east: "♠632 ♥A42 ♦95 ♣AKT76",
        south: "♠AQ875 ♥K9 ♦AK32 ♣54",
        west: "♠T9 ♥JT85 ♦QJT84 ♣J2",
        calls: ["1S", "P", "2S", "P", "3S", "P", "4S", "P", "P", "P"],
        coachedCalls: [0: .opening, 4: .rebid(.rebidAfterRaise(.spades))],
        tricks: [
            "♦Q ♦6 ♦5 ♦A",
            "♦K ♦4 ♦7 ♦9",
            "♦3 ♦8 ♠J ♣6",
            "♠4 ♠2 ♠A ♠9",
            "♦2 ♦T ♠K ♣7",
            "♣3 ♣K ♣4 ♣2",
            "♣A ♣5 ♣J ♣8",
            "♥A ♥9 ♥5 ♥3",
            "♥4 ♥K ♥8 ♥6",
            "♠Q ♠T ♥7 ♠3",
            "♠8 ♥J ♣9 ♠6",
            "♠7 ♥T ♣Q ♣T",
            "♠5 ♦J ♥Q ♥2",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Cash the K♦ before you touch trumps. Dummy's K♠ and J♠ are going to ruff your last two diamonds.",
                cardNotes: [
                    "♦3": "A low diamond gives the defenders a trick you can avoid. Cash the K♦, then ruff the last two in dummy.",
                    "♦2": "A low diamond gives the defenders a trick you can avoid. Cash the K♦, then ruff the last two in dummy.",
                ],
                suitNotes: [
                    .spades: "Each round of trumps takes a trump from dummy, and dummy needs both high ones for ruffs. Cash the K♦ first.",
                    .hearts: "A heart gives up the lead, and the defenders can lead trumps to stop your ruffs. Cash the K♦ first.",
                    .clubs: "A club gives up the lead, and the defenders can lead trumps to stop your ruffs. Cash the K♦ first.",
                ]
            ),
            PlayDecision(
                trick: 2,
                seat: .north,
                reason: "Ruff with the J♠. East may be out of diamonds too, and a low trump invites an overruff. East cannot beat the jack.",
                cardNotes: [
                    "♠4": "East may have no diamonds left and overruff the 4♠. Ruff high with the J♠.",
                ],
                suitNotes: [
                    .hearts: "A discard lets West's diamond win. Ruff it, and ruff high.",
                    .clubs: "A discard lets West's diamond win. Ruff it, and ruff high.",
                ]
            ),
            PlayDecision(
                trick: 4,
                seat: .north,
                reason: "Ruff the last diamond with the K♠. That ruff is your tenth trick.",
                suitNotes: [
                    .hearts: "A discard lets West's diamond win the trick. Ruff it with the K♠.",
                    .clubs: "A discard lets West's diamond win the trick. Ruff it with the K♠.",
                ]
            ),
        ]
    )

    // MARK: - 3NT: take your nine tricks

    static let nineTricks = HandPlayDeal(
        id: "handplay-nine-tricks",
        title: "Take Your Nine Tricks",
        north: "♠AKQ4 ♥852 ♦AQ73 ♣94",
        east: "♠J862 ♥74 ♦T865 ♣JT5",
        south: "♠75 ♥A63 ♦KJ4 ♣AQ862",
        west: "♠T93 ♥KQJT9 ♦92 ♣K73",
        calls: ["1C", "P", "1D", "P", "1NT", "P", "3NT", "P", "P", "P"],
        coachedCalls: [0: .opening],
        tricks: [
            "♥K ♥2 ♥4 ♥A",
            "♠5 ♠3 ♠A ♠2",
            "♣4 ♣5 ♣A ♣3",
            "♦K ♦2 ♦3 ♦5",
            "♦J ♦9 ♦7 ♦6",
            "♦4 ♣7 ♦A ♦8",
            "♦Q ♦T ♣2 ♠9",
            "♠K ♠6 ♠7 ♠T",
            "♠Q ♠8 ♣6 ♥9",
            "♠4 ♠J ♣8 ♥T",
            "♣J ♣Q ♣K ♣9",
            "♥Q ♥5 ♥7 ♥3",
            "♥J ♥8 ♣T ♥6",
        ],
        decisions: [
            PlayDecision(
                trick: 1,
                reason: "Count first: three spades, four diamonds, the A♥ and the A♣ make nine tricks. Cash them and keep the lead.",
                cardNotes: [
                    "♣Q": "Leading the Q♣ loses to the K♣ if a defender plays it. You have nine tricks without it.",
                ],
                suitNotes: [
                    .hearts: "A heart hands the defenders the lead, and they have hearts to cash. Take your nine tricks.",
                    .clubs: "A low club gives up the lead, and the defenders have hearts to cash. Take your nine tricks.",
                ],
                alsoFine: ["♦K", "♦J", "♦4", "♣A"]
            ),
            PlayDecision(
                trick: 2,
                reason: "Win the A♣. It is your ninth trick, and a finesse with the Q♣ would risk the lead for a trick you do not need.",
                cardNotes: [
                    "♣Q": "If West holds the K♣, the finesse loses and West cashes the rest of the hearts. You have nine tricks without it.",
                ],
                suitNotes: [
                    .clubs: "A low club lets East win the trick and lead a heart. Take the A♣.",
                ]
            ),
            PlayDecision(
                trick: 5,
                reason: "Lead the 4♦ to dummy's A♦. Then the Q♦ and the top spades take the rest of your nine tricks.",
                suitNotes: [
                    .hearts: "A heart hands the defenders the lead and their hearts. Get to dummy and cash your winners.",
                    .clubs: "A club gives up the lead, and the defenders have hearts to cash. Get to dummy and cash your winners.",
                ],
                alsoFine: ["♠7"]
            ),
        ]
    )
}
