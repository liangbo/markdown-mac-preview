import SwiftUI

private struct AppViewModelKey: EnvironmentKey {
    static let defaultValue: AppViewModel? = nil
}

extension EnvironmentValues {
    var appViewModel: AppViewModel? {
        get { self[AppViewModelKey.self] }
        set { self[AppViewModelKey.self] = newValue }
    }
}

struct AppCommands: Commands {
    @Environment(\.appViewModel) private var viewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                viewModel?.openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Button("Save") {
                viewModel?.saveDocument()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(viewModel?.canSave != true)
        }

        CommandMenu("View") {
            Button("Toggle Editor") {
                viewModel?.toggleEditor()
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(viewModel?.hasDocument != true)
        }
    }
}
