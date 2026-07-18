import SwiftUI

struct RecentFilesSidebarView: View {
    let recentFiles: [RecentFile]
    let selectedURL: URL?
    let open: (RecentFile) -> Void
    let remove: (RecentFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.headline)
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
                List(recentFiles) { file in
                    Button {
                        open(file)
                    } label: {
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
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Remove from Recent") {
                            remove(file)
                        }
                    }
                    .listRowBackground(rowBackground(for: file))
                }
                .listStyle(.sidebar)
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 300)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func rowBackground(for file: RecentFile) -> Color {
        guard selectedURL?.standardizedFileURL.path == file.url.standardizedFileURL.path else {
            return Color.clear
        }
        return Color(nsColor: .selectedContentBackgroundColor).opacity(0.25)
    }
}
