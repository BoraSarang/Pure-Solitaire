import Foundation

/// 월 달력 계산 — 데일리 도전 3개월(이전/현재/다음) 달력 표시용.
/// 날짜 산술은 그레고리력 로컬 달력 기준, 월 경계/연 경계를 안전하게 처리한다. (T-217)
public struct CalendarMonth: Equatable, Sendable {
    public let year: Int
    public let month: Int  // 1...12

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// 현재 날짜가 속한 월
    public static func current(date: Date = Date(), calendar: Calendar = .current) -> CalendarMonth {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return CalendarMonth(year: comps.year ?? 2026, month: comps.month ?? 1)
    }

    /// 이전 달 (연 경계 처리: 1월 → 전년 12월)
    public var previousMonth: CalendarMonth {
        if month == 1 { return CalendarMonth(year: year - 1, month: 12) }
        return CalendarMonth(year: year, month: month - 1)
    }

    /// 다음 달 (연 경계 처리: 12월 → 다음 해 1월)
    public var nextMonth: CalendarMonth {
        if month == 12 { return CalendarMonth(year: year + 1, month: 1) }
        return CalendarMonth(year: year, month: month + 1)
    }

    /// 현재 달 기준 ±1개월 3개월 목록 (이전/현재/다음)
    public static func rangeAround(_ month: CalendarMonth) -> [CalendarMonth] {
        [month.previousMonth, month, month.nextMonth]
    }

    /// 이 달의 첫 번째 날 (YYYY-MM-01)
    public func firstDate(calendar: Calendar = .current) -> Date {
        var comps = DateComponents()
        comps.calendar = calendar
        comps.year = year
        comps.month = month
        comps.day = 1
        comps.hour = 12
        return comps.date ?? Date()
    }

    /// 이 달의 일 수 (28/29/30/31)
    public func dayCount(calendar: Calendar = .current) -> Int {
        calendar.range(of: .day, in: .month, for: firstDate(calendar: calendar))?.count ?? 30
    }

    /// 이 달의 1일 요일 인덱스 (일=0, 월=1, ... 토=6) — 달력 셀 배치용
    public func firstWeekday(calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: firstDate(calendar: calendar)) - 1
    }

    /// 이 달의 특정 날짜 (day 1...dayCount)
    public func date(day: Int, calendar: Calendar = .current) -> Date {
        var comps = DateComponents()
        comps.calendar = calendar
        comps.year = year
        comps.month = month
        comps.day = min(max(day, 1), dayCount(calendar: calendar))
        comps.hour = 12
        return comps.date ?? Date()
    }

    /// 날짜가 이 달에 속하는지
    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return comps.year == year && comps.month == month
    }

    /// 이 달의 날짜별 완료 상태 (데일리 도전 9판 기준) — ChallengeStore 연동용
    /// returns: [day(1...dayCount): DayResult?]
    public func dailyResults(
        store: ChallengeStore,
        calendar: Calendar = .current
    ) -> [Int: ChallengeStore.DayResult?] {
        var result: [Int: ChallengeStore.DayResult?] = [:]
        for day in 1...dayCount(calendar: calendar) {
            let key = ChallengeStore.dateKey(for: date(day: day, calendar: calendar), calendar: calendar)
            result[day] = store.dayResult(for: key)
        }
        return result
    }
}

/// 월간 완료 통계 — 완료 판수/총 판수, 별 합계, 완료율, 변형별 분포 (T-217)
public struct MonthSummary: Equatable, Sendable {
    public let month: CalendarMonth
    public let completedCount: Int
    public let totalCount: Int
    public let totalStars: Int
    public let maxStars: Int
    /// 변형별 완료 판수
    public let variantCounts: [GameVariant: Int]

    public init(month: CalendarMonth, results: [ChallengeStore.DayResult?]) {
        self.month = month
        var completed = 0
        var total = 0
        var stars = 0
        var max = 0
        var counts: [GameVariant: Int] = [:]
        for day in results {
            guard let day else { continue }
            total += day.deals.count
            completed += day.completedCount
            stars += day.totalStars
            max += day.deals.count * 3
            for deal in day.deals where deal.stars > 0 {
                counts[deal.variant, default: 0] += 1
            }
        }
        completedCount = completed
        totalCount = total
        totalStars = stars
        maxStars = max
        variantCounts = counts
    }

    /// 완료율 0...1 (총 판수가 0이면 0)
    public var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    /// 별 획득률 0...1 (maxStars 0이면 0)
    public var starRate: Double {
        guard maxStars > 0 else { return 0 }
        return Double(totalStars) / Double(maxStars)
    }

    /// 월간 배지 (D) — 완료율 기준 브론즈/실버/골드/다이아몬드
    public var badge: MonthBadge {
        MonthBadge(completionRate: completionRate)
    }
}

/// 월간 완료 배지 — 완료율 25% 브론즈 / 50% 실버 / 75% 골드 / 100% 다이아몬드 (PLAN v3.21)
public enum MonthBadge: String, CaseIterable, Sendable {
    case bronze
    case silver
    case gold
    case diamond
    case none

    public init(completionRate: Double) {
        if completionRate >= 1.0 { self = .diamond }
        else if completionRate >= 0.75 { self = .gold }
        else if completionRate >= 0.5 { self = .silver }
        else if completionRate >= 0.25 { self = .bronze }
        else { self = .none }
    }

    public var displayName: String {
        switch self {
        case .bronze: "브론즈"
        case .silver: "실버"
        case .gold: "골드"
        case .diamond: "다이아몬드"
        case .none: "없음"
        }
    }
}