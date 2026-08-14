import XCTest
@testable import GameCore

/// Difficulty — solve() 소요 노드 수 기반 난이도 판정 테스트
final class DifficultyTests: XCTestCase {

    private let testBudget = FreeCellSolver.Budget(nodeLimit: 400_000, timeLimit: 60.0, depthLimit: 20_000)

    /// 노드 수 경계값: < 20k 쉬움, < 150k 보통, 그 외 어려움
    func testNodeCountThresholds() {
        XCTAssertEqual(Difficulty.for(nodeCount: 0), .easy)
        XCTAssertEqual(Difficulty.for(nodeCount: 19_999), .easy)
        XCTAssertEqual(Difficulty.for(nodeCount: 20_000), .medium)
        XCTAssertEqual(Difficulty.for(nodeCount: 149_999), .medium)
        XCTAssertEqual(Difficulty.for(nodeCount: 150_000), .hard)
        XCTAssertEqual(Difficulty.for(nodeCount: 10_000_000), .hard)
    }

    /// SolveResult 기반 판정 — 미해결은 unmeasured (nil 처리 별도)
    func testDifficultyFromResult() {
        let result = SolveResult(moves: [Move.columnToHome(columnIndex: 0, card: .init(suit: .spades, rank: .ace))], nodeCount: 500, depth: 1)
        XCTAssertEqual(Difficulty.for(result: result), .easy)
    }

    /// 실제 딜의 소요 노드 수가 판정에 반영됨 — #1/#2는 쉬움~보통 범위 내
    func testRealDealDifficultyMeasurable() {
        for n in [1, 2, 100] {
            guard let solution = FreeCellSolver.solve(gameNumber: n, variant: .freecell, budget: testBudget) else {
                XCTFail("게임 #\(n)은 풀려야 함")
                return
            }
            let difficulty = Difficulty.for(result: solution)
            XCTAssertTrue(solution.nodeCount > 0, "게임 #\(n)은 노드 소요가 측정되어야 함")
            XCTAssertTrue(solution.depth > 0, "게임 #\(n)은 깊이 소요가 측정되어야 함")
            XCTAssertNotEqual(difficulty, .unmeasured, "게임 #\(n)은 해결됐으므로 미측정이면 안 됨")
        }
    }

    /// 미해결(예산 초과) 시 solve가 nil → unmeasured로 표현 (호출부 판단)
    func testUnresolvedIsUnmeasured() {
        XCTAssertNil(FreeCellSolver.solve(gameNumber: 11982, variant: .freecell, budget: testBudget))
        // solve() == nil 이면 Difficulty.unmeasured 로 표시한다 (C 난이도 태그 UI 규칙)
        XCTAssertEqual(Difficulty.unmeasured.rawValue, "unmeasured")
    }

    // MARK: - measure (T-219)

    /// measure — 쉬운 판은 예산 내 해 발견되어 unmeasured가 아님
    func testMeasureEasyDeal() {
        let d = Difficulty.measure(gameNumber: 1, variant: .freecell)
        XCTAssertNotEqual(d, .unmeasured, "#1은 measure 예산으로 풀려야 함")
    }

    /// measure — FreeCell 계열이 아닌 변형은 unmeasured (미지원)
    func testMeasureUnsupportedVariant() {
        XCTAssertEqual(Difficulty.measure(gameNumber: 1, variant: .klondike), .unmeasured)
        XCTAssertEqual(Difficulty.measure(gameNumber: 1, variant: .spider), .unmeasured)
    }
}