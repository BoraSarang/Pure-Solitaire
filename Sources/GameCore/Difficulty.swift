import Foundation

/// solve() 결과 — 풀이 이동 시퀀스 + 탐색 소요(노드 수/깊이). 난이도 판정 입력.
public struct SolveResult: Sendable {
    public let moves: [Move]
    public let nodeCount: Int
    public let depth: Int

    public init(moves: [Move], nodeCount: Int, depth: Int) {
        self.moves = moves
        self.nodeCount = nodeCount
        self.depth = depth
    }
}

/// 결정적 난이도 — solve()의 소요 노드 수 기반.
/// 노드 < 20k: 쉬움, < 150k: 보통, 그 외: 어려움. (PLAN_v3.21 결정 사항)
public enum Difficulty: String, CaseIterable, Sendable {
    case easy
    case medium
    case hard
    /// 미해결(예산 초과) — 난이도 미측정
    case unmeasured

    public static func `for`(nodeCount: Int) -> Difficulty {
        if nodeCount < 20_000 { return .easy }
        if nodeCount < 150_000 { return .medium }
        return .hard
    }

    public static func `for`(result: SolveResult) -> Difficulty {
        `for`(nodeCount: result.nodeCount)
    }

    /// 난이도 측정용 예산 — 9판 순차 측정 시 판당 시간을 제한. 표준 판정보다 넉넉하되 재생 예산보다 작게.
    public static let measureBudget = FreeCellSolver.Budget(
        nodeLimit: 400_000,
        timeLimit: 8.0,
        depthLimit: 20_000
    )

    /// 게임 번호 기준 난이도 측정 — FreeCell 계열만 실제 풀이, 그 외/미해결(예산 초과)은 unmeasured.
    /// 자동 풀어 보기와 달리 사용자 명시 실행이 아니므로 measureBudget 사용.
    public static func measure(gameNumber: Int, variant: GameVariant) -> Difficulty {
        guard FreeCellSolver.isFreeCellFamily(variant) else { return .unmeasured }
        guard let result = FreeCellSolver.solve(gameNumber: gameNumber, variant: variant, budget: measureBudget) else {
            return .unmeasured
        }
        return `for`(result: result)
    }
}