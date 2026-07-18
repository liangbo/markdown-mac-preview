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

    func testLoadDocumentSwitchesImmediatelyBeforePreviewRenderCompletes() async throws {
        let url = try makeMarkdownFile(named: "slow.md", content: "# Slow")
        var continuation: CheckedContinuation<MarkdownPreviewContent, Never>?
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { _ in
                await withCheckedContinuation { pending in
                    continuation = pending
                }
            }
        )

        viewModel.loadDocument(from: url)

        XCTAssertEqual(viewModel.document?.fileURL, url.standardizedFileURL)
        XCTAssertTrue(viewModel.isPreviewRendering)
        XCTAssertTrue(viewModel.previewContent.html.contains("Rendering"))

        try await waitUntil({ continuation != nil })
        continuation?.resume(returning: MarkdownPreviewContent(html: "<p>Done</p>"))
        try await waitForPreviewRender(in: viewModel)

        XCTAssertFalse(viewModel.isPreviewRendering)
        XCTAssertEqual(viewModel.previewContent.html, "<p>Done</p>")
    }

    func testStalePreviewRenderDoesNotOverwriteNewerDocument() async throws {
        let first = try makeMarkdownFile(named: "first.md", content: "# First")
        let second = try makeMarkdownFile(named: "second.md", content: "# Second")
        var continuations: [String: CheckedContinuation<MarkdownPreviewContent, Never>] = [:]
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { markdown in
                await withCheckedContinuation { pending in
                    continuations[markdown] = pending
                }
            }
        )

        viewModel.loadDocument(from: first)
        viewModel.loadDocument(from: second)

        try await waitUntil({ continuations["# Second"] != nil })
        continuations["# First"]?.resume(returning: MarkdownPreviewContent(html: "<p>First</p>"))
        continuations["# Second"]?.resume(returning: MarkdownPreviewContent(html: "<p>Second</p>"))
        try await waitForPreviewRender(in: viewModel)

        XCTAssertEqual(viewModel.document?.fileURL, second.standardizedFileURL)
        XCTAssertEqual(viewModel.previewContent.html, "<p>Second</p>")
    }

    func testPreviewUsesUnsavedEditedContent() async throws {
        let url = try makeMarkdownFile(named: "draft.md", content: "# Old")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: url)
        try await waitForPreviewRender(in: viewModel)

        viewModel.updateContent("# New\n\nLive preview text")
        try await waitForPreviewRender(in: viewModel)

        let renderedHTML = viewModel.previewContent.html
        XCTAssertTrue(renderedHTML.contains("New"))
        XCTAssertTrue(renderedHTML.contains("Live preview text"))
        XCTAssertTrue(viewModel.document?.isDirty == true)
    }

    func testEditingKeepsCurrentPreviewVisibleDuringDebounce() async throws {
        let url = try makeMarkdownFile(named: "draft.md", content: "# Old")
        var continuation: CheckedContinuation<MarkdownPreviewContent, Never>?
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { markdown in
                if markdown == "# Old" {
                    return MarkdownPreviewContent(html: "<p>Old</p>")
                }
                return await withCheckedContinuation { pending in
                    continuation = pending
                }
            }
        )
        viewModel.loadDocument(from: url)
        try await waitForPreviewRender(in: viewModel)

        viewModel.updateContent("# New")

        XCTAssertTrue(viewModel.isPreviewRendering)
        XCTAssertEqual(viewModel.previewContent.html, "<p>Old</p>")

        try await waitUntil({ continuation != nil })
        continuation?.resume(returning: MarkdownPreviewContent(html: "<p>New</p>"))
        try await waitForPreviewRender(in: viewModel)

        XCTAssertEqual(viewModel.previewContent.html, "<p>New</p>")
    }

    func testSaveDoesNotTriggerPreviewRenderWhenContentIsUnchanged() async throws {
        let url = try makeMarkdownFile(named: "saved.md", content: "# Saved")
        var renderCount = 0
        let viewModel = AppViewModel(
            recentFilesStore: store,
            previewRenderer: { markdown in
                renderCount += 1
                return MarkdownPreviewContent(html: markdown)
            }
        )
        viewModel.loadDocument(from: url)
        try await waitForPreviewRender(in: viewModel)

        viewModel.updateContent("# Changed")
        try await waitForPreviewRender(in: viewModel)
        viewModel.saveDocument()

        XCTAssertEqual(renderCount, 2)
        XCTAssertFalse(viewModel.isPreviewRendering)
    }

    func testPreviewContentIsRenderedUntilDocumentContentChanges() async throws {
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
        try await waitForPreviewRender(in: viewModel)

        XCTAssertEqual(renderCount, 1)

        viewModel.updateContent("# Changed")
        try await waitForPreviewRender(in: viewModel)

        XCTAssertEqual(renderCount, 2)
    }

    private func waitForPreviewRender(
        in viewModel: AppViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        try await waitUntil({ !viewModel.isPreviewRendering }, file: file, line: line)
    }

    private func waitUntil(
        _ condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<100 {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for condition", file: file, line: line)
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
