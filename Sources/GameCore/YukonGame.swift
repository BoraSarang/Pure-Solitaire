/// Yukon(유콘) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 7개 타블로 열 (뒤집힌 카드 포함), 홈셀 4개, 스톡/웨이스트 없음
/// - 규칙: 내림차순 + 교대색, 빈 열엔 K만,
///   **유콘 이동** — 아무 앞면 카드와 그 위 전부를 그룹으로 이동 (내부 순서 무관),
///   노출된 뒤집힌 카드는 자동으로 앞면 전환
public struct YukonGame: Equatable, Sendable, Codable {
    public internal(set) var columns: [[KlondikeGame.ColumnCard]]
    public internal(set) var homes: [[Card]]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[KlondikeGame.ColumnCard]]
        var homes: [[Card]]
        var moveCount: Int
    }

    public static let columnCount = 7
    public static let homeCount = 4

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        self.columns = DealGenerator.yukonDeal(gameNumber: gameNumber)
        self.homes = Array(repeating: [], count: Self.homeCount)
    }

    // MARK: - 조회

    public var isWon: Bool {
        homes.allSatisfy { $0.count == 13 }
    }

    /// 자동 완성 판단: 승리 직전 상태 — 모든 카드가 앞면으로 노출되고 바로 홈으로 이동 가능한 때.
    public var canAutoFinish: Bool {
        guard !isWon else { return false }
        var allCards: [Card] = []
        for column in columns {
            guard column.allSatisfy({ $0.faceUp }) else { return false }
            allCards.append(contentsOf: column.map { $0.card })
        }
        return allCards.allSatisfy { canMoveToFoundation($0) }
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
        return homes.firstIndex { $0.last?.suit == card.suit }
    }

    /// 열에 놓을 수 있는지 (내림차순 + 교대색, 빈 열엔 K만)
    public func canPlaceOnColumn(_ card: Card, column: Int) -> Bool {
        guard columns.indices.contains(column) else { return false }
        guard let top = columns[column].last else { return card.rank == .king }
        return card.rank == top.card.rank.previous && card.color != top.card.color
    }

    /// 유콘 이동: topIndex(앞면 카드)부터 위 전부를 한 그룹으로 반환 (내부 순서 무관)
    public func movableGroup(from column: Int, topIndex: Int) -> [Card]? {
        guard columns.indices.contains(column),
              topIndex >= 0,
              topIndex < columns[column].count,
              columns[column][topIndex].faceUp else { return nil }
        return columns[column][topIndex...].map { $0.card }
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
            let startIndex = columns[from].count - cardCount
            guard columns[from][startIndex].faceUp else { return false }
            return canPlaceOnColumn(columns[from][startIndex].card, column: to)

        case let .columnToHome(columnIndex, card):
            guard columns.indices.contains(columnIndex),
                  columns[columnIndex].last?.card == card,
                  columns[columnIndex].last?.faceUp == true else { return false }
            return canMoveToFoundation(card)

        // 유콘은 자동 앞면 전환 — 뒤집기/드로/웨이스트 이동 없음
        case .flipColumnCard, .drawFromStock, .recycleStock, .wasteToColumn, .wasteToFoundation, .dealFromStock:
            return false

        default:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, homes: homes, moveCount: moveCount))
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
            flipTopIfNeeded(column: from)

        case let .columnToHome(columnIndex, card):
            columns[columnIndex].removeLast()
            flipTopIfNeeded(column: columnIndex)
            homes[homeIndex(for: card)!].append(card)

        default:
            break
        }
    }

    /// 열 맨 위가 뒤집힌 카드면 앞면으로 뒤집는다 (노출 시 자동 전환)
    private mutating func flipTopIfNeeded(column: Int) {
        guard let last = columns[column].last, !last.faceUp else { return }
        columns[column][columns[column].count - 1].faceUp = true
    }

    // MARK: - 실행 취소 / 다시 실행

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(Snapshot(columns: columns, homes: homes, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, homes: homes, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        homes = snapshot.homes
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 홈 > 열→열)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 홈 우선 (열 맨 위 앞면)
        for i in columns.indices {
            if let cc = columns[i].last, cc.faceUp, canMoveToFoundation(cc.card),
               canMove(.columnToHome(columnIndex: i, card: cc.card)) {
                moves.append(.columnToHome(columnIndex: i, card: cc.card))
            }
        }

        // 열 → 열 (각 앞면 카드에서 그 위 전부를 그룹 이동)
        for from in columns.indices {
            for startIndex in columns[from].indices where columns[from][startIndex].faceUp {
                let cardCount = columns[from].count - startIndex
                for to in columns.indices where to != from && canMove(.columnToColumn(from: from, to: to, cardCount: cardCount)) {
                    moves.append(.columnToColumn(from: from, to: to, cardCount: cardCount))
                }
            }
        }

        return moves
    }
}
