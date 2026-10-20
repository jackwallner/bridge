import Foundation
import StoreKit

enum AppStoreLinks {
    static let appStoreID = "6791026407"
    static let productURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!

    /// The write-a-review page. No storefront prefix: the App Store resolves
    /// the bare app id into the viewer's own storefront, and hardcoding one
    /// only risks sending a UK player to the US store.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    static let feedbackEmail = "jackwallner+b@gmail.com"
}

/// What the player did about a review. Only opening the write-review page
/// ends the passive asks: someone who sent feedback can still rate later.
enum ReviewPromptOutcome: String, Sendable {
    case openedWriteReview
    /// Written by the old in-app feedback sheet (before 1.3). Kept so
    /// those installs decode it; it no longer stops anything.
    case submittedFeedback
}

/// When the app may put Apple's own rating prompt on screen.
///
/// No question goes in front of it. An "Enjoying Bridge Trainer?" step that
/// sent only the yeses to a rating is review gating under App Review 5.6.1,
/// and the fleet's ratings come in high anyway, so the job is to ask early
/// and often enough inside Apple's limits: from the second launch on, at a
/// finished drill or challenge, at most once every 30 days. Apple shows the
/// prompt at most three times a year and decides each time; a call it
/// swallows costs nothing.
@MainActor
enum ReviewPromptTracker {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount = "reviewPrompt.launchCount"
        static let firstOpen = "reviewPrompt.firstOpenDate"
        static let lastShown = "reviewPrompt.lastShownDate"
        static let outcome = "reviewPrompt.outcome"
        // Retired with the enjoyment funnel; cleared by `resetForTesting`.
        static let positiveMoments = "reviewPrompt.positiveMomentCount"
        static let softDefer = "reviewPrompt.softDefer"
    }

    /// Not in the first session: a second cold start is the only tenure gate.
    static let minimumLaunchCount = 2
    /// Days between our calls. Paces the asks, not the player's answers.
    static let cooldownDays = 30

    static var launchCount: Int {
        get { max(defaults.integer(forKey: Keys.launchCount), 0) }
        set { defaults.set(newValue, forKey: Keys.launchCount) }
    }

    static var outcome: ReviewPromptOutcome? {
        get { defaults.string(forKey: Keys.outcome).flatMap(ReviewPromptOutcome.init(rawValue:)) }
        set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: Keys.outcome)
            } else {
                defaults.removeObject(forKey: Keys.outcome)
            }
        }
    }

    private static var lastShownDate: Date? {
        get { defaults.object(forKey: Keys.lastShown) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastShown) }
    }

    static func recordAppLaunch(now: Date = Date()) {
        if defaults.object(forKey: Keys.firstOpen) == nil {
            defaults.set(now, forKey: Keys.firstOpen)
        }
        launchCount += 1
    }

    /// Whether a positive moment right now may call `requestReview()`.
    static func shouldRequestReview(now: Date = Date()) -> Bool {
        guard outcome != .openedWriteReview else { return false }
        guard launchCount >= minimumLaunchCount else { return false }
        guard let last = lastShownDate else { return true }
        return now.timeIntervalSince(last) >= TimeInterval(cooldownDays) * 86_400
    }

    /// Recorded when the call is made: Apple may show nothing, and there is
    /// no answer to wait for.
    static func markShown(now: Date = Date()) {
        lastShownDate = now
    }

    /// Settings > Rate Bridge Trainer. The one thing that ends the asks.
    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    /// Settings' "Reset Progress" should not un-retire a review we already got.
    static func resetForTesting() {
        [Keys.launchCount, Keys.firstOpen, Keys.lastShown, Keys.outcome, Keys.positiveMoments, Keys.softDefer]
            .forEach(defaults.removeObject(forKey:))
    }
}
