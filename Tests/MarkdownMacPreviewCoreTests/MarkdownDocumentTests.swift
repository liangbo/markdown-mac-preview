import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownDocumentTests: XCTestCase {
    func testLoadsSupportedMarkdownFile() throws {
        let url = try writeTempFile(name: "note.md", content: "# Hello\n\nLocal preview")

        let document = try MarkdownDocument.load(from: url)

        XCTAssertEqual(document.fileURL, url)
        XCTAssertEqual(document.fileName, "note.md")
        XCTAssertEqual(document.content, "# Hello\n\nLocal preview")
        XCTAssertFalse(document.isDirty)
        XCTAssertEqual(document.stats.headings, 1)
    }

    func testRejectsUnsupportedExtension() throws {
        let url = try writeTempFile(name: "note.txt", content: "# Hello")

        XCTAssertThrowsError(try MarkdownDocument.load(from: url)) { error in
            XCTAssertEqual(error as? MarkdownDocumentError, .unsupportedFileType("txt"))
        }
    }

    func testDirtyStateChangesAfterEditAndClearsAfterSave() throws {
        let url = try writeTempFile(name: "draft.markdown", content: "# Draft")
        var document = try MarkdownDocument.load(from: url)

        document.updateContent("# Draft\n\nUpdated body")

        XCTAssertTrue(document.isDirty)
        XCTAssertEqual(document.stats.words, 3)

        try document.save()

        XCTAssertFalse(document.isDirty)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Draft\n\nUpdated body")
    }

    private func writeTempFile(name: String, content: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
