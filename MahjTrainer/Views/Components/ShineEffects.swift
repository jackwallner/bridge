import SwiftUI

/// One-shot diagonal shine sweep, the slot-machine "you won" gleam. Bump
/// `trigger` to fire; a bright band sweeps across once and disappears.
struct ShineSweep: ViewModifier {
    var trigger: Int
    var corner: CGFloat = 14

    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let band = max(geo.size.width * 0.42, 60)
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.08), .white.opacity(0.62), .white.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: band, height: geo.size.height * 2.4)
                    .rotationEffect(.degrees(16))
                    .offset(
                        x: phase * (geo.size.width + band) - band / 2,
                        y: -geo.size.height * 0.7
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, _ in
                guard trigger > 0 else { return }
                phase = -1
                withAnimation(.easeInOut(duration: 0.85)) { phase = 1.4 }
            }
    }
}

/// Horizontal shake for wrong answers. Animate `travels` from 0 to N.
struct ShakeEffect: GeometryEffect {
    var travels: CGFloat

    var animatableData: CGFloat {
        get { travels }
        set { travels = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(travels * .pi * 2), y: 0))
    }
}

extension View {
    func shine(trigger: Int, corner: CGFloat = 14) -> some View {
        modifier(ShineSweep(trigger: trigger, corner: corner))
    }

    /// Celebration glow around a winning element.
    func winGlow(_ color: Color, active: Bool) -> some View {
        shadow(color: color.opacity(active ? 0.5 : 0), radius: active ? 12 : 0, y: 0)
    }
}
