import XCTest

/// P6 probe: one `reminderPermissionDenied` flag drives two alerts when Game
/// Night Prep is pushed from Settings (Settings' root Form and the pushed view).
/// Denying notifications there must show exactly one "Notifications are off"
/// alert, dismiss with one tap, not come back, and leave Game Night Prep open.
final class GameNightDeniedAlertUITests: XCTestCase {

    func testDenialFromSettingsGameNightShowsOneAlertThatDismisses() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.bridge")
        app.launchArguments += ["-DuoSeed", "-bridge.suppressWhatsNew"]
        app.launch()

        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 30), "Home never showed the Settings button")
        gear.tap()

        let prep = app.buttons["Game Night Prep"]
        XCTAssertTrue(prep.waitForExistence(timeout: 10), "Settings has no Game Night Prep row (not Pro?)")
        prep.tap()

        let toggle = app.switches["Weekly game night reminder"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Game Night Prep never opened")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.alerts.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Don'")).firstMatch
        XCTAssertTrue(deny.waitForExistence(timeout: 15), "iOS never asked for notification permission")
        deny.tap()

        let alert = app.alerts["Notifications are off"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "no Notifications are off alert after the denial")
        XCTAssertEqual(app.alerts.count, 1, "more than one alert is up")
        alert.buttons["Not now"].tap()

        sleep(3)
        XCTAssertEqual(app.alerts.count, 0, "an alert is still up, or came back, after Not now")
        XCTAssertTrue(app.navigationBars["Game Night Prep"].exists, "dismissing the alert left Game Night Prep")
        XCTAssertTrue(app.switches["Weekly game night reminder"].exists)
    }
}
