import XCTest
@testable import Bridge

@MainActor
final class ReminderCopyTests: XCTestCase {
    /// Repeating reminders are static text: any number in them goes stale
    /// for the player who stops opening the app.
    func testRepeatingReminderCopyQuotesNoCount() {
        for body in [AppSettings.dailyReminderBody, AppSettings.gameNightReminderBody] {
            XCTAssertFalse(body.contains("locked in"))
            XCTAssertNil(body.rangeOfCharacter(from: .decimalDigits), body)
        }
    }
}
