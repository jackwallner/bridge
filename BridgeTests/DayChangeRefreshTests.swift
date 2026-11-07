import Combine
import UIKit
import XCTest

@testable import Bridge

/// Home reads "today's session is done" and the streak from `ProgressStore`
/// against the clock. Nothing published changes at midnight, so a Home left
/// open overnight kept yesterday's state until something else changed.
@MainActor
final class DayChangeRefreshTests: XCTestCase {
    func testMidnightRedrawsEverythingThatReadsProgress() {
        let progress = ProgressStore(defaults: UserDefaults(suiteName: "DayChangeRefreshTests.\(UUID().uuidString)")!)
        let redraw = expectation(description: "a new day redraws Home")
        redraw.assertForOverFulfill = false
        let watch = progress.objectWillChange.sink { redraw.fulfill() }
        defer { watch.cancel() }

        NotificationCenter.default.post(name: UIApplication.significantTimeChangeNotification, object: nil)

        wait(for: [redraw], timeout: 2)
    }
}
