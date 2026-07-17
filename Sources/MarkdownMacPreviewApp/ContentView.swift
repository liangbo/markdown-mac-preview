import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Markdown Mac Preview")
                .font(.title)
            Text("Open a Markdown file to preview it locally.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
