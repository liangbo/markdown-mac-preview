# mdPreview WebView HTML Preview Design

## Goal

Replace the current `AttributedString` preview with a real HTML preview pipeline so Markdown is rendered like a local document reader, close to Typora-style reading, inside the native macOS app.

## Problem

The current preview path is:

`Markdown -> AttributedString(markdown:) -> SwiftUI Text`

That path is not an HTML renderer. It cannot faithfully render Markdown that contains HTML tags, tables, richer block layout, or CSS-like document styling. The previous HTML-tag replacement patch improved a narrow symptom, but it is not the right architecture for real Markdown preview.

## Chosen Direction

Use a mature Markdown-to-HTML library plus an embedded `WKWebView`:

`Markdown -> HTML -> Typora-style local CSS -> WKWebView`

The app remains a local native macOS app. It does not open an external browser. `WKWebView` is used only as the preview surface inside the app window.

## Markdown Engine

Use Ink as the first Markdown-to-HTML engine because it is lightweight, Swift Package friendly, and simple to integrate. This keeps the first real HTML preview iteration small and maintainable.

If future documents require broader GitHub Flavored Markdown compatibility, the renderer boundary should allow swapping Ink for a cmark-gfm based renderer later without rewriting the WebView preview UI.

## Preview UI

`PreviewView` becomes a SwiftUI wrapper around `WKWebView`.

The WebView loads generated HTML using `loadHTMLString(_:baseURL:)`. The HTML document includes:

- UTF-8 meta tag.
- A local Typora-style CSS block.
- A constrained article body for comfortable reading.
- Styling for headings, paragraphs, links, blockquotes, lists, code blocks, tables, horizontal rules, and images.

The visual goal is clean document reading, not a GitHub clone or marketing page.

## Data Model

Replace `MarkdownPreviewContent.attributed` with HTML-oriented content:

- `html`: complete HTML document string ready for WebView.
- `warning`: optional fallback warning.

`MarkdownRenderer.render(_:)` returns `MarkdownPreviewContent(html: warning:)`. It owns Markdown-to-HTML conversion and HTML document wrapping. It should remove the previous regex-based raw HTML replacement logic because raw HTML should be rendered by WebView, not approximated as Markdown.

## Live Preview and Performance

Keep the existing `AppViewModel` preview caching shape, but cache generated HTML instead of `AttributedString`. The cache is invalidated only when the current document content changes, a new document loads, or a save updates the document model.

This avoids repeated Markdown-to-HTML conversion when SwiftUI asks for preview content multiple times during the same UI refresh, which directly addresses slow recent-file selection caused by repeated preview computation.

Editing remains live: the editor updates in-memory Markdown, cache invalidates, and the WebView reloads the newly generated HTML.

## Local Files and Links

Use the Markdown file parent directory as the WebView `baseURL` when available. This allows relative image paths in Markdown such as `./images/example.png` to resolve naturally. Remote links should remain clickable in the WebView if WebKit permits them.

## Error Handling

If Markdown-to-HTML conversion fails, return a safe HTML fallback that displays escaped source text in a readable `<pre>` block and sets a warning. The preview should not crash the app.

## Testing

Add tests that prove the new architecture, not just symptoms:

- Markdown headings and bold text become HTML elements.
- Raw HTML in Markdown is preserved as HTML instead of shown as escaped or stripped text.
- The complete HTML document includes Typora-style CSS and an article container.
- Fallback output escapes unsafe text in `<pre>`.
- AppViewModel preview caching still avoids duplicate rendering for unchanged document content.

Full verification before completion:

- `swift test`
- `swift build`
- `scripts/build-app.sh`
- `plutil -lint build/mdPreview.app/Contents/Info.plist`
- Launch `build/mdPreview.app`
