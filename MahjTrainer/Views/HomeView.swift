import SwiftUI

/// Home is the lobby: Get Started, then the rooms as doors. The drills
/// themselves live one level down in `RoomView`. (Home used to list every
/// drill flat; once each room grew a Mahj+ extra set that list ran to a dozen
/// rows and the rooms stopped reading as places.)
struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var highlightedRoomID: String?
    @AppStorage("mahj.skillLevel") private var skillLevel = ""
    /// One-shot hint set by `HowToPlayView`'s end-of-primer recommendation:
    /// the room id to highlight/scroll to the next time Home appears.
    @AppStorage("mahj.recommendedRoomHint") private var recommendedRoomHint = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        getStartedCard
                        if skillLevel == "new" {
                            howToPlayCard
                        }
                        statsHeader
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

    // MARK: - Rooms

    private var roomsHeading: some View {
        HStack {
            Text("THE ROOMS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
        .padding(.top, 4)
        .padding(.horizontal, 4)
    }

    private func roomCard(_ room: Room) -> some View {
        let locked = !room.isFree && !subscriptions.isPro
        let highlighted = highlightedRoomID == room.id
        let done = room.drills.filter { progress.completions(for: $0.id) > 0 }.count
        return NavigationLink {
            RoomView(room: room)
        } label: {
            VStack(spacing: 0) {
                RoomArt(room: room, height: 96, dimmed: locked)
                HStack(spacing: 12) {
                    Image(systemName: room.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(room.accent)
                        .frame(width: 42, height: 42)
                        .background(room.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        Text(subtitle(for: room, done: done, locked: locked))
                            .font(.caption)
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: locked ? "lock.fill" : "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(locked ? Theme.gold : Theme.inkTertiary)
                }
                .padding(14)
            }
            .themedCard()
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(highlighted ? room.accent : Color.clear, lineWidth: 2.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .id(room.id)
    }

    /// The room's one-line status. For free rooms this is where the extra sets
    /// announce themselves, so the upgrade reads as "more of what you like".
    private func subtitle(for room: Room, done: Int, locked: Bool) -> String {
        if locked {
            return "\(room.drills.count) advanced drills"
        }
        let extras = room.drills.filter(\.isPlus).count
        let free = room.drills.count - extras
        var parts = ["\(done) of \(room.drills.count) done"]
        if extras > 0, !subscriptions.isPro {
            parts.append("\(free) free, \(extras) with \(Membership.name)")
        }
        return parts.joined(separator: " · ")
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
    }

    private var lockedDrillCount: Int {
        DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount }
    }

    private var disclaimerFooter: some View {
        Text("Mahj Trainer teaches skills for American Mah Jongg with original practice hands. It is not affiliated with the National Mah Jongg League. For official hands and values, get the current NMJL card.")
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

/// The room's illustration banner. Decorative only: if the asset is missing
/// (or was never generated) the card falls back to a tinted wash, so nothing
/// here is load-bearing.
struct RoomArt: View {
    let room: Room
    var height: CGFloat
    var dimmed: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [room.accent.opacity(0.22), room.accent.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if let image = UIImage(named: room.artName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .saturation(dimmed ? 0.35 : 1)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Theme.card.opacity(0), Theme.card],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 22)
        }
        .allowsHitTesting(false)
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
