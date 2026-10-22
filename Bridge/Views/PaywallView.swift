import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    /// `trialTitle` is the subscription plans' button (`TrialCTA`).
    func ctaTitle(trialTitle: String = TrialCTA.sevenDay.title(.paywall), eligibleForTrial: Bool = false) -> String {
        if self == .lifetime { return "Unlock \(Membership.name) Forever" }
        return eligibleForTrial ? trialTitle : "Subscribe Now"
    }

    var packageType: PackageType {
        switch self {
        case .yearly: return .annual
        case .monthly: return .monthly
        case .lifetime: return .lifetime
        }
    }
}

enum PaywallLinks {
    /// Apple's standard EULA. If the app ever ships a custom EULA, this is the
    /// one place to swap it; App Review requires a functional Terms link here.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://jackwallner.github.io/bridge/privacy-policy")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

/// Shared paywall content used by the locked-drill sheet and Settings.
///
/// App Review 3.1.2 wants all of this ON the purchase screen, not buried:
/// the membership name, what each plan costs, the billing period, an explicit
/// auto-renew statement, Restore, and working Terms + Privacy links. Every one
/// of those lives in this file; don't trim them for layout.
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Get \(Membership.name)")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("Everything you have stays free. \(Membership.name) adds practice that never runs out.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            // Leads with the endless modes on purpose. Selling "more drills"
            // is what let a motivated player finish the membership in two
            // sittings; what they are actually buying now is practice that
            // does not end.
            VStack(alignment: .leading, spacing: 9) {
                benefit("Endless Practice: a fresh hand dealt every time")
                benefit("Fix My Mistakes: misses come back until they stick")
                benefit("Timed Challenge: 90 seconds, chase your best")
                benefit("Extra practice sets in every room, plus the Master Tables")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            planCards
        }
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planCards: some View {
        // Yearly, then monthly, then lifetime. Monthly sits DIRECTLY under yearly
        // on purpose: the yearly card's whole pitch is a discount off the monthly
        // price, and a discount only reads as one when the thing it's discounting
        // is the next line down. Lifetime is a different decision (own it vs rent
        // it) and belongs after that comparison, not inside it.
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: PaywallPricing.priceText(subscriptions, .yearly),
                     perMonth: PaywallPricing.perMonthEquivalent(subscriptions),
                     anchor: PaywallPricing.monthlyAnchor(subscriptions),
                     detail: PaywallPricing.planDetail(subscriptions, .yearly),
                     badge: PaywallPricing.savingsBadge(subscriptions))
            planCard(.monthly, title: "Monthly", price: PaywallPricing.priceText(subscriptions, .monthly),
                     perMonth: nil, anchor: nil,
                     detail: PaywallPricing.planDetail(subscriptions, .monthly), badge: nil)
            planCard(.lifetime, title: "Lifetime", price: PaywallPricing.priceText(subscriptions, .lifetime),
                     perMonth: nil, anchor: nil,
                     detail: "One payment. No subscription, nothing renews.", badge: "NO SUBSCRIPTION")
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, perMonth: String?,
                          anchor: String?, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.18), in: Capsule())
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    if let perMonth {
                        // The struck-through monthly price beside the yearly
                        // per-month figure is the discount, stated. Without it
                        // the two cards are just two numbers and the bigger one
                        // looks like the worse deal.
                        HStack(spacing: 5) {
                            if let anchor {
                                Text(anchor)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.inkTertiary)
                                    .strikethrough(true, color: Theme.inkTertiary)
                            }
                            Text(perMonth)
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                isSelected ? Theme.jade.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.jade : Theme.rule, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        // Selection was carried by a border colour and a fill alone, and the
        // two subscription cards share a CTA title, so nothing told a VoiceOver
        // user which plan the button at the bottom would actually buy.
        .accessibilityLabel([title, badge, price, perMonth.map { "\($0) billed yearly" }, detail]
            .compactMap { $0 }
            .joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Selected plan" : "Double tap to choose this plan")
    }
}

/// Price and terms strings, live from StoreKit.
///
/// Hardcoded fallback amounts used to live here, and they had already drifted a
/// full price tier out of date, so the screen could quietly quote $19.99/year on
/// a $9.99 product. A price the store did not give us is worse than no price at
/// all (3.1.2 wants the amount the customer will actually be charged), so an
/// unresolved product renders the loading placeholder and the disclosure drops
/// the amount rather than inventing one.
@MainActor
enum PaywallPricing {
    /// Shown in the amount's place until StoreKit answers.
    static let placeholder = "Loading price…"

