import AVKit
import MediaPlayer

class MusicManager: ObservableObject {
    static let shared = MusicManager()
    private var player: AVPlayer?
    private var preloadedPlayer: AVPlayer?
    @Published var isPlaying = false
    @Published var isMusicEnabled = true
    
    private let defaultMusicURL = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
    
    init() {
        preloadMusic()
        isMusicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
    }
    
    func preloadMusic() {
        guard let url = URL(string: defaultMusicURL) else { return }
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        preloadedPlayer = AVPlayer(playerItem: item)
        preloadedPlayer?.volume = 0.15
    }
    
    func play() {
        guard isMusicEnabled else { return }
        stop()
        player = preloadedPlayer
        player?.volume = 0
        player?.play()
        isPlaying = true
        
        // Fade in 2 giây
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let p = self.player else { timer.invalidate(); return }
            p.volume = min(p.volume + 0.0075, 0.15)
            if p.volume >= 0.15 { timer.invalidate() }
        }
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        preloadMusic()
    }
    
    func toggle() {
        isMusicEnabled.toggle()
        UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
        if isMusicEnabled { play() } else { stop() }
    }
}