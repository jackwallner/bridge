import XCTest

/// Persona audit: a tired, busy player pulled away mid-task who returns later
/// and expects their place and credit to survive.
///
/// Not part of the Bridge scheme; run through the `Screenshots` scheme:
/// `gh-sim test --scheme Screenshots --only BridgeScreenshots/InterruptedReturnAuditTests`.
///
/// Like `ScreenshotTests` it never XCFails on a missing element (a failing UI
/// test spends ten minutes collecting simulator diagnostics first). Each test
/// writes what it saw to a `notes_*` text attachment and takes numbered
/// screenshots, so one run answers every flow. "Kill" is `terminate()` then
/// `launch()`, which is how iOS reclaims a backgrounded app.
///
/// Test names sort in run order: A needs a clean first run, so it goes first.
@MainActor
final class InterruptedReturnAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []
    private var shots = 0

    private let onboarded = [
        "-progress.hasOnboarded", "YES",
        "-bridge.hasReadPrimer", "YES",
        "-bridge.skillLevel", "some",
    ]
    private let member = ["-subscription.localProOverride", "YES"]
    /// Last, so it is not read as the key of another pair.
    private let quiet = ["-bridge.suppressWhatsNew"]

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        notes = []
        shots = 0
    }

    // MARK: - A. A paying member is interrupted right after the trial page

    /// First run with the Bridge+ override on, which is what the player looks
    /// like the moment after Apple's sheet confirms. Brand new skill, so the
    /// primer follows the trial page. Kill in the primer and see where the
    /// relaunch lands.
    func testA_PaidMemberInterruptedInPrimer() {
        launch(member)
        note("A first screen has value page 1: \(has("Make it stick between games"))")
        capture("A01_first_launch")

        for _ in 0..<3 { tapButton("Continue") }
        note("A skill page showing: \(has("Where are you starting from?"))")
        tapButton(startingWith: "Brand new")
        capture("A02_skill_page_brand_new_chosen")

        tapButton("Continue")
        note("A trial page title for a member: \(has("Bridge+ is on your account"))")
        note("A trial page primary button label: \(buttonExists("Continue") ? "Continue" : "(other)")")
        capture("A03_trial_page_member")

        tapButton("Continue")
        note("A primer page 1 showing: \(app.buttons["Skip for now"].exists)")
        capture("A04_primer_page1")

        tapButton("Continue")
        tapButton("Continue")
        let counterBefore = firstCounter()
        note("A primer counter before interruption: \(counterBefore)")
        capture("A05_primer_page3_before_interruption")
        attachTree("A05_primer_page3")

        background(seconds: 5)
        note("A primer counter after home button: \(firstCounter())")
        capture("A06_primer_after_home_button")

        kill()
        note("A after kill, value page 1 showing again: \(has("Make it stick between games"))")
        note("A after kill, primer visible: \(app.buttons["Skip for now"].exists)")
        capture("A07_relaunch_after_kill_in_primer")
        attachTree("A07_relaunch")

        // How far is the way back to the primer?
        var taps = 0
        for _ in 0..<3 { tapButton("Continue"); taps += 1 }
        let skillShown = has("Where are you starting from?")
        note("A skill page again after \(taps) taps: \(skillShown)")
        note("A skill choice remembered (Continue enabled without a pick): \(app.buttons["Continue"].isEnabled)")
        capture("A08_skill_page_after_relaunch")
        tapButton("Continue"); taps += 1
        capture("A09_trial_page_after_relaunch")
        tapButton("Continue"); taps += 1
        note("A taps from relaunch back to primer page 1: \(taps); primer showing: \(app.buttons["Skip for now"].exists)")
        capture("A10_primer_page1_again")
        flushNotes("A")
    }

    // MARK: - B. Endless Practice: Back, Finish, and what counts

    func testB_EndlessBackExitAndFinishCredit() {
        launch(onboarded + member)
        waitForHome()
        let startChips = chips()
        note("B chips at start: \(startChips)")
        capture("B01_home_start")

        guard open("Endless") else { flushNotes("B"); return }
        capture("B02_endless_picker_before")
        note("B picker answered line before: \(firstLabel(containing: "answered"))")
        guard open("Count the Points") else { flushNotes("B"); return }
        capture("B03_run_question1")

        for round in 1...3 {
            answerVisibleChoice()
            if round == 3 { capture("B04_third_answer_shown") }
            if round < 3 { tapAdvance() }
        }
        note("B status line after 3 answers: \(firstLabel(containing: "correct"))")
        let finishButton = app.buttons["Finish"].firstMatch.exists
        note("B toolbar Finish button present mid-run: \(finishButton)")

        // The natural exit: the Back chevron. Is there any confirmation?
        tapBackChevron()
        let dialog = app.alerts.count + app.sheets.count
        note("B Back mid-run: alerts/sheets after tap = \(dialog), picker showing = \(has("Endless Practice"))")
        capture("B05_picker_after_back_mid_run")
        note("B picker answered line after Back: \(firstLabel(containing: "answered"))")

        goHome()
        let afterBack = chips()
        note("B chips after answering 3 and leaving by Back: \(afterBack)")
        note("B chips unchanged after Back: \(afterBack == startChips)")
        capture("B06_home_after_back_exit")

        // Now the same thing, but ending with Finish.
        guard open("Endless"), open("Count the Points") else { flushNotes("B"); return }
        answerVisibleChoice()
        if app.buttons["Finish"].firstMatch.waitForExistence(timeout: 3) {
            app.buttons["Finish"].firstMatch.tap()
        }
        settle(0.8)
        note("B complete screen after Finish: \(has("right"))")
        capture("B07_complete_after_finish")
        // Done at once: the rating prompt waits three seconds on this screen.
        if app.buttons["Done"].firstMatch.exists { app.buttons["Done"].firstMatch.tap() }
        settle(0.8)
        goHome()
        let afterFinish = chips()
        note("B chips after one answer ended with Finish: \(afterFinish)")
        capture("B08_home_after_finish")

        kill()
        waitForHome()
        note("B chips after kill: \(chips())")
        capture("B09_home_after_kill")
        flushNotes("B")
    }

    // MARK: - C. Flashcard deck, killed after three cards

    func testC_FlashcardDeckKilled() {
        launch(onboarded)
        waitForHome()
        guard open("The Card Room"), open("Meet the Game") else { flushNotes("C"); return }
        let before = firstCounter()
        let firstCard = firstLabel(containing: "Four suits")
        note("C deck counter on entry: \(before); first card visible: \(firstCard != "(none)")")
        capture("C01_deck_start")

        for _ in 0..<3 { knewIt() }
        let mid = firstCounter()
        note("C deck counter after three cards graded: \(mid)")
        capture("C02_deck_three_down")
        attachTree("C02_deck")

        kill()
        waitForHome()
        guard open("The Card Room") else { flushNotes("C"); return }
        capture("C03_card_room_after_kill")
        guard open("Meet the Game") else { flushNotes("C"); return }
        let after = firstCounter()
        note("C deck counter after kill and reopen: \(after)")
        note("C first card is again 'Four suits': \(firstLabel(containing: "Four suits") != "(none)")")
        capture("C04_deck_after_kill")
        flushNotes("C")
    }

    // MARK: - D. A room drill killed after three answers

    func testD_RoomDrillKilled() {
        launch(onboarded)
        waitForHome()
        guard open("The Auction Room"), open("Name Your Opening") else { flushNotes("D"); return }
        let first = firstCounter()
        note("D drill counter on entry: \(first)")
        capture("D01_drill_start")
        for round in 1...3 {
            answerVisibleChoice()
            if round == 3 { capture("D02_third_answer_shown") }
            tapAdvance()
        }
        note("D drill counter before kill: \(firstCounter())")
        capture("D03_before_kill_hand4")
        attachTree("D03_hand4")

        kill()
        waitForHome()
        guard open("The Auction Room") else { flushNotes("D"); return }
        capture("D04_room_after_kill")
        guard open("Name Your Opening") else { flushNotes("D"); return }
        note("D drill counter after kill and reopen: \(firstCounter())")
        capture("D05_drill_after_kill")
        flushNotes("D")
    }

    // MARK: - E. All ten Quick Session answers given, Finish never tapped

    func testE_QuickSessionAnsweredNotFinished() {
        launch(onboarded)
        waitForHome()
        let startChips = chips()
        note("E chips at start: \(startChips)")
        note("E Get Started card offered: \(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Get Started")).firstMatch.exists)")
        capture("E01_home_start")
        guard open("Get Started") else { flushNotes("E"); return }
        let total = firstCounter()
        note("E session counter on entry: \(total)")

        for round in 1...10 {
            answerVisibleChoice()
            if round < 10 {
                tapAdvance()
            } else {
                note("E last answer shown, button reads: \(app.buttons["Finish"].exists ? "Finish" : "(other)")")
                capture("E02_tenth_answer_before_finish")
            }
        }

        // Pulled away on the last screen: the answer is in, Finish is not.
        kill()
        waitForHome()
        let after = chips()
        note("E chips after kill with 10 of 10 answered: \(after)")
        note("E chips unchanged: \(after == startChips)")
        note("E Get Started card still offered: \(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Get Started")).firstMatch.exists)")
        note("E 'Today's session is done' shown: \(has("Today's session is done"))")
        capture("E03_home_after_kill")
        if open("Get Started") {
            note("E session counter after kill: \(firstCounter())")
            capture("E04_new_session_after_kill")
        }
        flushNotes("E")
    }

    // MARK: - Lifecycle

    private func launch(_ args: [String]) {
        app.launchArguments = args + quiet
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    /// The system reclaiming a backgrounded app: no chance to save anything.
    private func kill() {
        note("-- kill and relaunch")
        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    private func background(seconds: TimeInterval) {
        note("-- home button for \(Int(seconds))s")
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: seconds)
        app.activate()
        settle()
    }

    // MARK: - Reading the screen

    private func has(_ text: String) -> Bool {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.exists
    }

    private func buttonExists(_ label: String) -> Bool { app.buttons[label].firstMatch.exists }

    private func firstLabel(containing part: String) -> String {
        let predicate = NSPredicate(format: "label CONTAINS %@", part)
        for query in [app.staticTexts, app.buttons, app.otherElements] {
            let match = query.matching(predicate).firstMatch
            if match.exists { return match.label }
        }
        return "(none)"
    }

    /// The "3 of 10", "Hand 4 of 6", "2 of 7 down" style progress label.
    private func firstCounter() -> String {
        let predicate = NSPredicate(format: "label MATCHES %@", ".*[0-9]+ of [0-9]+.*")
        let match = app.staticTexts.matching(predicate).firstMatch
        return match.exists ? match.label : "(no counter)"
    }

    private func chips() -> String {
        let match = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "drills done")).firstMatch
        return match.exists ? match.label : "(chips not found)"
    }

    private var atHome: Bool {
        app.staticTexts.matching(NSPredicate(format: "label == %@", "THE ROOMS")).firstMatch.exists
    }

    private func waitForHome() {
        let rooms = app.staticTexts.matching(NSPredicate(format: "label == %@", "THE ROOMS")).firstMatch
        if !rooms.waitForExistence(timeout: 15) {
            note("(Home did not show THE ROOMS within 15s)")
        }
        settle(0.5)
    }

    // MARK: - Driving the screen

    private func tapButton(_ label: String) {
        let button = app.buttons[label].firstMatch
        guard button.waitForExistence(timeout: 6) else {
            note("(could not find button \(label))")
            return
        }
        button.tap()
        settle(0.9)
    }

    private func tapButton(startingWith label: String) {
        let match = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
        guard match.waitForExistence(timeout: 6) else {
            note("(could not find button starting with \(label))")
            return
        }
        match.tap()
        settle(0.9)
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        note("(could not open \(label))")
        return false
    }

    private func tapBackChevron() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists { back.tap() }
        settle(0.8)
    }

    private func goHome() {
        for _ in 0..<4 {
            if atHome { return }
            let done = app.buttons["Done"].firstMatch
            if done.exists { done.tap(); settle(0.6); continue }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    /// Presses the first answer-looking button in the middle band of the
    /// screen. Reads ONE snapshot: walking live queries by index failed with
    /// "No matches found for Element at index N" whenever a row came or went.
    private func answerVisibleChoice() {
        let height = max(app.windows.firstMatch.frame.height, 1)
        let excluded: Set<String> = [
            "Settings", "Back", "Next", "Next Question", "Next Hand", "Next Play",
            "Finish", "Close", "Done", "Endless Practice",
        ]
        let choice = visibleButtons().first { button in
            !button.label.isEmpty
                && !excluded.contains(button.label)
                && button.frame.midY > height * 0.20
                && button.frame.midY < height * 0.82
        }
        guard let choice else {
            note("(no answer choice found)")
            return
        }
        let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        origin.withOffset(CGVector(dx: choice.frame.midX, dy: choice.frame.midY))
            .press(forDuration: 0.1)
        settle(0.8)
    }

    private func visibleButtons() -> [(label: String, frame: CGRect)] {
        guard let root = try? app.snapshot() else { return [] }
        var found: [(label: String, frame: CGRect)] = []
        func walk(_ element: any XCUIElementSnapshot) {
            if element.elementType == .button { found.append((element.label, element.frame)) }
            for child in element.children { walk(child) }
        }
        walk(root)
        return found
    }

    private func tapAdvance() {
        let next = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Next")).firstMatch
        guard next.waitForExistence(timeout: 3) else {
            note("(no Next button)")
            return
        }
        next.tap()
        settle(0.8)
    }

    /// Flip the top flashcard, then throw it right ("knew it").
    private func knewIt() {
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(1.0)
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.5))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: to)
        settle(1.2)
    }

    private func settle(_ seconds: TimeInterval = 1.2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Evidence

    private func note(_ line: String) {
        notes.append(line)
        NSLog("AUDIT %@", line)
    }

    private func capture(_ name: String) {
        shots += 1
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

    private func flushNotes(_ tag: String) {
        let text = XCTAttachment(string: notes.joined(separator: "\n"))
        text.name = "notes_\(tag)"
        text.lifetime = .keepAlways
        add(text)
    }
}
