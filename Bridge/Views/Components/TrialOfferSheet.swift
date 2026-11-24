import SwiftUI

/// What the player just did, so the sheet's headline answers it.
enum TrialOfferContext {
    case drillResult
    case handSpent

    var headline: String {
        switch self {
        case .drillResult: return String(localized: "Keep the practice going")
        case .handSpent: return String(localized: "Play another hand now")
        }
    }

    /// RevenueCat impression id. Auto and tapped asks are reported apart so
    /// the two can be compared.
    func source(auto: Bool) -> String {
        let base: String
        switch self {
        case .drillResult: base = "bridge_offer_drill"
        case .handSpent: base = "bridge_offer_hand"
        }
        return auto ? "\(base)_auto" : base
    }
}

/// The one-tap trial ask after a practice, ported from Mahj Trainer: a short
/// sheet with one plan and one button that goes straight to Apple's confirm
/// sheet. The plan is the onboarding page's (monthly), so both one-tap asks
/// buy the same thing. It carries every 3.1.2 element the onboarding page
/// does: membership name, billed amount as the largest price text, the
/// auto-renew line, Terms, Privacy and Restore.
struct TrialOfferSheet: View {
    let context: TrialOfferContext
    let auto: Bool

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?
    @State private var showPlans = false
    @State private var height: CGFloat = 520
    /// False until StoreKit says this Apple Account still gets the free week:
    /// unknown eligibility never promises a trial.
    @State private var trialEligible = false
    /// The tap's preflight and purchase; cancelled if the sheet goes away.
    @State private var purchaseTask: Task<Void, Never>?

    /// The same plan as the onboarding trial page.
    static let plan: PaywallPlan = .monthly

    static let benefits = [
        String(localized: "Play coached hands, as many as you want"),
        String(localized: "Endless Practice: a fresh hand dealt every time"),
        String(localized: "Fix My Mistakes: misses come back until they stick"),
    ]

