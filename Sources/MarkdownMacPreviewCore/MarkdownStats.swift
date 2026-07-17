import Foundation

public struct MarkdownStats: Equatable {
    public let characters: Int
    public let words: Int
    public let headings: Int

    public init(characters: Int = 0, words: Int = 0, headings: Int = 0) {
        self.characters = characters
        self.words = words
        self.headings = headings
    }
}
