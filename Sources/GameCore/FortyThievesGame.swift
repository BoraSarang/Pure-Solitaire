/// Forty Thieves(포트티브스) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 2덱 104장, 10개 타블로 열(각 4장, 전부 앞면), 스톡 64장, 웨이스트, 홈셀 8개
/// - 규칙: 같은 수트 내림차순, 빈 열엔 아무 카드,
///   스톡에서 1장 드로 → 웨이스트, 웨이스트 → 열/홈, 홈셀 8개 A→K (2덱 수트당 2홈)
public struct FortyThievesGame: Equatable, Sendable, Codable {
    public internal(set) var columns: [[Card]]
    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public internal(set) var homes: [[Card]]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[Card]]
        var stock: [Card]
        var waste: [Card]
        var homes: [[Card]]
        var moveCount: Int
    }

    public static let columnCount = 10
    public static let homeCount = 8

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        let deal = DealGenerator.fortyThievesDeal(gameNumber: gameNumber)
        self.columns = deal.columns
        self.stock = deal.stock
        self.waste = []
        self.homes = Array(repeating: [], count: Self.homeCount)
    }

    // MARK: - 조회

    public var isWon: Bool {
        homes.allSatisfy { $0.count == 13 }
    }

    /// 자동 완성 판단: 승리 직전 상태 — 스톡/웨이스트가 비고 열 카드 전부가 바로 홈으로 이동 가능한 때.
    public var canAutoFinish: Bool {
        guard !isWon else { return false }
        guard stock.isEmpty, waste.isEmpty else { return false }
        return columns.allSatisfy { column in
            column.allSatisfy { canMoveToFoundation($0) }
        }
    }

    /// 홈셀에 놓을 수 있는지 (같은 수트, A부터 순차)
    public func canMoveToFoundation(_ card: Card) -> Bool {
        if card.rank == .ace {
            return homes.contains { $0.isEmpty }
        }
        return homes.contains {
            guard let top = $0.last else { return false }
            return top.suit == card.suit && top.rank.next == card.rank
        }
    }

    public func homeIndex(for card: Card) -> Int? {
        if card.rank == .ace, let i = homes.firstIndex(where: { $0.isEmpty }) {
            return i
        }
        return homes.firstIndex {
            guard let top = $0.last else { return false }
            return top.suit == card.suit && top.rank.next == card.rank
        }
    }

    /// 열에 놓을 수 있는지 (같은 수트 내림차순, 빈 열엔 아무 카드)
    public func canPlaceOnColumn(_ card: Card, column: Int) -> Bool {
        guard columns.indices.contains(column) else { return false }
        guard let top = columns[column].last else { return true }
        return card.rank == top.rank.previous && card.suit == top.suit
    }

    /// 타블로 열 맨 아래(bottom)에서 같은 수트 내림차순 시퀀스 추출 (bottom→top 랭크 증가)
    public func movableRun(from column: Int) -> [Card] {
        var run: [Card] = []
        for card in columns[column].reversed() {
            if run.isEmpty {
                run.append(card)
            } else if let top = run.last,
                      card.rank == top.rank.next,
                      card.suit == top.suit {
                run.append(card)
            } else {
                break
            }
        }
        return Array(run.reversed())
    }

    public var hasAnyMove: Bool {
        hint() != nil
    }

    // MARK: - 이동 검증

    public func canMove(_ move: Move) -> Bool {
        switch move {
        case let .columnToColumn(from, to, cardCount):
            guard from != to,
                  columns.indices.contains(from),
                  columns.indices.contains(to),
                  cardCount >= 1,
                  columns[from].count >= cardCount else { return false }
            let moving = movableRun(from: from)
            guard moving.count >= cardCount else { return false }
            let top = moving[moving.count - cardCount]
            return canPlaceOnColumn(top, column: to)

        case let .columnToHome(columnIndex, card):
            guard columns.indices.contains(columnIndex),
                  columns[columnIndex].last == card else { return false }
            return canMoveToFoundation(card)

        case let .wasteToColumn(columnIndex, card):
            guard waste.last == card else { return false }
            return canPlaceOnColumn(card, column: columnIndex)

        case let .wasteToFoundation(card):
            guard waste.last == card else { return false }
            return canMoveToFoundation(card)

        case .drawFromStock:
            return !stock.isEmpty

        // 프리셀/스파이더/유콘/골프/피라미드 전용 이동은 발생하지 않음
        case .columnToFreeCell, .freeCellToColumn, .freeCellToHome,
             .homeToColumn, .homeToFreeCell, .flipColumnCard,
             .recycleStock, .dealFromStock, .columnToWaste,
             .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle, .triPeaksRemove:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, homes: homes, moveCount: moveCount))
        applyUnchecked(move)
        redoStack.removeAll()
        moveCount += 1
        return true
    }

    private mutating func applyUnchecked(_ move: Move) {
        switch move {
        case let .columnToColumn(from, to, cardCount):
            let moving = Array(columns[from].suffix(cardCount))
            columns[from].removeLast(cardCount)
            columns[to].append(contentsOf: moving)

        case let .columnToHome(columnIndex, card):
            columns[columnIndex].removeLast()
            homes[homeIndex(for: card)!].append(card)

        case let .wasteToColumn(columnIndex, card):
            waste.removeLast()
            columns[columnIndex].append(card)

        case let .wasteToFoundation(card):
            waste.removeLast()
            homes[homeIndex(for: card)!].append(card)

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
        redoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, homes: homes, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, stock: stock, waste: waste, homes: homes, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        stock = snapshot.stock
        waste = snapshot.waste
        homes = snapshot.homes
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 홈 > 웨이스트→열 > 열→열 > 드로)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 홈 우선 (열 맨 위 / 웨이스트 맨 위)
        for i in columns.indices {
            if let card = columns[i].last, canMoveToFoundation(card),
               canMove(.columnToHome(columnIndex: i, card: card)) {
                moves.append(.columnToHome(columnIndex: i, card: card))
            }
        }
        if let card = waste.last, canMoveToFoundation(card), canMove(.wasteToFoundation(card: card)) {
            moves.append(.wasteToFoundation(card: card))
        }

        // 웨이스트 → 열
        if let card = waste.last {
            for i in columns.indices where canMove(.wasteToColumn(columnIndex: i, card: card)) {
                moves.append(.wasteToColumn(columnIndex: i, card: card))
            }
        }

        // 열 → 열 (한 장씩, 같은 수트)
        for from in columns.indices {
            guard movableRun(from: from).count >= 1 else { continue }
            for to in columns.indices where to != from && canMove(.columnToColumn(from: from, to: to, cardCount: 1)) {
                moves.append(.columnToColumn(from: from, to: to, cardCount: 1))
            }
        }

        // 드로 (스톡 일회성 — 재활용 없음)
        if !stock.isEmpty {
            moves.append(.drawFromStock)
        }

        return moves
    }
}
