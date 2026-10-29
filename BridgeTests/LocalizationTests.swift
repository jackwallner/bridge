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

    func testRussianPluralCategoriesResolve() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "ru", ofType: "lproj"), "ru.lproj is missing")
        let russian = try XCTUnwrap(Bundle(path: path))
        let locale = Locale(identifier: "ru")

        XCTAssertEqual(String(localized: "\(1) cards", bundle: russian, locale: locale), "1 карта")
        XCTAssertEqual(String(localized: "\(3) cards", bundle: russian, locale: locale), "3 карты")
        XCTAssertEqual(String(localized: "\(5) cards", bundle: russian, locale: locale), "5 карт")

        XCTAssertEqual(
            String(localized: "All \(1) cards down. They'll stick a little better every pass.", bundle: russian, locale: locale),
            "Ты повторил 1 карточку. С каждым повторением она будет запоминаться лучше."
        )
        XCTAssertEqual(
            String(localized: "All \(3) cards down. They'll stick a little better every pass.", bundle: russian, locale: locale),
            "Ты повторил 3 карточки. С каждым повторением они будут запоминаться лучше."
        )
        XCTAssertEqual(
            String(localized: "All \(5) cards down. They'll stick a little better every pass.", bundle: russian, locale: locale),
            "Ты повторил 5 карточек. С каждым повторением они будут запоминаться лучше."
        )
    }
}
