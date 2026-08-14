import Foundation

/// FreeCell 계열 딜의 승리 가능 여부를 판정하는 솔버
///
/// 전략: 매 상태에서 **안전한 홈 이동(AutoPlay 규칙)을 자동 적용**해 상태를 압축한 뒤,
/// 남은 상태에 대해 반복 DFS + 휴리스틱 이동 순서 + 방문 상태 집합으로 탐색한다.
/// (재귀 대신 명시적 스택 사용 — 깊은 탐색 시 스택 오버플로우 방지)
/// 노드 예산/시간 예산/깊이 예산을 초과하면 "미확정"으로 취급한다.
///
/// 범위: FreeCell 계열 4종(freecell, bakersGame, seaTower, superFreeCell) 전용.
/// 그 외 변형은 미지원(false/입력값 그대로 반환).
public enum FreeCellSolver {

    /// 탐색 예산 — 노드 수 / 소요 시간 / 깊이를 모두 만족해야 계속 탐색
    public struct Budget: Sendable {
        public var nodeLimit: Int
        public var timeLimit: TimeInterval
        public var depthLimit: Int

        public init(nodeLimit: Int = 400_000, timeLimit: TimeInterval = 4.0, depthLimit: Int = 20_000) {
            self.nodeLimit = nodeLimit
            self.timeLimit = timeLimit
            self.depthLimit = depthLimit
        }

        public static let standard = Budget()
    }

    /// FreeCell 계열 여부
    public static func isFreeCellFamily(_ variant: GameVariant) -> Bool {
        switch variant {
        case .freecell, .bakersGame, .seaTower, .superFreeCell: true
        default: false
        }
    }

    /// 주어진 게임 번호의 딜이 풀리는지 여부 (미지원 변형은 false)
    public static func isWinnable(gameNumber: Int, variant: GameVariant, budget: Budget = .standard) -> Bool {
        solve(gameNumber: gameNumber, variant: variant, budget: budget) != nil
    }

    /// 풀이 이동 시퀀스 + 탐색 소요 — DFS가 찾은 성공 경로를 처음부터 끝까지 순서대로 반환.
    /// 미지원 변형/미해결/예산 초과는 nil. (자동 풀어 보기/리플레이/난이도 판정용)
    public static func solve(
        gameNumber: Int,
        variant: GameVariant,
        budget: Budget = .standard
    ) -> SolveResult? {
        guard isFreeCellFamily(variant) else { return nil }
        let game = FreeCellGame(gameNumber: gameNumber, variant: variant)
        return solve(state: SolverState(from: game), variant: variant, budget: budget)
    }

    /// 자동 풀어 보기 재생용 예산 — 사용자 명시 실행이므로 판정 예산보다 크게.
    /// timeLimit 20s: 실측 #50 유효 해가 16.6초 소요되어 15초에서 조정(PLAN v3.21 기록).
    /// 30s: CI 러너는 로컬보다 느려 20s에서 #50이 시간 초과로 실패하는 문제 → 여유 확보 (2026-08-14).
    public static let replayBudget = Budget(
        nodeLimit: 2_000_000,
        timeLimit: 30.0,
        depthLimit: 60_000
    )

    /// 시작 번호부터 위로(최대 maxAttempts개) 풀리는 번호를 찾는다. 못 찾으면 nil.
    /// 첫 번호가 풀리면 그대로 반환(대부분 즉시 종료). 미지원 변형은 시작 번호 그대로 반환.
    public static func firstWinnableGameNumber(
        from startNumber: Int,
        variant: GameVariant,
        budget: Budget = .standard,
        maxAttempts: Int = 200
    ) -> Int? {
        guard isFreeCellFamily(variant) else { return startNumber }
        let deadline = Date().addingTimeInterval(budget.timeLimit * Double(maxAttempts))
        for n in startNumber...(startNumber + maxAttempts - 1) {
            let safe = min(max(n, DealGenerator.minGameNumber), DealGenerator.maxGameNumber)
            if Date() > deadline { return nil }
            if isWinnable(gameNumber: safe, variant: variant, budget: budget) {
                return safe
            }
        }
        return nil
    }

    // MARK: - 솔버 내부

    /// 솔버 전용 가변 상태 (undo 스택 없는 경량 표현)
    struct SolverState: Hashable {
        var columns: [[Card]]
        var freeCells: [Card?]
        var homes: [[Card]]

        init(from game: FreeCellGame) {
            columns = game.columns
            freeCells = game.freeCells
            homes = game.homes
        }

        var allCardsInPlay: [Card] {
            columns.flatMap { $0 } + freeCells.compactMap { $0 }
        }

        func isHomeCard(_ card: Card) -> Bool {
            homes.contains { $0.contains(card) }
        }
    }

