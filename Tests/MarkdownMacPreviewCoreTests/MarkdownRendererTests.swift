import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownRendererTests: XCTestCase {
    func testRendersBasicMarkdownIntoHTMLDocument() {
        let result = MarkdownRenderer.render("""
        # Title

        This is **bold** text.
        """)

        XCTAssertTrue(result.html.contains("<article>"))
        XCTAssertTrue(result.html.contains("mdpreview-document"))
        XCTAssertTrue(result.html.contains("<h1"))
        XCTAssertTrue(result.html.contains("Title"))
        XCTAssertTrue(result.html.contains("<strong>bold</strong>"))
        XCTAssertNil(result.warning)
    }

    func testPreservesRawHTMLForWebViewRendering() {
        let markdown = """
        Before

        <div class="note"><strong>Hello</strong><br>World</div>

        After
        """

        let result = MarkdownRenderer.render(markdown)

        XCTAssertTrue(result.html.contains("<div class=\"note\"><strong>Hello</strong><br>World</div>"))
        XCTAssertTrue(result.html.contains("Before"))
        XCTAssertTrue(result.html.contains("After"))
        XCTAssertNil(result.warning)
    }

    func testRendererKeepsRecoverableMarkdownInHTML() {
        let markdown = "Unclosed [link]("

        let result = MarkdownRenderer.render(markdown)

        XCTAssertTrue(result.html.contains("Unclosed"))
        XCTAssertNil(result.warning)
    }

    func testPlainTextFallbackEscapesOriginalTextAndWarnsWhenRendererThrows() {
        let markdown = "# Broken <script>alert('x')</script>"

        let result = MarkdownRenderer.render(markdown, htmlRenderer: { _ in
            throw TestError.parserFailed
        })

        XCTAssertTrue(result.html.contains("<pre>"))
        XCTAssertTrue(result.html.contains("# Broken &lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;"))
        XCTAssertEqual(result.warning, "Markdown preview fell back to plain text.")
    }

    func testFencedCodeBlockWithBlankLinePreservesCodeContent() {
        let markdown = """
        # Title

        ```swift
        let a = 1

        let b = 2
        ```
        """

        let rendered = MarkdownRenderer.render(markdown).html

        XCTAssertTrue(rendered.contains("let a = 1"))
        XCTAssertTrue(rendered.contains("let b = 2"))
        XCTAssertTrue(rendered.contains("<pre>"))
    }

    func testMarkdownTableProducesHTMLTableWhenSupportedByRenderer() {
        let markdown = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """

        let rendered = MarkdownRenderer.render(markdown).html

        XCTAssertTrue(rendered.contains("A"))
        XCTAssertTrue(rendered.contains("B"))
        XCTAssertTrue(rendered.contains("1"))
        XCTAssertTrue(rendered.contains("2"))
    }
}

enum TestError: Error {
    case parserFailed
}
