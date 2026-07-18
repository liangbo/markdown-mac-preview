# mdPreview WebView HTML Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current attributed-text preview with a real Markdown-to-HTML renderer displayed inside an embedded `WKWebView`, styled like a clean Typora-style document reader.

**Architecture:** Add Ink as the Markdown-to-HTML engine in the core target, make `MarkdownPreviewContent` carry a complete HTML document string, and replace `PreviewView` with a SwiftUI `NSViewRepresentable` wrapper around `WKWebView`. Keep `AppViewModel` preview caching, but cache HTML content instead of attributed text.

**Tech Stack:** Swift 5.9, Swift Package Manager, Ink, SwiftUI, AppKit, WebKit, XCTest, macOS 13+.

## Global Constraints

- App remains native macOS and local-only.
- Preview must be rendered inside the app using `WKWebView`, not an external browser.
- Markdown must render through Markdown-to-HTML conversion, not `AttributedString(markdown:)`.
- Visual style should be Typora-like clean document reading.
- Raw HTML inside Markdown must remain HTML for WebView rendering.
- Existing recent files, editor, saving, unsaved-change guard, and `mdPreview.app` bundle behavior must remain working.
- Preview caching must avoid repeated conversion for unchanged document content.
- Full verification must include tests, build, bundle script, plist lint, and launch check.

---

## Task 1: Add Ink Dependency and HTML Renderer

**Files:**
- Modify: `markdown-mac-preview/Package.swift`
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift`
- Modify: `markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownRendererTests.swift`

**Interfaces:**
- Change `MarkdownPreviewContent` to expose `public let html: String` and `public let warning: String?`.
- Keep `MarkdownRenderer.render(_:) -> MarkdownPreviewContent`.
- Add an internal injectable render path for tests: `static func render(_ markdown: String, htmlRenderer: (String) throws -> String) -> MarkdownPreviewContent`.

- [ ] Write failing tests that assert rendered output includes `<h1`, `<strong`, a Typora-style CSS marker, and an `<article` container.
- [ ] Write a failing test that raw HTML such as `<div class="note"><strong>Hello</strong></div>` survives as HTML in the output.
- [ ] Write a failing fallback test using the injectable renderer that throws; assert the returned HTML escapes source text inside `<pre>` and warning is set.
- [ ] Add Ink to `Package.swift` dependencies and wire `MarkdownMacPreviewCore` to product `Ink`.
- [ ] Replace the current `AttributedString` renderer and regex HTML replacement with Ink Markdown-to-HTML conversion plus HTML document wrapping.
- [ ] Include local CSS in the generated HTML for headings, paragraphs, blockquotes, lists, code blocks, tables, links, images, and body/article layout.
- [ ] Run focused renderer tests and then full `swift test`.
- [ ] Commit with message `Use HTML renderer for Markdown preview`.

## Task 2: Replace Preview UI with WKWebView

**Files:**
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/PreviewView.swift`
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift` only if base URL wiring requires it.

**Interfaces:**
- `PreviewView` consumes `MarkdownPreviewContent` and an optional `baseURL: URL?`.
- `PreviewView` uses `WKWebView.loadHTMLString(content.html, baseURL: baseURL)`.

- [ ] Replace SwiftUI `Text(content.attributed)` preview with `NSViewRepresentable` wrapping `WKWebView`.
- [ ] Disable unnecessary WebView chrome/behavior where appropriate: keep scrolling, no external browser requirement.
- [ ] Pass the current document parent directory as base URL so relative images can resolve.
- [ ] Build to verify WebKit integration compiles.
- [ ] Run full `swift test`.
- [ ] Commit with message `Render preview with WKWebView`.

## Task 3: Update App Preview Cache and Tests

**Files:**
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Modify: `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`
- Modify any tests that still refer to `.attributed`.

**Interfaces:**
- `previewRenderer` injection remains `(String) -> MarkdownPreviewContent`.
- `previewContent` cache remains invalidated on load, edit, and save.

- [ ] Update live-preview test to inspect `previewContent.html`.
- [ ] Keep cache test and update fake renderer to return `MarkdownPreviewContent(html:)`.
- [ ] Add a test that switching from one loaded document to another invalidates cached HTML.
- [ ] Run focused app tests and full `swift test`.
- [ ] Commit with message `Cache generated HTML previews`.

## Task 4: Documentation and Final Verification

**Files:**
- Modify: `markdown-mac-preview/README.md`

**Requirements:**
- README states preview is HTML-based inside the native app.
- README keeps `build/mdPreview.app` instructions.

- [ ] Update README to describe HTML preview, Typora-style reading, recent files, and live editing preview.
- [ ] Run `swift test --disable-sandbox --scratch-path /private/tmp/mdpreview-webview-build --cache-path /private/tmp/mdpreview-webview-swiftpm-cache --config-path /private/tmp/mdpreview-webview-swiftpm-config --security-path /private/tmp/mdpreview-webview-swiftpm-security`.
- [ ] Run `swift build --disable-sandbox --scratch-path /private/tmp/mdpreview-webview-build --cache-path /private/tmp/mdpreview-webview-swiftpm-cache --config-path /private/tmp/mdpreview-webview-swiftpm-config --security-path /private/tmp/mdpreview-webview-swiftpm-security`.
- [ ] Run `scripts/build-app.sh`.
- [ ] Run `plutil -lint "build/mdPreview.app/Contents/Info.plist"`.
- [ ] Run `open -n "build/mdPreview.app"` and confirm process path with `pgrep -fl MarkdownMacPreview`.
- [ ] Commit README/verification fixes only if files changed.

---

## Self-Review

- Spec coverage: Task 1 replaces the renderer architecture and removes regex HTML approximation. Task 2 embeds WKWebView. Task 3 preserves live preview and caching semantics. Task 4 covers documentation and full verification.
- Placeholder scan: no unresolved placeholders are present.
- Risk: Ink dependency download requires network during implementation.
