# mdPreview Recent Files and Live Preview Design

## Goal

Improve the native macOS Markdown app so it feels more like a small local document tool: the compiled app is named `mdPreview`, opened Markdown files appear in a left-side recent-files explorer, and editing shows preview updates immediately.

## Scope

This iteration includes three user-facing changes:

1. Add a left sidebar for recently opened Markdown files.
2. Rename the built application from `Markdown Mac Preview.app` to `mdPreview.app` and update visible app naming.
3. Ensure edit mode gives immediate live preview feedback without requiring save.

This iteration does not add a full folder browser, recursive project tree, search, tagging, or cloud sync.

## User Experience

The main window keeps the current toolbar and preview-first behavior. A narrow left sidebar is added beside the document area. The sidebar is titled `Recent` and lists the latest Markdown files opened by the user. Each row shows the file name and a smaller parent folder path so repeated names can be distinguished.

Opening a Markdown file through the toolbar or File menu adds it to the top of the sidebar. Opening the same file again moves it back to the top instead of duplicating it. The list keeps at most 20 files.

Clicking a recent file opens it. If the current document has unsaved changes, the existing Save / Discard / Cancel confirmation appears before switching. If the recent file no longer exists, the app shows an error message and removes that stale entry from the recent list.

When no document is open, the center empty state remains available. The sidebar can still show recent files so the user can reopen something quickly.

## Data Model

Create a small model for recent files:

- `RecentFile`: stores a stable `URL`, derived `fileName`, and derived `parentPath`.
- `RecentFilesStore`: owns loading and saving recent file paths using `UserDefaults`.

The store persists absolute file paths as strings. It deduplicates by standardized file URL, keeps newest first, filters unsupported extensions, and caps the list at 20.

`AppViewModel` owns the currently loaded `recentFiles` array and delegates persistence to `RecentFilesStore`. This keeps UI code simple and makes recent-file behavior testable outside AppKit UI.

## App Naming

The app-facing name becomes `mdPreview` everywhere the user sees or builds the app:

- Window title: `mdPreview`
- Quit menu item: `Quit mdPreview`
- Bundle output: `build/mdPreview.app`
- README commands and paths

The Swift package product name may remain `MarkdownMacPreview` internally unless changing it is required for the bundle script. Keeping internal target names stable reduces unnecessary churn.

## Live Preview

The current editor binding already updates the document content as the user types. This design preserves that behavior and makes it explicit in tests and UI structure: when edit mode is visible, the preview pane uses the same in-memory document content, so preview changes appear before save.

No debounce is added in this iteration. Markdown files targeted by this app are expected to be ordinary notes and documents, and immediate feedback is the simpler, more predictable behavior. If large-file performance becomes a real issue later, a measured debounce can be added.

## Error Handling

- Unsupported file extensions are still rejected by the document loader.
- Missing recent files are removed from the recent list when selected and an error is shown in the status bar.
- Unsaved-change confirmation remains the guard before opening from either the system file picker or the recent list.
- Save errors keep the current document open and prevent switching away when the user chose Save.

## Testing

Add tests for recent-file behavior:

- Adding a file puts it first.
- Adding the same file again moves it first without duplication.
- The list is capped at 20 files.
- Unsupported extensions are ignored.
- Removing a stale path updates the persisted list.

Add or adjust app-level/core-level tests to confirm edit updates are reflected in preview content through the view model, proving live preview uses unsaved in-memory content.

Full verification before completion:

- Run all Swift tests.
- Run Swift build.
- Run the app bundle script and verify `build/mdPreview.app` exists.
- Lint the generated `Info.plist`.
- Launch `build/mdPreview.app` once to confirm macOS accepts the bundle.
