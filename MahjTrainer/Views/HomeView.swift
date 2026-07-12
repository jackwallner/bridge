import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false
    @State private var showSettings = false
    @AppStorage("mahj.skillLevel") private var skillLevel = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    getStartedCard
                    if skillLevel == "new" {
                        howToPlayCard
                    }
                    statsHeader
                    ForEach(DrillLibrary.rooms) { room in
                        section(for: room)
                    }
                    disclaimerFooter
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .tint(Theme.jade)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mahj Trainer")
                .font(Theme.display(34))
                .foregroundStyle(Theme.ink)
            Text("Your seat at the table.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    /// The one-tap way in: builds a short mixed session, no browsing needed.
    private var getStartedCard: some View {
        NavigationLink {
            MixedSessionView(items: SessionBuilder.dailyMix(
                seen: progress.seenItems,
                missed: progress.missedItems,
                includePro: subscriptions.isPro
            ))
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Started")
                        .font(Theme.display(24))
                        .foregroundStyle(.white)
                    Text("A five-minute mix of what you need next")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 4)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Theme.jade, Theme.jade.opacity(0.82)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
            )
            .shadow(color: Theme.jade.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Brand-new players keep a door back to the primer until it sticks.
    private var howToPlayCard: some View {
        NavigationLink {
            HowToPlayView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("How to Play")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("The five-minute primer, any time you want it")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(12)
            .themedCard(corner: 16)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var statsHeader: some View {
        HStack(spacing: 12) {
            statTile(value: "\(progress.streakCount)", label: "Day streak", icon: "flame.fill", color: Theme.coral)
            statTile(value: "\(progress.totalSessions)", label: "Drills done", icon: "checkmark.seal.fill", color: Theme.jade)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .themedCard(corner: 16)
    }

    // MARK: - Drill sections (flat: every drill is one tap from here)

    private func section(for room: Room) -> some View {
        let locked = !room.isFree && !subscriptions.isPro
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: room.icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(room.accent)
                Text(room.name.uppercased())
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                if locked {
                    Text("PRO")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.gold.opacity(0.15), in: Capsule())
                }
            }
            .padding(.horizontal, 4)
            ForEach(room.drills) { drill in
                drillRow(drill, room: room, locked: locked)
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func drillRow(_ drill: Drill, room: Room, locked: Bool) -> some View {
        if locked {
            Button {
                showPaywall = true
            } label: {
                drillRowBody(drill, room: room, locked: true)
            }
            .buttonStyle(PressableCardStyle())
        } else {
            NavigationLink {
                drillDestination(drill, room: room)
            } label: {
                drillRowBody(drill, room: room, locked: false)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    private func drillRowBody(_ drill: Drill, room: Room, locked: Bool) -> some View {
        let done = progress.completions(for: drill.id) > 0
        return HStack(spacing: 14) {
            Image(systemName: drill.kind.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(locked ? room.accent.opacity(0.55) : room.accent)
                .frame(width: 42, height: 42)
                .background(room.accent.opacity(locked ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(drill.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(drill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
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
        .themedCard(corner: 16)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func drillDestination(_ drill: Drill, room: Room) -> some View {
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

    private var disclaimerFooter: some View {
        Text("Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.")
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

extension DrillKind {
    var symbol: String {
        switch self {
        case .flashcards: return "rectangle.stack.fill"
        case .quiz: return "questionmark.circle.fill"
        case .handMatch: return "square.grid.3x3.fill"
        case .charleston: return "arrow.left.arrow.right"
        }
    }

    var unitName: String {
        switch self {
        case .flashcards: return "cards"
        case .quiz: return "questions"
        case .handMatch: return "racks"
        case .charleston: return "deals"
        }
    }
}
