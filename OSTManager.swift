import AVKit

class OSTManager: ObservableObject {
    static let shared = OSTManager()
    private var player: AVPlayer?
    private var fadeTimer: Timer?
    @Published var isPlaying = false
    @Published var isMusicEnabled = true
    private let apiKey = "AIzaSyA0qjtM4QlHgVRINsnqyiKR6_-1UuKJU1Y"
    
    init() {
        isMusicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
    }
    
    func searchOST(for movieTitle: String) async -> URL? {
        let query = "\(movieTitle) soundtrack theme song".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? movieTitle
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(query)&type=video&maxResults=1&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct YTResponse: Codable { let items: [YTItem]? }
            struct YTItem: Codable { let id: YTId? }
            struct YTId: Codable { let videoId: String? }
            let res = try JSONDecoder().decode(YTResponse.self, from: data)
            if let videoId = res.items?.first?.id?.videoId {
                return URL(string: "https://www.youtube.com/watch?v=\(videoId)")
            }
        } catch { print("OST error: \(error)") }
        return nil
    }
    
    func playOST(for movieTitle: String) async {
        guard isMusicEnabled else { return }
        stop()
        if let url = await searchOST(for: movieTitle) {
            await MainActor.run {
                player = AVPlayer(url: url)
                player?.volume = 0
                player?.play()
                isPlaying = true
                
                fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
                    guard let p = self?.player else { t.invalidate(); return }
                    p.volume = min(p.volume + 0.005, 0.15)
                    if p.volume >= 0.15 { t.invalidate() }
                }
            }
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
        if !isMusicEnabled { stop() }
    }
}