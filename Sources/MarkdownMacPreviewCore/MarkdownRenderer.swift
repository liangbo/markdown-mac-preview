import Foundation
import Ink

public struct MarkdownPreviewContent: Equatable {
    public let html: String
    public let warning: String?

    public init(html: String, warning: String? = nil) {
        self.html = html
        self.warning = warning
    }
}

public enum MarkdownRenderer {
    public static func render(_ markdown: String) -> MarkdownPreviewContent {
        render(markdown, htmlRenderer: { markdown in
            MarkdownParser().html(from: markdown)
        })
    }

    static func render(
        _ markdown: String,
        htmlRenderer: (String) throws -> String
    ) -> MarkdownPreviewContent {
        do {
            return MarkdownPreviewContent(
                html: htmlDocument(body: try htmlRenderer(markdown))
            )
        } catch {
            return MarkdownPreviewContent(
                html: fallbackDocument(for: markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }

    private static func htmlDocument(body: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root { color-scheme: light dark; }
            body.mdpreview-document {
              margin: 0;
              padding: 0;
              background: Canvas;
              color: CanvasText;
              font: 16px/1.68 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
            }
            article {
              box-sizing: border-box;
              max-width: 820px;
              margin: 0 auto;
              padding: 36px 42px 56px;
            }
            h1, h2, h3, h4, h5, h6 {
              line-height: 1.25;
              margin: 1.45em 0 0.6em;
              font-weight: 650;
            }
            h1 { font-size: 2.0em; border-bottom: 1px solid color-mix(in srgb, CanvasText 18%, transparent); padding-bottom: 0.25em; }
            h2 { font-size: 1.55em; border-bottom: 1px solid color-mix(in srgb, CanvasText 12%, transparent); padding-bottom: 0.2em; }
            h3 { font-size: 1.25em; }
            p { margin: 0.72em 0; }
            a { color: LinkText; text-decoration-thickness: 0.08em; text-underline-offset: 0.16em; }
            blockquote {
              margin: 1em 0;
              padding: 0.1em 1em;
              color: color-mix(in srgb, CanvasText 72%, transparent);
              border-left: 4px solid color-mix(in srgb, CanvasText 22%, transparent);
              background: color-mix(in srgb, CanvasText 5%, transparent);
            }
            ul, ol { padding-left: 1.7em; margin: 0.65em 0; }
            li + li { margin-top: 0.2em; }
            code {
              font-family: "SF Mono", Menlo, Monaco, Consolas, monospace;
              font-size: 0.92em;
              background: color-mix(in srgb, CanvasText 8%, transparent);
              border-radius: 4px;
              padding: 0.12em 0.32em;
            }
            pre {
              overflow: auto;
              padding: 14px 16px;
              border-radius: 7px;
              background: color-mix(in srgb, CanvasText 7%, transparent);
            }
            pre code { background: transparent; padding: 0; border-radius: 0; }
            table {
              width: 100%;
              border-collapse: collapse;
              margin: 1em 0;
              display: block;
              overflow-x: auto;
            }
            th, td {
              border: 1px solid color-mix(in srgb, CanvasText 18%, transparent);
              padding: 7px 10px;
            }
            th { background: color-mix(in srgb, CanvasText 6%, transparent); font-weight: 650; }
            hr { border: 0; border-top: 1px solid color-mix(in srgb, CanvasText 16%, transparent); margin: 2em 0; }
            img { max-width: 100%; height: auto; }
          </style>
        </head>
        <body class="mdpreview-document">
          <article>
        \(body)
          </article>
        </body>
        </html>
        """
    }

    private static func fallbackDocument(for markdown: String) -> String {
        htmlDocument(body: "<pre>\(escapeHTML(markdown))</pre>")
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
