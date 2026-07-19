import Foundation
import WebKit

// MARK: - Regex Extractor
class NguonCExtractor {
    private static let regexPattern = #"(?:file|src)\s*:\s*["']([^"']*\.m3u8[^"']*)["']"#
    
    static func extractStreamURL(from embedURL: URL) async throws -> URL {
        var request = URLRequest(url: embedURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue(embedURL.absoluteString, forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else { throw NguonCError.invalidHTML }
        
        guard let streamPath = try findM3U8(in: html) else { throw NguonCError.streamURLNotFound }
        
        if streamPath.hasPrefix("http") { return URL(string: streamPath)! }
        else if streamPath.hasPrefix("//") { return URL(string: "https:" + streamPath)! }
        else if streamPath.hasPrefix("/") {
            var components = URLComponents(url: embedURL, resolvingAgainstBaseURL: false)!
            components.path = streamPath
            return components.url!
        } else {
            return URL(string: streamPath, relativeTo: embedURL)!.absoluteURL
        }
    }
    
    private static func findM3U8(in html: String) throws -> String? {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let swiftRange = Range(match.range(at: 1), in: html) {
            return String(html[swiftRange])
        }
        return nil
    }
}

// MARK: - WebView Extractor (fallback)
class StreamExtractorWebView: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var completion: ((URL?) -> Void)?
    
    func extract(from embedURL: URL, completion: @escaping (URL?) -> Void) {
        self.completion = completion
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "streamExtractor")
        
        let script = """
        function getStreamURL() {
            if (typeof jwplayer !== 'undefined' && jwplayer().getPlaylist) {
                let playlist = jwplayer().getPlaylist();
                if (playlist && playlist[0]) return playlist[0].file;
            }
            let scripts = document.getElementsByTagName('script');
            for (let s of scripts) {
                let match = s.textContent.match(/(?:file|src)\\s*:\\s*["']([^"']*\\.m3u8[^"']*)["']/i);
                if (match) return match[1];
            }
            return null;
        }
        window.webkit.messageHandlers.streamExtractor.postMessage(getStreamURL());
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: embedURL))
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "streamExtractor", let urlString = message.body as? String, !urlString.isEmpty {
            completion?(URL(string: urlString))
        } else { completion?(nil) }
        webView.stopLoading(); webView = nil
    }
}

enum NguonCError: Error {
    case invalidHTML
    case streamURLNotFound
}