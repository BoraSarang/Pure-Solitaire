import Foundation

/// 데일리 챌린지 — 하루 1개 고정 변형 + 별점(승리/시간/이동 수) 평가
public enum DailyChallenge {
    /// 날짜 → 오늘 챌린지 변형 (전체 변형 순환, 결정적)
    public static func variant(for date: Date, calendar: Calendar = .current) -> GameVariant {
        let days = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let all = GameVariant.allCases
        return all[days % all.count]
    }

    /// 오늘 챌린지 시드 (v3.16 DailyDeal 재사용)
    public static func gameNumber(for date: Date, calendar: Calendar = .current) -> Int {
        DailyDeal.gameNumber(for: date, variant: variant(for: date, calendar: calendar), calendar: calendar)
    }

    /// 챌린지 변형 (메시지 표시용)
    public static func challengeVariant(for date: Date, calendar: Calendar = .current) -> GameVariant {
        variant(for: date, calendar: calendar)
    }

    /// 시간 목표 (초) — 변형별 상수
    public static func timeTarget(for variant: GameVariant) -> Double {
        switch variant {
        case .freecell, .bakersGame, .seaTower, .superFreeCell: return 480
        case .klondike, .yukon: return 540
        case .spider, .fortyThieves: return 600
        case .golf, .pyramid, .triPeaks: return 420
        }
    }

    /// 이동 수 목표 — 변형별 상수
    public static func moveTarget(for variant: GameVariant) -> Int {
        switch variant {
        case .freecell, .bakersGame, .seaTower: return 120
        case .superFreeCell, .spider, .fortyThieves: return 260
        case .klondike, .yukon: return 220
        case .golf: return 80
        case .pyramid: return 90
        case .triPeaks: return 100
        }
    }

    /// 별점 — 승리 1 + 시간 목표 1 + 이동 수 목표 1 (최대 3)
    public static func stars(variant: GameVariant, isWin: Bool, seconds: Double, moves: Int) -> Int {
        guard isWin else { return 0 }
        var s = 1
        if seconds <= timeTarget(for: variant) { s += 1 }
        if moves <= moveTarget(for: variant) { s += 1 }
        return min(s, 3)
    }
}

/// 챌린지 완료 상태 저장 (UserDefaults) — 날짜별 1건
public final class ChallengeStore {
    public struct Result: Codable, Equatable {
        public let dateKey: String
        public let variantRaw: String
        public let stars: Int
        public let seconds: Double
        public let moves: Int

        public init(dateKey: String, variant: GameVariant, stars: Int, seconds: Double, moves: Int) {
            self.dateKey = dateKey
            self.variantRaw = variant.rawValue
            self.stars = stars
            self.seconds = seconds
            self.moves = moves
        }

        public var variant: GameVariant {
            GameVariant(rawValue: variantRaw) ?? .freecell
        }

        var dictionary: [String: Any] {
            ["dateKey": dateKey, "variantRaw": variantRaw, "stars": stars, "seconds": seconds, "moves": moves]
        }
    }

    private enum Keys {
        static func result(_ dateKey: String) -> String { "challenge.result.\(dateKey)" }
        static let current = "challenge.currentDate"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 날짜 키 (YYYY-MM-DD, 로컬 달력 기준)
    public static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// 오늘 챌린지 완료 결과 (없으면 nil)
    public func todayResult(date: Date = Date(), calendar: Calendar = .current) -> Result? {
        result(for: Self.dateKey(for: date, calendar: calendar))
    }

    public func result(for dateKey: String) -> Result? {
        guard let dict = defaults.dictionary(forKey: Keys.result(dateKey)),
              let starRaw = dict["stars"] as? Int,
              let variantRaw = dict["variantRaw"] as? String else { return nil }
        return Result(
            dateKey: dateKey,
            variant: GameVariant(rawValue: variantRaw) ?? .freecell,
            stars: starRaw,
            seconds: dict["seconds"] as? Double ?? 0,
            moves: dict["moves"] as? Int ?? 0
        )
    }

    /// 챌린지 완료 기록 (같은 날짜면 갱신 — 더 높은 별점 우선)
    @discardableResult
    public func record(_ newResult: ChallengeStore.Result) -> Bool {
        if let existing = result(for: newResult.dateKey), existing.stars >= newResult.stars {
            return false
        }
        defaults.set(newResult.dictionary, forKey: Keys.result(newResult.dateKey))
        return true
    }

    public func clearAll() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("challenge.") {
            defaults.removeObject(forKey: key)
        }
    }
}