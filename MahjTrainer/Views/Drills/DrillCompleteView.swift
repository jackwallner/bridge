import SwiftUI
import StoreKit

struct DrillCompleteView: View {
    let drill: Drill
    let score: Int?
    let total: Int

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showReviewPrompt = false
    @State private var recorded = false
    @State private var celebrate = false
    @State private var confettiTrigger = 0

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 132, height: 132)
                    .scaleEffect(celebrate ? 1 : 0.6)
                if let score {
                    VStack(spacing: 2) {
                        Text("\(score)/\(total)")
                            .font(Theme.display(34))
                            .foregroundStyle(Theme.jade)
                            .monospacedDigit()
                        Text("right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(Theme.jade)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
            VStack(spacing: 8) {
                Text(headline)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                Text(subheadline)
                    .font(.body)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.coral)
                Text("\(progress.streakCount)-day streak")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .themedCard(corner: 22)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.3), particleCount: 44) }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            celebrate = true
            confettiTrigger += 1
            guard !recorded else { return }
            recorded = true
            Haptics.success()
            SoundPlayer.play(.complete)
            progress.recordSession(drillID: drill.id)
            recordPositiveMoment()
        }
        .sheet(isPresented: $showReviewPrompt) {
            ReviewPromptSheet(onFinish: handleReviewOutcome)
        }
    }

    /// A finished drill is the positive moment the funnel waits for. Let the
    /// celebration land first: a sheet that lands on top of the confetti reads
    /// as an interruption, not a thank-you.
    private func recordPositiveMoment() {
        ReviewPromptTracker.recordPositiveMoment()
        guard ReviewPromptTracker.shouldShowAfterPositiveMoment() else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showReviewPrompt = true
        }
    }

    private func handleReviewOutcome(_ outcome: ReviewPromptDismissOutcome) {
        // "Yes" then "Maybe later" is the one case worth spending Apple's
        // native prompt on: they're warm, and the system sheet is one tap.
        guard outcome == .enjoyedMaybeLater else { return }
        requestReview()
    }

    private var headline: String {
        guard let score else { return "Deck cleared!" }
        let fraction = Double(score) / Double(max(total, 1))
        if fraction >= 1 { return "Perfect round!" }
        if fraction >= 0.7 { return "Nice work!" }
        return "Good practice!"
    }

    private var subheadline: String {
        if score == nil {
            return "All \(total) cards down. They'll stick a little better every pass."
        }
        return "Every rack you read here is one you'll read faster at the table."
    }
}
