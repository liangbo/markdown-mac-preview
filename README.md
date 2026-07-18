# mdPreview

A native macOS Markdown preview app focused on local `.md` and `.markdown` files.

The app opens local Markdown files, keeps recently opened files in a left sidebar, renders Markdown as HTML in an embedded macOS WebView by default, and lets you toggle a plain-text editor with live preview when you need to make small changes.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer

## Run From Source

```bash
swift run MarkdownMacPreview
```

## Test

```bash
swift test
```

## Build A Local App Bundle

```bash
scripts/build-app.sh
open "build/mdPreview.app"
```

The generated app bundle is local and unsigned. macOS may ask for confirmation the first time it opens.

## Shortcuts

- `Command-O`: open a Markdown file
- `Command-S`: save current changes
- `Command-E`: show or hide the editor
