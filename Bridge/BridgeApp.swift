import SwiftUI

@main
struct BridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptions)
                .environmentObject(progress)
                .environmentObject(settings)
                .environmentObject(router)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onAppear {
                    subscriptions.start()
                    ReviewPromptTracker.recordAppLaunch()
                    ConversionDiagnostics.recordAppOpen()
                    #if DEBUG
                    if RevenueCatProbe.isEnabled {
                        // Same entry point the real paywall screens call, so
                        // what this proves is the actual path, not a parallel one.
                        subscriptions.trackPaywallImpression(id: RevenueCatProbe.impressionID)
                    }
                    #endif
                }
        }
    }
}
