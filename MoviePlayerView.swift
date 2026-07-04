import SwiftUI
import AVKit
import MediaPlayer

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, httpError(Int), parseError(String), networkError(String)
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .httpError(let c): return "Server lỗi HTTP \(c)"
        case .parseError(let m): return "Lỗi parse: \(m)"
        case .networkError(let m): return "Lỗi mạng: \(m)"
        }
    }
}

// MARK: - MovieSource
enum MovieSource: String, CaseIterable {
    case ophim = "OPhim"
    case twoembed = "2Embed"
    case vidsrc = "VidSrc"
    case nguonc = "NguonC"
    case kkphim = "KKPhim"
    case ntl = "NTL Stream"
}

// MARK: - Network Manager
class NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default; c.httpCookieAcceptPolicy = .always; return URLSession(configuration: c)
    }()
    
    func fetchJSON(from urlString: String, source: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let host = url.host { req.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }
        req.timeoutInterval = 15
        let (data, r) = try await session.data(for: req)
        guard let hr = r as? HTTPURLResponse, (200...299).contains(hr.statusCode) else { throw StreamError.httpError((r as? HTTPURLResponse)?.statusCode ?? 0) }
        return data
    }
    
    func resolveURL(_ urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        let path = url.absoluteString.lowercased()
        if path.contains(".m3u8") || path.contains(".mp4") { return url }
        var current = url; var max = 5
        while max > 0 {
            var req = URLRequest(url: current)
            req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            req.httpMethod = "HEAD"
            let (_, r) = try await session.data(for: req)
            if [301,302,307,308].contains((r as? HTTPURLResponse)?.statusCode ?? 0),
               let loc = (r as? HTTPURLResponse)?.allHeaderFields["Location"] as? String,
               let ru = URL(string: loc, relativeTo: current) {
                current = ru; max -= 1
                if current.absoluteString.lowercased().contains(".m3u8") || current.absoluteString.lowercased().contains(".mp4") { return current }
                continue
            }
            break
        }
        return current
    }
}

// MARK: - Models
struct OPhimMovie: Codable { let slug: String? }
struct OPhimListResponse: Codable { let items: [OPhimMovie]?; let data: OPhimListData? }
struct OPhimListData: Codable { let items: [OPhimMovie]? }
struct OPhimEpisode: Codable { let link_embed: String?; let link_m3u8: String? }
struct OPhimDetailResponse: Codable { let episodes: [OPhimEpisode]? }
struct NguoncItem: Codable { let name: String?; let slug: String? }
struct NguoncList: Codable { let items: [NguoncItem]? }
struct NguoncEp: Codable { let link_embed: String?; let link_m3u8: String? }
struct NguoncDetail: Codable { let episodes: [NguoncEp]? }
struct KKPhimMovie: Codable { let slug: String? }
struct KKPhimSource: Codable { let url: String? }
struct KKPhimEpisode: Codable { let sources: [KKPhimSource]? }
struct KKPhimResponse: Codable { let episodes: [KKPhimEpisode]? }
struct NTLStreamItem: Codable { let url: String? }
struct NTLStreamResponse: Codable { let streams: [NTLStreamItem]? }

// MARK: - Source Manager
class SourceManager {
    static let shared = SourceManager()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> URL {
        switch source {
        case .ophim: return try await fetchOPhim(imdbId)
        case .twoembed: return try await fetch2Embed(imdbId)
        case .vidsrc: return try await fetchVidSrc(imdbId)
        case .nguonc: return try await fetchNguonc(imdbId)
        case .kkphim: return try await fetchKKPhim(imdbId)
        case .ntl: return try await fetchNTLStream(imdbId)
        }
    }
    
