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

// MARK: - Player WebView
struct PlayerWebView: UIViewRepresentable {
    let imdbId: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // Cấu hình
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        
        // User-Agent giả lập iPhone thật
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        // Load URL
        let urlString = "https://vidsrc.to/embed/movie/\(imdbId)"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            request.setValue("https://vidsrc.to", forHTTPHeaderField: "Referer")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            request.timeoutInterval = 30
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ LOAD THÀNH CÔNG: \(webView.url?.absoluteString ?? "")")
            
            // Inject script để tự động bấm Play và debug
            let debugScript = """
            // Debug: In toàn bộ HTML ra console
            console.log('=== DEBUG HTML START ===');
            console.log(document.body.innerHTML.substring(0, 2000));
            console.log('=== DEBUG HTML END ===');
            
            // Tìm và click nút Play
            setTimeout(function() {
                var playButtons = document.querySelectorAll('button, .play-button, .plyr__control--overlaid, [data-plyr="play"], video');
                console.log('Tìm thấy ' + playButtons.length + ' phần tử video/play');
                
                for (var i = 0; i < playButtons.length; i++) {
                    var el = playButtons[i];
                    console.log('Phần tử ' + i + ': ' + el.tagName + ' - Class: ' + el.className);
                    
                    if (el.tagName === 'VIDEO') {
                        el.play().then(function() { console.log('Video đã play'); }).catch(function(e) { console.log('Lỗi play: ' + e); });
                        el.muted = false;
                    } else {
                        el.click();
                        console.log('Đã click: ' + el.className);
                    }
                }
            }, 2000);
            
            // Thử lại sau 5 giây
            setTimeout(function() {
                var videos = document.querySelectorAll('video');
                for (var i = 0; i < videos.length; i++) {
                    videos[i].play().catch(function(e) { console.log('Retry play error: ' + e); });
                }
            }, 5000);
            """
            
            webView.evaluateJavaScript(debugScript) { result, error in
                if let error = error {
                    print("❌ LỖI JS: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ LỖI PROVISIONAL: \(error.localizedDescription)")
            let nsError = error as NSError
            print("❌ Domain: \(nsError.domain) - Code: \(nsError.code)")
            print("❌ URL thất bại: \(nsError.userInfo[NSURLErrorFailingURLStringErrorKey] ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ LỖI NAVIGATION: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 ĐANG LOAD: \(webView.url?.absoluteString ?? "")")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("🔗 REQUEST: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}