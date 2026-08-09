import XCTest
@testable import GameCore

final class SuperFreeCellGameTests: XCTestCase {

    /// 딜 구성: 104장(2덱), 10열, 첫 4열 11장/다음 6열 10장, 프리셀 6개, 홈셀 4개
    func testDealLayout() {
        let g = FreeCellGame(gameNumber: 617, variant: .superFreeCell)
        XCTAssertEqual(g.columns.count, 10)
        XCTAssertEqual(g.columns[0].count, 11)
        XCTAssertEqual(g.columns[3].count, 11)
        XCTAssertEqual(g.columns[4].count, 10)
        XCTAssertEqual(g.columns[9].count, 10)
        let total = g.columns.flatMap { $0 }.count
        XCTAssertEqual(total, 104)
        XCTAssertEqual(g.freeCells.count, 6)
        XCTAssertTrue(g.freeCells.allSatisfy { $0 == nil }, "Super FreeCell 프리셀은 빈 상태로 시작")
        XCTAssertEqual(g.homes.count, 4)
    }

    /// 2덱: 모든 카드가 정확히 2장씩
    func testEveryCardAppearsTwice() {
        let g = FreeCellGame(gameNumber: 99, variant: .superFreeCell)
        let all = g.columns.flatMap { $0 }
        for raw in 0..<52 {
            let c = Card(rawValue: raw)
            let count = all.filter { $0 == c }.count
            XCTAssertEqual(count, 2, "\(c.shortDescription)는 2장이어야 함")
        }
    }

    /// 결정적 재현
    func testDeterministicDeal() {
        let a = FreeCellGame(gameNumber: 42, variant: .superFreeCell)
        let b = FreeCellGame(gameNumber: 42, variant: .superFreeCell)
        XCTAssertEqual(a.columns, b.columns)
    }

    /// 교대색 내림차순, 빈 열 아무 카드 (표준 프리셀 규칙)
    func testAlternatingColorAndEmptyColumn() {
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .hearts, rank: .seven), variant: .superFreeCell))
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .clubs, rank: .seven), variant: .superFreeCell), "같은 색은 거부")
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .two), topCard: nil, variant: .superFreeCell), "빈 열엔 아무 카드")
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .ace), topCard: nil, variant: .superFreeCell))
    }

    /// 수퍼무브: (빈 프리셀+1) × 2^(빈 열) — 표준 공식, 교대색 시퀀스만 이동 가능
    func testSupermoveStandardFormula() {
        var g = FreeCellGame(gameNumber: 1, variant: .superFreeCell)
        // 교대색 8장 시퀀스 (♣K,♥Q,♠J,♦10,♣9,♥8,♠7,♦6)
        let cards: [Card] = [
            Card(suit: .clubs, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .spades, rank: .jack),
            Card(suit: .diamonds, rank: .ten),
            Card(suit: .clubs, rank: .nine),
            Card(suit: .hearts, rank: .eight),
            Card(suit: .spades, rank: .seven),
            Card(suit: .diamonds, rank: .six),
        ]
        g.columns[0] = cards
        // 목적지 열 1 + 임시 저장용 빈 열 2 → 빈 프리셀 6, 빈 열 2(목적지 제외 1) → 용량 (6+1)×2 = 14 ≥ 8
        g.columns[1] = []
        g.columns[2] = []
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 8)))
        // 목적지가 빈 열이면 그 열은 임시로 못 씀 → 용량 7로 감소 → 8장 이동 불가
        g.columns[1] = []
        g.columns[2] = [Card(suit: .spades, rank: .two)]
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 8)), "목적지 빈 열은 용량에 미포함")
        // 같은 수트 2장 연속이면 2장 이동 불가 (교대색 아님)
        g.columns[0] = [Card(suit: .clubs, rank: .king), Card(suit: .clubs, rank: .queen)]
        g.columns[1] = []
        g.columns[2] = []
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)), "같은 수트는 수퍼무브로 못 움직임")
    }

    /// 홈셀: 수트 고정, A→K 후 다시 A→K (26장)
    func testHomeSuitFixedAndDoubleCycle() {
        var g = FreeCellGame(gameNumber: 1, variant: .superFreeCell)
        // ♣ 홈(0): A♣ 첫 배치
        let ace = Card(suit: .clubs, rank: .ace)
        XCTAssertTrue(g.canMoveToHome(ace))
        _ = g.apply(.columnToHome(columnIndex: 0, card: ace)) // 실제 열에 A 없으면 거부될 수 있음 → 직접 주입
        g.homes[0] = [ace]
        // 2♣ → K♣ 쌓기
        for raw in 2...13 {
            let c = Card(suit: .clubs, rank: Rank(rawValue: raw)!)
            g.homes[0].append(c)
        }
        XCTAssertEqual(g.homes[0].count, 13)
        XCTAssertEqual(g.homes[0].last!.rank, .king)
        // K♣ 위에 다시 A♣ 허용 (2세트 시작)
        XCTAssertTrue(g.canMoveToHome(Card(suit: .clubs, rank: .ace)))
        g.homes[0].append(Card(suit: .clubs, rank: .ace))
        // 다른 수트는 이 홈에 못 옴
        XCTAssertFalse(g.canMoveToHome(Card(suit: .hearts, rank: .two)), "다른 수트는 같은 홈 거부")
        // 같은 수트 순차만
        XCTAssertTrue(g.canMoveToHome(Card(suit: .clubs, rank: .two)))
    }

    /// 승리: 홈 4개 모두 26장
    func testWinCondition() {
        var g = FreeCellGame(gameNumber: 1, variant: .superFreeCell)
        for suit in Suit.allCases {
            var pile: [Card] = []
            for _ in 0..<2 {
                for raw in 1...13 {
                    pile.append(Card(suit: suit, rank: Rank(rawValue: raw)!))
                }
            }
            g.homes[suit.rawValue] = pile
        }
        XCTAssertTrue(g.isWon)
        XCTAssertFalse(FreeCellGame(gameNumber: 1, variant: .superFreeCell).isWon)
    }

    /// undo/redo
    func testUndoRedo() {
        var g = FreeCellGame(gameNumber: 1, variant: .superFreeCell)
        let from = g.columns[0].last!
        let top1 = g.columns[1].last!
        if FreeCellRule.canMoveToColumn(from, topCard: top1, variant: .superFreeCell) {
            let before = g.columns
            XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 1)))
            g.undo()
            XCTAssertEqual(g.columns, before)
            g.redo()
            XCTAssertEqual(g.moveCount, 1)
        }
    }

    /// Codable 왕복
    func testCodableRoundTrip() throws {
        let g = FreeCellGame(gameNumber: 77, variant: .superFreeCell)
        let data = try JSONEncoder().encode(g)
        let restored = try JSONDecoder().decode(FreeCellGame.self, from: data)
        XCTAssertEqual(restored.variant, .superFreeCell)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.freeCells, g.freeCells)
    }
}
