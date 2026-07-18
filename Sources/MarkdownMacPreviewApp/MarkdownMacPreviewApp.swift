import AppKit
import Combine
import SwiftUI

@main
@MainActor
final class MarkdownMacPreviewApplication: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static var sharedDelegate: MarkdownMacPreviewApplication?
    private let viewModel = AppViewModel()
    private var window: NSWindow?
    private var titlebarButtons: [TitlebarAction: NSButton] = [:]
    private var viewModelCancellable: AnyCancellable?
    private var mayTerminateWithoutConfirmation = false

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)

        let delegate = MarkdownMacPreviewApplication()
        sharedDelegate = delegate
        application.delegate = delegate
        application.mainMenu = delegate.buildMainMenu()
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
            .environmentObject(viewModel)
            .frame(minWidth: 900, minHeight: 600)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "mdPreview"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.addTitlebarAccessoryViewController(buildTitlebarActions())
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        viewModelCancellable = viewModel.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateToolbarItems()
            }
        }
        updateToolbarItems()

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if mayTerminateWithoutConfirmation {
            return .terminateNow
        }

        return viewModel.confirmDiscardIfNeeded() ? .terminateNow : .terminateCancel
    }

    @objc
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let shouldClose = viewModel.confirmDiscardIfNeeded()
        mayTerminateWithoutConfirmation = shouldClose
        return shouldClose
    }

    private func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit mdPreview",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        let openItem = NSMenuItem(title: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        let saveItem = NSMenuItem(title: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
        saveItem.target = self
        fileMenu.addItem(saveItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        let toggleEditorItem = NSMenuItem(
            title: "Toggle Editor",
            action: #selector(toggleEditor(_:)),
            keyEquivalent: "e"
        )
        toggleEditorItem.target = self
        viewMenu.addItem(toggleEditorItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        return mainMenu
    }

    @objc func openDocument(_ sender: Any?) {
        viewModel.openDocument()
        updateToolbarItems()
    }

    @objc func saveDocument(_ sender: Any?) {
        viewModel.saveDocument()
        updateToolbarItems()
    }

    @objc func toggleEditor(_ sender: Any?) {
        viewModel.toggleEditor()
        updateToolbarItems()
    }

    private func updateToolbarItems() {
        titlebarButtons[.save]?.isEnabled = viewModel.canSave
        titlebarButtons[.edit]?.isEnabled = viewModel.hasDocument
        titlebarButtons[.edit]?.title = viewModel.isEditorVisible ? "Hide Editor" : "Edit"
    }

    private func buildTitlebarActions() -> NSTitlebarAccessoryViewController {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 6
        stackView.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)

        for action in TitlebarAction.allCases {
            let button = NSButton(title: action.title, target: self, action: action.selector)
            button.bezelStyle = .texturedRounded
            button.controlSize = .small
            button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.toolTip = action.title
            titlebarButtons[action] = button
            stackView.addArrangedSubview(button)
        }

        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .left
        accessory.view = stackView
        return accessory
    }
}

private enum TitlebarAction: CaseIterable {
    case open
    case save
    case edit

    var title: String {
        switch self {
        case .open:
            "Open"
        case .save:
            "Save"
        case .edit:
            "Edit"
        }
    }

    var selector: Selector {
        switch self {
        case .open:
            #selector(MarkdownMacPreviewApplication.openDocument(_:))
        case .save:
            #selector(MarkdownMacPreviewApplication.saveDocument(_:))
        case .edit:
            #selector(MarkdownMacPreviewApplication.toggleEditor(_:))
        }
    }
}
