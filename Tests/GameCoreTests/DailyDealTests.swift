import XCTest
@testable import GameCore

final class DailyDealTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.year = y
        comps.month = m
        comps.day = d
        return comps.date ?? Date()
    }

    /// 같은 날짜 + 같은 변형 → 항상 같은 번호 (결정성)
    func testSameDateSameVariantIsDeterministic() {
        let d = date(2026, 8, 12)
        let a = DailyDeal.gameNumber(for: d, variant: .freecell)
        let b = DailyDeal.gameNumber(for: d, variant: .freecell)
        XCTAssertEqual(a, b)
    }

    /// 같은 날짜 + 다른 변형 → 서로 다른 번호
    func testVariantsDifferOnSameDate() {
        let d = date(2026, 8, 12)
        var seen = Set<Int>()
        for variant in GameVariant.allCases {
            let n = DailyDeal.gameNumber(for: d, variant: variant)
            XCTAssertFalse(seen.contains(n), "변형 \(variant.rawValue) 시드 충돌")
            seen.insert(n)
        }
    }

    /// 다른 날짜 → 다른 번호 (연속 3일 샘플)
    func testDifferentDatesDiffer() {
        var seen = Set<Int>()
        for day in 10...12 {
            let n = DailyDeal.gameNumber(for: date(2026, 8, day), variant: .freecell)
            XCTAssertFalse(seen.contains(n), "날짜 8/\(day) 시드 중복")
            seen.insert(n)
        }
    }

    /// 결과는 항상 유효 게임 번호 범위 (1...maxGameNumber)
    func testRange() {
        for day in 1...31 {
            for variant in GameVariant.allCases {
                let n = DailyDeal.gameNumber(for: date(2026, 8, day), variant: variant)
                XCTAssertGreaterThanOrEqual(n, DealGenerator.minGameNumber)
                XCTAssertLessThanOrEqual(n, DealGenerator.maxGameNumber)
            }
        }
    }

    /// 고정 회귀값 — 동일 날짜의 번호가 미래에도 동일해야 함 (해시 변경 감지)
    func testFixedRegressionValues() {
        XCTAssertEqual(DailyDeal.gameNumber(for: date(2026, 8, 12), variant: .freecell), 858_146)
        XCTAssertEqual(DailyDeal.gameNumber(for: date(2026, 8, 12), variant: .klondike), 443_745)
    }
}
