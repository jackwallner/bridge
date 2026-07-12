import XCTest
@testable import MahjTrainer

final class ContentValidityTests: XCTestCase {

    // Every drill in the library, so new packs (like the Pro Tables) are
    // covered automatically.
    private var allDrills: [Drill] {
        DrillLibrary.rooms.flatMap(\.drills)
    }

    private var allHandMatch: [HandMatchQuestion] {
        allDrills.flatMap { drill -> [HandMatchQuestion] in
            if case .handMatch(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allQuiz: [QuizQuestion] {
        allDrills.flatMap { drill -> [QuizQuestion] in
            if case .quiz(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allCharleston: [CharlestonScenario] {
        allDrills.flatMap { drill -> [CharlestonScenario] in
            if case .charleston(let scenarios) = drill.kind { return scenarios }
            return []
        }
    }

    private var allFlashcards: [Flashcard] {
        allDrills.flatMap { drill -> [Flashcard] in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
    }

    // MARK: - Hand match

    func testHandMatchQuestionsHaveThirteenTiles() {
        for question in allHandMatch {
            XCTAssertEqual(question.tiles.count, 13, "\(question.id) must show a 13-tile rack")
        }
    }

    func testHandMatchAnswerIsAmongChoices() {
        for question in allHandMatch {
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) answer missing from choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    // MARK: - Charleston

    func testCharlestonDealsAreThirteenTiles() {
        for scenario in allCharleston {
            XCTAssertEqual(scenario.deal.count, 13, "\(scenario.id) deal must be 13 tiles")
        }
    }

    func testCharlestonRecommendsExactlyThreePassableTiles() {
        for scenario in allCharleston {
            XCTAssertEqual(scenario.recommendedPass.count, 3, "\(scenario.id) must recommend exactly 3 tiles")
            XCTAssertFalse(scenario.recommendedPass.contains(.joker), "\(scenario.id) recommends passing a joker (illegal)")
        }
    }

    func testCharlestonRecommendedPassComesFromDeal() {
        for scenario in allCharleston {
            var pool = scenario.deal
            for tile in scenario.recommendedPass {
                guard let index = pool.firstIndex(of: tile) else {
                    XCTFail("\(scenario.id) recommends passing \(tile.shortLabel), which isn't in the deal")
                    continue
                }
                pool.remove(at: index)
            }
        }
    }

    func testNoDealExceedsFourCopiesOfATile() {
        for scenario in allCharleston {
            var counts: [Tile: Int] = [:]
            for tile in scenario.deal where tile != .flower && tile != .joker {
                counts[tile, default: 0] += 1
            }
            for (tile, count) in counts {
                XCTAssertLessThanOrEqual(count, 4, "\(scenario.id) has \(count)× \(tile.shortLabel); only 4 exist")
            }
        }
    }

    // MARK: - Quiz

    func testQuizAnswerIndicesAreValid() {
        for question in allQuiz {
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), "\(question.id) has out-of-range answer")
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) needs at least 2 choices")
        }
    }

    // MARK: - Flashcard choices

    func testCardChoicesAreTwoOptionsWithValidAnswer() {
        for card in allFlashcards {
            guard let choice = card.choice else { continue }
            XCTAssertEqual(choice.options.count, 2, "\(card.id) choice must have exactly 2 options")
            XCTAssertTrue(choice.options.indices.contains(choice.answerIndex), "\(card.id) has out-of-range choice answer")
            XCTAssertEqual(Set(choice.options).count, 2, "\(card.id) has duplicate choice options")
        }
    }

    // MARK: - Library integrity

    func testAllContentIDsAreUnique() {
        var ids: [String] = []
        for room in DrillLibrary.rooms {
            ids.append(room.id)
            for drill in room.drills {
                ids.append(drill.id)
                switch drill.kind {
                case .flashcards(let cards): ids += cards.map(\.id)
                case .quiz(let questions): ids += questions.map(\.id)
                case .handMatch(let questions): ids += questions.map(\.id)
                case .charleston(let scenarios): ids += scenarios.map(\.id)
                }
            }
        }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate content IDs found")
    }

    func testEveryRoomHasDrillsAndFirstRoomIsFree() {
        XCTAssertFalse(DrillLibrary.rooms.isEmpty)
        for room in DrillLibrary.rooms {
            XCTAssertFalse(room.drills.isEmpty, "\(room.id) has no drills")
            for drill in room.drills {
                XCTAssertGreaterThan(drill.kind.itemCount, 0, "\(drill.id) is empty")
            }
        }
        XCTAssertTrue(DrillLibrary.rooms.first?.isFree == true, "First room must be free")
    }

    func testBeginnerRoomsAreFreeAndProTablesArePaid() {
        for room in DrillLibrary.rooms {
            if room.id == "pro-tables" {
                XCTAssertFalse(room.isFree, "Pro Tables must be the paid tier")
            } else {
                XCTAssertTrue(room.isFree, "\(room.id) must be free (free-beginner model)")
            }
        }
    }

    func testNoEmDashesInPlayerFacingCopy() {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy.append(room.name)
            copy.append(room.tagline)
            for drill in room.drills {
                copy.append(drill.title)
                copy.append(drill.subtitle)
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] + ($0.choice?.options ?? []) }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .charleston(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { page in
            [page.title, page.body, page.tip ?? ""]
        }
        for text in copy {
            XCTAssertFalse(text.contains("\u{2014}"), "Em dash found in copy: \(text)")
        }
    }

    // MARK: - How to Play

    func testHowToPlayPagesHaveUniqueIDsAndValidTileCounts() {
        let pages = HowToPlayContent.pages
        XCTAssertFalse(pages.isEmpty)
        XCTAssertEqual(Set(pages.map(\.id)).count, pages.count, "Duplicate How to Play page IDs found")

        for page in pages {
            var counts: [Tile: Int] = [:]
            for tile in page.tiles where tile != .flower && tile != .joker {
                counts[tile, default: 0] += 1
            }
            for (tile, count) in counts {
                XCTAssertLessThanOrEqual(count, 4, "\(page.id) has \(count)× \(tile.shortLabel); only 4 exist")
            }
        }
    }

    // MARK: - Session builder

    func testDailyMixPullsTenItemsAndPrioritizesMisses() {
        let mix = SessionBuilder.dailyMix(seen: [], missed: [], includePro: false)
        XCTAssertEqual(mix.count, 10)
        XCTAssertEqual(Set(mix.map(\.id)).count, 10, "Mix must not repeat items")

        let missedID = mix[0].id
        let biased = SessionBuilder.dailyMix(seen: [missedID], missed: [missedID], includePro: false)
        XCTAssertTrue(biased.contains { $0.id == missedID }, "A missed item must come back in the next mix")
    }

    func testDailyMixExcludesProContentForFreeUsers() {
        let mix = SessionBuilder.dailyMix(seen: [], missed: [], includePro: false)
        XCTAssertFalse(mix.contains { $0.id.hasPrefix("pro-") }, "Free mix must not leak Pro items")
    }
}
