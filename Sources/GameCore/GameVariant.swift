/// 카드 게임 형식
public enum GameVariant: String, Codable, CaseIterable, Sendable {
    /// 표준 프리셀 — 프리셀 4개, 타블로 교대색, 수퍼무브
    case freecell
    /// Baker's Game — 프리셀 없음, 타블로 같은 수트, 한 번에 한 장만
    case bakersGame
    /// Klondike — 7열, 스톡/웨이스트, 교대색, 뒤집힌 카드, 홈셀 4개
    case klondike
    /// Spider — 10열, 스톡 5더미, 같은 수트 K→A 완성, 홈셀 없음
    case spider
    /// Sea Tower (Sea Towers/Seahaven Towers) — 10열×5장, 프리셀 4개(2장 시작 배치), 같은 수트, 빈 열 K만
    case seaTower
    /// Super FreeCell (Double FreeCell) — 2덱 104장, 10열, 프리셀 6개, 홈셀 수트당 26장
    case superFreeCell
    /// Yukon — 7열, 스톡/웨이스트 없음, 유콘 이동(앞면 카드+위 전부 그룹 이동), 교대색, 뒤집힌 카드
    case yukon
    /// Forty Thieves — 2덱 104장, 10열×4장(전부 앞면)+스톡 64장, 같은 수트 K→A, 빈 열 아무 카드, 홈셀 8개
    case fortyThieves
    /// Golf — 1덱 52장, 7열×5장(전부 앞면)+스톡 16장+웨이스트 1장, 웨이스트와 1 차이/같은 랭크 카드 제거
    case golf
    /// Pyramid — 1덱 52장, 피라미드 28장(7줄)+스톡 24장, 합 13인 노출 카드 제거
    case pyramid
    /// TriPeaks — 1덱 52장, 3개 피크(각 4줄)+스톡 21장+웨이스트 1장, 웨이스트와 1 랭크 차이인 노출 카드 제거
    case triPeaks
    /// Scorpion — 1덱 52장, 7열×7장+예비 3장, 같은 수트 내림차순+그룹 이동, 빈 열 K만, 홈 없음(열에 K→A 완성)
    case scorpion

    public var displayName: String {
        switch self {
        case .freecell: "FreeCell"
        case .bakersGame: "Baker's Game"
        case .klondike: "Klondike"
        case .spider: "Spider"
        case .seaTower: "Sea Tower"
        case .superFreeCell: "Super FreeCell"
        case .yukon: "Yukon"
        case .fortyThieves: "Forty Thieves"
        case .golf: "Golf"
        case .pyramid: "Pyramid"
        case .triPeaks: "TriPeaks"
        case .scorpion: "Scorpion"
        }
    }

    /// 변형별 옵션 정의 — 게임 번호 시트/설정에서 자동 렌더링.
    /// 새 게임이 옵션을 가지면 여기에 추가한다.
    public var optionDefinitions: [GameOption] {
        switch self {
        case .klondike:
            return [
                GameOption(
                    id: "klondikeDraw",
                    title: "스톡 드로",
                    choices: ["1", "3"].map { GameOptionChoice(id: $0, title: $0 + "장") }
                )
            ]
        case .spider:
            return [
                GameOption(
                    id: "spiderDifficulty",
                    title: "난이도",
                    choices: SpiderGame.Difficulty.allCases.map {
                        GameOptionChoice(id: String($0.rawValue), title: $0.displayName)
                    }
                )
            ]
        case .freecell, .bakersGame, .seaTower, .superFreeCell:
            return [
                GameOption(
                    id: "winnable",
                    title: "승리 보장",
                    choices: [
                        GameOptionChoice(id: "normal", title: "일반"),
                        GameOptionChoice(id: "guaranteed", title: "승리 보장"),
                    ]
                )
            ]
        default:
            return []
        }
    }
}

/// 게임 카테고리 — 홈 화면 그룹 표시용. (T-222)
public enum GameCategory: String, CaseIterable, Sendable {
    /// FreeCell 계열 (FreeCell/Baker's/Sea Tower/Super FreeCell)
    case freeCell
    /// 스톡 계열 (Klondike/Yukon)
    case stock
    /// 스파이더 계열 (Spider/Forty Thieves/Scorpion)
    case spider
    /// 카드 제거 (Golf/Pyramid/TriPeaks)
    case removal

    public var displayName: String {
        switch self {
        case .freeCell: "FreeCell 계열"
        case .stock: "스톡 계열"
        case .spider: "스파이더 계열"
        case .removal: "카드 제거"
        }
    }
}

extension GameVariant {
    /// 카테고리 — 홈 화면 그룹 표시용. (T-222)
    public var category: GameCategory {
        switch self {
        case .freecell, .bakersGame, .seaTower, .superFreeCell: .freeCell
        case .klondike, .yukon: .stock
        case .spider, .fortyThieves, .scorpion: .spider
        case .golf, .pyramid, .triPeaks: .removal
        }
    }

    /// 변형별 대표 난이도 (게임 규칙 복잡성 기준 고정값) — 홈 타일/게임 중 난이도 표시용. (T-222)
    /// FreeCell 계열 실측(`Difficulty.measure`)은 판당 최대 8s라 게임 중 표시엔 변형 고정값 사용.
    public var baseDifficulty: Difficulty {
        switch self {
        case .scorpion, .golf: .easy
        case .freecell, .bakersGame, .klondike, .spider, .pyramid, .triPeaks: .medium
        case .seaTower, .superFreeCell, .yukon, .fortyThieves: .hard
        }
    }

    /// 카테고리 내 보조 정렬 순서 (개발순 고정) — 동일 난이도일 때 사용. (T-222)
    public var categoryOrder: Int {
        switch self {
        case .freecell: 0
        case .bakersGame: 1
        case .seaTower: 2
        case .superFreeCell: 3
        case .klondike: 0
        case .yukon: 1
        case .scorpion: 0
        case .spider: 1
        case .fortyThieves: 2
        case .golf: 0
        case .pyramid: 1
        case .triPeaks: 2
        }
    }

    /// 홈 화면 표시 정렬 — 카테고리 → 난이도(쉬움→어려움) → categoryOrder. (T-222)
    public static var homeOrderedVariants: [GameVariant] {
        let difficultyRank = { (d: Difficulty) -> Int in
            switch d {
            case .easy: 0
            case .medium: 1
            case .hard: 2
            case .unmeasured: 3
            }
        }
        return GameCategory.allCases.flatMap { category in
            GameVariant.allCases
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    let ld = difficultyRank(lhs.baseDifficulty)
                    let rd = difficultyRank(rhs.baseDifficulty)
                    if ld != rd { return ld < rd }
                    return lhs.categoryOrder < rhs.categoryOrder
                }
        }
    }
}