# mdPreview Async Preview and Left Toolbar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move titlebar actions to the upper-left area and make opening large Markdown files feel immediate by rendering previews asynchronously.

**Architecture:** Keep document loading synchronous for file I/O and selection state, but move Markdown-to-HTML preview rendering into cancellable async tasks in `AppViewModel` backed by a serial background render queue. `ContentView` reads a stored preview state instead of triggering synchronous rendering from a computed property. Open/Save/Edit are exposed through a leading `NSTitlebarAccessoryViewController` in the window titlebar.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, Combine, Swift concurrency.

## Global Constraints

- Open, Save, and Edit remain in the macOS titlebar toolbar.
- Toolbar actions should sit toward the upper-left, near the window controls.
- Opening or clicking a Markdown file should update the selected document immediately.
- Long preview rendering should not block document switching.
- Stale async render results must not overwrite the active document.
- Editing still updates live preview, with light debounce.
- Existing recent files, save, HTML WebView preview, and local image behavior remain intact.

---

### Task 1: Async Preview State

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Modify: `Sources/MarkdownMacPreviewApp/ContentView.swift`
- Test: `Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`

**Interfaces:**
- Produces: `AppViewModel.previewContent: MarkdownPreviewContent`
- Produces: `AppViewModel.isPreviewRendering: Bool`
- Produces: async rendering that ignores stale results.

- [x] Add tests that `loadDocument(from:)` immediately changes `document` and marks preview as rendering before a delayed renderer completes.
- [x] Add tests that completing an older render after switching files does not overwrite the newer preview.
- [x] Add tests that edited content eventually updates preview through the async path.
- [x] Implement render task cancellation and version checking.
- [x] Run production Markdown rendering on a serial background queue so large previews do not block the window.
- [x] Keep a lightweight placeholder preview while loading a new document and preserve the previous preview while editing.
- [x] Avoid forced preview re-render on save when content is unchanged.
- [x] Run `swift test --filter AppViewModelTests`.

### Task 2: Preview Loading UI

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/ContentView.swift`

**Interfaces:**
- Consumes: `viewModel.previewContent`
- Consumes: `viewModel.isPreviewRendering`

- [x] Pass the stored preview content to `PreviewView`.
- [x] Overlay a small `Rendering...` indicator while the async preview is running.
- [x] Keep editor and WebView layout unchanged.
- [x] Run `swift test`.

### Task 3: Titlebar Toolbar Leading Placement

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`

**Interfaces:**
- Consumes: existing Open, Save, Edit selectors.
- Produces: toolbar item ordering biased toward the left side of the titlebar.

- [x] Replace toolbar item placement with a leading titlebar accessory for Open, Save, and Edit.
- [x] Keep item enabled state sync unchanged.
- [x] Run `swift test`.

### Task 4: Final Verification and Merge

**Files:**
- Verify all changed files.

- [x] Run full `swift test`.
- [x] Run `scripts/build-app.sh`.
- [x] Run `plutil -lint build/mdPreview.app/Contents/Info.plist`.
- [x] Confirm only intended files are tracked.
- [ ] Commit, merge back to `main`, remove worktree.
