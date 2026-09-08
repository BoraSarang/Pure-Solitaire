import XCTest
@testable import GameCore

/// FreeCellSolver — 승리 가능 판정/첫 Winnable 번호 탐색 테스트
final class FreeCellSolverTests: XCTestCase {

    /// 테스트용 예산 — 기본 nodeLimit(400k)은 유지하되, timeLimit은 개발 환경(최적화 유무)에
    /// 민감하므로 넉넉히. "기본 노드 예산 내 판정"을 검증하는 것이 목적.
    private let testBudget = FreeCellSolver.Budget(nodeLimit: 400_000, timeLimit: 60.0, depthLimit: 20_000)

    /// MS FreeCell 정통 딜은 대부분 풀림 — 대표 샘플.
    /// (#10은 유효 해가 존재하지만 기본 예산 내 판정 불가 — 난이도 높음으로 분류되어 제외.
    ///  버그 수정 후 무효 이동이 사라져 #10이 134초가 필요한 것이 드러남. 재생 예산 밖.)
    func testWinnableStandardDeals() {
        let winnable = [1, 2, 4, 5, 20, 100, 1000, 5000, 10000]
        for n in winnable {
            let r = FreeCellSolver.isWinnable(gameNumber: n, variant: .freecell, budget: testBudget)
            XCTAssertTrue(r, "게임 #\(n)은 풀려야 함")
        }
    }

    /// 예산 초과(미확정)도 false로 반환하되, 해가 있는 #1/#2는 기본 nodeLimit 내 판정
    func testSolvableWithinBudget() {
        for n in [1, 2] {
            let r = FreeCellSolver.isWinnable(gameNumber: n, variant: .freecell, budget: testBudget)
            XCTAssertTrue(r, "게임 #\(n)은 기본 nodeLimit 내 풀려야 함")
        }
    }

    /// 예산 0이면 미확정(false)
    func testZeroBudgetIsUndetermined() {
        let budget = FreeCellSolver.Budget(nodeLimit: 0, timeLimit: 0, depthLimit: 0)
        let r = FreeCellSolver.isWinnable(gameNumber: 1, variant: .freecell, budget: budget)
        XCTAssertFalse(r)
    }

    /// 미지원 변형은 false
    func testUnsupportedVariant() {
        let r = FreeCellSolver.isWinnable(gameNumber: 1, variant: .klondike)
        XCTAssertFalse(r)
        XCTAssertFalse(FreeCellSolver.isFreeCellFamily(.klondike))
        XCTAssertTrue(FreeCellSolver.isFreeCellFamily(.freecell))
        XCTAssertTrue(FreeCellSolver.isFreeCellFamily(.bakersGame))
        XCTAssertTrue(FreeCellSolver.isFreeCellFamily(.seaTower))
        XCTAssertTrue(FreeCellSolver.isFreeCellFamily(.superFreeCell))
    }

    /// firstWinnableGameNumber — 반환된 번호는 실제로 풀리는 번호여야 함
    func testFirstWinnableGameNumber() {
        let budget = FreeCellSolver.Budget(nodeLimit: 200_000, timeLimit: 2.0, depthLimit: 20_000)
        guard let n = FreeCellSolver.firstWinnableGameNumber(from: 1, variant: .freecell, budget: budget, maxAttempts: 10) else {
            XCTFail("첫 Winnable 번호를 찾지 못함")
            return
        }
        XCTAssertTrue(FreeCellSolver.isWinnable(gameNumber: n, variant: .freecell, budget: budget))
    }

    // MARK: - solve() 풀이 시퀀스

    /// solve()가 반환한 이동을 순서대로 실제 게임에 적용하면 승리 상태에 도달해야 함
    /// (#10은 기본 예산 내 판정 불가 난이도 높음 게임 — 제외)
    func testSolveAppliesToWinningState() {
        for n in [1, 2, 100] {
            guard let solution = FreeCellSolver.solve(gameNumber: n, variant: .freecell, budget: testBudget) else {
                XCTFail("게임 #\(n)은 풀려야 함")
                return
            }
            var game = FreeCellGame(gameNumber: n, variant: .freecell)
            var applied = 0
            for move in solution.moves {
                if game.apply(move) { applied += 1 }
            }
            XCTAssertTrue(game.isWon, "게임 #\(n)은 풀이 적용 후 승리 상태여야 함 (적용 \(applied)/\(solution.moves.count))")
        }
    }

