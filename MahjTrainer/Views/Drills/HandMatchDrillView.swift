import SwiftUI

struct HandMatchDrillView: View {
    let drill: Drill
    let questions: [HandMatchQuestion]

    @EnvironmentObject private var progress: ProgressStore

    @State private var index = 0
    @State private var selection: HandCategory?
    @State private var score = 0
    @State private var finished = false
    @State private var confettiTrigger = 0

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: questions.count)
        } else {
            drillBody
        }
    }

    private var question: HandMatchQuestion { questions[index] }
    private var answered: Bool { selection != nil }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Theme.jade)
            VStack(spacing: 16) {
                QuestionPager(
                    prompt: "Which section is this rack chasing?",
                    tiles: question.tiles.racked,
                    explanation: question.explanation,
                    answered: answered
                ) {
                    ChoiceList(
                        labels: question.choices.map(\.displayName),
                        selection: question.choices.firstIndex(where: { $0 == selection }),
                        answerIndex: question.choices.firstIndex(of: question.answer) ?? 0
                    ) { pick in
                        select(question.choices[pick])
                    }
                }
                footer
            }
            .id(index)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var footer: some View {
        Group {
            if answered {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < questions.count ? "Next Rack" : "Finish").primaryCTA()
                }
            } else {
                Text("Rack \(index + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 54)
            }
        }
    }

    private func select(_ category: HandCategory) {
        guard !answered else { return }
        selection = category
        let correct = category == question.answer
        progress.recordItem(id: question.id, correct: correct)
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
        if index + 1 < questions.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selection = nil
                index += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
        }
    }
}
