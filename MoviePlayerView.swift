import SwiftUI
import WebKit
import AVKit

// MARK: - MediaFusion Manager
class MediaFusionManager {
    static let shared = MediaFusionManager()
    private let baseURL = "https://mediafusion.elfhosted.com"
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.httpCookieAcceptPolicy = .always
        return URLSession(configuration: c)
    }()
    
    // Bước 1: Parse Manifest
    func fetchManifest() async throws {
        guard let url = URL(string: "\(baseURL)/manifest.json") else { return }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        print("📋 MediaFusion Manifest: \(String(data: data, encoding: .utf8)?.prefix(500) ?? "")")
    }
    
    // Bước 2: Lấy Stream cho phim lẻ
    func fetchStreams(imdbId: String) async throws -> [MediaFusionStream] {
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        return try await fetchStreams(path: "/stream/movie/\(cleanId).json")
    }
    
    // Bước 2: Lấy Stream cho phim bộ
    func fetchStreams(imdbId: String, season: Int, episode: Int) async throws -> [MediaFusionStream] {
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        return try await fetchStreams(path: "/stream/series/\(cleanId):\(season):\(episode).json")
    }
    
    private func fetchStreams(path: String) async throws -> [MediaFusionStream] {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw StreamError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        req.setValue("https://mediafusion.elfhosted.com/", forHTTPHeaderField: "Referer")
        req.timeoutInterval = 15
        
        print("🌐 MediaFusion: \(url.absoluteString)")
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw StreamError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MediaFusionResponse.self, from: data)
        
        // Bước 3: LỌC - chỉ lấy type 'url' hoặc 'http', bỏ torrent/magnet/infoHash
        let filtered = result.streams?.filter { stream in
            let isTorrent = stream.type == "torrent" || stream.type == "magnet" || stream.infoHash != nil
            let isDirect = stream.type == "url" || stream.type == "http" || stream.url != nil
            return !isTorrent && isDirect
        } ?? []
        
        print("✅ MediaFusion: Tìm thấy \(filtered.count) stream hợp lệ (tổng \(result.streams?.count ?? 0))")
        return filtered
    }
    
    // Bước 4: Resolve URL cuối cùng (.m3u8/.mp4)
    func resolveFinalURL(_ urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        // Nếu đã là link video trực tiếp
        let path = url.absoluteString.lowercased()
        if path.contains(".m3u8") || path.contains(".mp4") { return url }
        
        // Theo dõi redirect
        var current = url
        var maxRedirects = 5
        while maxRedirects > 0 {
            var req = URLRequest(url: current)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            req.httpMethod = "HEAD"
            
            let (_, resp) = try await session.data(for: req)
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
            
            if [301, 302, 307, 308].contains(statusCode),
               let location = (resp as? HTTPURLResponse)?.allHeaderFields["Location"] as? String,
               let redirectURL = URL(string: location, relativeTo: current) {
                current = redirectURL
                maxRedirects -= 1
                if current.absoluteString.lowercased().contains(".m3u8") || current.absoluteString.lowercased().contains(".mp4") {
                    return current
                }
                continue
            }
            break
        }
        return current
    }
    
    // Lấy URL stream đầu tiên hợp lệ
    func getBestStreamURL(imdbId: String) async throws -> URL {
        let streams = try await fetchStreams(imdbId: imdbId)
        guard let firstStream = streams.first, let urlString = firstStream.url else {
            throw StreamError.noStreamAvailable
        }
        return try await resolveFinalURL(urlString)
    }
}

// MARK: - MediaFusion Models
struct MediaFusionResponse: Codable {
    let streams: [MediaFusionStream]?
}

struct MediaFusionStream: Codable {
    let name: String?
    let title: String?
    let url: String?
    let type: String?
    let infoHash: String?
    let behaviorHints: MediaFusionBehaviorHints?
    
    enum CodingKeys: String, CodingKey {
        case name, title, url, type
        case infoHash = "infoHash"
        case behaviorHints = "behaviorHints"
    }
}

struct MediaFusionBehaviorHints: Codable {
    let notWebReady: Bool?
    let bingeGroup: String?
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, httpError(Int)
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .httpError(let c): return "Server lỗi HTTP \(c)"
        }
    }
}

