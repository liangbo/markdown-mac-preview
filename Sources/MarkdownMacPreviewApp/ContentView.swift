import MarkdownMacPreviewCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private var editableContent: Binding<String> {
        Binding(
            get: { viewModel.document?.content ?? "" },
            set: { viewModel.updateContent($0) }
        )
    }

    private var previewBaseURL: URL? {
        viewModel.document?.fileURL.deletingLastPathComponent()
    }

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                RecentFilesSidebarView(
                    recentFiles: viewModel.recentFiles,
                    selectedURL: viewModel.document?.fileURL,
                    actionState: viewModel.sidebarActionState,
                    openDocument: viewModel.openDocument,
                    toggleEditor: viewModel.toggleEditor,
                    saveDocument: viewModel.saveDocument,
                    open: viewModel.openRecentFile,
                    remove: viewModel.removeRecentFile,
                    move: viewModel.moveRecentFiles
                )

                if viewModel.hasDocument {
                    documentBody
                } else {
                    emptyState
                }
            }

            Divider()

            StatusBarView(
                fileName: viewModel.document?.fileName,
                isDirty: viewModel.document?.isDirty == true,
                stats: viewModel.document?.stats ?? MarkdownStats(),
                errorMessage: viewModel.errorMessage,
                warningMessage: viewModel.previewContent.warning
            )
        }
    }

    private var documentBody: some View {
        Group {
            if viewModel.isEditorVisible {
                HSplitView {
                    EditorView(content: editableContent)
                        .frame(minWidth: 320)
                    previewPane
                        .frame(minWidth: 420)
                }
            } else {
                previewPane
            }
        }
    }

    private var previewPane: some View {
        ZStack(alignment: .topTrailing) {
            PreviewView(content: viewModel.previewContent, baseURL: previewBaseURL)

            if viewModel.isPreviewRendering {
                Text("Rendering...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(12)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("mdPreview")
                .font(.title)
            Text("Open a local Markdown file to preview it.")
                .foregroundStyle(.secondary)
            Button("Open Markdown File") {
                viewModel.openDocument()
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
