import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    var ctaTitle: String {
        self == .lifetime ? "Unlock \(Membership.name) Forever" : "Start 7-Day Free Trial"
    }
}

enum PaywallLinks {
    /// Apple's standard EULA. If the app ever ships a custom EULA, this is the
    /// one place to swap it; App Review requires a functional Terms link here.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://jackwallner.github.io/mahj/privacy-policy")!
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
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 74, height: 74)
                    .background(Theme.gold.opacity(0.14), in: Circle())
                Text("Get \(Membership.name)")
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                Text("Every drill you have today stays free. \(Membership.name) adds more of them, everywhere.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 10) {
                benefit("Extra practice sets in all four beginner rooms")
                benefit("The Master Tables: Advanced Charleston and Defense School")
                benefit("Expert rack reading with deliberately tricky deals")
                benefit("New drills added all year")
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
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: PaywallPricing.price(subscriptions, .yearly),
                     detail: "7 days free, then billed yearly. Auto-renews.", badge: "BEST VALUE")
            planCard(.lifetime, title: "Lifetime", price: PaywallPricing.price(subscriptions, .lifetime),
                     detail: "One payment. No subscription, nothing renews.", badge: "NO SUBSCRIPTION")
            planCard(.monthly, title: "Monthly", price: PaywallPricing.price(subscriptions, .monthly),
                     detail: "7 days free, then billed monthly. Auto-renews.", badge: nil)
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, detail: String, badge: String?) -> some View {
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
                Text(price)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
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
    }
}

/// Price and terms strings, live from StoreKit when RevenueCat has loaded and
/// falling back to the configured prices so the screen is never blank.
@MainActor
enum PaywallPricing {
    static func price(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let base = subscriptions.package(for: plan)?.storeProduct.localizedPriceString
        switch plan {
        case .yearly: return "\(base ?? "$9.99")/year"
        case .monthly: return "\(base ?? "$1.99")/month"
        case .lifetime: return base ?? "$29.99"
        }
    }

    /// The legally load-bearing sentence: price, period, renewal, cancellation.
    static func terms(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let amount = price(subscriptions, plan)
        switch plan {
        case .lifetime:
            return "One-time purchase of \(amount). Not a subscription: nothing renews and there is nothing to cancel."
        case .yearly, .monthly:
            let period = plan == .yearly ? "year" : "month"
            return "7 days free, then \(amount). Your subscription renews automatically each \(period) unless you cancel at least 24 hours before the trial or period ends. Manage or cancel any time in your App Store account settings."
        }
    }
}

/// Standalone paywall sheet (locked drills, locked rooms, Settings upgrade).
struct PaywallView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContent(selectedPlan: $selectedPlan)
                    .padding()
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Text(PaywallPricing.terms(subscriptions, selectedPlan))
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        purchase()
                    } label: {
                        Group {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(selectedPlan.ctaTitle)
                            }
                        }
                        .primaryCTA()
                    }
                    .disabled(purchasing)
                    footerLinks
                }
                .padding()
                .background(.thinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .alert("Mahj Trainer", isPresented: .init(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: subscriptions.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore") { restore() }
                .disabled(restoring)
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
                let outcome = try await subscriptions.purchase(subscriptions.package(for: selectedPlan))
                if outcome == .purchased { Haptics.success() }
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
