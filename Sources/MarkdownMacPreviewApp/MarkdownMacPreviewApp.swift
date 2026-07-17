import AppKit
import SwiftUI

@main
@MainActor
final class MarkdownMacPreviewApplication: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static var sharedDelegate: MarkdownMacPreviewApplication?
    private let viewModel = AppViewModel()
    private var window: NSWindow?
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
        window.title = "Markdown Mac Preview"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

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
            withTitle: "Quit Markdown Mac Preview",
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
    }

    @objc private func saveDocument(_ sender: Any?) {
        viewModel.saveDocument()
    }

    @objc private func toggleEditor(_ sender: Any?) {
        viewModel.toggleEditor()
    }
}
