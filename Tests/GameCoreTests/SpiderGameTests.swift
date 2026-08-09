import XCTest
@testable import GameCore

final class SpiderGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    /// 테스트용: 모든 열을 비우고 지정 열만 구성
    private func freshGame(_ difficulty: SpiderGame.Difficulty = .fourSuits,
                           columns: [Int: [Card]] = [:]) -> SpiderGame {
        var g = SpiderGame(gameNumber: 42, difficulty: difficulty)
        g.columns = Array(repeating: [], count: SpiderGame.columnCount)
        for (i, cards) in columns {
            g.columns[i] = cards.map { .init(card: $0, faceUp: true) }
        }
        g.stock = []
        return g
    }

    // MARK: - 덱 구성

    func testDeckComposition() {
        let one = DealGenerator.spiderCards(gameNumber: 617, suitCount: 1)
        XCTAssertEqual(one.count, 104)
        XCTAssertTrue(one.allSatisfy { $0.suit == .spades })

        let two = DealGenerator.spiderCards(gameNumber: 617, suitCount: 2)
        XCTAssertEqual(two.count, 104)
        XCTAssertEqual(two.filter { $0.suit == .spades }.count, 52)
        XCTAssertEqual(two.filter { $0.suit == .hearts }.count, 52)

        let four = DealGenerator.spiderCards(gameNumber: 617, suitCount: 4)
        XCTAssertEqual(four.count, 104)
        for suit in Suit.allCases {
            XCTAssertEqual(four.filter { $0.suit == suit }.count, 26)
        }
    }

    /// 같은 게임 번호 → 동일한 순서
    func testDeckDeterministic() {
        let a = DealGenerator.spiderCards(gameNumber: 100, suitCount: 4)
        let b = DealGenerator.spiderCards(gameNumber: 100, suitCount: 4)
        XCTAssertEqual(a.map { $0.rawValue }, b.map { $0.rawValue })
    }

    // MARK: - 딜

    func testDealLayout() {
        var g = SpiderGame(gameNumber: 617, difficulty: .fourSuits)
        XCTAssertEqual(g.columns.count, 10)
        // 열 0~3은 6장, 열 4~9는 5장
        for i in 0..<4 { XCTAssertEqual(g.columns[i].count, 6) }
        for i in 4..<10 { XCTAssertEqual(g.columns[i].count, 5) }
        // 총 카드 104장 (열 54 + 스톡 50)
        let totalColumns = g.columns.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalColumns, 54)
        XCTAssertEqual(g.stock.count, 50)
        // 맨 위만 앞면
        for i in 0..<10 {
            for (j, cc) in g.columns[i].enumerated() {
                XCTAssertEqual(cc.faceUp, j == g.columns[i].count - 1)
            }
        }
        XCTAssertEqual(g.completedSuits, 0)
        XCTAssertFalse(g.isWon)
    }

    // MARK: - 이동 규칙

    /// 같은 수트 내림차순 시퀀스는 이동 가능 (K는 빈 열에만)
    func testMoveSameSuitRun() {
        var g = freshGame(columns: [
            0: [Card(suit: .spades, rank: .king),
                Card(suit: .spades, rank: .queen),
                Card(suit: .spades, rank: .jack)]
        ])
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 3)))
        XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 3)))
        XCTAssertEqual(g.columns[1].map { $0.card },
                       [Card(suit: .spades, rank: .king),
                        Card(suit: .spades, rank: .queen),
                        Card(suit: .spades, rank: .jack)])
        XCTAssertTrue(g.columns[0].isEmpty)
    }

    /// 다른 수트 시퀀스는 이동 불가 (K♠ 아래 Q♥는 같은 수트가 아님)
    func testMoveDifferentSuitRunNotAllowed() {
        var g = freshGame(columns: [
            0: [Card(suit: .spades, rank: .king),
                Card(suit: .hearts, rank: .queen)]
        ])
        XCTAssertFalse(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)))
        // 1장 이동은 허용 (시퀀스 아니어도 단일 카드)
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
    }

    /// 빈 열엔 아무 카드나 배치 가능
    func testEmptyColumnAcceptsAnyCard() {
        var g = freshGame(columns: [
            0: [Card(suit: .diamonds, rank: .three)]
        ])
        XCTAssertTrue(g.canPlaceOnColumn(Card(suit: .diamonds, rank: .three), column: 1))
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
    }

    /// 랭크 규칙: 목적지 맨 위보다 한 단계 낮아야 함
    func testRankRule() {
        var g = freshGame(columns: [
            0: [Card(suit: .hearts, rank: .six)],
            1: [Card(suit: .clubs, rank: .seven)]
        ])
        XCTAssertTrue(g.canPlaceOnColumn(Card(suit: .hearts, rank: .six), column: 1))
        XCTAssertFalse(g.canPlaceOnColumn(Card(suit: .spades, rank: .five), column: 1))
        XCTAssertTrue(g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)))
    }

    // MARK: - 완성 수트

    /// K→A 같은 수트 13장이 열에 있으면 자동 제거 + completedSuits 증가
    func testCompleteSuitRemoval() {
        var g = freshGame(columns: [
            0: (1...13).reversed().map { Card(suit: .spades, rank: Rank(rawValue: $0)!) }
                + [Card(suit: .hearts, rank: .seven)],
            1: [Card(suit: .hearts, rank: .six)]
        ])
        // 열 0의 완성 시퀀스(K♠..A♠)를 트리거하기 위해 6♥ → 7♥ 위로 이동
        XCTAssertTrue(g.canMove(.columnToColumn(from: 1, to: 0, cardCount: 1)))
        XCTAssertTrue(g.apply(.columnToColumn(from: 1, to: 0, cardCount: 1)))
        XCTAssertEqual(g.completedSuits, 1)
        // 13장 제거 후 남은 카드: 7♥, 6♥
        XCTAssertEqual(g.columns[0].map { $0.card },
                       [Card(suit: .hearts, rank: .seven),
                        Card(suit: .hearts, rank: .six)])
    }

    // MARK: - 스톡 딜

    func testDealFromStock() {
        var g = SpiderGame(gameNumber: 617, difficulty: .fourSuits)
        XCTAssertEqual(g.stock.count, 50)
        XCTAssertTrue(g.canMove(.dealFromStock))
        XCTAssertTrue(g.apply(.dealFromStock))
        // 각 열에 1장씩 앞면 추가, 스톡 40장
        XCTAssertEqual(g.stock.count, 40)
        for i in 0..<10 {
            XCTAssertEqual(g.columns[i].count, i < 4 ? 7 : 6)
            XCTAssertTrue(g.columns[i].last!.faceUp)
        }
    }

    /// 스톡이 비면 딜 불가
    func testDealFromStockEmpty() {
        var g = SpiderGame(gameNumber: 617, difficulty: .fourSuits)
        g.stock = []
        XCTAssertFalse(g.canMove(.dealFromStock))
    }

    // MARK: - 승리

    func testWinCondition() {
        var g = SpiderGame(gameNumber: 42, difficulty: .oneSuit)
        XCTAssertFalse(g.isWon)
        XCTAssertEqual(SpiderGame.completedSuitsToWin, 8)
    }

    // MARK: - 실행 취소 / 다시 실행

    func testUndoRedo() {
        var g = SpiderGame(gameNumber: 617, difficulty: .fourSuits)
        XCTAssertTrue(g.apply(.dealFromStock))
        XCTAssertEqual(g.stock.count, 40)
        XCTAssertEqual(g.moveCount, 1)
        g.undo()
        XCTAssertEqual(g.stock.count, 50)
        XCTAssertEqual(g.moveCount, 0)
        g.redo()
        XCTAssertEqual(g.stock.count, 40)
        XCTAssertEqual(g.moveCount, 1)
    }

    // MARK: - Codable

    func testCodableRoundTrip() {
        var g = SpiderGame(gameNumber: 100, difficulty: .twoSuits)
        _ = g.apply(.dealFromStock)
        _ = g.apply(.dealFromStock)
        let data = try! JSONEncoder().encode(g)
        let decoded = try! JSONDecoder().decode(SpiderGame.self, from: data)
        XCTAssertEqual(decoded, g)
        XCTAssertEqual(decoded.gameNumber, 100)
        XCTAssertEqual(decoded.difficulty, .twoSuits)
        XCTAssertEqual(decoded.stock.count, g.stock.count)
        XCTAssertEqual(decoded.moveCount, g.moveCount)
    }
}
