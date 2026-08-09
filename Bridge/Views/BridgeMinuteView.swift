import StoreKit
import SwiftUI

struct BridgeMinuteView: View {
    @StateObject private var store = BridgeMinuteStore.shared

    private var today: Date { Date() }
    private var challenge: BridgeMinuteChallenge { BridgeMinuteContent.challenge(for: today) }
    private var todayResult: BridgeMinuteResult? { store.result(for: today) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                weeklyRhythm
                archive
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Bridge Minute")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: todayResult == nil ? "calendar.badge.clock" : "checkmark.seal.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(todayResult == nil ? Theme.coral : Theme.jade)
                .frame(width: 68, height: 68)
                .background((todayResult == nil ? Theme.coral : Theme.jade).opacity(0.13), in: Circle())
            VStack(spacing: 5) {
                Text("Today's Bridge Minute")
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                Text("The same five original questions for every member: two opening calls, one declarer decision, and two defensive judgments.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let todayResult {
                NavigationLink {
                    BridgeMinuteResultView(result: todayResult)
                } label: {
                    Text("View Today's \(todayResult.score)/\(todayResult.total)").primaryCTA()
                }
            } else {
                NavigationLink {
                    QuickSessionView(bridgeMinute: challenge)
                } label: {
                    Text("Start Today's Challenge").primaryCTA(color: Theme.coral)
                }
            }
        }
        .padding(20)
        .themedCard()
    }

    private var weeklyRhythm: some View {
        let completed = min(store.completedThisWeek(), 5)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR WEEK")
                        .font(.caption.weight(.heavy))
                        .kerning(1.4)
                        .foregroundStyle(Theme.inkSecondary)
                    Text(completed >= 5 ? "Weekly goal complete" : "\(completed) of 5 practiced")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                Image(systemName: completed >= 5 ? "checkmark.seal.fill" : "calendar")
                    .foregroundStyle(completed >= 5 ? Theme.jade : Theme.coral)
            }
            HStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? Theme.coral : Theme.well)
                        .overlay {
                            if index < completed {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 34, height: 34)
                }
            }
            Text("Any five days count. Miss one, catch up from the archive, and keep the week alive.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private var archive: some View {
        let dates = store.archiveDates()
        return VStack(alignment: .leading, spacing: 10) {
            Text("ARCHIVE")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(dates, id: \.self) { date in
                    archiveRow(date)
                    if date != dates.last {
                        Divider().overlay(Theme.rule)
                    }
                }
            }
            .themedCard(corner: 16)
        }
    }

    @ViewBuilder
    private func archiveRow(_ date: Date) -> some View {
        let result = store.result(for: date)
        NavigationLink {
            if let result {
                BridgeMinuteResultView(result: result)
            } else {
                QuickSessionView(bridgeMinute: BridgeMinuteContent.challenge(for: date))
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result == nil ? "play.circle" : "checkmark.circle.fill")
                    .foregroundStyle(result == nil ? Theme.coral : Theme.jade)
                    .frame(width: 28)
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(result.map { "\($0.score)/\($0.total)" } ?? "Play")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(result == nil ? Theme.coral : Theme.jade)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct BridgeMinuteResultView: View {
    let result: BridgeMinuteResult
    var recordsCompletion = false
    var onDone: (() -> Void)?

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @StateObject private var store = BridgeMinuteStore.shared
    @State private var recorded = false
    @State private var showReviewPrompt = false
    @State private var confettiTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                scoreCard
                breakdown
                weeklyCard
                ShareLink(item: result.shareText) {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                        .primaryCTA(color: Theme.coral)
                }
                Button("Done") {
                    if let onDone { onDone() } else { dismiss() }
                }
                .font(.headline)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.vertical, 8)
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.22), particleCount: 44) }
        .navigationTitle("Bridge Minute")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(recordsCompletion)
        .onAppear { recordCompletionIfNeeded() }
        .sheet(isPresented: $showReviewPrompt) {
            ReviewPromptSheet { outcome in
                if outcome == .enjoyedMaybeLater { requestReview() }
            }
        }
    }

    private var scoreCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 122, height: 122)
                VStack(spacing: 1) {
                    Text("\(result.score)/\(result.total)")
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.jade)
                        .monospacedDigit()
                    Text("right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Text(result.score == result.total ? "Perfect minute!" : "Minute complete")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
            Text("Bridge Minute \(result.shortDate)")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY SKILL")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(BridgeMinuteCategory.allCases) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .foregroundStyle(color(for: category))
                        .frame(width: 30)
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(result.correct(in: category))/\(result.total(in: category))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color(for: category))
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private var weeklyCard: some View {
        let completed = min(store.completedThisWeek(), 5)
        return HStack(spacing: 12) {
            Image(systemName: completed >= 5 ? "checkmark.seal.fill" : "calendar.badge.checkmark")
                .foregroundStyle(completed >= 5 ? Theme.jade : Theme.coral)
                .frame(width: 38, height: 38)
                .background((completed >= 5 ? Theme.jade : Theme.coral).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(completed >= 5 ? "Weekly goal complete" : "\(completed) of 5 this week")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("Any five days keep the rhythm going.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private func color(for category: BridgeMinuteCategory) -> Color {
        let correct = result.correct(in: category)
        let total = result.total(in: category)
        if correct == total { return Theme.jade }
        if correct > 0 { return Theme.gold }
        return Theme.coral
    }

    private func recordCompletionIfNeeded() {
        guard recordsCompletion, !recorded else { return }
        recorded = true
        confettiTrigger += 1
        Haptics.success()
        SoundPlayer.play(.complete)
        progress.recordSession(drillID: BridgeMinuteContent.drill.id)
        ReviewPromptTracker.recordPositiveMoment()
        guard ReviewPromptTracker.shouldShowAfterPositiveMoment() else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showReviewPrompt = true
        }
    }
}
