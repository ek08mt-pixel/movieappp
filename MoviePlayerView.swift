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
    
    var isAPI: Bool { manifestURL == nil }
    var isStremio: Bool { manifestURL != nil }
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, httpError(Int), parseError(String), networkError(String)
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .httpError(let code): return "Server lỗi HTTP \(code)"
        case .parseError(let m): return "Lỗi parse JSON: \(m)"
        case .networkError(let m): return "Lỗi mạng: \(m)"
        }
    }
}

// MARK: - Link Resolver
class LinkResolver {
    static let shared = LinkResolver()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Accept": "application/json, text/html, */*",
            "Accept-Language": "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7"
        ]
        return URLSession(configuration: config)
    }()
    
    func fetchJSON(from urlString: String, source: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        // Tự động lấy domain làm Referer
        let referer = url.host.map { "https://\($0)/" } ?? ""
        
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json, text/html, */*", forHTTPHeaderField: "Accept")
        req.setValue(referer, forHTTPHeaderField: "Referer")
        req.timeoutInterval = 20
        
        print("🌐 [\(source)] GỌI: \(urlString)")
        print("🔗 [\(source)] Referer: \(referer)")
        
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StreamError.networkError("Không phải HTTP response")
        }
        
        print("📊 [\(source)] HTTP STATUS: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let body = String(data: data, encoding: .utf8) {
                print("❌ [\(source)] HTTP \(httpResponse.statusCode): \(body.prefix(1000))")
            }
            throw StreamError.httpError(httpResponse.statusCode)
        }
        
        if let raw = String(data: data, encoding: .utf8) {
            print("📄 [\(source)] RAW JSON (first 2000 chars): \(raw.prefix(2000))")
        }
        
        return data
    }
    
    func resolveFinalURL(_ urlString: String) async -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.httpMethod = "HEAD"
        do {
            let (_, response) = try await session.data(for: req)
            let finalURL = response.url ?? url
            print("🔀 Redirect: \(urlString) -> \(finalURL.absoluteString)")
            return finalURL
        } catch {
            return url
        }
    }
}

// MARK: - Response Models
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

// MARK: - Source Manager (Fallback logic)
class SourceManager {
    static let shared = SourceManager()
    
