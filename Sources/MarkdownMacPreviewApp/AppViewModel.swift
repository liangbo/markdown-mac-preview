import AppKit
import Foundation
import MarkdownMacPreviewCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var document: MarkdownDocument?
    @Published private(set) var recentFiles: [RecentFile]
    @Published var isEditorVisible = false
    @Published var errorMessage: String?

    private let recentFilesStore: RecentFilesStore
    private let previewRenderer: (String) -> MarkdownPreviewContent
    private var cachedPreviewContent: MarkdownPreviewContent?
    private var cachedPreviewSource: String?

    init(
        recentFilesStore: RecentFilesStore = RecentFilesStore(),
        previewRenderer: @escaping (String) -> MarkdownPreviewContent = MarkdownRenderer.render
    ) {
        self.recentFilesStore = recentFilesStore
        self.previewRenderer = previewRenderer
        recentFiles = recentFilesStore.load()
    }

    var previewContent: MarkdownPreviewContent {
        let source = document?.content ?? ""
        if cachedPreviewSource == source, let cachedPreviewContent {
            return cachedPreviewContent
        }

        let renderedContent = previewRenderer(source)
        cachedPreviewSource = source
        cachedPreviewContent = renderedContent
        return renderedContent
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
        loadDocument(from: url, promoteExistingRecentFile: true)
    }

    private func loadDocument(from url: URL, promoteExistingRecentFile: Bool) {
        do {
            document = try MarkdownDocument.load(from: url)
            invalidatePreviewCache()
            recentFiles = recentFilesStore.record(url, promoteExisting: promoteExistingRecentFile)
            isEditorVisible = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openRecentFile(_ recentFile: RecentFile) {
        guard FileManager.default.fileExists(atPath: recentFile.url.path) else {
            recentFiles = recentFilesStore.remove(recentFile.url)
            errorMessage = "Recent file no longer exists: \(recentFile.fileName)"
            return
        }

        guard confirmDiscardIfNeeded() else {
            return
        }

        loadDocument(from: recentFile.url, promoteExistingRecentFile: false)
    }

    func removeRecentFile(_ recentFile: RecentFile) {
        recentFiles = recentFilesStore.remove(recentFile.url)
    }

    func moveRecentFiles(fromOffsets source: IndexSet, toOffset destination: Int) {
        recentFiles = recentFilesStore.reorder(fromOffsets: source, toOffset: destination)
    }

    func updateContent(_ content: String) {
        document?.updateContent(content)
        invalidatePreviewCache()
    }

    func saveDocument() {
        guard var currentDocument = document else {
            return
        }

        do {
            try currentDocument.save()
            document = currentDocument
            invalidatePreviewCache()
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

    private func invalidatePreviewCache() {
        cachedPreviewSource = nil
        cachedPreviewContent = nil
    }
}
