import SwiftUI
import AVKit
import MediaPlayer

// MARK: - MovieSource (chỉ giữ nguồn streaming)
enum MovieSource: String, CaseIterable {
    case kkphim = "KKPhim"
    case ntlStream = "NTL Stream"
    case animeKitsu = "Anime Kitsu"
    
    var manifestURL: String {
        switch self {
        case .kkphim: return "https://kkphim.trankhanh.io.vn/manifest.json"
        case .ntlStream: return "https://tnluannguyen-ntl-stream.hf.space/manifest.json"
        case .animeKitsu: return "https://anime-kitsu.strem.fun/manifest.json"
        }
    }
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
struct AnimeKitsuStream: Codable { let title: String?; let url: String? }
struct AnimeKitsuResponse: Codable { let streams: [AnimeKitsuStream]? }

struct KKPhimSource: Codable { let url: String? }
struct KKPhimEpisode: Codable { let sources: [KKPhimSource]?; let subtitles: [KKPhimSubtitle]? }
struct KKPhimSubtitle: Codable { let url: String?; let lang: String? }
struct KKPhimResponse: Codable { let episodes: [KKPhimEpisode]? }
struct KKPhimMovie: Codable { let slug: String? }

struct NTLStreamItem: Codable { let name: String?; let title: String?; let url: String? }
struct NTLStreamResponse: Codable { let streams: [NTLStreamItem]? }

// MARK: - MovieStreamService
class MovieStreamService {
    static let shared = MovieStreamService()
    private var currentSourceIndex = 0
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> (URL, URL?) {
        switch source {
        case .animeKitsu: return try await fetchAnimeKitsu(imdbId: imdbId)
        case .kkphim: return try await fetchKKPhim(imdbId: imdbId)
        case .ntlStream: return try await fetchNTLStream(imdbId: imdbId)
        }
    }
    
    func getNextSource(current: MovieSource) -> MovieSource {
        let all = MovieSource.allCases
        if let idx = all.firstIndex(of: current), idx + 1 < all.count {
            return all[idx + 1]
        }
        return all[0]
    }
    
    private func fetchAnimeKitsu(imdbId: String) async throws -> (URL, URL?) {
        let urlString = "https://anime-kitsu.strem.fun/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(AnimeKitsuResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil })?.url, let streamURL = URL(string: url) {
            return (streamURL, nil)
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchKKPhim(imdbId: String) async throws -> (URL, URL?) {
        let searchURL = "https://kkphim.trankhanh.io.vn/api/search?keyword=\(imdbId)"
        var req = URLRequest(url: URL(string: searchURL)!)
        req.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        
        var slug: String?
        if let results = try? JSONDecoder().decode([KKPhimMovie].self, from: data) {
            slug = results.first?.slug
        } else if let movie = try? JSONDecoder().decode(KKPhimMovie.self, from: data) {
            slug = movie.slug
        }
        guard let slug = slug else { throw StreamError.noStreamAvailable }
        
        let epURL = "https://kkphim.trankhanh.io.vn/api/movie/\(slug)"
        var req2 = URLRequest(url: URL(string: epURL)!)
        req2.setValue("https://kkphim.trankhanh.io.vn", forHTTPHeaderField: "Referer")
        let (data2, _) = try await URLSession.shared.data(for: req2)
        let res = try JSONDecoder().decode(KKPhimResponse.self, from: data2)
        
        if let episode = res.episodes?.first,
           let sourceURL = episode.sources?.first?.url,
           let streamURL = URL(string: sourceURL) {
            let subURL = episode.subtitles?.first(where: { $0.lang?.contains("vi") ?? false || $0.lang?.contains("en") ?? false })?.url
            return (streamURL, subURL != nil ? URL(string: subURL!) : nil)
        }
        throw StreamError.noStreamAvailable
    }
    
    private func fetchNTLStream(imdbId: String) async throws -> (URL, URL?) {
        let urlString = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("https://www.stremio.com", forHTTPHeaderField: "Referer")
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(NTLStreamResponse.self, from: data)
        if let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
           let streamURL = URL(string: url) {
            return (streamURL, nil)
        }
        throw StreamError.noStreamAvailable
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: MovieSource = .kkphim
    @State private var streamURL: URL?; @State private var subtitleURL: URL?
    @State private var isLoading = true; @State private var errorMessage: String?
    @State private var player: AVPlayer?
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đang lấy link từ \(selectedSource.rawValue)...").foregroundColor(.gray).font(.caption)
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
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                    
                    Button { Task { await loadStream() } } label: {
                        Text("Thử lại").foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
            } else if let player = player {
                CustomVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                        setupAudioSession()
                    }
                    .onDisappear { player.pause() }
            }
        }
        .task { await loadStream() }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil
        do {
            let imdbId = try await fetchIMDbId()
            let (stream, subtitle) = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId)
            await MainActor.run {
                self.streamURL = stream; self.subtitleURL = subtitle
                let asset = AVURLAsset(url: stream)
                let playerItem = AVPlayerItem(asset: asset)
                
                if let subURL = subtitle {
                    let locale = Locale(identifier: "vi")
                    let annotation = AVMetadataItem(propertiesOf: .commonIdentifierTitle, value: "Vietsub" as NSString)
                    playerItem.externalMetadata = [annotation]
                }
                
                self.player = AVPlayer(playerItem: playerItem)
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
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

// MARK: - Custom Video Player với PiP + Xoay ngang
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.updatesNowPlayingInfoCenter = true
        
        // Hỗ trợ xoay ngang
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - PiP Window Scene Delegate
class PiPDelegate: NSObject, ObservableObject {
    func enablePiP() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("PiP error: \(error)")
        }
    }
}