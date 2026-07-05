import AVKit

class MusicManager: ObservableObject {
    static let shared = MusicManager()
    private var player: AVPlayer?
    private var fadeTimer: Timer?
    @Published var isPlaying = false
    @Published var isMusicEnabled = true
    
    private let defaultMusicURL = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
    
    init() {
        isMusicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        preload()
    }
    
    func preload() {
        guard let url = URL(string: defaultMusicURL) else { return }
        player = AVPlayer(url: url)
        player?.volume = 0
    }
    
    func play() {
        guard isMusicEnabled else { return }
        stop()
        preload()
        player?.play()
        isPlaying = true
        
        // Fade in 3 giây
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let p = self?.player else { t.invalidate(); return }
            p.volume = min(p.volume + 0.005, 0.15)
            if p.volume >= 0.15 { t.invalidate() }
        }
        
        // Fade out sau 12 giây, rồi phát lại
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            self?.fadeOutAndReplay()
        }
    }
    
    func fadeOutAndReplay() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let p = self?.player else { t.invalidate(); return }
            p.volume = max(p.volume - 0.01, 0)
            if p.volume <= 0 { t.invalidate(); self?.play() }
        }
    }
    
    func stop() {
        fadeTimer?.invalidate()
        player?.pause()
        player = nil
        isPlaying = false
    }
    
    func toggle() {
        isMusicEnabled.toggle()
        UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
        if isMusicEnabled { play() } else { stop() }
    }
}