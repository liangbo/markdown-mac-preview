# Markdown Mac Preview Design

Date: 2026-07-17
Project path: `/Users/liangbo/aiskills/markdown-mac-preview`

## Goal

Build a native macOS application for opening, previewing, and lightly editing Markdown files. The application should be a real local Mac app, not a browser-hosted site. It will live as an independent project inside the existing `aiskills` Git repository so future changes can be managed with normal Git workflows.

The first version should prioritize a comfortable preview experience. Editing is supported, but the app should feel like a Markdown reader with editing available when needed, not a full writing studio.

## Scope

The first version includes:

- A SwiftUI macOS app project under `markdown-mac-preview`.
- A build path that produces a local `.app` bundle for double-click launching.
- Opening local `.md` and `.markdown` files from the app.
- Rendering Markdown content in a readable preview view.
- A toggleable editor view for modifying the opened file.
- Saving changes back to the same local file.
- Clear dirty-state feedback when edits have not been saved.
- Basic document metadata such as file name, character count, word count, and heading count.

The first version does not include:

- Cloud sync.
- Multi-file workspace management.
- Plugin systems.
- GitHub-perfect Markdown rendering.
- WYSIWYG editing.
- Cross-platform builds.

## Recommended Approach

Use a native SwiftUI macOS application.

This gives the app the right long-term shape for macOS: native windows, menus, file dialogs, keyboard shortcuts, and future document handling. It also keeps the app small and avoids shipping a browser runtime for a focused local utility.

Markdown rendering should start with Apple platform APIs by converting Markdown into `AttributedString` where possible. This keeps dependency risk low for the first version. If preview fidelity becomes more important later, the rendering layer can be swapped for a WebKit-backed renderer or a dedicated Markdown library without changing the document model.

## Architecture

### App Shell

The app shell owns the macOS entry point, window configuration, menu commands, and high-level app state. It should expose native commands for opening, saving, and toggling the editor.

Expected files:

- `Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`
- `Sources/MarkdownMacPreviewApp/AppCommands.swift`
- `scripts/build-app.sh`

### Document Model

A document model tracks the currently opened Markdown file and its state:

- file URL
- original content loaded from disk
- current editable content
- dirty state
- computed metadata
- load and save errors

This model should be testable without launching the UI.

Expected files:

- `Sources/MarkdownMacPreviewCore/MarkdownDocument.swift`
- `Sources/MarkdownMacPreviewCore/MarkdownStats.swift`

### Markdown Rendering

A rendering service converts Markdown text into preview content. The initial implementation uses `AttributedString(markdown:)` and falls back to plain text with an error message if conversion fails.

Expected files:

- `Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift`

### Views

The main window should have three working states:

- Empty state: no file is open, with a clear Open action.
- Preview state: the opened file is shown in a large readable preview.
- Edit state: a split layout shows editor and preview side by side, or an editor pane is revealed beside the preview.

The preview should remain the visual center of the app. Editing should be easy to reach but not dominate the default layout.

Expected files:

- `Sources/MarkdownMacPreviewApp/ContentView.swift`
- `Sources/MarkdownMacPreviewApp/PreviewView.swift`
- `Sources/MarkdownMacPreviewApp/EditorView.swift`
- `Sources/MarkdownMacPreviewApp/StatusBarView.swift`

## Data Flow

1. The user opens a Markdown file through the app.
2. The app validates the extension as `.md` or `.markdown`.
3. The document model reads UTF-8 text from disk.
4. The main view displays the preview and metadata.
5. If the user enables editing, changes update the document model immediately.
6. The preview re-renders from the current text.
7. Save writes the current text back to the original file URL.
8. After a successful save, dirty state clears.

## Error Handling

The app should show friendly local errors for:

- unsupported file type
- unreadable file
- non-UTF-8 content
- save failure
- Markdown render fallback

Errors should appear in the window without crashing the app. The document model should preserve the current text if saving fails.

## UX Details

Default layout should favor preview readability:

- Use a calm native macOS layout.
- Keep toolbar actions compact: Open, Save, Toggle Editor.
- Show unsaved changes near the file name or status area.
- Use readable preview typography and comfortable line width.
- Do not show marketing copy or onboarding screens.

Keyboard shortcuts:

- `Command-O`: Open file.
- `Command-S`: Save file.
- `Command-E`: Toggle editor.

## Testing

Core tests should cover:

- loading Markdown text from a valid file
- rejecting unsupported extensions
- detecting dirty state after edits
- clearing dirty state after save
- computing document stats
- rendering basic Markdown without throwing

UI verification should include a manual run of the app to confirm:

- the app launches
- file open dialog accepts Markdown files
- preview updates after edits
- save writes changes back to disk

## Project Layout

The project should live here:

```text
/Users/liangbo/aiskills/markdown-mac-preview
```

Planned structure:

```text
markdown-mac-preview/
  Package.swift
  README.md
  docs/
    superpowers/
      specs/
        2026-07-17-markdown-mac-preview-design.md
      plans/
  Sources/
    MarkdownMacPreviewApp/
    MarkdownMacPreviewCore/
  Tests/
    MarkdownMacPreviewCoreTests/
```

A Swift Package layout is preferred for the first implementation because it is lightweight, easy to review in Git, and keeps the core model easy to test. Because the user wants a real local Mac app, the project must also include a packaging script that turns the built executable into a minimal `.app` bundle with an `Info.plist`. If a full Xcode project becomes necessary for signing, icons, or richer packaging details, it can be added after the core behavior is working.

## Acceptance Criteria

The first implementation is complete when:

- The project exists at `/Users/liangbo/aiskills/markdown-mac-preview`.
- The macOS app launches locally from the generated `.app` bundle.
- A user can open a `.md` or `.markdown` file.
- The file content renders as Markdown preview.
- The user can toggle editing, change content, and save it.
- Unsaved changes are visible to the user.
- Core model and rendering tests pass.
- The packaging script creates a usable local `.app` bundle.
- The design and implementation plan are stored under `markdown-mac-preview/docs`.
