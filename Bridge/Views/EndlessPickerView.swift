import SwiftUI

/// Picks which generated skill to drill. Small on purpose: the whole point of
/// Endless Practice is that it starts fast and never runs out, so this is one
/// tap between Home and the first dealt hand, not another lobby.
struct EndlessPickerView: View {
    @StateObject private var records = PracticeRecordStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                intro
                ForEach(PracticeSkill.allCases) { skill in
                    NavigationLink {
                        PracticeRunView(mode: .endless(skill))
                    } label: {
                        skillCard(skill)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle("Endless Practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "infinity")
                .foregroundStyle(Theme.jade)
            Text("Every hand here is dealt fresh the moment you see it, so you can practise for as long as you like without repeating a question.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.jade.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 12)
    }

    private func skillCard(_ skill: PracticeSkill) -> some View {
        let record = records.records[skill.rawValue]
        return HStack(spacing: 14) {
            Image(systemName: skill.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 48, height: 48)
                .background(Theme.jade.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(skill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                if let record, record.attempts > 0 {
                    Text("\(Int((record.accuracy * 100).rounded()))% across \(record.attempts) answered")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(14)
        .themedCard()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }
}
