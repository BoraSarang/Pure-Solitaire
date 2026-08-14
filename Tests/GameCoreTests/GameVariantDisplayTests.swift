import XCTest
@testable import GameCore

/// GameVariant 표시 전용 속성 — 카테고리/난이도/정렬 테스트 (T-222)
final class GameVariantDisplayTests: XCTestCase {

    /// 12종 모두 카테고리 매핑 존재
    func testAllVariantsHaveCategory() {
        for variant in GameVariant.allCases {
            XCTAssertFalse(variant.category.displayName.isEmpty)
        }
        XCTAssertEqual(GameVariant.allCases.count, 12)
    }

    /// 카테고리 그룹 구성 (4그룹)
    func testCategoryGrouping() {
        let freeCell: Set<GameVariant> = [.freecell, .bakersGame, .seaTower, .superFreeCell]
        let stock: Set<GameVariant> = [.klondike, .yukon]
        let spider: Set<GameVariant> = [.spider, .fortyThieves, .scorpion]
        let removal: Set<GameVariant> = [.golf, .pyramid, .triPeaks]

        for variant in GameVariant.allCases {
            switch variant.category {
            case .freeCell: XCTAssertTrue(freeCell.contains(variant))
            case .stock: XCTAssertTrue(stock.contains(variant))
            case .spider: XCTAssertTrue(spider.contains(variant))
            case .removal: XCTAssertTrue(removal.contains(variant))
            }
        }
    }

    /// 변형별 난이도 고정값
    func testBaseDifficultyMapping() {
        XCTAssertEqual(GameVariant.scorpion.baseDifficulty, .easy)
        XCTAssertEqual(GameVariant.golf.baseDifficulty, .easy)
        XCTAssertEqual(GameVariant.freecell.baseDifficulty, .medium)
        XCTAssertEqual(GameVariant.klondike.baseDifficulty, .medium)
        XCTAssertEqual(GameVariant.spider.baseDifficulty, .medium)
        XCTAssertEqual(GameVariant.seaTower.baseDifficulty, .hard)
        XCTAssertEqual(GameVariant.superFreeCell.baseDifficulty, .hard)
        XCTAssertEqual(GameVariant.yukon.baseDifficulty, .hard)
        XCTAssertEqual(GameVariant.fortyThieves.baseDifficulty, .hard)
    }

    /// 홈 정렬 — 카테고리 순서 → 그룹 내 난이도순 → categoryOrder
    func testHomeOrderedVariants() {
        let ordered = GameVariant.homeOrderedVariants
        XCTAssertEqual(ordered.count, GameVariant.allCases.count)

        // 카테고리 순서: freeCell → stock → spider → removal
        let categorySequence = ordered.map(\.category)
        let expected = GameCategory.allCases.flatMap { c in
            ordered.filter { $0.category == c }
        }.map(\.category)
        XCTAssertEqual(categorySequence, expected)

        // 그룹 내 난이도 오름차순 (쉬움 먼저)
        let difficultyRank: [Difficulty: Int] = [.easy: 0, .medium: 1, .hard: 2, .unmeasured: 3]
        for category in GameCategory.allCases {
            let group = ordered.filter { $0.category == category }
            let ranks = group.map { difficultyRank[$0.baseDifficulty] ?? 3 }
            XCTAssertEqual(ranks, ranks.sorted(), "\(category) 내 난이도순 정렬 실패")
        }

        // 첫 번째는 FreeCell 계열, 첫 항목은 medium 중 categoryOrder 0 (FreeCell)
        XCTAssertEqual(ordered.first, .freecell)
    }
}