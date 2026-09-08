import XCTest
@testable import GameCore

final class DailyChallengeTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.year = y
        comps.month = m
        comps.day = d
        return comps.date ?? Date()
    }

    /// 같은 날짜 → 같은 변형 + 시드 (결정성)
    func testDeterministicSameDate() {
        let d = date(2026, 8, 12)
        XCTAssertEqual(DailyChallenge.challengeVariant(for: d), DailyChallenge.challengeVariant(for: d))
        XCTAssertEqual(DailyChallenge.gameNumber(for: d), DailyChallenge.gameNumber(for: d))
    }

    /// 다른 날짜 → 변형 전환 가능 (전체 변형 순환 — 샘플 5일이 전부 같지 않아야 함)
    func testVariantRotationOverDays() {
        let variants = (10...14).map { DailyChallenge.challengeVariant(for: date(2026, 8, $0)) }
        XCTAssertGreaterThan(Set(variants).count, 1)
    }

    /// 시드는 항상 유효 범위
    func testGameNumberRange() {
        for day in 1...31 {
            let n = DailyChallenge.gameNumber(for: date(2026, 8, day))
            XCTAssertGreaterThanOrEqual(n, 1)
            XCTAssertLessThanOrEqual(n, DealGenerator.maxGameNumber)
        }
    }

    /// 별점 — 패/승리/시간/이동 경계
    func testStarsBoundaries() {
        // 패배는 0
        XCTAssertEqual(DailyChallenge.stars(variant: .freecell, isWin: false, seconds: 0, moves: 0), 0)
        // 승리만 = 1
        XCTAssertEqual(DailyChallenge.stars(variant: .freecell, isWin: true, seconds: 900, moves: 300), 1)
        // 승리 + 시간 (이동은 초과) = 2
        XCTAssertEqual(DailyChallenge.stars(variant: .freecell, isWin: true, seconds: 479, moves: 300), 2)
        // 승리 + 이동 (시간은 초과) = 2
        XCTAssertEqual(DailyChallenge.stars(variant: .freecell, isWin: true, seconds: 900, moves: 119), 2)
        // 전부 달성 = 3
        XCTAssertEqual(DailyChallenge.stars(variant: .freecell, isWin: true, seconds: 480, moves: 120), 3)
        // 3 초과 불가
        XCTAssertEqual(DailyChallenge.stars(variant: .spider, isWin: true, seconds: 1, moves: 1), 3)
    }

    // MARK: - 9판 (T-215)

    /// 같은 날짜 → 같은 9판 (결정성)
    func testDealsDeterministicSameDate() {
        let d = date(2026, 8, 12)
        XCTAssertEqual(DailyChallenge.deals(for: d), DailyChallenge.deals(for: d))
    }

    /// 9판 구성 — 정확히 9개, 변형 중복 없음, 게임 번호 유효 범위
    func testDealsCountAndUniqueness() {
        let deals = DailyChallenge.deals(for: date(2026, 8, 12))
        XCTAssertEqual(deals.count, DailyChallenge.dealsPerDay)
        let variants = deals.map(\.variant)
        XCTAssertEqual(Set(variants).count, deals.count, "변형은 중복 없어야 함")
        for deal in deals {
            XCTAssertGreaterThanOrEqual(deal.number, 1)
            XCTAssertLessThanOrEqual(deal.number, DealGenerator.maxGameNumber)
        }
    }

    /// 9판이 12종 중 9개를 샘플링 — 전체 집합에 포함되어야 함
    func testDealsAreSubsetOfAllVariants() {
        let deals = DailyChallenge.deals(for: date(2026, 8, 12))
        let all = Set(GameVariant.allCases)
        for deal in deals {
            XCTAssertTrue(all.contains(deal.variant))
        }
    }

    /// 월 변경 시 9판 구성이 달라짐 (전부 같지 않아야 함)
    func testDealsChangeAcrossMonths() {
        let august = DailyChallenge.deals(for: date(2026, 8, 12))
        let september = DailyChallenge.deals(for: date(2026, 9, 12))
        XCTAssertNotEqual(august, september)
    }

    /// 같은 달 안에서 날짜가 바뀌면 순서가 달라짐 (전부 같지 않아야 함)
    func testDealsVaryWithinMonth() {
        let day1 = DailyChallenge.deals(for: date(2026, 8, 12))
        let day2 = DailyChallenge.deals(for: date(2026, 8, 13))
        XCTAssertNotEqual(day1, day2)
    }
}

