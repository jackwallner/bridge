import XCTest

/// Release-gate journeys. `QA.checkpoint` runs the oracles on every screen; the
/// assertions here only prove a screen is reachable, except the core loop, which
/// also proves a finished Get Started session is counted and survives a relaunch.
///
/// The paywall reads prices from the RevenueCat Test Store in these journeys.
///
/// Tests run in name order on one install: the core loop goes first so Home's
/// daily Get Started card is still unspent when it looks for it, and no other
/// journey finishes a daily session.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private static let testCustomer = ["RC_PROBE_USER": "qa-ios-journeys-bridge", "RC_PROBE_SURFACE": "qa_gate"]

    /// Skips onboarding and the primer and keeps What's New off Home. The
    /// `-key value` form lands in the argument domain, so nothing is persisted.
    private static let seeded = [
        "-progress.hasOnboarded", "YES",
        "-bridge.hasReadPrimer", "YES",
        "-bridge.skillLevel", "some",
        "-bridge.suppressWhatsNew",
    ]

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Journeys

    func testCoreLoopQuickSessionCountsAndSurvivesRelaunch() {
        let app = launchApp(seeded: true)
        home("home-before-session", in: app)
        let before = drillsDone(in: app)
        XCTAssertFalse(app.staticTexts[L("Today's session is done")].exists)

        let getStarted = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", L("Get Started"))).firstMatch
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15))
        getStarted.tap()

        var question = 0
        while true {
            let choice = firstChoice(in: app)
            XCTAssertTrue(choice.waitForExistence(timeout: 15))
            if question == 0 { QA.checkpoint(app, "session-question") }
            choice.tap()
            let advance = advanceButton(in: app)
            XCTAssertTrue(advance.waitForExistence(timeout: 10))
            if question == 0 { QA.checkpoint(app, "session-answered") }
            question += 1
            let isLast = advance.label == L("Finish")
            advance.tap()
            if isLast { break }
            XCTAssertTrue(advance.waitForNonExistence(timeout: 10))
            XCTAssertLessThan(question, 15, "the session never reached Finish")
        }
        XCTAssertGreaterThan(question, 0)

        let done = app.buttons[L("Done")]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        QA.checkpoint(app, "session-complete")
        done.tap()

        home("home-after-session", in: app)
        XCTAssertTrue(app.staticTexts[L("Today's session is done")].waitForExistence(timeout: 10))
        XCTAssertEqual(drillsDone(in: app), before + 1)
        QA.checkpoint(app, "session-counted")

        QA.relaunch(app)
        home("home-after-relaunch", in: app)
        XCTAssertTrue(app.staticTexts[L("Today's session is done")].waitForExistence(timeout: 10))
        XCTAssertEqual(drillsDone(in: app), before + 1)
        QA.checkpoint(app, "session-persisted")
    }

    func testFirstRunToFirstAnswer() {
        let app = launchApp(seeded: false)
        for page in 1...3 {
            tap(app.buttons[L("Continue")], name: "Continue")
            QA.checkpoint(app, "onboarding-page-\(page)")
        }
        XCTAssertTrue(app.staticTexts[L("Where are you starting from?")].waitForExistence(timeout: 10))
        QA.checkpoint(app, "onboarding-skill")
        tap(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", L("Know the basics"))).firstMatch,
            name: "Know the basics")
        tap(app.buttons[L("Continue")], name: "Continue")

        // The free way in sits above the trial button; it is not on any other page.
        let freeExit = app.buttons[L("Get Started")]
        XCTAssertTrue(freeExit.waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        freeExit.tap()

        for page in 1...3 {
            tap(app.buttons[L("Show me")], name: "Show me")
            QA.checkpoint(app, "tour-page-\(page)")
        }
        tap(app.buttons[L("Start my first session")], name: "Start my first session")

        let choice = firstChoice(in: app)
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
        QA.checkpoint(app, "first-question")
        choice.tap()
        XCTAssertTrue(advanceButton(in: app).waitForExistence(timeout: 10))
        QA.checkpoint(app, "first-answer")

        tap(app.buttons[L("Close")], name: "Close")
        home("home-first-run", in: app)
    }

    func testPaywallShownAndDismissed() {
        let app = launchApp(seeded: true)
        home("home-free", in: app)

        let locked = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", L("Endless"))).firstMatch
        tap(locked, name: "Endless Practice")
        let close = app.buttons[L("Close")]
        XCTAssertTrue(close.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons[L("Restore")].waitForExistence(timeout: 10))
        if QA.persona == "accessibility" {
            let price = app.staticTexts["paywall-billed-price"]
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<10 where !price.isHittable {
                scroll.swipeUp()
            }
            XCTAssertTrue(price.isHittable, "The billed amount must be reachable at accessibility sizes")
        }
        QA.checkpoint(app, "paywall-shown", paywall: true)

        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 10))
        home("paywall-dismissed", in: app)
    }

    func testReturnVisitAndInterruption() {
        let app = launchApp(seeded: true)
        home("home-return", in: app)

        QA.swipe(app.scrollViews.firstMatch, .up)
        QA.checkpoint(app, "home-scrolled")
        QA.swipe(app.scrollViews.firstMatch, .down)

        tap(statsLink(in: app), name: "progress chips")
        XCTAssertTrue(app.navigationBars[L("Your Progress")].waitForExistence(timeout: 10))
        QA.checkpoint(app, "progress")
        tap(backButton(in: app), name: "back")
        home("home-after-progress", in: app)

        tap(app.buttons[L("Settings")], name: "Settings")
        XCTAssertTrue(app.navigationBars[L("Settings")].waitForExistence(timeout: 10))
        QA.checkpoint(app, "settings")
        tap(app.buttons[L("Done")], name: "Done")
        home("home-after-settings", in: app)

        QA.interrupt(app)
        home("home-after-background", in: app)
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
    }

    // MARK: - Helpers

    /// Addressed by bundle id: PRODUCT_NAME differs from the target name, which
    /// the implicit initialiser cannot resolve.
    private func launchApp(seeded: Bool) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.bridge")
        QA.launch(app, environment: Self.testCustomer, arguments: ["-rcfunnelprobe"] + (seeded ? Self.seeded : []))
        return app
    }

    /// The gear is on Home at every size, with or without a spent daily session.
    private func home(_ name: String, in app: XCUIApplication, journey: String = #function) {
        XCTAssertTrue(app.buttons[L("Settings")].waitForExistence(timeout: 20), "Home never appeared")
        QA.checkpoint(app, name, journey: journey)
    }

    private func tap(_ element: XCUIElement, name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 15), "\(name) never appeared")
        element.tap()
    }

    private func firstChoice(in app: XCUIApplication) -> XCUIElement {
        app.buttons["drill-answer-0"]
    }

    private func advanceButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", [L("Next"), L("Finish")])).firstMatch
    }

    /// The system back button. On the unfolded Duo it is drawn beside the
    /// status area, outside the navigation bar's element tree, so the bar's own
    /// buttons are not enough there.
    private func backButton(in app: XCUIApplication) -> XCUIElement {
        let inBar = app.navigationBars.buttons.firstMatch
        return inBar.waitForExistence(timeout: 3) ? inBar : app.buttons["BackButton"]
    }

    private func statsLink(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label MATCHES %@", ".*\(drillsPattern).*")).firstMatch
    }

    private var drillsPattern: String {
        QA.persona == "german" ? "(\\d+) Übung(?:en)? erledigt" : "(\\d+) drills? done"
    }

    /// The count on Home's drills chip.
    private func drillsDone(in app: XCUIApplication) -> Int {
        let chip = statsLink(in: app)
        XCTAssertTrue(chip.waitForExistence(timeout: 15), "the drills chip never appeared")
        let label = chip.label
        guard let regex = try? NSRegularExpression(pattern: drillsPattern),
              let match = regex.firstMatch(in: label, range: NSRange(label.startIndex..., in: label)),
              let range = Range(match.range(at: 1), in: label),
              let count = Int(label[range]) else {
            XCTFail("no drill count in \"\(label)\"")
            return -1
        }
        return count
    }

    /// The German strings the journeys look for; other personas see the English source.
    private static let german = [
        "Continue": "Weiter", "Get Started": "Los geht's", "Know the basics": "Ich kenne die Grundlagen",
        "Show me": "Zeig mal", "Start my first session": "Meine erste Runde starten",
        "Close": "Schließen", "Next": "Weiter", "Finish": "Fertig", "Done": "Fertig",
        "Settings": "Einstellungen", "Endless": "Endlos", "Restore": "Wiederherstellen",
        "Today's session is done": "Die heutige Runde ist erledigt",
        "Where are you starting from?": "Wo stehst du gerade?", "Your Progress": "Dein Fortschritt",
    ]

    private func L(_ english: String) -> String {
        QA.persona == "german" ? Self.german[english] ?? english : english
    }
}
