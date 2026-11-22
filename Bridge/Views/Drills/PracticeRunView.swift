import SwiftUI

/// What a run is and when it ends.
enum PracticeMode: Equatable {
    /// Generated questions for one skill, forever, until the player stops.
    case endless(PracticeSkill)
    /// Mixed generated questions against a countdown.
    case timed
    /// A fixed list of items the scheduler says are due.
    case review

    var isGenerated: Bool { self != .review }

    /// What a run that ends now is scored out of, or nil when it should just
    /// close: a run quit before any answer is not an achievement.
    func completionTotal(attempted: Int) -> Int? {
        attempted > 0 ? attempted : nil
    }
}

/// The runner behind Endless Practice, the Timed Challenge, and Fix My
/// Mistakes. All three are the same beat as Quick Session (pick, grade
/// immediately, the answer holds, explicit Next); what differs is only where
/// the questions come from and what ends the run.
///
/// `QuickSessionView` is deliberately left alone rather than generalised into
/// this: it is the shipped first-run flow and its snapshot/transition
/// behaviour is tuned. This shares the same components, not the same file.
struct PracticeRunView: View {
    let mode: PracticeMode

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var records = PracticeRecordStore.shared

    /// Snapshotted, never re-derived from the parent mid-run. Grading
    /// publishes store changes that re-render whoever pushed us, and a
    /// re-derived list would swap a different question under the live index.
    @State private var items: [QuickItem]
    @State private var index = 0
    @State private var score = 0
    /// Questions actually answered. An endless or timed run is scored out of
    /// this, not out of `index` (which lags by one until the player advances)
    /// and not out of `items.count` (which is just however much has been
    /// generated so far).
    @State private var attempted = 0
    @State private var finished = false
    /// The timed clock ran out with nothing answered. That run has no score
    /// to show, but it still needs an ending rather than a silent dismiss.
    @State private var timedOutEmpty = false
    @State private var selection: Int?

    @State private var secondsRemaining = Self.challengeSeconds
    /// Set once when the clock first runs and kept if the task restarts.
    @State private var deadline: Date?
    @State private var confettiTrigger = 0
    @State private var confettiParticleCount = 30
    @State private var flashOpacity: Double = 0
    @State private var answerRect: CGRect?
    @State private var streak = 0

    @Environment(\.dismiss) private var dismiss

    static let challengeSeconds = 90
    /// How many generated questions to mint at a time. Dealing is rejection
    /// sampling, so a batch costs real work; topping up near the end of the
    /// current one keeps that off the tap that advances the question.
    private static let batchSize = 8
    private static let topUpThreshold = 3

