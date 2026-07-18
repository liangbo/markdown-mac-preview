import AppKit
import Foundation
import MarkdownMacPreviewCore
import SwiftUI
import UniformTypeIdentifiers

private final class PreviewRenderQueue {
    private let queue = DispatchQueue(label: "app.mdpreview.preview-renderer", qos: .userInitiated)

    func render(_ markdown: String) async -> MarkdownPreviewContent {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: MarkdownRenderer.render(markdown))
            }
        }
    }
}

private let defaultPreviewRenderQueue = PreviewRenderQueue()

struct SidebarActionState: Equatable {
    let canEdit: Bool
    let canSave: Bool
    let editTitle: String
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var document: MarkdownDocument?
    @Published private(set) var recentFiles: [RecentFile]
    @Published private(set) var previewContent: MarkdownPreviewContent
    @Published private(set) var isPreviewRendering = false
    @Published var isEditorVisible = false
    @Published var errorMessage: String?

    private let recentFilesStore: RecentFilesStore
    private let previewRenderer: (String) async -> MarkdownPreviewContent
    private var renderTask: Task<Void, Never>?
    private var renderGeneration = 0

    init(
        recentFilesStore: RecentFilesStore = RecentFilesStore(),
        previewRenderer: @escaping (String) async -> MarkdownPreviewContent = { markdown in
            await defaultPreviewRenderQueue.render(markdown)
        }
    ) {
        self.recentFilesStore = recentFilesStore
        self.previewRenderer = previewRenderer
        recentFiles = recentFilesStore.load()
        previewContent = Self.placeholderPreviewContent(message: "Open a Markdown file to preview it.")
    }

    var hasDocument: Bool {
        document != nil
    }

    var canSave: Bool {
        document?.isDirty == true
    }

    var sidebarActionState: SidebarActionState {
        SidebarActionState(
            canEdit: hasDocument,
            canSave: canSave,
            editTitle: isEditorVisible ? "Hide Editor" : "Edit"
        )
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
            recentFiles = recentFilesStore.record(url, promoteExisting: promoteExistingRecentFile)
            isEditorVisible = false
            errorMessage = nil
            schedulePreviewRender(
                for: document?.content ?? "",
                debounceNanoseconds: 0,
                showPlaceholder: true
            )
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
        schedulePreviewRender(
            for: content,
            debounceNanoseconds: 150_000_000,
            showPlaceholder: false
        )
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

    private func schedulePreviewRender(
        for source: String,
        debounceNanoseconds: UInt64,
        showPlaceholder: Bool
    ) {
        renderGeneration += 1
        let generation = renderGeneration
        renderTask?.cancel()
        isPreviewRendering = true
        if showPlaceholder {
            previewContent = Self.placeholderPreviewContent(message: "Rendering preview...")
        }

        renderTask = Task { [previewRenderer] in
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }
            guard !Task.isCancelled else {
                return
            }

            let renderedContent = await previewRenderer(source)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard generation == self.renderGeneration else {
                    return
                }
                self.previewContent = renderedContent
                self.isPreviewRendering = false
            }
        }
    }

    private static func placeholderPreviewContent(message: String) -> MarkdownPreviewContent {
        MarkdownPreviewContent(
            html: """
            <!doctype html>
            <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <style>
                body {
                  margin: 0;
                  min-height: 100vh;
                  display: grid;
                  place-items: center;
                  color: color-mix(in srgb, CanvasText 58%, transparent);
                  background: Canvas;
                  font: 14px -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                }
              </style>
            </head>
            <body>\(message)</body>
            </html>
            """
        )
    }
}
