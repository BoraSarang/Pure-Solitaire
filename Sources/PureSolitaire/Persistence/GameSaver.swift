import Foundation
import GameCore

/// 게임 진행 상태 자동 저장 (UserDefaults, JSON 직렬화)
/// 앱 종료/크래시 후 재시작 시 이어서 복구하기 위한 안전망.
final class GameSaver {
    private enum Key: String, CaseIterable {
        case savedGame = "persistence.savedGame"
        case savedKlondike = "persistence.savedKlondike"
        case savedSpider = "persistence.savedSpider"
        case savedSeaTower = "persistence.savedSeaTower"
        case savedSuperFreeCell = "persistence.savedSuperFreeCell"
        case savedYukon = "persistence.savedYukon"
        case savedFortyThieves = "persistence.savedFortyThieves"
        case savedGolf = "persistence.savedGolf"
        case savedPyramid = "persistence.savedPyramid"
        case savedTriPeaks = "persistence.savedTriPeaks"
        case savedScorpion = "persistence.savedScorpion"
        case savedElapsedSeconds = "persistence.elapsedSeconds"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - 변형별 저장 슬롯

    /// 변형 → 저장 키 매핑. FreeCell/Baker's는 같은 슬롯(savedGame) 공유.
    private func key(for variant: GameVariant) -> String {
        switch variant {
        case .freecell, .bakersGame: Key.savedGame.rawValue
        case .klondike: Key.savedKlondike.rawValue
        case .spider: Key.savedSpider.rawValue
        case .seaTower: Key.savedSeaTower.rawValue
        case .superFreeCell: Key.savedSuperFreeCell.rawValue
        case .yukon: Key.savedYukon.rawValue
        case .fortyThieves: Key.savedFortyThieves.rawValue
        case .golf: Key.savedGolf.rawValue
        case .pyramid: Key.savedPyramid.rawValue
        case .triPeaks: Key.savedTriPeaks.rawValue
        case .scorpion: Key.savedScorpion.rawValue
        }
    }

    /// 해당 변형 저장 게임 존재 여부
    func hasData(for variant: GameVariant) -> Bool {
        defaults.data(forKey: key(for: variant)) != nil
    }

    /// 게임 상태 저장 (전체 상태 + undo/redo 스택 포함)
    func save<G: Encodable>(_ value: G, variant: GameVariant) {
        store(value, forKey: key(for: variant))
    }

    /// 저장된 게임 복구. 없거나 디코딩 실패 시 nil.
    func restore<G: Decodable>(_ type: G.Type, variant: GameVariant) -> G? {
        load(type, forKey: key(for: variant))
    }

    /// 변형 저장 상태 제거
    func clear(variant: GameVariant) {
        defaults.removeObject(forKey: key(for: variant))
    }

    /// 모든 게임/경과 시간 저장 제거 (승리 등 완료된 게임이 쌓이지 않도록)
    func clearAll() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    // MARK: - 경과 시간 (이어하기 시간 연속성, T-238)

    /// 경과 시간 저장 (persist 시 함께 저장)
    func saveElapsed(_ seconds: TimeInterval) {
        defaults.set(seconds, forKey: Key.savedElapsedSeconds.rawValue)
    }

    /// 저장된 경과 시간 복구. 없으면 nil.
    func restoreElapsed() -> TimeInterval? {
        guard defaults.object(forKey: Key.savedElapsedSeconds.rawValue) != nil else { return nil }
        return defaults.double(forKey: Key.savedElapsedSeconds.rawValue)
    }

    // MARK: - 제네릭 직렬화 헬퍼

    private func store<T: Encodable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}