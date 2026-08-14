import Foundation

/// 데일리 챌린지 — 하루 9판(12종 중 9개 결정적 샘플링) + 별점(승리/시간/이동 수) 평가
public enum DailyChallenge {
    /// 데일리 챌린지 판 1개 — 변형 + 게임 번호
    public struct Deal: Equatable, Sendable {
        public let variant: GameVariant
        public let number: Int

        public init(variant: GameVariant, number: Int) {
            self.variant = variant
            self.number = number
        }
    }

    /// 하루 챌린지 판 수 (12종 중 9개)
    public static let dealsPerDay = 9

    /// 날짜 → 오늘 챌린지 9판 (12종 중 9개를 날짜 시드로 결정적 셔플 후 선택, 중복 없음, 순서 결정적)
    /// 각 변형의 게임 번호는 DailyDeal.gameNumber 재사용.
    public static func deals(for date: Date, calendar: Calendar = .current) -> [Deal] {
        let days = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        var variants = GameVariant.allCases
        seededShuffle(&variants, seed: UInt64(days))
        let chosen = Array(variants.prefix(dealsPerDay))
        return chosen.map { Deal(variant: $0, number: DailyDeal.gameNumber(for: date, variant: $0, calendar: calendar)) }
    }

    /// 결정적 셔플 (Fisher-Yates, 날짜 기반 시드) — 같은 날짜면 항상 같은 순서
    private static func seededShuffle(_ array: inout [GameVariant], seed: UInt64) {
        var state = seed &* 0x9E37_79B9_7F4A_7C15 &+ 0xBF58_476D_1CE4_E5B9
        func nextRandom() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = Int(nextRandom() % UInt64(i + 1))
            array.swapAt(i, j)
        }
    }

    /// 날짜 → 오늘 챌린지 변형 (전체 변형 순환, 결정적) — 기존 단건 챌린지 호환
    public static func variant(for date: Date, calendar: Calendar = .current) -> GameVariant {
        let days = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let all = GameVariant.allCases
        return all[days % all.count]
    }

    /// 오늘 챌린지 시드 (v3.16 DailyDeal 재사용) — 기존 단건 챌린지 호환
    public static func gameNumber(for date: Date, calendar: Calendar = .current) -> Int {
        DailyDeal.gameNumber(for: date, variant: variant(for: date, calendar: calendar), calendar: calendar)
    }

    /// 챌린지 변형 (메시지 표시용) — 기존 단건 챌린지 호환
    public static func challengeVariant(for date: Date, calendar: Calendar = .current) -> GameVariant {
        variant(for: date, calendar: calendar)
    }

    /// 시간 목표 (초) — 변형별 상수
    public static func timeTarget(for variant: GameVariant) -> Double {
        switch variant {
        case .freecell, .bakersGame, .seaTower, .superFreeCell: return 480
        case .klondike, .yukon: return 540
        case .spider, .fortyThieves, .scorpion: return 600
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
        case .scorpion: return 240
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

/// 챌린지 완료 상태 저장 (UserDefaults) — 날짜별 9판 기록 (기존 단건 저장과 호환)
public final class ChallengeStore {
    /// 기존 단건 결과 (v3.16 이전 호환) — 유지
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

    // MARK: - 9판 기록 (T-216)

    /// 데일리 챌린지 판 1개의 완료 결과 (9판 배열의 요소)
    public struct DealResult: Codable, Equatable, Sendable {
        public let variantRaw: String
        public let number: Int
        public let stars: Int
        public let seconds: Double
        public let moves: Int

        public init(variant: GameVariant, number: Int, stars: Int, seconds: Double, moves: Int) {
            self.variantRaw = variant.rawValue
            self.number = number
            self.stars = stars
            self.seconds = seconds
            self.moves = moves
        }

        public var variant: GameVariant {
            GameVariant(rawValue: variantRaw) ?? .freecell
        }
    }

    /// 날짜별 9판 완료 기록 — dateKey당 deals 배열
    public struct DayResult: Codable, Equatable, Sendable {
        public let dateKey: String
        public var deals: [DealResult]

        public init(dateKey: String, deals: [DealResult]) {
            self.dateKey = dateKey
            self.deals = deals
        }

        /// 별 합계 (0...27)
        public var totalStars: Int {
            deals.reduce(0) { $0 + $1.stars }
        }

        /// 완료(승리) 판 수
        public var completedCount: Int {
            deals.filter { $0.stars > 0 }.count
        }
    }

    private enum DealsKeys {
        static func result(_ dateKey: String) -> String { "challenge.deals.\(dateKey)" }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// 날짜별 9판 완료 기록 (새 구조 우선, 없으면 기존 단건 → 9판 단일 변환)
    public func dayResult(for dateKey: String) -> DayResult? {
        if let data = defaults.data(forKey: DealsKeys.result(dateKey)),
           let day = try? decoder.decode(DayResult.self, from: data) {
            return day
        }
        // 기존 단건 저장 호환: 단일 판 결과를 9판 구조로 변환
        guard let legacy = result(for: dateKey) else { return nil }
        return DayResult(dateKey: dateKey, deals: [
            DealResult(variant: legacy.variant, number: 0, stars: legacy.stars, seconds: legacy.seconds, moves: legacy.moves)
        ])
    }

    /// 오늘 9판 완료 기록
    public func todayDayResult(date: Date = Date(), calendar: Calendar = .current) -> DayResult? {
        dayResult(for: Self.dateKey(for: date, calendar: calendar))
    }

    /// 판 결과 기록 — 같은 날짜·같은 판(변형+번호)은 더 높은 별점 우선 갱신, 없으면 추가
    @discardableResult
    public func recordDeal(_ newResult: DealResult, for dateKey: String) -> Bool {
        var day = dayResult(for: dateKey) ?? DayResult(dateKey: dateKey, deals: [])
        if let idx = day.deals.firstIndex(where: { $0.variantRaw == newResult.variantRaw && $0.number == newResult.number }) {
            guard day.deals[idx].stars < newResult.stars else { return false }
            day.deals[idx] = newResult
        } else {
            day.deals.append(newResult)
        }
        guard let data = try? encoder.encode(day) else { return false }
        defaults.set(data, forKey: DealsKeys.result(dateKey))
        return true
    }
}