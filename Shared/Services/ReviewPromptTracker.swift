import Foundation
import StoreKit

enum AppStoreLinks {
    static let appStoreID = "6790052126"

    /// The write-a-review page. No storefront prefix: the App Store resolves
    /// the bare app id into the viewer's own storefront, and hardcoding one
    /// only risks sending a UK player to the US store.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    static let feedbackEmail = "jackwallner+m@gmail.com"
}

/// How the player last resolved the review funnel. Either terminal outcome
/// retires the prompt for good: we asked, they acted, we stop asking.
enum ReviewPromptOutcome: String, Sendable {
    case openedWriteReview
    case submittedFeedback
}

/// The review funnel's memory: when we last asked, what happened, and whether
/// the player has done enough for the ask to be fair.
///
/// The funnel itself: a positive moment (a finished drill) leads to "Enjoying
/// Mahj Trainer?" A yes leads to the App Store; a no leads to a feedback box
/// that mails us instead. Unhappy players never get pushed at a star rating,
/// which is the whole point of gating it.
@MainActor
enum ReviewPromptTracker {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount = "reviewPrompt.launchCount"
        static let firstOpen = "reviewPrompt.firstOpenDate"
        static let lastShown = "reviewPrompt.lastShownDate"
        static let outcome = "reviewPrompt.outcome"
        static let positiveMoments = "reviewPrompt.positiveMomentCount"
        static let softDefer = "reviewPrompt.softDefer"
    }

    /// Finished drills before we're willing to ask. Three is enough to know
    /// whether the app is any good.
    static let minimumPositiveMoments = 3
    static let minimumLaunchCount = 2
    /// After a "Not now", don't ask again for months.
    static let cooldownDays = 120
    /// After a "Maybe later" on the review pitch we fired `requestReview()`,
    /// which Apple often silently swallows. Short cooldown so that dead ask
    /// doesn't cost us the next one.
    static let softDeferCooldownDays = 30

    static var launchCount: Int {
        get { max(defaults.integer(forKey: Keys.launchCount), 0) }
        set { defaults.set(newValue, forKey: Keys.launchCount) }
    }

    static var positiveMomentCount: Int {
        get { max(defaults.integer(forKey: Keys.positiveMoments), 0) }
        set { defaults.set(newValue, forKey: Keys.positiveMoments) }
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

    static func recordPositiveMoment() {
        positiveMomentCount += 1
    }

    /// Eligibility for the enjoyment gate after a finished drill.
    static func shouldShowAfterPositiveMoment(now: Date = Date()) -> Bool {
        guard outcome == nil else { return false }
        guard positiveMomentCount >= minimumPositiveMoments else { return false }
        guard launchCount >= minimumLaunchCount else { return false }
        guard let last = lastShownDate else { return true }
        let days = defaults.bool(forKey: Keys.softDefer) ? softDeferCooldownDays : cooldownDays
        return now.timeIntervalSince(last) >= TimeInterval(days) * 86_400
    }

    static func markShown(now: Date = Date()) {
        lastShownDate = now
        defaults.set(false, forKey: Keys.softDefer)
    }

    /// They said yes, then "Maybe later": we fired `requestReview()` and Apple
    /// may well have shown nothing. Come back sooner than a hard dismissal.
    static func markSoftDeferred(now: Date = Date()) {
        lastShownDate = now
        defaults.set(true, forKey: Keys.softDefer)
    }

    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    static func markFeedbackSubmitted() {
        outcome = .submittedFeedback
        markShown()
    }

    /// Settings' "Reset Progress" should not un-retire a review we already got.
    static func resetForTesting() {
        [Keys.launchCount, Keys.firstOpen, Keys.lastShown, Keys.outcome, Keys.positiveMoments, Keys.softDefer]
            .forEach(defaults.removeObject(forKey:))
    }
}
