import XCTest
@testable import MarkdownMacPreviewApp

final class RecentFilesStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: RecentFilesStore!

    override func setUp() {
        super.setUp()
        suiteName = "RecentFilesStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 20)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testRecordAddsNewestFirstAndDeduplicates() {
        let first = URL(fileURLWithPath: "/tmp/first.md")
        let second = URL(fileURLWithPath: "/tmp/second.markdown")

        _ = store.record(first)
        _ = store.record(second)
        let files = store.record(first)

        XCTAssertEqual(files.map(\.url), [first.standardizedFileURL, second.standardizedFileURL])
    }

    func testRecordCapsRecentFilesAtLimit() {
        store = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 3)

        for index in 0..<5 {
            _ = store.record(URL(fileURLWithPath: "/tmp/file-\(index).md"))
        }

        XCTAssertEqual(store.load().map(\.fileName), ["file-4.md", "file-3.md", "file-2.md"])
    }

    func testRecordIgnoresUnsupportedExtensions() {
        let files = store.record(URL(fileURLWithPath: "/tmp/not-markdown.txt"))

        XCTAssertTrue(files.isEmpty)
        XCTAssertTrue(store.load().isEmpty)
    }

    func testLoadRestoresPersistedFiles() {
        _ = store.record(URL(fileURLWithPath: "/tmp/saved.md"))
        let reloadedStore = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 20)

        XCTAssertEqual(reloadedStore.load().map(\.fileName), ["saved.md"])
    }

    func testRemoveDeletesPersistedEntry() {
        let stale = URL(fileURLWithPath: "/tmp/stale.md")
        _ = store.record(stale)

        let files = store.remove(stale)

        XCTAssertTrue(files.isEmpty)
        XCTAssertTrue(store.load().isEmpty)
    }
}
