import SwiftUI

@main
struct BridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Once per cold launch; the rating prompt waits for the second.
        ReviewPromptTracker.recordAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptions)
                .environmentObject(progress)
                .environmentObject(settings)
                .environmentObject(router)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onChange(of: scenePhase) { _, phase in
                    // iOS rarely cold-launches an app, so a report queued
                    // offline also retries every time the app comes back.
                    guard phase == .active else { return }
                    Task { await FeedbackService.shared.flushPending() }
                    MetaAds.activateApp()
                }
                .onAppear {
                    subscriptions.start()
                    ConversionDiagnostics.recordAppOpen()
                    Task { await FeedbackService.shared.flushPending() }
                    #if DEBUG
                    if RevenueCatProbe.isEnabled {
                        // Same entry point the real paywall screens call, so
                        // what this proves is the actual path, not a parallel one.
                        subscriptions.trackPaywallImpression(id: RevenueCatProbe.impressionID)
                        if RevenueCatProbe.wantsPurchase {
                            Task {
                                await subscriptions.loadOfferings()
                                let package = subscriptions.currentOffering?.availablePackages.first
                                // Logged rather than asserted: when the sheet
                                // never appears, this is what separates "no
                                // offering" from "offering with no packages"
                                // from "purchase threw".
                                NSLog("RCPROBE offerings=%@ current=%@ packages=%d",
                                      String(describing: subscriptions.currentOffering != nil),
                                      subscriptions.currentOffering?.identifier ?? "nil",
                                      subscriptions.currentOffering?.availablePackages.count ?? -1)
                                do {
                                    let outcome = try await subscriptions.purchase(package)
                                    NSLog("RCPROBE purchase outcome=%@", String(describing: outcome))
                                } catch {
                                    NSLog("RCPROBE purchase error=%@", String(describing: error))
                                }
                            }
                        }
                    }
                    #endif
                }
        }
    }
}
