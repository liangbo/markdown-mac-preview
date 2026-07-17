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
            var insertedCharacters = 0

            for boundary in topLevelBlankLineBoundaries(in: markdown) {
                let prefix = String(markdown[..<boundary])
                guard let renderedPrefix = try? parser(prefix) else {
                    continue
                }

                let insertionOffset = renderedPrefix.characters.count + insertedCharacters
                guard insertionOffset <= attributed.characters.count else {
                    continue
                }

                let insertionIndex = attributed.characters.index(
                    attributed.characters.startIndex,
                    offsetBy: insertionOffset
                )
                let remaining = attributed.characters[attributed.characters.index(
                    insertionIndex,
                    offsetBy: 0
                )...]

                guard String(remaining.prefix(2)) != "\n\n" else {
                    continue
                }

                attributed.insert(AttributedString("\n\n"), at: insertionIndex)
                insertedCharacters += 2
            }

            return MarkdownPreviewContent(attributed: attributed)
        } catch {
            return MarkdownPreviewContent(
                attributed: AttributedString(markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }

    private static func topLevelBlankLineBoundaries(in markdown: String) -> [String.Index] {
        var boundaries: [String.Index] = []
        var lineStart = markdown.startIndex
        var inFence: FenceMarker?
        var previousLineWasBlank = false

        while lineStart < markdown.endIndex {
            let lineEnd = markdown[lineStart...].firstIndex(of: "\n") ?? markdown.endIndex
            let line = markdown[lineStart..<lineEnd]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isBlank = trimmedLine.isEmpty

            if let fence = inFence {
                if let closingFence = fenceMarker(in: trimmedLine),
                   closingFence.character == fence.character,
                   closingFence.length >= fence.length,
                   closingFence.suffix.trimmingCharacters(in: .whitespaces).isEmpty {
                    inFence = nil
                }
            } else if let openingFence = fenceMarker(in: trimmedLine) {
                inFence = openingFence
            } else if isBlank && !previousLineWasBlank {
                boundaries.append(lineStart)
            }

            previousLineWasBlank = isBlank
            lineStart = lineEnd == markdown.endIndex
                ? markdown.endIndex
                : markdown.index(after: lineEnd)
        }

        return boundaries
    }

    private struct FenceMarker {
        let character: Character
        let length: Int
        let suffix: String
    }

    private static func fenceMarker(in line: String) -> FenceMarker? {
        guard let character = line.first, character == "`" || character == "~" else {
            return nil
        }

        var end = line.startIndex
        var length = 0
        while end < line.endIndex, line[end] == character {
            length += 1
            end = line.index(after: end)
        }

        guard length >= 3 else {
            return nil
        }

        return FenceMarker(character: character, length: length, suffix: String(line[end...]))
    }
}
