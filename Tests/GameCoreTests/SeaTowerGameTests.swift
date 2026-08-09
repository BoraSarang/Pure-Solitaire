import XCTest
@testable import GameCore

final class SeaTowerGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    /// 딜 구성: 10열 각 5장 + 프리셀 2장(0,1), 총 52장 무중복
    func testDealLayout() {
        let g = FreeCellGame(gameNumber: 617, variant: .seaTower)
        XCTAssertEqual(g.columns.count, 10)
        XCTAssertTrue(g.columns.allSatisfy { $0.count == 5 })
        XCTAssertEqual(g.freeCells.count, 4)
        XCTAssertNotNil(g.freeCells[0])
        XCTAssertNotNil(g.freeCells[1])
        XCTAssertNil(g.freeCells[2])
        XCTAssertNil(g.freeCells[3])
        XCTAssertEqual(g.homes.count, 4)
        let all = g.columns.flatMap { $0 } + g.freeCells.compactMap { $0 }
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52, "모든 카드는 유일해야 함")
    }

    /// 같은 게임 번호 → 결정적 재현
    func testDeterministicDeal() {
        let a = FreeCellGame(gameNumber: 42, variant: .seaTower)
        let b = FreeCellGame(gameNumber: 42, variant: .seaTower)
        XCTAssertEqual(a.columns, b.columns)
        XCTAssertEqual(a.freeCells, b.freeCells)
    }

    /// 같은 수트만 내림차순 쌓기, 다른 수트(교대색 포함) 거부
    func testSameSuitStacking() {
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .spades, rank: .seven), variant: .seaTower))
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .hearts, rank: .seven), variant: .seaTower), "교대색이지만 다른 수트는 거부")
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .five), topCard: Card(suit: .spades, rank: .seven), variant: .seaTower), "랭크 연속 아니면 거부")
    }

    /// 빈 열에는 K만 (비-K 거부)
    func testEmptyColumnKingOnly() {
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .king), topCard: nil, variant: .seaTower))
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .hearts, rank: .king), topCard: nil, variant: .seaTower))
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .queen), topCard: nil, variant: .seaTower), "빈 열에 Q는 거부")
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .ace), topCard: nil, variant: .seaTower), "빈 열에 A는 거부")
    }

    /// K로 시작하는 시퀀스만 빈 열 이동 가능 (K→Q→J 같은 수트), K 단독도 허용
    func testEmptyColumnKingSequence() {
        var g = FreeCellGame(gameNumber: 1, variant: .seaTower)
        let k = Card(suit: .spades, rank: .king)
        let q = Card(suit: .spades, rank: .queen)
        g.columns[0] = [k, q]
        g.columns[1] = []
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)), "K로 시작하는 같은 수트 시퀀스는 빈 열 이동 가능")
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)), "K 단독도 빈 열 이동 가능")
    }

    /// 수퍼무브: Sea Tower는 빈 열을 임시 저장으로 못 씀 → 용량 = 빈 프리셀 + 1 (빈 열 무시)
    func testSupermoveCapacityIgnoresEmptyColumns() {
        var g = FreeCellGame(gameNumber: 1, variant: .seaTower)
        // 열 0에 같은 수트 5장 시퀀스 (K♣,Q♣,J♣,10♣,9♣)
        let k = Card(suit: .clubs, rank: .king)
        let q = Card(suit: .clubs, rank: .queen)
        let j = Card(suit: .clubs, rank: .jack)
        let ten = Card(suit: .clubs, rank: .ten)
        let nine = Card(suit: .clubs, rank: .nine)
        g.columns[0] = [k, q, j, ten, nine]
        g.columns[1] = []
        // 프리셀 2,3 비움 (0,1은 시작 카드로 참) → 빈 프리셀 2개, 빈 열 1개
        g.freeCells[2] = nil
        g.freeCells[3] = nil
        // Sea Tower 용량 = 2+1 = 3 → 4장 이동 불가, 3장 이동 가능
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 4)))
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 3)))
        // 빈 프리셀을 3개로 늘려도 (빈 열 1개 존재) 빈 열은 기여하지 않으므로 용량 4 → 5장은 여전히 불가
        g.freeCells[1] = nil
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 4)), "빈 프리셀 3개 → 용량 4")
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 5)), "빈 열 1개가 있어도 5장 불가 (Sea Tower는 빈 열 미반영)")
    }

    /// 시작 프리셀 카드(K♣)는 빈 열로 이동 가능 (Sea Tower: K만 빈 열에 옴)
    func testFreeCellStartMove() {
        var g = FreeCellGame(gameNumber: 617, variant: .seaTower)
        guard let start = g.freeCells[0] else { return XCTFail("freeCells[0] should have card") }
        XCTAssertEqual(start, Card(suit: .clubs, rank: .king), "deal 617의 시작 프리셀은 K♣")
        g.columns[0] = []
        XCTAssertTrue(g.apply(.freeCellToColumn(freeCellIndex: 0, columnIndex: 0, card: start)))
        XCTAssertNil(g.freeCells[0], "이동 성공 시 프리셀은 비워져야 함")
        XCTAssertEqual(g.moveCount, 1)
    }

    /// 승리: 홈셀 4개 모두 13장
    func testWinCondition() {
        var g = FreeCellGame(gameNumber: 1, variant: .seaTower)
        for suit in Suit.allCases {
            var pile: [Card] = []
            for raw in 0..<13 {
                pile.append(Card(suit: suit, rank: Rank(rawValue: raw + 1)!))
            }
            g.homes[suit.rawValue] = pile
        }
        XCTAssertTrue(g.isWon)
    }

    /// undo/redo 정상
    func testUndoRedo() {
        var g = FreeCellGame(gameNumber: 1, variant: .seaTower)
        // 열 0에서 열 1로 1장 이동 가능한지 확인 후 undo/redo
        let from = g.columns[0].last!
        let top1 = g.columns[1].last!
        let moveable = FreeCellRule.canMoveToColumn(from, topCard: top1, variant: .seaTower)
        if moveable {
            let before = g.columns
            XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 1)))
            XCTAssertEqual(g.moveCount, 1)
            g.undo()
            XCTAssertEqual(g.columns, before)
            XCTAssertTrue(g.canUndo == false)
            g.redo()
            XCTAssertEqual(g.moveCount, 1)
        }
    }

    /// Codable 왕복 (variant/딜 유지)
    func testCodableRoundTrip() throws {
        let g = FreeCellGame(gameNumber: 77, variant: .seaTower)
        let data = try JSONEncoder().encode(g)
        let restored = try JSONDecoder().decode(FreeCellGame.self, from: data)
        XCTAssertEqual(restored.variant, .seaTower)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.freeCells, g.freeCells)
        XCTAssertEqual(restored.moveCount, g.moveCount)
    }
}
