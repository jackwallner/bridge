import UserNotifications
import XCTest

@testable import Bridge

/// A switched-on reminder toggle is saved before iOS answers the permission
/// alert, so a kill while the alert is up left the toggle on with nothing
/// scheduled and nothing that would ever ask again. Launch and every return
/// to the foreground now reconcile the toggles with iOS's answer.
@MainActor
final class ReminderReconcileTests: XCTestCase {
    func testAnUnansweredPermissionIsAskedAgain() {
        XCTAssertEqual(AppSettings.reminderRepair(for: .notDetermined), .ask,
                       "a kill during the permission alert would leave the toggle on with nothing scheduled")
    }

    func testAnAllowedPermissionPutsTheRequestBack() {
        for status: UNAuthorizationStatus in [.authorized, .provisional, .ephemeral] {
            XCTAssertEqual(AppSettings.reminderRepair(for: status), .schedule, "\(status.rawValue)")
        }
    }

    /// Notifications turned off in iOS Settings keep the player's choice, so
    /// turning them back on brings the reminder back on the next return.
    func testADeniedPermissionKeepsTheToggleAndWaits() {
        XCTAssertEqual(AppSettings.reminderRepair(for: .denied), .wait)
    }

    /// The reconcile reads iOS's answer in a completion handler formed on the
    /// main actor, which iOS calls on its own queue. Under Swift 6 a closure
    /// wrongly inferred main-actor isolated traps there, which would crash
    /// every launch with a reminder on. Running the real call proves it does not.
    func testReconcileReadsTheSettingsWithoutAnIsolationTrap() {
        let store = UserDefaults(suiteName: "ReminderReconcileTests.\(UUID().uuidString)")!
        store.set(true, forKey: "settings.reminderEnabled")
        let settings = AppSettings(defaults: store)
        settings.reconcileReminders()
        let answered = expectation(description: "iOS answered")
        UNUserNotificationCenter.current().getNotificationSettings { _ in answered.fulfill() }
        wait(for: [answered], timeout: 10)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    }
}
