# Markdown Mac Preview

A native macOS Markdown preview app focused on local `.md` and `.markdown` files.

The app opens a local Markdown file, renders a readable preview by default, and lets you toggle a plain-text editor when you need to make small changes.

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
open "build/Markdown Mac Preview.app"
```

The generated app bundle is local and unsigned. macOS may ask for confirmation the first time it opens.

## Shortcuts

- `Command-O`: open a Markdown file
- `Command-S`: save current changes
- `Command-E`: show or hide the editor
