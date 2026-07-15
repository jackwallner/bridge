import SwiftUI

struct PlayDrillView: View {
    let drill: Drill
    let scenarios: [PlayScenario]

    @EnvironmentObject private var progress: ProgressStore
    @State private var index = 0
    @State private var selection: Int?
    @State private var score = 0
    @State private var finished = false
    @State private var confettiTrigger = 0

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: scenarios.count)
        } else {
            drillBody
        }
    }

    private var scenario: PlayScenario { scenarios[index] }
    private var answered: Bool { selection != nil }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(scenarios.count))
                .tint(Theme.jade)
            ScrollView {
                VStack(spacing: 20) {
                    Text(scenario.situation)
                        .font(Theme.display(21, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    Text("Tap the card you would play")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                    HStack(spacing: 10) {
                        ForEach(Array(scenario.cards.enumerated()), id: \.offset) { cardIndex, card in
                            Button {
                                select(cardIndex)
                            } label: {
                                BridgeCardView(card: card, width: 54)
                                    .overlay {
                                        if answered {
                                            RoundedRectangle(cornerRadius: 7)
                                                .strokeBorder(borderColor(cardIndex), lineWidth: 3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(answered)
                        }
                    }
                    if answered {
                        coachCard
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                }
            }
            if answered {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < scenarios.count ? "Next Play" : "Finish").primaryCTA()
                }
            } else {
                Text("Play \(index + 1) of \(scenarios.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 56)
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                selection == scenario.answerIndex ? "Right play" : "Coach's play",
                systemImage: selection == scenario.answerIndex ? "checkmark.circle.fill" : "lightbulb.fill"
            )
            .font(.headline)
            .foregroundStyle(selection == scenario.answerIndex ? Theme.jade : Theme.gold)
            Text(scenario.reasoning)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Text(scenario.tip)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 16)
    }

    private func borderColor(_ cardIndex: Int) -> Color {
        if cardIndex == scenario.answerIndex { return Theme.jade }
        if cardIndex == selection { return Theme.coral }
        return .clear
    }

    private func select(_ cardIndex: Int) {
        guard !answered else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selection = cardIndex
        }
        let correct = cardIndex == scenario.answerIndex
        progress.recordItem(id: scenario.id, correct: correct)
        if correct {
            score += 1
            confettiTrigger += 1
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    private func advance() {
        if index + 1 < scenarios.count {
            selection = nil
            index += 1
        } else {
            finished = true
        }
    }
}
