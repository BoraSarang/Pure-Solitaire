import SwiftUI
import GameCore

@MainActor
final class FreeCellViewModel: ObservableObject {
    /// 현재 선택된 카드 시퀀스
    struct Selection {
        var source: CardSource
        var cardCount: Int
    }

    @Published private(set) var game: FreeCellGame
    @Published private(set) var klondike: KlondikeGame?
    @Published private(set) var spider: SpiderGame?
    @Published private(set) var yukon: YukonGame?
    @Published private(set) var fortyThieves: FortyThievesGame?
    @Published private(set) var golf: GolfGame?
    @Published private(set) var pyramid: PyramidGame?
    @Published private(set) var triPeaks: TriPeaksGame?
    @Published var gameNumberText: String
    @Published private(set) var selection: Selection?
    @Published var showingGameNumber = false
    @Published var showingStats = false
    @Published var showingSettings = false
    @Published var showingNewGameConfirmation = false
    @Published var showNextGameButton = false
    @Published private(set) var message: String?
    @Published private(set) var highlightedMove: Move?
    @Published var hintAnimationMove: Move?
    @Published var hintAnimationTick = 0
    /// 전체 힌트 강조 모드 — 켜져 있으면 유효 이동 전체의 소스를 동시에 강조
    @Published var showAllHints = false
    @Published var isDealing = false
    @Published private(set) var lastHomeCard: Card?
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var isPaused = false
    private var homePulseTask: Task<Void, Never>?
    private var elapsedTimer: Timer?
    private var pauseAccumulated: TimeInterval = 0
    private var hintCandidates: [Move] = []
    private var hintIndex: Int = 0
    private var dismissTask: Task<Void, Never>?
    private var gameStartedAt: Date?
    private var newGameVariantRequest: GameVariant?
    private var newGameNumberRequest: Int?

    /// 현재 게임 소요 시간 (초, 승리 전까지 증가)
    var activeElapsedSeconds: TimeInterval? {
        guard gameStartedAt != nil, !currentIsWon else { return nil }
        return elapsedSeconds
    }

    /// 진행 중 게임 여부 (일시정지 포함)
    var isInProgress: Bool {
        gameStartedAt != nil && !currentIsWon
    }

    let settings = UserSettings()
    private let stats = StatsStore()
    private let gameSaver = GameSaver()
    private let recordStore = RecordStore()
    let gameOptions = GameOptionsStore()

    /// Spider 난이도 — GameOptionsStore 기반 (단일 진실 소스)
    var spiderDifficulty: SpiderGame.Difficulty {
        get {
            guard let def = GameVariant.spider.optionDefinitions.first(where: { $0.id == "spiderDifficulty" }),
                  let raw = Int(gameOptions.selectedID(for: .spider, option: def)),
                  let diff = SpiderGame.Difficulty(rawValue: raw) else { return .fourSuits }
            return diff
        }
        set {
            gameOptions.setSelectedID(String(newValue.rawValue), for: .spider, optionID: "spiderDifficulty")
        }
    }

    /// Klondike 스톡 드로 장수 (1 or 3) — GameOptionsStore 기반
    private var klondikeDrawMode: Int {
        guard let def = GameVariant.klondike.optionDefinitions.first(where: { $0.id == "klondikeDraw" }),
              let raw = Int(gameOptions.selectedID(for: .klondike, option: def)),
              raw == 3 else { return 1 }
        return 3
    }

    /// 변형별 승리 기록 (최신순)
    var winRecords: [RecordStore.GameRecord] {
        recordStore.records(for: variant)
    }

    /// 특정 변형의 승리 기록 (최신순) — 통계 상세 표시용
    func winRecords(for v: GameVariant) -> [RecordStore.GameRecord] {
        recordStore.records(for: v)
    }

    /// 현재 게임 형식
    var variant: GameVariant {
        if spider != nil { return .spider }
        if klondike != nil { return .klondike }
        if yukon != nil { return .yukon }
        if fortyThieves != nil { return .fortyThieves }
        if golf != nil { return .golf }
        if pyramid != nil { return .pyramid }
        if triPeaks != nil { return .triPeaks }
        return game.variant
    }
    var variantDisplayName: String { variant.displayName }

    /// 현재 게임의 게임번호 / 이동 수 (Spider/Klondike/Yukon/FortyThieves/Golf/Pyramid/TriPeaks 분기)
    var currentGameNumber: Int { spider?.gameNumber ?? klondike?.gameNumber ?? yukon?.gameNumber ?? fortyThieves?.gameNumber ?? golf?.gameNumber ?? pyramid?.gameNumber ?? triPeaks?.gameNumber ?? game.gameNumber }
    var currentMoveCount: Int { spider?.moveCount ?? klondike?.moveCount ?? yukon?.moveCount ?? fortyThieves?.moveCount ?? golf?.moveCount ?? pyramid?.moveCount ?? triPeaks?.moveCount ?? game.moveCount }
    var currentIsWon: Bool { spider?.isWon ?? klondike?.isWon ?? yukon?.isWon ?? fortyThieves?.isWon ?? golf?.isWon ?? pyramid?.isWon ?? triPeaks?.isWon ?? game.isWon }
    var currentIsPaused: Bool { isPaused }

    // 통계 노출 (현재 변형 + 전체 합계)
    var statsTotalGames: Int { stats.entry(for: variant).totalGames }
    var statsWins: Int { stats.entry(for: variant).wins }
    var statsWinRate: Double { stats.entry(for: variant).winRate }
    var statsCurrentStreak: Int { stats.entry(for: variant).currentStreak }
    var statsBestStreak: Int { stats.entry(for: variant).bestStreak }

    var allTotalGames: Int { stats.totalGames }
    var allWins: Int { stats.wins }
    var allWinRate: Double { stats.winRate }
    var allCurrentStreak: Int { stats.currentStreak }
    var allBestStreak: Int { stats.bestStreak }
    var allLeastMoves: Int? { stats.leastMoves }

    func stats(for v: GameVariant) -> StatsStore.Entry { stats.entry(for: v) }

    var bestTimeSeconds: Double? { stats.bestTimeSeconds(for: variant) }

    // MARK: - 통계 초기화

    func resetStats() {
        stats.resetAll()
        recordStore.clearAll()
        objectWillChange.send()
    }

    // MARK: - 배경음악

    func toggleBGM(_ enabled: Bool) {
        if enabled {
            BGMPLayer.shared.start(volume: settings.bgmVolume)
        } else {
            BGMPLayer.shared.stop()
        }
    }

    func setBGMVolume(_ v: Double) {
        BGMPLayer.shared.setVolume(v)
    }

