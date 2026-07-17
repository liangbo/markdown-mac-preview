import Foundation

public struct MarkdownPreviewContent: Equatable {
    public let attributed: AttributedString
    public let warning: String?

    public init(attributed: AttributedString, warning: String? = nil) {
        self.attributed = attributed
        self.warning = warning
    }
}

public enum MarkdownRenderer {
    public static func render(_ markdown: String) -> MarkdownPreviewContent {
        render(markdown, parser: { markdown in
            try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            )
        })
    }

    static func render(
        _ markdown: String,
        parser: (String) throws -> AttributedString
    ) -> MarkdownPreviewContent {
        do {
            var attributed = try parser(markdown)
            insertMissingBlockSeparators(into: &attributed)
            return MarkdownPreviewContent(attributed: attributed)
        } catch {
            return MarkdownPreviewContent(
                attributed: AttributedString(markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }

    private static func insertMissingBlockSeparators(into attributed: inout AttributedString) {
        var insertions: [(offset: Int, count: Int)] = []
        var offset = 0
        var previousBlockIdentity: Int?

        for run in attributed.runs {
            let blockIdentity = run.presentationIntent?.components.last?.identity

            if let previousBlockIdentity,
               let blockIdentity,
               previousBlockIdentity != blockIdentity {
                let trailingNewlines = trailingNewlineCount(
                    in: attributed.characters,
                    before: offset
                )
                if trailingNewlines < 2 {
                    insertions.append((offset, 2 - trailingNewlines))
                }
            }

            previousBlockIdentity = blockIdentity
            offset += attributed.characters[run.range].count
        }

        for insertion in insertions.reversed() {
            guard insertion.offset <= attributed.characters.count else {
                continue
            }

            let index = attributed.characters.index(
                attributed.characters.startIndex,
                offsetBy: insertion.offset
            )
            attributed.insert(
                AttributedString(String(repeating: "\n", count: insertion.count)),
                at: index
            )
        }
    }

    private static func trailingNewlineCount(
        in characters: AttributedString.CharacterView,
        before offset: Int
    ) -> Int {
        guard offset <= characters.count else {
            return 0
        }

        let end = characters.index(characters.startIndex, offsetBy: offset)
        return characters[..<end].reversed().prefix { $0 == "\n" }.count
    }
}
