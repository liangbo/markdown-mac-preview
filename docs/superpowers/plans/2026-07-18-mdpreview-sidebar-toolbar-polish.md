# mdPreview Sidebar and Toolbar Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the recent-files sidebar, titlebar actions, and app icon shape for mdPreview.

**Architecture:** Keep the existing SwiftUI/AppKit hybrid app. Use `HSplitView` for a resizable sidebar, move Open/Save/Edit into an `NSToolbar`, add explicit recent-file reorder persistence, and process the icon source into a transparent rounded app icon during resource generation.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, UserDefaults, macOS `sips`/`iconutil`, Python/Pillow when available for icon alpha processing.

## Global Constraints

- Native macOS app remains named `mdPreview`.
- Sidebar starts at roughly 70% of the previous width and remains user-resizable.
- Clicking anywhere in a recent-file row opens that Markdown file.
- Opening a recent file does not move it to the top.
- Newly added files are inserted at the top.
- User drag ordering is persisted.
- App icon should have rounded corners and transparent white background.
- Open, Save, and Edit actions should live in the macOS titlebar toolbar.

---

### Task 1: Recent File Ordering

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/RecentFile.swift`
- Modify: `Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Test: `Tests/MarkdownMacPreviewAppTests/RecentFilesStoreTests.swift`
- Test: `Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`

**Interfaces:**
- Produces: `RecentFilesStore.reorder(fromOffsets:toOffset:) -> [RecentFile]`
- Produces: `RecentFilesStore.record(_ url: URL, promoteExisting: Bool) -> [RecentFile]`
- Produces: `AppViewModel.moveRecentFiles(fromOffsets:toOffset:)`

- [x] Add tests that opening an existing recent file with `promoteExisting: false` preserves order.
- [x] Add tests that recording a new file still inserts it at index 0.
- [x] Add tests that reordering recent files persists through `load()`.
- [x] Implement the store and view model APIs.
- [x] Run `swift test --filter RecentFilesStoreTests` and `swift test --filter AppViewModelTests`.

### Task 2: Sidebar Interaction and Resizable Layout

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift`
- Modify: `Sources/MarkdownMacPreviewApp/ContentView.swift`

**Interfaces:**
- Consumes: `AppViewModel.moveRecentFiles(fromOffsets:toOffset:)`
- Produces: sidebar with default width near 168 pt and drag-resizable split.

- [x] Replace the outer `HStack` layout with `HSplitView`.
- [x] Set sidebar width constraints to `minWidth: 150`, `idealWidth: 168`, `maxWidth: 260`.
- [x] Make each row fill the available width and use `contentShape(Rectangle())` so clicking the full row opens the file.
- [x] Add `List` move support using `.onMove(perform:)`.
- [x] Run `swift test`.

### Task 3: Titlebar Toolbar

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/ContentView.swift`
- Modify: `Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`

**Interfaces:**
- Consumes: `AppViewModel.openDocument()`, `saveDocument()`, `toggleEditor()`, `canSave`, `hasDocument`, `isEditorVisible`
- Produces: AppKit `NSToolbar` with Open, Save, Edit actions.

- [x] Remove the in-content Open/Save/Edit toolbar from `ContentView`.
- [x] Add an `NSToolbar` to the window with Open, Save, and Edit items.
- [x] Keep menu shortcuts unchanged.
- [x] Keep toolbar item enabled states synchronized with the view model.
- [x] Run `swift test`.

### Task 4: Rounded Transparent Icon

**Files:**
- Modify: `Resources/AppIcon.png`
- Modify: `scripts/build-app.sh` only if needed for generated icon flow.

**Interfaces:**
- Produces: rounded transparent PNG source and generated `AppIcon.icns`.

- [x] Process the current icon PNG so near-white background pixels become transparent.
- [x] Apply rounded icon mask.
- [x] Run `scripts/build-app.sh`.
- [x] Verify `build/mdPreview.app/Contents/Resources/AppIcon.icns` exists and `iconutil` can parse it.

### Task 5: Final Verification and Merge

**Files:**
- Verify all changed files.

- [x] Run full `swift test`.
- [x] Run `scripts/build-app.sh`.
- [x] Run `plutil -lint build/mdPreview.app/Contents/Info.plist`.
- [x] Confirm only intended files are tracked in Git.
- [ ] Commit, merge back to `main`, remove the temporary worktree.
