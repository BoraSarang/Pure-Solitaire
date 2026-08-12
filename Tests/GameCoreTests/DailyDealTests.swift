import XCTest
@testable import GameCore

final class DailyDealTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = TimeZone(identifier: "UTC")
        comps.year = y
        comps.month = m
        comps.day = d
        return comps.date ?? Date()
    }

    private func number(_ y: Int, _ m: Int, _ d: Int, _ variant: GameVariant) -> Int {
        DailyDeal.gameNumber(for: date(y, m, d), variant: variant, calendar: calendar)
    }

    /// 같은 날짜 + 같은 변형 → 항상 같은 번호 (결정성)
    func testSameDateSameVariantIsDeterministic() {
        let a = number(2026, 8, 12, .freecell)
        let b = number(2026, 8, 12, .freecell)
        XCTAssertEqual(a, b)
    }

    /// 같은 날짜 + 다른 변형 → 서로 다른 번호
    func testVariantsDifferOnSameDate() {
        var seen = Set<Int>()
        for variant in GameVariant.allCases {
            let n = number(2026, 8, 12, variant)
            XCTAssertFalse(seen.contains(n), "변형 \(variant.rawValue) 시드 충돌")
            seen.insert(n)
        }
    }

    /// 다른 날짜 → 다른 번호 (연속 3일 샘플)
    func testDifferentDatesDiffer() {
        var seen = Set<Int>()
        for day in 10...12 {
            let n = number(2026, 8, day, .freecell)
            XCTAssertFalse(seen.contains(n), "날짜 8/\(day) 시드 중복")
            seen.insert(n)
        }
    }

    /// 결과는 항상 유효 게임 번호 범위 (1...maxGameNumber)
    func testRange() {
        for day in 1...31 {
            for variant in GameVariant.allCases {
                let n = number(2026, 8, day, variant)
                XCTAssertGreaterThanOrEqual(n, DealGenerator.minGameNumber)
                XCTAssertLessThanOrEqual(n, DealGenerator.maxGameNumber)
            }
        }
    }

    /// 고정 회귀값 — UTC 그레고리안 캘린더 기준, 미래에도 동일해야 함 (해시 변경 감지)
    func testFixedRegressionValues() {
        XCTAssertEqual(number(2026, 8, 12, .freecell), 31_149)
        XCTAssertEqual(number(2026, 8, 12, .klondike), 173_480)
    }
}