import SwiftUI

struct RecentFilesSidebarView: View {
    let recentFiles: [RecentFile]
    let selectedURL: URL?
    let actionState: SidebarActionState
    let openDocument: () -> Void
    let toggleEditor: () -> Void
    let saveDocument: () -> Void
    let open: (RecentFile) -> Void
    let remove: (RecentFile) -> Void
    let move: (IndexSet, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("Recent")
                    .font(.headline)

                Spacer(minLength: 4)

                Button("Open", action: openDocument)
                Button(actionState.editTitle, action: toggleEditor)
                    .disabled(!actionState.canEdit)
                Button("Save", action: saveDocument)
                    .disabled(!actionState.canSave)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if recentFiles.isEmpty {
                Text("No recent files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            } else {
                List {
                    ForEach(recentFiles) { file in
                        row(for: file)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            open(file)
                        }
                        .contextMenu {
                            Button("Remove from Recent") {
                                remove(file)
                            }
                        }
                        .listRowBackground(rowBackground(for: file))
                    }
                    .onMove(perform: move)
                }
                .listStyle(.sidebar)
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 150, idealWidth: 168, maxWidth: 260)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func row(for file: RecentFile) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(file.fileName)
                .font(.body)
                .lineLimit(1)
            Text(file.parentPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func rowBackground(for file: RecentFile) -> Color {
        guard selectedURL?.standardizedFileURL.path == file.url.standardizedFileURL.path else {
            return Color.clear
        }
        return Color(nsColor: .selectedContentBackgroundColor).opacity(0.25)
    }
}
