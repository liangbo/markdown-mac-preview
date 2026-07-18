import XCTest
import MarkdownMacPreviewCore
@testable import MarkdownMacPreviewApp

@MainActor
final class AppViewModelTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: RecentFilesStore!

    override func setUp() {
        super.setUp()
        suiteName = "AppViewModelTests-\(UUID().uuidString)"
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

    func testLoadDocumentRecordsRecentFile() throws {
        let url = try makeMarkdownFile(named: "note.md", content: "# Note")
        let viewModel = AppViewModel(recentFilesStore: store)

        viewModel.loadDocument(from: url)

        XCTAssertEqual(viewModel.recentFiles.map(\.url), [url.standardizedFileURL])
    }

    func testOpenRecentFileDoesNotPromoteItToTop() throws {
        let first = try makeMarkdownFile(named: "first.md", content: "# First")
        let second = try makeMarkdownFile(named: "second.md", content: "# Second")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: first)
        viewModel.loadDocument(from: second)

        viewModel.openRecentFile(RecentFile(url: first.standardizedFileURL))

        XCTAssertEqual(viewModel.document?.fileURL, first.standardizedFileURL)
        XCTAssertEqual(viewModel.recentFiles.map(\.url), [second.standardizedFileURL, first.standardizedFileURL])
    }

    func testMoveRecentFilesPersistsManualOrder() throws {
        let first = try makeMarkdownFile(named: "first.md", content: "# First")
        let second = try makeMarkdownFile(named: "second.md", content: "# Second")
        let third = try makeMarkdownFile(named: "third.md", content: "# Third")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: first)
        viewModel.loadDocument(from: second)
        viewModel.loadDocument(from: third)

        viewModel.moveRecentFiles(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        XCTAssertEqual(viewModel.recentFiles.map(\.url), [first.standardizedFileURL, third.standardizedFileURL, second.standardizedFileURL])
        XCTAssertEqual(store.load().map(\.url), [first.standardizedFileURL, third.standardizedFileURL, second.standardizedFileURL])
    }

    func testPreviewUsesUnsavedEditedContent() throws {
        let url = try makeMarkdownFile(named: "draft.md", content: "# Old")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: url)

        viewModel.updateContent("# New\n\nLive preview text")

        let renderedHTML = viewModel.previewContent.html
        XCTAssertTrue(renderedHTML.contains("New"))
        XCTAssertTrue(renderedHTML.contains("Live preview text"))
        XCTAssertTrue(viewModel.document?.isDirty == true)
    }

    func testPreviewContentIsCachedUntilDocumentContentChanges() throws {
        let url = try makeMarkdownFile(named: "cached.md", content: "# Cached")
        var renderCount = 0
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { markdown in
                renderCount += 1
                return MarkdownPreviewContent(html: markdown)
            }
        )
        viewModel.loadDocument(from: url)

        _ = viewModel.previewContent
        _ = viewModel.previewContent

        XCTAssertEqual(renderCount, 1)

        viewModel.updateContent("# Changed")
        _ = viewModel.previewContent

        XCTAssertEqual(renderCount, 2)
    }

    private func makeMarkdownFile(named name: String, content: String) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AppViewModelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
