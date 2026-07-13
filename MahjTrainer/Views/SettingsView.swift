import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?
    /// Non-nil while the review funnel is up; the value is where it opens.
    @State private var reviewPromptStep: ReviewPromptSheet.Step?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                practiceSection
                proSection
                dataSection
                supportSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.jade)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $reviewPromptStep) { step in
                ReviewPromptSheet(initialStep: step) { outcome in
                    if outcome == .enjoyedMaybeLater { requestReview() }
                }
            }
            .alert("Restore", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .alert("Notifications are off", isPresented: $settings.reminderPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Mahj Trainer can't send your daily reminder until notifications are turned on for it in iOS Settings.")
            }
            .alert("Reset all progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { progress.resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your streak, completed drills, and practice history will be cleared. Purchases are not affected.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
        }
    }

    private var practiceSection: some View {
        Section("Practice") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle("Sound Effects", isOn: $settings.soundEnabled)
            Toggle("Daily Reminder", isOn: $settings.reminderEnabled)
            if settings.reminderEnabled {
                DatePicker("Reminder Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    /// Reset gets its own section. A destructive red button sitting between
    /// Haptics and Sound Effects is a trap for anyone who taps to see what
    /// something does.
    private var dataSection: some View {
        Section("Your Practice History") {
            Button("Reset Progress", role: .destructive) {
                showResetConfirm = true
            }
        }
    }

    private var proSection: some View {
        Section("Membership") {
            if subscriptions.isPro {
                Label("\(Membership.name) unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.jade)
                Link("Manage Subscription", destination: PaywallLinks.manageSubscriptions)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Get \(Membership.name)", systemImage: "sparkles")
                }
            }
            Button("Restore Purchases") {
                Task {
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro
                            ? "\(Membership.name) restored!"
                            : "No previous purchase found on this Apple Account."
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                HowToPlayView()
            } label: {
                Label("How to Play", systemImage: "book.fill")
            }
            Button {
                reviewPromptStep = .reviewPitch
            } label: {
                Label("Rate Mahj Trainer", systemImage: "star.fill")
            }
            Button {
                reviewPromptStep = .feedback
            } label: {
                Label("Send Feedback", systemImage: "envelope.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            Text("Mahj Trainer teaches American Mah Jongg skills with original practice hands. It is not affiliated with or endorsed by the National Mah Jongg League. For official hands and values, pick up the current NMJL card.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Developer") {
            Toggle("Local Pro override", isOn: .init(
                get: { subscriptions.isPro },
                set: { subscriptions.setLocalOverride(isPro: $0) }
            ))
        }
    }
    #endif
}