// MARK: - External Player
class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    
    func openInPlayer(_ playerName: String, streamURL: String) {
        guard let encoded = streamURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let scheme: String
        switch playerName {
        case "Infuse": scheme = "infuse://x-callback-url/play?url=\(encoded)"
        case "VLC": scheme = "vlc-x-callback://x-callback-url/stream?url=\(encoded)"
        case "Outplayer": scheme = "outplayer://\(encoded)"
        case "nPlayer": scheme = "nplayer-\(encoded)"
        case "Safari": scheme = streamURL
        case "Copy": UIPasteboard.general.string = streamURL; return
        default: return
        }
        
        if let url = URL(string: scheme) {
            print("🚀 Mở \(playerName): \(scheme.prefix(80))...")
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var selectedSource = 0
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var streamURL: String?
    
    let sources = ["NTL Stream", "MediaFusion", "VidLink", "MultiEmbed"]
    
    var embedURL: String {
        switch selectedSource {
        case 2: return "https://vidlink.pro/movie/\(movieId)"
        case 3: return "https://multiembed.mov/directstream.php?video_id=\(movieId)&tmdb=1"
        default: return ""
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đợi Mew tí...").foregroundColor(.white.opacity(0.7)).font(.headline)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                    HStack(spacing: 8) {
                        Button("Thử lại") { loadSource() }
                            .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)).font(.caption)
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button(sources[i]) { selectedSource = i; loadSource() }
                                .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(Capsule().fill(.white.opacity(0.15))).font(.caption2)
                        }
                    }
                    if let url = streamURL {
                        HStack(spacing: 8) {
                            Button("Mở bằng VLC") { ExternalPlayerManager.shared.openInPlayer("VLC", streamURL: url) }
                                .foregroundColor(.orange).font(.caption2)
                            Button("Mở bằng Infuse") { ExternalPlayerManager.shared.openInPlayer("Infuse", streamURL: url) }
                                .foregroundColor(.orange).font(.caption2)
                            Button("Copy Link") { ExternalPlayerManager.shared.openInPlayer("Copy", streamURL: url) }
                                .foregroundColor(.gray).font(.caption2)
                        }
                    }
                }
            } else if let player = player {
                FullScreenPlayer(player: player).ignoresSafeArea()
                    .onAppear { player.play() }.onDisappear { player.pause() }
            } else {
                FullScreenWebView(urlString: embedURL).ignoresSafeArea()
            }
        }
        .task { loadSource() }
    }
    
    func loadSource() {
        isLoading = true; errorMessage = nil; player = nil; streamURL = nil
        switch selectedSource {
        case 0: loadNTLStream()
        case 1: loadMediaFusion()
        default: isLoading = false
        }
    }
    
    func loadNTLStream() {
        Task {
            do {
                let imdbId = try await fetchIMDbId()
                let ntlURL = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
                var req = URLRequest(url: URL(string: ntlURL)!)
                req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                let (data, _) = try await URLSession.shared.data(for: req)
                struct NTLR: Codable { let streams: [NTLS]? }
                struct NTLS: Codable { let url: String? }
                let res = try JSONDecoder().decode(NTLR.self, from: data)
                if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
                   let videoURL = URL(string: url) {
                    await MainActor.run {
                        self.streamURL = url
                        self.player = AVPlayer(url: videoURL)
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run { self.errorMessage = "NTL không có link"; self.isLoading = false }
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
    
    func loadMediaFusion() {
        Task {
            do {
                let imdbId = try await fetchIMDbId()
                let url = try await MediaFusionManager.shared.getBestStreamURL(imdbId: imdbId)
                await MainActor.run {
                    self.streamURL = url.absoluteString
                    self.player = AVPlayer(url: url)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
    
    func fetchIMDbId() async throws -> String {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
        struct EID: Codable { let imdb_id: String? }
        guard let imdbId = try JSONDecoder().decode(EID.self, from: data).imdb_id else { throw StreamError.noStreamAvailable }
        return imdbId
    }
}

// MARK: - Full Screen Player
struct FullScreenPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true
        c.videoGravity = .resizeAspectFill; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true; return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}

// MARK: - Full Screen WebView
struct FullScreenWebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true; config.mediaTypesRequiringUserActionForPlayback = []
        let pagePrefs = WKWebpagePreferences(); pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black; webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        if let url = URL(string: urlString) {
            var req = URLRequest(url: url)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            webView.load(req)
        }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}