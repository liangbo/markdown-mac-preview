import SwiftUI

struct EditorView: View {
    @Binding var content: String

    var body: some View {
        TextEditor(text: $content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
            .padding(.vertical, 8)
    }
}
