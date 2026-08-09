import XCTest
@testable import GameCore

final class FortyThievesGameTests: XCTestCase {

    private func card(_ suit: Suit, _ rank: Rank) -> Card { Card(suit: suit, rank: rank) }

    // MARK: - 딜

    func testDealLayout() {
        let g = FortyThievesGame(gameNumber: 617)
        XCTAssertEqual(g.columns.count, 10)
        for i in 0..<10 {
            XCTAssertEqual(g.columns[i].count, 4)
        }
        XCTAssertEqual(g.stock.count, 64)
        XCTAssertTrue(g.waste.isEmpty)
        XCTAssertEqual(g.homes.count, 8)
        XCTAssertTrue(g.homes.allSatisfy { $0.isEmpty })
        XCTAssertFalse(g.isWon)
    }

    /// 2덱 104장 — 각 카드가 정확히 2장씩, 전체 104장
    func testDealHasExactlyTwoOfEachCard() {
        let g = FortyThievesGame(gameNumber: 42)
        let all = g.columns.flatMap { $0 } + g.stock
        XCTAssertEqual(all.count, 104)
        XCTAssertEqual(Set(all).count, 52)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = Card(suit: suit, rank: rank)
                XCTAssertEqual(all.filter { $0 == card }.count, 2)
            }
        }
    }

    // MARK: - 열 이동 규칙

    /// 같은 수트 내림차순만 열 이동 허용 (다른 수트/랭크차 초과 불가)
    func testSameSuitDescendingOnly() {
        var g = FortyThievesGame(gameNumber: 1)
        // 10♠ → J♠ 아래 (같은 수트, 한 단계 낮음)
        g.columns[0] = [card(.spades, .ten)]
        g.columns[1] = [card(.spades, .jack)]
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
        // 10♠ → J♥ 아래: 수트 다름 → 불가
        g.columns[1] = [card(.hearts, .jack)]
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
        // 10♠ → Q♠ 아래: 한 단계 차이 아님 → 불가
        g.columns[1] = [card(.spades, .queen)]
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
    }

    /// 빈 열엔 아무 카드나 놓을 수 있다
    func testEmptyColumnAnyCard() {
        var g = FortyThievesGame(gameNumber: 1)
        g.columns[3] = []
        XCTAssertTrue(g.canPlaceOnColumn(card(.spades, .king), column: 3))
        XCTAssertTrue(g.canPlaceOnColumn(card(.clubs, .ace), column: 3))
    }

    /// 같은 수트 내림차순 그룹 이동 적용
    func testColumnGroupMove() {
        var g = FortyThievesGame(gameNumber: 1)
        // 열0 = [K♠, Q♠, J♠, 10♠] (K=맨 위, 10=바닥), 열1 = [J♠]
        g.columns[0] = [card(.spades, .king), card(.spades, .queen), card(.spades, .jack), card(.spades, .ten)]
        g.columns[1] = [card(.spades, .jack)]
        // 바닥 10♠를 J♠ 아래로 1장 이동
        XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 1)))
        XCTAssertEqual(g.columns[0], [card(.spades, .king), card(.spades, .queen), card(.spades, .jack)])
        XCTAssertEqual(g.columns[1], [card(.spades, .jack), card(.spades, .ten)])
    }

    /// 시퀀스 검증: 같은 수트 내림차순만 movableRun에 포함 (반환 = 위→바닥 순서)
    func testMovableRun() {
        var g = FortyThievesGame(gameNumber: 1)
        g.columns[0] = [card(.spades, .king), card(.spades, .queen), card(.spades, .jack), card(.spades, .ten)]
        // 모든 카드가 같은 수트 내림차순 → 4장 전부
        XCTAssertEqual(g.movableRun(from: 0), [card(.spades, .king), card(.spades, .queen), card(.spades, .jack), card(.spades, .ten)])
        // 중간에 수트가 바뀌면 바닥부터 끊김 → [J♠, 10♠]만
        g.columns[0] = [card(.spades, .king), card(.hearts, .queen), card(.spades, .jack), card(.spades, .ten)]
        XCTAssertEqual(g.movableRun(from: 0), [card(.spades, .jack), card(.spades, .ten)])
    }

    // MARK: - 스톡 / 웨이스트

    /// 스톡 드로 → 웨이스트, 스톡은 일회성 (재활용 없음)
    func testStockDrawAndNoRecycle() {
        var g = FortyThievesGame(gameNumber: 1)
        let stockBefore = g.stock.count
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.stock.count, stockBefore - 1)
        XCTAssertEqual(g.waste.count, 1)
        // 스톡이 남아 있으면 재활용 불가
        XCTAssertFalse(g.canMove(.recycleStock))
        // 스톡을 모두 소진하면 드로 불가
        while !g.stock.isEmpty { _ = g.apply(.drawFromStock) }
        XCTAssertFalse(g.canMove(.drawFromStock))
    }

    /// 웨이스트 → 열 / 홈
    func testWasteToColumnAndHome() {
        var g = FortyThievesGame(gameNumber: 1)
        g.columns[0] = [card(.spades, .jack)]
        g.waste = [card(.spades, .ten)]
        XCTAssertTrue(g.canMove(.wasteToColumn(columnIndex: 0, card: card(.spades, .ten))))
        XCTAssertTrue(g.apply(.wasteToColumn(columnIndex: 0, card: card(.spades, .ten))))
        XCTAssertEqual(g.columns[0], [card(.spades, .jack), card(.spades, .ten)])
        XCTAssertTrue(g.waste.isEmpty)

        // 웨이스트 → 홈 (A → 빈 홈)
        g.waste = [card(.clubs, .ace)]
        XCTAssertTrue(g.canMove(.wasteToFoundation(card: card(.clubs, .ace))))
        XCTAssertTrue(g.apply(.wasteToFoundation(card: card(.clubs, .ace))))
        XCTAssertTrue(g.homes.contains { $0 == [card(.clubs, .ace)] })
        XCTAssertTrue(g.waste.isEmpty)

        // 웨이스트 → 홈 (같은 수트 다음 랭크)
        g.waste = [card(.clubs, .two)]
        XCTAssertTrue(g.canMove(.wasteToFoundation(card: card(.clubs, .two))))
        XCTAssertTrue(g.apply(.wasteToFoundation(card: card(.clubs, .two))))
        XCTAssertTrue(g.homes.contains { $0 == [card(.clubs, .ace), card(.clubs, .two)] })
    }

    /// 홈셀 8개 — 2덱 수트 2세트(A→K), 전부 완성 시 승리
    func testHomeEightPilesAndWin() {
        var g = FortyThievesGame(gameNumber: 1)
        for set in 0..<2 {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    let c = Card(suit: suit, rank: rank)
                    g.waste = [c]
                    XCTAssertTrue(g.canMove(.wasteToFoundation(card: c)), "\(c) 이동 불가 (set \(set))")
                    XCTAssertTrue(g.apply(.wasteToFoundation(card: c)))
                }
            }
        }
        XCTAssertEqual(g.homes.count, 8)
        XCTAssertTrue(g.homes.allSatisfy { $0.count == 13 })
        XCTAssertTrue(g.isWon)
    }

    // MARK: - 승리 / undo / Codable

    func testWinDetection() {
        var g = FortyThievesGame(gameNumber: 1)
        g.homes = [[Card]].init(repeating: Rank.allCases.map { Card(suit: .spades, rank: $0) }, count: 8)
        XCTAssertTrue(g.isWon)
    }

    func testUndoRedo() {
        var g = FortyThievesGame(gameNumber: 1)
        let stockBefore = g.stock
        _ = g.apply(.drawFromStock)
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.stock, stockBefore)
        XCTAssertTrue(g.waste.isEmpty)
        g.redo()
        XCTAssertEqual(g.waste.count, 1)
    }

    func testCodableRoundTrip() {
        var g = FortyThievesGame(gameNumber: 617)
        _ = g.apply(.drawFromStock)
        let data = try! JSONEncoder().encode(g)
        let restored = try! JSONDecoder().decode(FortyThievesGame.self, from: data)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.stock, g.stock)
        XCTAssertEqual(restored.waste, g.waste)
        XCTAssertEqual(restored.homes, g.homes)
        XCTAssertEqual(restored.moveCount, g.moveCount)
    }
}
