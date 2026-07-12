import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                practiceSection
                proSection
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
            .alert("Restore", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
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
            Button("Reset Progress", role: .destructive) {
                showResetConfirm = true
            }
        }
    }

    private var proSection: some View {
        Section("Membership") {
            if subscriptions.isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.jade)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock the Pro Tables", systemImage: "lock.open.fill")
                }
            }
            Button("Restore Purchases") {
                Task {
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro ? "Pro restored!" : "No purchases found."
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
                requestReview()
            } label: {
                Label("Rate Mahj Trainer", systemImage: "star.fill")
            }
            Link(destination: URL(string: "mailto:jackwallner@gmail.com?subject=Mahj%20Trainer%20Feedback")!) {
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
