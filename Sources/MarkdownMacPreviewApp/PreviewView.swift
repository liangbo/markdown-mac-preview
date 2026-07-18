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

        context.coordinator.lastHTML = html
        context.coordinator.lastBaseURL = baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastHTML: String?
        var lastBaseURL: URL?
    }
}
