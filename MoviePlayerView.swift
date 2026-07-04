import SwiftUI
import AVKit

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var streamURL: URL?
    @State private var subtitles: [Subtitle] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                }.padding()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang tải phim...").foregroundColor(.gray).font(.caption)
                    }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await fetchMovie() } }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }.frame(maxHeight: .infinity)
                } else if let player = player {
                    CustomVideoPlayer(player: player, subtitles: subtitles)
                        .onAppear { player.play() }
                        .onDisappear { player.pause() }
                }
            }
        }
        .task { await fetchMovie() }
    }
    
    // MARK: - Fetch Movie từ Consumet API
    private func fetchMovie() async {
        isLoading = true; errorMessage = nil
        
        do {
            // Bước 1: Lấy thông tin phim từ Consumet
            let infoURL = "https://api.consumet.org/movies/tmdb/info?id=\(movieId)"
            let infoData = try await fetchJSON(from: infoURL)
            
            // Parse JSON để lấy episode ID
            struct ConsumetInfo: Codable {
                let id: String
                let episodes: [ConsumetEpisode]?
            }
            struct ConsumetEpisode: Codable {
                let id: String
                let title: String
                let number: Int
            }
            
            let info = try JSONDecoder().decode(ConsumetInfo.self, from: infoData)
            
            // Bước 2: Lấy link stream từ episode đầu tiên
            let episodeId = info.episodes?.first?.id ?? info.id
            let watchURL = "https://api.consumet.org/movies/tmdb/watch?episodeId=\(episodeId)&mediaId=\(info.id)"
            let watchData = try await fetchJSON(from: watchURL)
            
            // Parse JSON lấy link stream + phụ đề
            struct ConsumetWatch: Codable {
                let sources: [ConsumetSource]?
                let subtitles: [ConsumetSubtitle]?
            }
            struct ConsumetSource: Codable {
                let url: String
                let quality: String?
                let isM3U8: Bool?
            }
            struct ConsumetSubtitle: Codable {
                let url: String
                let lang: String
            }
            
            let watch = try JSONDecoder().decode(ConsumetWatch.self, from: watchData)
            
            await MainActor.run {
                if let sourceURL = watch.sources?.first?.url,
                   let url = URL(string: sourceURL) {
                    
                    // Tạo AVPlayer với link stream
                    let asset = AVURLAsset(url: url)
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    // Thêm phụ đề
                    if let subs = watch.subtitles {
                        var loadedSubtitles: [Subtitle] = []
                        for sub in subs {
                            if let subURL = URL(string: sub.url) {
                                loadedSubtitles.append(Subtitle(url: subURL, language: sub.lang))
                            }
                        }
                        self.subtitles = loadedSubtitles
                    }
                    
                    self.player = AVPlayer(playerItem: playerItem)
                } else {
                    self.errorMessage = "Không tìm thấy link stream"
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Lỗi API: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Hàm fetch JSON tổng quát
    private func fetchJSON(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL không hợp lệ"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server lỗi"])
        }
        
        return data
    }
}

// MARK: - Subtitle Model
struct Subtitle {
    let url: URL
    let language: String
}

// MARK: - Custom Video Player với phụ đề
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let subtitles: [Subtitle]
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}