import SwiftUI
import AVKit

// MARK: - PiP Window Manager
class PiPWindowManager: ObservableObject {
    static let shared = PiPWindowManager()
    
    @Published var isActive = false
    @Published var isPlaying = true
    @Published var showFullScreen = false
    
    var player: AVPlayer?
    var movieId: Int?
    var movieTitle = ""
    var mediaType: String?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var posterURL: URL?
    var currentTime: Double = 0
    var duration: Double = 0
    
    var episodeInfo: String? {
        if let s = seasonNumber, let e = episodeNumber {
            return "S\(s):E\(e)"
        }
        return nil
    }
    
    func startPiP(player: AVPlayer, movieId: Int, movieTitle: String, mediaType: String?, seasonNumber: Int?, episodeNumber: Int?, posterURL: URL?, currentTime: Double, duration: Double) {
        self.player = player
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.mediaType = mediaType
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.posterURL = posterURL
        self.currentTime = currentTime
        self.duration = duration
        isPlaying = player.rate > 0
        isActive = true
        showFullScreen = false
    }
    
    func restoreFullScreen() {
        showFullScreen = true
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if player.rate == 0 {
            player.play()
            isPlaying = true
        } else {
            player.pause()
            isPlaying = false
        }
    }
    
    func stopPiP() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isActive = false
        isPlaying = false
        movieId = nil
        movieTitle = ""
        posterURL = nil
        seasonNumber = nil
        episodeNumber = nil
        showFullScreen = false
    }
}

// MARK: - PiP Window View (cửa sổ PiP trong app)
struct PiPWindowView: View {
    @StateObject private var pip = PiPWindowManager.shared
    @State private var position: CGPoint = .zero
    @State private var hasSetInitialPosition = false
    
    var body: some View {
        if pip.isActive {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        pip.restoreFullScreen()
                    } label: {
                        VideoPlayerView(player: pip.player)
                            .frame(width: 150, height: 85)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.6), radius: 10, y: 5)
                            .overlay(
                                // Nút X nhỏ góc trên phải
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button {
                                            pip.stopPiP()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                                .padding(4)
                                        }
                                    }
                                    Spacer()
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                    .padding(.bottom, 80)
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Video Player UIView
struct VideoPlayerView: UIViewRepresentable {
    var player: AVPlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let player = player {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = CGRect(x: 0, y: 0, width: 150, height: 85)
            view.layer.addSublayer(playerLayer)
            
            context.coordinator.playerLayer = playerLayer
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.playerLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}