    /// The localized billed amount, or nil while the product is still in flight.
    static func price(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String? {
        guard let base = subscriptions.paywallPrice(for: plan)?.localized else {
            return nil
        }
        switch plan {
        case .yearly: return "\(base)/year"
        case .monthly: return "\(base)/month"
        case .lifetime: return base
        }
    }

    /// The same, ready to render: the amount or the placeholder.
    static func priceText(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        price(subscriptions, plan) ?? placeholder
    }

    /// Yearly billed amount restated per month, e.g. "$3.33/mo". Yearly is the
    /// only plan this makes sense for; everything else returns nil.
    ///
    /// This is the line that keeps a yearly price legible next to the monthly
    /// one. Without it a 4x sticker gap reads as a penalty instead of a saving.
    static func perMonthEquivalent(_ subscriptions: SubscriptionService) -> String? {
        guard let product = subscriptions.paywallPrice(for: .yearly) else { return nil }
        let monthly = product.amount / 12
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.locale = product.locale
        guard let text = fmt.string(from: monthly as NSDecimalNumber) else { return nil }
        return "\(text)/mo"
    }

    /// The monthly plan's own price restated as a per-month anchor, e.g.
    /// "$9.99/mo". This is the number the yearly card is discounting; it is
    /// struck through beside the yearly per-month figure.
    static func monthlyAnchor(_ subscriptions: SubscriptionService) -> String? {
        guard let product = subscriptions.paywallPrice(for: .monthly) else { return nil }
        return "\(product.localized)/mo"
    }

    /// Whole-percent saving of the yearly plan against twelve months of the
    /// monthly plan. nil when either product is missing or the yearly plan is
    /// not actually cheaper, so the badge can never claim a saving that isn't
    /// there (PPP territories price the two plans independently).
    static func savingsPercent(_ subscriptions: SubscriptionService) -> Int? {
        guard let yearly = subscriptions.paywallPrice(for: .yearly),
              let monthly = subscriptions.paywallPrice(for: .monthly) else { return nil }
        let twelveMonths = monthly.amount * 12
        guard twelveMonths > 0, yearly.amount < twelveMonths else { return nil }
        var rounded = Decimal()
        var raw = (twelveMonths - yearly.amount) / twelveMonths * 100
        NSDecimalRound(&rounded, &raw, 0, .plain)
        let percent = NSDecimalNumber(decimal: rounded).intValue
        return percent > 0 ? percent : nil
    }

    /// The yearly card's badge: the quantified saving when we can compute it,
    /// otherwise the generic claim. "SAVE 67%" outsells "BEST VALUE" because it
    /// says what the value is.
    static func savingsBadge(_ subscriptions: SubscriptionService) -> String {
        guard let percent = savingsPercent(subscriptions) else { return "BEST VALUE" }
        return "SAVE \(percent)%"
    }

    /// One concise point-of-purchase line: price, trial, auto-renew, cancel.
    /// The full legalese lives in the EULA behind the Terms link.
    static func terms(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        terms(amount: price(subscriptions, plan), plan: plan, trialLabel: trialLabel(subscriptions, plan))
    }

    static func trialLabel(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String? {
        guard subscriptions.isEligibleForIntroOffer(plan),
              let period = subscriptions.package(for: plan)?.storeProduct.introductoryDiscount?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return "\(period.value) days free"
        case .week: return "\(period.value * 7) days free"
        case .month: return "\(period.value) months free"
        case .year: return "\(period.value) years free"
        @unknown default: return nil
        }
    }

    static func planDetail(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let billing = plan == .monthly ? "billed monthly" : "billed yearly"
        if let trial = trialLabel(subscriptions, plan) { return "\(trial), then \(billing). Auto-renews." }
        return "\(billing.capitalized). Auto-renews."
    }

    static func terms(amount: String?, plan: PaywallPlan, trialLabel: String? = nil) -> String {
        if plan == .lifetime {
            return amount.map { "\($0) one-time. Not a subscription, nothing renews." }
                ?? "One-time purchase. Not a subscription, nothing renews."
        }
        guard let amount else { return "Auto-renews until canceled." }
        if let trialLabel { return "\(trialLabel), then \(amount). Auto-renews until canceled." }
        return "\(amount). Auto-renews until canceled."
    }

}

/// Standalone paywall sheet (locked drills, locked rooms, Settings upgrade).
struct PaywallView: View {
    /// Which surface opened the sheet; reported to RevenueCat.
    var source: String = "bridge_paywall_sheet"
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var restoring = false
    @State private var loadingPrices = false
    /// Whether a price fetch has actually been tried yet. Without it the
    /// "prices aren't available" line renders on the very first frame, before
    /// `.task` has had a chance to ask, so a perfectly healthy cold open
    /// flashes a connection error at the customer.
    @State private var priceLoadAttempted = false
    @State private var message: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                if subscriptions.isCheckingEntitlements {
                    ProgressView("Checking membership…")
                        .padding()
                } else {
                    PaywallContent(selectedPlan: $selectedPlan)
                        .padding()
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                }
                // At accessibility sizes a pinned footer covered most of the
                // screen and clipped Restore, Terms and Privacy, so there it
                // scrolls with the plans instead.
                if dynamicTypeSize.isAccessibilitySize {
                    purchaseFooter
                        .padding()
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    purchaseFooter
                        .padding()
                        .background(.thinMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .alert("Bridge Trainer", isPresented: .init(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: subscriptions.isPro, initial: true) { _, isPro in
                if isPro { dismiss() }
            }
            .task {
                subscriptions.trackPaywallImpression(id: source)
                if !priceReady { await loadPrices() }
            }
        }
    }

    private var purchaseFooter: some View {
        VStack(spacing: 8) {
            if priceLoadAttempted && !priceReady && !loadingPrices {
                Text("Prices aren't available right now. Check your connection and try again.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                Button("Retry loading prices") {
                    Task { await loadPrices() }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.jade)
            }
            // Billed amount, shown prominently at the point of purchase
            // (App Review 3.1.2(c)): the reviewer flagged that it wasn't
            // clearly and conspicuously displayed.
            if priceReady {
                Text(PaywallPricing.priceText(subscriptions, selectedPlan))
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
            }
            Text(PaywallPricing.terms(subscriptions, selectedPlan))
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                purchase()
            } label: {
                Group {
                    if purchasing || loadingPrices || (!priceLoadAttempted && !priceReady) {
                        ProgressView().tint(Theme.onFill)
                    } else {
                        Text(selectedPlan.ctaTitle(trialTitle: subscriptions.trialCTA(.paywall, plan: selectedPlan), eligibleForTrial: subscriptions.isEligibleForIntroOffer(selectedPlan)))
                    }
                }
                .primaryCTA()
            }
            // Dead until there is a price. Enabled over an unresolved
            // product, this button ran a second offerings fetch and
            // then showed a generic "products unavailable" alert, which
            // reads as the app being broken rather than the store being
            // slow.
            .disabled(purchasing || restoring || !priceReady || !subscriptions.membershipResolved || subscriptions.isPro)
            .opacity(priceReady ? 1 : 0.75)
            .accessibilityHint(priceReady ? "" : "Waiting for the App Store to return prices")
            footerLinks
        }
    }

