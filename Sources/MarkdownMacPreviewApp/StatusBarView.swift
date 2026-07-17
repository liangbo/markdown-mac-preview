import MarkdownMacPreviewCore
import SwiftUI

struct StatusBarView: View {
    let fileName: String?
    let isDirty: Bool
    let stats: MarkdownStats
    let errorMessage: String?
    let warningMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(fileName ?? "No file open")
                .fontWeight(.medium)
                .lineLimit(1)

            if isDirty {
                Text("Unsaved")
                    .foregroundStyle(.orange)
            }

            Spacer()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else if let warningMessage {
                Text(warningMessage)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            } else {
                Text("\(stats.words) words")
                Text("\(stats.characters) chars")
                Text("\(stats.headings) headings")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
