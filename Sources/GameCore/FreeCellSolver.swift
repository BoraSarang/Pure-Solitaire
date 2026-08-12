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
        guard isFreeCellFamily(variant) else { return false }
        let game = FreeCellGame(gameNumber: gameNumber, variant: variant)
        return isWinnable(state: SolverState(from: game), variant: variant, budget: budget)
    }

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

    /// 반복 DFS 스택 프레임 — 상태와 다음 시도할 이동 인덱스
    private struct Frame {
        var state: SolverState
        var moves: [Move]
        var nextIndex: Int
    }

    static func isWinnable(state: SolverState, variant: GameVariant, budget: Budget) -> Bool {
        let start = Date()
        var visited: Set<SolverState> = []
        var nodes = 0

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

        /// 안전 규칙 (표준 FreeCell 자동 이동 규칙, 재귀 없음):
        /// 카드 C(rank r)를 홈으로 보내도 안전한 조건 —
        /// C 위에 쌓일 수 있는 카드들(r-1, 반대색 2장)이 모두 이미 홈에 있으면 안전.
        /// (A는 항상 안전)
        func isSafeToAutoplay(_ card: Card, in s: SolverState) -> Bool {
            if card.rank == .ace { return true }
            guard let lowerRank = card.rank.previous else { return true }
            let blockers = s.allCardsInPlay.filter {
                $0.rank == lowerRank && $0.color == card.color.opposite
            }
            return blockers.allSatisfy { s.isHomeCard($0) }
        }

        /// 안전한 홈 이동을 가능한 만큼 연속 적용한 정규화 상태 반환 (상태 압축)
        func normalize(_ s: SolverState) -> SolverState {
            var cur = s
            var progressed = true
            while progressed {
                progressed = false
                for i in cur.columns.indices {
                    guard let card = cur.columns[i].last else { continue }
                    if canMoveToHome(card, in: cur), isSafeToAutoplay(card, in: cur) {
                        cur.columns[i].removeLast()
                        cur.homes[homeIndex(for: card, in: cur)!].append(card)
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
                        progressed = true
                        break
                    }
                }
            }
            return cur
        }

        /// 일반 이동 (안전 홈 이동은 normalize에서 이미 처리됨) — 우선순위 오름차순
        /// 수퍼무브(그룹) 포함 — FreeCell 탐색 효율의 핵심.
        /// 0: 홈 이동(안전하지 않은 것만) / 1: 프리셀 비우기 / 2: 열→열(빈 열 제외, K 우선) /
        /// 3: 열→빈 열(비-K) / 4: 열→프리셀 / 5: 홈 꺼내기
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
                for to in s.columns.indices where to != from {
                    guard FreeCellRule.canMoveToColumn(run.first!, topCard: s.columns[to].last, variant: variant) else { continue }
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
                        moves.append(.columnToColumn(from: from, to: to, cardCount: 1))
                        if maxCount > 1 {
                            moves.append(.columnToColumn(from: from, to: to, cardCount: maxCount))
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

        /// 이동 우선순위 (낮을수록 먼저 시도)
        /// 0 홈 이동 / 1 프리셀→열(프리셀 정리) / 2 빈 열로 K /
        /// 3 그룹 이동(크기 2+) / 4 빈 열로 비-K / 5 단일 열→열(빈 열 있을 때만) /
        /// 6 열→프리셀 / 9 홈에서 꺼내기
        func priority(_ move: Move, in s: SolverState) -> Int {
            switch move {
            case .columnToHome: return 0
            case .freeCellToColumn: return 1
            case let .columnToColumn(from, to, cardCount):
                let empty = s.columns[to].isEmpty
                if empty {
                    if variant == .seaTower { return 3 }
                    return s.columns[from].last?.rank == .king ? 2 : 4
                }
                if cardCount >= 2 { return 3 }
                let emptyCols = s.columns.filter { $0.isEmpty }.count
                return emptyCols > 0 ? 5 : 8
            case .columnToFreeCell: return 6
            case .homeToColumn, .homeToFreeCell: return 9
            default: return 6
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

        // 반복 DFS (명시적 스택) — 스택 오버플로우 없음
        var stack: [Frame] = []
        let current = normalize(state)
        visited.insert(current)
        nodes += 1
        if isWon(current) { return true }
        let firstMoves = generalMoves(current)
        stack.append(Frame(state: current, moves: firstMoves, nextIndex: 0))

        while !stack.isEmpty {
            if nodes > budget.nodeLimit { return false }
            if Date().timeIntervalSince(start) > budget.timeLimit { return false }

            let frame = stack[stack.count - 1]
            if frame.nextIndex >= frame.moves.count {
                stack.removeLast()
                continue
            }
            let move = frame.moves[frame.nextIndex]
            stack[stack.count - 1].nextIndex += 1

            // 깊이 제한 — 이 경로만 중단하고 백트래킹 (형제 이동 계속 탐색)
            if stack.count > budget.depthLimit { continue }

            var nextState = frame.state
            apply(move, to: &nextState)
            let normalized = normalize(nextState)

            if visited.contains(normalized) { continue }
            visited.insert(normalized)
            nodes += 1
            if isWon(normalized) { return true }

            stack.append(Frame(state: normalized, moves: generalMoves(normalized), nextIndex: 0))
        }
        return false
    }
}
