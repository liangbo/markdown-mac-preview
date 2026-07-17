import Foundation

public enum MarkdownDocumentError: Error, Equatable, LocalizedError {
    case unsupportedFileType(String)
    case unreadableFile(String)
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext). Please open a .md or .markdown file."
        case .unreadableFile(let message):
            return "Could not read this Markdown file. \(message)"
        case .saveFailed(let message):
            return "Could not save this Markdown file. \(message)"
        }
    }
}

public struct MarkdownDocument: Equatable {
    public let fileURL: URL
    public private(set) var originalContent: String
    public private(set) var content: String

    public var fileName: String {
        fileURL.lastPathComponent
    }

    public var isDirty: Bool {
        content != originalContent
    }

    public var stats: MarkdownStats {
        MarkdownStats.compute(for: content)
    }

    public static func load(from url: URL) throws -> MarkdownDocument {
        try validateSupportedFile(url)

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return MarkdownDocument(fileURL: url, originalContent: text, content: text)
        } catch {
            throw MarkdownDocumentError.unreadableFile(error.localizedDescription)
        }
    }

    public mutating func updateContent(_ newContent: String) {
        content = newContent
    }

    public mutating func save() throws {
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            originalContent = content
        } catch {
            throw MarkdownDocumentError.saveFailed(error.localizedDescription)
        }
    }

    private static func validateSupportedFile(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        guard ext == "md" || ext == "markdown" else {
            throw MarkdownDocumentError.unsupportedFileType(ext.isEmpty ? "none" : ext)
        }
    }
}
