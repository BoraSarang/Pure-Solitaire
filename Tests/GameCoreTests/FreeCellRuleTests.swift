import XCTest
@testable import GameCore

final class FreeCellRuleTests: XCTestCase {

    func testCanMoveToColumn_EmptyColumn_AllowsAnyCard() {
        XCTAssertTrue(FreeCellRule.canMoveToColumn(Card(rawValue: 0), topCard: nil))
    }

    func testCanMoveToColumn_DescendingAlternating() {
        // 5♥ 위에 4♣ (내림차순, 교대색) → 허용
        XCTAssertTrue(FreeCellRule.canMoveToColumn(
            Card(suit: .clubs, rank: .four),
            topCard: Card(suit: .hearts, rank: .five)
        ))
    }

    func testCanMoveToColumn_SameColor_Rejected() {
        // 5♣ 위에 4♠ (내림차순이지만 같은 색) → 거부
        XCTAssertFalse(FreeCellRule.canMoveToColumn(
            Card(suit: .spades, rank: .four),
            topCard: Card(suit: .clubs, rank: .five)
        ))
    }

    func testCanMoveToColumn_WrongOrder_Rejected() {
        // 5♥ 위에 6♣ (오름차순) → 거부
        XCTAssertFalse(FreeCellRule.canMoveToColumn(
            Card(suit: .clubs, rank: .six),
            topCard: Card(suit: .hearts, rank: .five)
        ))
    }

    func testCanMoveToHome_AceOnEmpty() {
        XCTAssertTrue(FreeCellRule.canMoveToHome(Card(suit: .hearts, rank: .ace), topCard: nil))
        XCTAssertFalse(FreeCellRule.canMoveToHome(Card(suit: .hearts, rank: .two), topCard: nil))
    }

    func testCanMoveToHome_SameSuitAscending() {
        // 5♥ 위에 6♥ → 허용
        XCTAssertTrue(FreeCellRule.canMoveToHome(
            Card(suit: .hearts, rank: .six),
            topCard: Card(suit: .hearts, rank: .five)
        ))
        // 다른 무늬 → 거부
        XCTAssertFalse(FreeCellRule.canMoveToHome(
            Card(suit: .diamonds, rank: .six),
            topCard: Card(suit: .hearts, rank: .five)
        ))
    }

    func testMovableRun() {
        // 아래에서 위로: 2♠, 3♥, 4♠ (내림차순+교대색) → run [4♠,3♥,2♠] (top→bottom)
        let column = [
            Card(suit: .spades, rank: .four),
            Card(suit: .hearts, rank: .three),
            Card(suit: .spades, rank: .two)
        ]
        let run = FreeCellRule.movableRun(from: column)
        XCTAssertEqual(run.map(\.shortDescription), ["4S", "3H", "2S"])
    }

    func testMovableRun_BreaksOnSameColor() {
        // 2♠, 3♠ (같은 색) → run은 1장만
        let column = [
            Card(suit: .spades, rank: .three),
            Card(suit: .spades, rank: .two)
        ]
        let run = FreeCellRule.movableRun(from: column)
        XCTAssertEqual(run.map(\.shortDescription), ["2S"])
    }

    func testSupermoveCapacity() {
        XCTAssertEqual(FreeCellRule.supermoveCapacity(emptyFreeCells: 0, emptyColumns: 0, destinationIsEmpty: false), 1)
        XCTAssertEqual(FreeCellRule.supermoveCapacity(emptyFreeCells: 4, emptyColumns: 0, destinationIsEmpty: false), 5)
        XCTAssertEqual(FreeCellRule.supermoveCapacity(emptyFreeCells: 0, emptyColumns: 3, destinationIsEmpty: false), 8)
        XCTAssertEqual(FreeCellRule.supermoveCapacity(emptyFreeCells: 2, emptyColumns: 2, destinationIsEmpty: false), 12)
        // 목적지가 빈 열이면 한 열 제외
        XCTAssertEqual(FreeCellRule.supermoveCapacity(emptyFreeCells: 2, emptyColumns: 2, destinationIsEmpty: true), 6)
    }
}
