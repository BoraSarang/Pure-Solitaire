import Foundation
import GameCore

/// 게임 진행 상태 자동 저장 (UserDefaults, JSON 직렬화)
/// 앱 종료/크래시 후 재시작 시 이어서 복구하기 위한 안전망.
final class GameSaver {
    private enum Keys {
        static let savedGame = "persistence.savedGame"
        static let savedKlondike = "persistence.savedKlondike"
        static let savedSpider = "persistence.savedSpider"
        static let savedSeaTower = "persistence.savedSeaTower"
        static let savedSuperFreeCell = "persistence.savedSuperFreeCell"
        static let savedYukon = "persistence.savedYukon"
        static let savedFortyThieves = "persistence.savedFortyThieves"
        static let savedGolf = "persistence.savedGolf"
        static let savedPyramid = "persistence.savedPyramid"
        static let savedTriPeaks = "persistence.savedTriPeaks"
        static let savedScorpion = "persistence.savedScorpion"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - FreeCell/Baker's

    /// 저장된 게임이 있는지
    func hasSavedGame() -> Bool {
        defaults.data(forKey: Keys.savedGame) != nil
    }

    /// 게임 상태 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ game: FreeCellGame) {
        store(game, forKey: Keys.savedGame)
    }

    /// 저장된 게임 복구. 없거나 디코딩 실패 시 nil.
    func restore() -> FreeCellGame? {
        load(FreeCellGame.self, forKey: Keys.savedGame)
    }

    /// 저장 상태 제거 (승리 등 완료된 게임이 쌓이지 않도록)
    func clear() {
        defaults.removeObject(forKey: Keys.savedGame)
    }

    // MARK: - Klondike

    /// Klondike 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ klondike: KlondikeGame) {
        store(klondike, forKey: Keys.savedKlondike)
    }

    /// 저장된 Klondike 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreKlondike() -> KlondikeGame? {
        load(KlondikeGame.self, forKey: Keys.savedKlondike)
    }

    func clearKlondike() {
        defaults.removeObject(forKey: Keys.savedKlondike)
    }

    // MARK: - Spider

    /// Spider 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ spider: SpiderGame) {
        store(spider, forKey: Keys.savedSpider)
    }

    /// 저장된 Spider 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreSpider() -> SpiderGame? {
        load(SpiderGame.self, forKey: Keys.savedSpider)
    }

    func clearSpider() {
        defaults.removeObject(forKey: Keys.savedSpider)
    }

    // MARK: - Sea Tower

    func saveSeaTower(_ game: FreeCellGame) {
        guard game.variant == .seaTower else { return }
        store(game, forKey: Keys.savedSeaTower)
    }

    func restoreSeaTower() -> FreeCellGame? {
        guard let game: FreeCellGame = load(FreeCellGame.self, forKey: Keys.savedSeaTower),
              game.variant == .seaTower else { return nil }
        return game
    }

    func clearSeaTower() {
        defaults.removeObject(forKey: Keys.savedSeaTower)
    }

    // MARK: - Super FreeCell

    func saveSuperFreeCell(_ game: FreeCellGame) {
        guard game.variant == .superFreeCell else { return }
        store(game, forKey: Keys.savedSuperFreeCell)
    }

    func restoreSuperFreeCell() -> FreeCellGame? {
        guard let game: FreeCellGame = load(FreeCellGame.self, forKey: Keys.savedSuperFreeCell),
              game.variant == .superFreeCell else { return nil }
        return game
    }

    func clearSuperFreeCell() {
        defaults.removeObject(forKey: Keys.savedSuperFreeCell)
    }

    // MARK: - Yukon

    func save(_ yukon: YukonGame) {
        store(yukon, forKey: Keys.savedYukon)
    }

    func restoreYukon() -> YukonGame? {
        load(YukonGame.self, forKey: Keys.savedYukon)
    }

    func clearYukon() {
        defaults.removeObject(forKey: Keys.savedYukon)
    }

    // MARK: - Forty Thieves

    /// Forty Thieves 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ fortyThieves: FortyThievesGame) {
        store(fortyThieves, forKey: Keys.savedFortyThieves)
    }

    /// 저장된 Forty Thieves 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreFortyThieves() -> FortyThievesGame? {
        load(FortyThievesGame.self, forKey: Keys.savedFortyThieves)
    }

    func clearFortyThieves() {
        defaults.removeObject(forKey: Keys.savedFortyThieves)
    }

    // MARK: - Golf

    /// Golf 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ golf: GolfGame) {
        store(golf, forKey: Keys.savedGolf)
    }

    /// 저장된 Golf 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreGolf() -> GolfGame? {
        load(GolfGame.self, forKey: Keys.savedGolf)
    }

    func clearGolf() {
        defaults.removeObject(forKey: Keys.savedGolf)
    }

    // MARK: - Pyramid

    /// Pyramid 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ pyramid: PyramidGame) {
        store(pyramid, forKey: Keys.savedPyramid)
    }

    /// 저장된 Pyramid 게임 복구. 없거나 디코딩 실패 시 nil.
    func restorePyramid() -> PyramidGame? {
        load(PyramidGame.self, forKey: Keys.savedPyramid)
    }

    func clearPyramid() {
        defaults.removeObject(forKey: Keys.savedPyramid)
    }

    // MARK: - TriPeaks

    /// TriPeaks 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ triPeaks: TriPeaksGame) {
        store(triPeaks, forKey: Keys.savedTriPeaks)
    }

    /// 저장된 TriPeaks 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreTriPeaks() -> TriPeaksGame? {
        load(TriPeaksGame.self, forKey: Keys.savedTriPeaks)
    }

    func clearTriPeaks() {
        defaults.removeObject(forKey: Keys.savedTriPeaks)
    }

    // MARK: - Scorpion

    /// Scorpion 게임 저장 (전체 상태 + undo/redo 스택 포함)
    func save(_ scorpion: ScorpionGame) {
        store(scorpion, forKey: Keys.savedScorpion)
    }

    /// 저장된 Scorpion 게임 복구. 없거나 디코딩 실패 시 nil.
    func restoreScorpion() -> ScorpionGame? {
        load(ScorpionGame.self, forKey: Keys.savedScorpion)
    }

    func clearScorpion() {
        defaults.removeObject(forKey: Keys.savedScorpion)
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