final class ChallengeStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var store: ChallengeStore!

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "test.challenge.\(UUID().uuidString)")!
        store = ChallengeStore(defaults: suite)
    }

    override func tearDown() {
        store.clearAll()
        super.tearDown()
    }

    func testRecordAndRead() {
        let r = ChallengeStore.Result(dateKey: "2026-08-12", variant: .freecell, stars: 3, seconds: 300, moves: 100)
        XCTAssertTrue(store.record(r))
        XCTAssertEqual(store.result(for: "2026-08-12")?.stars, 3)
        XCTAssertEqual(store.result(for: "2026-08-12")?.variant, .freecell)
    }

    /// 같은 날짜 더 낮은 별점은 기록 안 함, 더 높으면 갱신
    func testRecordDoesNotDowngrade() {
        let low = ChallengeStore.Result(dateKey: "2026-08-12", variant: .freecell, stars: 1, seconds: 900, moves: 300)
        XCTAssertTrue(store.record(low))
        XCTAssertFalse(store.record(low))
        let high = ChallengeStore.Result(dateKey: "2026-08-12", variant: .freecell, stars: 3, seconds: 300, moves: 100)
        XCTAssertTrue(store.record(high))
        XCTAssertEqual(store.result(for: "2026-08-12")?.stars, 3)
    }

    /// 날짜별 격리
    func testDateIsolation() {
        store.record(ChallengeStore.Result(dateKey: "2026-08-12", variant: .freecell, stars: 2, seconds: 500, moves: 200))
        XCTAssertNil(store.result(for: "2026-08-13"))
    }

    func testTodayResultUsesCurrentDate() {
        let today = ChallengeStore.dateKey(for: Date())
        store.record(ChallengeStore.Result(dateKey: today, variant: .freecell, stars: 2, seconds: 400, moves: 150))
        XCTAssertEqual(store.todayResult()?.stars, 2)
    }

    // MARK: - 9판 기록 (T-216)

    /// 판 결과 기록 → 날짜별 9판 조회
    func testRecordDealAndRead() {
        let key = "2026-08-12"
        let deal = ChallengeStore.DealResult(variant: .freecell, number: 42, stars: 3, seconds: 300, moves: 100)
        XCTAssertTrue(store.recordDeal(deal, for: key))
        let day = store.dayResult(for: key)
        XCTAssertEqual(day?.deals.count, 1)
        XCTAssertEqual(day?.deals.first?.variant, .freecell)
        XCTAssertEqual(day?.totalStars, 3)
        XCTAssertEqual(day?.completedCount, 1)
    }

    /// 같은 판 더 높은 별점은 갱신, 낮으면 유지
    func testRecordDealUpgradeOnly() {
        let key = "2026-08-12"
        let low = ChallengeStore.DealResult(variant: .freecell, number: 42, stars: 1, seconds: 900, moves: 300)
        let high = ChallengeStore.DealResult(variant: .freecell, number: 42, stars: 3, seconds: 300, moves: 100)
        XCTAssertTrue(store.recordDeal(low, for: key))
        XCTAssertFalse(store.recordDeal(low, for: key))
        XCTAssertTrue(store.recordDeal(high, for: key))
        XCTAssertEqual(store.dayResult(for: key)?.deals.first?.stars, 3)
        XCTAssertEqual(store.dayResult(for: key)?.deals.count, 1)
    }

    /// 다른 판은 누적 (9판까지)
    func testRecordDealAccumulates() {
        let key = "2026-08-12"
        let a = ChallengeStore.DealResult(variant: .freecell, number: 1, stars: 2, seconds: 400, moves: 150)
        let b = ChallengeStore.DealResult(variant: .spider, number: 2, stars: 3, seconds: 500, moves: 200)
        let c = ChallengeStore.DealResult(variant: .golf, number: 3, stars: 0, seconds: 0, moves: 0)
        store.recordDeal(a, for: key)
        store.recordDeal(b, for: key)
        store.recordDeal(c, for: key)
        let day = store.dayResult(for: key)
        XCTAssertEqual(day?.deals.count, 3)
        XCTAssertEqual(day?.totalStars, 5)
        XCTAssertEqual(day?.completedCount, 2)
    }

    /// 기존 단건 저장 → 9판 구조로 변환 (호환)
    func testLegacySingleResultConvertsToDayResult() {
        let key = "2026-08-12"
        store.record(ChallengeStore.Result(dateKey: key, variant: .freecell, stars: 2, seconds: 400, moves: 150))
        let day = store.dayResult(for: key)
        XCTAssertEqual(day?.deals.count, 1)
        XCTAssertEqual(day?.deals.first?.stars, 2)
        XCTAssertEqual(day?.totalStars, 2)
        // 새 구조 기록이 생기면 기존 변환 결과를 대체
        let deal = ChallengeStore.DealResult(variant: .spider, number: 7, stars: 3, seconds: 400, moves: 150)
        store.recordDeal(deal, for: key)
        XCTAssertEqual(store.dayResult(for: key)?.deals.count, 2)
    }

    // MARK: - T-233 데일리 단일화 정합성

    /// 날짜 키 사전식 순서 = 시간 순서 (미래 판정 문자열 비교의 근거)
    func testDateKeyLexicographicOrderMatchesChronology() {
        let cal = Calendar(identifier: .gregorian)
        func key(_ y: Int, _ m: Int, _ d: Int) -> String {
            var comps = DateComponents()
            comps.calendar = cal
            comps.year = y
            comps.month = m
            comps.day = d
            return ChallengeStore.dateKey(for: comps.date ?? Date(), calendar: cal)
        }
        XCTAssertLessThan(key(2026, 8, 12), key(2026, 8, 13))
        XCTAssertLessThan(key(2026, 8, 31), key(2026, 9, 1))
        XCTAssertLessThan(key(2026, 12, 31), key(2027, 1, 1))
        XCTAssertEqual(key(2026, 8, 12), key(2026, 8, 12))
    }

    /// 같은 변형·다른 번호는 별개 판으로 누적 (기록 키 = 변형+번호)
    func testSameVariantDifferentNumberAreSeparateDeals() {
        let key = "2026-08-12"
        let a = ChallengeStore.DealResult(variant: .freecell, number: 10, stars: 2, seconds: 400, moves: 150)
        let b = ChallengeStore.DealResult(variant: .freecell, number: 20, stars: 3, seconds: 300, moves: 100)
        XCTAssertTrue(store.recordDeal(a, for: key))
        XCTAssertTrue(store.recordDeal(b, for: key))
        let day = store.dayResult(for: key)
        XCTAssertEqual(day?.deals.count, 2)
        XCTAssertEqual(day?.totalStars, 5)
    }

    /// 9판 각 번호 = DailyDeal 번호 (단일화 fallback 구성과 동일한 번호 보장)
    func testDealNumbersMatchDailyDealNumbers() {
        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .gregorian)
        comps.year = 2026
        comps.month = 8
        comps.day = 12
        let date = comps.date ?? Date()
        let cal = Calendar(identifier: .gregorian)
        for deal in DailyChallenge.deals(for: date, calendar: cal) {
            XCTAssertEqual(
                deal.number,
                DailyDeal.gameNumber(for: date, variant: deal.variant, calendar: cal)
            )
        }
    }
}

