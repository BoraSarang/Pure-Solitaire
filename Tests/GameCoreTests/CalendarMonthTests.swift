import XCTest
@testable import GameCore

/// CalendarMonth — 달력 월 산술/월 통계/월 배지 테스트 (T-217)
final class CalendarMonthTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.year = y
        comps.month = m
        comps.day = d
        comps.hour = 12
        return comps.date ?? Date()
    }

    /// 월 경계 (1월 → 전년 12월)
    func testJanuaryPreviousMonth() {
        let jan = CalendarMonth(year: 2026, month: 1)
        XCTAssertEqual(jan.previousMonth, CalendarMonth(year: 2025, month: 12))
    }

    /// 월 경계 (12월 → 다음 해 1월)
    func testDecemberNextMonth() {
        let dec = CalendarMonth(year: 2026, month: 12)
        XCTAssertEqual(dec.nextMonth, CalendarMonth(year: 2027, month: 1))
    }

    /// 3개월 목록 = 이전/현재/다음
    func testRangeAround() {
        let middle = CalendarMonth(year: 2026, month: 8)
        let range = CalendarMonth.rangeAround(middle)
        XCTAssertEqual(range, [
            CalendarMonth(year: 2026, month: 7),
            CalendarMonth(year: 2026, month: 8),
            CalendarMonth(year: 2026, month: 9),
        ])
    }

    /// 일 수 (2월 윤년/평년)
    func testDayCount() {
        XCTAssertEqual(CalendarMonth(year: 2026, month: 2).dayCount(), 28)
        XCTAssertEqual(CalendarMonth(year: 2024, month: 2).dayCount(), 29)
        XCTAssertEqual(CalendarMonth(year: 2026, month: 4).dayCount(), 30)
        XCTAssertEqual(CalendarMonth(year: 2026, month: 12).dayCount(), 31)
    }

    /// 날짜 포함 여부
    func testContains() {
        let month = CalendarMonth(year: 2026, month: 8)
        XCTAssertTrue(month.contains(date(2026, 8, 15)))
        XCTAssertFalse(month.contains(date(2026, 7, 31)))
        XCTAssertFalse(month.contains(date(2026, 9, 1)))
    }

    /// MonthSummary — 완료 판수/총 판수/별 합계/배지
    func testMonthSummary() {
        let results: [ChallengeStore.DayResult?] = [
            // 2판 중 1판 완료, 별 3+0
            ChallengeStore.DayResult(dateKey: "2026-08-01", deals: [
                ChallengeStore.DealResult(variant: .freecell, number: 1, stars: 3, seconds: 300, moves: 100),
                ChallengeStore.DealResult(variant: .spider, number: 2, stars: 0, seconds: 0, moves: 0),
            ]),
            // 2판 모두 완료, 별 2+3
            ChallengeStore.DayResult(dateKey: "2026-08-02", deals: [
                ChallengeStore.DealResult(variant: .golf, number: 3, stars: 2, seconds: 400, moves: 150),
                ChallengeStore.DealResult(variant: .klondike, number: 4, stars: 3, seconds: 500, moves: 200),
            ]),
            // 완료 안 한 날
            nil,
        ]
        let summary = MonthSummary(month: CalendarMonth(year: 2026, month: 8), results: results)
        XCTAssertEqual(summary.completedCount, 3)
        XCTAssertEqual(summary.totalCount, 4)
        XCTAssertEqual(summary.totalStars, 8)
        XCTAssertEqual(summary.maxStars, 12)
        XCTAssertEqual(summary.variantCounts[.freecell], 1)
        XCTAssertEqual(summary.variantCounts[.golf], 1)
        XCTAssertNil(summary.variantCounts[.spider])
    }

    /// 월 배지 — 완료율 25/50/75/100 경계
    func testBadgeBoundaries() {
        XCTAssertEqual(MonthBadge(completionRate: 0.24), .none)
        XCTAssertEqual(MonthBadge(completionRate: 0.25), .bronze)
        XCTAssertEqual(MonthBadge(completionRate: 0.5), .silver)
        XCTAssertEqual(MonthBadge(completionRate: 0.75), .gold)
        XCTAssertEqual(MonthBadge(completionRate: 1.0), .diamond)
    }
}