    /// solve() 결과의 각 이동은 해당 상태에서 유효해야 함 (canMove 성립)
    func testSolveMovesAreValid() {
        guard let solution = FreeCellSolver.solve(gameNumber: 1, variant: .freecell, budget: testBudget) else {
            XCTFail("게임 #1은 풀려야 함")
            return
        }
        var game = FreeCellGame(gameNumber: 1, variant: .freecell)
        var validCount = 0
        for move in solution.moves {
            if game.canMove(move), game.apply(move) { validCount += 1 }
        }
        XCTAssertTrue(game.isWon, "모든 이동이 유효해 승리 도달해야 함 (유효 \(validCount)/\(solution.moves.count))")
    }

    /// 불가능한 게임(#11982 — MS FreeCell 32000딜 중 유일한 미해결. 20M/240s에서도 미해결 확인됨)은 nil.
    /// (이전의 #500은 버그 수정 후 풀리는 게임으로 드러나 교체 — 솔버가 강력해짐)
    func testSolveUnwinnableReturnsNil() {
        let budget = FreeCellSolver.Budget(nodeLimit: 500_000, timeLimit: 5.0, depthLimit: 20_000)
        XCTAssertNil(FreeCellSolver.solve(gameNumber: 11982, variant: .freecell, budget: budget))
    }

    /// 예산 0이면 nil
    func testSolveZeroBudgetIsNil() {
        let budget = FreeCellSolver.Budget(nodeLimit: 0, timeLimit: 0, depthLimit: 0)
        XCTAssertNil(FreeCellSolver.solve(gameNumber: 1, variant: .freecell, budget: budget))
    }

    /// 미지원 변형은 nil
    func testSolveUnsupportedVariantIsNil() {
        XCTAssertNil(FreeCellSolver.solve(gameNumber: 1, variant: .klondike))
    }

    /// 취소 플래그 설정 시 즉시 nil 반환 (T-241: 중단해도 예산 만료까지 도는 문제 수정)
    func testSolveRespectsCancellation() {
        var budget = FreeCellSolver.Budget(
            nodeLimit: 10_000_000,
            timeLimit: 60,
            depthLimit: 60_000,
            isCancelled: { true }
        )
        XCTAssertNil(FreeCellSolver.solve(gameNumber: 1, variant: .freecell, budget: budget))
    }

    /// 취소 없음(기본 예산)은 기존 동작 유지
    func testSolveWithoutCancellationUnchanged() {
        let budget = FreeCellSolver.Budget(isCancelled: { false })
        XCTAssertNotNil(FreeCellSolver.solve(gameNumber: 1, variant: .freecell, budget: budget))
    }

    /// 취소 시 firstWinnable 즉시 nil (T-239: 탐색 중 취소 전파)
    func testFirstWinnableCancelledReturnsNil() {
        var budget = FreeCellSolver.Budget(
            nodeLimit: 10_000_000,
            timeLimit: 60,
            depthLimit: 60_000,
            isCancelled: { true }
        )
        XCTAssertNil(FreeCellSolver.firstWinnableGameNumber(
            from: 1, variant: .freecell, budget: budget, maxAttempts: 50
        ))
    }

    /// 정상 탐색은 첫 번호 그대로 (#1은 풀림)
    func testFirstWinnableFindsFirst() {
        XCTAssertEqual(
            FreeCellSolver.firstWinnableGameNumber(from: 1, variant: .freecell),
            1
        )
    }

    /// replayBudget도 동일하게 유효한 풀이를 생성해야 함
    /// #50은 로컬 16.6s 소요로 CI에서 시간 예산에 민감 — 빠른 #2로 교체(결정적).
    func testSolveWithReplayBudget() {
        guard let solution = FreeCellSolver.solve(gameNumber: 2, variant: .freecell, budget: FreeCellSolver.replayBudget) else {
            XCTFail("게임 #2는 replayBudget으로 풀려야 함")
            return
        }
        var game = FreeCellGame(gameNumber: 2, variant: .freecell)
        var applied = 0
        for move in solution.moves {
            if game.apply(move) { applied += 1 }
        }
        XCTAssertTrue(game.isWon, "게임 #2 풀이가 승리 상태에 도달해야 함 (적용 \(applied)/\(solution.moves.count))")
    }
}
