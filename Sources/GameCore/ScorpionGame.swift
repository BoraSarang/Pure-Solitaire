/// Scorpion(스콜피온) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 7개 타블로 열 (7장씩, 앞 4열은 밑 3장 뒤집힘 / 뒤 3열 전부 앞면), 예비 3장
/// - 규칙: 같은 수트 + 한 단계 낮은 카드 위로만, 앞면 카드와 그 위 전부를 그룹 이동(Yukon식),
///   빈 열엔 K만, 노출된 뒤집힌 카드는 자동 앞면, 예비 3장은 스톡 클릭 시 1회만 열 0,1,2에 딜
/// - 홈셀 없음 — 승리: 열 4개가 각각 같은 수트 K→A 완성 시퀀스
public struct ScorpionGame: Equatable, Sendable, Codable {
    public internal(set) var columns: [[KlondikeGame.ColumnCard]]
    public internal(set) var reserve: [Card]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    public private(set) var reserveDealt = false
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var columns: [[KlondikeGame.ColumnCard]]
        var reserve: [Card]
        var moveCount: Int
        var reserveDealt: Bool
    }

    public static let columnCount = 7

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        let deal = DealGenerator.scorpionDeal(gameNumber: gameNumber)
        self.columns = deal.columns
        self.reserve = deal.reserve
    }

    // MARK: - 조회

    public var isWon: Bool {
        completedSequencesCount == 4
    }

    /// 완성된 같은 수트 K→A 시퀀스(13장) 개수 — 각 열에서 위(맨 끝)를 포함해 검사
    public var completedSequencesCount: Int {
        columns.reduce(0) { count, column in
            count + (isCompleteColumn(column) ? 1 : 0)
        }
    }

    /// 열 전체가 같은 수트 K→A 내림차순 완성 시퀀스인지
    private func isCompleteColumn(_ column: [KlondikeGame.ColumnCard]) -> Bool {
        guard column.count == 13 else { return false }
        var expected = Rank.king
        for cc in column {
            guard cc.faceUp, cc.card.rank == expected else { return false }
            guard let next = expected.previous else { return true }  // A까지 확인 완료
            expected = next
        }
        return false
    }

    public var canAutoFinish: Bool { false }

    /// 열에 놓을 수 있는지 — 같은 수트 + 정확히 한 단계 낮은 카드, 빈 열엔 K만
    public func canPlaceOnColumn(_ card: Card, column: Int) -> Bool {
        guard columns.indices.contains(column) else { return false }
        guard let top = columns[column].last else { return card.rank == .king }
        return top.card.suit == card.suit && card.rank == top.card.rank.previous
    }

    /// 시작 위치(앞면 카드)부터 그 위 전부를 그룹으로 반환 (위 카드 순서 무관)
    public func movableGroup(from column: Int, startIndex: Int) -> [Card]? {
        guard columns.indices.contains(column),
              startIndex >= 0,
              startIndex < columns[column].count,
              columns[column][startIndex].faceUp else { return nil }
        return columns[column][startIndex...].map { $0.card }
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
            let group = movableGroup(from: from, startIndex: startIndex) ?? []
            guard group.count >= cardCount, let bottom = group.first else { return false }
            return canPlaceOnColumn(bottom, column: to)

        case .dealReserve:
            return !reserveDealt && !reserve.isEmpty

        // 홈/웨이스트/드로/뒤집기 없음
        case .columnToHome, .wasteToFoundation, .wasteToColumn, .drawFromStock,
             .recycleStock, .flipColumnCard, .dealFromStock, .columnToWaste,
             .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle,
             .triPeaksRemove, .columnToFreeCell, .freeCellToColumn, .freeCellToHome,
             .homeToColumn, .homeToFreeCell:
            return false

        default:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(columns: columns, reserve: reserve, moveCount: moveCount, reserveDealt: reserveDealt))
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

        case .dealReserve:
            for i in 0..<min(reserve.count, 3) {
                columns[i].append(KlondikeGame.ColumnCard(card: reserve[i], faceUp: true))
            }
            reserve.removeAll()
            reserveDealt = true

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
        redoStack.append(Snapshot(columns: columns, reserve: reserve, moveCount: moveCount, reserveDealt: reserveDealt))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(columns: columns, reserve: reserve, moveCount: moveCount, reserveDealt: reserveDealt))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        columns = snapshot.columns
        reserve = snapshot.reserve
        moveCount = snapshot.moveCount
        reserveDealt = snapshot.reserveDealt
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 열→열 그룹 > 예비 딜)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []

        // 열 → 열 (앞면 카드마다 그룹 이동)
        for from in columns.indices {
            for startIndex in columns[from].indices where columns[from][startIndex].faceUp {
                let cardCount = columns[from].count - startIndex
                for to in columns.indices where to != from && canMove(.columnToColumn(from: from, to: to, cardCount: cardCount)) {
                    moves.append(.columnToColumn(from: from, to: to, cardCount: cardCount))
                }
            }
        }

        // 예비 딜 (1회)
        if canMove(.dealReserve) {
            moves.append(.dealReserve)
        }

        return moves
    }
}
