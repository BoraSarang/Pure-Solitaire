import XCTest
@testable import GameCore

final class GolfGameTests: XCTestCase {

    private func card(_ suit: Suit, _ rank: Rank) -> Card { Card(suit: suit, rank: rank) }

    // MARK: - 딜

    func testDealLayout() {
        let g = GolfGame(gameNumber: 617)
        XCTAssertEqual(g.columns.count, 7)
        for i in 0..<7 {
            XCTAssertEqual(g.columns[i].count, 5)
        }
        XCTAssertEqual(g.stock.count, 16)
        XCTAssertEqual(g.waste.count, 1)
        XCTAssertFalse(g.isWon)
    }

    /// 총 52장, 각 카드 정확히 1장
    func testDealHasEveryCardOnce() {
        let g = GolfGame(gameNumber: 42)
        let all = g.columns.flatMap { $0 } + g.stock + g.waste
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52)
    }

    func testDeterministicDeal() {
        let a = GolfGame(gameNumber: 617)
        let b = GolfGame(gameNumber: 617)
        XCTAssertEqual(a.columns, b.columns)
        XCTAssertEqual(a.stock, b.stock)
        XCTAssertEqual(a.waste, b.waste)
    }

    // MARK: - 이동 규칙

    /// 1 차이 / 같은 랭크만 제거 허용 (수트 무관, K↔A 순환)
    func testAdjacencyRule() {
        var g = GolfGame(gameNumber: 1)
        g.columns = Array(repeating: [], count: 7)
        g.waste = [card(.spades, .nine)]

        g.columns[0] = [card(.clubs, .ten)]   // +1 → 허용
        XCTAssertTrue(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .ten))))
        g.columns[0] = [card(.clubs, .eight)] // -1 → 허용
        XCTAssertTrue(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .eight))))
        g.columns[0] = [card(.clubs, .nine)]  // 같은 랭크 → 허용
        XCTAssertTrue(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .nine))))
        g.columns[0] = [card(.clubs, .seven)] // 2 차이 → 거부
        XCTAssertFalse(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .seven))))

        // K ↔ A 순환: 웨이스트 A 위에 K / 웨이스트 K 위에 A
        g.waste = [card(.spades, .ace)]
        g.columns[0] = [card(.clubs, .king)]
        XCTAssertTrue(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .king))))
        g.waste = [card(.spades, .king)]
        g.columns[0] = [card(.clubs, .ace)]
        XCTAssertTrue(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .ace))))
    }

    /// 열→웨이스트 적용: 열 마지막 카드 제거 + 웨이스트에 추가
    func testColumnToWasteApply() {
        var g = GolfGame(gameNumber: 1)
        g.columns = Array(repeating: [], count: 7)
        g.waste = [card(.spades, .nine)]
        g.columns[0] = [card(.clubs, .ten)]
        XCTAssertTrue(g.apply(.columnToWaste(columnIndex: 0, card: card(.clubs, .ten))))
        XCTAssertTrue(g.columns[0].isEmpty)
        XCTAssertEqual(g.waste, [card(.spades, .nine), card(.clubs, .ten)])
    }

    /// 웨이스트가 비면 열 제거 불가 (Golf는 웨이스트 1장 시작이라 실제론 비지 않지만 방어)
    func testEmptyWasteRejectsColumnMove() {
        var g = GolfGame(gameNumber: 1)
        g.columns = Array(repeating: [], count: 7)
        g.waste = []
        g.columns[0] = [card(.clubs, .ten)]
        XCTAssertFalse(g.canMove(.columnToWaste(columnIndex: 0, card: card(.clubs, .ten))))
    }

    // MARK: - 스톡 / 승리 / 종료

    /// 스톡 드로 → 웨이스트, 재활용 없음 (스톡 소진 시 드로 불가)
    func testStockDrawAndNoRecycle() {
        var g = GolfGame(gameNumber: 1)
        let stockBefore = g.stock.count
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.stock.count, stockBefore - 1)
        XCTAssertEqual(g.waste.count, 2)
        while !g.stock.isEmpty { _ = g.apply(.drawFromStock) }
        XCTAssertFalse(g.canMove(.drawFromStock))
    }

    func testWinDetection() {
        var g = GolfGame(gameNumber: 1)
        g.columns = Array(repeating: [], count: 7)
        XCTAssertTrue(g.isWon)
    }

    /// 종료 판정: 스톡 소진 + 제거 가능 카드 없음 → hasAnyMove false
    func testNoMovesWhenStuck() {
        var g = GolfGame(gameNumber: 1)
        g.stock = []
        g.columns = Array(repeating: [], count: 7)
        g.columns[0] = [card(.clubs, .ace)]
        g.waste = [card(.spades, .six)] // A(1)와 6은 1 차이도 같지도 않음 → 제거 불가
        XCTAssertFalse(g.hasAnyMove)
        // 웨이스트를 바꾸면 제거 가능
        g.waste = [card(.spades, .two)]
        XCTAssertTrue(g.hasAnyMove)
    }

    // MARK: - undo / Codable

    func testUndoRedo() {
        var g = GolfGame(gameNumber: 1)
        g.columns = Array(repeating: [], count: 7)
        g.waste = [card(.spades, .nine)]
        g.columns[0] = [card(.clubs, .ten)]
        let wasteBefore = g.waste
        let columnBefore = g.columns[0]
        _ = g.apply(.columnToWaste(columnIndex: 0, card: card(.clubs, .ten)))
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.columns[0], columnBefore)
        XCTAssertEqual(g.waste, wasteBefore)
        g.redo()
        XCTAssertTrue(g.columns[0].isEmpty)
    }

    func testCodableRoundTrip() {
        var g = GolfGame(gameNumber: 617)
        _ = g.apply(.drawFromStock)
        let data = try! JSONEncoder().encode(g)
        let restored = try! JSONDecoder().decode(GolfGame.self, from: data)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.stock, g.stock)
        XCTAssertEqual(restored.waste, g.waste)
        XCTAssertEqual(restored.moveCount, g.moveCount)
    }
}
