import SwiftUI
import WebKit
import AVKit

struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var selectedSource = 0
    @State private var player: AVPlayer?
    @State private var streamURL: String?
    @State private var errorMessage: String?
    
    var sources: [(String, String, Bool)] {
        [
            ("NTL Stream (Direct)", "", true),
            ("Fmovies (USUK)", "https://fmovies.ps/filter?keyword=\(searchQuery)", false),
            ("PhimCN (Vietsub)", "https://phimcn.site/search?keyword=\(searchQuery)", false),
            ("Motphim (Vietsub)", "https://motphimtv.com/tim-kiem?q=\(searchQuery)", false),
            ("VidLink (USUK)", "https://vidlink.pro/movie/\(movieId)", false),
            ("MultiEmbed", "https://multiembed.mov/directstream.php?video_id=\(movieId)&tmdb=1", false),
        ]
    }
    
    var searchQuery: String {
        movieTitle.replacingOccurrences(of: " ", with: "+")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Menu {
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button(sources[i].0) { selectedSource = i; loadSource() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill").font(.system(size: 24)).foregroundColor(.white)
                    }
                }.padding()
                
                if isLoading {
                    ProgressView().tint(.white).padding(.top, 100)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { loadSource() }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    }
                } else if let player = player {
                    CustomVideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() }
                } else {
                    CustomWebView(urlString: sources[selectedSource].1)
                }
            }
        }
        .task { loadNTLStream() }
    }
    
    func loadSource() {
        isLoading = true; errorMessage = nil; player = nil
        if sources[selectedSource].2 {
            loadNTLStream()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isLoading = false }
        }
    }
    
    func loadNTLStream() {
        isLoading = true; errorMessage = nil; player = nil
        Task {
            do {
                let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
                guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
                let (data, _) = try await URLSession.shared.data(from: url)
                struct EID: Codable { let imdb_id: String? }
                let result = try JSONDecoder().decode(EID.self, from: data)
                guard let imdbId = result.imdb_id else { throw StreamError.noStreamAvailable }
                
                let ntlURL = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
                guard let ntlUrl = URL(string: ntlURL) else { throw StreamError.invalidURL }
                var req = URLRequest(url: ntlUrl)
                req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                let (ntlData, _) = try await URLSession.shared.data(for: req)
                struct NTLResponse: Codable { let streams: [NTLStream]? }
                struct NTLStream: Codable { let url: String? }
                let ntlRes = try JSONDecoder().decode(NTLResponse.self, from: ntlData)
                
                if let streamURL = ntlRes.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
                   let videoURL = URL(string: streamURL) {
                    await MainActor.run {
                        let headers: [String: String] = ["User-Agent": "Mozilla/5.0", "Referer": "https://tnluannguyen-ntl-stream.hf.space/"]
                        let asset = AVURLAsset(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
                        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run { self.errorMessage = "NTL không có link stream"; self.isLoading = false }
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
}

enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        }
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true
        c.videoGravity = .resizeAspect; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true; return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}

struct CustomWebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black; webView.isOpaque = false
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        if let url = URL(string: urlString) { webView.load(URLRequest(url: url)) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}