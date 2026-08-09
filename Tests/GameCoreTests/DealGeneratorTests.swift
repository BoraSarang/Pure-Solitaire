import XCTest
@testable import GameCore

final class DealGeneratorTests: XCTestCase {

    /// 게임 #1 딜이 마이크로소프트 원본과 일치해야 한다
    func testGame1DealMatchesMicrosoft() {
        let expected = """
        JD 2D 9H JC 5D 7H 7C 5H
        KD KC 9S 5S AD QC KH 3H
        2S KS 9D QD JS AS AH 3C
        4C 5C TS QH 4H AC 4D 7S
        3S TD 4S TH 8H 2C JH 7D
        6D 8S 8D QS 6C 3D 8C TC
        6S 9C 2H 6H
        """
        let result = DealGenerator.dealString(gameNumber: 1)
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), expected)
    }

    /// 게임 #617 딜이 마이크로소프트 원본과 일치해야 한다
    func testGame617DealMatchesMicrosoft() {
        let expected = """
        7D AD 5C 3S 5S 8C 2D AH
        TD 7S QD AC 6D 8H AS KH
        TH QC 3H 9D 6S 8D 3D TC
        KD 5H 9S 3C 8S 7H 4D JS
        4C QS 9C 9H 7C 6H 2C 2S
        4S TS 2H 5D JC 6C JH QH
        JD KS KC 4H
        """
        let result = DealGenerator.dealString(gameNumber: 617)
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), expected)
    }

    /// 게임 #11982 딜 (알려진 어려운 게임) 검증
    func testGame11982Deal() {
        let expected = """
        AH AS 4H AC 2D 6S TS JS
        3D 3H QS QC 8S 7H AD KS
        KD 6H 5S 4D 9H JH 9S 3C
        JC 5D 5C 8C 9D TD KH 7C
        6C 2C TH QH 6D TC 4S 7S
        JD 7D 8H 9C 2H QD 4C 5H
        KC 8D 2S 3S
        """
        let result = DealGenerator.dealString(gameNumber: 11982)
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), expected)
    }

    /// 딜 구조: 8열, 4열은 7장, 4열은 6장, 총 52장
    func testDealStructure() {
        let columns = DealGenerator.deal(gameNumber: 1)
        XCTAssertEqual(columns.count, 8)
        XCTAssertEqual(columns.prefix(4).map(\.count), [7, 7, 7, 7])
        XCTAssertEqual(columns.suffix(4).map(\.count), [6, 6, 6, 6])
        XCTAssertEqual(columns.reduce(0) { $0 + $1.count }, 52)

        // 모든 카드는 유일해야 함
        let all = columns.flatMap { $0 }
        XCTAssertEqual(Set(all).count, 52)
    }

    /// 게임 번호 범위
    func testGameNumberRange() {
        XCTAssertEqual(DealGenerator.minGameNumber, 1)
        XCTAssertEqual(DealGenerator.maxGameNumber, 1_000_000)
    }
}
