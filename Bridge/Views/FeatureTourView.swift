import SwiftUI

/// The post-trial feature tour: right after the trial decision, every player
/// gets a quick show of where things live. The Pro beat is premium-aware.
/// subscribers see what their trial already opened (shine, confetti), free
/// players see exactly what Pro would unlock, gleaming behind the lock.
struct FeatureTourView: View {
    let onDone: () -> Void

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var index = 0
    @State private var shineTrigger = 0
    @State private var confettiTrigger = 0
    @State private var showQuickSession = false

    private struct TourPage {
        let eyebrow: String
        let title: String
        let body: String
        let hero: AnyView
        /// Gold-accented "jackpot" beat (the Pro reveal), regardless of position.
        var accentGold: Bool = false
    }

    var body: some View {
        let pages = tourPages
        let page = pages[index]
        let isLast = index == pages.count - 1
        return VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { dot in
                    Capsule()
                        .fill(dot == index ? Theme.jade : Theme.jade.opacity(0.22))
                        .frame(width: dot == index ? 20 : 7, height: 7)
                        .animation(.snappy(duration: 0.22), value: index)
                }
            }
            .padding(.top, 10)
            if dynamicTypeSize.isAccessibilitySize {
                // At the largest sizes a page outgrows the screen and pushed
                // Show me and Skip below it with no way to reach them. The
                // page scrolls there, from the top on every page; the
                // buttons stay put.
                ScrollView { card(page) }
                    .id(index)
            } else {
                // Centred where it fits; scrolls on a small phone rather than
                // pushing the buttons off the screen.
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        card(page)
                        Spacer(minLength: 0)
                    }
                    ScrollView { card(page) }
                        .id(index)
                }
            }
            buttons(isLast: isLast, pageCount: pages.count)
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .fullScreenCover(isPresented: $showQuickSession, onDismiss: onDone) {
            quickSession
        }
        .onAppear { fireShine() }
    }

    private func card(_ page: TourPage) -> some View {
        VStack(spacing: 16) {
            Text(page.eyebrow)
                .font(.caption.weight(.heavy))
                .kerning(2)
                .foregroundStyle(page.accentGold ? Theme.gold : Theme.jade)
            page.hero
            Text(page.title)
                .font(Theme.display(27))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(page.body)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .themedCard(corner: 22)
        .shine(trigger: shineTrigger, corner: 22)
        .id(index)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // The escape hatch is offered on EVERY page, not just at the session
    // prompt: by the time someone has tapped through a trial page and a tour,
    // "let me just use the app" is a fair ask.
    private func buttons(isLast: Bool, pageCount: Int) -> some View {
        VStack(spacing: 10) {
            Button {
                advance(pageCount: pageCount)
            } label: {
                Text(isLast ? String(localized: "Start my first session") : String(localized: "Show me")).primaryCTA()
            }
            Button {
                Haptics.impact(.light, intensity: 0.6)
                onDone()
            } label: {
                Text(isLast ? String(localized: "Skip it, take me to the app") : String(localized: "Skip the tour"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private var quickSession: some View {
        NavigationStack {
            QuickSessionView(
                items: SessionBuilder.quickSession(
                    seen: progress.seenItems,
                    missed: progress.missedItems,
                    includePro: subscriptions.isPro
                ),
                isDaily: false,
                onClose: { showQuickSession = false }
            )
        }
    }

    // MARK: - Pages

    private var tourPages: [TourPage] {
        [
            TourPage(
                eyebrow: String(localized: "THE ROOMS"),
                title: String(localized: "Four rooms, four skills"),
                body: String(localized: "Home is the lobby. Each room holds its own drills: learn the rules, bid a hand, plan declarer play, and defend. All four beginner rooms are free, forever."),
                hero: AnyView(roomsHero)
            ),
            TourPage(
                eyebrow: String(localized: "KEEP IT LIT"),
                title: String(localized: "Streaks make it stick"),
                body: String(localized: "Finish a drill a day and your streak grows. Anything you miss quietly returns until you own it."),
                hero: AnyView(streakHero)
            ),
            subscriptions.isPro
                ? TourPage(
                    eyebrow: String(localized: "YOURS NOW"),
                    title: String(localized: "\(Membership.name) is open"),
                    body: subscriptions.isTrialing
                        ? String(localized: "Your free week already includes Endless Practice, the timed challenge, the extra sets in every room, and the Master Tables: conventions, advanced play, and duplicate decisions.")
                        : String(localized: "Your membership already includes Endless Practice, the timed challenge, the extra sets in every room, and the Master Tables: conventions, advanced play, and duplicate decisions."),
                    hero: AnyView(proHero(locked: false)),
                    accentGold: true
                )
                : TourPage(
                    eyebrow: String(localized: "BEHIND THE GOLD DOOR"),
                    title: String(localized: "\(Membership.name) adds more of it"),
                    body: String(localized: "Endless Practice deals hands that never run out, every room keeps a set of extra drills behind the lock, and the Master Tables hold the advanced ones. Nothing you have now goes away. Unlock any time from Home or Settings."),
                    hero: AnyView(proHero(locked: true)),
                    accentGold: true
                ),
            // Last on purpose: this is the one page whose CTA is real. Tapping
            // it opens an actual Quick Session, not a preview of one.
            TourPage(
                eyebrow: String(localized: "YOUR TURN"),
                title: String(localized: "Let's try a real one"),
                body: String(localized: "Get Started builds this same five-minute mix any time from Home: exactly what you need next, misses first. Let's run your first one now."),
                hero: AnyView(getStartedHero)
            ),
        ]
    }

    // MARK: - Heroes

    /// A live replica of Home's Get Started card, not a picture of one: it
    /// looks like a button because it IS one, and tapping it opens the same
    /// real Quick Session as the CTA below.
    private var getStartedHero: some View {
        Button {
            startQuickSession()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Started")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.onFill)
                    Text("A five-minute mix of what you need next")
                        .font(.caption)
                        .foregroundStyle(Theme.onFill.opacity(0.9))
                }
                Spacer(minLength: 4)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.onFill)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Theme.jade, Theme.jade.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
    }

    private var roomsHero: some View {
        HStack(spacing: 10) {
            roomChip("suit.spade.fill", Theme.jade)
            roomChip("quote.bubble.fill", Theme.coral)
            roomChip("hand.point.up.left.fill", Theme.plum)
            roomChip("shield.lefthalf.filled", Theme.gold)
        }
    }

    private func roomChip(_ icon: String, _ color: Color) -> some View {
        Image(systemName: icon)
            .font(.body.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: 54, height: 54)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var streakHero: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.coral)
            Text("7-day streak")
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.coral.opacity(0.10), in: Capsule())
    }

    private func proHero(locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: locked ? "lock.fill" : "sparkles")
                    .foregroundStyle(Theme.gold)
                Text(Membership.name.uppercased())
                    .font(.caption.weight(.heavy))
                    .kerning(1.6)
                    .foregroundStyle(Theme.goldText)
                Spacer()
                if !locked {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.jade)
                }
            }
            // The same three modes the paywall leads with. Extra sets and the
            // Master Tables are carried by the page body, so the hero does not
            // have to say everything.
            ForEach([String(localized: "Endless Practice, never repeats"), String(localized: "Fix My Mistakes replays your misses"), String(localized: "Timed Challenge, 90 seconds")], id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: locked ? "sparkles" : "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(locked ? Theme.gold : Theme.jade)
                    // Wrap, never truncate: on an iPhone SE and at larger
                    // sizes all three lines lost their second half.
                    Text(line)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Flow

    /// The finale is genuinely actionable: it opens a real Quick Session
    /// rather than just advancing a tour page. The tour only finishes
    /// (`onDone`) once that session's `fullScreenCover` is dismissed.
    private func startQuickSession() {
        Haptics.success()
        showQuickSession = true
    }

    private func advance(pageCount: Int) {
        if index == pageCount - 1 {
            startQuickSession()
            return
        }
        Haptics.impact(.soft, intensity: 0.6)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            index += 1
        }
        if tourPages[index].accentGold {
            // The Pro beat is the jackpot moment either way.
            confettiTrigger += 1
        }
        fireShine()
    }

    private func fireShine() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            shineTrigger += 1
        }
    }
}
