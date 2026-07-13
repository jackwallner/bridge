import SwiftUI

/// The Get Started session: a short, UNIFORM run of single-select choice
/// items pulled from across the rooms. Every item follows the same beat -
/// pick, grade immediately, the correct answer highlights and HOLDS, then an
/// explicit Next - so there's no interstitial or mixed grading path to fight
/// the transition. (The old MixedSessionView packed flip-flashcards, quiz,
/// and hand-match into one screen with a per-switch interstitial; that mix
/// of grading paths is what made it look like it skipped the right answer.)
struct QuickSessionView: View {
    /// Snapshotted at first construction, never re-read from the parent.
    /// `SessionBuilder.quickSession` shuffles and re-tiers on every call, and
    /// grading publishes `ProgressStore.seenItems`, which re-renders whichever
    /// parent (Home, the tour) built us. Holding the list as a plain `let`
    /// meant that re-render swapped a DIFFERENT question under the live index
    /// mid-answer, which read as "it changed the answer on me".
    @State private var items: [QuickItem]
    /// Set when the session is presented with no navigation stack of its own to
    /// escape through (the onboarding tour's fullScreenCover). Without it the
    /// player's FIRST question flow has no exit but finishing it, which is a
    /// trap, and a bad one right after the money page.
    private let onClose: (() -> Void)?

    init(items: [QuickItem], onClose: (() -> Void)? = nil) {
        _items = State(initialValue: items)
        self.onClose = onClose
    }

    @EnvironmentObject private var progress: ProgressStore

    @State private var index = 0
    @State private var score = 0
    @State private var finished = false
    @State private var selection: Int?

    @State private var confettiTrigger = 0
    @State private var confettiParticleCount = 30
    @State private var flashOpacity: Double = 0
    /// The correct answer row, published by `ChoiceList`. The celebration
    /// launches from there, not from the middle of the screen.
    @State private var answerRect: CGRect?

    @State private var streak = 0
    @State private var streakBannerText: String?
    @State private var streakBannerTrigger = 0

    private static let streakMilestones: Set<Int> = [3, 5, 10]

    var body: some View {
        if finished || items.isEmpty {
            DrillCompleteView(drill: SessionBuilder.sessionDrill, score: score, total: items.count, onDone: onClose)
        } else {
            drillBody
        }
    }

    private var item: QuickItem { items[index] }
    private var answered: Bool { selection != nil }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(items.count))
                .tint(Theme.jade)
            VStack(spacing: 12) {
                Text(item.sourceLabel.uppercased())
                    .font(.caption2.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.inkTertiary)
                QuestionPager(
                    prompt: item.prompt,
                    tiles: item.tiles,
                    explanation: item.explanation,
                    answered: answered
                ) {
                    ChoiceList(labels: item.choices, selection: selection, answerIndex: item.answerIndex) { pick in
                        grade(pick)
                    }
                }
                footer
            }
            .id(item.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .padding()
        .background(Theme.background)
        .drillStage(answerRect: $answerRect)
        .overlay { Theme.bamGreen.opacity(flashOpacity).allowsHitTesting(false).ignoresSafeArea() }
        .overlay {
            ConfettiBurst(
                trigger: confettiTrigger,
                origin: .init(x: 0.5, y: 0.35),
                particleCount: confettiParticleCount,
                sourceRect: answerRect
            )
        }
        .overlay(alignment: .top) {
            if let streakBannerText {
                StreakBanner(text: streakBannerText)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Quick Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onClose() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
    }

    private var footer: some View {
        Group {
            if answered {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < items.count ? "Next" : "Finish").primaryCTA()
                }
            } else {
                Text("\(index + 1) of \(items.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 54)
            }
        }
    }

    // MARK: - Grading

    private func grade(_ pick: Int) {
        guard selection == nil else { return }
        selection = pick
        let correct = pick == item.answerIndex
        progress.recordItem(id: item.id, correct: correct)
        if correct {
            score += 1
            streak += 1
            landCorrect()
        } else {
            streak = 0
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    /// The dopamine landing: confetti + haptic + sound every time, escalating
    /// with a full-screen glow flash and a stronger haptic + banner at streak
    /// milestones. A miss keeps the existing gentle feedback in `grade`.
    private func landCorrect() {
        confettiParticleCount = particleCount(forStreak: streak)
        confettiTrigger += 1
        Haptics.correctAnswer()
        SoundPlayer.play(.success)

        flashOpacity = 0.14
        withAnimation(.easeOut(duration: 0.5)) { flashOpacity = 0 }

        guard Self.streakMilestones.contains(streak) else { return }
        Haptics.impact(.rigid, intensity: 1.0)
        announceStreak(streak)
    }

    private func particleCount(forStreak streak: Int) -> Int {
        switch streak {
        case 10...: return 90
        case 5..<10: return 60
        case 3..<5: return 44
        default: return 28
        }
    }

    private func announceStreak(_ streak: Int) {
        streakBannerTrigger += 1
        let trigger = streakBannerTrigger
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            streakBannerText = "\(streak) in a row!"
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard trigger == streakBannerTrigger else { return }
            withAnimation(.easeOut(duration: 0.3)) { streakBannerText = nil }
        }
    }

    private func advance() {
        if index + 1 < items.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selection = nil
                index += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
        }
    }
}

/// Brief celebratory pill for a consecutive-correct milestone (3/5/10 in a row).
private struct StreakBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
            Text(text)
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Theme.coral, in: Capsule())
        .shadow(color: Theme.coral.opacity(0.4), radius: 10, y: 4)
    }
}
