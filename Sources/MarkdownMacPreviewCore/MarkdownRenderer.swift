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
        let listTransitions = listItemTransitions(in: markdown)
        var nextListTransition = 0
        var previousIntent: PresentationIntent?
        var lastListItemByContainer: [Int: Int] = [:]

        for run in attributed.runs {
            let intent = run.presentationIntent
            let blockIdentity = intent?.components.first?.identity
            let currentListContainerIdentity = listContainerIdentity(in: intent)
            let currentListItemIdentity = listItemIdentity(in: intent)
            let sharesListContainer = previousListContainerIdentity != nil &&
                previousListContainerIdentity == currentListContainerIdentity
            let isSiblingListItemTransition = if let currentListContainerIdentity,
                                                  let currentListItemIdentity {
                lastListItemByContainer[currentListContainerIdentity] != nil &&
                    lastListItemByContainer[currentListContainerIdentity] != currentListItemIdentity
            } else {
                false
            }
            let isSameListItem = sharesListContainer &&
                previousListItemIdentity != nil &&
                previousListItemIdentity == currentListItemIdentity
            let isReturningToListContainer = !sharesListContainer &&
                previousListContainerIdentity != nil &&
                currentListContainerIdentity != nil &&
                containsListContainer(
                    in: previousIntent,
                    identity: currentListContainerIdentity!
                )
            let isLooseListTransition = isSiblingListItemTransition &&
                nextListTransition < listTransitions.count &&
                listTransitions[nextListTransition].isLoose
            let isBlockTransition = previousBlockIdentity != blockIdentity
            let isParentContinuationTransition = isReturningToListContainer &&
                isBlockTransition &&
                currentListContainerIdentity.flatMap {
                    lastListItemByContainer[$0]
                } == currentListItemIdentity
            let isNestedListTransition = previousListContainerIdentity != nil &&
                currentListContainerIdentity != nil &&
                previousListContainerIdentity != currentListContainerIdentity &&
                (containsListContainer(
                    in: intent,
                    identity: previousListContainerIdentity!
                ) || containsListContainer(
                    in: previousIntent,
                    identity: currentListContainerIdentity!
                ))
            let shouldInsertSeparator = if isNestedListTransition && !isReturningToListContainer {
                false
            } else if sharesListContainer {
                (isSameListItem && isBlockTransition) || isLooseListTransition
            } else if isReturningToListContainer {
                isLooseListTransition || isParentContinuationTransition
            } else {
                isBlockTransition
            }

            if previousBlockIdentity != nil,
               blockIdentity != nil,
               shouldInsertSeparator {
                let trailingNewlines = trailingNewlineCount(
                    in: attributed.characters,
                    before: offset
                )
                if trailingNewlines < 2 {
                    insertions.append((offset, 2 - trailingNewlines))
                }
            }

            if isSiblingListItemTransition {
                nextListTransition += 1
            }

            if let currentListContainerIdentity,
               let currentListItemIdentity {
                lastListItemByContainer[currentListContainerIdentity] = currentListItemIdentity
            }

            previousBlockIdentity = blockIdentity
            previousListContainerIdentity = currentListContainerIdentity
            previousListItemIdentity = currentListItemIdentity
            previousIntent = intent
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

        for component in intent.components {
            switch component.kind {
            case .orderedList, .unorderedList:
                return component.identity
            default:
                continue
            }
        }

        return nil
    }

    private static func containsListContainer(
        in intent: PresentationIntent?,
        identity: Int
    ) -> Bool {
        intent?.components.contains { component in
            switch component.kind {
            case .orderedList, .unorderedList:
                return component.identity == identity
            default:
                return false
            }
        } ?? false
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

    private struct ListTransition {
        let isLoose: Bool
    }

    private struct ListContext {
        var hasListItem = false
        var markerKind: ListMarkerKind?
    }

    private enum ListMarkerKind: Equatable {
        case ordered
        case unordered
    }

    private static func listItemTransitions(in markdown: String) -> [ListTransition] {
        var transitions: [ListTransition] = []
        var contexts: [Int: ListContext] = [:]
        var fence: FenceMarker?
        var blankLinePending = false

        for rawLine in markdown.components(separatedBy: "\n") {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            let leadingSpaces = line.prefix { $0 == " " }.count
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if let activeFence = fence {
                if let closingFence = fenceMarker(in: trimmedLine),
                   closingFence.character == activeFence.character,
                   closingFence.length >= activeFence.length,
                   closingFence.suffix.trimmingCharacters(in: .whitespaces).isEmpty {
                    fence = nil
                }
                continue
            }

            if leadingSpaces <= 3, let openingFence = fenceMarker(in: trimmedLine) {
                fence = openingFence
                contexts.removeAll()
                blankLinePending = false
                continue
            }

            let listMarker = listMarker(in: line)
            if leadingSpaces >= 4, listMarker == nil {
                contexts = contexts.filter { $0.key < leadingSpaces }
                blankLinePending = false
                continue
            }

            let isBlank = trimmedLine.isEmpty

            if isBlank {
                blankLinePending = true
            } else if let listMarker {
                contexts = contexts.filter { $0.key <= listMarker.indentation }
                var context = contexts[listMarker.indentation] ?? ListContext()
                if context.hasListItem, context.markerKind == listMarker.kind {
                    transitions.append(
                        ListTransition(isLoose: blankLinePending)
                    )
                }
                context.hasListItem = true
                context.markerKind = listMarker.kind
                contexts[listMarker.indentation] = context
                blankLinePending = false
            } else {
                contexts = contexts.filter { $0.key < leadingSpaces }
                blankLinePending = false
            }
        }

        return transitions
    }

    private struct ListMarker {
        let indentation: Int
        let kind: ListMarkerKind
    }

    private static func listMarker(in line: String) -> ListMarker? {
        let indentation = line.prefix { $0 == " " }.count
        let marker = String(line.dropFirst(indentation))

        if marker.range(of: #"^(?:[*+-])[ \t]+"#, options: .regularExpression) != nil {
            return ListMarker(indentation: indentation, kind: .unordered)
        }

        if marker.range(of: #"^\d+[.)][ \t]+"#, options: .regularExpression) != nil {
            return ListMarker(indentation: indentation, kind: .ordered)
        }

        return nil
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
