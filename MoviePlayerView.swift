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
                    CustomWebView(urlString: "https://vidsrc.to/embed/movie/\(imdbId)")
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

struct CustomWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        config.preferences = prefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            request.setValue("https://vidsrc.to", forHTTPHeaderField: "Referer")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}