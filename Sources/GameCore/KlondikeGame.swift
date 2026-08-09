/// Klondike(솔리테어) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 7개 타블로 열 (뒤집힌 카드 포함), 스톡/웨이스트, 홈셀 4개
/// - 규칙: 내림차순 + 교대색, 빈 열엔 K만, 앞면 카드만 이동,
///   스톡에서 1장 드로 → 웨이스트, 뒤집힌 카드는 탭으로 뒤집기
public struct KlondikeGame: Equatable, Sendable, Codable {
    /// 타블로 열의 한 장 (뒤집힘 여부 포함)
    public struct ColumnCard: Equatable, Sendable, Codable {
        public var card: Card
        public var faceUp: Bool

        public init(card: Card, faceUp: Bool) {
            self.card = card
            self.faceUp = faceUp
        }
    }

    public internal(set) var columns: [[ColumnCard]]
    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public internal(set) var homes: [[Card]]
    public let gameNumber: Int
    /// 스톡 드로 장수 (1 = 한 장, 3 = 세 장)
    public var drawMode: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[ColumnCard]]
        var stock: [Card]
        var waste: [Card]
        var homes: [[Card]]
        var moveCount: Int
    }

    public static let columnCount = 7
    public static let homeCount = 4

    public init(gameNumber: Int, drawMode: Int = 1) {
        self.gameNumber = gameNumber
        self.drawMode = drawMode == 3 ? 3 : 1
        let shuffled = DealGenerator.shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [ColumnCard](), count: Self.columnCount)
        var index = 0
        for col in 0..<Self.columnCount {
            let count = col + 1
            for _ in 0..<count {
                columns[col].append(ColumnCard(card: shuffled[index], faceUp: false))
                index += 1
            }
            columns[col][columns[col].count - 1].faceUp = true
        }
        self.columns = columns
        self.stock = Array(shuffled[index...])
        self.waste = []
        self.homes = Array(repeating: [], count: Self.homeCount)
    }

    // MARK: - Codable (이전 저장 데이터 호환 — drawMode 기본 1)

    private enum CodingKeys: String, CodingKey {
        case columns, stock, waste, homes, gameNumber, drawMode, moveCount, undoStack, redoStack
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        columns = try c.decode([[ColumnCard]].self, forKey: .columns)
        stock = try c.decode([Card].self, forKey: .stock)
        waste = try c.decode([Card].self, forKey: .waste)
        homes = try c.decode([[Card]].self, forKey: .homes)
        gameNumber = try c.decode(Int.self, forKey: .gameNumber)
        drawMode = try c.decodeIfPresent(Int.self, forKey: .drawMode) ?? 1
        moveCount = try c.decodeIfPresent(Int.self, forKey: .moveCount) ?? 0
        undoStack = try c.decodeIfPresent([Snapshot].self, forKey: .undoStack) ?? []
        redoStack = try c.decodeIfPresent([Snapshot].self, forKey: .redoStack) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(columns, forKey: .columns)
        try c.encode(stock, forKey: .stock)
        try c.encode(waste, forKey: .waste)
        try c.encode(homes, forKey: .homes)
        try c.encode(gameNumber, forKey: .gameNumber)
        try c.encode(drawMode, forKey: .drawMode)
        try c.encode(moveCount, forKey: .moveCount)
        try c.encode(undoStack, forKey: .undoStack)
        try c.encode(redoStack, forKey: .redoStack)
    }

    // MARK: - 조회

    public var isWon: Bool {
        homes.allSatisfy { $0.count == 13 }
    }

    /// 자동 완성 판단: 승리 직전 상태 — 모든 카드가 앞면으로 노출되고
    /// 스톡/웨이스트가 비어 홈 셀로만 완성하면 승리하는 때.
    public var canAutoFinish: Bool {
        guard !isWon else { return false }
        guard stock.isEmpty, waste.isEmpty else { return false }
        return columns.allSatisfy { column in
            column.allSatisfy { $0.faceUp && canMoveToFoundation($0.card) }
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
        return homes.firstIndex { $0.last?.suit == card.suit }
    }

    /// 열에 놓을 수 있는지 (내림차순 + 교대색, 빈 열엔 K만)
    public func canPlaceOnColumn(_ card: Card, column: Int) -> Bool {
        guard columns.indices.contains(column) else { return false }
        guard let top = columns[column].last else { return card.rank == .king }
        return card.rank == top.card.rank.previous && card.color != top.card.color
    }

    /// 타블로 열 맨 아래 앞면 카드 시퀀스 추출 (bottom→top, 내림차순+교대색)
    public func movableRun(from column: Int) -> [Card] {
        var run: [Card] = []
        for cc in columns[column].reversed() {
            guard cc.faceUp else { break }
            if run.isEmpty {
                run.append(cc.card)
            } else if let top = run.last,
                      cc.card.rank == top.rank.next,
                      cc.card.color != top.color {
                run.append(cc.card)
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
            return canPlaceOnColumn(moving[0], column: to)

        case let .columnToHome(columnIndex, card):
            guard columns.indices.contains(columnIndex),
                  columns[columnIndex].last?.card == card,
                  columns[columnIndex].last?.faceUp == true else { return false }
            return canMoveToFoundation(card)

        case let .wasteToColumn(columnIndex, card):
            guard waste.last == card else { return false }
            return canPlaceOnColumn(card, column: columnIndex)

        case let .wasteToFoundation(card):
            guard waste.last == card else { return false }
            return canMoveToFoundation(card)

        case .drawFromStock:
            return !stock.isEmpty

        case .recycleStock:
            return stock.isEmpty && !waste.isEmpty

        case let .flipColumnCard(columnIndex, card):
            guard columns.indices.contains(columnIndex),
                  let last = columns[columnIndex].last,
                  last.card == card,
                  !last.faceUp else { return false }
            return true

        case .dealFromStock:
            return false

        default:
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
            flipTopIfNeeded(column: from)

        case let .columnToHome(columnIndex, card):
            columns[columnIndex].removeLast()
            flipTopIfNeeded(column: columnIndex)
            homes[homeIndex(for: card)!].append(card)

        case let .wasteToColumn(columnIndex, card):
            waste.removeLast()
            columns[columnIndex].append(ColumnCard(card: card, faceUp: true))

        case let .wasteToFoundation(card):
            waste.removeLast()
            homes[homeIndex(for: card)!].append(card)

        case .drawFromStock:
            // drawMode장을 스톡 맨 위(배열 마지막)에서 순서대로 웨이스트에 쌓는다.
            // 표준 규칙: 3장 드로 시 스톡 상단 3장이 그대로 노출되어 맨 위(마지막)만 플레이 가능.
            let count = min(drawMode, stock.count)
            let drawn = Array(stock.suffix(count))
            waste.append(contentsOf: drawn)
            stock.removeLast(count)

        case .recycleStock:
            stock = waste.reversed()
            waste.removeAll()

        case let .flipColumnCard(columnIndex, card):
            if let i = columns[columnIndex].indices.last, columns[columnIndex][i].card == card {
                columns[columnIndex][i].faceUp = true
            }

        default:
            break
        }
    }

    /// 열 맨 위가 뒤집힌 카드면 앞면으로 뒤집는다 (다른 수는 카운트하지 않음)
    private mutating func flipTopIfNeeded(column: Int) {
        guard let last = columns[column].last, !last.faceUp else { return }
        columns[column][columns[column].count - 1].faceUp = true
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

    /// 유효한 이동 하나 (우선순위: 홈 > 웨이스트→열 > 열→열 > 뒤집기 > 드로)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 홈 우선 (열 맨 위 앞면 / 웨이스트 맨 위)
        for i in columns.indices {
            if let cc = columns[i].last, cc.faceUp, canMoveToFoundation(cc.card),
               canMove(.columnToHome(columnIndex: i, card: cc.card)) {
                moves.append(.columnToHome(columnIndex: i, card: cc.card))
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

        // 열 → 열 (한 장씩, 교대색)
        for from in columns.indices {
            guard movableRun(from: from).count >= 1 else { continue }
            for to in columns.indices where to != from && canMove(.columnToColumn(from: from, to: to, cardCount: 1)) {
                moves.append(.columnToColumn(from: from, to: to, cardCount: 1))
            }
        }

        // 뒤집기
        for i in columns.indices {
            if let cc = columns[i].last, !cc.faceUp {
                moves.append(.flipColumnCard(columnIndex: i, card: cc.card))
            }
        }

        // 드로
        if !stock.isEmpty {
            moves.append(.drawFromStock)
        }

        // 재활용 (스톡 비고 웨이스트 있을 때)
        if stock.isEmpty && !waste.isEmpty {
            moves.append(.recycleStock)
        }

        return moves
    }
}
