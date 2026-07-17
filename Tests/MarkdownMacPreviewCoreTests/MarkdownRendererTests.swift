import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownRendererTests: XCTestCase {
    func testRendersBasicMarkdownIntoAttributedContent() {
        let result = MarkdownRenderer.render("# Title\n\nThis is **bold** text.")

        XCTAssertEqual(String(result.attributed.characters), "TitleThis is bold text.")
        XCTAssertNil(result.warning)
    }

    func testPlainTextFallbackKeepsOriginalText() {
        let markdown = "Unclosed [link]("

        let result = MarkdownRenderer.render(markdown)

        XCTAssertEqual(String(result.attributed.characters), markdown)
    }
}
