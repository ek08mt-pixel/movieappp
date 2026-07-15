import Foundation
import WebKit

final class CobePhimService: NSObject {
    static let shared = CobePhimService()
    private let baseURL = "https://cobephim.sbs"
    private var webView: WKWebView?
    private var completion: ((Result<URL, Error>) -> Void)?
    private var searchTitle = ""
    private var searchSeason: Int?
    private var searchEpisode: Int?
    
    func fetchStream(title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        self.completion = completion
        self.searchTitle = title
        self.searchSeason = season
        self.searchEpisode = episode
        
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let urlString = "\(baseURL)/tim-kiem?q=\(query)"
        
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
            self.webView?.navigationDelegate = self
            if let url = URL(string: urlString) {
                self.webView?.load(URLRequest(url: url))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if let comp = self.completion {
                self.completion = nil
                comp(.failure(StreamServiceError.noData))
            }
        }
    }
    
    private func fetchBySlug(_ slug: String) {
        guard let url = URL(string: "\(baseURL)/xem-phim/\(slug)") else {
            completion?(.failure(StreamServiceError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let comp = self.completion else { return }
            self.completion = nil
            
            if let error = error { comp(.failure(error)); return }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                comp(.failure(StreamServiceError.noData)); return
            }
            
            if let range = html.range(of: "\"link\":\""),
               let end = html[range.upperBound...].firstIndex(of: "\"") {
                var link = String(html[range.upperBound..<end])
                link = link.replacingOccurrences(of: "\\/", with: "/")
                if let streamURL = URL(string: link) {
                    comp(.success(streamURL))
                    return
                }
            }
            comp(.failure(StreamServiceError.noStreamURL))
        }.resume()
    }
}

extension CobePhimService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            webView.evaluateJavaScript("document.querySelector('a[href*=\"/phim/\"]')?.getAttribute(\"href\")") { result, _ in
                if let href = result as? String, href.contains("/phim/") {
                    let slug = href.components(separatedBy: "/phim/").last ?? ""
                    self.webView = nil
                    self.fetchBySlug(slug)
                } else {
                    self.webView = nil
                    self.completion?(.failure(StreamServiceError.noMatchFound(id: self.searchTitle)))
                }
            }
        }
    }
}