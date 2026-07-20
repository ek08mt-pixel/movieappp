import Foundation
import WebKit

class WebtorIOExtractor: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var completion: ((URL?) -> Void)?
    private var foundURL: URL?
    private var timer: Timer?
    private var retryCount = 0
    private let maxRetries = 5
    private var hash: String = ""
    private var serviceIndex = 0
    
    private let services = [
        "https://webtor.io/show/",
        "https://btor2.xyz/torrent/",
        "https://webtor.cc/player?hash="
    ]
    
    func extractStream(from magnetLink: String) async throws -> URL {
        guard let infoHash = infoHash(from: magnetLink) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Magnet link không hợp lệ"])
        }
        self.hash = infoHash
        
        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { url in
                if let url = url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: StreamError.noStreamAvailable) }
            }
            
            DispatchQueue.main.async {
                self.serviceIndex = 0
                self.tryNextService()
            }
        }
    }
    
    private func tryNextService() {
        guard serviceIndex < services.count else {
            cleanup()
            completion?(nil)
            return
        }
        
        let urlString = services[serviceIndex] + hash
        guard let url = URL(string: urlString) else {
            serviceIndex += 1
            tryNextService()
            return
        }
        
        retryCount = 0
        loadWebView(url: url)
    }
    
    private func loadWebView(url: URL) {
        cleanup()
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
        wv.isHidden = true
        wv.navigationDelegate = self
        self.webView = wv
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.view.addSubview(wv)
        }
        
        wv.load(URLRequest(url: url))
        
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            self?.tryExtractVideo()
        }
    }
    
    private func tryExtractVideo() {
        let js = """
        (function() {
            var v = document.querySelector('video');
            if (v && v.src && (v.src.includes('.m3u8') || v.src.includes('.mp4') || v.src.includes('blob:') || v.src.includes('http'))) return v.src;
            var sources = document.querySelectorAll('source');
            for (var i = 0; i < sources.length; i++) {
                if (sources[i].src && (sources[i].src.includes('.m3u8') || sources[i].src.includes('.mp4'))) {
                    return sources[i].src;
                }
            }
            var iframes = document.querySelectorAll('iframe');
            for (var j = 0; j < iframes.length; j++) {
                if (iframes[j].src && iframes[j].src.includes('http')) return iframes[j].src;
            }
            return '';
        })();
        """
        
        webView?.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self = self else { return }
            if let urlStr = result as? String, !urlStr.isEmpty,
               let url = URL(string: urlStr) {
                self.foundURL = url
                self.cleanup()
                self.completion?(url)
            } else if self.retryCount < self.maxRetries {
                self.retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.tryExtractVideo()
                }
            } else {
                // Thử service tiếp theo
                self.serviceIndex += 1
                self.tryNextService()
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString,
           (url.contains(".m3u8") || url.contains(".mp4")) {
            foundURL = navigationAction.request.url
            cleanup()
            completion?(foundURL)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        serviceIndex += 1
        tryNextService()
    }
    
    private func infoHash(from magnet: String) -> String? {
        guard let components = URLComponents(string: magnet),
              let queryItems = components.queryItems else { return nil }
        for item in queryItems {
            if item.name == "xt", let value = item.value {
                if value.hasPrefix("urn:btih:") {
                    return String(value.dropFirst(9)).lowercased()
                }
            }
        }
        return nil
    }
    
    private func cleanup() {
        timer?.invalidate(); timer = nil
        webView?.stopLoading(); webView?.removeFromSuperview(); webView = nil
    }
}