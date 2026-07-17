import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownRendererTests: XCTestCase {
    func testRendersBasicMarkdownIntoAttributedContent() {
        let result = MarkdownRenderer.render("# Title\n\nThis is **bold** text.")

        XCTAssertEqual(String(result.attributed.characters), "Title\n\nThis is bold text.")
        XCTAssertNil(result.warning)
    }

    func testPlainTextFallbackKeepsOriginalText() {
        let markdown = "Unclosed [link]("

        let result = MarkdownRenderer.render(markdown)

        XCTAssertEqual(String(result.attributed.characters), markdown)
        XCTAssertNil(result.warning)
    }

    func testPlainTextFallbackKeepsOriginalTextAndWarnsWhenParserThrows() {
        let markdown = "# Broken"

        let result = MarkdownRenderer.render(markdown, parser: { _ in
            throw TestError.parserFailed
        })

        XCTAssertEqual(String(result.attributed.characters), markdown)
        XCTAssertEqual(result.warning, "Markdown preview fell back to plain text.")
    }

    private enum TestError: Error {
        case parserFailed
    }
}
