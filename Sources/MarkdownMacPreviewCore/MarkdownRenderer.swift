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
            var attributed = AttributedString()
            let blocks = markdown.components(separatedBy: "\n\n")

            for (index, block) in blocks.enumerated() {
                if index > 0 {
                    attributed.append(AttributedString("\n\n"))
                }
                attributed.append(try parser(block))
            }

            return MarkdownPreviewContent(attributed: attributed)
        } catch {
            return MarkdownPreviewContent(
                attributed: AttributedString(markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }
}
