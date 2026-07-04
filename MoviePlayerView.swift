import SwiftUI
import AVKit
import MediaPlayer

// MARK: - MovieSource
enum MovieSource: String, CaseIterable {
    case nguonc = "Nguồn C"
    case kkphim = "KKPhim"
    case ntlStream = "NTL Stream"
    case animeKitsu = "Anime Kitsu"
    case stravo = "Stravo"
    case mediafusion = "MediaFusion"
    case torrentio = "Torrentio"
    case flixnest = "FlixNest"
    case dramacool = "DramaCool"
    case hanime = "HAnime"
    
    var manifestURL: String? {
        switch self {
        case .stravo: return "https://stravo-clfk.onrender.com/auto/manifest.json"
        case .mediafusion: return "https://mediafusion.elfhosted.com/manifest.json"
        case .torrentio: return "https://torrentio.strem.fun/manifest.json"
        case .flixnest: return "https://flixnest.app/flix-streams/manifest.json"
        case .dramacool: return "https://stremio-dramacool-addon.xyz/manifest.json"
        case .hanime: return "https://86f0740f37f6-hanime-stremio.baby-beamup.club/manifest.json"
        default: return nil
        }
    }
    
    var isAPISource: Bool { manifestURL == nil }
    var isTorrentSource: Bool { manifestURL != nil }
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, parseError(String), networkError(String), playerError(String)
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .parseError(let m): return "Lỗi parse: \(m)"
        case .networkError(let m): return "Lỗi mạng: \(m)"
        case .playerError(let m): return "Lỗi phát: \(m)"
        }
    }
}

// MARK: - External Player Manager
class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    struct PlayerApp {
        let name: String; let scheme: String
        func buildURL(streamURL: String) -> URL? {
            guard let encoded = streamURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            switch name {
            case "Infuse": return URL(string: "infuse://x-callback-url/play?url=\(encoded)")
            case "VLC": return URL(string: "vlc-x-callback://x-callback-url/stream?url=\(encoded)")
            case "ViMu": return URL(string: "vimu://\(encoded)")
            case "Outplayer": return URL(string: "outplayer://\(encoded)")
            case "nPlayer": return URL(string: "nplayer-\(encoded)")
            case "PlayerXtreme": return URL(string: "pxtreme://\(encoded)")
            case "FileBrowser": return URL(string: "fbplayer://\(encoded)")
            case "MX Player": return URL(string: "mxplayer://\(encoded)")
            case "IINA": return URL(string: "iina://open?url=\(encoded)")
            case "Safari": return URL(string: streamURL)
            default: return nil
            }
        }
    }
    let players: [PlayerApp] = [
        PlayerApp(name: "Infuse", scheme: "infuse"), PlayerApp(name: "VLC", scheme: "vlc-x-callback"),
        PlayerApp(name: "ViMu", scheme: "vimu"), PlayerApp(name: "Outplayer", scheme: "outplayer"),
        PlayerApp(name: "nPlayer", scheme: "nplayer"), PlayerApp(name: "PlayerXtreme", scheme: "pxtreme"),
        PlayerApp(name: "FileBrowser", scheme: "fbplayer"), PlayerApp(name: "MX Player", scheme: "mxplayer"),
        PlayerApp(name: "IINA", scheme: "iina"), PlayerApp(name: "Safari", scheme: "http"),
    ]
    func openInPlayer(_ player: PlayerApp, streamURL: String) {
        guard let url = player.buildURL(streamURL: streamURL) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Network Manager
class NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"]
        return URLSession(configuration: config)
    }()
    
    func fetchJSON(from urlString: String, source: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        print("🌐 [\(source)] URL: \(urlString)")
        let (data, response) = try await session.data(for: req)
        if let httpResponse = response as? HTTPURLResponse { print("📊 [\(source)] HTTP: \(httpResponse.statusCode)") }
        if let raw = String(data: data, encoding: .utf8) { print("📄 [\(source)] RAW: \(raw.prefix(2000))") }
        return data
    }
}

