import SwiftUI

/// The Get Started session: one screen per item, mixing flashcards (tap to
/// flip, self-grade) with quiz and rack-reading questions. Short by design,
/// so a new player gets a win in under five minutes.
struct MixedSessionView: View {
    let items: [MixedItem]

    @EnvironmentObject private var progress: ProgressStore

    @State private var index = 0
    @State private var score = 0
    @State private var finished = false
    @State private var confettiTrigger = 0
    /// Transition beat: shown before the first item and whenever the game
    /// type switches, so a new interaction never lands unannounced.
    @State private var showBeat = true

    // Per-item state, reset on advance.
    @State private var isFlipped = false
    @State private var choicePick: Int?
    @State private var quizSelection: Int?
    @State private var handMatchSelection: HandCategory?

    var body: some View {
        if finished || items.isEmpty {
            DrillCompleteView(drill: SessionBuilder.sessionDrill, score: score, total: items.count)
        } else {
            drillBody
        }
    }

    private var item: MixedItem { items[index] }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(items.count))
                .tint(Theme.jade)
            if showBeat {
                SessionBeat(kind: item.beatKind) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showBeat = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                VStack(spacing: 16) {
                    itemBody
                    footer
                }
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.4)) }
        .navigationTitle("Quick Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var itemBody: some View {
        switch item {
        case .flashcard(let card):
            flashcardBody(card)
        case .quiz(let question):
            QuestionPager(
                prompt: question.prompt,
                tiles: question.tiles,
                explanation: question.explanation,
                answered: quizSelection != nil
            ) {
                ChoiceList(
                    labels: question.choices,
                    selection: quizSelection,
                    answerIndex: question.answerIndex
                ) { pick in
                    quizSelection = pick
                    grade(correct: pick == question.answerIndex, id: question.id)
                }
            }
        case .handMatch(let question):
            QuestionPager(
                prompt: "Which section is this rack chasing?",
                tiles: question.tiles.racked,
                explanation: question.explanation,
                answered: handMatchSelection != nil
            ) {
                ChoiceList(
                    labels: question.choices.map(\.displayName),
                    selection: question.choices.firstIndex(where: { $0 == handMatchSelection }),
                    answerIndex: question.choices.firstIndex(of: question.answer) ?? 0
                ) { pick in
                    handMatchSelection = question.choices[pick]
                    grade(correct: question.choices[pick] == question.answer, id: question.id)
                }
            }
        }
    }

    private func flashcardBody(_ card: Flashcard) -> some View {
        FlipCardFace(
            card: card,
            isFlipped: isFlipped,
            choicePick: choicePick,
            onChoose: { pick in
                guard let choice = card.choice, choicePick == nil else { return }
                choicePick = pick
                grade(correct: pick == choice.answerIndex, id: card.id)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { isFlipped = true }
            },
            showsSwipeHints: false
        )
        .onTapGesture {
            // Choice cards flip through their buttons only; a free reveal
            // would dead-end the item with nothing graded.
            guard !isFlipped, card.choice == nil else { return }
            Haptics.impact(.soft, intensity: 0.5)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isFlipped = true }
        }
        .padding(.vertical, 4)
    }

    private var answered: Bool {
        switch item {
        case .flashcard(let card):
            // A plain card is "answered" when flipped; graded by Got it/Again.
            return isFlipped && (card.choice == nil || choicePick != nil)
        case .quiz:
            return quizSelection != nil
        case .handMatch:
            return handMatchSelection != nil
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch item {
        case .flashcard(let card) where card.choice == nil && isFlipped:
            // Self-grade: did you know it before the flip?
            HStack(spacing: 10) {
                Button {
                    progress.recordItem(id: card.id, correct: false)
                    advance()
                } label: {
                    Text("Again")
                        .font(.headline)
                        .foregroundStyle(Theme.coral)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Button {
                    progress.recordItem(id: card.id, correct: true)
                    score += 1
                    advance()
                } label: {
                    Text("Knew it").primaryCTA()
                }
            }
        case .flashcard(let card) where card.choice != nil && !isFlipped:
            Text("Make the call on the card")
                .font(.caption)
                .foregroundStyle(Theme.inkTertiary)
                .frame(height: 56)
        case .flashcard:
            if answered {
                nextButton
            } else {
                Text("Tap the card to reveal")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 56)
            }
        default:
            if answered {
                nextButton
            } else {
                Text("\(index + 1) of \(items.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 56)
            }
        }
    }

    private var nextButton: some View {
        Button {
            advance()
        } label: {
            Text(index + 1 < items.count ? "Next" : "Finish").primaryCTA()
        }
    }

    private func grade(correct: Bool, id: String) {
        progress.recordItem(id: id, correct: correct)
        if correct {
            score += 1
            confettiTrigger += 1
            Haptics.success()
            SoundPlayer.play(.success)
        } else {
            Haptics.error()
            SoundPlayer.play(.miss)
        }
    }

    private func advance() {
        if index + 1 < items.count {
            let kindSwitches = items[index + 1].beatKind != item.beatKind
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isFlipped = false
                choicePick = nil
                quizSelection = nil
                handMatchSelection = nil
                index += 1
                if kindSwitches { showBeat = true }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
        }
    }
}

// MARK: - Transition beat

/// A short interstitial announcing the next game type: what it is and how to
/// answer, held until the player taps in.
struct SessionBeat: View {
    enum Kind {
        case flashcard, quiz, handMatch

        var title: String {
            switch self {
            case .flashcard: return "Flashcards"
            case .quiz: return "Quick Quiz"
            case .handMatch: return "Rack Reading"
            }
        }

        var icon: String {
            switch self {
            case .flashcard: return "rectangle.stack.fill"
            case .quiz: return "questionmark.circle.fill"
            case .handMatch: return "square.grid.3x3.fill"
            }
        }

        var howTo: String {
            switch self {
            case .flashcard: return "Tap the card to reveal the answer, or make the call when it asks for one. Then be honest: knew it, or see it again?"
            case .quiz: return "Pick the answer you'd trust at the table. The right one lights up either way."
            case .handMatch: return "Study the rack and pick the card section it's chasing."
            }
        }

        var accent: Color {
            switch self {
            case .flashcard: return Theme.jade
            case .quiz: return Theme.coral
            case .handMatch: return Theme.plum
            }
        }
    }

    let kind: Kind
    let onContinue: () -> Void

    @State private var shineTrigger = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            VStack(spacing: 14) {
                Text("NEXT UP")
                    .font(.caption.weight(.heavy))
                    .kerning(2)
                    .foregroundStyle(kind.accent)
                Image(systemName: kind.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(kind.accent)
                    .frame(width: 78, height: 78)
                    .background(kind.accent.opacity(0.12), in: Circle())
                Text(kind.title)
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)
                Text(kind.howTo)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(26)
            .frame(maxWidth: .infinity)
            .themedCard(corner: 22)
            .shine(trigger: shineTrigger, corner: 22)
            Spacer()
            Button(action: onContinue) {
                Text("Deal me in").primaryCTA(color: kind.accent)
            }
        }
        .onAppear {
            Haptics.impact(.soft, intensity: 0.6)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                shineTrigger += 1
            }
        }
    }
}

