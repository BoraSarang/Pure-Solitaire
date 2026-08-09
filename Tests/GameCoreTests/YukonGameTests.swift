import XCTest
@testable import GameCore

final class YukonGameTests: XCTestCase {

    private func card(_ raw: Int) -> Card { Card(rawValue: raw) }

    // MARK: - 딜

    /// 7열 1/6/7/8/9/10/11장, 열0 앞면 1장, 열1~6 뒤집힌 5장+앞면(col)장, 총 52장
    func testDealLayout() {
        let g = YukonGame(gameNumber: 617)
        XCTAssertEqual(g.columns.count, 7)
        XCTAssertEqual(g.columns[0].count, 1)
        XCTAssertEqual(g.columns[1].count, 6)
        XCTAssertEqual(g.columns[2].count, 7)
        XCTAssertEqual(g.columns[3].count, 8)
        XCTAssertEqual(g.columns[4].count, 9)
        XCTAssertEqual(g.columns[5].count, 10)
        XCTAssertEqual(g.columns[6].count, 11)
        // 열0은 앞면 1장
        XCTAssertTrue(g.columns[0][0].faceUp)
        // 열1~6: 뒤집힌 5장 + 앞면 (col)장
        for col in 1..<7 {
            for i in 0..<g.columns[col].count {
                XCTAssertEqual(g.columns[col][i].faceUp, i >= 5, "열\(col)의 앞면은 인덱스 5부터")
            }
        }
        // 총 52장 무중복
        let all = g.columns.flatMap { $0.map { $0.card } }
        XCTAssertEqual(all.count, 52)
        XCTAssertEqual(Set(all).count, 52)
        XCTAssertEqual(g.homes.count, 4)
        XCTAssertTrue(g.homes.allSatisfy { $0.isEmpty })
        XCTAssertFalse(g.isWon)
    }

    /// 같은 게임 번호 → 결정적 재현
    func testDeterministicDeal() {
        let a = YukonGame(gameNumber: 42)
        let b = YukonGame(gameNumber: 42)
        XCTAssertEqual(a.columns, b.columns)
    }

    // MARK: - 유콘 이동

    /// 앞면 카드 + 그 위 전부를 그룹 이동 (내부 순서 무관)
    func testYukonGroupMoveIgnoresInternalOrder() {
        var g = YukonGame(gameNumber: 1)
        // 열 5(앞면 5장)를 목적지 열에 놓을 수 있도록 구성
        // 목적지: 열0 (1장). 앞면 카드 5장 중 맨 아래(시작 카드)가 열0 탑에 놓일 수 있게.
        guard let destTop = g.columns[0].last?.card else {
            return XCTFail("열0 카드 없음")
        }
        // 열5의 앞면 시작 카드 인덱스
        let startIndex = 5
        guard let group = g.movableGroup(from: 5, topIndex: startIndex) else {
            return XCTFail("그룹 추출 실패")
        }
        let lead = group[0]
        // 시작 카드가 목적지 규칙(랭크1높음+교대색)을 만족하는 경우에만 이동 가능
        let expect = (lead.rank == destTop.rank.next) && (lead.color != destTop.color)
        let cardCount = group.count
        XCTAssertEqual(g.canMove(.columnToColumn(from: 5, to: 0, cardCount: cardCount)), expect)
        // 내부 순서(그룹 위 카드)는 이동 규칙과 무관 — 그룹 전체 count만 확인
        XCTAssertEqual(cardCount, 5, "열5 앞면 5장 전체 이동")
    }

    /// 뒤집힌 카드는 그룹 소스로 쓸 수 없음 (앞면 시작 카드만)
    func testFaceDownCannotStartGroup() {
        let g = YukonGame(gameNumber: 1)
        // 열1: 뒤집힌 5장 + 앞면 1장. 인덱스 0(뒤집힘)은 시작 불가
        XCTAssertNil(g.movableGroup(from: 1, topIndex: 0))
        // 인덱스 5(앞면)는 그룹 가능
        XCTAssertNotNil(g.movableGroup(from: 1, topIndex: 5))
    }

    /// 교대색 + 랭크 규칙 (빈 열은 K만)
    func testPlacementRules() {
        var g = YukonGame(gameNumber: 1)
        // 빈 열 하나 만들기 (열0 = 1장만 → 홈 이동 시 빈 열)
        let col0 = g.columns[0].last!.card
        if g.canMoveToFoundation(col0) {
            _ = g.apply(.columnToHome(columnIndex: 0, card: col0))
        }
        guard let empty = g.columns.firstIndex(where: { $0.isEmpty }) else {
            return
        }
        XCTAssertTrue(g.canPlaceOnColumn(card(51), column: empty), "K♠는 빈 열 가능")
        XCTAssertFalse(g.canPlaceOnColumn(card(3), column: empty), "Q♣는 빈 열 불가")

        // 비빈 열: 랭크 1낮음+교대색만
        let dest = g.columns.firstIndex(where: { !$0.isEmpty })!
        let destTop = g.columns[dest].last!.card
        guard let prevRank = destTop.rank.previous else { return }
        let good = card(rank: prevRank.rawValue, suit: destTop.suit == .spades ? .hearts : .spades)
        let badSameColor = card(rank: prevRank.rawValue, suit: destTop.suit)
        XCTAssertTrue(g.canPlaceOnColumn(good, column: dest))
        XCTAssertFalse(g.canPlaceOnColumn(badSameColor, column: dest), "같은 색은 거부")
    }

