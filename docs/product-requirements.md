# mdPreview Product Requirements Document

## 1. Product Overview

`mdPreview` is a native macOS application for opening, previewing, and lightly editing local Markdown files. It is designed as a local desktop reader first, with editing available when the user needs quick changes.

The app must not require a browser tab or local web server. It should launch as a normal macOS `.app` bundle, open `.md` and `.markdown` files from disk, render them as HTML in an embedded preview surface, and preserve a small recent-file workflow for quickly reopening documents.

## 2. Goals

- Provide a native macOS app for local Markdown preview.
- Make Markdown preview the primary experience.
- Support light plain-text editing with live preview.
- Keep recently opened Markdown files visible in a left sidebar.
- Render Markdown as HTML with readable document styling.
- Support local images referenced by Markdown files using relative paths.
- Keep file switching responsive, even for larger documents.
- Package the app as `mdPreview.app`.

## 3. Non-Goals

- Do not build a browser-only or web-hosted app.
- Do not build a full folder/project file explorer.
- Do not add cloud sync, accounts, collaboration, or remote storage.
- Do not implement WYSIWYG rich-text editing.
- Do not support multi-window document management in the first version.
- Do not require GitHub-perfect Markdown compatibility if a simpler Markdown engine is sufficient.
- Do not add plugin systems, themes marketplace, or complex settings.

## 4. Target Platform

- Platform: macOS.
- Minimum OS: macOS 13 or newer.
- App type: native local Mac app.
- Preferred implementation stack: Swift 5.9+, SwiftUI, AppKit where needed, WebKit for HTML preview.
- The app should be buildable from a lightweight Swift Package layout.

## 5. Primary User

The target user is someone who keeps Markdown notes or documents locally and wants a quick desktop app for reading them, with occasional editing.

Common use cases:

- Open a local `.md` file and read it in a clean preview.
- Reopen recently used Markdown files from the app sidebar.
- Quickly edit a Markdown file and save it back to disk.
- Preview local images referenced near the Markdown file.
- Install the app into `/Applications` and use it as a normal desktop utility.

## 6. App Identity and Packaging

The app-facing name must be `mdPreview`.

Required naming:

- Window title: `mdPreview`
- Quit menu item: `Quit mdPreview`
- Built app bundle: `build/mdPreview.app`
- App icon source: `Resources/AppIcon.png`
- Generated bundle icon: `AppIcon.icns`

The repository should include a packaging script that builds a local unsigned `.app` bundle. The generated bundle may require normal macOS first-open confirmation because it is local and unsigned.

## 7. Core Functional Requirements

### 7.1 Open Markdown Files

The app must allow users to open local Markdown files through a native macOS file picker.

Requirements:

- Accept `.md` and `.markdown` files.
- Reject unsupported file extensions with a friendly error.
- Read files as UTF-8 text.
- Show the opened document in the preview area.
- Add opened files to the Recent sidebar.
- If another document has unsaved changes, show a confirmation before switching.

Unsaved-change confirmation should offer:

- Save
- Discard
- Cancel

### 7.2 Preview Markdown as HTML

The app must render Markdown into HTML and display it inside the native app window.

Expected rendering behavior:

- Headings become HTML headings.
- Paragraphs, bold text, links, blockquotes, lists, code blocks, inline code, tables, horizontal rules, and images should be styled for reading.
- Raw HTML included in Markdown should render as HTML when supported by the Markdown engine and WebView.
- The preview should use a constrained article layout with comfortable typography.
- The app should use an embedded WebView, not an external browser.
- JavaScript should be disabled in the preview surface.

Preferred pipeline:

```text
Markdown text -> Markdown-to-HTML renderer -> styled HTML document -> embedded WKWebView
```

### 7.3 Local Image Rendering

Markdown images that refer to files in the same directory as the Markdown file, or below that directory, should render in preview.

Examples:

```markdown
![diagram](diagram.png)
![screenshot](./images/screenshot.png)
```

Requirements:

- Resolve relative image paths against the parent directory of the current Markdown file.
- Support common local image formats such as PNG, JPEG, GIF, SVG, and WebP.
- Do not embed or rewrite remote HTTP/HTTPS images.
- Do not allow relative image handling to read arbitrary files outside the Markdown file's directory tree.
- Missing images should not crash the preview.

One acceptable implementation is to rewrite local image sources into data URLs before loading the generated preview HTML file.

### 7.4 Edit Mode

The app must support a plain-text Markdown editor that can be toggled on and off.

Requirements:

- Default mode is preview-only after a document opens.
- The user can toggle editing using the UI or `Command-E`.
- In edit mode, show editor and preview side by side.
- Editing updates the in-memory document content immediately.
- Preview updates from unsaved edited content.
- Saving writes the current edited content back to the original file.
- After save succeeds, the dirty state clears.
- If save fails, keep the edited content in memory and show an error.