final class AchievementTests: XCTestCase {
    private var suite: UserDefaults!
    private var store: AchievementStore!

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "test.achievement.\(UUID().uuidString)")!
        store = AchievementStore(defaults: suite)
    }

    override func tearDown() {
        store.clearAll()
        super.tearDown()
    }

    private func snapshot(totalGames: Int = 0, wins: Int = 0, bestStreak: Int = 0, variantsWon: Int = 0, bestTime: Double? = nil) -> StatsSnapshot {
        StatsSnapshot(totalGames: totalGames, wins: wins, bestStreak: bestStreak, variantsWonCount: variantsWon, bestTimeSeconds: bestTime)
    }

    func testFirstWin() {
        XCTAssertFalse(Achievement.isUnlocked(.firstWin, stats: snapshot(wins: 0), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.firstWin, stats: snapshot(wins: 1), challengeStars: 0))
    }

    func testWinCounts() {
        XCTAssertFalse(Achievement.isUnlocked(.tenWins, stats: snapshot(wins: 9), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.tenWins, stats: snapshot(wins: 10), challengeStars: 0))
        XCTAssertFalse(Achievement.isUnlocked(.fiftyWins, stats: snapshot(wins: 49), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.fiftyWins, stats: snapshot(wins: 50), challengeStars: 0))
    }

    func testStreaks() {
        XCTAssertTrue(Achievement.isUnlocked(.firstStreak, stats: snapshot(bestStreak: 1), challengeStars: 0))
        XCTAssertFalse(Achievement.isUnlocked(.fiveStreak, stats: snapshot(bestStreak: 4), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.fiveStreak, stats: snapshot(bestStreak: 5), challengeStars: 0))
    }

    func testVariantsCompleted() {
        XCTAssertFalse(Achievement.isUnlocked(.oneVariantCompleted, stats: snapshot(variantsWon: 0), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.oneVariantCompleted, stats: snapshot(variantsWon: 1), challengeStars: 0))
        XCTAssertFalse(Achievement.isUnlocked(.fiveVariantsCompleted, stats: snapshot(variantsWon: 4), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.fiveVariantsCompleted, stats: snapshot(variantsWon: 5), challengeStars: 0))
    }

    func testHundredGamesAndFastWin() {
        XCTAssertFalse(Achievement.isUnlocked(.hundredGames, stats: snapshot(totalGames: 99), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.hundredGames, stats: snapshot(totalGames: 100), challengeStars: 0))
        XCTAssertFalse(Achievement.isUnlocked(.fastWin, stats: snapshot(bestTime: 61), challengeStars: 0))
        XCTAssertTrue(Achievement.isUnlocked(.fastWin, stats: snapshot(bestTime: 60), challengeStars: 0))
    }

    func testChallengeThreeStars() {
        XCTAssertFalse(Achievement.isUnlocked(.challengeThreeStars, stats: snapshot(), challengeStars: 2))
        XCTAssertTrue(Achievement.isUnlocked(.challengeThreeStars, stats: snapshot(), challengeStars: 3))
    }

    func testStoreUnlockOnce() {
        XCTAssertTrue(store.recordUnlock(.firstWin))
        XCTAssertFalse(store.recordUnlock(.firstWin))
        XCTAssertTrue(store.isUnlocked(.firstWin))
        XCTAssertEqual(store.unlockedSet().count, 1)
    }
}