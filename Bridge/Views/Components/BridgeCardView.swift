import SwiftUI

struct BridgeCardView: View {
    let card: BridgeCard
    var width: CGFloat = 44

    private var height: CGFloat { width * 1.38 }
    private var suitColor: Color {
        card.suit == .hearts || card.suit == .diamonds ? Theme.cardRed : Theme.cardBlack
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.13, style: .continuous)
                .fill(Theme.ivory)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            RoundedRectangle(cornerRadius: width * 0.13, style: .continuous)
                .strokeBorder(Theme.ivoryShadow, lineWidth: 1)
            VStack(spacing: -1) {
                Text(card.rank.rawValue)
                    .font(.system(size: width * 0.40, weight: .bold, design: .serif))
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.42, weight: .semibold))
            }
            .foregroundStyle(suitColor)
        }
        .frame(width: width, height: height)
        .accessibilityLabel(card.spokenName)
    }
}

struct BridgeHandView: View {
    let cards: [BridgeCard]
    var cardWidth: CGFloat = 44
    var highlightedIndices: Set<Int> = []
    var onTap: ((Int) -> Void)?

    private let columns = 7

    var body: some View {
        let rows = cards.enumerated().map { (index: $0.offset, card: $0.element) }
            .chunked(into: columns)
        VStack(spacing: 10) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.index) { item in
                        cardCell(item.index, item.card)
                    }
                }
            }
        }
    }

    private func cardCell(_ index: Int, _ card: BridgeCard) -> some View {
        let selected = highlightedIndices.contains(index)
        return BridgeCardView(card: card, width: cardWidth)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: cardWidth * 0.13)
                        .strokeBorder(Theme.gold, lineWidth: 3)
                }
            }
            .offset(y: selected ? -8 : 0)
            .onTapGesture { onTap?(index) }
            .animation(.spring(duration: 0.25), value: selected)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
