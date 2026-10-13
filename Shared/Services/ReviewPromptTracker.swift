import Foundation

enum AppStoreLinks {
    static let appStoreID = "6791026407"

    /// The write-a-review page. No storefront prefix: the App Store resolves
    /// the bare app id into the viewer's own storefront, and hardcoding one
    /// only risks sending a UK player to the US store.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    /// The plain product page, for share text. The write-review URL above
    /// would drop a friend straight into a rating form for an app they have
    /// never opened.
    static let productURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!

    static let feedbackEmail = "jackwallner+b@gmail.com"
}

/// What the player did about a review. Only opening the review page ends the
/// passive asks: someone who sent feedback can still rate later.
enum ReviewPromptOutcome: String, Sendable {
    case openedWriteReview
    case submittedFeedback
}

/// When to call Apple's rating prompt. There is no question in front of it:
/// App Review 5.6.1 rejects an "Enjoying it?" gate that routes only happy
/// players to the store. A finished drill marks a positive moment, and the
/// next clear screen after it asks.
@MainActor
enum ReviewPromptTracker {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount = "reviewPrompt.launchCount"
        static let firstOpen = "reviewPrompt.firstOpenDate"
        static let lastShown = "reviewPrompt.lastShownDate"
        static let outcome = "reviewPrompt.outcome"
        static let positiveMoments = "reviewPrompt.positiveMomentCount"
        static let pendingMoment = "reviewPrompt.pendingPositiveMoment"
        /// Written by the old gate's "Maybe later". Only cleared now.
        static let softDefer = "reviewPrompt.softDefer"
    }

    /// Ask early: most installs are gone within a week. The only tenure gate
    /// is "not the first session", a second cold launch.
    static let minimumLaunchCount = 2
    /// Days between our calls. Apple shows the prompt at most three times a
    /// year per device and decides each time, so this only paces the asks.
    static let cooldownDays = 30

    static var launchCount: Int {
        get { max(defaults.integer(forKey: Keys.launchCount), 0) }
        set { defaults.set(newValue, forKey: Keys.launchCount) }
    }

    static var positiveMomentCount: Int {
        get { max(defaults.integer(forKey: Keys.positiveMoments), 0) }
        set { defaults.set(newValue, forKey: Keys.positiveMoments) }
    }

    static var hasPendingPositiveMoment: Bool {
        get { defaults.bool(forKey: Keys.pendingMoment) }
        set { defaults.set(newValue, forKey: Keys.pendingMoment) }
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

    static var lastShownDate: Date? {
        get { defaults.object(forKey: Keys.lastShown) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.lastShown)
            } else {
                defaults.removeObject(forKey: Keys.lastShown)
            }
        }
    }

    /// Call once per cold launch, from the app's init.
    static func recordAppLaunch(now: Date = Date()) {
        if defaults.object(forKey: Keys.firstOpen) == nil {
            defaults.set(now, forKey: Keys.firstOpen)
        }
        launchCount += 1
    }

    static func recordPositiveMoment() {
        positiveMomentCount += 1
        hasPendingPositiveMoment = true
    }

    static func canRequestReview(hasCompletedSetup: Bool, now: Date = Date()) -> Bool {
        guard hasCompletedSetup else { return false }
        guard outcome != .openedWriteReview else { return false }
        guard launchCount >= minimumLaunchCount else { return false }
        guard let last = lastShownDate else { return true }
        return now.timeIntervalSince(last) >= TimeInterval(cooldownDays) * 86_400
    }

    /// Eligible and a positive moment is still waiting. An ask that finds the
    /// screen busy leaves the moment pending, so the next one can ask.
    static func shouldRequestAfterPositiveMoment(hasCompletedSetup: Bool, now: Date = Date()) -> Bool {
        guard hasPendingPositiveMoment else { return false }
        return canRequestReview(hasCompletedSetup: hasCompletedSetup, now: now)
    }

    static func markShown(now: Date = Date()) {
        lastShownDate = now
        hasPendingPositiveMoment = false
    }

    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    /// Feedback never ends the asks, and never overwrites a review-page stop.
    static func markFeedbackSubmitted() {
        if outcome != .openedWriteReview {
            outcome = .submittedFeedback
        }
        markShown()
    }

    static func resetForTesting() {
        [Keys.launchCount, Keys.firstOpen, Keys.lastShown, Keys.outcome,
         Keys.positiveMoments, Keys.pendingMoment, Keys.softDefer]
            .forEach(defaults.removeObject(forKey:))
    }
}
