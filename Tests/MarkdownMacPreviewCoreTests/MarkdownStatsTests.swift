import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownStatsTests: XCTestCase {
    func testComputesCharactersWordsAndHeadings() {
        let markdown = """
        # Title

        Hello **local** Markdown preview.

        ## Notes
        - one item
        - second item
        """

        let stats = MarkdownStats.compute(for: markdown)

        XCTAssertEqual(stats.characters, markdown.count)
        XCTAssertEqual(stats.words, 10)
        XCTAssertEqual(stats.headings, 2)
    }

    func testEmptyMarkdownHasZeroStats() {
        let stats = MarkdownStats.compute(for: "")

        XCTAssertEqual(stats.characters, 0)
        XCTAssertEqual(stats.words, 0)
        XCTAssertEqual(stats.headings, 0)
    }
}
