import SwiftUI
import UIKit

/// How the funnel ended, so the host knows whether to fire `requestReview()`.
enum ReviewPromptDismissOutcome: Sendable {
    case notNow
    case feedbackSubmitted
    case openedWriteReview
    /// Said yes, then "Maybe later": the host may fire `requestReview()` once.
    case enjoyedMaybeLater
}

/// The three-step review funnel: enjoying it? -> yes, please rate / no, tell us
/// what's wrong. Nobody who says "not really" is ever shown a rating prompt;
/// they get a feedback box that mails us instead. That's the whole trick, and
/// it's why the App Store rating only ever hears from happy players.
struct ReviewPromptSheet: View {
    enum Step: Identifiable {
        case enjoyment, reviewPitch, feedback

        var id: Self { self }
    }

    let initialStep: Step
    let onFinish: (ReviewPromptDismissOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step
    @State private var feedbackText = ""
    @State private var mailFailed = false
    @FocusState private var feedbackFocused: Bool

    init(initialStep: Step = .enjoyment, onFinish: @escaping (ReviewPromptDismissOutcome) -> Void) {
        self.initialStep = initialStep
        self.onFinish = onFinish
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .enjoyment: enjoymentContent
                case .reviewPitch: reviewPitchContent
                case .feedback: feedbackContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        ReviewPromptTracker.markShown()
                        finish(.notNow)
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .presentationDetents(step == .feedback ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var navigationTitle: String {
        switch step {
        case .enjoyment: "Enjoying Mahj Trainer?"
        case .reviewPitch: "Support an indie app"
        case .feedback: "Help us improve"
        }
    }

    private var enjoymentContent: some View {
        VStack(spacing: 20) {
            icon("checkmark.seal.fill", Theme.jade)
            Text("You've finished \(ReviewPromptTracker.positiveMomentCount) drills. If Mahj Trainer is helping the card stick between games, a quick rating helps other players find it.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button { step = .reviewPitch } label: {
                    Text("Yes, I'm enjoying it").primaryCTA()
                }
                Button { step = .feedback } label: {
                    Text("Not really")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    private var reviewPitchContent: some View {
        VStack(spacing: 18) {
            icon("star.fill", Theme.gold)
            Text("Mahj Trainer is built by one person. No ads, no accounts, and your practice history never leaves your phone.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("An honest App Store review takes a few seconds and is the single biggest thing that helps a small app like this reach new players.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    ReviewPromptTracker.markOpenedWriteReview()
                    UIApplication.shared.open(AppStoreLinks.writeReviewURL)
                    finish(.openedWriteReview)
                } label: {
                    Text("Rate on the App Store").primaryCTA()
                }
                Button {
                    ReviewPromptTracker.markSoftDeferred()
                    finish(.enjoyedMaybeLater)
                } label: {
                    Text("Maybe later")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    private var feedbackContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What would make Mahj Trainer better for you?")
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $feedbackText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .padding(10)
                .themedCard(corner: 14)
                .focused($feedbackFocused)
            if mailFailed {
                // Plenty of people never set up Apple Mail. Telling them it
                // "sent" when nothing opened is worse than saying nothing.
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your mail app didn't open. You can email us directly:")
                        .font(.caption)
                        .foregroundStyle(Theme.ink)
                    Button {
                        UIPasteboard.general.string = AppStoreLinks.feedbackEmail
                        Haptics.success()
                    } label: {
                        Label("Copy \(AppStoreLinks.feedbackEmail)", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.jade)
                    }
                }
            } else {
                Text("Opens your mail app with a draft to the developer. It goes to a real person.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Button {
                sendFeedback()
            } label: {
                Text("Send feedback").primaryCTA()
            }
            .disabled(trimmedFeedback.isEmpty)
            .opacity(trimmedFeedback.isEmpty ? 0.5 : 1)
            Spacer(minLength: 0)
        }
        .padding(24)
        .onAppear { feedbackFocused = true }
    }

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 68, height: 68)
            .background(color.opacity(0.13), in: Circle())
            .padding(.top, 6)
    }

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Only claim the feedback was sent if a mail app actually opened.
    private func sendFeedback() {
        guard !trimmedFeedback.isEmpty, let url = Self.feedbackMailURL(body: trimmedFeedback) else { return }
        UIApplication.shared.open(url, options: [:]) { opened in
            Task { @MainActor in
                guard opened else {
                    mailFailed = true
                    return
                }
                ReviewPromptTracker.markFeedbackSubmitted()
                finish(.feedbackSubmitted)
            }
        }
    }

    private func finish(_ outcome: ReviewPromptDismissOutcome) {
        onFinish(outcome)
        dismiss()
    }

    static func feedbackMailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppStoreLinks.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Mahj Trainer feedback"),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
