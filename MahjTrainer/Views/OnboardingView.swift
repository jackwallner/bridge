import SwiftUI

/// Onboarding: three value pages, a skill-level question, then the OT710-style
/// trial step. The primary button keeps IDENTICAL geometry on every page (the
/// zero-shift rule): the thumb rides Continue the whole way, and on the last
/// page the same button becomes "Start 7-day free trial", one tap straight
/// to Apple's confirm. No plan cards here; the full paywall is only a fallback
/// when products failed to load.
///
/// After the trial decision (either way), brand-new players get the How to
/// Play quick start FIRST, then everyone gets the feature tour, whose finale
/// runs a real Quick Session. The primer has to come before that session:
/// answering questions about tiles you haven't met yet is not an onboarding.
/// Only once the tour is done does `hasOnboarded` flip and Home appear.
struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var page = 0
    @State private var purchasing = false
    @State private var showPaywallFallback = false
    @State private var purchaseError: String?
    @AppStorage("mahj.skillLevel") private var skillLevel = ""

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
                    icon: "square.grid.3x3.fill",
                    title: "Make it stick between games",
                    body: "Mah Jongg fades fast between games. Mahj Trainer gives you five-minute drills you can run anywhere, whether you are still meeting the tiles or sharpening instincts you already have.",
                    tiles: [.c(2), .dragon(.soap), .c(2), .b(6)]
                ).tag(0)
                infoPage(
                    icon: "rectangle.stack.fill",
                    title: "Practice, not pressure",
                    body: "Swipe through flashcards, read racks, make keep-or-throw calls, and pick your Charleston pass, with the why behind every answer.",
                    tiles: [.b(4), .b(5), .b(6), .joker]
                ).tag(1)
                infoPage(
                    icon: "figure.walk",
                    title: "Walk in confident",
                    body: "Know which dragon matches which suit, spot your section fast, and stop dreading the Charleston. Practice at your own pace: no timers, no opponents.",
                    tiles: [.dragon(.red), .dragon(.green), .flower]
                ).tag(2)
                skillLevelPage.tag(3)
                trialPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
            footer
        }
        .background(Theme.background)
        .sheet(isPresented: $showPaywallFallback, onDismiss: paywallDismissed) {
            PaywallView()
        }
        .alert("Purchase Issue", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "")
        }
    }

    private func infoPage(icon: String, title: String, body bodyText: String, tiles: [Tile]) -> some View {
        VStack(spacing: 26) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 92, height: 92)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text(title)
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            TileRackView(tiles: tiles, tileWidth: 54)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Skill level

    private struct SkillOption {
        let id: String
        let title: String
        let detail: String
    }

    private let skillOptions: [SkillOption] = [
        SkillOption(id: "new", title: "Brand new", detail: "Still learning what the tiles even are"),
        SkillOption(id: "basics", title: "Know the basics", detail: "Met the tiles, still slow on the card"),
        SkillOption(id: "played", title: "Played real games", detail: "Comfortable, want sharper instincts"),
    ]

    private var skillLevelPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("Where are you starting from?")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("We'll point you at the right drills.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
            VStack(spacing: 12) {
                ForEach(skillOptions, id: \.id) { option in
                    skillCard(option)
                }
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
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
    }

    // MARK: - Trial step (OT710: hero + bullets, zero plan cards)

    private var trialPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 92, height: 92)
                .background(Theme.gold.opacity(0.14), in: Circle())
            Text("Try \(Membership.name) free")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                trialBenefit("Every beginner room is free, forever")
                trialBenefit("\(Membership.name) adds extra practice sets in all four rooms")
                trialBenefit("Plus the Master Tables: advanced Charleston and defense")
                trialBenefit("New drills added all year")
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func trialBenefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
    }

    /// The 3.1.2 disclosure has to sit next to the button that charges money,
    /// even though this page has no plan picker: price, period, auto-renewal,
    /// how to cancel.
    private var yearlyDisclosure: String {
        let price = PaywallPricing.price(subscriptions, .yearly)
        return "7 days free, then \(price). Renews automatically unless canceled at least 24 hours before the trial ends. Cancel any time in App Store settings."
    }

    // MARK: - Footer (identical geometry on every page: zero-shift CTA)

    private var footer: some View {
        let onTrialPage = page == lastPage
        return VStack(spacing: 8) {
            pageDots
            // Soft free exit sits ABOVE the primary so the trial CTA owns the
            // Continue slot. Height reserved on every page.
            Button {
                startTour()
            } label: {
                Text("Get Started")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(height: 30)
            .opacity(onTrialPage ? 1 : 0)
            .disabled(!onTrialPage)
            // Disclosure slot, also reserved.
            Text(yearlyDisclosure)
                .font(.caption2)
                .foregroundStyle(Theme.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 42)
                .opacity(onTrialPage ? 1 : 0)
            Button {
                primaryAction()
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(onTrialPage ? "Start 7-day free trial" : "Continue")
                    }
                }
                .primaryCTA()
            }
            .disabled(purchasing || (page == skillPage && skillLevel.isEmpty))
            .opacity(page == skillPage && skillLevel.isEmpty ? 0.5 : 1)
            // Legal footer slot, reserved on every page.
            HStack(spacing: 14) {
                Link("Terms of Use", destination: PaywallLinks.terms)
                Link("Privacy Policy", destination: PaywallLinks.privacy)
                Button("Restore") {
                    Task { try? await subscriptions.restore() }
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .frame(height: 20)
            .opacity(onTrialPage ? 1 : 0)
            .disabled(!onTrialPage)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
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
        purchasing = true
        Task {
            defer { purchasing = false }
            await subscriptions.ensureOfferings()
            guard let yearly = subscriptions.package(for: .yearly) else {
                showPaywallFallback = true
                return
            }
            do {
                let outcome = try await subscriptions.purchase(yearly)
                switch outcome {
                case .purchased:
                    startTour()
                case .cancelled:
                    break // They said no to Apple, not to the app. Stay put.
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    /// Both exits from the trial page land here. Brand-new players take the
    /// primer first so the tour's closing Quick Session isn't the first time
    /// they see a tile; everyone else goes straight to the tour.
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
        progress.hasOnboarded = true
    }
}
