import SwiftUI
import AVKit

// MARK: - MovieSource
enum MovieSource: String, CaseIterable {
    case torrentio = "Torrentio"
    case netflixCatalog = "Netflix Catalog"
    case animeKitsu = "Anime Kitsu"
    case torrentCatalogs = "Torrent Catalogs"
    case onepace = "OnePace"
    case kkphim = "KKPhim"
    case ntlStream = "NTL Stream"
    
    var manifestURL: String {
        switch self {
        case .torrentio: return "https://torrentio.strem.fun/lite/manifest.json"
        case .netflixCatalog: return "https://7a82163c306e-stremio-netflix-catalog-addon.baby-beamup.club/manifest.json"
        case .animeKitsu: return "https://anime-kitsu.strem.fun/manifest.json"
        case .torrentCatalogs: return "https://torrent-catalogs.strem.fun/manifest.json"
        case .onepace: return "https://onepaceaddon-zoropogger.koyeb.app/manifest.json"
        case .kkphim: return "https://kkphim.trankhanh.io.vn/manifest.json"
        case .ntlStream: return "https://tnluannguyen-ntl-stream.hf.space/manifest.json"
        }
    }
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case metadataOnly, noStreamAvailable, invalidURL, parseError(String), networkError(String)
    var errorDescription: String? {
        switch self {
        case .metadataOnly: return "Nguồn này không hỗ trợ xem trực tiếp (chỉ là catalog)"
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .parseError(let m): return "Lỗi parse: \(m)"
        case .networkError(let m): return "Lỗi mạng: \(m)"
        }
    }
}

// MARK: - Response Models
struct TorrentioStream: Codable {
    let title: String?; let url: String?; let infoHash: String?
    enum CodingKeys: String, CodingKey { case title, url, infoHash = "infoHash" }
}
struct TorrentioResponse: Codable { let streams: [TorrentioStream]? }

struct AnimeKitsuStream: Codable { let title: String?; let url: String? }
struct AnimeKitsuResponse: Codable { let streams: [AnimeKitsuStream]? }

struct OnePaceStream: Codable { let title: String?; let url: String? }
struct OnePaceResponse: Codable { let streams: [OnePaceStream]? }

struct KKPhimSource: Codable { let url: String? }
struct KKPhimEpisode: Codable { let sources: [KKPhimSource]? }
struct KKPhimResponse: Codable { let episodes: [KKPhimEpisode]? }
struct KKPhimMovie: Codable { let slug: String? }

struct NTLStreamItem: Codable { let name: String?; let title: String?; let url: String? }
struct NTLStreamResponse: Codable { let streams: [NTLStreamItem]? }

// MARK: - MovieStreamService
class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> URL? {
        switch source {
        case .torrentio: return try await fetchTorrentio(imdbId: imdbId)
        case .netflixCatalog: throw StreamError.metadataOnly
        case .animeKitsu: return try await fetchAnimeKitsu(imdbId: imdbId)
        case .torrentCatalogs: throw StreamError.metadataOnly
        case .onepace: return try await fetchOnePace(imdbId: imdbId)
        case .kkphim: return try await fetchKKPhim(imdbId: imdbId)
        case .ntlStream: return try await fetchNTLStream(imdbId: imdbId)
        }
    }
    
    private func fetchTorrentio(imdbId: String) async throws -> URL? {
        let urlString = "https://torrentio.strem.fun/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(TorrentioResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url {
            return URL(string: url)
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchAnimeKitsu(imdbId: String) async throws -> URL? {
        let urlString = "https://anime-kitsu.strem.fun/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(AnimeKitsuResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil })?.url { return URL(string: url) }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchOnePace(imdbId: String) async throws -> URL? {
        let urlString = "https://onepaceaddon-zoropogger.koyeb.app/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OnePaceResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil })?.url { return URL(string: url) }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhim(imdbId: String) async throws -> URL? {
        let searchURL = "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)"
        var req = URLRequest(url: URL(string: searchURL)!)
        req.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        if let results = try? JSONDecoder().decode([KKPhimMovie].self, from: data), let slug = results.first?.slug {
            return try await fetchKKPhimEpisodes(slug: slug)
        }
        if let movie = try? JSONDecoder().decode(KKPhimMovie.self, from: data), let slug = movie.slug {
            return try await fetchKKPhimEpisodes(slug: slug)
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhimEpisodes(slug: String) async throws -> URL? {
        let urlString = "https://kkphim.trankhanh.io.vn/api/movie/\(slug)"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(KKPhimResponse.self, from: data)
        if let url = res.episodes?.first?.sources?.first?.url { return URL(string: url) }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNTLStream(imdbId: String) async throws -> URL? {
        let urlString = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url {
            return URL(string: url)
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: MovieSource = .torrentio
    @State private var streamURL: URL?; @State private var isLoading = true
    @State private var errorMessage: String?; @State private var player: AVPlayer?
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white) }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                        Menu {
                            ForEach(MovieSource.allCases, id: \.self) { s in
                                Button(s.rawValue) { selectedSource = s; Task { await loadStream() } }
                            }
                        } label: {
                            HStack(spacing: 4) { Text(selectedSource.rawValue).font(.caption2).foregroundColor(.gray); Image(systemName: "chevron.down").font(.caption2).foregroundColor(.gray) }
                        }
                    }
                    Spacer()
                }.padding()
                
                if isLoading {
                    VStack(spacing: 16) { ProgressView().tint(.white).scaleEffect(1.5); Text("Đang lấy link từ \(selectedSource.rawValue)...").foregroundColor(.gray).font(.caption) }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await loadStream() } }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                        Text("Chọn nguồn khác:").foregroundColor(.gray).font(.caption).padding(.top)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MovieSource.allCases, id: \.self) { s in Button(s.rawValue) { selectedSource = s; Task { await loadStream() } }.font(.caption).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(.ultraThinMaterial)) }
                            }.padding(.horizontal)
                        }
                    }.frame(maxHeight: .infinity)
                } else if let player = player {
                    CustomVideoPlayer(player: player).onAppear { player.play() }.onDisappear { player.pause() }
                }
            }
        }.task { await loadStream() }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil
        do {
            let imdbId = try await fetchIMDbId()
            let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId)
            await MainActor.run {
                if let url = url { self.player = AVPlayer(url: url) } else { self.errorMessage = "Không tìm thấy link stream" }
                self.isLoading = false
            }
        } catch { await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false } }
    }
    
    private func fetchIMDbId() async throws -> String {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)"
        var req = URLRequest(url: URL(string: urlString)!)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct EID: Codable { let imdb_id: String? }
        let result = try JSONDecoder().decode(EID.self, from: data)
        guard let imdbId = result.imdb_id else { throw StreamError.noStreamAvailable }
        return imdbId
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController { let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true; c.videoGravity = .resizeAspect; return c }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}