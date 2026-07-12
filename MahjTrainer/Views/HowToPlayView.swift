import SwiftUI

/// The How to Play quick start: a short, held-until-tap primer on American
/// Mah Jongg for brand-new players. Runs inside onboarding (pass `onDone`)
/// and re-opens from Home and Settings (dismisses itself).
struct HowToPlayView: View {
    var onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var shineTrigger = 0
    @State private var confettiTrigger = 0

    private let pages = HowToPlayContent.pages
    private var page: HowToPlayPage { pages[index] }
    private var isLast: Bool { index == pages.count - 1 }

    var body: some View {
        VStack(spacing: 18) {
            progressDots
            Spacer(minLength: 0)
            pageCard
                .id(page.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            Spacer(minLength: 0)
            Button {
                advance()
            } label: {
                Text(isLast ? "Take your seat" : "Continue").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fireShine() }
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == index ? 20 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: index)
            }
        }
        .padding(.top, 6)
    }

    private var pageCard: some View {
        VStack(spacing: 16) {
            Image(systemName: page.icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 76, height: 76)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text(page.title)
                .font(Theme.display(27))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !page.tiles.isEmpty {
                TileRackView(tiles: page.tiles, tileWidth: 46)
            }
            Text(page.body)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let tip = page.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Theme.gold)
                    Text(tip)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .themedCard(corner: 22)
        .shine(trigger: shineTrigger, corner: 22)
    }

    private func advance() {
        if isLast {
            Haptics.success()
            if let onDone {
                onDone()
            } else {
                dismiss()
            }
            return
        }
        Haptics.impact(.soft, intensity: 0.6)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            index += 1
        }
        if index == pages.count - 1 {
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
