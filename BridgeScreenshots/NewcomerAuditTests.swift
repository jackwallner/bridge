import XCTest

/// Newcomer persona audit: a first-time player who does not know bridge
/// terminology walks the real first run (onboarding, primer, tour, first Quick
/// Session, Home), then relaunches for the return visit. Every step attaches a
/// screenshot, and the question text and tap-target frames are attached as
/// text so the report can quote them.
///
/// Run: gh-sim test --scheme Screenshots --only BridgeScreenshots/NewcomerAuditTests
///
/// Like ScreenshotTests this never calls XCTFail: a failing UI test spends ten
/// minutes collecting simulator diagnostics. Whatever could not be found is
/// recorded in the `problems` attachment instead.
@MainActor
final class NewcomerAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []
    private var metrics: [String] = []
    private var questions: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // No launch arguments: a fresh install, so onboarding is the first screen.
        app.launch()
    }

    func testFirstRunAndReturnVisit() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.5)
        onboardingPages()
        primer()
        tour()
        firstSession()
        homeAfterFirstSession()
        returnVisit()
        attachNotes()
    }

    // MARK: - Onboarding

    private func onboardingPages() {
        capture("01_onboarding_page1")
        tapButton("Continue")
        capture("02_onboarding_page2")
        tapButton("Continue")
        capture("03_onboarding_page3")
        tapButton("Continue")
        capture("04_skill_level_nothing_chosen")

        // The CTA is dimmed until a choice is made: does a tap or a swipe get past?
        tapButton("Continue")
        capture("05_skill_level_continue_while_disabled")
        app.swipeLeft()
        settle()
        capture("06_skill_level_after_swipe_left")

        tapButton("Brand new")
        capture("07_skill_level_brand_new_chosen")
        tapButton("Continue")
        settle(1.5)
        capture("08_trial_page")
        logFrame("trial CTA", app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "trial")).firstMatch)
        logFrame("trial Get Started exit", app.buttons["Get Started"].firstMatch)
        logFrame("trial Restore", app.buttons["Restore"].firstMatch)
        logFrame("trial Terms", app.links["Terms"].firstMatch)
        logFrame("trial Privacy", app.links["Privacy"].firstMatch)
        attachTree("trial_page")

        // Lost state: kill the app on the trial page and come back.
        app.terminate()
        app.launch()
        settle(2.5)
        capture("09_relaunch_mid_onboarding")
        // Skill choice is stored; the pages are not. Walk back to the trial page.
        for _ in 0..<4 {
            if app.buttons["Continue"].firstMatch.exists { tapButton("Continue", settleFor: 1.0) }
        }
        capture("10_relaunch_trial_page_again")
        tapButton("Get Started")
        settle(1.5)
    }

    // MARK: - Primer

    private func primer() {
        capture("11_primer_page1")
        attachTexts("primer_page1")
        logFrame("primer Back chevron", app.buttons["Previous page"].firstMatch)
        logFrame("primer Skip for now", app.buttons["Skip for now"].firstMatch)
        for page in 2...6 {
            tapButton("Continue", settleFor: 1.3)
            capture(String(format: "%02d_primer_page%d", 10 + page, page))
            attachTexts("primer_page\(page)")
        }
        // Last page: "Take your seat".
        tapButton("Take your seat", settleFor: 1.5)
    }

    // MARK: - Tour

    private func tour() {
        capture("17_tour_page1")
        attachTexts("tour_page1")
        for page in 2...4 {
            tapButton("Show me", settleFor: 1.3)
            capture(String(format: "%02d_tour_page%d", 16 + page, page))
            attachTexts("tour_page\(page)")
        }
        tapButton("Start my first session", settleFor: 2.0)
    }

    // MARK: - First Quick Session

    private func firstSession() {
        for number in 1...10 {
            let texts = visibleTexts()
            questions.append("Q\(number): \(texts.joined(separator: " | "))")
            if number == 1 {
                capture("21_session_q1")
                logFrame("session Close", app.buttons["Close"].firstMatch)
            }
            guard answerVisibleChoice() else { break }
            if number <= 3 || number == 7 { capture("22_session_q\(number)_answered") }
            // Exact labels: the tour card behind the cover reads "... what you need next".
            let advance = app.buttons.matching(
                NSPredicate(format: "label == %@ OR label == %@", "Next", "Finish")
            ).firstMatch
            guard advance.waitForExistence(timeout: 4) else {
                problems.append("no Next/Finish after Q\(number)")
                break
            }
            if number == 10 { capture("23_session_q10_answered") }
            advance.tap()
            settle(1.2)
        }
        capture("24_session_complete")
        attachTexts("session_complete")
        // The finale's cover dismisses back to the tour, which then calls onDone.
        for label in ["Done", "Back to Home", "Finish", "Close", "Continue"] {
            let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if button.exists { logFrame("complete button \(label)", button) }
        }
    }

    private func homeAfterFirstSession() {
        for label in ["Done", "Back to Home", "Close", "Finish"] {
            let button = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
            if button.exists {
                button.tap()
                settle(1.8)
                break
            }
        }
        capture("25_home_first_arrival")
        attachTexts("home_first_arrival")
        app.swipeUp()
        settle()
        capture("26_home_scrolled")
        attachTexts("home_scrolled")
        app.swipeDown()
        app.swipeDown()
        settle()
        logFrame("home Settings gear", app.buttons["Settings"].firstMatch)
        tapButton("Settings", settleFor: 1.5)
        capture("27_settings")
        attachTexts("settings")
        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap(); settle() }
    }

    // MARK: - Return visit

    private func returnVisit() {
        app.terminate()
        app.launch()
        settle(2.5)
        capture("28_return_home")
        attachTexts("return_home")
        // A second Get Started the same day: is it fresh or spent?
        if let card = firstButton(containing: "Get Started") {
            card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(1.8)
            capture("29_return_session_q1")
            attachTexts("return_session_q1")
        } else {
            problems.append("return visit: no Get Started card")
        }
    }

    // MARK: - Helpers

    private func firstButton(containing label: String) -> XCUIElement? {
        let match = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
        return match.waitForExistence(timeout: 5) ? match : nil
    }

    private func tapButton(_ label: String, settleFor seconds: TimeInterval = 1.4) {
        guard let match = firstButton(containing: label) else {
            problems.append("could not find button: \(label)")
            return
        }
        match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(seconds)
    }

    @discardableResult
    private func answerVisibleChoice() -> Bool {
        let height = max(app.windows.firstMatch.frame.height, 1)
        let excluded = ["Settings", "Back", "Next", "Next Question", "Finish", "Close"]
        let choice = app.buttons.allElementsBoundByIndex.first { element in
            let label = element.label
            return !label.isEmpty
                && !excluded.contains(label)
                && element.frame.midY > height * 0.20
                && element.frame.midY < height * 0.82
        }
        guard let choice else {
            problems.append("could not answer visible choice")
            return false
        }
        choice.press(forDuration: 0.1)
        settle(1.0)
        return true
    }

    private func visibleTexts() -> [String] {
        app.staticTexts.allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
    }

    private func logFrame(_ name: String, _ element: XCUIElement) {
        guard element.exists else {
            metrics.append("\(name): not found")
            return
        }
        let f = element.frame
        metrics.append("\(name): \(Int(f.width)) x \(Int(f.height)) pt at (\(Int(f.minX)), \(Int(f.minY)))")
    }

    private func settle(_ seconds: TimeInterval = 1.4) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTexts(_ name: String) {
        attachString("texts_\(name)", visibleTexts().joined(separator: "\n"))
    }

    private func attachTree(_ name: String) {
        attachString("tree_\(name)", app.debugDescription)
    }

    private func attachString(_ name: String, _ text: String) {
        let note = XCTAttachment(string: text)
        note.name = name
        note.lifetime = .keepAlways
        add(note)
    }

    private func attachNotes() {
        attachString("questions", questions.joined(separator: "\n"))
        attachString("metrics", metrics.joined(separator: "\n"))
        attachString("problems", problems.isEmpty ? "none" : problems.joined(separator: "\n"))
    }
}
