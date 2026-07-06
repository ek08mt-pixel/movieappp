import SwiftUI
import WebKit
import AVFoundation

class EmbedExtractor: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var completion: ((URL?) -> Void)?
    private var foundURL: URL?
    private var timer: Timer?
    
    func extractM3U8(from embedURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { url in
                if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: StreamError.noStreamAvailable)
                }
            }
            
            DispatchQueue.main.async {
                let config = WKWebViewConfiguration()
                config.allowsInlineMediaPlayback = true
                
                let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
                wv.isHidden = true
                wv.navigationDelegate = self
                self.webView = wv
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.view.addSubview(wv)
                }
                
                wv.load(URLRequest(url: embedURL))
                
                self.timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { _ in
                    wv.evaluateJavaScript("""
                        (function() {
                            var video = document.querySelector('video');
                            if (video && video.src) return video.src;
                            var source = document.querySelector('source');
                            if (source && source.src) return source.src;
                            var iframe = document.querySelector('iframe');
                            if (iframe && iframe.src) return iframe.src;
                            return '';
                        })()
                    """) { result, _ in
                        if let urlStr = result as? String, !urlStr.isEmpty,
                           let url = URL(string: urlStr),
                           (urlStr.contains(".m3u8") || urlStr.contains(".mp4") || urlStr.contains(".ts")) {
                            self.foundURL = url
                        }
                        self.cleanup()
                        self.completion?(self.foundURL)
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString,
           url.contains(".m3u8") || url.contains(".mp4") {
            foundURL = navigationAction.request.url
            cleanup()
            completion?(foundURL)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("""
            (function() {
                var video = document.querySelector('video');
                if (video && video.src) return video.src;
                var source = document.querySelector('source');
                if (source && source.src) return source.src;
                return '';
            })()
        """) { result, _ in
            if let urlStr = result as? String, !urlStr.isEmpty,
               let url = URL(string: urlStr),
               (urlStr.contains(".m3u8") || urlStr.contains(".mp4")) {
                self.foundURL = url
                self.cleanup()
                self.completion?(url)
            }
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
    }
}