import XCTest
@testable import GameCore

final class GameOptionTests: XCTestCase {

    // MARK: - Spider 옵션 (난이도)

    func testSpiderOptionDefinitions() {
        let options = GameVariant.spider.optionDefinitions
        XCTAssertEqual(options.count, 1)
        guard let difficulty = options.first else { return }

        XCTAssertEqual(difficulty.id, "spiderDifficulty")
        XCTAssertEqual(difficulty.title, "난이도")
        XCTAssertEqual(difficulty.choices.count, SpiderGame.Difficulty.allCases.count)

        let ids = difficulty.choices.map(\.id)
        XCTAssertEqual(ids, ["1", "2", "4"])
        XCTAssertEqual(difficulty.choices.map(\.title),
                       SpiderGame.Difficulty.allCases.map(\.displayName))

        // 선택지 id ↔ Difficulty 왕복
        for choice in difficulty.choices {
            XCTAssertNotNil(Int(choice.id).flatMap(SpiderGame.Difficulty.init(rawValue:)))
        }
    }

    // MARK: - Klondike 옵션 (스톡 드로)

    func testKlondikeOptionDefinitions() {
        let options = GameVariant.klondike.optionDefinitions
        XCTAssertEqual(options.count, 1)
        guard let draw = options.first else { return }

        XCTAssertEqual(draw.id, "klondikeDraw")
        XCTAssertEqual(draw.title, "스톡 드로")
        XCTAssertEqual(draw.choices.map(\.title), ["1장", "3장"])
        XCTAssertEqual(draw.choices.map(\.id), ["1", "3"])
    }

    // MARK: - FreeCell 계열 옵션 (승리 보장)

    func testFreeCellFamilyWinnableOptionDefinitions() {
        let freeCellFamily: [GameVariant] = [.freecell, .bakersGame, .seaTower, .superFreeCell]
        for variant in freeCellFamily {
            let options = variant.optionDefinitions
            XCTAssertEqual(options.count, 1, "\(variant)는 winnable 옵션 1개")
            guard let winnable = options.first else { continue }

            XCTAssertEqual(winnable.id, "winnable")
            XCTAssertEqual(winnable.title, "승리 보장")
            XCTAssertEqual(winnable.choices.map(\.id), ["normal", "guaranteed"])
            XCTAssertEqual(winnable.choices.map(\.title), ["일반", "승리 보장"])
        }
    }

    // MARK: - 옵션 없는 변형

    func testOtherVariantsHaveNoOptions() {
        let withOptions: Set<GameVariant> = [.spider, .klondike, .freecell, .bakersGame, .seaTower, .superFreeCell]
        for variant in GameVariant.allCases where !withOptions.contains(variant) {
            XCTAssertTrue(variant.optionDefinitions.isEmpty, "\(variant)는 옵션이 없어야 함")
        }
    }
}