    func resolveMovie(imdbId: String) async throws -> (URL, Bool) {
        // 1. Thử 3 nguồn API trước
        print("🔍 BẮT ĐẦU QUÉT 3 NGUỒN API...")
        if let url = try? await fetchNguonc(imdbId) { return (url, false) }
        if let url = try? await fetchKKPhim(imdbId) { return (url, false) }
        if let url = try? await fetchNTLStream(imdbId) { return (url, false) }
        
        // 2. Thử 6 nguồn Stremio Manifest
        print("🔍 API THẤT BẠI - CHUYỂN SANG STREMIO...")
        let stremioSources: [MovieSource] = [.torrentio, .stravo, .mediafusion, .flixnest, .dramacool, .hanime, .animeKitsu]
        for source in stremioSources {
            if let url = try? await fetchStremio(source: source, imdbId: imdbId) {
                return (url, true)
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNguonc(_ imdbId: String) async throws -> URL {
        print("🎯 THỬ NguonC...")
        let data = try await LinkResolver.shared.fetchJSON(from: "https://phim.nguonc.com/api/films/phim-moi-cap-nhat", source: "NguonC")
        let list = try JSONDecoder().decode(NguoncFilmListResponse.self, from: data)
        guard let slug = list.items?.first(where: { $0.name?.lowercased().contains(imdbId.lowercased()) ?? false })?.slug else {
            throw StreamError.noStreamAvailable
        }
        let detailData = try await LinkResolver.shared.fetchJSON(from: "https://phim.nguonc.com/api/film/\(slug)", source: "NguonC-Detail")
        let detail = try JSONDecoder().decode(NguoncFilmDetailResponse.self, from: detailData)
        if let episodes = detail.episodes {
            for ep in episodes {
                if let m3u8 = ep.link_m3u8, let url = URL(string: m3u8) {
                    if let final = await LinkResolver.shared.resolveFinalURL(m3u8) { return final }
                    return url
                }
                if let embed = ep.link_embed, let url = URL(string: embed) { return url }
            }
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhim(_ imdbId: String) async throws -> URL {
        print("🎯 THỬ KKPhim...")
        let data = try await LinkResolver.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)", source: "KKPhim")
        var slug: String?
        if let r = try? JSONDecoder().decode([KKPhimMovie].self, from: data) { slug = r.first?.slug }
        else if let r = try? JSONDecoder().decode(KKPhimMovie.self, from: data) { slug = r.slug }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        let epData = try await LinkResolver.shared.fetchJSON(from: "https://kkphim.trankhanh.io.vn/api/movie/\(slug)", source: "KKPhim-Ep")
        let ep = try JSONDecoder().decode(KKPhimResponse.self, from: epData)
        if let url = ep.episodes?.first?.sources?.first?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNTLStream(_ imdbId: String) async throws -> URL {
        print("🎯 THỬ NTL...")
        let data = try await LinkResolver.shared.fetchJSON(from: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json", source: "NTL")
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
           let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchStremio(source: MovieSource, imdbId: String) async throws -> URL {
        guard let manifest = source.manifestURL else { throw StreamError.invalidURL }
        let base = manifest.replacingOccurrences(of: "/manifest.json", with: "")
        print("🎯 THỬ \(source.rawValue)...")
        let data = try await LinkResolver.shared.fetchJSON(from: "\(base)/stream/movie/\(imdbId).json", source: source.rawValue)
        let res = try JSONDecoder().decode(StremioResponse.self, from: data)
        if let stream = res.streams?.first {
            if let url = stream.url, !url.hasPrefix("magnet:"), let streamURL = URL(string: url) { return streamURL }
            if let hash = stream.infoHash { return URL(string: "magnet:?xt=urn:btih:\(hash)")! }
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - External Player Manager
class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    
    struct PlayerApp {
        let name: String
        let scheme: String
        
        func buildURL(streamURL: String) -> URL? {
            guard let encoded = streamURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            let urlString: String
            switch name {
            case "Infuse": urlString = "infuse://x-callback-url/play?url=\(encoded)"
            case "VLC": urlString = "vlc-x-callback://x-callback-url/stream?url=\(encoded)"
            case "ViMu": urlString = "vimu://\(encoded)"
            case "Outplayer": urlString = "outplayer://\(encoded)"
            case "nPlayer": urlString = "nplayer-\(encoded)"
            case "PlayerXtreme": urlString = "pxtreme://\(encoded)"
            case "FileBrowser": urlString = "fbplayer://\(encoded)"
            case "MX Player": urlString = "mxplayer://\(encoded)"
            case "IINA": urlString = "iina://open?url=\(encoded)"
            case "Safari": return URL(string: streamURL)
            case "Copy Link": UIPasteboard.general.string = streamURL; return nil
            default: return nil
            }
            print("🔗 [External] \(name): \(urlString)")
            return URL(string: urlString)
        }
    }
    
    let players: [PlayerApp] = [
        PlayerApp(name: "Infuse", scheme: "infuse"),
        PlayerApp(name: "VLC", scheme: "vlc-x-callback"),
        PlayerApp(name: "ViMu", scheme: "vimu"),
        PlayerApp(name: "Outplayer", scheme: "outplayer"),
        PlayerApp(name: "nPlayer", scheme: "nplayer"),
        PlayerApp(name: "PlayerXtreme", scheme: "pxtreme"),
        PlayerApp(name: "FileBrowser", scheme: "fbplayer"),
        PlayerApp(name: "MX Player", scheme: "mxplayer"),
        PlayerApp(name: "IINA", scheme: "iina"),
        PlayerApp(name: "Safari", scheme: "http"),
        PlayerApp(name: "Copy Link", scheme: "copy"),
    ]
    
    func openInPlayer(_ player: PlayerApp, streamURL: String) {
        if player.name == "Copy Link" { return }
        guard let url = player.buildURL(streamURL: streamURL) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Player Debug
class PlayerDebugger: NSObject {
    static let shared = PlayerDebugger()
    static func createPlayerItem(url: URL) -> AVPlayerItem {
        let headers: [String: String] = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15",
            "Referer": "https://phim.nguonc.com/"
        ]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        item.addObserver(shared, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
        return item
    }
    static func debugPlayer(url: URL) -> AVPlayer { return AVPlayer(playerItem: createPlayerItem(url: url)) }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status), let item = object as? AVPlayerItem {
            switch item.status {
            case .readyToPlay: print("✅ AVPlayer READY")
            case .failed: print("❌ AVPlayer FAILED: \(item.error?.localizedDescription ?? "")")
            default: break
            }
        }
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
                    HStack(spacing: 12) {
                        Button { Task { await loadStream() } } label: { Label("Thử lại", systemImage: "arrow.triangle.2.circlepath").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)).font(.caption) }
                        if streamURL != nil { Button { showExternalPlayerMenu = true } label: { Label("Mở bằng app khác", systemImage: "arrow.up.forward.app").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.white.opacity(0.15))).font(.caption) } }
                    }
                }
            } else if let player = player, !isTorrent {
                CustomVideoPlayer(player: player).ignoresSafeArea().onAppear { player.play() }.onDisappear { player.pause() }
                    .overlay(alignment: .topTrailing) {
                        Menu {
                            ForEach(ExternalPlayerManager.shared.players, id: \.name) { p in Button(p.name) { if let url = streamURL { ExternalPlayerManager.shared.openInPlayer(p, streamURL: url) } } }
                        } label: { Image(systemName: "ellipsis.circle.fill").font(.system(size: 24)).foregroundColor(.white).padding() }
                    }
            } else if isTorrent {
                VStack(spacing: 20) {
                    Image(systemName: "film.stack.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text("Link Torrent").foregroundColor(.white).font(.headline)
                    Button { showExternalPlayerMenu = true } label: { Label("Mở bằng trình phát ngoài", systemImage: "arrow.up.forward.app").foregroundColor(.white).padding().background(Capsule().fill(.ultraThinMaterial)) }
                }
            }
        }
        .task { await loadStream() }
        .actionSheet(isPresented: $showExternalPlayerMenu) {
            ActionSheet(title: Text("Chọn trình phát"), message: Text("Nếu lỗi, hãy chọn 'Copy Link' rồi dán vào app."),
                buttons: ExternalPlayerManager.shared.players.map { p in .default(Text(p.name)) { if let url = streamURL { ExternalPlayerManager.shared.openInPlayer(p, streamURL: url) } } } + [.cancel()])
        }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil; isTorrent = false
        do {
            let imdbId = try await fetchIMDbId()
            let (url, torrent) = try await SourceManager.shared.resolveMovie(imdbId: imdbId)
            await MainActor.run {
                self.streamURL = url.absoluteString; self.isTorrent = torrent
                if !torrent { self.player = PlayerDebugger.debugPlayer(url: url) }
                self.isLoading = false
            }
        } catch { await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false } }
    }
    
    private func fetchIMDbId() async throws -> String {
        let data = try await LinkResolver.shared.fetchJSON(from: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)", source: "TMDB")
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