### 7.5 Live Preview and Performance

Preview rendering should feel responsive.

Requirements:

- Opening or selecting a file should switch the selected document immediately.
- Long Markdown-to-HTML rendering should not block the main UI.
- While a new preview is rendering, show a lightweight `Rendering...` indicator.
- Stale render results must not overwrite the active document after the user has switched files.
- Editing should debounce preview updates lightly so typing does not trigger excessive rendering.
- While editing, keep the previous preview visible until the new preview is ready.

An acceptable implementation is a cancellable render task with a generation/version check and a serial background rendering queue.

### 7.6 Save

The app must save changes back to the same local file path.

Requirements:

- Save is enabled only when the current document has unsaved changes.
- `Command-S` saves the current document.
- Save clears dirty state on success.
- Save failures are shown without closing or discarding the document.
- Saving unchanged content should not force an unnecessary preview re-render.

## 8. Recent Sidebar Requirements

The app must include a narrow left sidebar titled `Recent`.

### 8.1 Sidebar Layout

The sidebar should appear on the left side of the main window.

Requirements:

- Header text: `Recent`
- Place `Open`, `Edit` or `Hide Editor`, and `Save` controls directly after the `Recent` header.
- Keep the sidebar relatively narrow, around 70% of the earlier wider version.
- Allow users to adjust sidebar width through the split view.
- Use native macOS styling.

Suggested width constraints:

- Minimum width: about 150 px.
- Ideal width: about 168 px.
- Maximum width: about 260 px.

### 8.2 Sidebar Action Buttons

Header actions:

- `Open`: always enabled and opens the Markdown file picker.
- `Edit`: disabled until a document is open.
- `Hide Editor`: replaces `Edit` while edit mode is visible.
- `Save`: disabled unless the current document has unsaved changes.

These actions should call the same underlying document actions as the menu shortcuts.

### 8.3 Recent File List

Each recent file row should show:

- File name.
- Parent folder path in smaller secondary text.

Requirements:

- Clicking anywhere in the row should open that Markdown file, not only clicking the text.
- The active document should be visibly selected.
- Missing recent files should be removed when selected and an error should be shown.
- Rows should support context-menu removal from Recent.
- The recent list should persist across launches.
- The recent list should store at most 20 files.

### 8.4 Recent File Ordering

Ordering rules:

- Newly opened files are added to the top.
- Opening the same file again through the file picker moves it to the top.
- Clicking an existing recent file should not reorder it.
- Users should be able to manually reorder recent files by dragging.
- Manual order should persist across launches.

## 9. Menus and Keyboard Shortcuts

The app must provide native macOS menu commands.

Required shortcuts:

- `Command-O`: Open Markdown file.
- `Command-S`: Save current document.
- `Command-E`: Toggle editor.
- `Command-Q`: Quit mdPreview.

If the current document has unsaved changes, closing or quitting should ask whether to save, discard, or cancel.

## 10. Status and Metadata

The app should show simple document status information.

Required status items:

- Current file name.
- Dirty state indicator for unsaved changes.
- Character count.
- Word count.
- Heading count.
- Error or warning message when relevant.

Status information should be derived from the current in-memory document content.

## 11. Data Model Requirements

### 11.1 Markdown Document

The document model should track:

- File URL.
- Original loaded content.
- Current editable content.
- Dirty state.
- Derived file name.
- Derived stats.

The model should provide:

- Load from local URL.
- Validate supported file extensions.
- Update content.
- Save to original URL.

### 11.2 Recent Files Store

The recent file store should track:

- Standardized absolute file URLs.
- Derived file name.
- Derived parent path.

Persistence:

- Local persistence is sufficient.
- `UserDefaults` is acceptable.

Required behavior:

- Deduplicate by standardized file URL.
- Ignore unsupported extensions.
- Cap list length at 20.
- Remove stale files.
- Persist manual reorder operations.

## 12. Error Handling

The app should never crash for ordinary document problems.

Show friendly errors for:

- Unsupported file type.
- File no longer exists.
- File cannot be read.
- File cannot be decoded as UTF-8.
- File cannot be saved.
- Markdown renderer fallback.
- Preview HTML file write failure.

If preview rendering fails, show a safe fallback HTML document that displays escaped source text in a readable block.

## 13. Security and Local File Access

The app is local-first and should avoid unnecessary network or script behavior.

Requirements:

- Disable JavaScript in the preview WebView.
- Use the Markdown file parent directory as the preview base/read-access boundary.
- Do not allow local image embedding to escape the Markdown file's parent directory tree.
- Do not execute Markdown content as code.
- Do not require a local server.

## 14. Suggested Technical Architecture

The following architecture is recommended but not mandatory if another implementation satisfies the behavior.

