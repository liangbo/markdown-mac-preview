import MarkdownMacPreviewCore
import SwiftUI

struct PreviewView: View {
    let content: MarkdownPreviewContent

    var body: some View {
        ScrollView {
            Text(content.attributed)
                .textSelection(.enabled)
                .font(.system(size: 16))
                .lineSpacing(5)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}
