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
            insertMissingBlockSeparators(into: &attributed, markdown: markdown)
            return MarkdownPreviewContent(attributed: attributed)
        } catch {
            return MarkdownPreviewContent(
                attributed: AttributedString(markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }

    private static func insertMissingBlockSeparators(
        into attributed: inout AttributedString,
        markdown: String
    ) {
        var insertions: [(offset: Int, count: Int)] = []
        var offset = 0
        var previousBlockIdentity: Int?
        var previousListContainerIdentity: Int?
        var previousListItemIdentity: Int?
        var looseListTransitions = looseListItemTransitionCount(in: markdown)

        for run in attributed.runs {
            let intent = run.presentationIntent
            let blockIdentity = intent?.components.last?.identity
            let currentListContainerIdentity = listContainerIdentity(in: intent)
            let currentListItemIdentity = listItemIdentity(in: intent)
            let sharesListContainer = previousListContainerIdentity != nil &&
                previousListContainerIdentity == currentListContainerIdentity
            let isLooseListTransition = sharesListContainer &&
                previousListItemIdentity != nil &&
                previousListItemIdentity != currentListItemIdentity &&
                looseListTransitions > 0
            let isBlockTransition = previousBlockIdentity != blockIdentity

            if previousBlockIdentity != nil,
               blockIdentity != nil,
               (isBlockTransition && !sharesListContainer) || isLooseListTransition {
                let trailingNewlines = trailingNewlineCount(
                    in: attributed.characters,
                    before: offset
                )
                if trailingNewlines < 2 {
                    insertions.append((offset, 2 - trailingNewlines))
                }
            }

            if isLooseListTransition {
                looseListTransitions -= 1
            }

            previousBlockIdentity = blockIdentity
            previousListContainerIdentity = currentListContainerIdentity
            previousListItemIdentity = currentListItemIdentity
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

    private static func listContainerIdentity(
        in intent: PresentationIntent?
    ) -> Int? {
        guard let intent else {
            return nil
        }

        for component in intent.components.reversed() {
            switch component.kind {
            case .orderedList, .unorderedList:
                return component.identity
            default:
                continue
            }
        }

        return nil
    }

    private static func listItemIdentity(in intent: PresentationIntent?) -> Int? {
        guard let intent else {
            return nil
        }

        for component in intent.components {
            if case .listItem = component.kind {
                return component.identity
            }
        }

        return nil
    }

    private static func looseListItemTransitionCount(in markdown: String) -> Int {
        var transitions = 0
        var lastNonBlankLineWasListItem = false
        var blankLineAfterListItem = false

        for line in markdown.components(separatedBy: .newlines) {
            let isBlank = line.trimmingCharacters(in: .whitespaces).isEmpty
            let isListItem = line.range(
                of: #"^[ ]{0,3}(?:[*+-]|\d+[.)])[ \t]+"#,
                options: .regularExpression
            ) != nil

            if isListItem && lastNonBlankLineWasListItem && blankLineAfterListItem {
                transitions += 1
            }

            if isBlank {
                blankLineAfterListItem = lastNonBlankLineWasListItem
            } else {
                blankLineAfterListItem = false
                lastNonBlankLineWasListItem = isListItem
            }
        }

        return transitions
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
