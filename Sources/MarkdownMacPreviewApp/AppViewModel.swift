import AppKit
import Foundation
import MarkdownMacPreviewCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var document: MarkdownDocument?
    @Published var isEditorVisible = false
    @Published var errorMessage: String?

    var previewContent: MarkdownPreviewContent {
        MarkdownRenderer.render(document?.content ?? "")
    }

    var hasDocument: Bool {
        document != nil
    }

    var canSave: Bool {
        document?.isDirty == true
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        guard confirmDiscardIfNeeded() else {
            return
        }

        loadDocument(from: url)
    }

    func loadDocument(from url: URL) {
        do {
            document = try MarkdownDocument.load(from: url)
            isEditorVisible = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContent(_ content: String) {
        document?.updateContent(content)
    }

    func saveDocument() {
        guard var currentDocument = document else {
            return
        }

        do {
            try currentDocument.save()
            document = currentDocument
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDiscardIfNeeded() -> Bool {
        guard document?.isDirty == true else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Save changes?"
        alert.informativeText = "Do you want to save changes to \(document?.fileName ?? "this document") before continuing?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveDocument()
            return document?.isDirty != true && errorMessage == nil
        case .alertSecondButtonReturn:
            errorMessage = nil
            return true
        default:
            return false
        }
    }

    func toggleEditor() {
        guard hasDocument else {
            return
        }
        isEditorVisible.toggle()
    }
}
