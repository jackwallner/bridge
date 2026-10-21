import XCTest
@testable import Bridge

/// The unfolded iPhone Duo puts Home and Your Progress either side of the fold.
/// What has to hold: phones and the folded Duo never split, the panes meet the
/// fold edges exactly when the system reports a usable fold, and nothing ever
/// gets a pane too narrow for the phone layout.
final class UnfoldedSplitTests: XCTestCase {
    func testCompactWidthNeverSplits() {
        XCTAssertNil(UnfoldedSplit.make(width: 951, isRegularWidth: false, fold: 474...477))
        XCTAssertNil(UnfoldedSplit.make(width: 466, isRegularWidth: false, fold: nil))
    }

    func testRegularWidthTooNarrowForTwoPanesStaysSingle() {
        // The unfolded Duo held in portrait: 669 pt cannot hold two 360 pt panes.
        XCTAssertNil(UnfoldedSplit.make(width: 669, isRegularWidth: true, fold: nil))
        XCTAssertNil(UnfoldedSplit.make(width: 719, isRegularWidth: true, fold: 350...369))
    }

    func testPanesMeetTheFoldEdges() {
        let split = UnfoldedSplit.make(width: 871, isRegularWidth: true, fold: 474...477)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 474, secondaryX: 477, secondaryWidth: 394))
    }

    func testZeroWidthFoldSharesOneEdge() {
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 475.5...475.5)
        XCTAssertEqual(split?.primaryWidth, 475.5)
        XCTAssertEqual(split?.secondaryX, 475.5)
        XCTAssertEqual(split?.secondaryWidth, 475.5)
    }

    func testNoFoldSplitsEvenly() {
        let split = UnfoldedSplit.make(width: 1033, isRegularWidth: true, fold: nil)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 516, secondaryX: 516, secondaryWidth: 517))
    }

    func testFoldThatLeavesANarrowPaneFallsBackToAnEvenSplit() {
        // A fold this far off-centre would squeeze Your Progress under 360 pt.
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 600...604)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 475, secondaryX: 475, secondaryWidth: 476))
    }

    func testEveryPaneIsAtLeastTheMinimum() {
        for width in stride(from: CGFloat(720), through: 1400, by: 37) {
            for fold in [nil, (width / 2 - 2)...(width / 2 + 2), CGFloat(100)...CGFloat(104)] {
                guard let split = UnfoldedSplit.make(width: width, isRegularWidth: true, fold: fold) else {
                    return XCTFail("\(width) should split")
                }
                XCTAssertGreaterThanOrEqual(split.primaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertGreaterThanOrEqual(split.secondaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertEqual(split.secondaryX + split.secondaryWidth, width, accuracy: 0.001)
            }
        }
    }
}