    init(mode: PracticeMode, items: [QuickItem] = []) {
        self.mode = mode
        switch mode {
        case .endless(let skill):
            _items = State(initialValue: EndlessPractice.items(for: skill, count: Self.batchSize))
        case .timed:
            _items = State(initialValue: EndlessPractice.mixedItems(count: Self.batchSize))
        case .review:
            _items = State(initialValue: items)
        }
    }

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label("Nothing due", systemImage: "checkmark.circle")
            } actions: {
                Button("Done") { dismiss() }
            }
            .background(Theme.background)
            .navigationTitle(title)
        } else if timedOutEmpty {
            timeUpScreen
        } else if finished {
            DrillCompleteView(drill: completedDrill, score: score, total: completionTotal ?? 0)
        } else {
            runBody
        }
    }

    private var timeUpScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 48))
                .foregroundStyle(Theme.coral)
                .accessibilityHidden(true)
            Text("Time's up")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                retryTimed()
            } label: {
                Text("Try again").primaryCTA()
            }
            Button { dismiss() } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.jade)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            AccessibilityNotification.Announcement(String(localized: "Time's up")).post()
        }
    }

    /// A fresh deal and a fresh clock, started at once: the player just asked
    /// for it.
    private func retryTimed() {
        Haptics.impact(.rigid)
        items = EndlessPractice.mixedItems(count: Self.batchSize)
        index = 0
        selection = nil
        score = 0
        streak = 0
        attempted = 0
        deadline = nil
        secondsRemaining = Self.challengeSeconds
        timedOutEmpty = false
    }

    private var item: QuickItem { items[min(index, items.count - 1)] }
    private var answered: Bool { selection != nil }

    private var missNote: MissNote? {
        guard let selection, let reason = item.note(forPick: selection) else { return nil }
        return MissNote(pickedLabel: item.choices[selection], reason: reason)
    }
    private var completionTotal: Int? { mode.completionTotal(attempted: attempted) }

    private var completedDrill: Drill {
        switch mode {
        case .endless(let skill): return EndlessPractice.drill(for: skill)
        case .timed: return EndlessPractice.challengeDrill
        case .review: return SessionBuilder.reviewDrill
        }
    }

    private var title: String {
        switch mode {
        case .endless(let skill): return skill.title
        case .timed: return String(localized: "Timed Challenge")
        case .review: return String(localized: "Fix My Mistakes")
        }
    }

    // MARK: - Body

    private var runBody: some View {
        VStack(spacing: 16) {
            statusBar
            VStack(spacing: 12) {
                QuestionPager(
                    prompt: item.prompt,
                    cards: item.cards,
                    explanation: item.explanation,
                    answered: answered,
                    eyebrow: item.sourceLabel.localizedUppercase,
                    missNote: missNote
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
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .drillStage(answerRect: $answerRect)
        .overlay { Theme.bamGreen.opacity(flashOpacity).allowsHitTesting(false).ignoresSafeArea() }
        .overlay {
            ConfettiBurst(
                trigger: confettiTrigger,
                origin: .init(x: 0.5, y: 0.35),
                particleCount: confettiParticleCount,
                sourceRect: answerRect,
                scope: index
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // An endless run has no natural end, so it must always offer one.
            if mode != .timed {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(mode == .review ? String(localized: "Close") : String(localized: "Finish")) { finish() }
                        .foregroundStyle(Theme.jade)
                }
            }
        }
        .task { await runClock() }
    }

    @ViewBuilder
    private var statusBar: some View {
        switch mode {
        case .timed:
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .foregroundStyle(secondsRemaining <= 10 ? Theme.coral : Theme.inkSecondary)
                Text("\(secondsRemaining)s")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(secondsRemaining <= 10 ? Theme.coral : Theme.ink)
                Spacer()
                Text("\(score) correct")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.jade)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
        case .review:
            ProgressView(value: Double(index), total: Double(max(items.count, 1)))
                .tint(Theme.jade)
        case .endless:
            HStack {
                Text("\(score) of \(attempted) correct")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .monospacedDigit()
                Spacer()
                if streak >= 3 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(streak)")
                            .monospacedDigit()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.coral)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var footer: some View {
        Group {
            if answered {
                Button {
                    advance()
                } label: {
                    Text(isLastItem ? String(localized: "Finish") : String(localized: "Next")).primaryCTA()
                }
            } else {
                Text(counterText)
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 54)
            }
        }
    }

    private var isLastItem: Bool {
        mode == .review && index + 1 >= items.count
    }

    private var counterText: String {
        mode == .review ? String(localized: "\(index + 1) of \(items.count)") : String(localized: "Question \(index + 1)")
    }

    // MARK: - Clock

    /// Whole seconds until `deadline`, rounded up so the clock reads 90 at the
    /// start and 0 only once time is truly up.
    static func secondsLeft(until deadline: Date, now: Date = Date()) -> Int {
        max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
    }

    /// The challenge ends at a wall-clock deadline, not after ninety sleeps:
    /// time in another app or on a call counts, so every run is the same 90
    /// seconds and a best score is comparable.
    private func runClock() async {
        guard mode == .timed else { return }
        let end = deadline ?? Date().addingTimeInterval(TimeInterval(Self.challengeSeconds))
        deadline = end
        while !finished {
            secondsRemaining = Self.secondsLeft(until: end)
            if secondsRemaining == 0 { break }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
        }
        guard !finished else { return }
        Haptics.impact(.rigid)
        guard attempted > 0 else {
            timedOutEmpty = true
            return
        }
        finish()
    }

    // MARK: - Grading

    private func grade(_ pick: Int) {
        guard selection == nil else { return }
        // The clock ticks between checks; a tap after the deadline but before
        // the next tick does not score.
        if mode == .timed, let deadline, Date() >= deadline { return }
        selection = pick
        attempted += 1
        let correct = pick == item.answerIndex
        records.record(itemID: item.id, roomID: item.roomID, correct: correct)
        // Generated ids are unique per question, so feeding them to the
        // seen/missed sets would grow those sets forever and teach the daily
        // mix nothing. Authored items still feed it.
        if !mode.isGenerated {
            progress.recordItem(id: item.id, correct: correct)
        }
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

    private func landCorrect() {
        confettiParticleCount = particleCount(forStreak: streak)
        confettiTrigger += 1
        Haptics.correctAnswer()
        SoundPlayer.play(.success)
        flashOpacity = 0.14
        withAnimation(.easeOut(duration: 0.5)) { flashOpacity = 0 }
    }

    private func particleCount(forStreak streak: Int) -> Int {
        switch streak {
        case 10...: return 90
        case 5..<10: return 60
        case 3..<5: return 44
        default: return 28
        }
    }

    private func advance() {
        if isLastItem {
            finish()
            return
        }
        topUpIfNeeded()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selection = nil
            index += 1
        }
    }

    /// Keeps a generated run supplied without ever letting the index run past
    /// the end of the array.
    private func topUpIfNeeded() {
        guard mode.isGenerated, items.count - index <= Self.topUpThreshold else { return }
        switch mode {
        case .endless(let skill):
            items += EndlessPractice.items(for: skill, count: Self.batchSize)
        case .timed:
            items += EndlessPractice.mixedItems(count: Self.batchSize)
        case .review:
            break
        }
    }

    private func finish() {
        if mode == .timed {
            records.recordChallengeScore(score)
        }
        guard completionTotal != nil else {
            dismiss()
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) { finished = true }
    }
}