```text
Sources/
  MarkdownMacPreviewApp/
    MarkdownMacPreviewApp.swift      macOS app delegate, window, menus
    ContentView.swift                main split layout
    RecentFilesSidebarView.swift     Recent sidebar and action controls
    PreviewView.swift                WKWebView wrapper and preview file loading
    EditorView.swift                 plain text editor
    StatusBarView.swift              file metadata and messages
    AppViewModel.swift               app state and document actions
    RecentFile.swift                 recent file model and store
  MarkdownMacPreviewCore/
    MarkdownDocument.swift           file loading, saving, dirty state
    MarkdownRenderer.swift           Markdown to styled HTML
    MarkdownStats.swift              character, word, heading counts
Tests/
  MarkdownMacPreviewAppTests/
  MarkdownMacPreviewCoreTests/
Resources/
  AppIcon.png
scripts/
  build-app.sh
```

Recommended dependencies:

- SwiftUI and AppKit for native macOS UI.
- WebKit for embedded HTML preview.
- A lightweight Markdown-to-HTML library such as Ink.

## 15. Build and Distribution Requirements

The repository should support:

```bash
swift run MarkdownMacPreview
swift test
scripts/build-app.sh
```

The build script should:

- Build the Swift package executable.
- Create `build/mdPreview.app`.
- Generate or include `Info.plist`.
- Include `AppIcon.icns`.
- Copy the executable into the app bundle.

The app icon should be based on `Resources/AppIcon.png`. If the source image includes a visual checkerboard background, it should be converted to real transparency before generating `.icns`.

## 16. Acceptance Criteria

An implementation is complete when all items below are true:

- The app builds as a native macOS app named `mdPreview`.
- `build/mdPreview.app` is generated successfully.
- The app launches locally.
- The user can open `.md` and `.markdown` files.
- Unsupported file types are rejected.
- Markdown renders as styled HTML in an embedded preview.
- Raw HTML and tables render through the HTML preview path when supported by the Markdown engine.
- Relative local images next to the Markdown file render in preview.
- Remote and missing images do not crash the preview.
- Recent files appear in the left sidebar.
- Recent rows are clickable across the full row.
- Recent files persist across launches.
- Recent file ordering follows the defined add/click/drag rules.
- `Open`, `Edit` or `Hide Editor`, and `Save` appear after the `Recent` header.
- `Edit` and `Save` enable and disable according to document state.
- Edit mode supports live preview of unsaved content.
- Switching recent files feels immediate and does not block on long preview rendering.
- Stale async render results cannot overwrite the active document preview.
- Dirty state is visible and clears after successful save.
- Closing or switching away with unsaved changes prompts the user.
- `Command-O`, `Command-S`, and `Command-E` work.
- `Info.plist` validates.
- The generated `AppIcon.icns` can be parsed by macOS tools.
- Core and app tests pass.

## 17. Recommended Test Coverage

Core document tests:

- Load supported Markdown file.
- Reject unsupported extension.
- Dirty state changes after edit.
- Dirty state clears after save.
- Character, word, and heading stats are computed.

Markdown renderer tests:

- Basic Markdown renders into an HTML document.
- Headings, bold text, tables, code blocks, and raw HTML are handled.
- CSS and article container are present.
- Fallback escapes unsafe source text.

Recent file tests:

- New files are added newest first.
- Duplicate files deduplicate.
- Existing recent file can be opened without being promoted.
- Manual reorder persists.
- Missing/stale files are removed.
- Unsupported recent paths are ignored.
- Recent list is capped at 20.

Preview image tests:

- Relative images from the Markdown directory are embedded or resolved.
- Remote images are not rewritten.
- Missing images are left untouched.
- Images outside the Markdown directory are not embedded.

App state tests:

- Loading a document updates selection immediately before async preview completes.
- Stale preview renders do not overwrite newer documents.
- Editing keeps previous preview visible during debounce.
- Save does not trigger preview rendering when content is unchanged.
- Sidebar action state matches document and dirty state.

Manual verification:

- Launch generated app bundle.
- Open a real Markdown file.
- Open a Markdown file with a relative image.
- Toggle edit mode and type content.
- Save and reopen to confirm persistence.
- Drag recent files to reorder.
- Try closing with unsaved changes.

## 18. Handoff Notes for Other Coding Agents

When using this document with another coding agent, give it the following instruction:

> Build a native macOS app named `mdPreview` according to this PRD. Use the acceptance criteria as the completion checklist. Prefer a simple Swift Package based implementation with SwiftUI, AppKit menus, WebKit preview, and tests for document, rendering, recent files, and app state behavior. Do not build a browser-only app or require a local server.

If the agent is modifying the existing repository rather than implementing from scratch, ask it to first inspect:

- `README.md`
- `Package.swift`
- `Sources/MarkdownMacPreviewApp`
- `Sources/MarkdownMacPreviewCore`
- `Tests`
- `scripts/build-app.sh`
