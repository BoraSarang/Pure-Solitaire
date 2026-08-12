import XCTest
@testable import GameCore

final class ScoringTests: XCTestCase {

    // MARK: - 이동 점수

    func testMoveScores() {
        XCTAssertEqual(Scoring.moveScore(for: .drawFromStock, variant: .klondike), 5)
        XCTAssertEqual(Scoring.moveScore(for: .recycleStock, variant: .klondike), -100)
        XCTAssertEqual(Scoring.moveScore(for: .flipColumnCard(columnIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .klondike), 5)
        XCTAssertEqual(Scoring.moveScore(for: .columnToHome(columnIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .freecell), 10)
        XCTAssertEqual(Scoring.moveScore(for: .wasteToFoundation(card: Card(suit: .spades, rank: .ace)), variant: .klondike), 10)
        XCTAssertEqual(Scoring.moveScore(for: .freeCellToHome(freeCellIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .freecell), 10)
        XCTAssertEqual(Scoring.moveScore(for: .homeToColumn(homeIndex: 0, columnIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .freecell), -15)
        XCTAssertEqual(Scoring.moveScore(for: .homeToFreeCell(homeIndex: 0, freeCellIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .freecell), -15)
    }

    func testRemovalMoveScores() {
        let ace = Card(suit: .spades, rank: .ace)
        let king = Card(suit: .spades, rank: .king)
        XCTAssertEqual(Scoring.moveScore(for: .pyramidRemovePair(first: ace, second: king), variant: .pyramid), 10)
        XCTAssertEqual(Scoring.moveScore(for: .pyramidRemoveWastePair(card: ace), variant: .pyramid), 5)
        XCTAssertEqual(Scoring.moveScore(for: .pyramidRemoveSingle(card: king), variant: .pyramid), 10)
        XCTAssertEqual(Scoring.moveScore(for: .triPeaksRemove(card: ace), variant: .triPeaks), 5)
        XCTAssertEqual(Scoring.moveScore(for: .columnToWaste(columnIndex: 0, card: ace), variant: .golf), 5)
    }

    func testZeroScoreMoves() {
        XCTAssertEqual(Scoring.moveScore(for: .columnToColumn(from: 0, to: 1, cardCount: 1), variant: .spider), 0)
        XCTAssertEqual(Scoring.moveScore(for: .dealFromStock, variant: .spider), 0)
        XCTAssertEqual(Scoring.moveScore(for: .dealReserve, variant: .scorpion), 0)
        XCTAssertEqual(Scoring.moveScore(for: .wasteToColumn(columnIndex: 0, card: Card(suit: .spades, rank: .ace)), variant: .klondike), 0)
    }

    // MARK: - 승리 보너스

    func testWinBonusByVariant() {
        XCTAssertEqual(Scoring.winBonus(for: .klondike), 500)
        XCTAssertEqual(Scoring.winBonus(for: .freecell), 500)
        XCTAssertEqual(Scoring.winBonus(for: .yukon), 500)
        XCTAssertEqual(Scoring.winBonus(for: .fortyThieves), 500)
        XCTAssertEqual(Scoring.winBonus(for: .scorpion), 500)
        XCTAssertEqual(Scoring.winBonus(for: .spider), 800)
        XCTAssertEqual(Scoring.winBonus(for: .golf), 300)
        XCTAssertEqual(Scoring.winBonus(for: .pyramid), 300)
        XCTAssertEqual(Scoring.winBonus(for: .triPeaks), 300)
    }

    // MARK: - 시간 보너스

    func testTimeBonusKlondike() {
        XCTAssertEqual(Scoring.timeBonus(seconds: 0, variant: .klondike), 0)
        XCTAssertEqual(Scoring.timeBonus(seconds: 9, variant: .klondike), 0)
        XCTAssertEqual(Scoring.timeBonus(seconds: 10, variant: .klondike), -2)
        XCTAssertEqual(Scoring.timeBonus(seconds: 95, variant: .klondike), -18)  // 9 * 2
        XCTAssertEqual(Scoring.timeBonus(seconds: 100, variant: .klondike), -20)
    }

    func testTimeBonusOtherVariants() {
        XCTAssertEqual(Scoring.timeBonus(seconds: 95, variant: .freecell), 0)
        XCTAssertEqual(Scoring.timeBonus(seconds: 95, variant: .spider), 0)
        XCTAssertEqual(Scoring.timeBonus(seconds: 95, variant: .golf), 0)
    }

    // MARK: - 최종 점수

    func testFinalScore() {
        XCTAssertEqual(Scoring.finalScore(moveTotal: 50, variant: .klondike, seconds: 30), 50 + 500 - 6)
        XCTAssertEqual(Scoring.finalScore(moveTotal: 20, variant: .spider, seconds: 90), 20 + 800)
        XCTAssertEqual(Scoring.finalScore(moveTotal: 0, variant: .golf, seconds: 45), 300)
    }
}
