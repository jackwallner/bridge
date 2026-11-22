import SwiftUI

/// A one-shot confetti burst. Bump `trigger` to fire. Drawn with Canvas, and
/// the animation timeline is removed when the burst ends, so a finished burst
/// costs nothing. With Reduce Motion on it never fires: the haptic, sound and
/// the graded row already say "right".
///
/// It launches from `sourceRect` when the host knows what was celebrated (the
/// correct answer row, say), otherwise from `origin`. Firing from the winning
/// element is the whole point: a burst that always erupts from the middle of
/// the screen doesn't celebrate anything in particular.
///
/// The motion is deliberately not "point source under gravity" (which reads as
/// a firework, not a celebration). Pieces launch along a wide upward fan from
/// across the source's WIDTH, decelerate through linear air drag toward a slow
/// terminal fall, sway as they tumble, and flip end over end (the width squash
/// fakes the third dimension). Ribbons mixed in with the chips keep the shapes
/// from reading as uniform.
struct ConfettiBurst: View {
    var trigger: Int
    var origin: UnitPoint = .center
    var particleCount: Int = 26
    /// The celebrated element, in the same coordinate space this view fills.
    var sourceRect: CGRect?
    /// What the burst celebrates (the question on screen). A change cancels a
    /// burst still waiting to launch: the answer row always reports its
    /// frame, so a Next inside the wait would fire from the next question's
    /// right answer and give it away.
    var scope: AnyHashable? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var firedAt: Date?
    @State private var seed: Int = 0
    /// Snapshotted at fire time: the source can move (or vanish) mid-flight,
    /// and the burst should keep the geometry it launched with.
    @State private var launchRect: CGRect?
    /// The source as it is now, not as the struct captured it at the tap:
    /// after the settle delay the row has moved with the grade.
    @State private var currentSource: CGRect?
    @State private var latestShot = 0

    private static let colors: [Color] = [
        Theme.jade, Theme.coral, Theme.gold, Theme.plum, Theme.bamGreen, Theme.tileIvory,
    ]
    private static let duration: Double = 2.0
    /// The answer row's grade spring and the scroll to the note (0.35s).
    private static let settleDelay: UInt64 = 350_000_000
    /// Air drag. Higher = the initial burst dies back faster into the drift.
    private static let drag: Double = 1.9
    /// Sets the terminal fall, gravity / drag: about 340 pt/s.
    private static let gravity: Double = 650

    var body: some View {
        Group {
            if let firedAt {
                TimelineView(.animation) { context in
                    Canvas { canvas, size in
                        let t = context.date.timeIntervalSince(firedAt)
                        guard t < Self.duration else { return }
                        draw(in: &canvas, size: size, time: t)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: sourceRect, initial: true) { _, rect in currentSource = rect }
        .onChange(of: scope) { _, _ in latestShot = 0 }
        .onChange(of: trigger) { _, _ in
            guard trigger > 0, !reduceMotion else { return }
            let shot = trigger
            latestShot = shot
            let fromRow = sourceRect != nil
            Task { @MainActor in
                // A burst from an answer row waits for the row to settle, so
                // the grade reads first and the burst leaves its final frame.
                if fromRow {
                    try? await Task.sleep(nanoseconds: Self.settleDelay)
                    guard latestShot == shot else { return }
                }
                let fired = Date()
                seed = shot
                launchRect = fromRow ? currentSource : nil
                firedAt = fired
                try? await Task.sleep(nanoseconds: UInt64(Self.duration * 1_000_000_000))
                // A newer burst owns the timeline now; leave it running.
                if firedAt == fired { firedAt = nil }
            }
        }
    }

    /// Where a piece is born: spread along the source's top edge, so a wide row
    /// erupts along its whole width like a party popper rather than spitting
    /// everything out of one pixel.
    private func launchPoint(index: Int, count: Int, size: CGSize, random: inout SeededRandom) -> CGPoint {
        guard let rect = launchRect, rect.width > 1 else {
            return CGPoint(x: origin.x * size.width, y: origin.y * size.height)
        }
        let spread = (Double(index) + random.next(in: 0.15, 0.85)) / Double(count)
        return CGPoint(
            x: rect.minX + rect.width * spread,
            y: rect.midY - rect.height * 0.25
        )
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, time: Double) {
        var random = SeededRandom(seed: UInt64(bitPattern: Int64(seed &* 7919 &+ 13)))
        let k = Self.drag
        let g = Self.gravity
        // Closed-form linear-drag ballistics: an initial kick that decays into
        // a gentle terminal-velocity fall. Cheap, stable, and it looks right.
        let decay = (1 - exp(-k * time)) / k

        for index in 0..<particleCount {
            let start = launchPoint(index: index, count: particleCount, size: size, random: &random)
            // Wide upward fan, biased outward from the center of the source.
            let side: Double = index.isMultiple(of: 2) ? 1 : -1
            let angle = -Double.pi / 2 + side * random.next(in: 0.06, 1.15)
            let speed = random.next(in: 340, 760)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed

            // Every random value is drawn before any piece is culled, so a
            // piece leaving the canvas never shifts the draws of the pieces
            // after it (which made their paths jump mid-flight).
            let swayPhase = random.next(in: 0, 6.28)
            let swaySpeed = random.next(in: 3.5, 7.0)
            let swayWidth = random.next(in: 4, 14)
            let spinSpeed = random.next(in: 4, 11) * (index.isMultiple(of: 3) ? -1 : 1)
            let tiltBase = random.next(in: -0.5, 0.5)
            let isRibbon = index % 5 == 0
            let w = isRibbon ? random.next(in: 3, 5) : random.next(in: 6, 11)
            let h = isRibbon ? random.next(in: 14, 22) : random.next(in: 6, 11)

            // Canvas y grows downward, so gravity is +g: the kick decays and
            // the piece settles into a g/k terminal fall.
            var x = start.x + CGFloat(vx * decay)
            let y = start.y + CGFloat((vy - g / k) * decay + g * time / k)
            guard y < size.height + 30, y > -60 else { continue }

            // Flutter: the piece sways as it tumbles, and slows its sway as it
            // falls, which is what makes paper look like paper.
            x += CGFloat(sin(time * swaySpeed + swayPhase) * swayWidth)

            let life = time / Self.duration
            let fade = life < 0.72 ? 1.0 : max(0, 1 - (life - 0.72) / 0.28)

            // End-over-end tumble. |cos| squashes the width to fake the flip.
            let spin = spinSpeed * time + swayPhase
            let tilt = tiltBase + spin * 0.12
            let squash = max(0.15, abs(cos(spin)))

            var piece = canvas
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(tilt))
            piece.scaleBy(x: squash, y: 1)
            piece.opacity = fade
            let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            piece.fill(
                Path(roundedRect: rect, cornerRadius: isRibbon ? 1 : 1.8),
                with: .color(Self.colors[index % Self.colors.count])
            )
        }
    }
}

/// Tiny deterministic generator so a burst renders identically every frame.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B9 : seed }

    private mutating func nextRaw() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func next(in low: Double, _ high: Double) -> Double {
        low + (high - low) * (Double(nextRaw() % 10_000) / 10_000)
    }
}
