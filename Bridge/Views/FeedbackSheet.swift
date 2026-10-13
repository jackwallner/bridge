import SwiftUI
import UIKit

/// Settings' "Send Feedback": a note that opens as a mail draft to the
/// developer. Open to everyone and never tied to a rating question.
struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var mailFailed = false
    @FocusState private var feedbackFocused: Bool

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Theme.background)
                .navigationTitle("Help us improve")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What would make Bridge Trainer better for you?")
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
                dismiss()
            }
        }
    }

    static func feedbackMailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppStoreLinks.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Bridge Trainer feedback"),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
