import XCTest

/// Send used to be a big button just above the keyboard's suggestion bar. It
/// lit up after the first word, and the next reach for a suggestion landed on
/// it: feedback arrived as "The" and "The first", which are what the bar
/// offers an empty box. Send now sits in the navigation bar.
final class FeedbackSheetLayoutUITests: XCTestCase {
    private func checkSendIsClearOfTheKeyboard(size: String?) {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.bridge")
        app.launchArguments += [
            "-progress.hasOnboarded", "YES",
            "-bridge.hasReadPrimer", "YES",
            "-bridge.skillLevel", "some",
            "-bridge.suppressWhatsNew", "YES",
        ]
        if let size { app.launchArguments += ["-UIPreferredContentSizeCategoryName", size] }
        app.launch()
        defer { app.terminate() }
        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 30), "Home never appeared")
        gear.tap()
        let row = app.buttons["Send Feedback"]
        for _ in 0..<8 where !(row.exists && row.isHittable) { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10), "No feedback row")
        row.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let send = app.navigationBars.buttons["Send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5), "Send belongs in the navigation bar")
        XCTAssertFalse(send.isEnabled, "Nothing to send yet")
        editor.tap()
        editor.typeText("The ")
        XCTAssertTrue(send.isEnabled)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        // The suggestion bar sits about 50 points above what XCUITest reports
        // as the keyboard's top; keep Send far clear of both.
        XCTAssertLessThan(send.frame.maxY, keyboard.frame.minY - 200)
        XCTAssertEqual(app.buttons.matching(identifier: "Send").count, 1, "One Send, not a second one by the keyboard")
    }

    func testDefaultSize() { checkSendIsClearOfTheKeyboard(size: nil) }
    func testAccessibilitySize() { checkSendIsClearOfTheKeyboard(size: "UICTContentSizeCategoryAccessibilityM") }
}
