import SwiftUI

/// One room, its drills. Free drills open; Mahj+ extra sets show the lock and
/// route to the paywall. A locked room (the Master Tables) locks every row.
struct RoomView: View {
    let room: Room

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false

    private var roomLocked: Bool { !room.isFree && !subscriptions.isPro }
    private var lockedCount: Int {
        room.drills.filter { room.isLocked($0, isMember: subscriptions.isPro) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                RoomArt(room: room, height: 150, dimmed: roomLocked)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                header
                ForEach(room.drills) { drill in
                    drillRow(drill)
                }
                if lockedCount > 0 {
                    upsell
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(room.name)
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(room.tagline)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func drillRow(_ drill: Drill) -> some View {
        let locked = room.isLocked(drill, isMember: subscriptions.isPro)
        if locked {
            Button {
                showPaywall = true
            } label: {
                drillRowBody(drill, locked: true)
            }
            .buttonStyle(PressableCardStyle())
        } else {
            NavigationLink {
                destination(drill)
            } label: {
                drillRowBody(drill, locked: false)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    private func drillRowBody(_ drill: Drill, locked: Bool) -> some View {
        let done = progress.completions(for: drill.id) > 0
        return HStack(spacing: 14) {
            Image(systemName: drill.kind.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(locked ? room.accent.opacity(0.55) : room.accent)
                .frame(width: 42, height: 42)
                .background(room.accent.opacity(locked ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(drill.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    if locked {
                        PlusBadge()
                    }
                }
                Text(drill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text("\(drill.kind.itemCount) \(drill.kind.unitName)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
            }
            Spacer(minLength: 4)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.gold)
            } else if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(room.accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .themedCard(corner: 16)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Says exactly what the money buys IN THIS ROOM, which is the whole point
    /// of the extra sets: same drills, more reps.
    private var upsell: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.gold)
                    Text("\(lockedCount) more \(lockedCount == 1 ? "drill" : "drills") in this room")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                }
                Text("\(Membership.name) unlocks the extra sets here and in every other room, plus the Master Tables. Everything you already have stays free.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(Theme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
        .padding(.top, 4)
    }

    @ViewBuilder
    private func destination(_ drill: Drill) -> some View {
        switch drill.kind {
        case .flashcards(let cards):
            FlashcardDrillView(drill: drill, cards: cards, accent: room.accent)
        case .quiz(let questions):
            QuizDrillView(drill: drill, questions: questions)
        case .handMatch(let questions):
            HandMatchDrillView(drill: drill, questions: questions)
        case .charleston(let scenarios):
            CharlestonDrillView(drill: drill, scenarios: scenarios)
        }
    }
}
