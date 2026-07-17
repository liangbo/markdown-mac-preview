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

    func testFencedCodeBlockWithBlankLinePreservesCodeContent() {
        let markdown = """
        # Title

        ```swift
        let a = 1

        let b = 2
        ```
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertEqual(rendered, "Title\n\nlet a = 1\n\nlet b = 2\n")
        XCTAssertNil(result.warning)
    }

    func testFourBacktickFenceRequiresMatchingCloser() {
        let markdown = """
        # Title

        ````swift
        let a = 1
        ```

        let b = 2
        ````
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("let a = 1\n```\n\nlet b = 2"))
        XCTAssertFalse(rendered.contains("\n\n\n"))
        XCTAssertNil(result.warning)
    }

    func testTildeFenceRequiresWhitespaceOnlyCloserSuffix() {
        let markdown = """
        # Title

        ~~~swift
        let a = 1
        ~~~not-a-closer

        let b = 2
        ~~~
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("let a = 1\n~~~not-a-closer\n\nlet b = 2"))
        XCTAssertFalse(rendered.contains("\n\n\n"))
        XCTAssertNil(result.warning)
    }

    func testCRLFHeadingAndParagraphPreserveSeparator() {
        let result = MarkdownRenderer.render("# Title\r\n\r\nThis is **bold** text.")

        XCTAssertEqual(String(result.attributed.characters), "Title\n\nThis is bold text.")
        XCTAssertNil(result.warning)
    }

    func testIndentedCodeFenceDoesNotSuppressLaterParagraphSeparator() {
        let markdown = "    let code = 1\n    ```\n\nAfter paragraph"

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("let code = 1\n```\n\nAfter paragraph"))
        XCTAssertNil(result.warning)
    }

    func testCompactListDoesNotGainParagraphSeparatorsBetweenItems() {
        let result = MarkdownRenderer.render("- one\n- two")
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("one"))
        XCTAssertTrue(rendered.contains("two"))
        XCTAssertFalse(rendered.contains("\n\n"))
        XCTAssertNil(result.warning)
    }

    func testLooseListPreservesBlankLineBetweenItems() {
        let result = MarkdownRenderer.render("- one\n\n- two")
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("one\n\ntwo"))
        XCTAssertNil(result.warning)
    }

    func testListLikeLinesInsideFenceDoNotAffectFollowingCompactList() {
        let markdown = """
        ```text
        - fake one

        - fake two
        ```

        - real one
        - real two
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("- fake one"))
        XCTAssertTrue(rendered.contains("- fake two"))
        XCTAssertFalse(rendered.contains("real one\n\nreal two"))
        XCTAssertNil(result.warning)
    }

    func testListItemParagraphsPreserveSeparationWithinSameItem() {
        let result = MarkdownRenderer.render("- one\n\n  continuation")
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("one\n\ncontinuation"))
        XCTAssertNil(result.warning)
    }

    func testNestedCompactListDoesNotGainSeparatorsFromLooseParent() {
        let markdown = """
        - parent

          - child one
          - child two
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertTrue(rendered.contains("child one"))
        XCTAssertTrue(rendered.contains("child two"))
        XCTAssertFalse(rendered.contains("child one\n\nchild two"))
        XCTAssertNil(result.warning)
    }

    func testNestedLooseListUsesInnermostListContainer() {
        let markdown = """
        - parent
          - child one

          - child two
        """

        let result = MarkdownRenderer.render(markdown)
        let rendered = String(result.attributed.characters)

        XCTAssertFalse(rendered.contains("parent\n\nchild one"))
        XCTAssertTrue(rendered.contains("child one\n\nchild two"))
        XCTAssertNil(result.warning)
    }

    func testSeparatorsSurroundListWithoutSplittingListItems() {
        let markdown = "# Title\n\n- one\n- two\n\nAfter paragraph"

        let result = MarkdownRenderer.render(markdown)

        XCTAssertEqual(
            String(result.attributed.characters),
            "Title\n\nonetwo\n\nAfter paragraph"
        )
        XCTAssertNil(result.warning)
    }

    private enum TestError: Error {
        case parserFailed
    }
}
