import SwiftUI

/// Play a Hand: South bids and declares an authored deal to the last trick.
/// The table makes every other call and plays every routine card; the player
/// decides at the coached points and the coach answers each one.
struct HandPlayView: View {
    @ScaledMetric(relativeTo: .headline) private var callMinimum: CGFloat = 72
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var store = HandPlayStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine: HandPlayEngine?
    @State private var showPaywall = false
    @State private var reviewMoment = 0
    @State private var runner: Task<Void, Never>?
    @State private var finishedRecorded = false

    var body: some View {
        Group {
            if let engine {
                table(engine)
            } else if store.canPlay(isMember: subscriptions.isPro) {
                Color.clear.onAppear(perform: load)
            } else {
                lockedState
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(engine?.deal.title ?? String(localized: "Play a Hand"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView(source: "bridge_hand_play") }
        .requestsReview(after: reviewMoment)
        .onDisappear { runner?.cancel() }
    }

    // MARK: - Table

    /// One scroll view, so the coach's note at accessibility sizes never
    /// clips; a new note scrolls its Continue button into view.
    private func table(_ engine: HandPlayEngine) -> some View {
        ScrollViewReader { proxy in
            CenteringScrollView {
                VStack(spacing: 12) {
                    statusBar(engine)
                    if engine.phase == .auction {
                        auctionView(engine)
                    } else {
                        handView(engine.remaining(.north), seat: .north, engine: engine)
                            .opacity(engine.state.cardsPlayed > 0 ? 1 : 0)
                        trickView(engine)
                    }
                    if engine.phase != .finished {
                        handView(engine.remaining(.south), seat: .south, engine: engine)
                    }
                    bottom(engine)
                    actionButton(engine)
                        .id(bottomID)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: Theme.readableContentWidth)
            }
            .onChange(of: engine.state.pending) { _, note in
                guard note != nil || engine.phase == .finished else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }

    private let bottomID = "hand-play-bottom"

    @ViewBuilder
    private func actionButton(_ engine: HandPlayEngine) -> some View {
        Group {
            if engine.state.pending != nil {
                Button { continueAfterNote() } label: { Text("Continue").primaryCTA() }
            } else if engine.phase == .finished {
                if subscriptions.isPro {
                    Button { nextHand() } label: { Text("Next Hand").primaryCTA() }
                } else {
                    Button { dismiss() } label: { Text("Done").primaryCTA() }
                }
            }
        }
    }

    private func statusBar(_ engine: HandPlayEngine) -> some View {
        HStack {
            if engine.phase != .auction {
                Text(engine.deal.contractLabel)
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if engine.phase == .play {
                    Text("Tricks \(engine.declarerTricks)/\(engine.deal.tricksNeeded)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .frame(height: 28)
    }

    // MARK: - Auction

    private func auctionView(_ engine: HandPlayEngine) -> some View {
        let order: [Seat] = [.west, .north, .east, .south]
        let calls = engine.callsSoFar
        // Blank cells before the dealer so each column stays one seat.
        let lead = order.firstIndex(of: engine.deal.dealer) ?? 0
        let cells: [String?] = Array(repeating: nil, count: lead) + calls.map { Optional($0) }
        let rows = stride(from: 0, to: cells.count + 1, by: 4).map { Array(cells[$0..<min($0 + 4, cells.count)]) }
        return VStack(spacing: 8) {
            HStack {
                ForEach(order, id: \.self) { seat in
                    Text(seat.initial)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(seat == .south ? Theme.jade : Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(rows.indices, id: \.self) { row in
                HStack {
                    ForEach(0..<4, id: \.self) { column in
                        let index = row * 4 + column
                        let cell = column < rows[row].count ? rows[row][column] : nil
                        Group {
                            if let cell {
                                CallText(call: cell)
                            } else if index == cells.count, engine.pendingCoachedCall != nil {
                                Text(verbatim: "?").foregroundStyle(Theme.jade)
                            } else {
                                Text(verbatim: " ")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private func callButtons(_ call: CoachedCall) -> some View {
        let choices = HandPlayEngine.choices(for: call)
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: callMinimum), spacing: 8)], spacing: 8) {
            ForEach(choices, id: \.self) { choice in
                Button {
                    submitCall(choice)
                } label: {
                    CallText(call: choice)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .themedCard(corner: 12)
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityIdentifier("hand-call-\(choice)")
            }
        }
    }

    // MARK: - Hands and trick

    private func handView(_ cards: [BridgeCard], seat: Seat, engine: HandPlayEngine) -> some View {
        let active = engine.pendingDecision?.seat == seat
        let legal = active ? Set(engine.legalCards) : []
        return FannedHand(cards: cards, playable: legal, onTap: active ? { submitPlay($0) } : nil)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(active ? Theme.jade.opacity(0.12) : .clear)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(seat == .north ? String(localized: "Dummy") : String(localized: "Your hand"))
    }

    private func trickView(_ engine: HandPlayEngine) -> some View {
        let showingLast = engine.currentTrick.isEmpty && engine.lastTrick != nil
        let trick = showingLast ? engine.trickIndex - 1 : engine.trickIndex
        let cards = engine.currentTrick.isEmpty ? (engine.lastTrick ?? []) : engine.currentTrick
        let seats = trick < 13 ? engine.seats(ofTrick: trick) : []
        let winner = showingLast ? engine.winner(ofTrick: trick, in: engine.state.line) : nil
        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                let seat = seats[index]
                BridgeCardView(card: card, width: 46)
                    .overlay {
                        if seat == winner {
                            RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.gold, lineWidth: 2.5)
                        }
                    }
                    .offset(offset(for: seat))
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
            }
            ForEach([Seat.west, .east], id: \.self) { seat in
                Text(seat.initial)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Theme.inkTertiary)
                    .offset(x: seat == .west ? -118 : 118)
            }
        }
        .frame(height: 170)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func offset(for seat: Seat) -> CGSize {
        switch seat {
        case .north: return CGSize(width: 0, height: -52)
        case .south: return CGSize(width: 0, height: 52)
        case .west: return CGSize(width: -60, height: 0)
        case .east: return CGSize(width: 60, height: 0)
        }
    }

    // MARK: - Bottom

    @ViewBuilder
    private func bottom(_ engine: HandPlayEngine) -> some View {
        if let note = engine.state.pending {
            coachCard(note)
        } else if let call = engine.pendingCoachedCall {
            callButtons(call)
        } else if engine.phase == .finished {
            resultCard(engine)
        }
    }

    private func coachCard(_ note: CoachNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(heading(note), systemImage: note.verdict == .miss ? "lightbulb.fill" : "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(note.verdict == .miss ? Theme.goldText : Theme.gradeCorrect)
            if note.verdict == .miss, let whyNot = note.whyNot {
                MissNoteCard(note: MissNote(pickedLabel: note.pickedLabel, reason: whyNot))
            }
            Text(note.reason)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 16)
        .transition(.opacity)
    }

    private func heading(_ note: CoachNote) -> String {
        switch note.verdict {
        case .right: return note.isCall ? String(localized: "Right call") : String(localized: "Right play")
        case .alsoFine: return String(localized: "Also good. Coach's play: \(note.coachLabel)")
        case .miss: return note.isCall ? String(localized: "Coach's call: \(note.coachLabel)") : String(localized: "Coach's play: \(note.coachLabel)")
        }
    }

    private func resultCard(_ engine: HandPlayEngine) -> some View {
        let made = engine.declarerTricks >= engine.deal.tricksNeeded
        return VStack(spacing: 6) {
                Text(made ? String(localized: "Made \(engine.deal.contractLabel)") : String(localized: "Down in \(engine.deal.contractLabel)"))
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("\(engine.declarerTricks) tricks, \(engine.score) points")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Text("\(engine.state.right) of \(engine.state.decided) decisions right")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
            }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(18)
        .themedCard(corner: 16)
    }

    private var lockedState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.jade)
            Text("Today's free hand is played.")
                .font(Theme.display(22, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Spacer()
            Button { showPaywall = true } label: { Text("Play More with \(Membership.name)").primaryCTA() }
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
    }

    // MARK: - Flow

    private func load() {
        guard engine == nil else { return }
        engine = HandPlayEngine(state: store.currentState())
        run()
    }

    private func submitCall(_ call: String) {
        guard var current = engine, let note = current.submitCall(call) else { return }
        feedback(note)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { engine = current }
        store.save(current.state, isMember: subscriptions.isPro)
    }

    private func submitPlay(_ card: BridgeCard) {
        guard var current = engine, let note = current.submitPlay(card) else { return }
        feedback(note)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { engine = current }
        store.save(current.state, isMember: subscriptions.isPro)
    }

    private func feedback(_ note: CoachNote) {
        if note.verdict == .miss {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        } else {
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        }
    }

    private func continueAfterNote() {
        guard var current = engine else { return }
        current.dismissNote()
        withAnimation { engine = current }
        store.save(current.state, isMember: subscriptions.isPro)
        run()
    }

    /// Plays the table's calls and routine cards at table pace until the
    /// player has something to decide.
    private func run() {
        runner?.cancel()
        runner = Task { @MainActor in
            while !Task.isCancelled, var current = engine {
                if current.phase == .finished {
                    recordFinish(current)
                    return
                }
                guard current.state.pending == nil, current.pendingCoachedCall == nil,
                      current.pendingDecision == nil else { return }
                let pause: UInt64 = current.phase == .auction ? 550 : (current.state.cardsPlayed % 4 == 0 && current.state.cardsPlayed > 0 ? 1_100 : 450)
                try? await Task.sleep(nanoseconds: pause * 1_000_000)
                guard !Task.isCancelled else { return }
                if current.phase == .auction { current.advanceCall() } else { current.advancePlay() }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { engine = current }
                if current.state.callsMade > 0 { store.save(current.state, isMember: subscriptions.isPro) }
            }
        }
    }

    private func recordFinish(_ engine: HandPlayEngine) {
        guard !finishedRecorded else { return }
        finishedRecorded = true
        store.finish()
        SoundPlayer.play(.complete)
        if engine.state.right * 2 >= engine.state.decided { reviewMoment += 1 }
    }

    private func nextHand() {
        finishedRecorded = false
        engine = nil
        load()
    }
}

/// A call with its suit symbol in the card colors.
private struct CallText: View {
    let call: String

    var body: some View {
        let label = AuctionCallLabel.label(call)
        let red = label.contains("♥") || label.contains("♦")
        return label.reduce(Text(verbatim: "")) { text, character in
            let isSuit = "♠♥♦♣".contains(character)
            let piece = Text(verbatim: String(character))
                .foregroundStyle(isSuit ? (red ? Theme.cardRed : Theme.ink) : Theme.ink)
            return text + piece
        }
        .accessibilityLabel(label)
    }
}

/// A hand fanned in one row, overlapping to fit the width. Unplayable cards
/// dim only while the player is choosing.
private struct FannedHand: View {
    let cards: [BridgeCard]
    let playable: Set<BridgeCard>
    let onTap: ((BridgeCard) -> Void)?

    private let cardWidth: CGFloat = 44

    var body: some View {
        // Wrapped rows, never overlapped: overlapping cards shared one hit
        // area and read as two controls drawn over each other.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 4)], spacing: 6) {
            ForEach(cards, id: \.self) { card in
                let enabled = onTap != nil && playable.contains(card)
                BridgeCardView(card: card, width: cardWidth)
                    .overlay {
                        // A wash, not opacity.
                        if onTap != nil && !enabled {
                            RoundedRectangle(cornerRadius: cardWidth * 0.13, style: .continuous)
                                .fill(Theme.background.opacity(0.6))
                        }
                    }
                    .offset(y: enabled ? -6 : 0)
                    .onTapGesture { if enabled { onTap?(card) } }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(card.spokenName)
                    .accessibilityAddTraits(enabled ? .isButton : [])
                    .accessibilityIdentifier(enabled ? "hand-card-\(card.shortLabel)" : "")
            }
        }
        .padding(.top, 6)
    }
}
