import SwiftUI
import AVKit
import MediaPlayer

// MARK: - MovieSource
enum MovieSource: String, CaseIterable {
    case nguonc = "Nguồn C"
    case kkphim = "KKPhim"
    case ntlStream = "NTL Stream"
    case animeKitsu = "Anime Kitsu"
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, parseError(String), networkError(String)
    var errorDescription: String? {
        switch self {
        case .noStreamAvailable: return "Không tìm thấy link stream"
        case .invalidURL: return "URL không hợp lệ"
        case .parseError(let m): return "Lỗi parse: \(m)"
        case .networkError(let m): return "Lỗi mạng: \(m)"
        }
    }
}

// MARK: - Response Models

// AnimeKitsu
struct AnimeKitsuStream: Codable { let title: String?; let url: String? }
struct AnimeKitsuResponse: Codable { let streams: [AnimeKitsuStream]? }

// KKPhim
struct KKPhimSource: Codable { let url: String? }
struct KKPhimEpisode: Codable { let sources: [KKPhimSource]? }
struct KKPhimResponse: Codable { let episodes: [KKPhimEpisode]? }
struct KKPhimMovie: Codable { let slug: String? }

// NTL Stream
struct NTLStreamItem: Codable { let name: String?; let title: String?; let url: String? }
struct NTLStreamResponse: Codable { let streams: [NTLStreamItem]? }

// Nguonc.com
struct NguoncFilmItem: Codable {
    let name: String?
    let slug: String?
    let thumb_url: String?
    let poster_url: String?
}
struct NguoncFilmListResponse: Codable {
    let items: [NguoncFilmItem]?
}
struct NguoncEpisode: Codable {
    let name: String?
    let slug: String?
    let link_embed: String?
    let link_m3u8: String?
}
struct NguoncMovieDetail: Codable {
    let name: String?
    let slug: String?
    let thumb_url: String?
    let poster_url: String?
    let description: String?
    let year: String?
}
struct NguoncFilmDetailResponse: Codable {
    let movie: NguoncMovieDetail?
    let episodes: [NguoncEpisode]?
}

// MARK: - Nguonc Provider
class NguoncProvider {
    static let shared = NguoncProvider()
    private let baseURL = "https://phim.nguonc.com/api"
    
    func fetchFilmList() async throws -> [NguoncFilmItem] {
        let urlString = "\(baseURL)/films/phim-moi-cap-nhat"
        let req = URLRequest(url: URL(string: urlString)!)
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(NguoncFilmListResponse.self, from: data)
        return res.items ?? []
    }
    
    func fetchMovieDetail(slug: String) async throws -> NguoncFilmDetailResponse {
        let urlString = "\(baseURL)/film/\(slug)"
        let req = URLRequest(url: URL(string: urlString)!)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(NguoncFilmDetailResponse.self, from: data)
    }
    
    func fetchStreamURL(slug: String) async throws -> URL? {
        let detail = try await fetchMovieDetail(slug: slug)
        if let episodes = detail.episodes, !episodes.isEmpty {
            for ep in episodes {
                if let m3u8 = ep.link_m3u8, let url = URL(string: m3u8) { return url }
                if let embed = ep.link_embed, let url = URL(string: embed) { return url }
            }
        }
        throw StreamError.noStreamAvailable
    }
    
    func searchFilm(keyword: String) async throws -> String? {
        let list = try await fetchFilmList()
        if let match = list.first(where: { $0.name?.lowercased().contains(keyword.lowercased()) ?? false }) {
            return match.slug
        }
        return nil
    }
}

// MARK: - MovieStreamService
class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> URL {
        switch source {
        case .animeKitsu: return try await fetchAnimeKitsu(imdbId: imdbId)
        case .kkphim: return try await fetchKKPhim(imdbId: imdbId)
        case .ntlStream: return try await fetchNTLStream(imdbId: imdbId)
        case .nguonc: return try await fetchNguonc(imdbId: imdbId)
        }
    }
    
    func getNextSource(current: MovieSource) -> MovieSource {
        let all = MovieSource.allCases
        if let idx = all.firstIndex(of: current), idx + 1 < all.count { return all[idx + 1] }
        return all[0]
    }
    
    func tryAllSources(imdbId: String) async throws -> URL {
        for source in MovieSource.allCases {
            do {
                return try await getStreamURL(for: source, imdbId: imdbId)
            } catch {
                continue
            }
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchAnimeKitsu(imdbId: String) async throws -> URL {
        let urlString = "https://anime-kitsu.strem.fun/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(AnimeKitsuResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil })?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhim(imdbId: String) async throws -> URL {
        let searchURL = "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)"
        var req = URLRequest(url: URL(string: searchURL)!)
        req.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        var slug: String?
        if let results = try? JSONDecoder().decode([KKPhimMovie].self, from: data) { slug = results.first?.slug }
        else if let movie = try? JSONDecoder().decode(KKPhimMovie.self, from: data) { slug = movie.slug }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        let epURL = "https://kkphim.trankhanh.io.vn/api/movie/\(slug)"
        var req2 = URLRequest(url: URL(string: epURL)!)
        req2.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data2, _) = try await URLSession.shared.data(for: req2)
        let res = try JSONDecoder().decode(KKPhimResponse.self, from: data2)
        if let url = res.episodes?.first?.sources?.first?.url, let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNTLStream(imdbId: String) async throws -> URL {
        let urlString = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
           let streamURL = URL(string: url) { return streamURL }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNguonc(imdbId: String) async throws -> URL {
        if let slug = try? await NguoncProvider.shared.searchFilm(keyword: imdbId),
           let url = try? await NguoncProvider.shared.fetchStreamURL(slug: slug) {
            return url
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: MovieSource = .nguonc
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
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
                    Button {
                        selectedSource = MovieStreamService.shared.getNextSource(current: selectedSource)
                        Task { await loadStream() }
                    } label: {
                        Label("Thử nguồn khác", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    }
                    Button {
                        Task {
                            do {
                                let imdbId = try await fetchIMDbId()
                                let url = try await MovieStreamService.shared.tryAllSources(imdbId: imdbId)
                                await MainActor.run { self.player = AVPlayer(url: url); self.errorMessage = nil }
                            } catch {
                                await MainActor.run { self.errorMessage = error.localizedDescription }
                            }
                        }
                    } label: {
                        Text("Thử tất cả nguồn").foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
            } else if let player = player {
                CustomVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            }
        }
        .task { await loadStream() }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil
        do {
            let imdbId = try await fetchIMDbId()
            let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId)
            await MainActor.run { self.player = AVPlayer(url: url); self.isLoading = false }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func fetchIMDbId() async throws -> String {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)"
        let req = URLRequest(url: URL(string: urlString)!)
        let (data, _) = try await URLSession.shared.data(for: req)
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
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}