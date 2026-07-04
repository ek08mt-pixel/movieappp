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

// MARK: - Lỗi tùy chỉnh
enum StreamError: Error, LocalizedError {
    case metadataOnly
    case noStreamAvailable
    case invalidURL
    case parseError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .metadataOnly: return "Nguồn này không hỗ trợ xem trực tiếp (chỉ là catalog)"
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .parseError(let msg): return "Lỗi parse: \(msg)"
        case .networkError(let msg): return "Lỗi mạng: \(msg)"
        }
    }
}

// MARK: - Response Models riêng cho từng nguồn

// Torrentio Response
struct TorrentioStream: Codable {
    let title: String?
    let url: String?
    let infoHash: String?
    let fileIdx: Int?
    let behaviorHints: TorrentioBehaviorHints?
    
    enum CodingKeys: String, CodingKey {
        case title, url, fileIdx
        case infoHash = "infoHash"
        case behaviorHints = "behaviorHints"
    }
}
struct TorrentioBehaviorHints: Codable {
    let bingeGroup: String?
    let notWebReady: Bool?
}
struct TorrentioResponse: Codable {
    let streams: [TorrentioStream]?
}

// AnimeKitsu Response (giống Stremio format)
struct AnimeKitsuStream: Codable {
    let title: String?
    let url: String?
    let name: String?
    let description: String?
}
struct AnimeKitsuResponse: Codable {
    let streams: [AnimeKitsuStream]?
}

// KKPhim Response
struct KKPhimEpisode: Codable {
    let id: String?
    let title: String?
    let sources: [KKPhimSource]?
}
struct KKPhimSource: Codable {
    let url: String?
    let quality: String?
    let isM3U8: Bool?
}
struct KKPhimResponse: Codable {
    let success: Bool?
    let movie: KKPhimMovie?
    let episodes: [KKPhimEpisode]?
}
struct KKPhimMovie: Codable {
    let id: String?
    let title: String?
    let slug: String?
}

// NTL Stream Response (Stremio format)
struct NTLStreamItem: Codable {
    let name: String?
    let title: String?
    let url: String?
    let description: String?
    let infoHash: String?
    let behaviorHints: NTLBehaviorHints?
}
struct NTLBehaviorHints: Codable {
    let notWebReady: Bool?
    let bingeGroup: String?
}
struct NTLStreamResponse: Codable {
    let streams: [NTLStreamItem]?
}

// OnePace Response
struct OnePaceStream: Codable {
    let title: String?
    let url: String?
    let infoHash: String?
}
struct OnePaceResponse: Codable {
    let streams: [OnePaceStream]?
}

// MARK: - Movie Stream Service
class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> URL? {
        switch source {
        case .torrentio:
            return try await fetchTorrentio(imdbId: imdbId)
        case .netflixCatalog:
            throw StreamError.metadataOnly
        case .animeKitsu:
            return try await fetchAnimeKitsu(imdbId: imdbId)
        case .torrentCatalogs:
            throw StreamError.metadataOnly
        case .onepace:
            return try await fetchOnePace(imdbId: imdbId)
        case .kkphim:
            return try await fetchKKPhim(imdbId: imdbId)
        case .ntlStream:
            return try await fetchNTLStream(imdbId: imdbId)
        }
    }
    
    // MARK: - Torrentio
    private func fetchTorrentio(imdbId: String) async throws -> URL? {
        let urlString = "https://torrentio.strem.fun/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TorrentioResponse.self, from: data)
        
        // Tìm stream có url (không phải torrent)
        if let stream = response.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) }) {
            return URL(string: stream.url!)
        }
        
        // Nếu chỉ có torrent, báo lỗi
        if response.streams?.first?.infoHash != nil {
            throw StreamError.noStreamAvailable
        }
        
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - AnimeKitsu
    private func fetchAnimeKitsu(imdbId: String) async throws -> URL? {
        let urlString = "https://anime-kitsu.strem.fun/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AnimeKitsuResponse.self, from: data)
        
        if let stream = response.streams?.first(where: { $0.url != nil }),
           let urlString = stream.url {
            return URL(string: urlString)
        }
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - OnePace
    private func fetchOnePace(imdbId: String) async throws -> URL? {
        let urlString = "https://onepaceaddon-zoropogger.koyeb.app/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        let (data, _) = try await URLSession.shared.data(for: url)
        let response = try JSONDecoder().decode(OnePaceResponse.self, from: data)
        
        if let stream = response.streams?.first(where: { $0.url != nil }),
           let urlString = stream.url {
            return URL(string: urlString)
        }
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - KKPhim
    private func fetchKKPhim(imdbId: String) async throws -> URL? {
        // KKPhim dùng ID riêng, thử tìm bằng slug
        let searchURL = "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)"
        guard let url = URL(string: searchURL) else { throw StreamError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Thử parse dạng mảng trước
        if let results = try? JSONDecoder().decode([KKPhimMovie].self, from: data),
           let firstMovie = results.first,
           let slug = firstMovie.slug {
            return try await fetchKKPhimEpisodes(slug: slug)
        }
        
        // Thử parse dạng object
        if let movie = try? JSONDecoder().decode(KKPhimMovie.self, from: data),
           let slug = movie.slug {
            return try await fetchKKPhimEpisodes(slug: slug)
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhimEpisodes(slug: String) async throws -> URL? {
        let urlString = "https://kkphim.trankhanh.io.vn/api/movie/\(slug)"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(KKPhimResponse.self, from: data)
        
        if let episodes = response.episodes,
           let firstEpisode = episodes.first,
           let sources = firstEpisode.sources,
           let firstSource = sources.first,
           let link = firstSource.url {
            return URL(string: link)
        }
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - NTL Stream
    private func fetchNTLStream(imdbId: String) async throws -> URL? {
        let urlString = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        
        if let stream = response.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) }),
           let urlString = stream.url {
            return URL(string: urlString)
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSource: MovieSource = .torrentio
    @State private var streamURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                        Menu {
                            ForEach(MovieSource.allCases, id: \.self) { source in
                                Button(source.rawValue) {
                                    selectedSource = source
                                    Task { await loadStream() }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedSource.rawValue).font(.caption2).foregroundColor(.gray)
                                Image(systemName: "chevron.down").font(.caption2).foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }.padding()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang lấy link từ \(selectedSource.rawValue)...").foregroundColor(.gray).font(.caption)
                    }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await loadStream() } }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                        Text("Chọn nguồn khác:").foregroundColor(.gray).font(.caption).padding(.top)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MovieSource.allCases, id: \.self) { source in
                                    Button(source.rawValue) {
                                        selectedSource = source; Task { await loadStream() }
                                    }.font(.caption).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(.ultraThinMaterial))
                                }
                            }.padding(.horizontal)
                        }
                    }.frame(maxHeight: .infinity)
                } else if let player = player {
                    CustomVideoPlayer(player: player)
                        .onAppear { player.play() }
                        .onDisappear { player.pause() }
                }
            }
        }
        .task { await loadStream() }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil
        
        do {
            let imdbId = try await fetchIMDbId()
            let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId)
            
            await MainActor.run {
                if let url = url {
                    self.player = AVPlayer(url: url)
                } else {
                    self.errorMessage = "Không tìm thấy link stream"
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func fetchIMDbId() async throws -> String {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw StreamError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct EID: Codable { let imdb_id: String? }
        let result = try JSONDecoder().decode(EID.self, from: data)
        guard let imdbId = result.imdb_id else { throw StreamError.noStreamAvailable }
        return imdbId
    }
}

// MARK: - Custom Video Player
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true; c.videoGravity = .resizeAspect; return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}