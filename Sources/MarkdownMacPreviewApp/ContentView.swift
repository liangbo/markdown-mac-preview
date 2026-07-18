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

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            HStack(spacing: 0) {
                RecentFilesSidebarView(
                    recentFiles: viewModel.recentFiles,
                    selectedURL: viewModel.document?.fileURL,
                    open: viewModel.openRecentFile,
                    remove: viewModel.removeRecentFile
                )

                Divider()

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

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button("Open") {
                viewModel.openDocument()
            }

            Button("Save") {
                viewModel.saveDocument()
            }
            .disabled(!viewModel.canSave)

            Button(viewModel.isEditorVisible ? "Hide Editor" : "Edit") {
                viewModel.toggleEditor()
            }
            .disabled(!viewModel.hasDocument)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var documentBody: some View {
        Group {
            if viewModel.isEditorVisible {
                HSplitView {
                    EditorView(content: editableContent)
                        .frame(minWidth: 320)
                    PreviewView(content: viewModel.previewContent)
                        .frame(minWidth: 420)
                }
            } else {
                PreviewView(content: viewModel.previewContent)
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
