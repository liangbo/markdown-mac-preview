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

    public static func compute(for markdown: String) -> MarkdownStats {
        let headingCount = markdown
            .split(whereSeparator: \.isNewline)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.range(of: #"^#{1,6}\s+\S"#, options: .regularExpression) != nil
            }
            .count

        let plainText = markdown
            .replacingOccurrences(of: #"```[\s\S]*?```"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"`[^`]+`"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"https?://\S+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[#>*_\-\[\]()`]"#, with: " ", options: .regularExpression)

        let words = plainText
            .split { character in
                character.isWhitespace || character.isNewline
            }
            .count

        return MarkdownStats(
            characters: markdown.count,
            words: words,
            headings: headingCount
        )
    }
}
