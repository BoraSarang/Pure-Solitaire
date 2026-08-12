import XCTest
@testable import GameCore

final class ScorpionGameTests: XCTestCase {

    /// 딜 검증: 7열×7장 + 예비 3장 = 52장, 앞 4열은 밑 3장 뒤집힘, 뒤 3열 전부 앞면
    func testDealLayout() {
        let game = ScorpionGame(gameNumber: 1)
        XCTAssertEqual(game.columns.count, 7)
        for col in game.columns {
            XCTAssertEqual(col.count, 7)
        }
        for col in 0..<4 {
            XCTAssertFalse(game.columns[col][0].faceUp)
            XCTAssertFalse(game.columns[col][1].faceUp)
            XCTAssertFalse(game.columns[col][2].faceUp)
            XCTAssertTrue(game.columns[col][3].faceUp)
            XCTAssertTrue(game.columns[col][4].faceUp)
            XCTAssertTrue(game.columns[col][5].faceUp)
            XCTAssertTrue(game.columns[col][6].faceUp)
        }
        for col in 4..<7 {
            for cc in game.columns[col] {
                XCTAssertTrue(cc.faceUp)
            }
        }
        XCTAssertEqual(game.reserve.count, 3)
        let total = game.columns.reduce(0) { $0 + $1.count } + game.reserve.count
        XCTAssertEqual(total, 52)
        XCTAssertFalse(game.reserveDealt)
    }

    /// 같은 수트 + 한 단계 낮은 카드만 놓을 수 있음
    func testPlacementRules() {
        var game = ScorpionGame(gameNumber: 1)
        // 열 맨 위 카드보다 한 단계 낮은 같은 수트
        let top0 = game.columns[0].last!.card
        if let lowerRank = top0.rank.previous {
            let lower = Card(suit: top0.suit, rank: lowerRank)
            XCTAssertTrue(game.canPlaceOnColumn(lower, column: 0))
            // 다른 수트 거부
            let otherSuit = Suit.allCases.first { $0 != top0.suit }!
            XCTAssertFalse(game.canPlaceOnColumn(Card(suit: otherSuit, rank: lowerRank), column: 0))
            // 랭크 차이 2 거부
            if let twoBelow = lowerRank.previous {
                XCTAssertFalse(game.canPlaceOnColumn(Card(suit: top0.suit, rank: twoBelow), column: 0))
            }
        }
        // 빈 열엔 K만
        game.columns[0] = []
        XCTAssertTrue(game.canPlaceOnColumn(Card(suit: .hearts, rank: .king), column: 0))
        XCTAssertFalse(game.canPlaceOnColumn(Card(suit: .hearts, rank: .queen), column: 0))
    }

    /// 그룹 이동: 앞면 카드와 그 위 전부 이동 (순서 무관), 노출된 뒤집힌 카드 자동 앞면
    func testGroupMove() {
        var game = ScorpionGame(gameNumber: 1)
        // 열 0의 앞면 4장(인덱스 3~6)을 그룹 이동
        let top0 = game.columns[0].last!.card
        let group = game.columns[0].suffix(4).map(\.card)
        // 이동 가능 여부: 목적 열(열 1) 맨 위보다 같은 수트 한 단계 낮으면 가능
        let top1 = game.columns[1].last!.card
        let canMove = top1.suit == group[0].suit && group[0].rank == top1.rank.previous
        if canMove {
            XCTAssertTrue(game.apply(.columnToColumn(from: 0, to: 1, cardCount: 4)))
            XCTAssertEqual(game.columns[1].count, 11)
            XCTAssertEqual(game.columns[0].count, 3)
            // 노출된 뒤집힌 카드가 자동 앞면
            XCTAssertTrue(game.columns[0].last!.faceUp)
            XCTAssertEqual(game.moveCount, 1)
        }
    }

    /// 예비 딜: 1회만, 열 0,1,2에 앞면 1장씩
    func testDealReserveOnce() {
        var game = ScorpionGame(gameNumber: 1)
        XCTAssertTrue(game.canMove(.dealReserve))
        XCTAssertTrue(game.apply(.dealReserve))
        XCTAssertTrue(game.reserveDealt)
        XCTAssertTrue(game.reserve.isEmpty)
        XCTAssertEqual(game.columns[0].count, 8)
        XCTAssertEqual(game.columns[1].count, 8)
        XCTAssertEqual(game.columns[2].count, 8)
        XCTAssertTrue(game.columns[0].last!.faceUp)
        // 2회째 거부
        XCTAssertFalse(game.canMove(.dealReserve))
        XCTAssertFalse(game.apply(.dealReserve))
    }

    /// 승리 판정: 열 4개가 완성 시퀀스면 true
    func testWinDetection() {
        let suits = Suit.allCases
        var columns: [[KlondikeGame.ColumnCard]] = []
        for suit in suits {
            var pile: [KlondikeGame.ColumnCard] = []
            var rank = Rank.king
            for _ in 0..<13 {
                pile.append(KlondikeGame.ColumnCard(card: Card(suit: suit, rank: rank), faceUp: true))
                rank = rank.previous ?? .ace
            }
            columns.append(pile)
        }
        // 4개 완성 + 3개 빈 열
        columns.append([])
        columns.append([])
        columns.append([])
        var game = ScorpionGame(gameNumber: 1)
        game.columns = columns
        game.reserve = []
        XCTAssertEqual(game.completedSequencesCount, 4)
        XCTAssertTrue(game.isWon)
    }

    /// 완성 시퀀스가 3개면 승리 아님
    func testNotWonWithThreeSequences() {
        let suits = Suit.allCases.prefix(3)
        var columns: [[KlondikeGame.ColumnCard]] = []
        for suit in suits {
            var pile: [KlondikeGame.ColumnCard] = []
            var rank = Rank.king
            for _ in 0..<13 {
                pile.append(KlondikeGame.ColumnCard(card: Card(suit: suit, rank: rank), faceUp: true))
                rank = rank.previous ?? .ace
            }
            columns.append(pile)
        }
        columns.append([])
        columns.append([])
        columns.append([])
        columns.append([])
        var game = ScorpionGame(gameNumber: 1)
        game.columns = columns
        game.reserve = []
        XCTAssertEqual(game.completedSequencesCount, 3)
        XCTAssertFalse(game.isWon)
    }

    /// undo/redo가 상태를 복원
    func testUndoRedo() {
        var game = ScorpionGame(gameNumber: 1)
        let before = game.columns
        XCTAssertTrue(game.apply(.dealReserve))
        XCTAssertTrue(game.canUndo)
        game.undo()
        XCTAssertEqual(game.columns, before)
        XCTAssertFalse(game.reserveDealt)
        game.redo()
        XCTAssertTrue(game.reserveDealt)
    }

    /// canAutoFinish는 항상 false (홈셀 없음)
    func testCanAutoFinishFalse() {
        let game = ScorpionGame(gameNumber: 1)
        XCTAssertFalse(game.canAutoFinish)
    }

    /// 힌트 후보가 존재 (초기 상태)
    func testHintCandidates() {
        let game = ScorpionGame(gameNumber: 1)
        XCTAssertFalse(game.hintCandidates().isEmpty)
    }
}