// MARK: - Response Models
struct AnimeKitsuStream: Codable { let title: String?; let url: String? }
struct AnimeKitsuResponse: Codable { let streams: [AnimeKitsuStream]? }
struct KKPhimSource: Codable { let url: String? }
struct KKPhimEpisode: Codable { let sources: [KKPhimSource]? }
struct KKPhimResponse: Codable { let episodes: [KKPhimEpisode]? }
struct KKPhimMovie: Codable { let slug: String? }
struct NTLStreamItem: Codable { let name: String?; let title: String?; let url: String? }
struct NTLStreamResponse: Codable { let streams: [NTLStreamItem]? }
struct NguoncFilmItem: Codable { let name: String?; let slug: String? }
struct NguoncFilmListResponse: Codable { let items: [NguoncFilmItem]? }
struct NguoncEpisode: Codable { let link_embed: String?; let link_m3u8: String? }
struct NguoncFilmDetailResponse: Codable { let episodes: [NguoncEpisode]? }
struct StremioStream: Codable { let title: String?; let url: String?; let infoHash: String?; let name: String?
    enum CodingKeys: String, CodingKey { case title, url, name; case infoHash = "infoHash" } }
struct StremioResponse: Codable { let streams: [StremioStream]? }

// MARK: - Nguonc Provider
class NguoncProvider {
    static let shared = NguoncProvider()
    private let baseURL = "https://phim.nguonc.com/api"
    func searchFilm(keyword: String) async throws -> String? {
        let data = try await NetworkManager.shared.fetchJSON(from: "\(baseURL)/films/phim-moi-cap-nhat", source: "Nguonc")
        let res = try JSONDecoder().decode(NguoncFilmListResponse.self, from: data)
        return res.items?.first(where: { $0.name?.lowercased().contains(keyword.lowercased()) ?? false })?.slug
    }
    func fetchStreamURL(slug: String) async throws -> URL? {
        let data = try await NetworkManager.shared.fetchJSON(from: "\(baseURL)/film/\(slug)", source: "Nguonc")
        let res = try JSONDecoder().decode(NguoncFilmDetailResponse.self, from: data)
        if let episodes = res.episodes {
            for ep in episodes {
                if let m3u8 = ep.link_m3u8, let url = URL(string: m3u8) { return url }
                if let embed = ep.link_embed, let url = URL(string: embed) { return url }
            }
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - MovieStreamService
class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> (URL, Bool) {
        switch source {
        case .nguonc: return (try await fetchNguonc(imdbId: imdbId), false)
        case .kkphim: return (try await fetchKKPhim(imdbId: imdbId), false)
        case .ntlStream: return (try await fetchNTLStream(imdbId: imdbId), false)
        case .animeKitsu: return (try await fetchAnimeKitsu(imdbId: imdbId), false)
        default: return (try await fetchStremio(source: source, imdbId: imdbId), true)
        }
    }
    
    func resolveMovie(imdbId: String) async throws -> (URL, Bool) {
        for source in MovieSource.allCases {
            if let (url, isTorrent) = try? await getStreamURL(for: source, imdbId: imdbId) { return (url, isTorrent) }
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchStremio(source: MovieSource, imdbId: String) async throws -> URL {
        guard let manifest = source.manifestURL else { throw StreamError.invalidURL }
        let base = manifest.replacingOccurrences(of: "/manifest.json", with: "")
        let data = try await NetworkManager.shared.fetchJSON(from: "\(base)/stream/movie/\(imdbId).json", source: source.rawValue)
        let res = try JSONDecoder().decode(StremioResponse.self, from: data)
        if let stream = res.streams?.first {
            if let url = stream.url, !url.hasPrefix("magnet:"), let streamURL = URL(string: url) { return streamURL }
            if let hash = stream.infoHash { return URL(string: "magnet:?xt=urn:btih:\(hash)")! }
        }
        throw StreamError.noStreamAvailable
    }
    private func fetchAnimeKitsu(imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://anime-kitsu.strem.fun/stream/movie/\(imdbId).json", source: "AnimeKitsu")
        let res = try JSONDecoder().decode(AnimeKitsuResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil })?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    private func fetchKKPhim(imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)", source: "KKPhim")
        var slug: String?
        if let r = try? JSONDecoder().decode([KKPhimMovie].self, from: data) { slug = r.first?.slug }
        else if let r = try? JSONDecoder().decode(KKPhimMovie.self, from: data) { slug = r.slug }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        let data2 = try await NetworkManager.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/movie/\(slug)", source: "KKPhim-Ep")
        let res = try JSONDecoder().decode(KKPhimResponse.self, from: data2)
        if let url = res.episodes?.first?.sources?.first?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    private func fetchNTLStream(imdbId: String) async throws -> URL {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json", source: "NTL")
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    private func fetchNguonc(imdbId: String) async throws -> URL {
        if let slug = try? await NguoncProvider.shared.searchFilm(keyword: imdbId),
           let url = try? await NguoncProvider.shared.fetchStreamURL(slug: slug) { return url }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - Player Debug (NSObject để KVO hoạt động)
class PlayerDebugger: NSObject {
    static let shared = PlayerDebugger()
    
    static func createPlayerItem(url: URL) -> AVPlayerItem {
        let headers: [String: String] = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        item.addObserver(shared, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
        return item
    }
    
    static func debugPlayer(url: URL) -> AVPlayer {
        let item = createPlayerItem(url: url)
        return AVPlayer(playerItem: item)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status), let item = object as? AVPlayerItem {
            switch item.status {
            case .readyToPlay: print("✅ AVPlayer READY TO PLAY")
            case .failed:
                print("❌ AVPlayer FAILED: \(item.error?.localizedDescription ?? "unknown")")
                if let error = item.error as NSError? { print("❌ Domain: \(error.domain), Code: \(error.code)") }
            case .unknown: print("⚠️ AVPlayer UNKNOWN")
            @unknown default: break
            }
        }
    }
    
    static func testAppleLink() {
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8") else { return }
        print("🧪 TEST APPLE LINK...")
        let player = debugPlayer(url: url)
        player.play()
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    @State private var streamURL: String?
    @State private var isTorrent = false
    @State private var showExternalPlayerMenu = false
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                VStack(spacing: 20) { ProgressView().tint(.white).scaleEffect(1.5); Text("Đợi Mew tí...").foregroundColor(.white.opacity(0.7)).font(.headline) }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                    Button { Task { await loadStream() } } label: {
                        Label("Thử lại", systemImage: "arrow.triangle.2.circlepath").foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    }
                }
            } else if let player = player, !isTorrent {
                CustomVideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() }
            } else if isTorrent, let url = streamURL {
                VStack(spacing: 20) {
                    Image(systemName: "film.stack.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text("Đây là link Torrent").foregroundColor(.white).font(.headline)
                    Text("Cần trình phát ngoài để xem").foregroundColor(.gray)
                    Button { showExternalPlayerMenu = true } label: {
                        Label("Mở bằng trình phát ngoài", systemImage: "arrow.up.forward.app").foregroundColor(.white).padding().background(Capsule().fill(.ultraThinMaterial))
                    }
                }
            }
        }
        .task { await loadStream() }
        .actionSheet(isPresented: $showExternalPlayerMenu) {
            ActionSheet(title: Text("Chọn trình phát"), buttons: ExternalPlayerManager.shared.players.map { p in .default(Text(p.name)) { if let url = streamURL { ExternalPlayerManager.shared.openInPlayer(p, streamURL: url) } } } + [.cancel()])
        }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil; isTorrent = false
        do {
            let imdbId = try await fetchIMDbId()
            let (url, torrent) = try await MovieStreamService.shared.resolveMovie(imdbId: imdbId)
            await MainActor.run {
                self.streamURL = url.absoluteString; self.isTorrent = torrent
                if !torrent { self.player = PlayerDebugger.debugPlayer(url: url) }
                self.isLoading = false
            }
        } catch { await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false } }
    }
    
    private func fetchIMDbId() async throws -> String {
        let data = try await NetworkManager.shared.fetchJSON(from: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)", source: "TMDB")
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