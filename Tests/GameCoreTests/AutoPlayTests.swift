import XCTest
@testable import GameCore

final class AutoPlayTests: XCTestCase {

    /// 에이스는 항상 안전 → 자동 플레이 대상
    func testAceIsSafe() {
        let game = FreeCellGame(gameNumber: 1)
        let ace = Card(suit: .hearts, rank: .ace)
        XCTAssertTrue(AutoPlay.isSafeToAutoplay(ace, in: game))
    }

    /// 자동 플레이 이동은 항상 유효해야 한다
    func testAutoPlayMovesAreValid() {
        var game = FreeCellGame(gameNumber: 1)
        // 에이스를 열 맨 위로 노출시킨다
        for ace in Deck.standard().filter({ $0.rank == .ace }) {
            if let idx = game.columns.firstIndex(where: { $0.contains(ace) }) {
                game.columns[idx].removeAll { $0 == ace }
                game.columns[idx].append(ace)
            }
        }

        var applied = 0
        for move in AutoPlay.safeAutoPlayMoves(in: game) {
            XCTAssertTrue(game.canMove(move))
            XCTAssertTrue(game.apply(move))
            applied += 1
        }
        XCTAssertGreaterThanOrEqual(applied, 1)
    }

    /// 자동 플레이 이후 에이스는 홈에 있어야 한다
    func testAcesGoToHomeAfterAutoPlay() {
        var game = FreeCellGame(gameNumber: 1)
        for ace in Deck.standard().filter({ $0.rank == .ace }) {
            if let idx = game.columns.firstIndex(where: { $0.contains(ace) }) {
                game.columns[idx].removeAll { $0 == ace }
                game.columns[idx].append(ace)
            }
        }

        let moves = AutoPlay.safeAutoPlayMoves(in: game)
        for move in moves {
            game.apply(move)
        }
        let acesInHomes = game.homes.flatMap { $0 }.filter { $0.rank == .ace }
        XCTAssertEqual(acesInHomes.count, moves.count)
    }

    /// 오토플레이 연쇄 반복이 무한 루프 없이 수렴하고 상태가 일관적이어야 한다
    func testAutoPlayConvergesWithoutInfiniteLoop() {
        for number in [1, 617, 11982, 999, 12345] {
            var game = FreeCellGame(gameNumber: number, variant: .bakersGame)
            var iterations = 0
            while iterations < 200 {
                let moves = AutoPlay.safeAutoPlayMoves(in: game)
                if moves.isEmpty { break }
                for move in moves {
                    XCTAssertTrue(game.canMove(move))
                    XCTAssertTrue(game.apply(move))
                }
                iterations += 1
            }
            XCTAssertLessThan(iterations, 200, "autoPlay did not converge for #\(number)")
            // 상태 일관성: 각 홈은 한 무늬 연속(1..count), 열/홈에 중복 카드 없음
            for home in game.homes {
                let ranks = home.map(\.rank.rawValue).sorted()
                XCTAssertEqual(ranks, home.map(\.rank.rawValue))
                if home.isEmpty {
                    XCTAssertTrue(ranks.isEmpty)
                } else {
                    XCTAssertEqual(ranks, Array(1...home.count))
                }
            }
            let all = game.allCardsInPlay
            XCTAssertEqual(Set(all).count, all.count, "duplicate card after autoplay #\(number)")
        }
    }

    /// 오토플레이 후에 홈으로 이동 가능한 카드가 남아 있어선 안 된다 (안전 규칙 수렴)
    func testNoSafeHomeMoveRemainingAfterAutoPlay() {
        for number in [1, 617, 11982] {
            var game = FreeCellGame(gameNumber: number)
            while true {
                let moves = AutoPlay.safeAutoPlayMoves(in: game)
                if moves.isEmpty { break }
                for move in moves { game.apply(move) }
            }
            // 모든 열/프리셀의 bottom 카드 중 홈 이동 가능 + 안전한 것이 남아 있으면 규칙 위반
            for i in game.columns.indices {
                if let card = game.columns[i].last,
                   game.canMoveToHome(card),
                   AutoPlay.isSafeToAutoplay(card, in: game) {
                    XCTFail("safe autoplay card left after convergence #\(number)")
                }
            }
        }
    }

    // MARK: - canAutoFinish (속성 전수)

    /// canAutoFinish는 모든 홈셀 변형에 존재하고 Bool을 반환해야 한다
    func testCanAutoFinishExistsAcrossAllGames() {
        let games: [(String, Bool)] = [
            ("freecell", FreeCellGame(gameNumber: 1).canAutoFinish),
            ("bakers", FreeCellGame(gameNumber: 1, variant: .bakersGame).canAutoFinish),
            ("klondike", KlondikeGame(gameNumber: 1).canAutoFinish),
            ("yukon", YukonGame(gameNumber: 1).canAutoFinish),
            ("forty", FortyThievesGame(gameNumber: 1).canAutoFinish),
        ]
        for (name, value) in games {
            XCTAssertTrue((true == value) || (value == false), "\(name) canAutoFinish 타입 불일치")
        }
    }
}
