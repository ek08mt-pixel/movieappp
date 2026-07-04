import SwiftUI
import AVKit

// MARK: - Nguồn phim
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
                // Header với chọn nguồn
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28)).foregroundColor(.white)
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
                                Text(selectedSource.rawValue)
                                    .font(.caption2).foregroundColor(.gray)
                                Image(systemName: "chevron.down")
                                    .font(.caption2).foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }.padding()
                
                // Content
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang lấy link từ \(selectedSource.rawValue)...")
                            .foregroundColor(.gray).font(.caption)
                    }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await loadStream() } }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                        
                        Text("Thử nguồn khác:")
                            .foregroundColor(.gray).font(.caption).padding(.top)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MovieSource.allCases, id: \.self) { source in
                                    Button(source.rawValue) {
                                        selectedSource = source
                                        Task { await loadStream() }
                                    }
                                    .font(.caption).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(.ultraThinMaterial))
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
    
    // MARK: - Load Stream
    private func loadStream() async {
        isLoading = true; errorMessage = nil; player = nil
        
        do {
            // Lấy IMDb ID
            let imdbId = try await fetchIMDbId()
            
            // Fetch stream từ nguồn đã chọn
            let url = try await fetchStream(from: selectedSource, imdbId: imdbId)
            
            await MainActor.run {
                if let url = url {
                    self.player = AVPlayer(url: url)
                } else {
                    self.errorMessage = "Nguồn \(selectedSource.rawValue) không có link stream"
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "\(selectedSource.rawValue): \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch IMDb ID
    private func fetchIMDbId() async throws -> String {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL lỗi"]) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "TMDB lỗi"])
        }
        struct EID: Codable { let imdb_id: String? }
        let result = try JSONDecoder().decode(EID.self, from: data)
        guard let imdbId = result.imdb_id else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không có IMDb ID"]) }
        return imdbId
    }
    
    // MARK: - Fetch Stream theo nguồn
    private func fetchStream(from source: MovieSource, imdbId: String) async throws -> URL? {
        switch source {
        case .torrentio:
            return try await fetchFromStremio(addon: "torrentio", imdbId: imdbId)
        case .netflixCatalog:
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nguồn này chỉ là catalog, không hỗ trợ stream"])
        case .animeKitsu:
            return try await fetchFromStremio(addon: "anime-kitsu", imdbId: imdbId)
        case .torrentCatalogs:
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nguồn này chỉ là catalog, không hỗ trợ stream"])
        case .onepace:
            return try await fetchFromStremio(addon: "onepace", imdbId: imdbId)
        case .kkphim:
            return try await fetchFromKKPhim(imdbId: imdbId)
        case .ntlStream:
            return try await fetchFromNTLStream(imdbId: imdbId)
        }
    }
    
    // Stremio Addon API
    private func fetchFromStremio(addon: String, imdbId: String) async throws -> URL? {
        let urlString = "https://\(addon).strem.fun/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let streams = json?["streams"] as? [[String: Any]],
           let firstStream = streams.first,
           let urlString = firstStream["url"] as? String ?? firstStream["infoHash"] as? String {
            if urlString.hasPrefix("magnet:") {
                // Torrent link - không phát trực tiếp được
                return nil
            }
            return URL(string: urlString)
        }
        return nil
    }
    
    // KKPhim API
    private func fetchFromKKPhim(imdbId: String) async throws -> URL? {
        let urlString = "https://kkphim.trankhanh.io.vn/api/movie/\(imdbId)"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let episodes = json?["episodes"] as? [[String: Any]],
           let firstEpisode = episodes.first,
           let sources = firstEpisode["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let link = firstSource["url"] as? String {
            return URL(string: link)
        }
        return nil
    }
    
    // NTL Stream API
    private func fetchFromNTLStream(imdbId: String) async throws -> URL? {
        let urlString = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let streams = json?["streams"] as? [[String: Any]],
           let firstStream = streams.first,
           let urlString = firstStream["url"] as? String {
            return URL(string: urlString)
        }
        return nil
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
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}