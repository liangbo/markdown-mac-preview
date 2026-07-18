# AGENTS.md

## Project

`mdPreview` is a native macOS Markdown preview app for local `.md` and `.markdown` files. It is preview-first, supports light plain-text editing, keeps a Recent sidebar, renders Markdown as HTML in an embedded WebView, and builds into `mdPreview.app`.

## Repository

Work only in this independent repository:

```text
/Users/liangbo/Documents/workspace/markdown-mac-preview
```

Do not use or recreate the old parent-repository path:

```text
/Users/liangbo/aiskills/markdown-mac-preview
```

The active remote is:

```text
git@github.com:liangbo/markdown-mac-preview.git
```

## Read First

Before making product or code changes, read these files:

- `README.md`: quick project overview and commands.
- `docs/product-requirements.md`: full product requirements and acceptance criteria.
- `docs/development-story.md`: development history and context for how the app evolved.
- Relevant files under `docs/superpowers/specs/` and `docs/superpowers/plans/` when working on related functionality.

## Project Structure

```text
Sources/
  MarkdownMacPreviewApp/      macOS app shell, SwiftUI views, WebView preview, app state
  MarkdownMacPreviewCore/     document model, Markdown renderer, stats
Tests/
  MarkdownMacPreviewAppTests/
  MarkdownMacPreviewCoreTests/
Resources/
  AppIcon.png
scripts/
  build-app.sh
docs/
  product-requirements.md
  development-story.md
  superpowers/
```

## Core Behavior

Preserve these product decisions unless the user explicitly asks to change them:

- Native macOS app, not browser-only and not web-hosted.
- App name and bundle name: `mdPreview`.
- Supported files: `.md` and `.markdown`.
- Default experience: preview first, editing optional.
- Markdown preview path: Markdown to styled HTML to embedded `WKWebView`.
- JavaScript disabled in the preview WebView.
- Local relative images should render when they are inside the Markdown file's directory tree.
- Recent sidebar appears on the left and includes `Open`, `Edit` or `Hide Editor`, and `Save`.
- Clicking a recent file should not reorder it.
- Users can manually reorder recent files by dragging.
- Opening or selecting files should feel immediate; preview rendering may happen asynchronously.
- Stale async preview render results must not overwrite the active document.

## Commands

Run tests:

```bash
swift test
```

Run from source:

```bash
swift run MarkdownMacPreview
```

Build the local app bundle:

```bash
scripts/build-app.sh
```

Generated app:

```text
build/mdPreview.app
```

Validate the generated bundle:

```bash
plutil -lint build/mdPreview.app/Contents/Info.plist
```

## Development Workflow

- Check `git status --short --branch` before editing.
- Keep changes focused and small.
- Prefer the existing SwiftUI/AppKit/WebKit patterns in the repository.
- Add or update tests for behavior changes.
- Run `swift test` before claiming behavior is complete.
- Rebuild with `scripts/build-app.sh` when changing UI, app bundle behavior, icon resources, packaging, or app identity.
- Validate `Info.plist` after rebuilding the app bundle.
- Update `docs/product-requirements.md` when product behavior changes.
- Update `docs/development-story.md` only when the user wants the public-facing development narrative changed.
- Keep generated build outputs out of Git.

## Testing Expectations

Existing tests cover:

- Markdown document loading, saving, and dirty state.
- Markdown stats.
- Markdown-to-HTML rendering.
- Preview HTML and local image handling.
- Recent files storage, deduplication, ordering, removal, and persistence.
- App view model state, async preview rendering, stale render prevention, save behavior, and sidebar action state.

When adding new behavior, prefer focused unit or view-model tests before implementation.

## Documentation Roles

- `README.md`: short user/developer entry point.
- `docs/product-requirements.md`: complete PRD for implementing or evaluating the app.
- `docs/development-story.md`: shareable development-process narrative.
- `docs/superpowers/specs/`: design decisions and requirements for specific iterations.
- `docs/superpowers/plans/`: implementation plans and verification checklists for specific iterations.

## Git Notes

- Main branch: `main`.
- Push destination: `origin/main`.
- Keep the working tree clean after each completed task.
- If the user asks for a feature branch or worktree, use a focused branch name that describes the change.
