import Foundation
import WebKit
import CryptoKit

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
    
    // MARK: - NEW: Extract m3u8 from NguonC embed
    static func extractM3U8FromNguonC(embedURL: String) async -> String? {
        guard let url = URL(string: embedURL) else { return nil }
        
        do {
            // 1. Tải HTML embed
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // 2. Tìm data-obf
            guard let obfRange = html.range(of: "data-obf=\"([^\"]+)\"", options: .regularExpression) else { return nil }
            let obf = String(html[obfRange])
                .replacingOccurrences(of: "data-obf=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
            
            // 3. Giải mã base64 lần 1
            guard let obfData = Data(base64Encoded: obf),
                  let obfJSON = try? JSONSerialization.jsonObject(with: obfData) as? [String: Any],
                  let sUb = obfJSON["sUb"] as? String else { return nil }
            
            // 4. Giải mã base64 lần 2
            guard let sUbData = Data(base64Encoded: sUb),
                  let sUbJSON = try? JSONSerialization.jsonObject(with: sUbData) as? [String: Any],
                  let a = sUbJSON["a"] as? String else { return nil }
            
            // 5. Tạo streamURL
            let baseHost = "https://embed13.streamc.xyz"
            let streamPath = "/\(a)"
            let streamURLString = baseHost + streamPath
            
            guard let streamURL = URL(string: streamURLString) else { return nil }
            
            // 6. Fetch streamURL
            var streamRequest = URLRequest(url: streamURL)
            streamRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            streamRequest.setValue(embedURL, forHTTPHeaderField: "Referer")
            
            let (streamData, _) = try await URLSession.shared.data(for: streamRequest)
            guard let m3u8Content = String(data: streamData, encoding: .utf8) else { return nil }
            
            // 7. Kiểm tra AES encryption
            if m3u8Content.contains("#EXT-X-KEY:METHOD=AES") {
                // Cần giải mã AES - phức tạp hơn
                print("NguonC: Stream bị mã hóa AES, cần giải mã")
                return nil
            }
            
            // 8. Nếu không mã hóa, trả về URL stream trực tiếp
            return streamURLString
            
        } catch {
            print("NguonC extract error: \(error)")
            return nil
        }
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