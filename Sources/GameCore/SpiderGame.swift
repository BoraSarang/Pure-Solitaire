/// Spider(스파이더) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 10개 타블로 열(뒤집힌 카드 포함), 스톡 5더미(각 10장), 홈셀 없음
/// - 2덱(104장). 난이도(수트 수)별 구성: 1수트 8세트 / 2수트 4세트씩 / 4수트 2세트씩
/// - 규칙: 같은 수트 내림차순(K→A) 시퀀스만 이동, 빈 열엔 아무 카드/시퀀스,
///   한 열에 K→A 같은 수트 13장 완성 시 자동 제거(완성 수트 +1),
///   스톡 클릭 시 각 열에 1장씩 앞면 딜
/// - 승리: 완성 수트 8개
public struct SpiderGame: Equatable, Sendable, Codable {
    /// 난이도(사용 수트 수)
    public enum Difficulty: Int, CaseIterable, Sendable, Codable, Equatable {
        case oneSuit = 1
        case twoSuits = 2
        case fourSuits = 4

        public var suitCount: Int { rawValue }

        public var displayName: String {
            switch self {
            case .oneSuit: "초급 (1수트)"
            case .twoSuits: "중급 (2수트)"
            case .fourSuits: "고급 (4수트)"
            }
        }
    }

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
    public let gameNumber: Int
    public let difficulty: Difficulty
    public private(set) var completedSuits: Int = 0
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[ColumnCard]]
        var stock: [Card]
        var completedSuits: Int
        var moveCount: Int
    }

    public static let columnCount = 10
    public static let completedSuitsToWin = 8

    public init(gameNumber: Int, difficulty: Difficulty = .fourSuits) {
        self.gameNumber = gameNumber
        self.difficulty = difficulty
        let cards = DealGenerator.spiderCards(gameNumber: gameNumber, suitCount: difficulty.suitCount)
        var columns = Array(repeating: [ColumnCard](), count: Self.columnCount)
        var index = 0
        for col in 0..<Self.columnCount {
            let count = col < 4 ? 6 : 5
            for _ in 0..<count {
                columns[col].append(ColumnCard(card: cards[index], faceUp: false))
                index += 1
            }
            columns[col][columns[col].count - 1].faceUp = true
        }
        self.columns = columns
        self.stock = Array(cards[index...])
    }

    // MARK: - 조회

    public var isWon: Bool {
        completedSuits == Self.completedSuitsToWin
    }

    /// 열에 놓을 수 있는지 (빈 열엔 아무 카드, 아니면 랭크 한 단계 낮은 카드)
    public func canPlaceOnColumn(_ card: Card, column: Int) -> Bool {
        guard columns.indices.contains(column) else { return false }
        guard let top = columns[column].last else { return true }
        return card.rank == top.card.rank.previous
    }

    /// 타블로 열 맨 아래 앞면 카드 시퀀스 추출 (bottom→top, 같은 수트 내림차순)
    public func movableRun(from column: Int) -> [Card] {
        guard columns.indices.contains(column) else { return [] }
        var run: [Card] = []
        for cc in columns[column].reversed() {
            guard cc.faceUp else { break }
            if run.isEmpty {
                run.append(cc.card)
            } else if let top = run.last,
                      cc.card.rank == top.rank.next,
                      cc.card.suit == top.suit {
                run.append(cc.card)
            } else {
                break
            }
        }
        return Array(run.reversed())
    }

    /// 스톡에 카드가 남아 딜할 수 있는지
    public var canDealFromStock: Bool {
        !stock.isEmpty
    }

    /// 이동 가능한 수가 하나라도 있는지
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
            // 선택된 부분 시퀀스의 맨 아래 카드로 판정 (전체 run 맨 아래가 아님)
            return canPlaceOnColumn(moving[moving.count - cardCount], column: to)

        case .dealFromStock:
            return canDealFromStock

        default:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, stock: stock, completedSuits: completedSuits, moveCount: moveCount))
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

        case .dealFromStock:
            for i in columns.indices {
                guard let card = stock.popLast() else { break }
                columns[i].append(ColumnCard(card: card, faceUp: true))
            }

        default:
            break
        }
        removeCompletedSequences()
    }

    /// 열 맨 위가 뒤집힌 카드면 앞면으로 뒤집는다
    private mutating func flipTopIfNeeded(column: Int) {
        guard let last = columns[column].last, !last.faceUp else { return }
        columns[column][columns[column].count - 1].faceUp = true
    }

    /// 각 열에서 K→A 같은 수트 13장 완성 시퀀스를 찾아 제거하고 완성 수트를 센다
    private mutating func removeCompletedSequences() {
        for col in columns.indices {
            var i = 0
            while i < columns[col].count {
                if isCompleteSequenceStart(column: col, start: i) {
                    columns[col].removeSubrange(i..<(i + 13))
                    completedSuits += 1
                } else {
                    i += 1
                }
            }
        }
    }

    /// start 위치부터 13장이 같은 수트 K→A 완성 시퀀스인지
    private func isCompleteSequenceStart(column: Int, start: Int) -> Bool {
        let cards = columns[column]
        guard start + 13 <= cards.count else { return false }
        for offset in 0..<13 {
            let cc = cards[start + offset]
            guard cc.faceUp else { return false }
            let expectedRank = Rank(rawValue: 13 - offset)!
            guard cc.card.rank == expectedRank else { return false }
            guard cc.card.suit == cards[start].card.suit else { return false }
        }
        return true
    }

    // MARK: - 실행 취소 / 다시 실행

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(Snapshot(columns: columns, stock: stock, completedSuits: completedSuits, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, stock: stock, completedSuits: completedSuits, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        stock = snapshot.stock
        completedSuits = snapshot.completedSuits
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 완성 수트 만들 이동 > 시퀀스 이동 > 1장 이동 > 스톡 딜)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 열 → 열 (시퀀스 이동, 카드 수 큰 순)
        for from in columns.indices {
            let run = movableRun(from: from)
            guard !run.isEmpty else { continue }
            for to in columns.indices where to != from {
                for count in stride(from: run.count, through: 1, by: -1) {
                    if canMove(.columnToColumn(from: from, to: to, cardCount: count)) {
                        moves.append(.columnToColumn(from: from, to: to, cardCount: count))
                        break
                    }
                }
            }
        }

        // 스톡 딜
        if canDealFromStock {
            moves.append(.dealFromStock)
        }

        return moves
    }
}
