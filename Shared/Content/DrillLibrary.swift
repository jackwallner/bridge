import Foundation

enum DrillLibrary {
    static let rooms: [Room] = [
        Room(
            id: "card-room",
            name: "The Card Room",
            tagline: "Ranks, tricks, contracts, and table roles",
            icon: "suit.spade.fill",
            isFree: true,
            drills: [
                Drill(id: "meet-cards", title: "Meet the Game", subtitle: "Flashcards: the deck, tricks, trump, and contracts", kind: .flashcards(CardBasicsContent.meetTheCards)),
                Drill(id: "card-check", title: "Card Check", subtitle: "Quick quiz: the rules every player needs", kind: .quiz(CardBasicsContent.cardQuiz)),
                Drill(id: "plus-card-extras", title: "Card Check: Extra Reps", subtitle: "Games, slams, dummy, and bridge vocabulary", kind: .quiz(PlusContent.cardExtras), isPlus: true),
            ]
        ),
        Room(
            id: "auction-room",
            name: "The Auction Room",
            tagline: "Count points and find your opening call",
            icon: "quote.bubble.fill",
            isFree: true,
            drills: [
                Drill(id: "opening-playbook", title: "Opening Playbook", subtitle: "Flashcards: pass, suits, and 1NT", kind: .flashcards(CategoryContent.openingCards)),
                Drill(id: "opening-bid", title: "Name Your Opening", subtitle: "Read 13 cards and choose the call", kind: .handMatch(CategoryContent.openingHands)),
                Drill(id: "plus-opening-extras", title: "Openings: Extra Reps", subtitle: "More five-card majors, minors, and shapes", kind: .handMatch(PlusContent.extraOpeningHands), isPlus: true),
            ]
        ),
        Room(
            id: "declarer-room",
            name: "The Declarer Room",
            tagline: "Plan the hand and choose the card",
            icon: "hand.point.up.left.fill",
            isFree: true,
            drills: [
                Drill(id: "play-plan", title: "Declarer Playbook", subtitle: "Flashcards: winners, trump, finesses, and timing", kind: .flashcards(PlayContent.strategyCards)),
                Drill(id: "choose-card", title: "Choose the Card", subtitle: "Table situations: make the legal, winning play", kind: .play(PlayContent.scenarios)),
                Drill(id: "plus-play-extras", title: "Choose the Card: Extra Reps", subtitle: "Covering honors, second hand, and unblocking", kind: .play(PlusContent.extraPlays), isPlus: true),
            ]
        ),
        Room(
            id: "defense-room",
            name: "The Defense Room",
            tagline: "Opening leads and partnership habits",
            icon: "shield.lefthalf.filled",
            isFree: true,
            drills: [
                Drill(id: "defense-calls", title: "Lead or Hold?", subtitle: "Make the call, then flip for the coach's answer", kind: .flashcards(JudgmentContent.judgmentCards)),
                Drill(id: "plus-defense-extras", title: "Defense: Extra Reps", subtitle: "Sequences, trump leads, and shortness", kind: .flashcards(PlusContent.extraDefense), isPlus: true),
            ]
        ),
        Room(
            id: "master-tables",
            name: "The Master Tables",
            tagline: "Conventions, advanced card play, and duplicate",
            icon: "crown.fill",
            isFree: false,
            drills: [
                Drill(id: "competitive-bidding", title: "Competitive Bidding", subtitle: "Doubles, preempts, Stayman, and transfers", kind: .quiz(ProContent.competitiveBidding)),
                Drill(id: "advanced-play", title: "Advanced Card Play", subtitle: "Finesses, hold-ups, and safety plays", kind: .play(ProContent.advancedPlay)),
                Drill(id: "duplicate-bridge", title: "Duplicate Decisions", subtitle: "Game levels, vulnerability, and matchpoints", kind: .quiz(ProContent.duplicateQuiz)),
            ]
        ),
    ]

    static func room(id: String) -> Room? { rooms.first { $0.id == id } }
}
