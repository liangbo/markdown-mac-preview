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

    func testPreviewUsesUnsavedEditedContent() throws {
        let url = try makeMarkdownFile(named: "draft.md", content: "# Old")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: url)

        viewModel.updateContent("# New\n\nLive preview text")

        let renderedText = String(viewModel.previewContent.attributed.characters)
        XCTAssertTrue(renderedText.contains("New"))
        XCTAssertTrue(renderedText.contains("Live preview text"))
        XCTAssertTrue(viewModel.document?.isDirty == true)
    }

    func testPreviewContentIsCachedUntilDocumentContentChanges() throws {
        let url = try makeMarkdownFile(named: "cached.md", content: "# Cached")
        var renderCount = 0
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { markdown in
                renderCount += 1
                return MarkdownPreviewContent(attributed: AttributedString(markdown))
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
