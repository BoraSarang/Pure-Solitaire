import Foundation
import GameCore

/// 로컬 플레이 통계 (UserDefaults 영구 저장) — 변형별 + 전체 합계
final class StatsStore {
    /// 특정 변형의 통계 (전체 합계는 별도 키)
    struct Entry {
        let totalGames: Int
        let wins: Int
        let currentStreak: Int
        let bestStreak: Int
        let bestTime: Double?

        var winRate: Double {
            guard totalGames > 0 else { return 0 }
            return Double(wins) / Double(totalGames) * 100
        }
    }

    private enum Keys {
        static let totalGames = "stats.totalGames"
        static let wins = "stats.wins"
        static let currentStreak = "stats.currentStreak"
        static let bestStreak = "stats.bestStreak"
        static let lastGameNumber = "stats.lastGameNumber"

        static func variant(_ variant: GameVariant, _ key: String) -> String {
            "stats.\(variant.rawValue).\(key)"
        }
    }

    private let defaults = UserDefaults.standard

    // MARK: - 전체 합계 (기존 키 유지)

    var totalGames: Int {
        get { defaults.integer(forKey: Keys.totalGames) }
        set { defaults.set(newValue, forKey: Keys.totalGames) }
    }

    var wins: Int {
        get { defaults.integer(forKey: Keys.wins) }
        set { defaults.set(newValue, forKey: Keys.wins) }
    }

    var currentStreak: Int {
        get { defaults.integer(forKey: Keys.currentStreak) }
        set { defaults.set(newValue, forKey: Keys.currentStreak) }
    }

    var bestStreak: Int {
        get { defaults.integer(forKey: Keys.bestStreak) }
        set { defaults.set(newValue, forKey: Keys.bestStreak) }
    }

    var winRate: Double {
        runRate(totalGames, wins)
    }

    /// 마지막으로 시작한 게임 번호 (변형별)
    func lastGameNumber(for variant: GameVariant) -> Int? {
        defaults.object(forKey: Keys.variant(variant, "lastGameNumber")) as? Int
            ?? defaults.object(forKey: Keys.lastGameNumber) as? Int
    }

    func setLastGameNumber(_ number: Int, for variant: GameVariant) {
        defaults.set(number, forKey: Keys.variant(variant, "lastGameNumber"))
    }

    /// 변형별 최단 승리 시간 (초, 기록 없으면 nil)
    func bestTimeSeconds(for variant: GameVariant) -> Double? {
        let v = defaults.double(forKey: Keys.variant(variant, "bestTimeSeconds"))
        return v > 0 ? v : nil
    }

    /// 승리 시간 기록 (기록 없거나 더 짧으면 갱신)
    func recordWinTime(_ seconds: Double, for variant: GameVariant) {
        let key = Keys.variant(variant, "bestTimeSeconds")
        let current = defaults.double(forKey: key)
        if current <= 0 || seconds < current {
            defaults.set(seconds, forKey: key)
        }
    }

    // MARK: - 변형별 기록

    func entry(for variant: GameVariant) -> Entry {
        Entry(
            totalGames: defaults.integer(forKey: Keys.variant(variant, "totalGames")),
            wins: defaults.integer(forKey: Keys.variant(variant, "wins")),
            currentStreak: defaults.integer(forKey: Keys.variant(variant, "currentStreak")),
            bestStreak: defaults.integer(forKey: Keys.variant(variant, "bestStreak")),
            bestTime: bestTimeSeconds(for: variant)
        )
    }

    func recordStarted(_ variant: GameVariant) {
        totalGames += 1
        let key = Keys.variant(variant, "totalGames")
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    func recordWin(_ variant: GameVariant) {
        wins += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)

        let base = Keys.variant(variant, "")
        defaults.set(defaults.integer(forKey: base + "wins") + 1, forKey: base + "wins")
        let streak = defaults.integer(forKey: base + "currentStreak") + 1
        defaults.set(streak, forKey: base + "currentStreak")
        let best = max(defaults.integer(forKey: base + "bestStreak"), streak)
        defaults.set(best, forKey: base + "bestStreak")
    }

    func recordLoss(_ variant: GameVariant) {
        currentStreak = 0
        defaults.set(0, forKey: Keys.variant(variant, "currentStreak"))
    }

    private func runRate(_ total: Int, _ w: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(w) / Double(total) * 100
    }

    // MARK: - 초기화

    /// 전체 통계 + 변형별 통계 모두 삭제 (베스트 타임/마지막 게임 번호 포함)
    func resetAll() {
        for key in [
            Keys.totalGames, Keys.wins, Keys.currentStreak, Keys.bestStreak, Keys.lastGameNumber
        ] {
            defaults.removeObject(forKey: key)
        }
        for variant in GameVariant.allCases {
            let base = "stats.\(variant.rawValue)."
            defaults.removeObject(forKey: base + "totalGames")
            defaults.removeObject(forKey: base + "wins")
            defaults.removeObject(forKey: base + "currentStreak")
            defaults.removeObject(forKey: base + "bestStreak")
            defaults.removeObject(forKey: base + "lastGameNumber")
            defaults.removeObject(forKey: base + "bestTimeSeconds")
        }
    }
}