    /// 반복 DFS 스택 프레임 — 상태와 다음 시도할 이동 인덱스.
    /// appliedMove는 이 상태에 도달하기 위해 부모에서 적용한 이동(루트는 nil),
    /// homeMoves는 이 상태로 정규화되며 자동 적용된 안전 홈 이동들.
    /// homeCount는 이 상태 진입 시 홈 카드 수, stagnantDepth는 홈 카드가 마지막으로
    /// 증가한 이후 진행된 이동 수 — 진행 없는 긴 경로 가지치기용.
    private struct Frame {
        var state: SolverState
        var moves: [Move]
        var nextIndex: Int
        var appliedMove: Move?
        var homeMoves: [Move]
        var homeCount: Int
        var stagnantDepth: Int
    }

    /// 홈 카드가 이 횟수 이상 증가 없이 이동만 반복하면 그 경로는 포기(가지치기).
    /// 실제 FreeCell 해법은 대부분 100~200 이동 내에 홈 카드가 꾸준히 늘므로,
    /// 정체가 긴 경로는 승리와 무관한 순환/배회로 간주해 백트래킹한다.
    private static let maxStagnantDepth = 80

    static func homeCount(_ s: SolverState) -> Int {
        s.homes.reduce(0) { $0 + $1.count }
    }

    /// 풀이 이동 시퀀스를 수집하는 반복 DFS.
    /// 성공 시 처음→끝 순서의 유효한 이동 시퀀스와 소요(노드/깊이)를 반환하고, 실패/예산 초과 시 nil.
    static func solve(state: SolverState, variant: GameVariant, budget: Budget) -> SolveResult? {
        let start = Date()

        // 단일 DFS 호출 — 깊이 제한은 budget.depthLimit 전체. (IDDFS는 FreeCell 상태 공간이
        // 커서 각 깊이 단계가 처음부터 재탐색해야 해서 시간 예산을 소진해 실패 — 단일 DFS로 회귀)
        var nodes = 0
        guard let (path, depth) = dfs(
            depthLimit: budget.depthLimit,
            start: start,
            nodes: &nodes,
            budget: budget,
            state: state,
            variant: variant
        ) else { return nil }
        return SolveResult(moves: path, nodeCount: nodes, depth: depth)
    }

