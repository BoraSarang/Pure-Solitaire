/// 프리셀 게임 상태 + 이동 적용 + 실행 취소/다시 실행
public struct FreeCellGame: Equatable, Sendable, Codable {
    public internal(set) var columns: [[Card]]
    public internal(set) var freeCells: [Card?]
    public internal(set) var homes: [[Card]]
    public let gameNumber: Int
    public let variant: GameVariant
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    /// 실행 취소/다시 실행 스택에 저장되는 상태 스냅샷.
    /// 이동 기반 역연산이 아닌 전체 상태 복원 방식이라 홈/열 상태가 불일치해도 크래시하지 않는다.
    private struct Snapshot: Equatable, Codable {
        var columns: [[Card]]
        var freeCells: [Card?]
        var homes: [[Card]]
        var moveCount: Int
    }

    public static let columnCount = 8
    public static let homeCount = 4
    public static let freeCellCountFreeCell = 4
    public static let freeCellCountBakers = 0

    /// 변형별 타블로 열 개수
    public static func columnCount(for variant: GameVariant) -> Int {
        switch variant {
        case .seaTower, .superFreeCell: 10
        default: columnCount
        }
    }

    public init(gameNumber: Int, variant: GameVariant = .freecell) {
        self.gameNumber = gameNumber
        self.variant = variant
        switch variant {
        case .seaTower:
            let deal = DealGenerator.seaTowerDeal(gameNumber: gameNumber)
            self.columns = deal.columns
            var cells = Array(repeating: Card?.none, count: Self.freeCellCount(for: variant))
            if deal.freeCellStarts.count >= 2 {
                cells[0] = deal.freeCellStarts[0]
                cells[1] = deal.freeCellStarts[1]
            }
            self.freeCells = cells
        case .superFreeCell:
            self.columns = DealGenerator.superFreeCellDeal(gameNumber: gameNumber)
            self.freeCells = Array(repeating: nil, count: Self.freeCellCount(for: variant))
        default:
            self.columns = DealGenerator.deal(gameNumber: gameNumber)
            self.freeCells = Array(repeating: nil, count: Self.freeCellCount(for: variant))
        }
        self.homes = Array(repeating: [], count: Self.homeCount)
    }

    /// 형식에 따른 프리셀 개수
    public static func freeCellCount(for variant: GameVariant) -> Int {
        switch variant {
        case .freecell: freeCellCountFreeCell
        case .bakersGame, .klondike, .spider, .yukon, .fortyThieves: freeCellCountBakers
        case .seaTower: 4
        case .superFreeCell: 6
        case .golf, .pyramid, .triPeaks: 0
        }
    }

    // MARK: - Codable (이전 저장 데이터 호환)

    private enum CodingKeys: String, CodingKey {
        case columns, freeCells, homes, gameNumber, moveCount, undoStack, redoStack, variant
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        columns = try c.decode([[Card]].self, forKey: .columns)
        freeCells = try c.decode([Card?].self, forKey: .freeCells)
        homes = try c.decode([[Card]].self, forKey: .homes)
        gameNumber = try c.decode(Int.self, forKey: .gameNumber)
        moveCount = try c.decodeIfPresent(Int.self, forKey: .moveCount) ?? 0
        undoStack = try c.decodeIfPresent([Snapshot].self, forKey: .undoStack) ?? []
        redoStack = try c.decodeIfPresent([Snapshot].self, forKey: .redoStack) ?? []
        variant = try c.decodeIfPresent(GameVariant.self, forKey: .variant) ?? .freecell
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(columns, forKey: .columns)
        try c.encode(freeCells, forKey: .freeCells)
        try c.encode(homes, forKey: .homes)
        try c.encode(gameNumber, forKey: .gameNumber)
        try c.encode(moveCount, forKey: .moveCount)
        try c.encode(undoStack, forKey: .undoStack)
        try c.encode(redoStack, forKey: .redoStack)
        try c.encode(variant, forKey: .variant)
    }

    // MARK: - 조회

    public var emptyFreeCellCount: Int {
        freeCells.filter { $0 == nil }.count
    }

    public var isWon: Bool {
        switch variant {
        case .superFreeCell:
            return homes.allSatisfy { $0.count == 26 }
        default:
            return homes.allSatisfy { $0.count == 13 }
        }
    }

