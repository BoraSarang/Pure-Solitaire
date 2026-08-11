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