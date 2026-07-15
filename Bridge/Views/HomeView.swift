import SwiftUI

/// Home is the lobby: Get Started, then the rooms as doors. The drills
/// themselves live one level down in `RoomView`. (Home used to list every
/// drill flat; once each room grew a Bridge+ extra set that list ran to a dozen
/// rows and the rooms stopped reading as places.)
///
/// The rooms are what Home is FOR, so everything else earns its space or
/// leaves: the stats ride beside the title instead of eating a row of their
/// own, and the primer card disappears the moment it has been read.
struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var highlightedRoomID: String?
    @AppStorage("bridge.skillLevel") private var skillLevel = ""
    /// Set once the primer has been read all the way through. After that it
    /// lives in Settings only; a permanent "How to Play" card on Home is a
    /// standing tax on the rooms below it.
    @AppStorage("bridge.hasReadPrimer") private var hasReadPrimer = false
    /// One-shot hint set by `HowToPlayView`'s end-of-primer recommendation:
    /// the room id to highlight/scroll to the next time Home appears.
    @AppStorage("bridge.recommendedRoomHint") private var recommendedRoomHint = ""

    private var showsPrimerCard: Bool { skillLevel == "new" && !hasReadPrimer }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        if progress.quickSessionCompletedToday() {
                            getStartedDoneCard
                        } else {
                            getStartedCard
                        }
                        if showsPrimerCard {
                            howToPlayCard
                        }
                        roomsHeading
                        ForEach(DrillLibrary.rooms) { room in
                            roomCard(room)
                        }
                        if !subscriptions.isPro {
                            upgradeCard
                        }
                        disclaimerFooter
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .onAppear { consumeRecommendedRoomHint(proxy: proxy) }
                .onChange(of: showSettings) { _, isShowing in
                    if !isShowing { consumeRecommendedRoomHint(proxy: proxy) }
                }
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

    /// Consumes the one-shot recommendation hint: scrolls to and briefly
    /// highlights the recommended room's card, then clears the hint so it
    /// only ever fires once per recommendation.
    private func consumeRecommendedRoomHint(proxy: ScrollViewProxy) {
        guard !recommendedRoomHint.isEmpty else { return }
        let roomID = recommendedRoomHint
        recommendedRoomHint = ""
        guard DrillLibrary.rooms.contains(where: { $0.id == roomID }) else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                proxy.scrollTo(roomID, anchor: .center)
                highlightedRoomID = roomID
            }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(.easeOut(duration: 0.4)) { highlightedRoomID = nil }
        }
    }

    // MARK: - Header (title left, stats right, one row total)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bridge Trainer")
                    .font(Theme.display(32))
                    .foregroundStyle(Theme.ink)
                Text("Your seat at the table.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                statChip(value: progress.streakCount, icon: "flame.fill", color: Theme.coral,
                         label: "\(progress.streakCount) day streak")
                statChip(value: progress.totalSessions, icon: "checkmark.seal.fill", color: Theme.jade,
                         label: "\(progress.totalSessions) drills done")
            }
            .padding(.top, 4)
        }
        .padding(.top, 2)
    }

    private func statChip(value: Int, icon: String, color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    /// The one-tap way in: builds a short mixed session, no browsing needed.
    private var getStartedCard: some View {
        NavigationLink {
            QuickSessionView(items: SessionBuilder.quickSession(
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

    /// Today's Get Started is spent. Rather than hand back the same questions
    /// (a repeat teaches nothing), the card rests and points at the rooms for
    /// more practice, and comes back fresh tomorrow.
    private var getStartedDoneCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.jade)
                .frame(width: 44, height: 44)
                .background(Theme.jade.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Today's session is done")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("A fresh mix lands tomorrow. Keep going in any room below.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    /// Shown only until the primer has actually been read; after that it's a
    /// Settings row like every other reference material.
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
                    Text("New here? Start with the five-minute primer")
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

    // MARK: - Rooms

    private var roomsHeading: some View {
        HStack {
            Text("THE ROOMS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }

    /// Progress is a ring, not a sentence. "2 of 3 done · 2 free, 1 with Bridge+"
    /// was three facts nobody asked for on a card whose job is to be a door.
    private func roomCard(_ room: Room) -> some View {
        let locked = !room.isFree && !subscriptions.isPro
        let highlighted = highlightedRoomID == room.id
        // Count only the drills this player can actually open. Putting the
        // locked Bridge+ set in the denominator would mean a free player's ring
        // can never close, which is a nag dressed up as progress.
        let open = room.drills.filter { !room.isLocked($0, isMember: subscriptions.isPro) }
        let total = open.count
        let done = open.filter { progress.completions(for: $0.id) > 0 }.count
        return NavigationLink {
            RoomView(room: room)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: room.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(room.accent)
                    .frame(width: 48, height: 48)
                    .background(room.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(room.name)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        if locked {
                            PlusBadge()
                        }
                    }
                    Text(room.tagline)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.gold)
                } else {
                    ProgressRing(done: done, total: total, color: room.accent)
                }
            }
            .padding(14)
            .themedCard()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(highlighted ? room.accent : Color.clear, lineWidth: 2.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint(locked
            ? "Locked. \(total) drills, included with \(Membership.name)"
            : "\(done) of \(total) drills done")
        .id(room.id)
    }

    private var upgradeCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get \(Membership.name)")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(lockedDrillCount) more drills across every room, plus the Master Tables")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(12)
            .themedCard(corner: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
        .padding(.top, 2)
    }

    private var lockedDrillCount: Int {
        DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount }
    }

    private var disclaimerFooter: some View {
        Text("Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.")
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

/// Room completion at a glance: a ring that fills as the room's drills get
/// done, and becomes a seal once they all are.
struct ProgressRing: View {
    let done: Int
    let total: Int
    var color: Color

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(done) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
            if done == total, total > 0 {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(color)
            } else {
                Text("\(done)/\(total)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                    .monospacedDigit()
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

extension DrillKind {
    var symbol: String {
        switch self {
        case .flashcards: return "rectangle.stack.fill"
        case .quiz: return "questionmark.circle.fill"
        case .handMatch: return "square.grid.3x3.fill"
        case .play: return "arrow.left.arrow.right"
        }
    }

    var unitName: String {
        switch self {
        case .flashcards: return "cards"
        case .quiz: return "questions"
        case .handMatch: return "hands"
        case .play: return "deals"
        }
    }
}