private extension MixedItem {
    var beatKind: SessionBeat.Kind {
        switch self {
        case .flashcard: return .flashcard
        case .quiz: return .quiz
        case .handMatch: return .handMatch
        }
    }
}

// MARK: - Shared question scaffolding

/// Prompt + tiles + choices + explanation, the shape every question shares.
struct QuestionPager<Choices: View>: View {
    let prompt: String
    let tiles: [Tile]
    let explanation: String
    let answered: Bool
    @ViewBuilder let choices: () -> Choices

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(prompt)
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                if !tiles.isEmpty {
                    TileRackView(tiles: tiles, tileWidth: 44)
                }
                choices()
                if answered {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Theme.gold)
                        Text(explanation)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

/// The answer buttons every question type shares. On reveal the correct
/// answer LANDS: it pops, glows, and a shine sweeps across it, and the graded
/// state holds until the drill's Next button advances and never auto-skips.
struct ChoiceList: View {
    let labels: [String]
    let selection: Int?
    let answerIndex: Int
    let onPick: (Int) -> Void

    @State private var shineTrigger = 0
    @State private var landed = false
    @State private var shakes: CGFloat = 0

    private var answered: Bool { selection != nil }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(labels.indices, id: \.self) { index in
                row(index)
            }
        }
        .onChange(of: answered) { _, isAnswered in
            guard isAnswered else {
                // New question: reset the celebration state.
                landed = false
                shakes = 0
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.05)) {
                landed = true
            }
            shineTrigger += 1
            if selection != answerIndex {
                withAnimation(.linear(duration: 0.4)) { shakes = 2 }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let isAnswer = index == answerIndex
        let isMiss = answered && index == selection && !isAnswer
        return Button {
            guard !answered else { return }
            onPick(index)
        } label: {
            HStack {
                Text(labels[index])
                    .font(.body.weight(answered && isAnswer ? .semibold : .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if answered {
                    if isAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Theme.bamGreen)
                            .scaleEffect(landed ? 1.15 : 0.4)
                    } else if isMiss {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.crakRed)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(background(index), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border(index), lineWidth: answered && isAnswer ? 2 : 1)
            )
            .shine(trigger: answered && isAnswer ? shineTrigger : 0)
            .winGlow(Theme.bamGreen, active: answered && isAnswer && landed)
            .scaleEffect(answered && isAnswer && landed ? 1.03 : 1)
            .modifier(ShakeEffect(travels: isMiss ? shakes : 0))
            .opacity(answered && !isAnswer && !isMiss ? 0.55 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answered)
        }
        .buttonStyle(.plain)
        .disabled(answered)
    }

    private func background(_ index: Int) -> Color {
        guard answered else { return Theme.card }
        if index == answerIndex { return Theme.bamGreen.opacity(0.18) }
        if index == selection { return Theme.crakRed.opacity(0.15) }
        return Theme.card
    }

    private func border(_ index: Int) -> Color {
        guard answered else { return Theme.rule }
        if index == answerIndex { return Theme.bamGreen.opacity(0.6) }
        if index == selection { return Theme.crakRed.opacity(0.5) }
        return Theme.rule
    }
}
