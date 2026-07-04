import SwiftUI
import WebKit

struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var imdbId: String?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                }.padding()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang tải phim...").foregroundColor(.gray).font(.caption)
                    }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await fetchIMDbId() } }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }.frame(maxHeight: .infinity)
                } else if let imdbId = imdbId {
                    PlayerWebView(imdbId: imdbId)
                }
            }
        }
        .task { await fetchIMDbId() }
    }
    
    private func fetchIMDbId() async {
        isLoading = true; errorMessage = nil
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { errorMessage = "URL không hợp lệ"; isLoading = false; return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Không thể kết nối đến TMDB"; isLoading = false; return
            }
            struct ExternalIDs: Codable { let imdb_id: String? }
            let result = try JSONDecoder().decode(ExternalIDs.self, from: data)
            await MainActor.run {
                if let imdbId = result.imdb_id { self.imdbId = imdbId }
                else { errorMessage = "Không tìm thấy IMDb ID" }
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = "Lỗi: \(error.localizedDescription)"; isLoading = false }
        }
    }
}

// MARK: - Player WebView với đầy đủ cấu hình
struct PlayerWebView: UIViewRepresentable {
    let imdbId: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // Cấu hình WKWebViewConfiguration
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Bật JavaScript
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        // Tạo WebView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        
        // User-Agent giả lập Chrome trên MacOS để tránh bị chặn
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        // Load URL
        let urlString = "https://vidsrc.to/embed/movie/\(imdbId)"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.setValue("https://vidsrc.to", forHTTPHeaderField: "Referer")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            request.timeoutInterval = 30
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    // MARK: - Coordinator để debug lỗi
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ LỖI LOAD WEBVIEW: \(error.localizedDescription)")
            print("❌ Chi tiết: \(error)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ LỖI NAVIGATION: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ LOAD THÀNH CÔNG")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 ĐANG BẮT ĐẦU LOAD...")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("🔗 URL: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            decisionHandler(.allow)
        }
    }
}