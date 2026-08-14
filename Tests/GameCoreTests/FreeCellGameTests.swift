import XCTest
@testable import GameCore

final class FreeCellGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    /// 초기 상태: 프리셀 4개 모두 비어 있고, 홈셀 4개 비어 있음
    func testInitialState() {
        let game = FreeCellGame(gameNumber: 1)
        XCTAssertEqual(game.columns.count, 8)
        XCTAssertEqual(game.freeCells.count, 4)
        XCTAssertEqual(game.homes.count, 4)
        XCTAssertTrue(game.freeCells.allSatisfy { $0 == nil })
        XCTAssertTrue(game.homes.allSatisfy { $0.isEmpty })
        XCTAssertFalse(game.isWon)
    }

    /// 타블로 → 프리셀 이동
    func testColumnToFreeCell() {
        var game = FreeCellGame(gameNumber: 1)
        guard let top = game.columns[0].last else { return XCTFail("column should not be empty") }
        XCTAssertTrue(game.canMove(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top)))
        XCTAssertTrue(game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top)))
        XCTAssertEqual(game.freeCells[0], top)
        XCTAssertFalse(game.columns[0].contains(top))
        XCTAssertEqual(game.moveCount, 1)
    }

    /// 빈 프리셀에 또 다른 카드는 불가
    func testColumnToFreeCell_OccupiedRejected() {
        var game = FreeCellGame(gameNumber: 1)
        let c0 = game.columns[0].last!
        let c1 = game.columns[1].last!
        game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: c0))
        XCTAssertFalse(game.apply(.columnToFreeCell(columnIndex: 1, freeCellIndex: 0, card: c1)))
    }

    /// 프리셀 → 타블로 (빈 열로)
    func testFreeCellToColumn() {
        var game = FreeCellGame(gameNumber: 1)
        guard let top = game.columns[0].last else { return XCTFail() }
        game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top))
        game.columns[1] = []
        XCTAssertTrue(game.canMove(.freeCellToColumn(freeCellIndex: 0, columnIndex: 1, card: top)))
        XCTAssertTrue(game.apply(.freeCellToColumn(freeCellIndex: 0, columnIndex: 1, card: top)))
        XCTAssertNil(game.freeCells[0])
        XCTAssertEqual(game.columns[1].last, top)
    }

    /// 에이스를 홈으로 이동
    func testColumnToHome_Ace() {
        var game = FreeCellGame(gameNumber: 1)
        let ace = card(0) // A♣
        guard let aceColumn = game.columns.firstIndex(where: { $0.contains(ace) }) else {
            return XCTFail("ace of clubs should exist")
        }
        game.columns[aceColumn].removeAll { $0 == ace }
        game.columns[aceColumn].append(ace)

        XCTAssertTrue(game.canMove(.columnToHome(columnIndex: aceColumn, card: ace)))
        XCTAssertTrue(game.apply(.columnToHome(columnIndex: aceColumn, card: ace)))
        XCTAssertTrue(game.homes.contains { $0.contains(ace) })
    }

    /// 홈셀에서 카드 꺼내기 허용 (MS 규칙)
    func testHomeToColumn() {
        var game = FreeCellGame(gameNumber: 1)
        let ace = card(0)
        game.homes[0].append(ace)
        game.columns[0] = [] // 빈 열
        XCTAssertTrue(game.canMove(.homeToColumn(homeIndex: 0, columnIndex: 0, card: ace)))
        XCTAssertTrue(game.apply(.homeToColumn(homeIndex: 0, columnIndex: 0, card: ace)))
        XCTAssertTrue(game.homes[0].isEmpty)
        XCTAssertEqual(game.columns[0].last, ace)
    }

    /// 무효한 이동은 거부되고 상태가 변하지 않는다
    func testInvalidMoveRejected() {
        var game = FreeCellGame(gameNumber: 1)
        let snapshot = game
        let badMove = Move.columnToColumn(from: 0, to: 1, cardCount: 99)
        XCTAssertFalse(game.apply(badMove))
        XCTAssertEqual(game, snapshot)
    }

    /// Undo / Redo
    func testUndoRedo() {
        var game = FreeCellGame(gameNumber: 1)
        let top0 = game.columns[0].last!
        let top1 = game.columns[1].last!

        game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top0))
        game.apply(.columnToFreeCell(columnIndex: 1, freeCellIndex: 1, card: top1))
        XCTAssertEqual(game.moveCount, 2)

        let after = game
        game.undo()
        XCTAssertNil(game.freeCells[1])
        XCTAssertEqual(game.columns[1].last, top1)
        game.undo()
        XCTAssertNil(game.freeCells[0])
        XCTAssertEqual(game.columns[0].last, top0)
        XCTAssertEqual(game.moveCount, 0)

        game.redo()
        XCTAssertEqual(game.freeCells[0], top0)
        XCTAssertEqual(game.moveCount, 1)
        game.redo()
        XCTAssertEqual(game, after)
    }

    /// 자동 풀어 보기 재생 전용 적용 — 상태는 변경하되 undo 스택/이동 수에는 남지 않음
    func testApplyForReplayDoesNotPolluteHistory() {
        var game = FreeCellGame(gameNumber: 1)
        let top0 = game.columns[0].last!
        let after = game

        XCTAssertTrue(game.applyForReplay(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top0)))
        XCTAssertEqual(game.freeCells[0], top0)
        XCTAssertEqual(game.moveCount, 0, "재생 적용은 이동 수를 증가시키지 않아야 함")
        XCTAssertFalse(game.canUndo, "재생 적용은 undo 기록을 만들지 않아야 함")
        XCTAssertFalse(game.canRedo)

        // 유효성 검사는 수행 — 무효 이동은 거부
        let fake = Card(suit: .spades, rank: .king)
        XCTAssertFalse(game.applyForReplay(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: fake)))
        // 상태 복원 가능성 검증 (스냅샷으로 완전 복구)
        game = after
        XCTAssertEqual(game, FreeCellGame(gameNumber: 1))
    }

    /// 수퍼무브 검증: 빈 프리셀 4개 + 빈 열 0개 → 이동 가능 시퀀스는 1장
    func testSupermoveCapacityInGame() {
        var game = FreeCellGame(gameNumber: 1)
        XCTAssertEqual(game.emptyFreeCellCount, 4)
        XCTAssertEqual(game.columns.filter { $0.isEmpty }.count, 0)

        // 이동할 시퀀스가 1장뿐이므로 2장 이동 불가
        XCTAssertFalse(game.canMove(.columnToColumn(from: 0, to: 1, cardCount: 2)))

        // 빈 열(col7) 생성 후 col0의 top을 빈 열로 이동 가능
        game.columns[7] = []
        XCTAssertTrue(game.canMove(.columnToColumn(from: 0, to: 7, cardCount: 1)))
        XCTAssertFalse(game.canMove(.columnToColumn(from: 0, to: 7, cardCount: 2)))
    }

    /// 여러 장 시퀀스 이동: 8♠,7♥,6♠ → 빈 열로 한 번에 3장 이동
    func testMultiCardColumnToColumn() {
        var game = FreeCellGame(gameNumber: 1)
        let c8 = Card(suit: .spades, rank: .eight)
        let c7 = Card(suit: .hearts, rank: .seven)
        let c6 = Card(suit: .spades, rank: .six)
        game.columns[0] = [c8, c7, c6]
        game.columns[1] = []

        let run = FreeCellRule.movableRun(from: game.columns[0])
        XCTAssertEqual(run.map(\.shortDescription), ["8S", "7H", "6S"])

        XCTAssertTrue(game.canMove(.columnToColumn(from: 0, to: 1, cardCount: 3)))
        XCTAssertTrue(game.apply(.columnToColumn(from: 0, to: 1, cardCount: 3)))
        XCTAssertTrue(game.columns[0].isEmpty)
        XCTAssertEqual(game.columns[1], [c8, c7, c6])
        XCTAssertEqual(game.moveCount, 1)
    }

    /// 모든 카드가 홈에 오면 승리
    func testIsWon() {
        var game = FreeCellGame(gameNumber: 1)
        for suit in Suit.allCases {
            let suitCards = Deck.standard().filter { $0.suit == suit }.sorted { $0.rank < $1.rank }
            game.homes[suit.rawValue] = suitCards
        }
        XCTAssertTrue(game.isWon)
    }

    /// 힌트: 유효한 이동이 있으면 nil이 아니다
    func testHintAvailable() {
        let game = FreeCellGame(gameNumber: 1)
        XCTAssertNotNil(game.hint())
    }

    /// 힌트 후보: 첫 후보는 hint()와 동일, 모든 후보는 유효해야 한다
    func testHintCandidatesAreValid() {
        let game = FreeCellGame(gameNumber: 1)
        let candidates = game.hintCandidates()
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertEqual(candidates.first, game.hint())
        for move in candidates {
            XCTAssertTrue(game.canMove(move), "invalid candidate \(move)")
        }
    }

    /// 힌트 후보: 모든 카드가 홈에 있으면 비어야 한다
    func testHintCandidatesEmptyWhenWon() {
        var game = FreeCellGame(gameNumber: 1)
        for suit in Suit.allCases {
            let suitCards = Deck.standard().filter { $0.suit == suit }.sorted { $0.rank < $1.rank }
            game.homes[suit.rawValue] = suitCards
        }
        game.columns = Array(repeating: [], count: 8)
        game.freeCells = Array(repeating: nil, count: 4)
        XCTAssertTrue(game.isWon)
        XCTAssertTrue(game.hintCandidates().isEmpty)
        XCTAssertNil(game.hint())
    }

    // MARK: - 에지 케이스 회귀 테스트

    /// 빈 프리셀 경계: freeCells가 0개인 Baker's는 프리셀 이동 인덱스(0)가 비어 배열이라도 거부
    func testBakersFreeCellIndexOutOfRange() {
        var b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        let top = b.columns[0].last!
        XCTAssertEqual(b.freeCells.count, 0)
        XCTAssertFalse(b.canMove(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top)))
        XCTAssertTrue(b.canMove(.columnToHome(columnIndex: 0, card: top))
                      || !b.canMoveToHome(top), "home move should be the only other option")
    }

    /// 빈 열 이동 경계: 빈 열 1개 → 수퍼무브 용량 2장(프리셀 0). Baker's는 1장만.
    func testBakersEmptyColumnCapacity() {
        var b = FreeCellGame(gameNumber: 1, variant: .bakersGame)
        let c7 = Card(suit: .spades, rank: .seven)
        let c8 = Card(suit: .spades, rank: .eight)
        b.columns[0] = []
        b.columns[1] = [c8, c7]
        b.columns[2] = []
        // 빈 열 2개, 목적지 빈 열 → 용량 2^(2-1)=2. Baker's는 1장 제한이라 2장 거부.
        XCTAssertFalse(b.canMove(.columnToColumn(from: 1, to: 0, cardCount: 2)))
        XCTAssertTrue(b.canMove(.columnToColumn(from: 1, to: 0, cardCount: 1)))
    }

    /// 더블클릭 홈 이동: bottom 카드(A)만 홈으로 가야 하고, 위 카드는 그대로 남아야 한다
    func testDoubleClickToHomeMovesOnlyBottomCard() {
        var game = FreeCellGame(gameNumber: 1)
        let ace = Card(suit: .spades, rank: .ace)
        let seven = Card(suit: .hearts, rank: .seven)
        game.columns[0] = [seven, ace] // bottom = ace
        game.columns[1] = []
        XCTAssertTrue(game.canMove(.columnToHome(columnIndex: 0, card: ace)))
        XCTAssertTrue(game.apply(.columnToHome(columnIndex: 0, card: ace)))
        XCTAssertEqual(game.columns[0], [seven])
        XCTAssertTrue(game.homes.contains { $0.contains(ace) })
    }

    /// 이동 후 열이 비는 경계: 열의 마지막 카드를 프리셀로 옮기면 열이 정상적으로 비워진다
    func testEmptyColumnAfterLastCardMoved() {
        var game = FreeCellGame(gameNumber: 1)
        let top0 = game.columns[0].last!
        game.columns[0] = [top0]
        XCTAssertEqual(game.columns[0].count, 1)
        game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 3, card: top0))
        XCTAssertTrue(game.columns[0].isEmpty)
        XCTAssertEqual(game.emptyFreeCellCount, 3)
    }

    /// 자동 저장(중간 복구): Card / FreeCellGame JSON round-trip
    func testCodableRoundTrip() throws {
        var game = FreeCellGame(gameNumber: 1)
        guard let top = game.columns[0].last else { return XCTFail("column should not be empty") }
        game.apply(.columnToFreeCell(columnIndex: 0, freeCellIndex: 0, card: top))

        let data = try JSONEncoder().encode(game)
        let restored = try JSONDecoder().decode(FreeCellGame.self, from: data)

        XCTAssertEqual(restored, game)
        XCTAssertEqual(restored.freeCells[0], top)
        XCTAssertEqual(restored.moveCount, 1)
        XCTAssertTrue(restored.canUndo)
        XCTAssertFalse(restored.canRedo)

        // undo까지도 복원되어 이어서 실행 취소 가능해야 한다
        var continuing = restored
        continuing.undo()
        XCTAssertNil(continuing.freeCells[0])
        XCTAssertEqual(continuing.columns[0].last, top)
    }
}
