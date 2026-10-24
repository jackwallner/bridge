import SwiftUI
import UIKit
import UserNotifications

enum AppDestination: Hashable {
    case gameNightPrepSession
    case endlessPicker
    case bridgeMinute
    case gameNightPrep
    case timedChallenge
    case review

    /// Free destinations open for everyone; the rest wait behind the paywall.
    /// Phase 2's challenge is the first free one.
    var isFree: Bool { false }
}

/// A locked action survives the paywall, then is consumed once on dismissal.
struct UpgradeIntent<Destination> {
    var destination: Destination?

    mutating func consume(isMember: Bool) -> Destination? {
        defer { destination = nil }
        return isMember ? destination : nil
    }
}

enum AppNotification {
    static let routeKey = "bridge.route"
    static let gameNightPrepValue = "game-night-prep"
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published private(set) var pendingDestination: AppDestination?

    func route(to destination: AppDestination) {
        pendingDestination = destination
    }

    func consumePendingDestination() -> AppDestination? {
        defer { pendingDestination = nil }
        return pendingDestination
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.userInfo[AppNotification.routeKey] as? String
            == AppNotification.gameNightPrepValue {
            Task { @MainActor in
                AppRouter.shared.route(to: .gameNightPrepSession)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
