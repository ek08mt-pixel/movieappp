import Foundation
import WebKit

final class CobePhimService: NSObject {
    static let shared = CobePhimService()
    private let baseURL = "https://cobephim.sbs"
    private var webView: WKWebView?
    private var completion: ((Result<URL, Error>) -> Void)?
    
    func fetchStream(title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        self.completion = completion
        
        let searchQuery = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let urlString = "\(baseURL)/tim-kiem?q=\(searchQuery)"
        
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            self.webView = WKWebView(frame: .zero, configuration: config)
            self.webView?.navigationDelegate = self
            self.webView?.load(URLRequest(url: URL(string: urlString)!))
        }
        
        // Timeout sau 10 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if let comp = self.completion {
                self.completion = nil
                comp(.failure(StreamServiceError.noData))
            }
        }
    }
}

extension CobePhimService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Đợi JS render xong rồi lấy HTML
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
                guard let self = self, let comp = self.completion else { return }
                self.completion = nil
                
                if let html = result as? String {
                    // Parse HTML tìm link stream giống như trước
                    if let range = html.range(of: "\"link\":\""),
                       let end = html[range.upperBound...].firstIndex(of: "\"") {
                        var link = String(html[range.upperBound..<end])
                        link = link.replacingOccurrences(of: "\\/", with: "/")
                        if let url = URL(string: link) {
                            comp(.success(url))
                            return
                        }
                    }
                }
                comp(.failure(StreamServiceError.noStreamURL))
            }
            self.webView = nil
        }
    }
}