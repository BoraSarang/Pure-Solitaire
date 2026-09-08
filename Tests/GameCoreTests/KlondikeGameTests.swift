import XCTest
@testable import GameCore

final class KlondikeGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    // MARK: - 딜

    func testDealLayout() {
        var g = KlondikeGame(gameNumber: 617)
        XCTAssertEqual(g.columns.count, 7)
        // 열 i는 i+1장
        for i in 0..<7 {
            XCTAssertEqual(g.columns[i].count, i + 1)
        }
        // 총 카드 52장
        let totalColumns = g.columns.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalColumns + g.stock.count, 52)
        XCTAssertEqual(g.stock.count, 24)
        // 맨 위만 앞면
        for i in 0..<7 {
            for (j, cc) in g.columns[i].enumerated() {
                XCTAssertEqual(cc.faceUp, j == g.columns[i].count - 1)
            }
        }
        XCTAssertTrue(g.waste.isEmpty)
        XCTAssertEqual(g.homes.count, 4)
        XCTAssertTrue(g.homes.allSatisfy { $0.isEmpty })
        XCTAssertFalse(g.isWon)
    }

    /// 같은 딜 번호 → 52장이 겹치지 않고 전체 포함
    func testDealUsesAllUniqueCards() {
        let g = KlondikeGame(gameNumber: 42)
        var all: [Card] = g.columns.flatMap { $0.map { $0.card } } + g.stock
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52)
        XCTAssertEqual(all.map { $0.rawValue }.sorted(), (0..<52).map { $0 })
    }

    // MARK: - 이동 규칙

    /// 빈 열에는 K만 놓을 수 있다
    func testEmptyColumnOnlyKing() {
        var g = KlondikeGame(gameNumber: 1)
        // 열 하나 비우기
        for col in 0..<7 where g.columns[col].count == 1 {
            _ = g.apply(.columnToHome(columnIndex: col, card: g.columns[col].last!.card))
        }
        // 아무 열이나 비었는지 확인
        guard let empty = g.columns.firstIndex(where: { $0.isEmpty }) else {
            XCTAssertTrue(true)
            return
        }
        XCTAssertTrue(g.canPlaceOnColumn(card(3), column: empty))   // Q♣ → K 자리 아님
        XCTAssertTrue(g.canPlaceOnColumn(card(51), column: empty))  // K♠
    }

    /// 교대색 내림차순만 이동 허용
    func testAlternatingColorMove() {
        var g = KlondikeGame(gameNumber: 1)
        // 열에서 앞면 카드 하나 확인
        guard let src = g.columns.indices.first(where: { $0 != 0 }),
              let top = g.columns[src].last, top.faceUp else {
            XCTFail("대상 열 없음")
            return
        }
        // 목적지 열은 마지막 카드와 비교
        let destCol = 0
        guard let destTop = g.columns[destCol].last else {
            XCTAssertTrue(g.canPlaceOnColumn(top.card, column: destCol))
            return
        }
        // destTop 보다 한 단계 높은(rank+1) 카드면 놓을 수 있음 (색 교대 시)
        let expectPlace = (top.card.rank == destTop.card.rank.next) && (top.card.color != destTop.card.color)
        XCTAssertEqual(g.canPlaceOnColumn(top.card, column: destCol), expectPlace)
    }

    /// 뒤집힌 카드는 이동 불가
    func testFaceDownNotMovable() {
        let g = KlondikeGame(gameNumber: 1)
        for i in 0..<7 {
            for cc in g.columns[i] where !cc.faceUp {
                // 뒤집힌 카드는 웨이스트/홈 이동 불가
                XCTAssertFalse(g.canMove(.columnToHome(columnIndex: i, card: cc.card)))
            }
        }
    }

    /// 뒤집기: 빈 열이면 뒤집힌 카드를 뒤집을 수 있다
    func testFlipFaceDown() {
        var g = KlondikeGame(gameNumber: 1)
        // 열 하나만 카드 1장(K) → 홈으로 보내면 빈 열
        let col = g.columns.firstIndex(where: { $0.count == 1 })!
        _ = g.apply(.columnToHome(columnIndex: col, card: g.columns[col].last!.card))
        // 이제 그 열은 빈 상태지만 다른 열은 뒤집힌 카드 보유
        // 뒤집기 후보: 아무 열의 맨 위 뒤집힌 카드
        guard let flipCol = g.columns.indices.first(where: { $0 != col && g.columns[$0].last?.faceUp == false }) else {
            XCTAssertTrue(true)
            return
        }
        let faceDownCard = g.columns[flipCol].last!.card
        XCTAssertTrue(g.canMove(.flipColumnCard(columnIndex: flipCol, card: faceDownCard)))
        XCTAssertTrue(g.apply(.flipColumnCard(columnIndex: flipCol, card: faceDownCard)))
        XCTAssertTrue(g.columns[flipCol].last!.faceUp)
    }

    /// 스톡 드로 → 웨이스트, 웨이스트 → 열/홈
    func testStockDrawAndWaste() {
        var g = KlondikeGame(gameNumber: 1)
        let stockBefore = g.stock.count
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.stock.count, stockBefore - 1)
        XCTAssertEqual(g.waste.count, 1)
        let top = g.waste.last!

        // 웨이스트 → 홈: A면 가능
        if top.rank == .ace {
            XCTAssertTrue(g.canMove(.wasteToFoundation(card: top)))
            XCTAssertTrue(g.apply(.wasteToFoundation(card: top)))
            XCTAssertTrue(g.homes.contains { $0.count == 1 })
        }
    }

    /// 스톡이 비면 드로 불가
    func testDrawWhenStockEmpty() {
        var g = KlondikeGame(gameNumber: 1)
        while !g.stock.isEmpty {
            XCTAssertTrue(g.apply(.drawFromStock))
        }
        XCTAssertFalse(g.canMove(.drawFromStock))
    }

    // MARK: - 스톡 재활용

    /// 스톡이 비면 웨이스트를 역순으로 스톡에 재활용
    func testRecycleStockWhenEmpty() {
        var g = KlondikeGame(gameNumber: 1)
        while !g.stock.isEmpty {
            XCTAssertTrue(g.apply(.drawFromStock))
        }
        XCTAssertTrue(g.stock.isEmpty)
        XCTAssertEqual(g.waste.count, 24)

        let wasteBefore = g.waste
        let countBefore = g.moveCount
        XCTAssertTrue(g.canMove(.recycleStock))
        XCTAssertTrue(g.apply(.recycleStock))
        XCTAssertEqual(g.stock, Array(wasteBefore.reversed()))
        XCTAssertTrue(g.waste.isEmpty)
        XCTAssertEqual(g.moveCount, countBefore + 1)
    }

    /// 재활용 순서: 웨이스트 역순 → 이후 드로 시 원래 웨이스트 맨 아래가 먼저 나옴
    func testRecycleOrderPreserved() {
        var g = KlondikeGame(gameNumber: 1)
        while !g.stock.isEmpty {
            _ = g.apply(.drawFromStock)
        }
        let firstWasteCard = g.waste[0]
        _ = g.apply(.recycleStock)
        _ = g.apply(.drawFromStock)
        XCTAssertEqual(g.waste.last, firstWasteCard)
    }

    /// 스톡이 남아 있으면 재활용 불가
    func testRecycleRequiresEmptyStock() {
        var g = KlondikeGame(gameNumber: 1)
        XCTAssertFalse(g.canMove(.recycleStock))
        XCTAssertFalse(g.apply(.recycleStock))
    }

    /// 웨이스트까지 비면 재활용 불가
    func testRecycleRequiresWasteCards() {
        var g = KlondikeGame(gameNumber: 1)
        while !g.stock.isEmpty {
            _ = g.apply(.drawFromStock)
        }
        _ = g.apply(.recycleStock)
        XCTAssertFalse(g.canMove(.recycleStock))
        XCTAssertFalse(g.apply(.recycleStock))
    }

    /// 재활용 undo/redo 복원
    func testRecycleUndoRedo() {
        var g = KlondikeGame(gameNumber: 1)
        while !g.stock.isEmpty {
            _ = g.apply(.drawFromStock)
        }
        let wasteBefore = g.waste
        let countBefore = g.moveCount
        _ = g.apply(.recycleStock)
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.waste, wasteBefore)
        XCTAssertTrue(g.stock.isEmpty)
        XCTAssertEqual(g.moveCount, countBefore)
        g.redo()
        XCTAssertEqual(g.stock, Array(wasteBefore.reversed()))
        XCTAssertTrue(g.waste.isEmpty)
    }

    // MARK: - 승리/undo/Codable

    /// 홈셀 4개에 13장씩 쌓이면 승리
    func testWinDetection() {
        var g = KlondikeGame(gameNumber: 1)
        // 인위적으로 홈셀 완성 (열 상태와 무관하게)
        g.homes = [[Card]].init(repeating: (1...13).map { Card(rawValue: $0 * 4 - 4) }, count: 4)
        XCTAssertTrue(g.isWon)
    }

    /// 이동 후 undo/redo 복원
    func testUndoRedo() {
        var g = KlondikeGame(gameNumber: 1)
        let snapBefore = g.columns
        _ = g.apply(.drawFromStock)
        XCTAssertTrue(g.canUndo)
        g.undo()
        XCTAssertEqual(g.columns, snapBefore)
        XCTAssertTrue(g.waste.isEmpty)
        g.redo()
        XCTAssertEqual(g.waste.count, 1)
    }

    // MARK: - 스톡 드로 3장 모드

    /// drawMode=3: 드로마다 3장씩, 3장 미만 남으면 남은 만큼만
    func testDrawThreeCards() {
        var g = KlondikeGame(gameNumber: 1, drawMode: 3)
        XCTAssertTrue(g.canMove(.drawFromStock))
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.waste.count, 3)
        XCTAssertEqual(g.stock.count, 21)
    }

    /// 드로 3장에서 3장 미만 남으면 남은 장수만 웨이스트로
    func testDrawThreePartialStock() {
        var g = KlondikeGame(gameNumber: 1, drawMode: 3)
        g.stock = [Card(suit: .hearts, rank: .two), Card(suit: .clubs, rank: .three)]
        XCTAssertTrue(g.apply(.drawFromStock))
        XCTAssertEqual(g.waste.count, 2)
        XCTAssertTrue(g.stock.isEmpty)
        _ = g.apply(.recycleStock)
        XCTAssertTrue(g.waste.isEmpty)
        XCTAssertEqual(g.stock.count, 2)
    }

    /// 드로 3장 모드에서 recycle 후 순서 유지
    func testDrawThreeRecycle() {
        var g = KlondikeGame(gameNumber: 1, drawMode: 3)
        while !g.stock.isEmpty {
            _ = g.apply(.drawFromStock)
        }
        let firstWasteCard = g.waste[0]
        _ = g.apply(.recycleStock)
        _ = g.apply(.drawFromStock)
        XCTAssertEqual(g.waste.count, 3)
        XCTAssertEqual(g.waste.last, firstWasteCard)
    }

    /// 드로 3장 모드 Codable 왕복 (drawMode 보존)
    func testCodableRoundTripDrawModeThree() {
        var g = KlondikeGame(gameNumber: 617, drawMode: 3)
        _ = g.apply(.drawFromStock)
        let data = try! JSONEncoder().encode(g)
        let restored = try! JSONDecoder().decode(KlondikeGame.self, from: data)
        XCTAssertEqual(restored.drawMode, 3)
        XCTAssertEqual(restored.waste, g.waste)
        XCTAssertEqual(restored.stock, g.stock)
    }

    /// Codable 왕복
    func testCodableRoundTrip() {
        var g = KlondikeGame(gameNumber: 617)
        _ = g.apply(.drawFromStock)
        let data = try! JSONEncoder().encode(g)
        let restored = try! JSONDecoder().decode(KlondikeGame.self, from: data)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.stock, g.stock)
        XCTAssertEqual(restored.waste, g.waste)
        XCTAssertEqual(restored.homes, g.homes)
        XCTAssertEqual(restored.moveCount, g.moveCount)
    }

    // MARK: - 부분 시퀀스 이동 (T-251: Spider와 동일 버그)

    private func freshGame(columns: [Int: [Card]]) -> KlondikeGame {
        var g = KlondikeGame(gameNumber: 42)
        g.columns = Array(repeating: [], count: KlondikeGame.columnCount)
        for (i, cards) in columns {
            g.columns[i] = cards.map { .init(card: $0, faceUp: true) }
        }
        g.stock = []
        g.waste = []
        return g
    }

    /// 9♣-8♥-7♣ 중 8♥-7♣만 9♠ 위로 — 허용되어야 함
    /// raw: 9♣=32, 8♥=30, 7♣=24, 9♠=35
    func testPartialRunMoveAccepted() {
        var g = freshGame(columns: [0: [card(32), card(30), card(24)],
                                     1: [card(35)]])
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)))
        XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 2)))
        XCTAssertEqual(g.columns[1].map { $0.card.rawValue }, [35, 30, 24])
    }

    /// 8♥-7♣을 10♥ 위로는 불가 — 전체 run 맨 아래(9♣)가 맞는다고 허용하면 안 됨
    /// 10♥=38
    func testPartialRunMoveRejected() {
        var g = freshGame(columns: [0: [card(32), card(30), card(24)],
                                     1: [card(38)]])
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)))
    }
}