    /// 단일 깊이 제한 반복 DFS (명시적 스택) — 승리 경로를 처음→끝 순서로 반환. 실패/예산 초과 nil.
    /// visited는 이 호출 전용(깊이 단계별로 새로 구성). nodes는 전체 단계에서 공유해 누적된다.
    private static func dfs(
        depthLimit: Int,
        start: Date,
        nodes: inout Int,
        budget: Budget,
        state: SolverState,
        variant: GameVariant
    ) -> (path: [Move], depth: Int)? {
        var visited: Set<SolverState> = []
        var stack: [Frame] = []

        func isWon(_ s: SolverState) -> Bool {
            switch variant {
            case .superFreeCell: return s.homes.allSatisfy { $0.count == 26 }
            default: return s.homes.allSatisfy { $0.count == 13 }
            }
        }

        func homeIndex(for card: Card, in s: SolverState) -> Int? {
            if variant == .superFreeCell {
                return card.suit.rawValue
            }
            if card.rank == .ace, let i = s.homes.firstIndex(where: { $0.isEmpty }) {
                return i
            }
            return s.homes.firstIndex { $0.last?.suit == card.suit }
        }

        func canMoveToHome(_ card: Card, in s: SolverState) -> Bool {
            if variant == .superFreeCell {
                let idx = card.suit.rawValue
                guard s.homes.indices.contains(idx) else { return false }
                guard let top = s.homes[idx].last else { return card.rank == .ace }
                if top.rank == .king { return card.rank == .ace }
                return top.suit == card.suit && top.rank.next == card.rank
            }
            if card.rank == .ace {
                return s.homes.contains { $0.isEmpty }
            }
            return s.homes.contains {
                guard let top = $0.last else { return false }
                return top.suit == card.suit && top.rank.next == card.rank
            }
        }

        func isSafeToAutoplay(_ card: Card, in s: SolverState) -> Bool {
            if card.rank == .ace { return true }
            guard let lowerRank = card.rank.previous else { return true }
            let blockers = s.allCardsInPlay.filter {
                $0.rank == lowerRank && $0.color == card.color.opposite
            }
            return blockers.allSatisfy { s.isHomeCard($0) }
        }

        func normalize(_ s: SolverState) -> (state: SolverState, homeMoves: [Move]) {
            var cur = s
            var homeMoves: [Move] = []
            var progressed = true
            while progressed {
                progressed = false
                for i in cur.columns.indices {
                    guard let card = cur.columns[i].last else { continue }
                    if canMoveToHome(card, in: cur), isSafeToAutoplay(card, in: cur) {
                        cur.columns[i].removeLast()
                        cur.homes[homeIndex(for: card, in: cur)!].append(card)
                        homeMoves.append(.columnToHome(columnIndex: i, card: card))
                        progressed = true
                        break
                    }
                }
                if progressed { continue }
                for i in cur.freeCells.indices {
                    guard let card = cur.freeCells[i] else { continue }
                    if canMoveToHome(card, in: cur), isSafeToAutoplay(card, in: cur) {
                        cur.freeCells[i] = nil
                        cur.homes[homeIndex(for: card, in: cur)!].append(card)
                        homeMoves.append(.freeCellToHome(freeCellIndex: i, card: card))
                        progressed = true
                        break
                    }
                }
            }
            return (cur, homeMoves)
        }

        func generalMoves(_ s: SolverState) -> [Move] {
            var moves: [Move] = []

            // 열 → 홈 (안전하지 않은 홈 이동 — 안전한 것은 normalize에서 처리)
            for i in s.columns.indices {
                guard let card = s.columns[i].last else { continue }
                if canMoveToHome(card, in: s), !isSafeToAutoplay(card, in: s) {
                    moves.append(.columnToHome(columnIndex: i, card: card))
                }
            }
            // 프리셀 → 열 (비우기 우선)
            for fc in s.freeCells.indices {
                guard let card = s.freeCells[fc] else { continue }
                for col in s.columns.indices where FreeCellRule.canMoveToColumn(card, topCard: s.columns[col].last, variant: variant) {
                    moves.append(.freeCellToColumn(freeCellIndex: fc, columnIndex: col, card: card))
                }
            }
            // 열 → 열 (수퍼무브 포함 — movableRun의 각 크기)
            let emptyColumnCount = s.columns.filter { $0.isEmpty }.count
            for from in s.columns.indices {
                let run = FreeCellRule.movableRun(from: s.columns[from], variant: variant)
                guard !run.isEmpty else { continue }
                let runTop = run.last!       // 이동 그룹의 top 카드 (단일 이동 시 실제 이동 카드)
                for to in s.columns.indices where to != from {
                    let destTop = s.columns[to].last
                    // 수퍼무브 용량 내 그룹 크기만 생성
                    // (supermoveCapacity가 destinationIsEmpty를 내부 처리 — 호출부에서 빼면 안 됨)
                    let destIsEmpty = s.columns[to].isEmpty
                    let capacity = FreeCellRule.supermoveCapacity(
                        emptyFreeCells: s.freeCells.filter { $0 == nil }.count,
                        emptyColumns: emptyColumnCount,
                        destinationIsEmpty: destIsEmpty
                    )
                    let maxCount = min(run.count, capacity)
                    if maxCount >= 1 {
                        // 단일 이동(1장)은 top 카드가 실제 이동 카드 → top 기준 검사
                        if FreeCellRule.canMoveToColumn(runTop, topCard: destTop, variant: variant) {
                            moves.append(.columnToColumn(from: from, to: to, cardCount: 1))
                        }
                        // 그룹 이동: 이동 그룹의 bottom 카드(run[run.count-count])가 목적지에 놓일 수
                        // 있는 크기 중 최대만 생성. maxCount로는 목적지에 못 놓이면
                        // 더 작은 그룹(2 이상)이 유효할 수 있다 — 큰 것부터 탐색.
                        if maxCount > 1 {
                            var groupCount: Int? = nil
                            for count in stride(from: maxCount, through: 2, by: -1) {
                                let groupBottom = run[run.count - count]
                                if FreeCellRule.canMoveToColumn(groupBottom, topCard: destTop, variant: variant) {
                                    groupCount = count
                                    break
                                }
                            }
                            if let groupCount {
                                moves.append(.columnToColumn(from: from, to: to, cardCount: groupCount))
                            }
                        }
                    }
                }
            }
            // 열 → 프리셀
            for col in s.columns.indices {
                guard let card = s.columns[col].last else { continue }
                for fc in s.freeCells.indices where s.freeCells[fc] == nil {
                    moves.append(.columnToFreeCell(columnIndex: col, freeCellIndex: fc, card: card))
                }
            }
            // 홈에서 꺼내기 (드물게 필요, 최하위)
            for h in s.homes.indices {
                guard let card = s.homes[h].last else { continue }
                for col in s.columns.indices where FreeCellRule.canMoveToColumn(card, topCard: s.columns[col].last, variant: variant) {
                    moves.append(.homeToColumn(homeIndex: h, columnIndex: col, card: card))
                }
                for fc in s.freeCells.indices where s.freeCells[fc] == nil {
                    moves.append(.homeToFreeCell(homeIndex: h, freeCellIndex: fc, card: card))
                }
            }
            return moves.sorted { priority($0, in: s) < priority($1, in: s) }
        }

        func priority(_ move: Move, in s: SolverState) -> Int {
            switch move {
            case .columnToHome: return 0
            case .freeCellToColumn: return 10
            case let .columnToColumn(from, to, cardCount):
                let empty = s.columns[to].isEmpty
                if empty {
                    if variant == .seaTower { return 50 }
                    return s.columns[from].last?.rank == .king ? 20 : 60
                }
                // 이동으로 새 카드가 드러나고 그 카드가 홈으로 갈 수 있으면 우선
                // (빈 열이 있을 때만 — 빈 열이 없으면 빈 열 만들기 우선)
                let emptyCols = s.columns.filter { $0.isEmpty }.count
                if emptyCols > 0, cardCount < s.columns[from].count {
                    let revealed = s.columns[from][s.columns[from].count - cardCount - 1]
                    if canMoveToHome(revealed, in: s) { return 30 + revealed.rank.rawValue }
                }
                if cardCount >= 2 { return 50 }
                return emptyCols > 0 ? 70 : 90
            case .columnToFreeCell: return 80
            case .homeToColumn, .homeToFreeCell: return 99
            default: return 80
            }
        }

        func apply(_ move: Move, to s: inout SolverState) {
            switch move {
            case let .columnToColumn(from, to, cardCount):
                let moving = Array(s.columns[from].suffix(cardCount))
                s.columns[from].removeLast(cardCount)
                s.columns[to].append(contentsOf: moving)
            case let .columnToFreeCell(columnIndex, freeCellIndex, card):
                s.columns[columnIndex].removeLast()
                s.freeCells[freeCellIndex] = card
            case let .freeCellToColumn(freeCellIndex, columnIndex, card):
                s.freeCells[freeCellIndex] = nil
                s.columns[columnIndex].append(card)
            case let .columnToHome(columnIndex, card):
                s.columns[columnIndex].removeLast()
                s.homes[homeIndex(for: card, in: s)!].append(card)
            case let .freeCellToHome(freeCellIndex, card):
                s.freeCells[freeCellIndex] = nil
                s.homes[homeIndex(for: card, in: s)!].append(card)
            case let .homeToColumn(homeIndex, columnIndex, card):
                s.homes[homeIndex].removeLast()
                s.columns[columnIndex].append(card)
            case let .homeToFreeCell(homeIndex, freeCellIndex, card):
                s.homes[homeIndex].removeLast()
                s.freeCells[freeCellIndex] = card
            default:
                break
            }
        }

        let initial = normalize(state)
        let current = initial.state
        visited.insert(current)
        nodes += 1
        if isWon(current) { return (initial.homeMoves, 1) }
        stack.append(Frame(state: current, moves: generalMoves(current), nextIndex: 0, appliedMove: nil, homeMoves: initial.homeMoves, homeCount: Self.homeCount(current), stagnantDepth: 0))

        while !stack.isEmpty {
            if nodes > budget.nodeLimit { return nil }
            if Date().timeIntervalSince(start) > budget.timeLimit { return nil }

            let frame = stack[stack.count - 1]
            if frame.nextIndex >= frame.moves.count {
                stack.removeLast()
                continue
            }
            let move = frame.moves[frame.nextIndex]
            stack[stack.count - 1].nextIndex += 1

            // 깊이 제한 — 이 경로만 중단하고 백트래킹 (형제 이동 계속 탐색)
            if stack.count > depthLimit { continue }

            var nextState = frame.state
            apply(move, to: &nextState)
            let normalized = normalize(nextState)

            if visited.contains(normalized.state) { continue }
            visited.insert(normalized.state)
            nodes += 1

            // 진행(홈 카드 증가) 없는 경로 가지치기 — 홈 카드가 늘지 않는 이동을
            // maxStagnantDepth 이상 반복하면 승리와 무관한 순환/배회로 간주해 백트래킹.
            let nextHomeCount = Self.homeCount(normalized.state)
            let newStagnant = nextHomeCount > frame.homeCount ? 0 : frame.stagnantDepth + 1
            if newStagnant > Self.maxStagnantDepth { continue }

            if isWon(normalized.state) {
                // 스택 순서대로 경로 누적: 각 프레임 = [appliedMove] + homeMoves (루트는 homeMoves만)
                var path: [Move] = []
                for f in stack {
                    if let applied = f.appliedMove { path.append(applied) }
                    path.append(contentsOf: f.homeMoves)
                }
                path.append(move)
                path.append(contentsOf: normalized.homeMoves)
                return (path, stack.count + 1)
            }

            stack.append(Frame(state: normalized.state, moves: generalMoves(normalized.state), nextIndex: 0, appliedMove: move, homeMoves: normalized.homeMoves, homeCount: nextHomeCount, stagnantDepth: newStagnant))
        }
        return nil
    }
}