    init() {
        if let restored = gameSaver.restoreSpider() {
            spider = restored
            gameOptions.setSelectedID(String(restored.difficulty.rawValue), for: .spider, optionID: "spiderDifficulty")
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreKlondike() {
            klondike = restored
            gameOptions.setSelectedID(String(restored.drawMode), for: .klondike, optionID: "klondikeDraw")
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreYukon() {
            yukon = restored
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreFortyThieves() {
            fortyThieves = restored
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreGolf() {
            golf = restored
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restorePyramid() {
            pyramid = restored
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreTriPeaks() {
            triPeaks = restored
            game = FreeCellGame(gameNumber: restored.gameNumber)
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreSeaTower() {
            game = restored
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restoreSuperFreeCell() {
            game = restored
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else if let restored = gameSaver.restore() {
            guard restored.variant == .freecell || restored.variant == .bakersGame else {
                gameSaver.clear()
                let number = stats.lastGameNumber(for: .freecell) ?? 1
                let safeNumber = min(max(number, DealGenerator.minGameNumber), DealGenerator.maxGameNumber)
                game = FreeCellGame(gameNumber: safeNumber)
                gameNumberText = String(safeNumber)
                stats.recordStarted(.freecell)
                gameStartedAt = Date()
                startElapsedTimer()
                if settings.autoPlayEnabled {
                    runAutoPlay()
                }
                return
            }
            game = restored
            gameNumberText = String(restored.gameNumber)
            gameStartedAt = Date()
            startElapsedTimer()
        } else {
            let number = stats.lastGameNumber(for: .freecell) ?? 1
            let safeNumber = min(max(number, DealGenerator.minGameNumber), DealGenerator.maxGameNumber)
            game = FreeCellGame(gameNumber: safeNumber)
            gameNumberText = String(safeNumber)
            stats.recordStarted(.freecell)
            gameStartedAt = Date()
            startElapsedTimer()
            if settings.autoPlayEnabled {
                runAutoPlay()
            }
        }
    }

    // MARK: - 새 게임

    func newGame() {
        newGame(number: Int.random(in: DealGenerator.minGameNumber...DealGenerator.maxGameNumber))
    }

    func newGame(variant: GameVariant) {
        let number = Int.random(in: DealGenerator.minGameNumber...DealGenerator.maxGameNumber)
        newGame(number: number, variant: variant, spiderDifficulty: spiderDifficulty)
    }

    /// 현재 게임을 제외한 변형 중 하나로 랜덤 전환 (진행 중이면 확인 다이얼로그 재사용)
    func switchToRandomGame() {
        let options = GameVariant.allCases.filter { $0 != variant }
        guard let next = options.randomElement() else { return }
        requestNewGame(variant: next)
    }

    /// Spider 난이도만 변경 (다음 게임부터 적용)
    func setSpiderDifficulty(_ difficulty: SpiderGame.Difficulty) {
        spiderDifficulty = difficulty
    }

    func newGame(number: Int) {
        newGame(number: number, variant: variant)
    }

    func requestNewGame() {
        guard currentMoveCount > 0 && !currentIsWon else {
            newGame()
            return
        }
        showingNewGameConfirmation = true
    }

    func requestNewGame(variant: GameVariant) {
        guard currentMoveCount > 0 && !currentIsWon else {
            newGame(variant: variant)
            return
        }
        newGameVariantRequest = variant
        showingNewGameConfirmation = true
    }

    func requestNewGame(number: Int) {
        guard currentMoveCount > 0 && !currentIsWon else {
            newGame(number: number)
            return
        }
        newGameNumberRequest = number
        showingNewGameConfirmation = true
    }

    func requestNewGame(number: Int, variant: GameVariant) {
        guard currentMoveCount > 0 && !currentIsWon else {
            newGame(number: number, variant: variant)
            return
        }
        newGameVariantRequest = variant
        newGameNumberRequest = number
        showingNewGameConfirmation = true
    }

    func confirmNewGame() {
        if let v = newGameVariantRequest {
            if let n = newGameNumberRequest {
                newGame(number: n, variant: v)
            } else {
                newGame(variant: v)
            }
        } else if let n = newGameNumberRequest {
            newGame(number: n)
        } else {
            newGame()
        }
        showingNewGameConfirmation = false
        newGameVariantRequest = nil
        newGameNumberRequest = nil
    }

    func cancelNewGame() {
        showingNewGameConfirmation = false
        newGameVariantRequest = nil
        newGameNumberRequest = nil
    }

    /// 승리 후 다음 게임 (확인 없이 바로)
    func nextGameAfterWin() {
        showNextGameButton = false
        newGame()
    }

    func newGame(number: Int, variant: GameVariant) {
        newGame(number: number, variant: variant, spiderDifficulty: spiderDifficulty)
    }

    func newGame(number: Int, variant: GameVariant, spiderDifficulty: SpiderGame.Difficulty) {
        let safeNumber = min(max(number, DealGenerator.minGameNumber), DealGenerator.maxGameNumber)
        switch variant {
        case .klondike:
            klondike = KlondikeGame(gameNumber: safeNumber, drawMode: klondikeDrawMode)
            spider = nil
            yukon = nil
            pyramid = nil
            triPeaks = nil
        case .spider:
            self.spiderDifficulty = spiderDifficulty
            spider = SpiderGame(gameNumber: safeNumber, difficulty: spiderDifficulty)
            klondike = nil
            yukon = nil
            pyramid = nil
            triPeaks = nil
        case .yukon:
            yukon = YukonGame(gameNumber: safeNumber)
            klondike = nil
            spider = nil
            pyramid = nil
            triPeaks = nil
        case .fortyThieves:
            fortyThieves = FortyThievesGame(gameNumber: safeNumber)
            klondike = nil
            spider = nil
            yukon = nil
            pyramid = nil
            triPeaks = nil
        case .golf:
            golf = GolfGame(gameNumber: safeNumber)
            klondike = nil
            spider = nil
            yukon = nil
            fortyThieves = nil
            pyramid = nil
            triPeaks = nil
        case .pyramid:
            pyramid = PyramidGame(gameNumber: safeNumber)
            klondike = nil
            spider = nil
            yukon = nil
            fortyThieves = nil
            golf = nil
            triPeaks = nil
        case .triPeaks:
            triPeaks = TriPeaksGame(gameNumber: safeNumber)
            klondike = nil
            spider = nil
            yukon = nil
            fortyThieves = nil
            golf = nil
            pyramid = nil
        default:
            game = FreeCellGame(gameNumber: safeNumber, variant: variant)
            klondike = nil
            spider = nil
            yukon = nil
            fortyThieves = nil
            golf = nil
            pyramid = nil
            triPeaks = nil
        }
        gameNumberText = String(safeNumber)
        selection = nil
        highlightedMove = nil
        hintCandidates = []
        hintIndex = 0
        clearAllHints()
        dismissMessage()
        stats.setLastGameNumber(safeNumber, for: variant)
        stats.recordStarted(variant)
        gameStartedAt = Date()
        startElapsedTimer()
        if settings.autoPlayEnabled {
            runAutoPlay()
        }
        persist()
        dealAnimation()
    }

    // MARK: - 경과 시간 타이머

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedSeconds = 0
        isPaused = false
        pauseAccumulated = 0
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isPaused, !self.currentIsWon else { return }
                self.elapsedSeconds += 1
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    /// 일시정지/재개 토글
    func togglePause() {
        guard !currentIsWon else { return }
        isPaused.toggle()
        if !isPaused {
            gameStartedAt = Date().addingTimeInterval(-elapsedSeconds)
        }
    }

    /// 새 게임 딜 연출 (카드가 위에서 내려오는 단발 애니메이션)
    private func dealAnimation() {
        isDealing = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                self.isDealing = false
            }
        }
    }

    // MARK: - 이동

    func select(source: CardSource, cardCount: Int) {
        if selection?.source == source, selection?.cardCount == cardCount {
            selection = nil
        } else {
            selection = Selection(source: source, cardCount: cardCount)
        }
    }

    @discardableResult
    func moveSelected(to destination: Destination) -> Bool {
        guard let sel = selection else { return false }
        return move(cardAt: sel.source, cardCount: sel.cardCount, to: destination)
    }

    @discardableResult
    func move(cardAt source: CardSource, cardCount: Int, to destination: Destination) -> Bool {
        guard let move = makeMove(from: source, cardCount: cardCount, to: destination) else {
            return false
        }
        return apply(move)
    }

    @discardableResult
    func apply(_ move: Move) -> Bool {
        let ok: Bool
        if spider != nil {
            ok = spider?.apply(move) == true
        } else if klondike != nil {
            ok = klondike?.apply(move) == true
        } else if yukon != nil {
            ok = yukon?.apply(move) == true
        } else if fortyThieves != nil {
            ok = fortyThieves?.apply(move) == true
        } else if golf != nil {
            ok = golf?.apply(move) == true
        } else if pyramid != nil {
            ok = pyramid?.apply(move) == true
        } else if triPeaks != nil {
            ok = triPeaks?.apply(move) == true
        } else {
            ok = game.apply(move)
        }
        guard ok else { return false }
        selection = nil
        dismissMessage()
        clearAllHints()
        highlightedMove = nil
        SoundPlayer.shared.play(move.isHomeMove ? .home : .move, enabled: settings.soundEnabled, volume: settings.soundVolume)
        if move.isHomeMove {
            pulseHomeCard(for: move)
        }
        if settings.autoFinishEnabled && runAutoFinish() {
            // 자동 완성으로 마무리됨 (checkState/persist는 runAutoFinish 내부에서 실행)
        } else if settings.autoPlayEnabled {
            runAutoPlay()
        } else {
            checkState()
        }
        persist()
        return true
    }

    // MARK: - 클릭 상호작용

    /// 선택 해제
    func clearSelection() {
        selection = nil
    }

    /// 선택된 카드(시퀀스 맨 아래 1장)를 홈셀로 이동 시도 (Space)
    @discardableResult
    func moveSelectionToHome() -> Bool {
        guard let sel = selection, sel.cardCount == 1 else { return false }
        return move(cardAt: sel.source, cardCount: 1, to: .home(0))
    }

    /// 타블로 카드 클릭: 선택이 없으면 시퀀스 선택, 있으면 이동 시도
    func tapCard(column: Int, cardIndex: Int) {
        let columnCards = game.columns[column]
        guard columnCards.indices.contains(cardIndex) else { return }
        handleColumnTap(
            column: column,
            cardIndex: cardIndex,
            columnCardCount: columnCards.count,
            movableCount: FreeCellRule.movableRun(from: columnCards).count
        )
    }

    /// 열 카드 클릭 공통 처리:
    /// 선택이 없으면 이동 가능한 시퀀스(맨 아래 movableCount 장) 선택,
    /// 선택이 있으면 해당 열로 이동 시도 후 실패 시 재선택.
    private func handleColumnTap(column: Int, cardIndex: Int, columnCardCount: Int, movableCount: Int) {
        guard columnCardCount > 0, movableCount > 0 else { return }
        let fromBottom = columnCardCount - 1 - cardIndex
        guard fromBottom < movableCount else { return }
        let cardCount = fromBottom + 1
        if selection == nil {
            select(source: .column(column), cardCount: cardCount)
        } else if !moveSelected(to: .column(column)) {
            select(source: .column(column), cardCount: cardCount)
        }
    }

    /// 프리셀 클릭
    func tapFreeCell(_ index: Int) {
        guard game.freeCells.indices.contains(index) else { return }
        if game.freeCells[index] != nil {
            if selection == nil {
                select(source: .freeCell(index), cardCount: 1)
            } else if !moveSelected(to: .freeCell(index)) {
                select(source: .freeCell(index), cardCount: 1)
            }
        } else {
            moveSelected(to: .freeCell(index))
        }
    }

    /// 홈셀 클릭
    func tapHome(_ index: Int) {
        if game.homes[index].last != nil {
            if selection == nil {
                select(source: .home(index), cardCount: 1)
            } else if !moveSelected(to: .home(index)) {
                select(source: .home(index), cardCount: 1)
            }
        } else {
            moveSelected(to: .home(index))
        }
    }

    /// 더블클릭: 홈셀로 자동 이동 시도
    @discardableResult
    func doubleClickToHome(column: Int, cardIndex: Int) -> Bool {
        let columnCards = game.columns[column]
        guard columnCards.indices.contains(cardIndex) else { return false }
        let fromBottom = columnCards.count - 1 - cardIndex
        guard fromBottom == 0 else { return false }
        return move(cardAt: .column(column), cardCount: 1, to: .home(0))
    }

    /// 선택된 카드 시퀀스인지 확인
    func isSelected(column: Int, cardIndex: Int) -> Bool {
        guard let sel = selection, sel.source == .column(column) else { return false }
        let fromBottom = game.columns[column].count - 1 - cardIndex
        return fromBottom < sel.cardCount
    }

    // MARK: - Yukon 상호작용

    /// Yukon 타블로 카드 클릭: 유콘 이동 (앞면 카드 + 그 위 전부)
    func tapYukonColumn(column: Int, cardIndex: Int) {
        guard let y = yukon, y.columns.indices.contains(column) else { return }
        let cards = y.columns[column]
        guard cards.indices.contains(cardIndex) else { return }
        guard cards[cardIndex].faceUp else { return }
        // 유콘은 앞면 카드 위 전부가 항상 이동 가능 (movableCount = 전체)
        handleColumnTap(
            column: column,
            cardIndex: cardIndex,
            columnCardCount: cards.count,
            movableCount: cards.count
        )
    }

    /// Yukon 홈셀 클릭: 선택 카드를 홈셀로 이동 시도
    func tapYukonHome(_ index: Int) {
        guard yukon != nil else { return }
        moveSelected(to: .home(index))
    }

    /// Yukon 카드 더블클릭: 홈셀로 자동 이동 시도
    @discardableResult
    func doubleClickYukonToHome(column: Int, cardIndex: Int) -> Bool {
        guard let y = yukon, y.columns.indices.contains(column) else { return false }
        let cards = y.columns[column]
        guard cards.indices.contains(cardIndex),
              cards[cardIndex].faceUp,
              cardIndex == cards.count - 1 else { return false }
        return move(cardAt: .column(column), cardCount: 1, to: .home(0))
    }

    /// 선택된 Yukon 카드 시퀀스인지 확인
    func isYukonSelected(column: Int, cardIndex: Int) -> Bool {
        guard let sel = selection, sel.source == .column(column), let y = yukon else { return false }
        let cards = y.columns[column]
        guard cards.indices.contains(cardIndex) else { return false }
        let fromBottom = cards.count - 1 - cardIndex
        return fromBottom < sel.cardCount
    }

    // MARK: - Klondike 상호작용

    /// 스톡 클릭: 1장 드로 (스톡이 비면 웨이스트를 스톡에 재활용)
    func tapKlondikeStock() {
        guard klondike != nil else { return }
        if let k = klondike, k.stock.isEmpty {
            _ = apply(.recycleStock)
        } else {
            apply(.drawFromStock)
        }
    }

    /// 웨이스트 클릭: 맨 위 카드 선택/해제 (선택 교체도 허용)
    func tapKlondikeWaste() {
        guard klondike?.waste.last != nil else { return }
        select(source: .waste, cardCount: 1)
    }

    /// 웨이스트 카드 더블클릭: 홈셀로
    @discardableResult
    func doubleClickKlondikeWaste() -> Bool {
        guard klondike?.waste.last != nil else { return false }
        return move(cardAt: .waste, cardCount: 1, to: .home(0))
    }

    /// Klondike 타블로 카드 클릭 (뒤집힌 카드 = 뒤집기)
    func tapKlondikeColumn(column: Int, cardIndex: Int) {
        guard let k = klondike, k.columns.indices.contains(column) else { return }
        let cards = k.columns[column]
        guard cards.indices.contains(cardIndex) else { return }

        if !cards[cardIndex].faceUp {
            if cardIndex == cards.count - 1 {
                if let card = cards.last?.card {
                    apply(.flipColumnCard(columnIndex: column, card: card))
                }
            }
            return
        }

        handleColumnTap(
            column: column,
            cardIndex: cardIndex,
            columnCardCount: cards.count,
            movableCount: k.movableRun(from: column).count
        )
    }

    /// Klondike 홈셀 클릭: 선택 카드를 홈셀로 이동 시도
    func tapKlondikeHome(_ index: Int) {
        guard klondike != nil else { return }
        if selection != nil {
            _ = moveSelected(to: .home(index))
        }
    }

    /// Klondike 더블클릭: 홈셀로 자동 이동 시도
    @discardableResult
    func doubleClickKlondikeToHome(column: Int, cardIndex: Int) -> Bool {
        guard let k = klondike, k.columns.indices.contains(column) else { return false }
        let cards = k.columns[column]
        guard cards.indices.contains(cardIndex), cardIndex == cards.count - 1,
              cards.last?.faceUp == true else { return false }
        return move(cardAt: .column(column), cardCount: 1, to: .home(0))
    }

    /// Klondike 열 카드가 선택 시퀀스에 포함되는지
    func isKlondikeSelected(column: Int, cardIndex: Int) -> Bool {
        guard let sel = selection, sel.source == .column(column),
              let k = klondike else { return false }
        let fromBottom = k.columns[column].count - 1 - cardIndex
        return fromBottom < sel.cardCount
    }

    // MARK: - Forty Thieves 상호작용

    /// 스톡 클릭: 1장 드로 (재활용 없음 — 스톡이 비면 무시)
    func tapFortyThievesStock() {
        guard fortyThieves?.stock.isEmpty == false else { return }
        apply(.drawFromStock)
    }

    /// 웨이스트 클릭: 맨 위 카드 선택/해제
    func tapFortyThievesWaste() {
        guard fortyThieves?.waste.last != nil else { return }
        select(source: .waste, cardCount: 1)
    }

    /// 웨이스트 카드 더블클릭: 홈셀로
    @discardableResult
    func doubleClickFortyThievesWaste() -> Bool {
        guard fortyThieves?.waste.last != nil else { return false }
        return move(cardAt: .waste, cardCount: 1, to: .home(0))
    }

    /// Forty Thieves 타블로 카드 클릭 (전부 앞면)
    func tapFortyThievesColumn(column: Int, cardIndex: Int) {
        guard let f = fortyThieves, f.columns.indices.contains(column) else { return }
        let cards = f.columns[column]
        guard cards.indices.contains(cardIndex) else { return }
        handleColumnTap(
            column: column,
            cardIndex: cardIndex,
            columnCardCount: cards.count,
            movableCount: f.movableRun(from: column).count
        )
    }

    /// Forty Thieves 홈셀 클릭: 선택 카드를 홈셀로 이동 시도
    func tapFortyThievesHome(_ index: Int) {
        guard fortyThieves != nil else { return }
        if selection != nil {
            _ = moveSelected(to: .home(index))
        }
    }

    /// Forty Thieves 더블클릭: 홈셀로 자동 이동 시도
    @discardableResult
    func doubleClickFortyThievesToHome(column: Int, cardIndex: Int) -> Bool {
        guard let f = fortyThieves, f.columns.indices.contains(column) else { return false }
        let cards = f.columns[column]
        guard cards.indices.contains(cardIndex), cardIndex == cards.count - 1 else { return false }
        return move(cardAt: .column(column), cardCount: 1, to: .home(0))
    }

    /// Forty Thieves 열 카드가 선택 시퀀스에 포함되는지
    func isFortyThievesSelected(column: Int, cardIndex: Int) -> Bool {
        guard let sel = selection, sel.source == .column(column),
              let f = fortyThieves else { return false }
        let fromBottom = f.columns[column].count - 1 - cardIndex
        return fromBottom < sel.cardCount
    }

    // MARK: - Golf 상호작용

    /// 스톡 클릭: 1장 드로 (재활용 없음 — 스톡이 비면 무시)
    func tapGolfStock() {
        guard golf?.stock.isEmpty == false else { return }
        apply(.drawFromStock)
    }

    /// 웨이스트 클릭: 아무 동작 없음 (Golf 웨이스트는 제거 대상이 아니라 기준 카드)
    func tapGolfWaste() {}

    /// Golf 타블로 열 카드 클릭: 맨 아래 카드면 웨이스트로 제거 시도
    func tapGolfColumn(column: Int, cardIndex: Int) {
        guard let g = golf, g.columns.indices.contains(column) else { return }
        let cards = g.columns[column]
        guard cards.indices.contains(cardIndex), cardIndex == cards.count - 1 else { return }
        _ = move(cardAt: .column(column), cardCount: 1, to: .waste)
    }

    // MARK: - Pyramid 상호작용

    /// 스톡 클릭: 1장 드로 (재활용 없음 — 스톡이 비면 무시)
    func tapPyramidStock() {
        guard pyramid?.stock.isEmpty == false else { return }
        apply(.drawFromStock)
    }

    /// 웨이스트 클릭: 아무 동작 없음 (Pyramid 웨이스트는 기준 카드)
    func tapPyramidWaste() {}

    /// 피라미드 카드 클릭:
    /// - 노출 K(13) → 즉시 제거
    /// - 노출 카드 + 웨이스트 합 13 → 즉시 제거
    /// - 선택 없음 → 카드 선택, 선택 있음 → 합 13이면 짝 제거, 아니면 재선택
    func tapPyramidCard(index: Int) {
        guard let p = pyramid, p.pyramid.indices.contains(index), let card = p.pyramid[index] else { return }
        guard p.isExposed(index) else { return }

        if PyramidGame.cardValue(card) == 13 {
            _ = apply(.pyramidRemoveSingle(card: card))
            return
        }
        if let top = p.waste.last, PyramidGame.cardValue(card) + PyramidGame.cardValue(top) == 13 {
            _ = apply(.pyramidRemoveWastePair(card: card))
            return
        }

        if selection == nil {
            select(source: .pyramid(index), cardCount: 1)
        } else if let sel = selection, sel.source == .pyramid(index) {
            clearSelection()
        } else {
            guard let sel = selection, sel.cardCount == 1 else {
                select(source: .pyramid(index), cardCount: 1)
                return
            }
            let otherCard: Card?
            switch sel.source {
            case let .pyramid(other): otherCard = p.pyramid[other]
            default: otherCard = nil
            }
            if let other = otherCard, PyramidGame.cardValue(card) + PyramidGame.cardValue(other) == 13 {
                _ = apply(.pyramidRemovePair(first: card, second: other))
            } else {
                select(source: .pyramid(index), cardCount: 1)
            }
        }
    }

    /// 피라미드 카드가 선택 상태인지
    func isPyramidSelected(index: Int) -> Bool {
        guard let sel = selection, sel.source == .pyramid(index) else { return false }
        return sel.cardCount == 1
    }

    // MARK: - TriPeaks 상호작용

    /// 스톡 클릭: 1장 드로 (재활용 없음 — 스톡이 비면 무시)
    func tapTriPeaksStock() {
        guard triPeaks?.stock.isEmpty == false else { return }
        apply(.drawFromStock)
    }

    /// 웨이스트 클릭: 아무 동작 없음 (TriPeaks 웨이스트는 기준 카드)
    func tapTriPeaksWaste() {}

    /// 피크 카드 클릭: 노출 카드가 웨이스트와 1 랭크 차이면 웨이스트로 제거
    func tapTriPeaksCard(index: Int) {
        guard let t = triPeaks, t.peaks.indices.contains(index), let card = t.peaks[index] else { return }
        guard t.isExposed(index) else { return }
        _ = apply(.triPeaksRemove(card: card))
    }

    /// TriPeaks 피크 카드가 선택 상태인지 (탭 즉시 제거 방식 — 항상 false)
    func isTriPeaksSelected(index: Int) -> Bool { false }

    // MARK: - Spider 상호작용

    /// 스톡 클릭: 각 열에 1장씩 앞면 딜
    func tapSpiderStock() {
        guard spider != nil else { return }
        apply(.dealFromStock)
    }

    /// Spider 타블로 카드 클릭 (뒤집힌 카드 = 뒤집기)
    func tapSpiderColumn(column: Int, cardIndex: Int) {
        guard let s = spider, s.columns.indices.contains(column) else { return }
        let cards = s.columns[column]
        guard cards.indices.contains(cardIndex) else { return }

        if !cards[cardIndex].faceUp {
            if cardIndex == cards.count - 1 {
                // 스파이더는 뒤집힌 카드를 이동으로만 노출 (뒤집기 이동은 없음)
                // 목적지가 비면 뒤집을 수 있음 — 여기선 선택만 허용하지 않고 무시
            }
            return
        }

        handleColumnTap(
            column: column,
            cardIndex: cardIndex,
            columnCardCount: cards.count,
            movableCount: s.movableRun(from: column).count
        )
    }

    /// Spider 열 카드가 선택 시퀀스에 포함되는지
    func isSpiderSelected(column: Int, cardIndex: Int) -> Bool {
        guard let sel = selection, sel.source == .column(column),
              let s = spider else { return false }
        let fromBottom = s.columns[column].count - 1 - cardIndex
        return fromBottom < sel.cardCount
    }

    /// 홈 도착 카드 펄스 (0.5s 하이라이트 후 해제)
    private func pulseHomeCard(for move: Move) {
        let card: Card
        switch move {
        case let .columnToHome(_, c): card = c
        case let .freeCellToHome(_, c): card = c
        case let .wasteToFoundation(c): card = c
        default: return
        }
        homePulseTask?.cancel()
        lastHomeCard = card
        homePulseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.lastHomeCard = nil
        }
    }

    // MARK: - 메시지 (3초 후 자동 소멸)

    private func showMessage(_ text: String) {
        message = text
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                self?.message = nil
            }
        }
    }

    private func dismissMessage() {
        dismissTask?.cancel()
        message = nil
    }

    private func checkState() {
        let isWon = currentIsWon
        if isWon {
            stopElapsedTimer()
            stats.recordWin(variant, moves: currentMoveCount)
            if let start = gameStartedAt {
                let seconds = Date().timeIntervalSince(start)
                stats.recordWinTime(seconds, for: variant)
                recordStore.record(RecordStore.GameRecord(
                    gameNumber: currentGameNumber,
                    variant: variant,
                    seconds: seconds,
                    moves: currentMoveCount
                ), for: variant)
                gameStartedAt = nil
            }
            clearSave()
            SoundPlayer.shared.playWinSequence(volume: settings.soundVolume)
            showMessage("승리! 게임을 클리어했습니다.")
            showNextGameButton = true
        } else if let s = spider {
            if !s.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let k = klondike {
            if !k.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let y = yukon {
            if !y.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let f = fortyThieves {
            if !f.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let g = golf {
            if !g.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let p = pyramid {
            if !p.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if let t = triPeaks {
            if !t.hasAnyMove {
                stats.recordLoss(variant)
                showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
            }
        } else if !game.hasAnyMove {
            stats.recordLoss(variant)
            showMessage("이동 가능한 수가 없습니다. 새 게임을 시작하세요.")
        }
    }

    // MARK: - 자동 저장

    func persist() {
        if let s = spider {
            gameSaver.save(s)
        } else if let k = klondike {
            gameSaver.save(k)
        } else if let y = yukon {
            gameSaver.save(y)
        } else if let f = fortyThieves {
            gameSaver.save(f)
        } else if let g = golf {
            gameSaver.save(g)
        } else if let p = pyramid {
            gameSaver.save(p)
        } else if let t = triPeaks {
            gameSaver.save(t)
        } else {
            switch game.variant {
            case .seaTower: gameSaver.saveSeaTower(game)
            case .superFreeCell: gameSaver.saveSuperFreeCell(game)
            default: gameSaver.save(game)
            }
        }
    }

    private func clearSave() {
        gameSaver.clear()
        gameSaver.clearKlondike()
        gameSaver.clearSpider()
        gameSaver.clearSeaTower()
        gameSaver.clearSuperFreeCell()
        gameSaver.clearYukon()
        gameSaver.clearFortyThieves()
        gameSaver.clearGolf()
        gameSaver.clearPyramid()
        gameSaver.clearTriPeaks()
    }

    func canMove(cardAt source: CardSource, cardCount: Int, to destination: Destination) -> Bool {
        guard let move = makeMove(from: source, cardCount: cardCount, to: destination) else {
            return false
        }
        if let s = spider {
            return s.canMove(move)
        }
        if let k = klondike {
            return k.canMove(move)
        }
        if let y = yukon {
            return y.canMove(move)
        }
        if let f = fortyThieves {
            return f.canMove(move)
        }
        if let g = golf {
            return g.canMove(move)
        }
        if let p = pyramid {
            return p.canMove(move)
        }
        if let t = triPeaks {
            return t.canMove(move)
        }
        return game.canMove(move)
    }

    private func makeMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        if spider != nil {
            return makeSpiderMove(from: source, cardCount: cardCount, to: destination)
        }
        if klondike != nil {
            return makeKlondikeMove(from: source, cardCount: cardCount, to: destination)
        }
        if yukon != nil {
            return makeYukonMove(from: source, cardCount: cardCount, to: destination)
        }
        if fortyThieves != nil {
            return makeFortyThievesMove(from: source, cardCount: cardCount, to: destination)
        }
        if golf != nil {
            return makeGolfMove(from: source, cardCount: cardCount, to: destination)
        }
        if pyramid != nil {
            return makePyramidMove(from: source, cardCount: cardCount, to: destination)
        }
        if triPeaks != nil {
            return makeTriPeaksMove(from: source, cardCount: cardCount, to: destination)
        }
        return makeFreeCellMove(from: source, cardCount: cardCount, to: destination)
    }

    /// Yukon 이동 생성 (열 → 열 / 열 → 홈)
    private func makeYukonMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        switch (source, destination) {
        case let (.column(from), .column(to)):
            return .columnToColumn(from: from, to: to, cardCount: cardCount)
        case let (.column(from), .home(_)):
            guard cardCount == 1, let card = yukon?.columns[from].last?.card else { return nil }
            return .columnToHome(columnIndex: from, card: card)
        default:
            return nil
        }
    }

    /// Spider 이동 생성 (열 → 열)
    private func makeSpiderMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let s = spider else { return nil }
        switch (source, destination) {
        case let (.column(from), .column(to)):
            guard s.canMove(.columnToColumn(from: from, to: to, cardCount: cardCount)) else { return nil }
            return .columnToColumn(from: from, to: to, cardCount: cardCount)
        default:
            return nil
        }
    }

    /// Forty Thieves 이동 생성 (열 → 열/홈, 웨이스트 → 열/홈)
    private func makeFortyThievesMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let f = fortyThieves else { return nil }
        switch (source, destination) {
        case let (.column(from), .column(to)):
            return .columnToColumn(from: from, to: to, cardCount: cardCount)

        case let (.column(from), .home(_)):
            guard cardCount == 1, let card = f.columns[from].last else { return nil }
            return .columnToHome(columnIndex: from, card: card)

        case let (.waste, .column(to)):
            guard let card = f.waste.last else { return nil }
            return .wasteToColumn(columnIndex: to, card: card)

        case (.waste, .home):
            guard let card = f.waste.last else { return nil }
            return .wasteToFoundation(card: card)

        default:
            return nil
        }
    }

    /// Golf 이동 생성 (열 → 웨이스트 제거)
    private func makeGolfMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let g = golf else { return nil }
        switch (source, destination) {
        case let (.column(from), .waste):
            guard cardCount == 1, let card = g.columns[from].last else { return nil }
            return .columnToWaste(columnIndex: from, card: card)

        default:
            return nil
        }
    }

    /// Pyramid 이동 생성 (노출 카드 → 웨이스트 짝 제거)
    private func makePyramidMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let p = pyramid else { return nil }
        switch (source, destination) {
        case let (.pyramid(index), .waste):
            guard cardCount == 1, p.pyramid.indices.contains(index), let card = p.pyramid[index] else { return nil }
            return .pyramidRemoveWastePair(card: card)

        default:
            return nil
        }
    }

    /// TriPeaks 이동 생성 (노출 카드 → 웨이스트 제거)
    private func makeTriPeaksMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let t = triPeaks else { return nil }
        switch (source, destination) {
        case let (.triPeaks(index), .waste):
            guard cardCount == 1, t.peaks.indices.contains(index), let card = t.peaks[index] else { return nil }
            return .triPeaksRemove(card: card)

        default:
            return nil
        }
    }

    private func makeFreeCellMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        switch (source, destination) {
        case let (.column(from), .column(to)):
            return .columnToColumn(from: from, to: to, cardCount: cardCount)

        case let (.column(from), .freeCell(fc)):
            guard game.freeCells.indices.contains(fc), let card = game.columns[from].last else { return nil }
            return .columnToFreeCell(columnIndex: from, freeCellIndex: fc, card: card)

        case let (.column(from), .home(_)):
            guard cardCount == 1, let card = game.columns[from].last else { return nil }
            return .columnToHome(columnIndex: from, card: card)

        case let (.freeCell(fc), .column(to)):
            guard game.freeCells.indices.contains(fc), let card = game.freeCells[fc] else { return nil }
            return .freeCellToColumn(freeCellIndex: fc, columnIndex: to, card: card)

        case let (.freeCell(fc), .home(_)):
            guard game.freeCells.indices.contains(fc), let card = game.freeCells[fc] else { return nil }
            return .freeCellToHome(freeCellIndex: fc, card: card)

        case let (.home(h), .column(to)):
            guard let card = game.homes[h].last else { return nil }
            return .homeToColumn(homeIndex: h, columnIndex: to, card: card)

        case let (.home(h), .freeCell(fc)):
            guard game.freeCells.indices.contains(fc), let card = game.homes[h].last else { return nil }
            return .homeToFreeCell(homeIndex: h, freeCellIndex: fc, card: card)

        default:
            return nil
        }
    }

    /// Klondike 이동 생성 (웨이스트/스톡/열/홈셀)
    private func makeKlondikeMove(from source: CardSource, cardCount: Int, to destination: Destination) -> Move? {
        guard let k = klondike else { return nil }
        switch (source, destination) {
        case let (.column(from), .column(to)):
            return .columnToColumn(from: from, to: to, cardCount: cardCount)

        case let (.column(from), .home(_)):
            guard cardCount == 1, let card = k.columns[from].last?.card else { return nil }
            return .columnToHome(columnIndex: from, card: card)

        case let (.waste, .column(to)):
            guard let card = k.waste.last else { return nil }
            return .wasteToColumn(columnIndex: to, card: card)

        case (.waste, .home):
            guard let card = k.waste.last else { return nil }
            return .wasteToFoundation(card: card)

        case let (.home(h), .column(to)):
            guard k.homes.indices.contains(h), let card = k.homes[h].last else { return nil }
            return .homeToColumn(homeIndex: h, columnIndex: to, card: card)

        default:
            return nil
        }
    }

    // MARK: - 실행 취소 / 다시 실행

    func undo() {
        if spider != nil {
            spider?.undo()
        } else if klondike != nil {
            klondike?.undo()
        } else if yukon != nil {
            yukon?.undo()
        } else if fortyThieves != nil {
            fortyThieves?.undo()
        } else if golf != nil {
            golf?.undo()
        } else if pyramid != nil {
            pyramid?.undo()
        } else if triPeaks != nil {
            triPeaks?.undo()
        } else {
            game.undo()
        }
        selection = nil
        dismissMessage()
        highlightedMove = nil
        resetWinUIAfterUndoIfNeeded()
        persist()
    }

    func redo() {
        if spider != nil {
            spider?.redo()
        } else if klondike != nil {
            klondike?.redo()
        } else if yukon != nil {
            yukon?.redo()
        } else if fortyThieves != nil {
            fortyThieves?.redo()
        } else if golf != nil {
            golf?.redo()
        } else if pyramid != nil {
            pyramid?.redo()
        } else if triPeaks != nil {
            triPeaks?.redo()
        } else {
            game.redo()
        }
        selection = nil
        dismissMessage()
        highlightedMove = nil
        if currentIsWon {
            showNextGameButton = true
        }
        persist()
    }

    /// 승리 직후 undo로 게임이 미승리 상태가 되면 승리 UI를 정리하고 타이머를 재개한다.
    private func resetWinUIAfterUndoIfNeeded() {
        guard !currentIsWon else { return }
        if showNextGameButton || gameStartedAt == nil {
            showNextGameButton = false
            gameStartedAt = Date()
            startElapsedTimer()
        }
    }

    func canUndo() -> Bool {
        spider?.canUndo ?? klondike?.canUndo ?? yukon?.canUndo ?? fortyThieves?.canUndo ?? golf?.canUndo ?? pyramid?.canUndo ?? triPeaks?.canUndo ?? game.canUndo
    }

    func canRedo() -> Bool {
        spider?.canRedo ?? klondike?.canRedo ?? yukon?.canRedo ?? fortyThieves?.canRedo ?? golf?.canRedo ?? pyramid?.canRedo ?? triPeaks?.canRedo ?? game.canRedo
    }

    // MARK: - 힌트 / 자동 플레이

    /// 현재 게임의 유효 이동 후보 (전체 힌트/힌트 순환 공용)
    var currentHintCandidates: [Move] {
        if let s = spider {
            return s.hintCandidates()
        } else if let k = klondike {
            return k.hintCandidates()
        } else if let y = yukon {
            return y.hintCandidates()
        } else if let f = fortyThieves {
            return f.hintCandidates()
        } else if let g = golf {
            return g.hintCandidates()
        } else if let p = pyramid {
            return p.hintCandidates()
        } else if let t = triPeaks {
            return t.hintCandidates()
        } else {
            return game.hintCandidates()
        }
    }

    /// 표시할 힌트 이동 목록 — 전체 힌트 ON이면 모든 후보, 아니면 단일 하이라이트
    var displayedHintMoves: [Move] {
        if showAllHints {
            return currentHintCandidates
        }
        if let move = highlightedMove {
            return [move]
        }
        return []
    }

    /// 전체 힌트 강조 토글 — 켜면 유효 이동 전체의 소스를 동시에 강조
    func toggleAllHints() {
        showAllHints.toggle()
        if showAllHints {
            showMessage("전체 힌트: 이동 가능한 \(currentHintCandidates.count)곳을 표시합니다.")
        } else {
            clearAllHints()
            dismissMessage()
        }
    }

    /// 전체 힌트 해제 (강조만 제거, 단일 힌트 상태는 유지)
    func clearAllHints() {
        showAllHints = false
    }

    /// 힌트: 다음 후보로 순환하며 해당 이동을 하이라이트 (적용하지 않음)
    func hint() {
        let candidates = currentHintCandidates
        guard !candidates.isEmpty else {
            highlightedMove = nil
            hintAnimationMove = nil
            hintAnimationTick += 1
            showMessage("이동 가능한 수가 없습니다.")
            return
        }
        hintCandidates = candidates
        if hintIndex >= candidates.count {
            hintIndex = 0
        }
        let move = candidates[hintIndex]
        let shown = hintIndex + 1
        hintIndex = (hintIndex + 1) % candidates.count
        highlightedMove = move
        hintAnimationMove = move
        hintAnimationTick += 1
        showMessage("힌트 \(shown)/\(candidates.count): \(moveDescription(move))")
    }

    /// 하이라이트된 힌트 이동 적용 (엔터)
    @discardableResult
    func applyHighlightedHint() -> Bool {
        guard let move = highlightedMove else { return false }
        highlightedMove = nil
        return apply(move)
    }

    func runAutoPlay() {
        var applied = 0
        var hasMore = true
        while hasMore {
            let moves: [Move]
            if let s = spider {
                // 스파이더는 자동 플레이 개념이 없음 (완성 수트는 이동 규칙상 즉시 제거됨)
                _ = s
                moves = []
            } else if let k = klondike {
                moves = k.hintCandidates().filter {
                    if case .columnToHome = $0 { return true }
                    if case .wasteToFoundation = $0 { return true }
                    return false
                }
            } else if let y = yukon {
                moves = y.hintCandidates().filter {
                    if case .columnToHome = $0 { return true }
                    return false
                }
            } else if let f = fortyThieves {
                moves = f.hintCandidates().filter {
                    if case .columnToHome = $0 { return true }
                    if case .wasteToFoundation = $0 { return true }
                    return false
                }
            } else if golf != nil {
                // 골프는 자동 플레이 없음 (제거 기반 — 홈 이동 개념 부적합)
                moves = []
            } else if pyramid != nil {
                // 피라미드는 자동 플레이 없음 (제거 기반 — 홈 이동 개념 부적합)
                moves = []
            } else if triPeaks != nil {
                // 트리피크스는 자동 플레이 없음 (제거 기반 — 홈 이동 개념 부적합)
                moves = []
            } else {
                moves = AutoPlay.safeAutoPlayMoves(in: game)
            }
            hasMore = false
            for move in moves {
                if applyRaw(move) {
                    applied += 1
                    hasMore = true
                }
            }
        }
        if applied > 0 {
            SoundPlayer.shared.play(.home, enabled: settings.soundEnabled, volume: settings.soundVolume)
            showMessage("자동 플레이: \(applied)장을 홈셀로 이동했습니다.")
        }
        checkState()
        persist()
    }

    /// 자동 완성: 승리 직전 상태(모든 카드가 홈으로 이동 가능)라면 남은 카드를 홈으로 정리한다.
    /// 홈셀 중심 게임(freecell/bakers/seaTower/superFreeCell/klondike/yukon/fortyThieves)만.
    @discardableResult
    func runAutoFinish() -> Bool {
        guard settings.autoFinishEnabled else { return false }
        guard autoFinishConditionHolds() else { return false }

        var applied = 0
        var guardCount = 0
        while guardCount < 500 {
            guardCount += 1
            let homeMoves = homeMovesOnlyFilter()
            guard !homeMoves.isEmpty else { break }
            var progressed = false
            for move in homeMoves {
                if applyRaw(move) {
                    applied += 1
                    progressed = true
                }
            }
            if !progressed { break }
        }
        if applied > 0 {
            SoundPlayer.shared.play(.home, enabled: settings.soundEnabled, volume: settings.soundVolume)
            showMessage("자동 완성: \(applied)장을 마무리했습니다.")
        }
        checkState()
        persist()
        return applied > 0
    }

    /// 자동 완성 대상 게임이며 승리 직전 상태인지 (GameCore 판단 위임)
    private func autoFinishConditionHolds() -> Bool {
        if spider != nil || golf != nil || pyramid != nil || triPeaks != nil {
            return false
        }
        if let k = klondike { return k.canAutoFinish }
        if let y = yukon { return y.canAutoFinish }
        if let f = fortyThieves { return f.canAutoFinish }
        return game.canAutoFinish
    }

    /// 현재 게임의 홈 이동 후보만 추출 (자동 완성용)
    private func homeMovesOnlyFilter() -> [Move] {
        if let k = klondike {
            return k.hintCandidates().filter {
                if case .columnToHome = $0 { return true }
                if case .wasteToFoundation = $0 { return true }
                return false
            }
        }
        if let y = yukon {
            return y.hintCandidates().filter {
                if case .columnToHome = $0 { return true }
                return false
            }
        }
        if let f = fortyThieves {
            return f.hintCandidates().filter {
                if case .columnToHome = $0 { return true }
                if case .wasteToFoundation = $0 { return true }
                return false
            }
        }
        if spider != nil || golf != nil || pyramid != nil || triPeaks != nil {
            return []
        }
        let safe = AutoPlay.safeAutoPlayMoves(in: game)
        return safe.isEmpty ? game.hintCandidates().filter { $0.isHomeMove } : safe
    }

    /// 자동 플레이용: 소리/펄스 없이 순수 적용 (재귀 방지)
    @discardableResult
    private func applyRaw(_ move: Move) -> Bool {
        if spider != nil {
            return spider?.apply(move) == true
        }
        if klondike != nil {
            return klondike?.apply(move) == true
        }
        if yukon != nil {
            return yukon?.apply(move) == true
        }
        if fortyThieves != nil {
            return fortyThieves?.apply(move) == true
        }
        if golf != nil {
            return golf?.apply(move) == true
        }
        if pyramid != nil {
            return pyramid?.apply(move) == true
        }
        if triPeaks != nil {
            return triPeaks?.apply(move) == true
        }
        return game.apply(move)
    }

    private func moveDescription(_ move: Move) -> String {
        switch move {
        case .columnToColumn(let from, let to, let count):
            return "열 \(from + 1) → 열 \(to + 1) (\(count)장)"
        case .columnToFreeCell(let ci, let fc, _):
            return "열 \(ci + 1) → 프리셀 \(fc + 1)"
        case .freeCellToColumn(let fc, let ci, _):
            return "프리셀 \(fc + 1) → 열 \(ci + 1)"
        case .columnToHome(let ci, let card):
            return "열 \(ci + 1) → 홈셀 (\(card.shortDescription))"
        case .freeCellToHome(let fc, let card):
            return "프리셀 \(fc + 1) → 홈셀 (\(card.shortDescription))"
        case .homeToColumn(let hi, let ci, _):
            return "홈셀 \(hi + 1) → 열 \(ci + 1)"
        case .homeToFreeCell(let hi, let fc, _):
            return "홈셀 \(hi + 1) → 프리셀 \(fc + 1)"
        case .drawFromStock:
            return "스톡 → 웨이스트"
        case .recycleStock:
            return "웨이스트 → 스톡 재활용"
        case .wasteToColumn(let ci, let card):
            return "웨이스트 → 열 \(ci + 1) (\(card.shortDescription))"
        case .wasteToFoundation(let card):
            return "웨이스트 → 홈셀 (\(card.shortDescription))"
        case .flipColumnCard(let ci, let card):
            return "열 \(ci + 1) 카드 뒤집기 (\(card.shortDescription))"
        case .dealFromStock:
            return "스톡에서 각 열에 카드 딜"
        case .columnToWaste(let ci, let card):
            return "열 \(ci + 1) → 웨이스트 제거 (\(card.shortDescription))"
        case .pyramidRemovePair(let first, let second):
            return "피라미드 짝 제거 (\(first.shortDescription)+\(second.shortDescription))"
        case .pyramidRemoveWastePair(let card):
            return "피라미드+웨이스트 제거 (\(card.shortDescription))"
        case .pyramidRemoveSingle(let card):
            return "피라미드 K 제거 (\(card.shortDescription))"
        case .triPeaksRemove(let card):
            return "피크 → 웨이스트 제거 (\(card.shortDescription))"
        }
    }

    // MARK: - 게임 번호

    func applyGameNumber() {
        guard let number = Int(gameNumberText) else {
            showMessage("유효한 번호를 입력하세요 (1 ~ 1,000,000).")
            return
        }
        requestNewGame(number: number)
        showingGameNumber = false
    }

    /// 게임 번호 시트에서 선택한 변형과 함께 시작
    func applyGameNumber(variant: GameVariant) {
        guard let number = Int(gameNumberText) else {
            showMessage("유효한 번호를 입력하세요 (1 ~ 1,000,000).")
            return
        }
        requestNewGame(number: number, variant: variant)
        showingGameNumber = false
    }
}
