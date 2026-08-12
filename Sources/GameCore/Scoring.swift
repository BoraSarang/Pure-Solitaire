import Foundation

/// 점수 체계 — 표준 Klondike 점수 기준 + 변형별 상수 (순수 계산)
public enum Scoring {

    /// 이동별 점수. 점수 없는 이동(타블로 내 정렬 등)은 0.
    public static func moveScore(for move: Move, variant: GameVariant) -> Int {
        switch move {
        case .drawFromStock:
            return 5
        case .recycleStock:
            return -100
        case .flipColumnCard:
            return 5
        case .columnToHome, .wasteToFoundation, .freeCellToHome:
            return 10
        case .homeToColumn, .homeToFreeCell:
            return -15
        case .pyramidRemovePair, .pyramidRemoveSingle:
            return 10
        case .pyramidRemoveWastePair:
            return 5
        case .triPeaksRemove:
            return 5
        case .columnToWaste:
            return 5
        case .columnToColumn, .columnToFreeCell, .freeCellToColumn,
             .wasteToColumn, .dealFromStock, .dealReserve:
            return 0
        }
    }

    /// 스파이더 완성 보너스: 13장 완성 1회당 +100 (증가분은 VM에서 계산)
    public static let spiderCompleteBonus = 100

    /// 변형별 승리 보너스
    public static func winBonus(for variant: GameVariant) -> Int {
        switch variant {
        case .spider:
            return 800
        case .golf, .pyramid, .triPeaks:
            return 300
        case .freecell, .bakersGame, .seaTower, .superFreeCell,
             .klondike, .yukon, .fortyThieves, .scorpion:
            return 500
        }
    }

    /// 시간 보너스 — Klondike만 표준(10초마다 -2, 소수점 버림), 나머지 0
    public static func timeBonus(seconds: Double, variant: GameVariant) -> Int {
        guard variant == .klondike, seconds > 0 else { return 0 }
        let penalty = Int(seconds / 10) * 2
        return -penalty
    }

    /// 최종 점수 = 누적 이동 점수 + 승리 보너스 + 시간 보너스 (승리 시)
    public static func finalScore(moveTotal: Int, variant: GameVariant, seconds: Double) -> Int {
        moveTotal + winBonus(for: variant) + timeBonus(seconds: seconds, variant: variant)
    }
}
