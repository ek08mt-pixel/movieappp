import WebKit

class PhimFunExtractor: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let shared = PhimFunExtractor()
    private var webView: WKWebView?
    private var completion: ((String?) -> Void)?
    
    func extractStreamURL(embedURL: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.completion = completion
            
            guard let url = URL(string: embedURL) else {
                completion(nil)
                return
            }
            
            let config = WKWebViewConfiguration()
            config.userContentController.add(self, name: "phimFunExtractor")
            
            let script = """
            setTimeout(function() {
                var iframe = document.getElementById('embedIframe') || document.getElementById('iframeStream');
                if (iframe && iframe.src && iframe.src !== '') {
                    window.webkit.messageHandlers.phimFunExtractor.postMessage(iframe.src);
                } else {
                    window.webkit.messageHandlers.phimFunExtractor.postMessage('null');
                }
            }, 8000);
            """
            let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            config.userContentController.addUserScript(userScript)
            
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            self.webView = webView
            webView.load(URLRequest(url: url))
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "phimFunExtractor" {
            let src = message.body as? String ?? ""
            if src != "null" && !src.isEmpty {
                completion?(src)
            } else {
                completion?(nil)
            }
            webView?.stopLoading()
            webView = nil
            completion = nil
        }
    }
}