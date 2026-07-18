import XCTest
@testable import MarkdownMacPreviewApp

final class PreviewHTMLFileStoreTests: XCTestCase {
    func testEmbedsRelativeImagesFromMarkdownDirectoryIntoPreviewFile() throws {
        let markdownDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PreviewHTMLFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        let imageDirectory = markdownDirectory.appendingPathComponent("images", isDirectory: true)
        try FileManager.default.createDirectory(at: markdownDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        let imageURL = imageDirectory.appendingPathComponent("photo.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)

        let store = PreviewHTMLFileStore(fileManager: .default)
        let request = try store.write(
            html: #"<!doctype html><html><head></head><body><img src="images/photo.png"></body></html>"#,
            baseURL: markdownDirectory
        )

        XCTAssertFalse(request.fileURL.path.hasPrefix(markdownDirectory.path))
        XCTAssertEqual(request.readAccessURL.standardizedFileURL, request.fileURL.deletingLastPathComponent().standardizedFileURL)
        let writtenHTML = try String(contentsOf: request.fileURL, encoding: .utf8)
        XCTAssertTrue(writtenHTML.contains(#"<img src="data:image/png;base64,iVBORw==">"#))
        XCTAssertFalse(writtenHTML.contains(#"src="images/photo.png""#))
    }

    func testLeavesRemoteAndMissingImagesUntouched() throws {
        let markdownDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PreviewHTMLFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: markdownDirectory, withIntermediateDirectories: true)

        let store = PreviewHTMLFileStore(fileManager: .default)
        let request = try store.write(
            html: #"<img src="https://example.com/a.png"><img src="./missing.png">"#,
            baseURL: markdownDirectory
        )

        let writtenHTML = try String(contentsOf: request.fileURL, encoding: .utf8)
        XCTAssertTrue(writtenHTML.contains(#"src="https://example.com/a.png""#))
        XCTAssertTrue(writtenHTML.contains(#"src="./missing.png""#))
    }

    func testWritesPreviewFileToTemporaryDirectoryWhenNoBaseURLExists() throws {
        let store = PreviewHTMLFileStore(fileManager: .default)
        let request = try store.write(html: "<p>No document</p>", baseURL: nil)

        XCTAssertTrue(FileManager.default.fileExists(atPath: request.fileURL.path))
        XCTAssertEqual(request.readAccessURL.standardizedFileURL, request.fileURL.deletingLastPathComponent().standardizedFileURL)
        XCTAssertEqual(try String(contentsOf: request.fileURL, encoding: .utf8), "<p>No document</p>")
    }
}