    /// Whether the selected plan has a real amount to charge. 3.1.2 wants the
    /// purchase screen to state what the customer pays, so a plan we cannot
    /// price is a plan we cannot sell.
    private var priceReady: Bool {
        PaywallPricing.price(subscriptions, selectedPlan) != nil
    }

    private func loadPrices() async {
        guard !loadingPrices else { return }
        loadingPrices = true
        defer {
            loadingPrices = false
            priceLoadAttempted = true
        }
        await subscriptions.loadOfferings()
    }

    private var footerLinks: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            Button("Restore") { restore() }
                .disabled(restoring || purchasing)
            Link("Terms of Use", destination: PaywallLinks.terms)
            Link("Privacy Policy", destination: PaywallLinks.privacy)
        }
        .font(.caption)
        .foregroundStyle(Theme.inkSecondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                await subscriptions.ensureOfferings()
                // A reinstalled member recovered just now: nothing to sell.
                guard !subscriptions.isPro else { return }
                let outcome = try await subscriptions.purchase(subscriptions.package(for: selectedPlan))
                guard outcome == .purchased else { return }
                Haptics.success()
                // The sheet dismisses itself the moment `isPro` flips. If the
                // entitlement hasn't landed after a few seconds, say so and
                // point at Restore, rather than leaving someone who just paid
                // looking at the paywall that charged them.
                if await !subscriptions.confirmEntitlement() {
                    message = "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore. You will not be charged twice."
                }
            } catch {
                // A cancel never lands here (it's an outcome, not a throw), so
                // anything that does is worth telling the player about.
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = "No previous purchase found on this Apple Account."
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
