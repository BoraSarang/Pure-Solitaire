import XCTest
@testable import GameCore

final class RecordStoreTests: XCTestCase {

    func testRecordStoreRoundTrip() {
        let store = RecordStore()
        let variant: GameVariant = .freecell
        store.clear(for: variant)

        store.record(RecordStore.GameRecord(gameNumber: 1, variant: variant, seconds: 120), for: variant)
        store.record(RecordStore.GameRecord(gameNumber: 617, variant: variant, seconds: 300), for: variant)

        let records = store.records(for: variant)
        XCTAssertEqual(records.count, 2)
        // 최신순 정렬 (나중에 기록한 게임 번호가 앞)
        XCTAssertEqual(records.first?.gameNumber, 617)
        XCTAssertEqual(records.first?.variant, variant)

        // 다른 변형은 독립적
        XCTAssertTrue(store.records(for: .bakersGame).isEmpty)
        store.clear(for: variant)
    }

    func testRecordStoreMovesRoundTrip() {
        let store = RecordStore()
        let variant: GameVariant = .freecell
        store.clear(for: variant)

        store.record(RecordStore.GameRecord(gameNumber: 1, variant: variant, seconds: 120, moves: 42), for: variant)
        store.record(RecordStore.GameRecord(gameNumber: 617, variant: variant, seconds: 300, moves: 7), for: variant)

        let records = store.records(for: variant)
        XCTAssertEqual(records.count, 2)
        let byGame = Dictionary(uniqueKeysWithValues: records.map { ($0.gameNumber, $0) })
        XCTAssertEqual(byGame[1]?.moves, 42)
        XCTAssertEqual(byGame[617]?.moves, 7)
        store.clear(for: variant)
    }

    func testRecordStoreMaxLimit() {
        let store = RecordStore()
        let variant: GameVariant = .bakersGame
        store.clear(for: variant)

        for i in 0..<60 {
            store.record(RecordStore.GameRecord(gameNumber: i, variant: variant, seconds: Double(i)), for: variant)
        }
        XCTAssertLessThanOrEqual(store.records(for: variant).count, 50)
        store.clear(for: variant)
    }

    func testRecordStoreClearAll() {
        let store = RecordStore()
        for variant in GameVariant.allCases {
            store.clear(for: variant)
        }

        for variant in GameVariant.allCases {
            store.record(RecordStore.GameRecord(gameNumber: 42, variant: variant, seconds: 99), for: variant)
            XCTAssertFalse(store.records(for: variant).isEmpty)
        }

        store.clearAll()

        for variant in GameVariant.allCases {
            XCTAssertTrue(store.records(for: variant).isEmpty)
        }
    }
}