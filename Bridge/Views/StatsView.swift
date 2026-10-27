import SwiftUI

/// Practice history: overall accuracy, a bar per room, and the weak spot worth
/// working on next. Free for everyone. Stats about your own effort are not a
/// feature to sell back to you, and a free player who can see they are 58% in
/// the Auction Room has a reason to care about the drills that would fix it.
struct StatsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var records = PracticeRecordStore.shared
    @StateObject private var ledger = MasteryLedger.shared

    private var roomStats: [PracticeRecordStore.RoomStat] { records.roomStats() }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if records.totalAttempts == 0 {
                    emptyState
                } else {
                    summaryCard
                    if let gain = ledger.weeklyGain() {
                        weekCard(gain)
                    }
                    if let weakest = records.weakestRoom(), roomStats.count > 1 {
                        weakSpotCard(weakest)
                    }
                    roomBreakdown
                }
                streakCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.jade.opacity(0.5))
            Text("No practice yet")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text("Answer a few questions and your accuracy for every room shows up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    /// The week in one sentence. The bars below say where you stand; this
    /// says whether the practice is working, which is the question a player
    /// in their first week is actually asking.
    private func weekCard(_ gain: Int) -> some View {
        let strongest = ledger.strongestRoom().flatMap { DrillLibrary.room(id: $0.roomID) }
        return HStack(spacing: 12) {
            Image(systemName: "arrow.up.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.plum)
                .frame(width: 38, height: 38)
                .background(Theme.plum.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Up \(gain) questions this week")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(strongest.map { String(localized: "Biggest jump in \($0.name). Keep that pace and it holds.") }
                     ?? String(localized: "Questions you have now answered right twice running."))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            metric(value: percent(records.overallAccuracy), caption: String(localized: "accuracy"), color: Theme.jade)
            divider
            metric(value: "\(records.totalAttempts)", caption: String(localized: "answered"), color: Theme.ink)
            // A free player cannot reach the Timed Challenge, so a 0 here
            // reads as a score they failed to earn.
            if records.bestChallengeScore > 0 {
                divider
                metric(value: "\(records.bestChallengeScore)", caption: String(localized: "best challenge"), color: Theme.coral)
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    private func metric(value: String, caption: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.display(26))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.rule)
            .frame(width: 1, height: 34)
    }

    private func weakSpotCard(_ stat: PracticeRecordStore.RoomStat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 38, height: 38)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Work on \(stat.name)")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(stat.attempts == 1
                     ? String(localized: "\(percent(stat.accuracy)) right across 1 question, your lowest so far.")
                     : String(localized: "\(percent(stat.accuracy)) right across \(stat.attempts) questions, your lowest so far."))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private var roomBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY ROOM")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(roomStats) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(percent(stat.accuracy))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(barColor(stat.accuracy))
                            .monospacedDigit()
                    }
                    accuracyBar(stat.accuracy)
                    Text("\(stat.correct) of \(stat.attempts) right")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    private func accuracyBar(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.well)
                Capsule()
                    .fill(barColor(fraction))
                    .frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 38, height: 38)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.currentStreak())-day streak")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(progress.totalSessions) drills finished")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    // MARK: - Helpers

    private func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    private func barColor(_ fraction: Double) -> Color {
        if fraction >= 0.8 { return Theme.bamGreen }
        if fraction >= 0.6 { return Theme.gold }
        return Theme.coral
    }
}
