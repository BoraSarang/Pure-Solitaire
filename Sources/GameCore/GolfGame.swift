/// Golf(골프) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 1덱 52장, 7개 타블로 열(각 5장, 전부 앞면), 스톡 16장, 웨이스트 1장 시작
/// - 규칙: 웨이스트 맨 위 카드와 1 차이 또는 같은 랭크인 열 맨 아래 카드를 웨이스트로 제거
///   (수트 무관, K↔A 인접 순환), 열 간 이동 없음, 빈 열 재사용 없음, 스톡 재활용 없음
/// - 승리: 7열 모두 비어있음
public struct GolfGame: Equatable, Sendable, Codable {
    public internal(set) var columns: [[Card]]
    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[Card]]
        var stock: [Card]
        var waste: [Card]
        var moveCount: Int
    }

    public static let columnCount = 7

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        let deal = DealGenerator.golfDeal(gameNumber: gameNumber)
        self.columns = deal.columns
        self.stock = deal.stock
        self.waste = deal.waste
    }

    // MARK: - 조회

    public var isWon: Bool {
        columns.allSatisfy { $0.isEmpty }
    }

    /// 웨이스트 맨 위 카드와 1 차이 또는 같은 랭크인지 (K↔A 인접 순환)
    public func isAdjacent(_ card: Card, to top: Card) -> Bool {
        let a = card.rank.rawValue
        let b = top.rank.rawValue
        if a == b { return true }
        if abs(a - b) == 1 { return true }
        // 순환: K(13) ↔ A(1)
        return (a == 13 && b == 1) || (a == 1 && b == 13)
    }

    /// 열 맨 아래 카드를 웨이스트로 제거할 수 있는지
    public func canRemoveFromColumn(_ column: Int) -> Bool {
        guard columns.indices.contains(column),
              let bottom = columns[column].last,
              let top = waste.last else { return false }
        return isAdjacent(bottom, to: top)
    }

    public var hasAnyMove: Bool {
        hint() != nil
    }

    // MARK: - 이동 검증

    public func canMove(_ move: Move) -> Bool {
        switch move {
        case let .columnToWaste(columnIndex, card):
            guard columns.indices.contains(columnIndex),
                  columns[columnIndex].last == card else { return false }
            return canRemoveFromColumn(columnIndex)

        case .drawFromStock:
            return !stock.isEmpty

        // 다른 게임 전용 이동은 발생하지 않음
        case .columnToColumn, .columnToFreeCell, .freeCellToColumn, .columnToHome,
             .freeCellToHome, .homeToColumn, .homeToFreeCell, .recycleStock,
             .wasteToColumn, .wasteToFoundation, .flipColumnCard, .dealFromStock,
             .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle, .triPeaksRemove:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, moveCount: moveCount))
        applyUnchecked(move)
        redoStack.removeAll()
        moveCount += 1
        return true
    }

    private mutating func applyUnchecked(_ move: Move) {
        switch move {
        case let .columnToWaste(columnIndex, card):
            columns[columnIndex].removeLast()
            waste.append(card)

        case .drawFromStock:
            waste.append(stock.removeLast())

        default:
            break
        }
    }

    // MARK: - 실행 취소 / 다시 실행

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        stock = snapshot.stock
        waste = snapshot.waste
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 열→웨이스트 제거 > 드로)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 열 맨 아래 카드 → 웨이스트 (왼쪽 열부터)
        for i in columns.indices {
            if canRemoveFromColumn(i), let card = columns[i].last {
                moves.append(.columnToWaste(columnIndex: i, card: card))
            }
        }

        // 드로 (스톡 일회성 — 재활용 없음)
        if !stock.isEmpty {
            moves.append(.drawFromStock)
        }

        return moves
    }
}