    private var plan: PaywallPlan { Self.plan }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { content }
                    .presentationDetents([.large])
            } else {
                // The sheet as designed while it fits; taller than the screen
                // (an SE at XXXL) the content scrolls so the legal row stays.
                ViewThatFits(in: .vertical) {
                    measuredContent
                    ScrollView { measuredContent }
                        .scrollBounceBehavior(.basedOnSize)
                }
                .presentationDetents([.height(height)])
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .interactiveDismissDisabled(purchasing)
        .alert("Bridge Trainer", isPresented: .init(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
        .sheet(isPresented: $showPlans) { PaywallView(source: context.source(auto: auto)) }
        .onChange(of: subscriptions.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .onChange(of: subscriptions.introEligibility) { _, _ in
            trialEligible = subscriptions.isEligibleForIntroOffer(plan)
        }
        .onDisappear { purchaseTask?.cancel() }
        .task {
            subscriptions.trackPaywallImpression(id: context.source(auto: auto))
            if PaywallPricing.price(subscriptions, plan) == nil {
                await subscriptions.loadOfferings()
            }
            trialEligible = await subscriptions.isTrialEligible(for: plan)
        }
    }

    private var measuredContent: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChangeCompat { height = $0 }
    }

    private var content: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 60, height: 60)
                .background(Theme.gold.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text(context.headline)
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(trialEligible
                     ? String(localized: "Try \(Membership.name) free for 7 days.")
                     : String(localized: "Everything in \(Membership.name), starting today."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            benefitList
            VStack(spacing: 2) {
                Text(PaywallPricing.priceText(subscriptions, plan))
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                    .accessibilityIdentifier("trial-offer-billed-price")
                Text(PaywallPricing.terms(subscriptions, plan, trial: trialEligible))
                    .font(.caption2)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 6) {
                Button(action: startTrial) {
                    Group {
                        if purchasing {
                            ProgressView().tint(Theme.onFill)
                        } else {
                            Text(trialEligible
                                 ? subscriptions.trialCTA(.onboarding, plan: plan)
                                 : String(localized: "Join \(Membership.name)"))
                        }
                    }
                    .primaryCTA()
                }
                .disabled(purchasing || restoring)
                Button("Not now") { dismiss() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .disabled(purchasing)
            }
            legalRow
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Self.benefits, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.jade)
                        .accessibilityHidden(true)
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 18))
        return layout {
            Link(destination: PaywallLinks.terms) { legalLabel("Terms") }
            Link(destination: PaywallLinks.privacy) { legalLabel("Privacy") }
            Button(action: restore) { legalLabel("Restore") }
                .disabled(purchasing || restoring)
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkTertiary)
    }

    private func legalLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }

    /// Straight to Apple's confirm sheet, as on the onboarding page. Backing
    /// out of Apple's sheet is the player saying no to Apple, not to the app:
    /// stay put. The plan picker is only for products that failed to load.
    private func startTrial() {
        guard !purchasing else { return }
        purchasing = true
        // What the sheet shows at this tap; the purchase runs on exactly that.
        let shown = trialEligible
        purchaseTask = Task {
            defer { purchasing = false }
            // Also re-runs the reinstall check: a member StoreKit knows about
            // must never be sold what they already own.
            await subscriptions.ensureOfferings()
            guard !Task.isCancelled else { return }
            guard !subscriptions.isPro else {
                dismiss()
                return
            }
            guard !subscriptions.isRecoveringMembership else {
                message = String(localized: "Still checking what this Apple Account owns. Try again in a moment, or tap Restore.")
                return
            }
            guard let package = subscriptions.package(for: plan) else {
                showPlans = true
                return
            }
            // The sheet may have drawn before StoreKit answered. If the free
            // week changed, show the real terms and let them tap again.
            let eligible = await subscriptions.isTrialEligible(for: plan)
            guard !Task.isCancelled else { return }
            guard eligible == shown else {
                trialEligible = eligible
                return
            }
            do {
                switch try await subscriptions.purchase(package) {
                case .cancelled:
                    break
                case .purchased:
                    Haptics.success()
                    if await subscriptions.confirmEntitlement() {
                        dismiss()
                    } else {
                        message = String(localized: "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore.")
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                // Ask to Buy lands here as `PurchaseError.awaitingApproval`.
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        guard !restoring, !purchasing else { return }
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = String(localized: "No previous purchase found on this Apple Account.")
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

extension View {
    /// The one-tap trial sheet for a result screen. Bump `autoMoment` at a
    /// good result; the sheet then rises on its own if `TrialOfferPacer`
    /// allows. Setting `isPresented` (a tapped Bridge+ card) always opens it.
    func trialOffer(_ context: TrialOfferContext, isPresented: Binding<Bool>, autoMoment: Int) -> some View {
        modifier(TrialOfferModifier(context: context, isPresented: isPresented, autoMoment: autoMoment))
    }

    /// Reports the view's height; `onGeometryChange` itself is iOS 18.
    fileprivate func onGeometryChangeCompat(_ action: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { action(proxy.size.height) }
                    .onChange(of: proxy.size.height) { _, new in action(new) }
            }
        )
    }
}

private struct TrialOfferModifier: ViewModifier {
    let context: TrialOfferContext
    @Binding var isPresented: Bool
    let autoMoment: Int

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @State private var onScreen = false
    @State private var auto = false

    func body(content: Content) -> some View {
        content
            .onAppear { onScreen = true }
            .onDisappear { onScreen = false }
            .onChange(of: autoMoment) { _, _ in schedule() }
            .onChange(of: isPresented) { _, shown in if !shown { auto = false } }
            .sheet(isPresented: $isPresented) { TrialOfferSheet(context: context, auto: auto) }
    }

    private func schedule() {
        guard eligible else { return }
        Task { @MainActor in
            // Let the result land before anything rises over it.
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard onScreen, !isPresented, eligible else { return }
            TrialOfferPacer.autoOffersPending += 1
            defer { TrialOfferPacer.autoOffersPending -= 1 }
            // Never rise on its own to promise a free week Apple won't give.
            guard await subscriptions.isTrialEligible(for: TrialOfferSheet.plan),
                  onScreen, !isPresented else { return }
            TrialOfferPacer.markAutoShown(installedAt: ConversionDiagnostics.installDate)
            auto = true
            isPresented = true
        }
    }

    private var eligible: Bool {
        TrialOfferEligibility.autoOfferAllowed(
            isMember: subscriptions.isPro,
            membershipResolved: subscriptions.membershipResolved,
            hasOnboarded: progress.hasOnboarded,
            switchOn: subscriptions.isOn(.trialOffer),
            due: TrialOfferPacer.autoOfferDue(
                practicesSinceOnboarding: progress.totalSessions - progress.sessionsAtOnboarding,
                installedAt: ConversionDiagnostics.installDate
            )
        )
    }
}

/// Who may get the automatic ask, apart from StoreKit's free-week answer.
enum TrialOfferEligibility {
    static func autoOfferAllowed(isMember: Bool, membershipResolved: Bool, hasOnboarded: Bool,
                                 switchOn: Bool, due: Bool) -> Bool {
        !isMember && membershipResolved && hasOnboarded && switchOn && due
    }
}