    private func card(rank raw: Int, suit: Suit) -> Card {
        Card(suit: suit, rank: Rank(rawValue: raw)!)
    }

    // MARK: - 홈셀

    /// 홈셀 A→K 같은 수트, 열→홈 이동, 홈→타블로 불가
    func testFoundationMoves() {
        var g = YukonGame(gameNumber: 1)
        // 어떤 열 맨 위 앞면 카드든 A면 홈 가능, 아니면 규칙 검증
        for col in g.columns.indices {
            guard let cc = g.columns[col].last, cc.faceUp else { continue }
            let card = cc.card
            if card.rank == .ace {
                XCTAssertTrue(g.canMove(.columnToHome(columnIndex: col, card: card)))
                XCTAssertTrue(g.apply(.columnToHome(columnIndex: col, card: card)))
                XCTAssertTrue(g.homes.contains { $0.count == 1 })
            } else {
                XCTAssertEqual(g.canMove(.columnToHome(columnIndex: col, card: card)), g.canMoveToFoundation(card))
            }
        }
        // 홈→타블로/홈→프리셀은 미지원 케이스(FreeCell 전용 Move) — canMove false
        XCTAssertFalse(g.canMove(.homeToColumn(homeIndex: 0, columnIndex: 0, card: g.homes[0].last ?? card(0))))
    }

    // MARK: - 노출 자동 앞면

    /// 뒤집힌 카드 위 전부 이동 시 자동 앞면 전환
    func testAutoFlipOnExposure() {
        var g = YukonGame(gameNumber: 1)
        // 열1: 뒤집힌 5장 + 앞면 1장. 앞면 카드를 홈으로 옮길 수 있으면 이동 → 노출 시 자동 앞면
        let col = 1
        guard let top = g.columns[col].last, top.faceUp else { return XCTFail("열1 앞면 카드 없음") }
        if g.canMove(.columnToHome(columnIndex: col, card: top.card)) {
            _ = g.apply(.columnToHome(columnIndex: col, card: top.card))
        } else {
            // 열→열로 그룹 이동해서 위 카드 제거
            for to in g.columns.indices where to != col {
                if g.canMove(.columnToColumn(from: col, to: to, cardCount: 1)) {
                    _ = g.apply(.columnToColumn(from: col, to: to, cardCount: 1))
                    break
                }
            }
        }
        // 열1에 카드가 남아있으면 그 top은 자동으로 앞면
        if let last = g.columns[col].last {
            XCTAssertTrue(last.faceUp, "노출된 카드는 자동으로 앞면이어야 함")
        }
    }

    // MARK: - 승리/undo/Codable

    /// 홈셀 4개 13장씩 → 승리
    func testWinDetection() {
        var g = YukonGame(gameNumber: 1)
        let full = (1...13).map { Card(rawValue: $0 * 4 - 4) }
        g.homes = Array(repeating: full, count: 4)
        XCTAssertTrue(g.isWon)
        XCTAssertFalse(YukonGame(gameNumber: 1).isWon)
    }

    /// 이동 후 undo/redo 복원
    func testUndoRedo() {
        var g = YukonGame(gameNumber: 1)
        // 열0 → 열1으로 그룹 이동 (가능하면)
        var moved = false
        if g.canMove(.columnToColumn(from: 0, to: 1, cardCount: 1)) {
            let before = g.columns
            XCTAssertTrue(g.apply(.columnToColumn(from: 0, to: 1, cardCount: 1)))
            moved = true
            g.undo()
            XCTAssertEqual(g.columns, before)
            g.redo()
            XCTAssertEqual(g.moveCount, 1)
        }
        if !moved {
            XCTAssertTrue(g.hint() != nil || g.hintCandidates().isEmpty, "힌트 비어있어도 됨")
        }
    }

    /// Codable 왕복
    func testCodableRoundTrip() throws {
        let g = YukonGame(gameNumber: 77)
        let data = try JSONEncoder().encode(g)
        let restored = try JSONDecoder().decode(YukonGame.self, from: data)
        XCTAssertEqual(restored.columns, g.columns)
        XCTAssertEqual(restored.homes, g.homes)
        XCTAssertEqual(restored.moveCount, g.moveCount)
    }
}