    func tryAllSources(imdbId: String) async throws -> URL {
        for source in MovieSource.allCases {
            print("🎯 THỬ: \(source.rawValue)...")
            if let url = try? await getStreamURL(for: source, imdbId: imdbId) {
                print("✅ THÀNH CÔNG: \(source.rawValue)")
                return url
            }
            print("❌ THẤT BẠI: \(source.rawValue)")
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchOPhim(_ imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://ophim1.com/tim-kiem?keyword=\(imdbId)", source: "OPhim")
        var slug: String?
        if let list = try? JSONDecoder().decode(OPhimListResponse.self, from: data) { slug = list.items?.first?.slug ?? list.data?.items?.first?.slug }
        else if let items = try? JSONDecoder().decode([OPhimMovie].self, from: data) { slug = items.first?.slug }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        let d = try await NetworkManager.shared.fetchJSON(from: "https://ophim1.com/phim/\(slug)", source: "OPhim")
        let detail = try JSONDecoder().decode(OPhimDetailResponse.self, from: d)
        if let eps = detail.episodes { for ep in eps {
            if let m3u8 = ep.link_m3u8 { return try await NetworkManager.shared.resolveURL(m3u8) }
            if let em = ep.link_embed { return try await NetworkManager.shared.resolveURL(em) }
        }}
        throw StreamError.noStreamAvailable
    }
    
    private func fetch2Embed(_ imdbId: String) async throws -> URL {
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        return try await NetworkManager.shared.resolveURL("https://www.2embed.cc/embed/\(cleanId)")
    }
    
    private func fetchVidSrc(_ imdbId: String) async throws -> URL {
        return try await NetworkManager.shared.resolveURL("https://vidsrc.to/embed/movie/\(imdbId)")
    }
    
    private func fetchNguonc(_ imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://phim.nguonc.com/api/films/phim-moi-cap-nhat", source: "NguonC")
        let list = try JSONDecoder().decode(NguoncList.self, from: data)
        guard let slug = list.items?.first(where: { $0.name?.lowercased().contains(imdbId.lowercased()) ?? false })?.slug else { throw StreamError.noStreamAvailable }
        let d = try await NetworkManager.shared.fetchJSON(from: "https://phim.nguonc.com/api/film/\(slug)", source: "NguonC")
        let detail = try JSONDecoder().decode(NguoncDetail.self, from: d)
        if let eps = detail.episodes { for ep in eps {
            if let m3u8 = ep.link_m3u8 { return try await NetworkManager.shared.resolveURL(m3u8) }
            if let em = ep.link_embed { return try await NetworkManager.shared.resolveURL(em) }
        }}
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhim(_ imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)", source: "KKPhim")
        var slug: String?
        if let r = try? JSONDecoder().decode([KKPhimMovie].self, from: data) { slug = r.first?.slug }
        else if let r = try? JSONDecoder().decode(KKPhimMovie.self, from: data) { slug = r.slug }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        let d = try await NetworkManager.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/movie/\(slug)", source: "KKPhim")
        let ep = try JSONDecoder().decode(KKPhimResponse.self, from: d)
        if let url = ep.episodes?.first?.sources?.first?.url { return try await NetworkManager.shared.resolveURL(url) }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNTLStream(_ imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json", source: "NTL")
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url { return try await NetworkManager.shared.resolveURL(url) }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - External Player Manager
class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    struct PlayerApp {
        let name: String
        func buildURL(streamURL: String) -> URL? {
            guard let encoded = streamURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            switch name {
            case "Infuse": return URL(string: "infuse://x-callback-url/play?url=\(encoded)")
            case "VLC": return URL(string: "vlc-x-callback://x-callback-url/stream?url=\(encoded)")
            case "Safari": return URL(string: streamURL)
            case "Copy Link": UIPasteboard.general.string = streamURL; return nil
            default: return nil
            }
        }
    }
    let players: [PlayerApp] = [PlayerApp(name: "Infuse"), PlayerApp(name: "VLC"), PlayerApp(name: "Safari"), PlayerApp(name: "Copy Link")]
    func openInPlayer(_ player: PlayerApp, streamURL: String) {
        guard let url = player.buildURL(streamURL: streamURL) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Player
class PlayerDebugger: NSObject {
    static let shared = PlayerDebugger()
    static func debugPlayer(url: URL) -> AVPlayer {
        let headers: [String: String] = ["User-Agent": "Mozilla/5.0", "Referer": "https://ophim1.com/"]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        item.addObserver(shared, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
        return AVPlayer(playerItem: item)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status), let item = object as? AVPlayerItem {
            switch item.status {
            case .readyToPlay: print("✅ READY")
            case .failed: print("❌ FAILED: \(item.error?.localizedDescription ?? "")")
            default: break
            }
        }
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true; @State private var errorMessage: String?
    @State private var player: AVPlayer?; @State private var streamURL: String?
    @State private var currentSource: MovieSource?
    @State private var showExternalPlayerMenu = false
    @State private var showSourcePicker = false
    private let tmdbKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                VStack(spacing: 20) { ProgressView().tint(.white).scaleEffect(1.5); Text("Đang tìm nguồn phim...").foregroundColor(.gray).font(.caption) }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                    HStack(spacing: 12) {
                        Button { Task { await loadStream() } } label: { Label("Thử lại", systemImage: "arrow.triangle.2.circlepath").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)).font(.caption) }
                        Button { showSourcePicker = true } label: { Label("Chọn nguồn", systemImage: "list.bullet").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.white.opacity(0.15))).font(.caption) }
                        if streamURL != nil { Button { showExternalPlayerMenu = true } label: { Label("App khác", systemImage: "arrow.up.forward.app").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.white.opacity(0.15))).font(.caption) } }
                    }
                }
            } else if let player = player {
                CustomVideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() }
                    .overlay(alignment: .topLeading) {
                        if let source = currentSource {
                            Text(source.rawValue).font(.caption2).foregroundColor(.white.opacity(0.6)).padding(6).background(Capsule().fill(.ultraThinMaterial)).padding(.top, 50).padding(.leading, 20)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Menu {
                                ForEach(MovieSource.allCases, id: \.self) { s in Button(s.rawValue) { Task { await loadFromSource(s) } } }
                            } label: { Image(systemName: "list.bullet").font(.system(size: 18)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial)) }
                            
                            Menu { ForEach(ExternalPlayerManager.shared.players, id: \.name) { p in Button(p.name) { if let url = streamURL { ExternalPlayerManager.shared.openInPlayer(p, streamURL: url) } } } }
                            label: { Image(systemName: "ellipsis.circle.fill").font(.system(size: 24)).foregroundColor(.white).padding() }
                        }
                    }
            }
        }
        .task { await loadStream() }
        .actionSheet(isPresented: $showExternalPlayerMenu) {
            ActionSheet(title: Text("Chọn trình phát"), buttons: ExternalPlayerManager.shared.players.map { p in .default(Text(p.name)) { if let url = streamURL { ExternalPlayerManager.shared.openInPlayer(p, streamURL: url) } } } + [.cancel()])
        }
        .actionSheet(isPresented: $showSourcePicker) {
            ActionSheet(title: Text("Chọn nguồn phim"), buttons: MovieSource.allCases.map { s in .default(Text(s.rawValue)) { Task { await loadFromSource(s) } } } + [.cancel()])
        }
    }
    
    private func loadStream() async { await loadFromSource(nil) }
    
    private func loadFromSource(_ source: MovieSource?) async {
        isLoading = true; errorMessage = nil; player = nil
        do {
            let imdbId = try await fetchIMDbId()
            let url: URL
            if let source = source {
                url = try await SourceManager.shared.getStreamURL(for: source, imdbId: imdbId)
                currentSource = source
            } else {
                url = try await SourceManager.shared.tryAllSources(imdbId: imdbId)
            }
            await MainActor.run { self.streamURL = url.absoluteString; self.player = PlayerDebugger.debugPlayer(url: url); self.isLoading = false }
        } catch { await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false } }
    }
    
    private func fetchIMDbId() async throws -> String {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(tmdbKey)", source: "TMDB")
        struct EID: Codable { let imdb_id: String? }
        let result = try JSONDecoder().decode(EID.self, from: data)
        guard let imdbId = result.imdb_id else { throw StreamError.noStreamAvailable }
        return imdbId
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