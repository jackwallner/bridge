import SwiftUI

/// The Bridge+ card under a finished practice, for players who are not
/// members, ported from Mahj Trainer. A player who said "not yet" on the
/// onboarding trial page otherwise never heard about Bridge+ again. A quiet
/// card the player taps; the screen owns the sheet so its rating ask can wait
/// while the offer is up.
struct BridgePlusPitchCard: View {
    let headline: String?
    let detail: String
    let action: () -> Void

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        headline: String? = nil,
        detail: String = String(localized: "Play coached hands as often as you want, with fresh deals that never run out."),
        action: @escaping () -> Void
    ) {
        self.headline = headline
        self.detail = detail
        self.action = action
    }

    /// An account StoreKit says already had its free week is not offered one.
    static func defaultHeadline(trialEligible: Bool) -> String {
        trialEligible
            ? String(localized: "Try \(Membership.name) free for 7 days")
            : String(localized: "Get \(Membership.name)")
    }

    /// Members never see it, and neither does the onboarding tour, whose
    /// flow is frozen. Nor does anyone before the customer record is read:
    /// a member's `isPro` is false until then.
    static func isShown(isMember: Bool, membershipResolved: Bool, hasOnboarded: Bool) -> Bool {
        !isMember && membershipResolved && hasOnboarded
    }

    var body: some View {
        if Self.isShown(isMember: subscriptions.isPro, membershipResolved: subscriptions.membershipResolved,
                        hasOnboarded: progress.hasOnboarded) {
            Button(action: action) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) {
                            icon
                            text
                        }
                    } else {
                        HStack(spacing: 12) {
                            icon
                            text
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.inkTertiary)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                // Surface and border inside the label, so the press moves the
                // whole card.
                .themedCard(corner: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.gold.opacity(0.45), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityIdentifier("bridge-plus-pitch-card")
            .accessibilityHint(String(localized: "Shows \(Membership.name) plans"))
        }
    }

    private var icon: some View {
        Image(systemName: "sparkles")
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.gold)
            .frame(width: 38, height: 38)
            .background(Theme.gold.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline ?? Self.defaultHeadline(trialEligible: subscriptions.isEligibleForIntroOffer(TrialOfferSheet.plan)))
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
