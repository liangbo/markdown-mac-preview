import MarkdownMacPreviewCore
import SwiftUI
import WebKit

struct PreviewView: View {
    let content: MarkdownPreviewContent
    let baseURL: URL?

    var body: some View {
        HTMLPreviewWebView(html: content.html, baseURL: baseURL)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct HTMLPreviewWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    private let fileStore = PreviewHTMLFileStore()

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html || context.coordinator.lastBaseURL != baseURL else {
            return
        }

        do {
            let request = try fileStore.write(html: html, baseURL: baseURL)
            context.coordinator.lastHTML = html
            context.coordinator.lastBaseURL = baseURL
            webView.loadFileURL(request.fileURL, allowingReadAccessTo: request.readAccessURL)
        } catch {
            context.coordinator.lastHTML = html
            context.coordinator.lastBaseURL = baseURL
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastHTML: String?
        var lastBaseURL: URL?
    }
}

struct PreviewHTMLFileStore {
    struct LoadRequest {
        let fileURL: URL
        let readAccessURL: URL
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func write(html: String, baseURL: URL?) throws -> LoadRequest {
        let parentDirectory = baseURL?.standardizedFileURL
        let previewDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("mdPreview", isDirectory: true)
        let fileURL = previewDirectory.appendingPathComponent("preview.html")
        let previewHTML = parentDirectory.map {
            embeddingLocalImages(in: html, relativeTo: $0)
        } ?? html

        try fileManager.createDirectory(at: previewDirectory, withIntermediateDirectories: true)
        try previewHTML.write(to: fileURL, atomically: true, encoding: .utf8)

        return LoadRequest(
            fileURL: fileURL,
            readAccessURL: previewDirectory
        )
    }

    private func embeddingLocalImages(in html: String, relativeTo baseURL: URL) -> String {
        let pattern = #"(?i)<img\b[^>]*\bsrc\s*=\s*(["'])(.*?)\1[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return html
        }

        var updatedHTML = html
        let fullRange = NSRange(updatedHTML.startIndex..<updatedHTML.endIndex, in: updatedHTML)
        let matches = regex.matches(in: updatedHTML, range: fullRange)

        for match in matches.reversed() {
            guard let sourceRange = Range(match.range(at: 2), in: updatedHTML),
                  let tagRange = Range(match.range(at: 0), in: updatedHTML) else {
                continue
            }

            let source = String(updatedHTML[sourceRange])
            guard let dataURL = localImageDataURL(for: source, relativeTo: baseURL) else {
                continue
            }

            let tag = String(updatedHTML[tagRange])
            let sourceNSRange = NSRange(sourceRange, in: updatedHTML)
            let tagNSRange = NSRange(tagRange, in: updatedHTML)
            let relativeSourceRange = NSRange(
                location: sourceNSRange.location - tagNSRange.location,
                length: sourceNSRange.length
            )
            let rewrittenTag = (tag as NSString).replacingCharacters(
                in: relativeSourceRange,
                with: dataURL
            )
            updatedHTML.replaceSubrange(tagRange, with: rewrittenTag)
        }

        return updatedHTML
    }

    private func localImageDataURL(for source: String, relativeTo baseURL: URL) -> String? {
        guard !source.isEmpty,
              !source.hasPrefix("#"),
              !source.hasCaseInsensitivePrefix("http://"),
              !source.hasCaseInsensitivePrefix("https://"),
              !source.hasCaseInsensitivePrefix("data:") else {
            return nil
        }

        let imageURL: URL
        if source.hasCaseInsensitivePrefix("file://"),
           let fileURL = URL(string: source),
           fileURL.isFileURL {
            imageURL = fileURL
        } else if source.hasPrefix("/") {
            imageURL = URL(fileURLWithPath: source)
        } else {
            imageURL = baseURL.appendingPathComponent(source.removingPercentEncoding ?? source)
        }

        guard isFileURL(imageURL, inside: baseURL),
              fileManager.fileExists(atPath: imageURL.path),
              let data = try? Data(contentsOf: imageURL) else {
            return nil
        }

        return "data:\(mimeType(for: imageURL));base64,\(data.base64EncodedString())"
    }

    private func isFileURL(_ fileURL: URL, inside directoryURL: URL) -> Bool {
        let filePath = fileURL.standardizedFileURL.path
        let directoryPath = directoryURL.standardizedFileURL.path
        return filePath == directoryPath || filePath.hasPrefix("\(directoryPath)/")
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "svg":
            return "image/svg+xml"
        case "webp":
            return "image/webp"
        default:
            return "image/png"
        }
    }
}

private extension String {
    func hasCaseInsensitivePrefix(_ prefix: String) -> Bool {
        range(of: prefix, options: [.caseInsensitive, .anchored]) != nil
    }
}
