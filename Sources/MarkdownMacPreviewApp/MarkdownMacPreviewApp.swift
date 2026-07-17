import SwiftUI

@main
struct MarkdownMacPreviewApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            AppCommands()
        }
        .environment(\.appViewModel, viewModel)
    }
}
