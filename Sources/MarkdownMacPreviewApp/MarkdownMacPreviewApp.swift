import AppKit
import Combine
import SwiftUI

@main
@MainActor
final class MarkdownMacPreviewApplication: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static var sharedDelegate: MarkdownMacPreviewApplication?
    private let viewModel = AppViewModel()
    private var window: NSWindow?
    private var toolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
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
        window.toolbar = buildWindowToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titleVisibility = .visible
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

    @objc private func openDocument(_ sender: Any?) {
        viewModel.openDocument()
        updateToolbarItems()
    }

    @objc private func saveDocument(_ sender: Any?) {
        viewModel.saveDocument()
        updateToolbarItems()
    }

    @objc private func toggleEditor(_ sender: Any?) {
        viewModel.toggleEditor()
        updateToolbarItems()
    }

    private func buildWindowToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "mdPreview.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    private func makeToolbarItem(
        identifier: NSToolbarItem.Identifier,
        label: String,
        systemSymbolName: String,
        action: Selector
    ) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.target = self
        item.action = action
        if #available(macOS 11.0, *) {
            item.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: label)
        }
        toolbarItems[identifier] = item
        return item
    }

    private func updateToolbarItems() {
        toolbarItems[.saveDocument]?.isEnabled = viewModel.canSave
        toolbarItems[.toggleEditor]?.isEnabled = viewModel.hasDocument
        toolbarItems[.toggleEditor]?.label = viewModel.isEditorVisible ? "Hide Editor" : "Edit"
        toolbarItems[.toggleEditor]?.paletteLabel = toolbarItems[.toggleEditor]?.label ?? "Edit"
        toolbarItems[.toggleEditor]?.toolTip = toolbarItems[.toggleEditor]?.label
    }
}

extension MarkdownMacPreviewApplication: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.openDocument, .saveDocument, .toggleEditor, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.openDocument, .saveDocument, .toggleEditor, .flexibleSpace]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .openDocument:
            makeToolbarItem(
                identifier: itemIdentifier,
                label: "Open",
                systemSymbolName: "folder",
                action: #selector(openDocument(_:))
            )
        case .saveDocument:
            makeToolbarItem(
                identifier: itemIdentifier,
                label: "Save",
                systemSymbolName: "square.and.arrow.down",
                action: #selector(saveDocument(_:))
            )
        case .toggleEditor:
            makeToolbarItem(
                identifier: itemIdentifier,
                label: "Edit",
                systemSymbolName: "square.and.pencil",
                action: #selector(toggleEditor(_:))
            )
        default:
            nil
        }
    }
}

private extension NSToolbarItem.Identifier {
    static let openDocument = NSToolbarItem.Identifier("mdPreview.open")
    static let saveDocument = NSToolbarItem.Identifier("mdPreview.save")
    static let toggleEditor = NSToolbarItem.Identifier("mdPreview.edit")
}
