import SwiftUI

/// Where the correct answer row sits, published up to whichever drill is
/// hosting it, so a celebration can fire FROM the thing that was right instead
/// of from the middle of the screen. Reported in the `.drillStage` coordinate
/// space, which the host installs on its root.
struct AnswerRowFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension CoordinateSpace {
    static let drillStageName = "drillStage"
}

extension View {
    /// Installs the coordinate space the winning answer row reports into, and
    /// binds that row's frame so the host can fire its celebration from it.
    func drillStage(answerRect: Binding<CGRect?>) -> some View {
        coordinateSpace(name: CoordinateSpace.drillStageName)
            .onPreferenceChange(AnswerRowFrameKey.self) { [answerRect] rect in
                answerRect.wrappedValue = rect
            }
    }
}

/// Shared question scaffolding: prompt + tiles + choices + explanation, the
/// shape every choice-based drill uses (Quiz, Hand Match, Quick Session).
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
            // Headroom so the winning row's pop and glow have somewhere to go.
            // A ScrollView clips its content, so a row that scales up to the
            // full content width gets its sides sheared off (that was the
            // "glitchy edges" on the correct answer).
            .padding(.horizontal, 10)
        }
        // The pop can overshoot the scroll view's own bounds too.
        .scrollClipDisabled()
    }
}

/// The answer buttons every question type shares. On reveal the correct
/// answer LANDS: it pops, glows, and a shine sweeps across it, and the graded
/// state holds until the drill's Next button advances and never auto-skips.
///
/// Two rules learned the hard way: (1) the correct row is never dimmed, ever.
/// It's the answer the player is supposed to be reading. (2) Nothing here uses
/// `.disabled()` to stop taps after grading, because SwiftUI dims disabled
/// button labels, and that dimming hit the winning row.
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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.05)) {
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
        // Wrong rows the player didn't pick recede a little so the eye goes to
        // the answer, but they stay readable: the miss and the answer are the
        // two rows that matter and neither is faded.
        let recedes = answered && !isAnswer && !isMiss
        return Button {
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
                            .scaleEffect(landed ? 1.2 : 0.4)
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
                    .strokeBorder(border(index), lineWidth: answered && isAnswer ? 2.5 : 1)
            )
            .background {
                // Publish the winning row's position for the host's confetti.
                if isAnswer {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: AnswerRowFrameKey.self,
                            value: geo.frame(in: .named(CoordinateSpace.drillStageName))
                        )
                    }
                }
            }
            .shine(trigger: answered && isAnswer ? shineTrigger : 0)
            .winGlow(Theme.bamGreen, active: answered && isAnswer && landed)
            .scaleEffect(answered && isAnswer && landed ? 1.035 : 1)
            .modifier(ShakeEffect(travels: isMiss ? shakes : 0))
            .opacity(recedes ? 0.72 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answered)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!answered)
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
