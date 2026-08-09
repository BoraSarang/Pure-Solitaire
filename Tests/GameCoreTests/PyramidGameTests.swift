import XCTest
@testable import GameCore

final class PyramidGameTests: XCTestCase {

    private func card(_ suit: Suit, _ rank: Rank) -> Card { Card(suit: suit, rank: rank) }

    /// 슬롯 21~27(7번째 줄)을 카드들로, 나머지는 빈 상태로 구성
    private func makeBottomRowGame(_ bottom: [Card]) -> PyramidGame {
        var g = PyramidGame(gameNumber: 1)
        var pyramid = Array<Card?>(repeating: nil, count: PyramidGame.pyramidCount)
        for (offset, c) in bottom.enumerated() {
            pyramid[21 + offset] = c
        }
        g.pyramid = pyramid
        g.stock = []
        g.waste = []
        return g
    }

    // MARK: - 딜

    func testDealLayout() {
        let g = PyramidGame(gameNumber: 617)
        XCTAssertEqual(g.pyramid.count, 28)
        XCTAssertTrue(g.pyramid.allSatisfy { $0 != nil })
        XCTAssertEqual(g.stock.count, 24)
        XCTAssertTrue(g.waste.isEmpty)
        XCTAssertFalse(g.isWon)
    }

    /// 총 52장, 각 카드 정확히 1장
    func testDealHasEveryCardOnce() {
        let g = PyramidGame(gameNumber: 42)
        let all = g.pyramid.compactMap { $0 } + g.stock
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52)
    }

    func testDeterministicDeal() {
        let a = PyramidGame(gameNumber: 617)
        let b = PyramidGame(gameNumber: 617)
        XCTAssertEqual(a.pyramid, b.pyramid)
        XCTAssertEqual(a.stock, b.stock)
    }

    // MARK: - 노출 판정

    func testExposure() {
        var g = PyramidGame(gameNumber: 1)
        var pyramid = Array<Card?>(repeating: nil, count: 28)
        // 7번째 줄(21~27)은 항상 노출
        pyramid[21] = card(.spades, .six)
        pyramid[22] = card(.hearts, .seven)
        // 6번째 줄(15~20)은 아래 자식(21,22 등)이 남아있으면 비노출
        pyramid[15] = card(.clubs, .five)
        g.pyramid = pyramid
        g.stock = []
        g.waste = []

        XCTAssertTrue(g.isExposed(21))
        XCTAssertTrue(g.isExposed(22))
        XCTAssertFalse(g.isExposed(15)) // 자식 21, 22 존재

        // 자식 제거 → 부모 노출
        pyramid[21] = nil
        pyramid[22] = nil
        g.pyramid = pyramid
        XCTAssertTrue(g.isExposed(15))
    }

    func testExposedCardsOnlyBottomRowInitially() {
        let g = PyramidGame(gameNumber: 617)
        XCTAssertEqual(g.exposedCards.count, 7)
        // 딜 직후 노출 카드는 전부 7번째 줄
        for card in g.exposedCards {
            let i = g.index(of: card)!
            XCTAssertTrue(i >= 21)
        }
    }

    // MARK: - 합 13 제거 규칙

    /// 노출 피라미드 2장 합 13 제거
    func testRemovePairSum13() {
        var g = makeBottomRowGame([card(.spades, .six), card(.hearts, .seven)])
        let a = card(.spades, .six)
        let b = card(.hearts, .seven)
        XCTAssertTrue(g.canMove(.pyramidRemovePair(first: a, second: b)))
        XCTAssertTrue(g.apply(.pyramidRemovePair(first: a, second: b)))
        XCTAssertTrue(g.pyramid[21] == nil)
        XCTAssertTrue(g.pyramid[22] == nil)
        XCTAssertEqual(g.moveCount, 1)
    }

    /// 합이 13이 아닌 짝은 거부
    func testRemovePairNotSum13() {
        var g = makeBottomRowGame([card(.spades, .five), card(.hearts, .nine)])
        XCTAssertFalse(g.canMove(.pyramidRemovePair(first: card(.spades, .five), second: card(.hearts, .nine))))
    }

    /// 같은 카드는 짝 불가
    func testRemovePairSameCardRejected() {
        let g = makeBottomRowGame([card(.spades, .six)])
        XCTAssertFalse(g.canMove(.pyramidRemovePair(first: card(.spades, .six), second: card(.spades, .six))))
    }

    /// 비노출 카드는 짝 제거 불가
    func testRemovePairUnexposedRejected() {
        var g = PyramidGame(gameNumber: 1)
        var pyramid = Array<Card?>(repeating: nil, count: 28)
        pyramid[15] = card(.clubs, .six)  // 부모 (자식 21 존재 → 비노출)
        pyramid[21] = card(.hearts, .seven) // 노출
        g.pyramid = pyramid
        g.stock = []
        g.waste = []
        XCTAssertFalse(g.canMove(.pyramidRemovePair(first: card(.clubs, .six), second: card(.hearts, .seven))))
    }

    /// K 단독(13) 제거
    func testRemoveKingSingle() {
        var g = makeBottomRowGame([card(.clubs, .king)])
        XCTAssertTrue(g.canMove(.pyramidRemoveSingle(card: card(.clubs, .king))))
        XCTAssertTrue(g.apply(.pyramidRemoveSingle(card: card(.clubs, .king))))
        XCTAssertTrue(g.pyramid[21] == nil)
    }

    /// K가 아닌 단독은 거부
    func testRemoveNonKingSingleRejected() {
        let g = makeBottomRowGame([card(.clubs, .queen)])
        XCTAssertFalse(g.canMove(.pyramidRemoveSingle(card: card(.clubs, .queen))))
    }

    /// 노출 피라미드 + 웨이스트 합 13 제거
    func testRemoveWastePair() {
        var g = makeBottomRowGame([card(.spades, .eight)])
        g.waste = [card(.diamonds, .five)]
        XCTAssertTrue(g.canMove(.pyramidRemoveWastePair(card: card(.spades, .eight))))
        XCTAssertTrue(g.apply(.pyramidRemoveWastePair(card: card(.spades, .eight))))
        XCTAssertTrue(g.pyramid[21] == nil)
        XCTAssertTrue(g.waste.isEmpty)
    }

    /// 웨이스트가 비어있으면 짝 제거 거부
    func testRemoveWastePairEmptyWasteRejected() {
        let g = makeBottomRowGame([card(.spades, .eight)])
        XCTAssertFalse(g.canMove(.pyramidRemoveWastePair(card: card(.spades, .eight))))
    }

    /// 웨이스트와 합 13이 아니면 거부
    func testRemoveWastePairNotSum13() {
        let g = makeBottomRowGame([card(.spades, .eight)])
        var waste = g
        waste.waste = [card(.diamonds, .four)] // 8+4=12
        XCTAssertFalse(waste.canMove(.pyramidRemoveWastePair(card: card(.spades, .eight))))
    }

    // MARK: - 스톡 드로

    func testDrawFromStock() {
        var g = PyramidGame(gameNumber: 617)
        let stockBefore = g.stock.count
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.waste.count, 1)
        XCTAssertEqual(g.stock.count, stockBefore - 1)
    }

    /// 스톡 소진 후 드로 불가 (재활용 없음)
    func testDrawFromStockNoRecycle() {
        var g = makeBottomRowGame([])
        g.stock = []
        XCTAssertFalse(g.canMove(.drawFromStock))
        XCTAssertFalse(g.apply(.drawFromStock))
    }

    // MARK: - 승리 / 종료

    func testWin() {
        var g = PyramidGame(gameNumber: 1)
        g.pyramid = Array<Card?>(repeating: nil, count: 28)
        g.stock = [card(.spades, .ace)]
        XCTAssertTrue(g.isWon)
    }

    func testNotWonWithRemainingCard() {
        let g = makeBottomRowGame([card(.spades, .six)])
        XCTAssertFalse(g.isWon)
    }

    /// 종료: 스톡 소진 + 짝/단독 없음 → 이동 불가
    func testStuck() {
        var g = makeBottomRowGame([card(.spades, .six), card(.hearts, .nine)])
        g.stock = []
        XCTAssertFalse(g.hasAnyMove) // 6+9=15, 단독 아님, 스톡 없음
        XCTAssertNil(g.hint())
    }

    /// 이동 가능: 짝 존재
    func testHasMoveWithPair() {
        let g = makeBottomRowGame([card(.spades, .six), card(.hearts, .seven)])
        XCTAssertTrue(g.hasAnyMove)
        XCTAssertNotNil(g.hint())
    }

    // MARK: - undo / redo

    func testUndoRedo() {
        var g = makeBottomRowGame([card(.spades, .six), card(.hearts, .seven)])
        let a = card(.spades, .six)
        let b = card(.hearts, .seven)
        XCTAssertTrue(g.apply(.pyramidRemovePair(first: a, second: b)))
        XCTAssertEqual(g.moveCount, 1)

        g.undo()
        XCTAssertFalse(g.pyramid[21] == nil)
        XCTAssertFalse(g.pyramid[22] == nil)
        XCTAssertEqual(g.moveCount, 0)

        g.redo()
        XCTAssertTrue(g.pyramid[21] == nil)
        XCTAssertTrue(g.pyramid[22] == nil)
        XCTAssertEqual(g.moveCount, 1)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        var g = PyramidGame(gameNumber: 617)
        XCTAssertTrue(g.apply(.drawFromStock))
        let data = try JSONEncoder().encode(g)
        let decoded = try JSONDecoder().decode(PyramidGame.self, from: data)
        XCTAssertEqual(g, decoded)
    }
}
