import XCTest
@testable import MarkdownMacPreviewCore

final class ScaffoldTests: XCTestCase {
    func testDefaultMarkdownStatsAreZero() {
        XCTAssertEqual(MarkdownStats(), MarkdownStats(characters: 0, words: 0, headings: 0))
    }
}