    /// 자동 완성 판단: 승리 직전 상태 — 남은 모든 카드가 바로 홈으로 이동 가능한 때.
    /// (홈셀 계열 게임 전용; spider/golf/pyramid/triPeaks는 완성 구조가 달라 제외)
    public var canAutoFinish: Bool {
        guard !isWon else { return false }
        return allCardsInPlay.allSatisfy { canMoveToHome($0) }
    }

    public var hasAnyMove: Bool {
        hint() != nil
    }

    public var allCardsInPlay: [Card] {
        columns.flatMap { $0 } + freeCells.compactMap { $0 }
    }

    public func isHomeCard(_ card: Card) -> Bool {
        homes.contains { $0.contains(card) }
    }

    public func canMoveToHome(_ card: Card) -> Bool {
        switch variant {
        case .superFreeCell:
            // 홈셀은 수트 고정(suit.rawValue), A→K 후 다시 A→K (26장)
            let homeIndex = suitHomeIndex(for: card)
            guard homes.indices.contains(homeIndex) else { return false }
            guard let top = homes[homeIndex].last else {
                return card.rank == .ace
            }
            if top.rank == .king {
                return card.rank == .ace
            }
            return top.suit == card.suit && top.rank.next == card.rank
        default:
            if card.rank == .ace {
                return homes.contains { $0.isEmpty }
            }
            return homes.contains {
                guard let top = $0.last else { return false }
                return top.suit == card.suit && top.rank.next == card.rank
            }
        }
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

            let moving = Array(columns[from].suffix(cardCount))
            let run = FreeCellRule.movableRun(from: columns[from], variant: variant)
            guard run.count >= cardCount, Array(run.suffix(cardCount)) == moving else { return false }

            // Baker's Game: 한 번에 한 장만 이동. Sea Tower: 빈 열은 K만이라 임시 저장 불가 → 수퍼무브는 프리셀만 사용
            let totalEmptyColumns = columns.filter { $0.isEmpty }.count
            let destinationIsEmpty = columns[to].isEmpty
            let capacity: Int
            if variant == .seaTower {
                capacity = FreeCellRule.supermoveCapacity(
                    emptyFreeCells: emptyFreeCellCount,
                    emptyColumns: 0,
                    destinationIsEmpty: false
                )
            } else {
                capacity = FreeCellRule.supermoveCapacity(
                    emptyFreeCells: emptyFreeCellCount,
                    emptyColumns: totalEmptyColumns,
                    destinationIsEmpty: destinationIsEmpty
                )
            }
            if variant == .bakersGame && cardCount != 1 { return false }
            guard cardCount <= capacity else { return false }

            if let destTop = columns[to].last {
                return FreeCellRule.canMoveToColumn(moving.first!, topCard: destTop, variant: variant)
            }
            return true

        case let .columnToFreeCell(columnIndex, freeCellIndex, card):
            guard columns.indices.contains(columnIndex),
                  freeCells.indices.contains(freeCellIndex),
                  freeCells[freeCellIndex] == nil else { return false }
            return columns[columnIndex].last == card

        case let .freeCellToColumn(freeCellIndex, columnIndex, card):
            guard freeCells.indices.contains(freeCellIndex),
                  columns.indices.contains(columnIndex),
                  freeCells[freeCellIndex] == card else { return false }
            return FreeCellRule.canMoveToColumn(card, topCard: columns[columnIndex].last, variant: variant)

        case let .columnToHome(columnIndex, card):
            guard columns.indices.contains(columnIndex) else { return false }
            guard columns[columnIndex].last == card else { return false }
            return canMoveToHome(card)

        case let .freeCellToHome(freeCellIndex, card):
            guard freeCells.indices.contains(freeCellIndex),
                  freeCells[freeCellIndex] == card else { return false }
            return canMoveToHome(card)

        case let .homeToColumn(homeIndex, columnIndex, card):
            guard homes.indices.contains(homeIndex),
                  columns.indices.contains(columnIndex),
                  homes[homeIndex].last == card else { return false }
            return FreeCellRule.canMoveToColumn(card, topCard: columns[columnIndex].last, variant: variant)

        case let .homeToFreeCell(homeIndex, freeCellIndex, card):
            guard homes.indices.contains(homeIndex),
                  freeCells.indices.contains(freeCellIndex),
                  homes[homeIndex].last == card,
                  freeCells[freeCellIndex] == nil else { return false }
            return true

        // Klondike/Spider/Golf/Pyramid 전용 이동은 프리셀 게임에서 발생하지 않음
        case .drawFromStock, .recycleStock, .wasteToColumn, .wasteToFoundation, .flipColumnCard, .dealFromStock, .columnToWaste,
             .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle, .triPeaksRemove:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, freeCells: freeCells, homes: homes, moveCount: moveCount))
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

        case let .columnToFreeCell(columnIndex, freeCellIndex, card):
            columns[columnIndex].removeLast()
            freeCells[freeCellIndex] = card

        case let .freeCellToColumn(freeCellIndex, columnIndex, card):
            freeCells[freeCellIndex] = nil
            columns[columnIndex].append(card)

        case let .columnToHome(columnIndex, card):
            columns[columnIndex].removeLast()
            homes[homeIndex(for: card)!].append(card)

        case let .freeCellToHome(freeCellIndex, card):
            freeCells[freeCellIndex] = nil
            homes[homeIndex(for: card)!].append(card)

        case let .homeToColumn(homeIndex, columnIndex, card):
            homes[homeIndex].removeLast()
            columns[columnIndex].append(card)

        case let .homeToFreeCell(homeIndex, freeCellIndex, card):
            homes[homeIndex].removeLast()
            freeCells[freeCellIndex] = card

        // Klondike/Spider/Golf/Pyramid 전용 이동은 프리셀 게임에서 발생하지 않음 (apply는 canMove 통과 시에만 도달)
        case .drawFromStock, .recycleStock, .wasteToColumn, .wasteToFoundation, .flipColumnCard, .dealFromStock, .columnToWaste,
             .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle, .triPeaksRemove:
            break
        }
    }

    /// 해당 카드를 놓을 홈셀 인덱스 (canMoveToHome이 true일 때만 호출)
    public func homeIndex(for card: Card) -> Int? {
        if variant == .superFreeCell {
            return suitHomeIndex(for: card)
        }
        if card.rank == .ace, let i = homes.firstIndex(where: { $0.isEmpty }) {
            return i
        }
        return homes.firstIndex { $0.last?.suit == card.suit }
    }

    /// Super FreeCell 전용: 홈셀을 수트 인덱스에 고정 (♣=0, ♦=1, ♥=2, ♠=3)
    private func suitHomeIndex(for card: Card) -> Int {
        card.suit.rawValue
    }

    // MARK: - 실행 취소 / 다시 실행

    public var canUndo: Bool { !undoStack.isEmpty }

    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(Snapshot(columns: columns, freeCells: freeCells, homes: homes, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, freeCells: freeCells, homes: homes, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        freeCells = snapshot.freeCells
        homes = snapshot.homes
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 반환 (우선순위: 홈 > 프리셀→타블로 > 타블로→타블로 > 타블로→프리셀)
    public func hint() -> Move? {
        hintCandidates().first
    }

    /// 유효한 이동 전부를 우선순위 순으로 수집 (힌트 순환/하이라이트용)
    public func hintCandidates() -> [Move] {
        var moves: [Move] = []
        for i in columns.indices {
            if let card = columns[i].last,
               canMoveToHome(card),
               canMove(.columnToHome(columnIndex: i, card: card)) {
                moves.append(.columnToHome(columnIndex: i, card: card))
            }
        }
        for i in freeCells.indices {
            if let card = freeCells[i],
               canMoveToHome(card),
               canMove(.freeCellToHome(freeCellIndex: i, card: card)) {
                moves.append(.freeCellToHome(freeCellIndex: i, card: card))
            }
        }
        for fc in freeCells.indices {
            guard let card = freeCells[fc] else { continue }
            for col in columns.indices where canMove(.freeCellToColumn(freeCellIndex: fc, columnIndex: col, card: card)) {
                moves.append(.freeCellToColumn(freeCellIndex: fc, columnIndex: col, card: card))
            }
        }
        for from in columns.indices {
            guard columns[from].last != nil else { continue }
            for to in columns.indices where to != from && canMove(.columnToColumn(from: from, to: to, cardCount: 1)) {
                moves.append(.columnToColumn(from: from, to: to, cardCount: 1))
            }
        }
        for col in columns.indices {
            guard let card = columns[col].last else { continue }
            for fc in freeCells.indices where freeCells[fc] == nil {
                moves.append(.columnToFreeCell(columnIndex: col, freeCellIndex: fc, card: card))
            }
        }
        return moves
    }
}
