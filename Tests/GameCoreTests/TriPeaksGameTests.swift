import XCTest
@testable import GameCore

final class TriPeaksGameTests: XCTestCase {

    private func card(_ suit: Suit, _ rank: Rank) -> Card { Card(suit: suit, rank: rank) }

    /// peak0의 마지막 줄(로컬 6~9)을 카드들로, 웨이스트 = 9♠, 나머지는 빈 상태로 구성
    private func makeBottomRowGame(_ bottom: [Card]) -> TriPeaksGame {
        var g = TriPeaksGame(gameNumber: 1)
        var peaks = Array<Card?>(repeating: nil, count: TriPeaksGame.totalPeaksCount)
        for (offset, c) in bottom.enumerated() {
            peaks[6 + offset] = c
        }
        g.peaks = peaks
        g.stock = []
        g.waste = [card(.spades, .nine)]
        return g
    }

    // MARK: - 딜

    func testDealLayout() {
        let g = TriPeaksGame(gameNumber: 617)
        XCTAssertEqual(g.peaks.count, 30)
        XCTAssertTrue(g.peaks.allSatisfy { $0 != nil })
        XCTAssertEqual(g.stock.count, 21)
        XCTAssertEqual(g.waste.count, 1)
        XCTAssertFalse(g.isWon)
    }

