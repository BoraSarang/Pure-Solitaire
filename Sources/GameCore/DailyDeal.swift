import Foundation

/// 데일리 딜 — 날짜(YYYY-MM-DD)를 결정적 시드로 변환해 하루 1개 고정 게임 제공
public enum DailyDeal {
    /// 날짜 + 변형 → 고정 게임 번호 (1...DealGenerator.maxGameNumber)
    /// 같은 날짜·같은 변형이면 항상 같은 번호, 변형이 다르면 서로 다른 번호.
    public static func gameNumber(for date: Date, variant: GameVariant, calendar: Calendar = .current) -> Int {
        let days = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let variantSalt = variant.rawValue.unicodeScalars.reduce(UInt64(5381)) {
            ($0 &* 33) &+ UInt64($1.value)
        }
        var x = UInt64(days) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* (0xBF58_476D_1CE4_E5B9 &+ variantSalt)
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        x = x ^ (x >> 31)
        let max = UInt64(DealGenerator.maxGameNumber)
        return Int((x % max) + 1)
    }
}
