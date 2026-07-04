import SwiftUI
import AVKit
import MediaPlayer

// ... giữ nguyên phần MovieSource, StreamError, Response Models, MovieStreamService ...

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: MovieSource = .kkphim
    @State private var streamURL: URL?; @State private var isLoading = true
    @State private var errorMessage: String?; @State private var player: AVPlayer?
    @State private var isFullScreen = false
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
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    }
                    Button { Task { await loadStream() } } label: {
                        Text("Thử lại").foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
            } else if let player = player {
                NetflixStylePlayer(player: player, movieTitle: movieTitle, dismiss: { dismiss() })
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
        } catch { await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false } }
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

// MARK: - Netflix Style Player
struct NetflixStylePlayer: View {
    let player: AVPlayer
    let movieTitle: String
    let dismiss: () -> Void
    @State private var showControls = true
    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var showSpeedMenu = false
    @State private var playbackSpeed: Float = 1.0
    @State private var showSubtitleMenu = false
    @State private var selectedSubtitle = "Tắt"
    
    let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    let subtitles = ["Tắt", "Tiếng Việt", "English", "Auto"]
    
    var body: some View {
        ZStack {
            // Video Player
            AVPlayerControllerRepresentable(player: player)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) { showControls.toggle() }
                }
            
            // Overlay Controls (Netflix style)
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        Spacer()
                        Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        
                        Menu {
                            ForEach(speeds, id: \.self) { speed in
                                Button("\(speed, specifier: "%.2f")x") {
                                    playbackSpeed = speed
                                    player.rate = speed
                                }
                            }
                        } label: {
                            Image(systemName: "speedometer")
                                .font(.system(size: 16)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial))
                        }
                        
                        Menu {
                            ForEach(subtitles, id: \.self) { sub in
                                Button(sub) { selectedSubtitle = sub }
                            }
                        } label: {
                            Image(systemName: "captions.bubble")
                                .font(.system(size: 16)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial))
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 50)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 8) {
                        // Progress bar
                        Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                            if !editing {
                                let cmTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                                player.seek(to: cmTime)
                            }
                        }
                        .tint(.red)
                        .padding(.horizontal)
                        
                        HStack {
                            Text(formatTime(currentTime)).font(.caption).foregroundColor(.gray)
                            Spacer()
                            Text(formatTime(duration - currentTime)).font(.caption).foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // Playback controls
                        HStack(spacing: 40) {
                            Button { player.seek(to: CMTime(seconds: max(currentTime - 10, 0), preferredTimescale: 600)) } label: {
                                Image(systemName: "gobackward.10").font(.system(size: 22)).foregroundColor(.white)
                            }
                            
                            Button {
                                if isPlaying { player.pause() } else { player.play() }
                                isPlaying.toggle()
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 40)).foregroundColor(.white)
                            }
                            
                            Button { player.seek(to: CMTime(seconds: min(currentTime + 10, duration), preferredTimescale: 600)) } label: {
                                Image(systemName: "goforward.10").font(.system(size: 22)).foregroundColor(.white)
                            }
                            
                            Button {
                                // Xoay ngang full screen
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                                }
                            } label: {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .font(.system(size: 16)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 30)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
                currentTime = time.seconds
                if let dur = player.currentItem?.duration.seconds, dur.isFinite { duration = dur }
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController()
        c.player = player
        c.showsPlaybackControls = false
        c.videoGravity = .resizeAspect
        c.allowsPictureInPicturePlayback = true
        c.canStartPictureInPictureAutomaticallyFromInline = true
        return c
    }
    
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}