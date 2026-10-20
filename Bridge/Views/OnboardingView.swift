import SwiftUI

/// Onboarding: three value pages, a skill-level question, then the OT710-style
/// trial step. The primary button keeps IDENTICAL geometry on every page (the
/// zero-shift rule): the thumb rides Continue the whole way, and on the last
/// page the same button becomes "Start 7-day free trial", one tap straight
/// to Apple's confirm. No plan cards here; the full paywall is only a fallback
/// when products failed to load. This page is the proven trial flow: change
/// the button's wording through a RevenueCat Experiment (`TrialCTA`), not here.
///
/// After the trial decision (either way), brand-new players get the How to
/// Play quick start FIRST, then everyone gets the feature tour, whose finale
/// runs a real Quick Session. The primer has to come before that session:
/// answering questions about cards you haven't met yet is not an onboarding.
/// Only once the tour is done does `hasOnboarded` flip and Home appear.
struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var page = 0
    @State private var purchasing = false
    @State private var restoring = false
    @State private var showPaywallFallback = false
    @State private var purchaseError: String?
    @AppStorage("bridge.skillLevel") private var skillLevel = ""

    private enum Stage: Equatable { case pages, tour, howToPlay }
    @State private var stage: Stage = .pages

    private let lastPage = 4
    private let skillPage = 3

    var body: some View {
        Group {
            switch stage {
            case .pages:
                pagesBody
            case .howToPlay:
                // Skip lands on Home, not on the next onboarding step: the
                // whole point of an escape hatch is that it escapes.
                HowToPlayView(onDone: { stage = .tour }, onSkip: { finish() })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .tour:
                FeatureTourView { finish() }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: stage)
    }

    private var pagesBody: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                infoPage(
                    icon: "suit.spade.fill",
                    title: "Make it stick between games",
                    body: "Bridge fades fast between games. Bridge Trainer gives you five-minute drills you can run anywhere, whether you are meeting the deck or sharpening instincts you already have.",
                    cards: [.s(.ace), .h(.king), .d(.queen), .c(.jack)]
                ).tag(0).accessibilityHidden(page != 0)
                infoPage(
                    icon: "rectangle.stack.fill",
                    title: "Practice, not pressure",
                    body: "Swipe through flashcards, count points, choose opening bids, and make card-play decisions, with the why behind every answer.",
                    cards: [.s(.ace), .s(.king), .s(.queen), .s(.jack)]
                ).tag(1).accessibilityHidden(page != 1)
                infoPage(
                    icon: "figure.walk",
                    title: "Walk in confident",
                    body: "Read an opening hand, plan a contract, and defend with purpose. Practice at your own pace, with no timers and no opponents.",
                    cards: [.h(.ace), .d(.ace), .c(.ace)]
                ).tag(2).accessibilityHidden(page != 2)
                skillLevelPage.tag(3).accessibilityHidden(page != 3)
                trialPage.tag(4).accessibilityHidden(page != 4)
            }
            // A paged TabView keeps every page built, so without this VoiceOver
            // walks off the first screen straight into the trial page's price,
            // Restore, Terms and Privacy controls before they are visible.
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
            footer
        }
        .background(Theme.background)
        .onChange(of: page) { _, newPage in
            // The TabView pages by swipe too, and only the Continue button is
            // gated on a skill choice: a swipe must not skip the question.
            if newPage > skillPage, skillLevel.isEmpty {
                page = skillPage
                return
            }
            guard newPage == lastPage else { return }
            subscriptions.trackPaywallImpression(id: "bridge_onboarding_trial", oncePerSession: true)
        }
        .sheet(isPresented: $showPaywallFallback, onDismiss: paywallDismissed) {
            PaywallView(source: "bridge_onboarding_fallback")
        }
        .alert("Bridge Trainer", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "")
        }
    }

    /// A page that sits a little above centre when it fits, as designed, and
    /// scrolls when it does not: at the largest text sizes the heading and the
    /// first skill choice used to sit above the screen with no way to reach them.
    private func fittedPage<Content: View>(spacing: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
        let content = content()
        return ViewThatFits(in: .vertical) {
            VStack(spacing: spacing) {
                Spacer()
                content
                Spacer()
                Spacer()
            }
            ScrollView {
                VStack(spacing: spacing) { content }
                    .padding(.vertical, 24)
            }
        }
        .padding(.horizontal, 28)
    }

    /// On an iPhone SE the full page is one line taller than the space above
    /// the footer, and the first screen anyone sees ended in a half-cut line.
    /// There the icon goes, which is decoration; the words and cards stay.
    /// Every larger phone and iPad still gets the full page, as in 1.3.2.
    private func infoPage(icon: String, title: String, body bodyText: String, cards: [BridgeCard]) -> some View {
        let full = VStack(spacing: 26) {
            infoIcon(icon)
            infoText(title: title, body: bodyText, cards: cards)
        }
        return ViewThatFits(in: .vertical) {
            ContentFit(margin: 26 + 8) {
                full.hidden().accessibilityHidden(true)
                VStack(spacing: 26) {
                    Spacer()
                    full
                    Spacer()
                    Spacer()
                }
            }
            // No icon, and no padding around the spacers either: on an SE
            // at XXXL those 70pt were the difference between the whole page
            // and a two-line sliver that scrolled.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                infoText(title: title, body: bodyText, cards: cards)
                Spacer(minLength: 0)
            }
            ScrollView {
                full.padding(.vertical, 24)
            }
            .scrollIndicatorsFlash(trigger: page)
        }
        .padding(.horizontal, 28)
    }

    private func infoIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(Theme.jade)
            .frame(width: 92, height: 92)
            .background(Theme.jade.opacity(0.12), in: Circle())
    }

    private func infoText(title: String, body bodyText: String, cards: [BridgeCard]) -> some View {
        VStack(spacing: 26) {
            Text(title)
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            BridgeHandView(cards: cards, cardWidth: 54)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Skill level

    private struct SkillOption {
        let id: String
        let title: String
        let detail: String
    }

    private let skillOptions: [SkillOption] = [
        SkillOption(id: "new", title: "Brand new", detail: "Still learning what the cards even are"),
        SkillOption(id: "basics", title: "Know the basics", detail: "Know tricks and points, still slow in the auction"),
        SkillOption(id: "played", title: "Played real games", detail: "Comfortable, want sharper instincts"),
    ]

    /// Full page as in 1.3.2. On an iPhone SE it overflowed by a card's last
    /// line, so there the subtitle goes and the gaps tighten before it falls
    /// back to scrolling.
    private var skillLevelPage: some View {
        ViewThatFits(in: .vertical) {
            ContentFit(margin: 22 + 8) {
                skillContent(compact: false).hidden().accessibilityHidden(true)
                VStack(spacing: 22) {
                    Spacer()
                    skillContent(compact: false)
                    Spacer()
                    Spacer()
                }
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                skillContent(compact: true)
                Spacer(minLength: 0)
            }
            // The bar flashes as the page arrives: a cut-off last choice
            // is the only other sign that there is more below.
            ScrollView {
                skillContent(compact: false).padding(.vertical, 24)
            }
            .scrollIndicatorsFlash(trigger: page)
        }
        .padding(.horizontal, 28)
    }

    private func skillContent(compact: Bool) -> some View {
        VStack(spacing: compact ? 14 : 22) {
            Text("Where are you starting from?")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !compact {
                Text("We'll point you at the right drills.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
            }
            VStack(spacing: compact ? 10 : 12) {
                ForEach(skillOptions, id: \.id) { option in
                    skillCard(option)
                }
            }
            Text(skillLevel.isEmpty ? "Pick one to continue." : " ")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func skillCard(_ option: SkillOption) -> some View {
        let selected = skillLevel == option.id
        return Button {
            skillLevel = option.id
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(option.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        // Wrap rather than truncate. Bridge's strings fit today,
                        // but the HStack will compress this to one line and
                        // clip it on a narrow phone or at larger type sizes.
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Theme.jade : Theme.inkTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selected ? Theme.jade.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Theme.jade : Theme.rule, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Trial step (OT710: hero + bullets, zero plan cards)

    /// Frozen at 1.3.2. Below the accessibility sizes this is 1.3.2's page
    /// exactly: same stack, same spacers, benefit lines on one line each.
    /// Only at accessibility sizes, where 1.3.2 pushed the heading off the
    /// screen and squeezed the CTA, does the page scroll and carry the price,
    /// the free exit and the legal links.
    @ViewBuilder
    private var trialPage: some View {
        if dynamicTypeSize.isAccessibilitySize {
            fittedPage(spacing: 22) {
                trialHeader
                trialBenefits
                if !subscriptions.isPro {
                    priceSlot
                    softExit
                    legalRow
                }
            }
        } else {
            VStack(spacing: 22) {
                Spacer()
                trialHeader
                trialBenefits
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }

    @ViewBuilder
    private var trialHeader: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(Theme.gold)
            .frame(width: 92, height: 92)
            .background(Theme.gold.opacity(0.14), in: Circle())
        Text(trialPageTitle)
            .font(Theme.display(30))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.center)
    }

    private static let trialBenefitLines = [
        "Every beginner room is free, forever",
        "Endless Practice deals a fresh hand every time",
        "Fix My Mistakes brings back what you miss",
        "Extra sets in all four rooms, plus the Master Tables",
    ]

    private var trialBenefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Self.trialBenefitLines, id: \.self) { trialBenefit($0) }
        }
    }

    private func trialBenefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                // Wraps only where the page scrolls; elsewhere one line, as in 1.3.2.
                .fixedSize(horizontal: false, vertical: dynamicTypeSize.isAccessibilitySize)
        }
    }

    private var trialPageTitle: String {
        if subscriptions.isPro { return "\(Membership.name) is on your account" }
        return "Try \(Membership.name) free"
    }

    /// The plan this tap buys: monthly. The price line and disclosure below
    /// always name it.
    private var onboardingPlan: PaywallPlan { .monthly }

    /// The billed amount, shown larger than anything else about price on the
    /// trial page (App Review 3.1.2(c)). Same plan as the CTA buys; empty for
    /// a member, who is not being charged.
    private var trialPrice: String {
        subscriptions.isPro ? "" : PaywallPricing.priceText(subscriptions, onboardingPlan)
    }

    /// One concise line, matching the approved fleet pattern (StatScout): trial
    /// length, price, that it renews, how to cancel. The EULA behind the Terms
    /// link carries the full legalese; this is the point-of-purchase micro copy.
    ///
    /// Must name the SAME plan the CTA buys (`onboardingPlan`), or it
    /// misstates what the player is charged, which is a 3.1.2 problem and a
    /// refund magnet.
    /// If the product has not loaded, drop the amount rather than invent one.
    private var trialDisclosure: String {
        // Nobody is being charged anything here, so quoting a price would be
        // a lie about the button next to it.
        if subscriptions.isPro { return "" }
        return PaywallPricing.terms(amount: PaywallPricing.price(subscriptions, onboardingPlan), plan: onboardingPlan)
    }

    /// A player who already owns \(Membership.name) is not a trial prospect.
    /// A reinstall, or a second device on the same Apple Account, restores the
    /// entitlement before onboarding is finished, and this page went on
    /// offering to sell it to them: the tap ran a purchase for a subscription
    /// they already hold, which Apple answers with its own confusing
    /// "you're already subscribed" sheet. Recognise them and just let them in.
    private var trialCTATitle: String {
        if subscriptions.isPro { return "Continue" }
        return subscriptions.trialCTA(.onboarding)
    }

    // MARK: - Footer (identical geometry on every page: zero-shift CTA)

    private var footer: some View {
        let onTrialPage = page == lastPage
        // The empty trial slots are reserved on every page so the CTA never
        // moves. At accessibility sizes they grew to a third of the screen
        // of invisible text and squeezed the page above into a sliver, so
        // there they move into the trial page's own scrolling content.
        let reservesTrialSlots = !dynamicTypeSize.isAccessibilitySize
        return VStack(spacing: 8) {
            pageDots
            // Soft free exit sits ABOVE the primary so the trial CTA owns the
            // Continue slot. "Get Started" (not "Skip"/"No trial") on purpose,
            // matching the approved fleet apps: it's the free way in, worded so
            // it doesn't read as a loud "escape the offer" button. Height
            // reserved on every page.
            if reservesTrialSlots {
                softExit
                    .opacity(onTrialPage && !subscriptions.isPro ? 1 : 0)
                    .accessibilityHidden(!onTrialPage || subscriptions.isPro)
                // Pricing slot, reserved on every page. The billed amount is the
                // most conspicuous pricing element (App Review 3.1.2(c) flagged
                // the trial outshining it); the disclosure under it stays small.
                // Cribbage Trainer's approved fix, ported as-is. minHeight so the
                // disclosure can wrap without moving the CTA on any page.
                priceSlot
                    .opacity(onTrialPage ? 1 : 0)
                    .accessibilityHidden(!onTrialPage || subscriptions.isPro)
            }
            Button {
                primaryAction()
            } label: {
                Group {
                    if purchasing || restoring {
                        ProgressView().tint(Theme.onFill)
                    } else {
                        Text(onTrialPage ? trialCTATitle : "Continue")
                    }
                }
                .primaryCTA()
            }
            .disabled(purchasing || restoring || (page == skillPage && skillLevel.isEmpty))
            .opacity(page == skillPage && skillLevel.isEmpty ? 0.5 : 1)
            // Legal footer slot, reserved on every page.
            if reservesTrialSlots {
                legalRow
                    .opacity(onTrialPage && !subscriptions.isPro ? 1 : 0)
                    .accessibilityHidden(!onTrialPage || subscriptions.isPro)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
        // Full width as in 1.3.2: the trial flow's layout is frozen, iPad too.
    }

    private var onTrialPageNow: Bool { page == lastPage }

    /// The free way in. "Get Started" (not "Skip"/"No trial") on purpose,
    /// matching the approved fleet apps.
    private var softExit: some View {
        Button {
            startTour()
        } label: {
            Text("Get Started")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        // 30pt, as shipped in 1.3.2: the trial page's geometry is the proven
        // one. Only the accessibility-size layout, where it scrolls, grows it.
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 44 : 30)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 30)
        .disabled(!onTrialPageNow || subscriptions.isPro || purchasing || restoring)
    }

    private var priceSlot: some View {
        VStack(spacing: 2) {
            Text(trialPrice)
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Text(trialDisclosure)
                .font(.caption2)
                .foregroundStyle(Theme.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 48)
    }

    private var legalRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 14))
        return layout {
            Link("Terms", destination: PaywallLinks.terms)
            Link("Privacy", destination: PaywallLinks.privacy)
            Button("Restore") {
                restorePurchases()
            }
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkTertiary)
        .frame(minHeight: 20)
        .disabled(!onTrialPageNow || subscriptions.isPro || purchasing || restoring)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0...lastPage, id: \.self) { dot in
                Capsule()
                    .fill(dot == page ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == page ? 20 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: page)
            }
        }
        .padding(.bottom, 2)
    }

    /// The trial CTA is the Apple purchase trigger, nothing else. One tap goes
    /// straight to StoreKit's confirm sheet.
    ///
    /// It must NOT open a second paywall. Backing out of Apple's sheet leaves
    /// the player exactly where they were (they can still tap Get Started, or
    /// the CTA again); the full plan-picker fallback is reserved for the one
    /// case it was designed for, products that genuinely failed to load, so
    /// the button is never dead.
    private func primaryAction() {
        if page < lastPage {
            page += 1
            return
        }
        // Already a member (a reinstall, or another device on the same Apple
        // Account): there is nothing to sell, so the CTA is just Continue.
        guard !subscriptions.isPro else {
            startTour()
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            // Also re-runs the reinstall check: a member StoreKit knows about
            // must never be sold what they already own.
            await subscriptions.ensureOfferings()
            guard !subscriptions.isPro else {
                startTour()
                return
            }
            // Monthly by default, and this is deliberate. Two different people
            // reach the two purchase surfaces: whoever taps through onboarding
            // has not used the app yet and is reacting to the number on Apple's
            // sheet, while whoever hits the paywall later has already decided the
            // app is worth something. The paywall still leads with yearly. Here
            // the smaller recurring figure is what gets the trial started, and
            // `trialDisclosure` above always names the plan bought here.
            guard let package = subscriptions.package(for: onboardingPlan) else {
                showPaywallFallback = true
                return
            }
            do {
                let outcome = try await subscriptions.purchase(package)
                switch outcome {
                case .purchased:
                    if await subscriptions.confirmEntitlement() {
                        startTour()
                    } else {
                        purchaseError = "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore."
                    }
                case .cancelled:
                    break // They said no to Apple, not to the app. Stay put.
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    private func restorePurchases() {
        guard !restoring, !purchasing else { return }
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if subscriptions.isPro {
                    startTour()
                } else {
                    purchaseError = "No previous purchase found on this Apple Account."
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    /// Both exits from the trial page land here. Brand-new players take the
    /// primer first so the tour's closing Quick Session isn't the first time
    /// they see a card; everyone else goes straight to the tour.
    private func startTour() {
        stage = skillLevel == "new" ? .howToPlay : .tour
    }

    /// A successful purchase in the products-failed fallback must rejoin the
    /// onboarding path instead of dropping the player back on the trial page.
    private func paywallDismissed() {
        guard subscriptions.isPro else { return }
        startTour()
    }

    private func finish() {
        // RootView branches on this key, so setting it swaps Home in.
        // A brand-new player has never run an older version, so there is
        // nothing "new" to tell them. Stamping the baseline here is what keeps
        // the update sheet off a fresh install.
        WhatsNew.markCurrentAsBaseline()
        // The tour's closing practice does not count toward Home's extras.
        progress.sessionsAtOnboarding = progress.totalSessions
        progress.hasOnboarded = true
    }
}

/// Draws its second view, the page exactly as 1.3.2 laid it out, but tells
/// `ViewThatFits` that it needs only the first view's height (the content on
/// its own) plus `margin`. The 1.3.2 page asks for room for its spacers and
/// the gaps around them too, and on a 13 mini it only fit by squeezing those
/// out, so a plain `ViewThatFits` swapped in the compact page there. With
/// `margin` at one gap plus a spacer's minimum, the content can still never
/// be pushed off the top.
private struct ContentFit: Layout {
    let margin: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        if let height = proposal.height, height.isFinite {
            return CGSize(width: proposal.width ?? subviews[1].sizeThatFits(proposal).width, height: height)
        }
        let content = subviews[0].sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? content.width, height: content.height + margin)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        // The measuring copy is laid out but never drawn or reachable.
        // Centred, as ViewThatFits places its pick: content narrower than
        // the page (an iPad) would otherwise hug the leading edge.
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        subviews[0].place(at: centre, anchor: .center, proposal: ProposedViewSize(width: bounds.width, height: nil))
        subviews[1].place(at: centre, anchor: .center, proposal: ProposedViewSize(bounds.size))
    }
}
