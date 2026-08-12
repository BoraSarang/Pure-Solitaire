/// TriPeaks(트리피크스) 게임 상태 + 이동 적용 + 실행 취소/다시 실행
///
/// - 1덱 52장, 3개 피크(각 4줄: 1+2+3+4 = 10장 × 3 = 30장), 웨이스트 1장(딜 시 오픈), 스톡 21장
/// - 노출 카드: 각 피크의 마지막 줄(4번째 줄)은 항상 노출, 위 줄 카드는 아래 두 자식이 모두 제거됐을 때만 노출
/// - 이동: 노출 카드가 웨이스트 맨 위와 정확히 1 랭크 차이(수트 무관, 같은 랭크·K↔A 순환 제외)면 제거
/// - 승리: 3개 피크 30장 전부 제거
public struct TriPeaksGame: Equatable, Sendable, Codable {
    /// 피크 카드 (글로벌 인덱스 0~29, peak*10 + local, local = rowStart(row)+pos, rowStart = [0,1,3,6]). nil = 제거됨.
    public internal(set) var peaks: [Card?]
    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public let gameNumber: Int
    public private(set) var moveCount: Int = 0
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    private struct Snapshot: Equatable, Codable {
        var peaks: [Card?]
        var stock: [Card]
        var waste: [Card]
        var moveCount: Int
    }

    public static let peakCount = 3
    public static let rowsPerPeak = 4
    public static var cardsPerPeak: Int { rowsPerPeak * (rowsPerPeak + 1) / 2 } // 10
    public static var totalPeaksCount: Int { peakCount * cardsPerPeak } // 30

    /// 피크 내 local row의 첫 로컬 인덱스
    public static func rowStart(_ row: Int) -> Int { row * (row + 1) / 2 }

    public init(gameNumber: Int) {
        self.gameNumber = gameNumber
        let deal = DealGenerator.triPeaksDeal(gameNumber: gameNumber)
        self.peaks = deal.peaks.map { Optional($0) }
        self.stock = deal.stock
        self.waste = deal.waste
    }

    // MARK: - 조회

    public var isWon: Bool {
        peaks.allSatisfy { $0 == nil }
    }

    /// 피크 번호 (0~2)와 피크 내 로컬 인덱스
    public static func peakAndLocal(of index: Int) -> (peak: Int, local: Int) {
        (index / cardsPerPeak, index % cardsPerPeak)
    }

    /// 글로벌 인덱스가 노출 카드인지: 카드가 남아있고, 아래 두 자식(있으면)이 모두 제거됐는지
    public func isExposed(_ index: Int) -> Bool {
        guard peaks.indices.contains(index), peaks[index] != nil else { return false }
        let (_, local) = Self.peakAndLocal(of: index)
        let row = rowOf(local)
        guard row < Self.rowsPerPeak - 1 else { return true } // 마지막 줄은 항상 노출
        let pos = local - Self.rowStart(row)
        let childStart = Self.rowStart(row + 1)
        let base = (index / Self.cardsPerPeak) * Self.cardsPerPeak
        return peaks[base + childStart + pos] == nil && peaks[base + childStart + pos + 1] == nil
    }

    /// 피크 내 로컬 인덱스의 줄 번호 (0~3)
    private func rowOf(_ local: Int) -> Int {
        var row = 0
        while Self.rowStart(row + 1) <= local { row += 1 }
        return row
    }

    /// 노출된 피크 카드 목록 (글로벌 인덱스 오름차순)
    public var exposedCards: [Card] {
        peaks.indices.filter { isExposed($0) }.compactMap { peaks[$0] }
    }

    /// 피크 카드의 글로벌 인덱스 (카드는 덱 내 유일)
    public func index(of card: Card) -> Int? {
        peaks.firstIndex { $0 == card }
    }

    /// 웨이스트 맨 위 카드와 정확히 1 랭크 차이인지 (수트 무관, 같은 랭크·K↔A 순환 제외)
    public func isOneRankAdjacent(_ card: Card, to top: Card) -> Bool {
        abs(card.rank.rawValue - top.rank.rawValue) == 1
    }

    public var hasAnyMove: Bool {
        hint() != nil
    }

    // MARK: - 이동 검증

    public func canMove(_ move: Move) -> Bool {
        switch move {
        case let .triPeaksRemove(card):
            guard let i = index(of: card), isExposed(i),
                  let top = waste.last else { return false }
            return isOneRankAdjacent(card, to: top)

        case .drawFromStock:
            return !stock.isEmpty

        // 다른 게임 전용 이동은 발생하지 않음
        case .columnToColumn, .columnToFreeCell, .freeCellToColumn, .columnToHome,
             .freeCellToHome, .homeToColumn, .homeToFreeCell, .recycleStock,
             .wasteToColumn, .wasteToFoundation, .flipColumnCard, .dealFromStock,
             .columnToWaste, .pyramidRemovePair, .pyramidRemoveWastePair, .pyramidRemoveSingle, .dealReserve:
            return false
        }
    }

    // MARK: - 이동 적용

    @discardableResult
    public mutating func apply(_ move: Move) -> Bool {
        guard canMove(move) else { return false }
        undoStack.append(Snapshot(peaks: peaks, stock: stock, waste: waste, moveCount: moveCount))
        applyUnchecked(move)
        redoStack.removeAll()
        moveCount += 1
        return true
    }

    private mutating func applyUnchecked(_ move: Move) {
        switch move {
        case let .triPeaksRemove(card):
            if let i = index(of: card) { peaks[i] = nil }
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
        redoStack.append(Snapshot(peaks: peaks, stock: stock, waste: waste, moveCount: moveCount))
        restore(prev)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(Snapshot(peaks: peaks, stock: stock, waste: waste, moveCount: moveCount))
        restore(next)
    }

    private mutating func restore(_ snapshot: Snapshot) {
        peaks = snapshot.peaks
        stock = snapshot.stock
        waste = snapshot.waste
        moveCount = snapshot.moveCount
    }

    // MARK: - 힌트

    /// 유효한 이동 하나 (우선순위: 피크 제거 > 드로)
    public func hint() -> Move? {
        hintCandidates().first
    }

    public func hintCandidates() -> [Move] {
        var moves: [Move] = []
        let exposed = exposedCards

        // 웨이스트와 1 랭크 차이인 노출 카드 제거 (왼쪽 인덱스부터)
        if let top = waste.last {
            for card in exposed where isOneRankAdjacent(card, to: top) {
                moves.append(.triPeaksRemove(card: card))
            }
        }

        // 드로 (스톡 일회성 — 재활용 없음)
        if !stock.isEmpty {
            moves.append(.drawFromStock)
        }

        return moves
    }
}
