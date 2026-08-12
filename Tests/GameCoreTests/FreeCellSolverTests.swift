import XCTest
@testable import GameCore

/// FreeCellSolver — 승리 가능 판정/첫 Winnable 번호 탐색 테스트
final class FreeCellSolverTests: XCTestCase {

    /// MS FreeCell 정통 딜은 대부분 풀림 — 대표 샘플
    /// (기본 예산 내 빠르게 판정되는 번호만 — #1 등 일부는 시간 예산 초과로 미확정)
    func testWinnableStandardDeals() {
        let winnable = [4, 5, 10, 20, 100, 1000, 5000, 10000]
        for n in winnable {
            let r = FreeCellSolver.isWinnable(gameNumber: n, variant: .freecell)
            XCTAssertTrue(r, "게임 #\(n)은 풀려야 함")
        }
    }

    /// 예산 초과(미확정)도 false로 반환하되, 해가 있는 #2는 기본 예산 내 판정
    func testSolvableWithinBudget() {
        let budget = FreeCellSolver.Budget(nodeLimit: 400_000, timeLimit: 4.0, depthLimit: 20_000)
        let r = FreeCellSolver.isWinnable(gameNumber: 2, variant: .freecell, budget: budget)
        XCTAssertTrue(r)
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
}
