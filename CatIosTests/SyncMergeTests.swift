import XCTest
@testable import CatIos

private struct Item: SyncRecord {
    var id: UUID
    var value: String
}

final class SyncMergeTests: XCTestCase {
    private let a = UUID(), b = UUID(), c = UUID()

    func testRemoteEditAppliesWhenLocalUntouched() {
        let base = [Item(id: a, value: "1")]
        let merged = SyncMerge.merge(local: base, remote: [Item(id: a, value: "2")], baseline: base)
        XCTAssertEqual(merged, [Item(id: a, value: "2")])
    }

    func testLocalEditWinsOverConcurrentRemoteEdit() {
        let base = [Item(id: a, value: "1")]
        let merged = SyncMerge.merge(local: [Item(id: a, value: "local")], remote: [Item(id: a, value: "remote")], baseline: base)
        XCTAssertEqual(merged, [Item(id: a, value: "local")])
    }

    func testNewItemsFromBothSidesAreKept() {
        let merged = SyncMerge.merge(local: [Item(id: a, value: "x")], remote: [Item(id: b, value: "y")], baseline: [])
        XCTAssertEqual(Set(merged.map(\.id)), [a, b])
    }

    func testLocalDeleteIsRespected() {
        let base = [Item(id: a, value: "1"), Item(id: b, value: "1")]
        let merged = SyncMerge.merge(local: [Item(id: a, value: "1")], remote: base, baseline: base)
        XCTAssertEqual(merged.map(\.id), [a])
    }

    func testRemoteDeleteIsRespectedUnlessEditedLocally() {
        let base = [Item(id: a, value: "1"), Item(id: c, value: "1")]
        let local = [Item(id: a, value: "1"), Item(id: c, value: "edited")]
        let merged = SyncMerge.merge(local: local, remote: [], baseline: base)
        XCTAssertEqual(merged, [Item(id: c, value: "edited")])
    }
}
