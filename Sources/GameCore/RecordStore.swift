import Foundation

/// 승리 기록 (UserDefaults 영구 저장) — 변형별 최근 승리 목록
public final class RecordStore {
    public struct GameRecord: Codable, Identifiable {
        public let id: UUID
        public let gameNumber: Int
        public let variant: GameVariant
        public let seconds: Double
        public let date: Date
        public let moves: Int

        public init(gameNumber: Int, variant: GameVariant, seconds: Double, moves: Int = 0, date: Date = Date()) {
            self.id = UUID()
            self.gameNumber = gameNumber
            self.variant = variant
            self.seconds = seconds
            self.moves = moves
            self.date = date
        }

        private enum CodingKeys: String, CodingKey {
            case id, gameNumber, variant, seconds, date, moves
        }

        /// 기존 저장 데이터(moves 없음) 호환 — 없으면 0
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(UUID.self, forKey: .id)
            gameNumber = try c.decode(Int.self, forKey: .gameNumber)
            variant = try c.decode(GameVariant.self, forKey: .variant)
            seconds = try c.decode(Double.self, forKey: .seconds)
            date = try c.decode(Date.self, forKey: .date)
            moves = try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0
        }
    }

    private enum Keys {
        static func records(_ variant: GameVariant) -> String {
            "records.\(variant.rawValue)"
        }
    }

    private let defaults = UserDefaults.standard
    private let maxRecords = 50

    public init() {}

    /// 변형별 승리 기록 (최신순)
    public func records(for variant: GameVariant) -> [GameRecord] {
        guard let data = defaults.data(forKey: Keys.records(variant)) else { return [] }
        return (try? JSONDecoder().decode([GameRecord].self, from: data)) ?? []
            .sorted { $0.date > $1.date }
    }

    /// 승리 기록 추가 (최신순 정렬 + 개수 제한)
    public func record(_ record: GameRecord, for variant: GameVariant) {
        var list = records(for: variant)
        list.append(record)
        list.sort { $0.date > $1.date }
        if list.count > maxRecords {
            list = Array(list.prefix(maxRecords))
        }
        if let data = try? JSONEncoder().encode(list) {
            defaults.set(data, forKey: Keys.records(variant))
        }
    }

    /// 기록 전체 삭제 (주로 테스트/관리용)
    public func clear(for variant: GameVariant) {
        defaults.removeObject(forKey: Keys.records(variant))
    }

    /// 모든 변형 기록 삭제
    public func clearAll() {
        for variant in GameVariant.allCases {
            clear(for: variant)
        }
    }
}