    /// 총 52장, 각 카드 정확히 1장
    func testDealHasEveryCardOnce() {
        let g = TriPeaksGame(gameNumber: 42)
        let all = g.peaks.compactMap { $0 } + g.stock + g.waste
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52)
    }

    func testDeterministicDeal() {
        let a = TriPeaksGame(gameNumber: 617)
        let b = TriPeaksGame(gameNumber: 617)
        XCTAssertEqual(a.peaks, b.peaks)
        XCTAssertEqual(a.stock, b.stock)
        XCTAssertEqual(a.waste, b.waste)
    }

    // MARK: - 노출 판정

    func testExposure() {
        var g = TriPeaksGame(gameNumber: 1)
        var peaks = Array<Card?>(repeating: nil, count: 30)
        // peak0 마지막 줄(로컬 6~9)은 항상 노출
        peaks[6] = card(.spades, .six)
        peaks[7] = card(.hearts, .seven)
        // peak0 로컬 3(row2 첫째)은 아래 자식 6,7이 남아있으면 비노출
        peaks[3] = card(.clubs, .five)
        g.peaks = peaks
        g.stock = []
        g.waste = [card(.spades, .nine)]

        XCTAssertTrue(g.isExposed(6))
        XCTAssertTrue(g.isExposed(7))
        XCTAssertFalse(g.isExposed(3)) // 자식 6,7 존재

        // 자식 제거 → 부모 노출
        peaks[6] = nil
        peaks[7] = nil
        g.peaks = peaks
        XCTAssertTrue(g.isExposed(3))
    }

    func testExposedCardsOnlyBottomRowsInitially() {
        let g = TriPeaksGame(gameNumber: 617)
        XCTAssertEqual(g.exposedCards.count, 3 * 4) // 피크당 4장
        for card in g.exposedCards {
            let i = g.index(of: card)!
            let (_, local) = TriPeaksGame.peakAndLocal(of: i)
            XCTAssertTrue(local >= 6) // 각 피크 마지막 줄
        }
    }

    // MARK: - 1 랭크 차이 제거 규칙

    /// 웨이스트와 정확히 1 랭크 차이만 제거 허용
    func testOneRankAdjacencyRule() {
        let g = makeBottomRowGame([card(.clubs, .ten), card(.clubs, .eight), card(.clubs, .nine), card(.clubs, .seven)])
        // 웨이스트 = 9♠
        XCTAssertTrue(g.canMove(.triPeaksRemove(card: card(.clubs, .ten))))   // +1 → 허용
        XCTAssertTrue(g.canMove(.triPeaksRemove(card: card(.clubs, .eight)))) // -1 → 허용
        XCTAssertFalse(g.canMove(.triPeaksRemove(card: card(.clubs, .nine))))  // 같은 랭크 → 거부
        XCTAssertFalse(g.canMove(.triPeaksRemove(card: card(.clubs, .seven)))) // 2 차이 → 거부
    }

    /// K↔A 순환은 인접 아님 (Golf와 다름)
    func testKingAceNotAdjacent() {
        var g = makeBottomRowGame([card(.clubs, .ace)])
        g.waste = [card(.spades, .king)]
        XCTAssertFalse(g.canMove(.triPeaksRemove(card: card(.clubs, .ace))))
    }

    /// 노출 카드만 제거 가능 (비노출 카드 거부)
    func testUnexposedRejected() {
        var g = TriPeaksGame(gameNumber: 1)
        var peaks = Array<Card?>(repeating: nil, count: 30)
        peaks[3] = card(.clubs, .ten)  // 부모 (자식 6,7 존재 → 비노출)
        peaks[6] = card(.hearts, .two)
        g.peaks = peaks
        g.stock = []
        g.waste = [card(.spades, .nine)]
        XCTAssertFalse(g.canMove(.triPeaksRemove(card: card(.clubs, .ten))))
    }

    /// 웨이스트가 비어있으면 제거 거부 (방어 로직)
    func testEmptyWasteRejected() {
        var g = makeBottomRowGame([card(.clubs, .ten)])
        g.waste = []
        XCTAssertFalse(g.canMove(.triPeaksRemove(card: card(.clubs, .ten))))
    }

    /// 제거 적용: 피크 카드 nil + 웨이스트에 추가
    func testApplyRemoval() {
        var g = makeBottomRowGame([card(.clubs, .ten)])
        XCTAssertTrue(g.apply(.triPeaksRemove(card: card(.clubs, .ten))))
        XCTAssertTrue(g.peaks[6] == nil)
        XCTAssertEqual(g.waste.last, card(.clubs, .ten))
        XCTAssertEqual(g.moveCount, 1)
    }

    // MARK: - 스톡 드로

    func testDrawFromStock() {
        var g = TriPeaksGame(gameNumber: 617)
        let stockBefore = g.stock.count
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.waste.count, 2)
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
        var g = TriPeaksGame(gameNumber: 1)
        g.peaks = Array<Card?>(repeating: nil, count: 30)
        g.stock = [card(.spades, .ace)]
        XCTAssertTrue(g.isWon)
    }

    func testNotWonWithRemainingCard() {
        let g = makeBottomRowGame([card(.clubs, .ten)])
        XCTAssertFalse(g.isWon)
    }

    /// 종료: 스톡 소진 + 웨이스트와 1 차이 노출 카드 없음 → 이동 불가
    func testStuck() {
        var g = makeBottomRowGame([card(.clubs, .seven), card(.hearts, .king)])
        g.stock = []
        XCTAssertFalse(g.hasAnyMove) // 9♠ 기준 7(K 차이 2), K(9 차이) — 1 차이 없음
        XCTAssertNil(g.hint())
    }

    /// 이동 가능: 1 차이 노출 카드 존재
    func testHasMoveWithAdjacent() {
        let g = makeBottomRowGame([card(.clubs, .ten)])
        XCTAssertTrue(g.hasAnyMove)
        XCTAssertNotNil(g.hint())
    }

    // MARK: - undo / redo

    func testUndoRedo() {
        var g = makeBottomRowGame([card(.clubs, .ten), card(.hearts, .eight)])
        XCTAssertTrue(g.apply(.triPeaksRemove(card: card(.clubs, .ten))))
        XCTAssertEqual(g.moveCount, 1)

        g.undo()
        XCTAssertFalse(g.peaks[6] == nil)
        XCTAssertEqual(g.waste.count, 1)
        XCTAssertEqual(g.moveCount, 0)

        g.redo()
        XCTAssertTrue(g.peaks[6] == nil)
        XCTAssertEqual(g.waste.count, 2)
        XCTAssertEqual(g.moveCount, 1)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        var g = TriPeaksGame(gameNumber: 617)
        XCTAssertTrue(g.apply(.drawFromStock))
        let data = try JSONEncoder().encode(g)
        let decoded = try JSONDecoder().decode(TriPeaksGame.self, from: data)
        XCTAssertEqual(g, decoded)
    }
}
