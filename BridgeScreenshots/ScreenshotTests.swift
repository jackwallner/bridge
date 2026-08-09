import XCTest

/// Captures the App Store screenshot set from the real app, on whatever
/// destination `xcodebuild test` is pointed at. Exists because the iPad shots
/// have to be re-captured whenever a drill layout changes, and re-shooting six
/// screens by hand is how you end up shipping a stale set.
///
/// Run: scripts/capture-screenshots.sh <udid> <out-dir> [prefix]
///
/// Not part of the Bridge scheme's test action — it lives on its own
/// `Screenshots` scheme so the unit-test loop stays fast.
///
/// The test never fails on a missing element. A hard XCTFail makes Xcode spend
/// ten minutes collecting simulator diagnostics before it reports anything,
/// which turns every navigation typo into a very slow question. Instead it
/// records what it could not find and attaches the element tree, so one run
/// tells you both what you got and why the rest is missing.
@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // The `-key value` form lands in UserDefaults' argument domain, so the
        // app boots past onboarding without a debug hook in shipping code.
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-bridge.hasReadPrimer", "YES",
            "-bridge.skillLevel", "some",
        ]
        // The What's New sheet fires on the first launch after a version bump
        // and covers Home. Marking the CURRENT version as already seen is what
        // suppresses it — any other value still counts as an upgrade — so the
        // capture script passes the real marketing version in.
        if let version = ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        app.launch()
    }

    func testCaptureAppStoreSet() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("05_home")
        attachTree("home")

        if open("Get Started") {
            capture("01_quick_session")
        }
        home()

        if open("The Auction Room"), open("Name Your Opening") {
            capture("02_opening")
        }
        home()

        if open("The Defense Room"), open("Lead or Hold?") {
            capture("03_lead_or_hold")
        }
        home()

        if open("The Declarer Room"), open("Choose the Card") {
            capture("04_declarer")
        }
        home()

        if open("The Card Room") {
            capture("06_card_room")
        }

        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    // MARK: - Navigation

    /// The What's New sheet fires on the first launch after a version bump and
    /// covers Home completely. Pinning `whatsnew.lastSeenVersion` from the
    /// launch arguments would mean hardcoding the marketing version here and
    /// re-breaking capture on every release, so just dismiss it.
    private func dismissWhatsNew() {
        // Belt and braces for a version the script could not resolve. Dismissing
        // does not mark the release seen, so the sheet returns every time Home
        // reappears; the launch argument above is the real fix.
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    /// Taps the first hittable element whose label starts with `label`.
    /// Home's cards are NavigationLinks with stacked title + subtitle, so the
    /// accessibility label is the whole card, not just the title.
    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            // Tap the centre of the frame rather than the element. SwiftUI
            // cards report isHittable false often enough that trusting it costs
            // a whole capture run, and a coordinate tap lands the same place.
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    /// Pops back to the root, recognising Home by its Get Started card.
    ///
    /// Do NOT just tap navigation-bar button 0 until it runs out: on Home that
    /// button is the Settings gear, so the extra tap opens Settings, and every
    /// later coordinate tap then lands on the Settings sheet while the elements
    /// underneath still answer queries. That failure looks exactly like a
    /// mislabelled drill row, which is a slow thing to debug.
    private func home() {
        for _ in 0..<4 {
            if atHome { return }
            let done = app.buttons["Done"].firstMatch
            if done.exists {
                done.tap()
                settle(0.6)
                continue
            }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    private var atHome: Bool {
        app.staticTexts.matching(NSPredicate(format: "label == %@", "THE ROOMS")).firstMatch.exists
    }

    /// Let the push transition and any entrance animation finish before the
    /// shutter: a mid-transition frame is a blurred, half-offset screenshot.
    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capture

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTree(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree_\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
