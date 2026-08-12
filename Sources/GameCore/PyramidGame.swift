/// Pyramid(피라미드) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 1덱 52장, 피라미드 28장(7줄: 1+2+3+4+5+6+7), 스톡 24장, 웨이스트 0장 시작
/// - 카드 값: A=1, 2~10=숫자, J=11, Q=12, K=13 (rank.rawValue)
/// - 노출 카드: 7번째 줄(맨 아래)은 항상 노출, 위 줄 카드는 아래 두 자식이 모두 제거됐을 때만 노출
/// - 이동: 합이 13인 노출 카드 제거 (피라미드 2장 / 피라미드+웨이스트 / K 단독), 스톡→웨이스트 드로(재활용 없음)
/// - 승리: 피라미드 28장 전부 제거
public struct PyramidGame: Equatable, Sendable, Codable {
    /// 피라미드 카드 (글로벌 인덱스 0~27, row r = r+1장, rowStart(r) = r*(r+1)/2). nil = 제거됨.
    public internal(set) var pyramid: [Card?]
    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var pyramid: [Card?]
        var stock: [Card]
        var waste: [Card]
        var moveCount: Int
    }

    public static let pyramidRows = 7
    public static var pyramidCount: Int { pyramidRows * (pyramidRows + 1) / 2 }

    /// row r의 첫 글로벌 인덱스
    public static func rowStart(_ row: Int) -> Int { row * (row + 1) / 2 }

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        let deal = DealGenerator.pyramidDeal(gameNumber: gameNumber)
        self.pyramid = deal.pyramid.map { Optional($0) }
        self.stock = deal.stock
        self.waste = []
    }

    // MARK: - 조회

    public var isWon: Bool {
        pyramid.allSatisfy { $0 == nil }
    }

    /// 카드 값 (A=1, ..., K=13)
    public static func cardValue(_ card: Card) -> Int { card.rank.rawValue }

    /// 글로벌 인덱스가 노출 카드인지: 카드가 남아있고, 아래 두 자식(있으면)이 모두 제거됐는지
    public func isExposed(_ index: Int) -> Bool {
        guard pyramid.indices.contains(index), pyramid[index] != nil else { return false }
        let row = rowOf(index)
        guard row < Self.pyramidRows - 1 else { return true } // 맨 아래 줄은 항상 노출
        let pos = index - Self.rowStart(row)
        let childStart = Self.rowStart(row + 1)
        return pyramid[childStart + pos] == nil && pyramid[childStart + pos + 1] == nil
    }

    /// 글로벌 인덱스가 속한 줄 번호 (0~6)
    private func rowOf(_ index: Int) -> Int {
        var row = 0
        while Self.rowStart(row + 1) <= index { row += 1 }
        return row
    }

    /// 노출된 피라미드 카드 목록 (글로벌 인덱스 오름차순)
    public var exposedCards: [Card] {
        pyramid.indices.filter { isExposed($0) }.compactMap { pyramid[$0] }
    }

    /// 피라미드 카드의 글로벌 인덱스 (카드는 덱 내 유일)
    public func index(of card: Card) -> Int? {
        pyramid.firstIndex { $0 == card }
    }

    public var hasAnyMove: Bool {
        hint() != nil
    }

    // MARK: - 이동 검증

    public func canMove(_ move: Move) -> Bool {
        switch move {
        case let .pyramidRemovePair(first, second):
            guard first != second,
                  let ai = index(of: first),
                  let bi = index(of: second),
                  isExposed(ai), isExposed(bi) else { return false }
            return Self.cardValue(first) + Self.cardValue(second) == 13

        case let .pyramidRemoveWastePair(card):
            guard let ai = index(of: card), isExposed(ai),
                  let top = waste.last else { return false }
            return Self.cardValue(card) + Self.cardValue(top) == 13

        case let .pyramidRemoveSingle(card):
            guard let ai = index(of: card), isExposed(ai) else { return false }
            return Self.cardValue(card) == 13

        case .drawFromStock:
            return !stock.isEmpty

        // 다른 게임 전용 이동은 발생하지 않음
        case .columnToColumn, .columnToFreeCell, .freeCellToColumn, .columnToHome,
             .freeCellToHome, .homeToColumn, .homeToFreeCell, .recycleStock,
             .wasteToColumn, .wasteToFoundation, .flipColumnCard, .dealFromStock,
             .columnToWaste, .triPeaksRemove, .dealReserve:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(pyramid: pyramid, stock: stock, waste: waste, moveCount: moveCount))
        applyUnchecked(move)
        redoStack.removeAll()
        moveCount += 1
        return true
    }

    private mutating func applyUnchecked(_ move: Move) {
        switch move {
        case let .pyramidRemovePair(first, second):
            if let ai = index(of: first) { pyramid[ai] = nil }
            if let bi = index(of: second) { pyramid[bi] = nil }

        case let .pyramidRemoveWastePair(card):
            if let ai = index(of: card) { pyramid[ai] = nil }
            waste.removeLast()

        case let .pyramidRemoveSingle(card):
            if let ai = index(of: card) { pyramid[ai] = nil }

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
        redoStack.append(Snapshot(pyramid: pyramid, stock: stock, waste: waste, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(pyramid: pyramid, stock: stock, waste: waste, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        pyramid = snapshot.pyramid
        stock = snapshot.stock
        waste = snapshot.waste
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: K 단독 > 피라미드 짝 > 웨이스트 짝 > 드로)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []
        let exposed = exposedCards

        // 노출 K 단독 (13)
        for card in exposed where Self.cardValue(card) == 13 {
            moves.append(.pyramidRemoveSingle(card: card))
        }

        // 노출 피라미드 2장 합 13
        for i in exposed.indices {
            for j in (i + 1)..<exposed.count {
                let a = exposed[i]
                let b = exposed[j]
                if Self.cardValue(a) + Self.cardValue(b) == 13 {
                    moves.append(.pyramidRemovePair(first: a, second: b))
                }
            }
        }

        // 노출 피라미드 + 웨이스트 합 13
        if let top = waste.last {
            for card in exposed where Self.cardValue(card) + Self.cardValue(top) == 13 {
                moves.append(.pyramidRemoveWastePair(card: card))
            }
        }

        // 드로 (스톡 일회성 — 재활용 없음)
        if !stock.isEmpty {
            moves.append(.drawFromStock)
        }

        return moves
    }
}
