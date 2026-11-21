import XCTest
@testable import Bridge

/// Authored content is looked up in the string catalog at runtime by its
/// English text (`String.localizedContent`), so the compiler never extracts
/// it. A question added without a catalog entry would silently show English
/// to every non-English player; this catches it.
final class LocalizationTests: XCTestCase {
    private let languages = ["da", "de", "el", "es", "fr", "it", "ja", "ko", "nb", "nl", "ru", "sv", "th", "tr", "zh-Hant"]
    private let missing = "__missing__"

    private var authoredCopy: [String] {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            for drill in room.drills {
                copy += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.backTitle, $0.backBody] + [$0.frontSubtitle].compactMap { $0 } + ($0.choice?.options ?? []) }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .play(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { [$0.title, $0.body] + [$0.tip].compactMap { $0 } }
        copy += WhatsNew.releases.flatMap { [$0.headline] + $0.items.flatMap { [$0.title, $0.body] } }
        // Numbers and card symbols ("13", "K♠") read the same everywhere.
        return copy.filter { $0.contains(where: \.isLetter) }
    }

    func testAuthoredContentIsTranslatedInEveryLanguage() throws {
        let copy = authoredCopy
        XCTAssertGreaterThan(copy.count, 300)
        for language in languages {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"), "\(language).lproj is missing")
            let bundle = try XCTUnwrap(Bundle(path: path))
            for text in copy {
                let translated = bundle.localizedString(forKey: text, value: missing, table: nil)
                XCTAssertNotEqual(translated, missing, "\(language) has no translation for: \(text)")
            }
        }
    }

    /// English had no catalog entry for the counted strings, so the key itself
    /// rendered and "1 drills done" shipped. Every counted string must agree
    /// with its number in the source language too.
    func testEnglishCountsAgreeWithTheirNumber() {
        let one = 1
        let many = 3
        XCTAssertEqual(String(localized: "\(one) more drills in this room"), "1 more drill in this room")
        XCTAssertEqual(String(localized: "\(many) more drills in this room"), "3 more drills in this room")
        XCTAssertEqual(String(localized: "Up \(one) questions this week"), "Up 1 question this week")
        XCTAssertEqual(String(localized: "Up \(many) questions this week"), "Up 3 questions this week")
        XCTAssertEqual(String(localized: "\(one) questions locked in this week"), "1 question locked in this week")
        XCTAssertEqual(String(localized: "\(many) questions locked in this week"), "3 questions locked in this week")
        XCTAssertEqual(String(localized: "\(one) drills done"), "1 drill done")
        XCTAssertEqual(String(localized: "\(many) drills done"), "3 drills done")
        XCTAssertEqual(String(localized: "\(one) drills finished"), "1 drill finished")
        XCTAssertEqual(String(localized: "\(many) drills finished"), "3 drills finished")
        XCTAssertEqual(String(localized: "\(one) cards"), "1 card")
        XCTAssertEqual(String(localized: "\(many) cards"), "3 cards")
        XCTAssertEqual(String(localized: "\(one) questions"), "1 question")
        XCTAssertEqual(String(localized: "\(one) hands"), "1 hand")
        XCTAssertEqual(String(localized: "\(one) deals"), "1 deal")
        XCTAssertEqual(String(localized: "\(one) due mistakes first, followed by material you have not seen yet."),
                       "1 due mistake first, followed by material you have not seen yet.")
    }
}
