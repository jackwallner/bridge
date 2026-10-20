import AppTrackingTransparency
import FBSDKCoreKit
import Foundation
import RevenueCat
import UIKit

/// Meta (Facebook and Instagram) ad measurement. Prep for a paid test, so it
/// is OFF until a Meta app exists.
///
/// Off means: no SDK start, no ATT prompt, nothing sent. It turns on when
/// `META_APP_ID` and `META_CLIENT_TOKEN` are filled in `project.yml`, which
/// lands them in Info.plist as `FacebookAppID` / `FacebookClientToken`. Turn
/// it on in the same build that updates the App Store privacy labels.
///
/// The jobs are split three ways (`.claude/rules/meta-ads.md`):
/// - This SDK: installs, app opens and SKAdNetwork/AEM. Purchase auto-logging
///   stays off, so no purchase is counted twice.
/// - RevenueCat's Meta Ads integration: Subscribe events (conversions,
///   renewals), sent server to server.
/// - The trial relay (a Supabase function in the Mahj repo, not ported here):
///   StartTrial, only once the trial is still on 15 minutes after it
///   began. Meta otherwise learns to find people who start a trial and cancel
///   straight away.
///
/// Never runs on a simulator: an agent run must not report installs to Meta.
@MainActor
enum MetaAds {
    private static var sdkStarted = false

    /// True when this build has a Meta app to report to.
    static var isEnabled: Bool {
        #if DEBUG
        // Captures only: shows the real ATT prompt without a Meta app.
        if ProcessInfo.processInfo.arguments.contains("-bridge.previewMetaATT") { return true }
        #endif
        // Never on a simulator: the SDK does not start there, and the alert
        // would land in every App Store screenshot run.
        guard !isSimulator else { return false }
        return !infoString("FacebookAppID").isEmpty && !infoString("FacebookClientToken").isEmpty
    }

    /// From `application(_:didFinishLaunchingWithOptions:)`. Meta requires
    /// this before any other SDK call.
    static func start(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard isEnabled, !sdkStarted, !isSimulator else { return }
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        // Info.plist already says no; this pins it in case Meta's remote
        // config flips the default. RevenueCat reports purchases.
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = trackingAuthorized
        sdkStarted = true
    }

    /// Every time the app becomes active (auto-logging is off, so the SDK
    /// does not do this itself).
    static func activateApp() {
        guard sdkStarted else { return }
        AppEvents.shared.activateApp()
    }

    /// Right after `Purchases.configure`. Gives RevenueCat the identifiers
    /// Meta matches events on: Meta's anonymous id, the IDFA when ATT allows
    /// it, IDFV and IP. `meta_extinfo` carries the device context Meta's
    /// Conversions API requires with every app event, which the trial relay
    /// reads back off the customer.
    static func linkRevenueCat() {
        guard sdkStarted, Purchases.isConfigured else { return }
        Purchases.shared.attribution.setFBAnonymousID(AppEvents.shared.anonymousID)
        Purchases.shared.attribution.collectDeviceIdentifiers()
        Purchases.shared.attribution.setAttributes(["meta_extinfo": extinfo])
    }

    /// Whether Home should put up Apple's tracking prompt now.
    static var shouldAskForTracking: Bool {
        isEnabled && ATTrackingManager.trackingAuthorizationStatus == .notDetermined
    }

    /// Apple's prompt, once. Asked on Home after the first finished practice,
    /// never at launch or in onboarding: a player who has not used the app
    /// yet has no reason to say yes.
    /// Nothing in the app depends on the answer.
    static func requestTracking() async {
        guard shouldAskForTracking else { return }
        let status = await askApple()
        if sdkStarted {
            Settings.shared.isAdvertiserIDCollectionEnabled = status == .authorized
        }
        // Refreshes $idfa and $attConsentStatus on the customer, which the
        // relay checks before sending anything.
        if Purchases.isConfigured {
            Purchases.shared.attribution.collectDeviceIdentifiers()
        }
    }

    /// Outside the main actor: ATT answers on a background queue, which traps
    /// a main-actor-isolated completion handler under Swift 6.
    nonisolated private static func askApple() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { continuation.resume(returning: $0) }
        }
    }

    private static var trackingAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private static func infoString(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }

    /// Meta's 16-slot `extinfo` array for app events, as a JSON string:
    /// version, bundle id, build, version, OS, model, locale, timezone
    /// abbreviation, carrier, screen width, height, density, CPU cores,
    /// storage size and free storage in GB (left empty: reading disk space is
    /// an Apple required-reason API with no reason that covers sending it to
    /// an ad network), timezone.
    static var extinfo: String {
        let bundle = Bundle.main
        let screen = UIScreen.main
        let timeZone = TimeZone.current
        let slots: [String] = [
            "i2",
            bundle.bundleIdentifier ?? "",
            bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            UIDevice.current.systemVersion,
            deviceModel,
            Locale.current.identifier,
            timeZone.abbreviation() ?? "",
            "",
            String(Int(screen.nativeBounds.width)),
            String(Int(screen.nativeBounds.height)),
            String(format: "%.2f", screen.scale),
            String(ProcessInfo.processInfo.activeProcessorCount),
            "",
            "",
            timeZone.identifier,
        ]
        let data = (try? JSONSerialization.data(withJSONObject: slots)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
