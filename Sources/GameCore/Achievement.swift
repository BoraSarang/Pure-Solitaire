import Foundation

/// 업적 배지 — 통계/챌린지 데이터 기반 순수 판정
public struct Achievement: Identifiable, Equatable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case firstWin
        case tenWins
        case fiftyWins
        case firstStreak
        case fiveStreak
        case oneVariantCompleted
        case fiveVariantsCompleted
        case hundredGames
        case fastWin
        case challengeThreeStars
    }

    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let symbol: String

    public var id: String { kind.rawValue }

    public static let all: [Achievement] = [
        Achievement(kind: .firstWin, title: "첫 승리", subtitle: "게임을 처음으로 클리어", symbol: "trophy.fill"),
        Achievement(kind: .tenWins, title: "승리 10회", subtitle: "총 승리 10회 달성", symbol: "medal.fill"),
        Achievement(kind: .fiftyWins, title: "승리 50회", subtitle: "총 승리 50회 달성", symbol: "medal.star.fill"),
        Achievement(kind: .firstStreak, title: "첫 연승", subtitle: "연승 기록 시작(1연승)", symbol: "flame"),
        Achievement(kind: .fiveStreak, title: "5연승", subtitle: "최고 연승 5회 달성", symbol: "flame.fill"),
        Achievement(kind: .oneVariantCompleted, title: "첫 변형 완주", subtitle: "한 변형으로 승리", symbol: "checkmark.seal.fill"),
        Achievement(kind: .fiveVariantsCompleted, title: "변형 5종 완주", subtitle: "5개 변형 각각 승리", symbol: "checkmark.seal.fill"),
        Achievement(kind: .hundredGames, title: "게임 100판", subtitle: "총 게임 100판 플레이", symbol: "sparkles"),
        Achievement(kind: .fastWin, title: "스피드 스타", subtitle: "1분 이내 승리", symbol: "bolt.fill"),
        Achievement(kind: .challengeThreeStars, title: "챌린지 마스터", subtitle: "데일리 챌린지 별 3개 달성", symbol: "star.circle.fill"),
    ]

    public static func achievement(for kind: Kind) -> Achievement {
        all.first { $0.kind == kind } ?? Achievement(kind: kind, title: kind.rawValue, subtitle: "", symbol: "star.fill")
    }

    /// 통계/챌린지 데이터 → 잠금 해제 여부
    public static func isUnlocked(_ kind: Kind, stats: StatsSnapshot, challengeStars: Int) -> Bool {
        switch kind {
        case .firstWin:
            return stats.wins >= 1
        case .tenWins:
            return stats.wins >= 10
        case .fiftyWins:
            return stats.wins >= 50
        case .firstStreak:
            return stats.bestStreak >= 1
        case .fiveStreak:
            return stats.bestStreak >= 5
        case .oneVariantCompleted:
            return stats.variantsWonCount >= 1
        case .fiveVariantsCompleted:
            return stats.variantsWonCount >= 5
        case .hundredGames:
            return stats.totalGames >= 100
        case .fastWin:
            return stats.bestTimeSeconds.map { $0 <= 60 } ?? false
        case .challengeThreeStars:
            return challengeStars >= 3
        }
    }
}

/// 배지 판정용 통계 스냅샷
public struct StatsSnapshot: Sendable {
    public let totalGames: Int
    public let wins: Int
    public let bestStreak: Int
    public let variantsWonCount: Int
    public let bestTimeSeconds: Double?

    public init(totalGames: Int, wins: Int, bestStreak: Int, variantsWonCount: Int, bestTimeSeconds: Double?) {
        self.totalGames = totalGames
        self.wins = wins
        self.bestStreak = bestStreak
        self.variantsWonCount = variantsWonCount
        self.bestTimeSeconds = bestTimeSeconds
    }

    static let empty = StatsSnapshot(totalGames: 0, wins: 0, bestStreak: 0, variantsWonCount: 0, bestTimeSeconds: nil)
}

/// 업적 잠금 해제 상태 저장 (UserDefaults)
public final class AchievementStore {
    private enum Keys {
        static let unlocked = "achievements.unlocked"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 잠금 해제된 kind rawValue 배열
    public func unlockedSet() -> Set<String> {
        Set(defaults.stringArray(forKey: Keys.unlocked) ?? [])
    }

    public func isUnlocked(_ kind: Achievement.Kind) -> Bool {
        unlockedSet().contains(kind.rawValue)
    }

    /// 잠금 해제 기록 — 신규라면 true 반환 (메시지 표시용)
    @discardableResult
    public func recordUnlock(_ kind: Achievement.Kind) -> Bool {
        var set = unlockedSet()
        guard !set.contains(kind.rawValue) else { return false }
        set.insert(kind.rawValue)
        defaults.set(Array(set).sorted(), forKey: Keys.unlocked)
        return true
    }

    public func clearAll() {
        defaults.removeObject(forKey: Keys.unlocked)
    }
}