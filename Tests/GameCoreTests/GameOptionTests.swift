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

    // MARK: - 옵션 없는 변형

    func testOtherVariantsHaveNoOptions() {
        for variant in GameVariant.allCases where variant != .spider {
            XCTAssertTrue(variant.optionDefinitions.isEmpty, "\(variant)는 옵션이 없어야 함")
        }
    }
}
