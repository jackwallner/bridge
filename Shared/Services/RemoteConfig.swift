import Foundation

import RevenueCat

/// Everything RevenueCat can change without a release, read from the current
/// offering's metadata (a running Experiment's variant included), the Vitals
/// and Mahj pattern. Every variant ships in the binary; a missing or unknown
/// value is the control, which is what the app shipped before this existed.
/// Keys that a switch reads must be set the same on every offering, or an
/// Experiment arm would flip them as a side effect.
///
/// DEBUG builds can pin any key for captures: `-bridge.rc.<key> <value>`.

/// The trial button's wording. Onboarding uses sentence case, the paywall
/// title case, as Bridge has always shipped them.
enum TrialCTA: String, CaseIterable, Sendable {
    static let metadataKey = "trial_cta"

    /// Control: "Start 7-day free trial", as shipped since 1.0.
    case sevenDay = "seven_day"
    case my
    case your

    enum Surface {
        case onboarding, paywall
    }

    static func from(metadata: [String: Any]?) -> TrialCTA {
        RemoteConfig.value(metadataKey, in: metadata, default: .sevenDay)
    }

    func title(_ surface: Surface) -> String {
        switch (self, surface) {
        case (.sevenDay, .onboarding): return String(localized: "Start 7-day free trial")
        case (.sevenDay, .paywall): return String(localized: "Start 7-Day Free Trial")
        case (.my, .onboarding): return String(localized: "Start my free trial")
        case (.my, .paywall): return String(localized: "Start My Free Trial")
        case (.your, .onboarding): return String(localized: "Start your free trial")
        case (.your, .paywall): return String(localized: "Start Your Free Trial")
        }
    }
}

/// The plan the onboarding trial button buys, both with the 7-day free trial.
/// Yearly is the control: Aug 11 (1.2.0) moved the button to monthly and at
/// 3 months that lost $0.64 per new customer against the apps that kept their
/// plan (2026-11-24 change-impact read), so it went back to yearly. `monthly`
/// in the offering metadata brings the monthly button back without a release.
/// The paywall leads with yearly either way.
enum OnboardingPlanArm: String, CaseIterable, Sendable {
    static let metadataKey = "onboarding_plan"

    case yearly
    case monthly

    static func from(metadata: [String: Any]?) -> OnboardingPlanArm {
        RemoteConfig.value(metadataKey, in: metadata, default: .yearly)
    }

    var plan: PaywallPlan { self == .monthly ? .monthly : .yearly }
}

/// Remote off switches, for what is worth pausing without a release. On
/// unless the metadata says "off".
enum RemoteSwitch: String, CaseIterable, Sendable {
    /// Apple's rating prompt after a good drill.
    case ratingPrompt = "rating_prompt"
    /// The daily and monthly challenge. Nothing reads it yet: the challenge
    /// lands in phase 2 and must gate its Home card and deep link on this.
    case challenge = "challenge"
    /// The one-tap trial sheet rising on its own after a good result.
    /// Tapped Bridge+ cards still open it when this is off.
    case trialOffer = "trial_offer"
}

enum RemoteConfig {
    /// The value for `key`, or `fallback` when it is missing, not a string,
    /// or not one of the shipped variants.
    static func value<T: RawRepresentable>(_ key: String, in metadata: [String: Any]?, default fallback: T) -> T
    where T.RawValue == String {
        #if DEBUG
        if let pinned = launchOverride(key).flatMap(T.init(rawValue:)) { return pinned }
        #endif
        guard let raw = metadata?[key] as? String else { return fallback }
        return T(rawValue: raw) ?? fallback
    }

    static func isOn(_ remoteSwitch: RemoteSwitch, in metadata: [String: Any]?) -> Bool {
        #if DEBUG
        if let pinned = launchOverride(remoteSwitch.rawValue) { return pinned != "off" }
        #endif
        return (metadata?[remoteSwitch.rawValue] as? String) != "off"
    }

    #if DEBUG
    private static func launchOverride(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-bridge.rc.\(key)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    #endif
}

extension SubscriptionService {
    private var remoteMetadata: [String: Any]? { currentOffering?.metadata }

    var trialCTAArm: TrialCTA { TrialCTA.from(metadata: remoteMetadata) }

    var onboardingPlanArm: OnboardingPlanArm { OnboardingPlanArm.from(metadata: remoteMetadata) }

    /// The plan the onboarding trial button buys (`onboarding_plan`, yearly unless set).
    var onboardingPlan: PaywallPlan { onboardingPlanArm.plan }

    func trialCTA(_ surface: TrialCTA.Surface, plan: PaywallPlan? = nil) -> String {
        let plan = plan ?? (surface == .onboarding ? onboardingPlan : .yearly)
        return isEligibleForIntroOffer(plan) ? trialCTAArm.title(surface) : String(localized: "Join \(Membership.name)")
    }

    func isOn(_ remoteSwitch: RemoteSwitch) -> Bool { RemoteConfig.isOn(remoteSwitch, in: remoteMetadata) }

    /// Every variant this customer saw, for reading tests by attribute too.
    var remoteVariantAttributes: [String: String] {
        [TrialCTA.metadataKey: trialCTAArm.rawValue,
         OnboardingPlanArm.metadataKey: onboardingPlanArm.rawValue]
    }
}
