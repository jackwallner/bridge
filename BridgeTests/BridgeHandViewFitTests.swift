import SwiftUI
import UIKit
import XCTest
@testable import Bridge

/// A hand is never wider than the room it is offered. Seven 44pt cards are
/// 344pt; with Display Zoom a 6.1" iPhone is 320pt wide and a question offers
/// its hand 268 to 288pt, so a fixed row lost cards off both screen edges.
@MainActor
final class BridgeHandViewFitTests: XCTestCase {
    private let deal: [BridgeCard] = [
        .s(.ace), .s(.king), .s(.ten), .s(.four), .h(.queen), .h(.jack), .h(.nine),
        .d(.eight), .d(.five), .d(.two), .c(.king), .c(.seven), .c(.three),
    ]

    private func size(_ cards: [BridgeCard], cardWidth: CGFloat, in width: CGFloat) -> CGSize {
        let host = UIHostingController(rootView: BridgeHandView(cards: cards, cardWidth: cardWidth))
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    func testAHandFitsTheWidthItIsOffered() {
        // A zoomed question (268), zoomed full width (288), an SE question (323).
        for width in [250, 268, 288, 323] as [CGFloat] {
            for (cards, cardWidth) in [(deal, 44), (Array(deal.prefix(7)), 52), (deal, 46)] as [([BridgeCard], CGFloat)] {
                let fitted = size(cards, cardWidth: cardWidth, in: width)
                XCTAssertLessThanOrEqual(fitted.width, width + 0.5, "\(cards.count) cards at \(cardWidth)pt in \(width)pt")
            }
        }
    }

    func testAHandThatFitsKeepsItsDesign() {
        // Seven 44pt cards and six 6pt gaps.
        XCTAssertEqual(size(deal, cardWidth: 44, in: 500).width, 7 * 44 + 6 * 6, accuracy: 0.5)
    }
}
