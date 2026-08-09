import XCTest
@testable import GameCore

final class BakersGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    /// 같은 딜 번호 → freecell/bakersGame 모두 같은 초기 columns
    func testSameDealAcrossVariants() {
        let f = FreeCellGame(gameNumber: 617, variant: .freecell)
        var b = FreeCellGame(gameNumber: 617, variant: .bakersGame)
        XCTAssertEqual(f.columns, b.columns)
        XCTAssertEqual(b.freeCells.count, 0)
        XCTAssertEqual(b.homes.count, 4)
        // Baker's 프리셀이 없어도 게임 정상
        XCTAssertFalse(b.isWon)
        XCTAssertTrue(b.homes.allSatisfy { $0.isEmpty })
        _ = b // keep
    }

    /// Baker's: 프리셀 이동은 무조건 거부
    func testFreeCellMovesRejected() {
        var b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        let top = b.columns[0].last!
        XCTAssertFalse(b.canMove(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top)))
        XCTAssertFalse(b.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top)))
    }

    /// Baker's: 같은 수트만 내림차순 쌓기, 교대색 거부
    func testSameSuitStackingRejectedAlternatingColor() {
        let b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        // 7♠ 위에 6♠ 는 허용 (같은 수트 내림차순)
        let top = Card(suit: .spades, rank: .seven)
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: top, variant: .bakersGame))
        // 7♥ 위에 6♠ 는 같은 수트 아니므로 거부 (교대색이어도)
        XCTAssertFalse(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .hearts, rank: .seven), variant: .bakersGame))
        // 프리셀이라면 교대색 카드는 허용돼야 함 (대조 검증)
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(suit: .spades, rank: .six), topCard: Card(suit: .hearts, rank: .seven), variant: .freecell))
    }

    /// Baker's: 한 번에 한 장만 이동 (2장 거부)
    func testOneCardLimitPerMove() {
        var b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        // 8♠,7♠ 시퀀스 (같은 수트) 구성
        let c8 = Card(suit: .spades, rank: .eight)
        let c7 = Card(suit: .spades, rank: .seven)
        b.columns[0] = [c8, c7]
        b.columns[1] = []
        XCTAssertFalse(b.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)))
        XCTAssertTrue(b.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
    }

    /// Baker's: 홈으로 A→K 같은 무늬 정상
    func testHomeMoveWorksInBakers() {
        var b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        let ace = card(0) // A♣
        guard let aceColumn = b.columns.firstIndex(where: { $0.contains(ace) }) else {
            return XCTFail("ace should exist")
        }
        b.columns[aceColumn].removeAll { $0 == ace }
        b.columns[aceColumn].append(ace)
        XCTAssertTrue(b.apply(.columnToHome(columnIndex: aceColumn, card: ace)))
        XCTAssertTrue(b.homes.contains { $0.contains(ace) })
    }

    /// legacy 저장(no variant) → freecell 기본값으로 복구
    func testDecodeDefaultVariant() throws {
        // variant 키 없이 기존 형식 그대로 인코딩
        var game = FreeCellGame(gameNumber: 1) // freecell
        let encoder = JSONEncoder()
        var data = try encoder.encode(game)
        // variant 키 제거 시뮬레이션: 수동으로 키 없는 JSON 생성
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var stripped = obj
        stripped.removeValue(forKey: "variant")
        data = try JSONSerialization.data(withJSONObject: stripped)

        let restored = try JSONDecoder().decode(FreeCellGame.self, from: data)
        XCTAssertEqual(restored.variant, .freecell)
        XCTAssertEqual(restored.freeCells.count, 4)
    }

    /// Codable 왕복 (variant 유지)
    func testCodableRoundTripVariant() throws {
        let b = FreeCellGame(gameNumber: 99, variant: .bakersGame)
        let data = try JSONEncoder().encode(b)
        let restored = try JSONDecoder().decode(FreeCellGame.self, from: data)
        XCTAssertEqual(restored.variant, .bakersGame)
        XCTAssertEqual(restored.freeCells.count, 0)
        XCTAssertEqual(restored.columns, b.columns)
    }
}