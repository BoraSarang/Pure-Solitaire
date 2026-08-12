/// 프리셀에서 발생 가능한 모든 이동
public enum Move: Equatable, Sendable {
    /// 타블로 → 타블로 (수퍼무브 포함, cardCount 장)
    case columnToColumn(from: Int, to: Int, cardCount: Int)
    /// 타블로 → 프리셀
    case columnToFreeCell(columnIndex: Int, freeCellIndex: Int, card: Card)
    /// 프리셀 → 타블로
    case freeCellToColumn(freeCellIndex: Int, columnIndex: Int, card: Card)
    /// 타블로 → 홈셀
    case columnToHome(columnIndex: Int, card: Card)
    /// 프리셀 → 홈셀
    case freeCellToHome(freeCellIndex: Int, card: Card)
    /// 홈셀 → 타블로 (MS 규칙: 홈셀에서 꺼내기 허용)
    case homeToColumn(homeIndex: Int, columnIndex: Int, card: Card)
    /// 홈셀 → 프리셀
    case homeToFreeCell(homeIndex: Int, freeCellIndex: Int, card: Card)
    /// Klondike: 스톡에서 카드 1장 드로 → 웨이스트
    case drawFromStock
    /// Klondike: 스톡이 비면 웨이스트를 역순으로 스톡에 재활용
    case recycleStock
    /// Klondike: 웨이스트 → 타블로 열
    case wasteToColumn(columnIndex: Int, card: Card)
    /// Klondike: 웨이스트 → 홈셀
    case wasteToFoundation(card: Card)
    /// Klondike: 뒤집힌 타블로 카드 뒤집기 (열 index, 카드)
    case flipColumnCard(columnIndex: Int, card: Card)
    /// Spider: 스톡에서 각 열에 1장씩 앞면 딜
    case dealFromStock
    /// Golf: 타블로 열 맨 아래 카드를 웨이스트로 제거 (열 index, 카드)
    case columnToWaste(columnIndex: Int, card: Card)
    /// Pyramid: 노출 피라미드 카드 2장의 합이 13 → 둘 다 제거 (카드 2장)
    case pyramidRemovePair(first: Card, second: Card)
    /// Pyramid: 노출 피라미드 카드 + 웨이스트 맨 위 카드의 합이 13 → 둘 다 제거 (피라미드 카드)
    case pyramidRemoveWastePair(card: Card)
    /// Pyramid: 노출 피라미드 K 단독(13) 제거 (카드)
    case pyramidRemoveSingle(card: Card)
    /// TriPeaks: 노출 피크 카드를 웨이스트로 제거 (웨이스트 맨 위와 정확히 1 랭크 차이, 카드)
    case triPeaksRemove(card: Card)
    /// Scorpion: 예비 3장을 열 0,1,2에 앞면으로 딜 (1회만)
    case dealReserve

    /// 홈셀로 이동하는 동작인지 여부
    public var isHomeMove: Bool {
        switch self {
        case .columnToHome, .freeCellToHome, .wasteToFoundation: true
        default: false
        }
    }
}
