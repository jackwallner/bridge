import SwiftUI
import UIKit

/// Every place the app asks the player to type: Settings > Send Feedback and
/// the one question asked when a membership is leaving.
///
/// It never asks about ratings. Sending only happy players to the App Store
/// is review gating (5.6.1); ratings come from Apple's own prompt after a
/// positive moment (`requestsReview(after:)`), and feedback is open to
/// everyone without standing in front of it.
struct ReviewPromptSheet: View {
    enum Step: Identifiable, Hashable {
        case feedback
        case churn(ChurnMoment)

        var id: Self { self }
    }

    let initialStep: Step

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step
    @State private var feedbackText = ""
    @State private var chosenChip: String?
    @State private var sending = false
    @State private var sendOutcome: FeedbackService.Outcome?
    @FocusState private var feedbackFocused: Bool

    init(initialStep: Step) {
        self.initialStep = initialStep
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        NavigationStack {
            // Scrolls, so the largest text sizes and the keyboard can never
            // push Send out of reach.
            ScrollView {
                switch step {
                case .feedback:
                    composer(
                        kind: .general,
                        question: String(localized: "What would make Bridge Trainer better for you?"),
                        chips: [],
                        thanks: String(localized: "Thanks. It went straight to the developer.")
                    )
                case .churn(let moment):
                    composer(
                        kind: .churn,
                        question: churnQuestion(moment),
                        chips: churnChips(moment),
                        thanks: String(localized: "Thanks for saying. It helps more than you'd think."),
                        context: ["moment": moment.rawValue]
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(sendOutcome == nil ? String(localized: "Not now") : String(localized: "Done")) { dismiss() }
                    .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var navigationTitle: String {
        switch step {
        case .feedback: String(localized: "Help us improve")
        case .churn(let moment): moment == .trialRenewalOff ? String(localized: "Before your trial ends") : String(localized: "Before you go")
        }
    }

    // MARK: - Composer (feedback, churn)

    private func composer(
        kind: FeedbackKind,
        question: String,
        chips: [String],
        thanks: String,
        context: [String: String] = [:]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sendOutcome {
                sentState(sendOutcome, thanks: thanks)
            } else {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !chips.isEmpty {
                    chipRows(chips)
                }
                TextEditor(text: $feedbackText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: chips.isEmpty ? 140 : 96)
                    .padding(10)
                    .themedCard(corner: 14)
                    .focused($feedbackFocused)
                    .overlay(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text(chips.isEmpty ? String(localized: "Anything at all.") : String(localized: "Add a few words if you like."))
                                .font(.body)
                                .foregroundStyle(Theme.inkTertiary)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }
                Text("Goes straight to the developer, a real person. No account, no email needed.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Button {
                    send(kind: kind, context: context)
                } label: {
                    Group {
                        if sending {
                            ProgressView().tint(Theme.onFill)
                        } else {
                            Text("Send")
                        }
                    }
                    .primaryCTA()
                }
                .disabled(!canSend || sending)
                .opacity(canSend ? 1 : 0.5)
            }
        }
        .padding(24)
        .onAppear { if chips.isEmpty { feedbackFocused = true } }
    }

    private func chipRows(_ chips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chips, id: \.self) { chip in
                let selected = chosenChip == chip
                Button {
                    chosenChip = selected ? nil : chip
                    Haptics.impact(.light, intensity: 0.5)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Theme.jade : Theme.inkTertiary)
                        // The chip is sent in English as a tag; only its label is translated.
                        Text(chip.localizedContent)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        selected ? Theme.jade.opacity(0.10) : Theme.card,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? Theme.jade : Theme.rule, lineWidth: selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func sentState(_ outcome: FeedbackService.Outcome, thanks: String) -> some View {
        VStack(spacing: 16) {
            switch outcome {
            case .sent:
                icon("paperplane.fill", Theme.jade)
                Text(thanks)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            case .queued:
                icon("tray.and.arrow.up.fill", Theme.gold)
                Text("Saved. It will send the next time you open the app with a connection.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            case .failed:
                icon("exclamationmark.triangle.fill", Theme.coral)
                Text("That didn't go through. Try again, or copy your message and email it to \(AppStoreLinks.feedbackEmail).")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    UIPasteboard.general.string = composedMessage
                    Haptics.success()
                } label: {
                    Label("Copy my message", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.jade)
                }
                // Back to the form with the text intact, so a refused send
                // never costs the player what they wrote.
                Button {
                    withAnimation(.easeOut(duration: 0.25)) { sendOutcome = nil }
                } label: {
                    Text("Try again")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.jade)
                }
            }
            Button {
                dismiss()
            } label: {
                Text("Done").primaryCTA()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What gets sent: the chosen chip as a tag, then the player's words.
    private var composedMessage: String {
        guard let chosenChip else { return trimmedFeedback }
        return trimmedFeedback.isEmpty ? chosenChip : "[\(chosenChip)] \(trimmedFeedback)"
    }

    private var canSend: Bool {
        chosenChip != nil || !trimmedFeedback.isEmpty
    }

    private func send(kind: FeedbackKind, context: [String: String]) {
        guard canSend, !sending else { return }
        sending = true
        feedbackFocused = false
        let message = composedMessage
        let isMember = subscriptions.isPro
        Task { @MainActor in
            let outcome = await FeedbackService.shared.submit(
                kind: kind,
                message: message,
                context: context,
                isMember: isMember
            )
            sending = false
            if outcome == .sent { Haptics.success() }
            withAnimation(.easeOut(duration: 0.25)) { sendOutcome = outcome }
        }
    }

    // MARK: - Churn copy

    private func churnQuestion(_ moment: ChurnMoment) -> String {
        switch moment {
        case .trialRenewalOff: return String(localized: "Your trial won't renew. What held you back?")
        case .trialLapsed: return String(localized: "Your free week ended. What held you back from keeping \(Membership.name)?")
        case .paidRenewalOff: return String(localized: "Your membership won't renew. What would have kept you?")
        case .paidLapsed: return String(localized: "Your membership ended. What would have kept you?")
        }
    }

    private func churnChips(_ moment: ChurnMoment) -> [String] {
        if moment.isTrial {
            return ["Too expensive", "Didn't use it enough", "Got what I needed", "Something was missing", "Something else"]
        }
        return ["Too expensive", "Not practicing enough anymore", "Learned what I needed", "Wanted more content", "Something else"]
    }

    // MARK: - Helpers

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 68, height: 68)
            .background(color.opacity(0.13), in: Circle())
            .padding(.top, 6)
    }
}
