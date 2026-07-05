import SwiftUI
import AVKit
import MediaPlayer

enum MovieSource: String, CaseIterable {
    case ntl = "NTL"
    case mediafusion = "MediaFusion"
    case yastream = "YasStream"
}

enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link"; case .invalidURL: return "URL lỗi" }
    }
}

class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String, season: Int? = nil, episode: Int? = nil) async throws -> URL {
        switch source {
        case .ntl: return try await fetchNTL(imdbId, season: season, episode: episode)
        case .mediafusion: return try await fetchMediaFusion(imdbId, season: season, episode: episode)
        case .yastream: return try await fetchStremio(imdbId: imdbId, season: season, episode: episode)
        }
    }
    
    private func fetchNTL(_ id: String, season: Int?, episode: Int?) async throws -> URL {
        var path = "/stream/movie/\(id).json"
        if let s = season, let e = episode { path = "/stream/series/\(id):\(s):\(e).json" }
        var r = URLRequest(url: URL(string: "https://tnluannguyen-ntl-stream.hf.space\(path)")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        guard let u = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url,
              let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    private func fetchMediaFusion(_ id: String, season: Int?, episode: Int?) async throws -> URL {
        let cleanId = id.replacingOccurrences(of: "tt", with: "")
        var path = "/stream/movie/\(cleanId).json"
        if let s = season, let e = episode { path = "/stream/series/\(cleanId):\(s):\(e).json" }
        var r = URLRequest(url: URL(string: "https://mediafusion.elfhosted.com\(path)")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        r.setValue("https://mediafusion.elfhosted.com/", forHTTPHeaderField: "Referer")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String?; let type: String?; let infoHash: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        let f = res.streams?.filter { ($0.type == "url" || $0.type == "http") && $0.infoHash == nil } ?? []
        guard let u = f.first?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    private func fetchStremio(imdbId: String, season: Int?, episode: Int?) async throws -> URL {
        let base = "https://yastream.tamthai.de"
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        var path = "/stream/movie/\(cleanId).json"
        if let s = season, let e = episode { path = "/stream/series/\(cleanId):\(s):\(e).json" }
        var r = URLRequest(url: URL(string: "\(base)\(path)")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        r.setValue(base, forHTTPHeaderField: "Referer")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String?; let type: String?; let infoHash: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        let f = res.streams?.filter { ($0.type == "url" || $0.type == "http") && $0.infoHash == nil } ?? []
        guard let u = f.first?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
}

// MARK: - Player View
struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    var mediaType: String? = nil
    var seasonNumber: Int? = nil
    var episodeNumber: Int? = nil
    var posterURL: URL?
    
    @Environment(\.dismiss) var dismiss
    @State private var player = AVPlayer()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSource: MovieSource = .ntl
    @State private var sourceStatus: [MovieSource: Bool] = [:]
    @State private var showSourceMenu = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var isSeeking = false
    @State private var controlsTimer: Timer?
    @State private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var brightness: CGFloat = UIScreen.main.brightness
    @State private var showVolumeSlider = false
    @State private var showBrightnessSlider = false
    @State private var volumeTimer: Timer?
    @State private var brightnessTimer: Timer?
    @State private var volumeDragStart: Float = 0
    @State private var briDragStart: CGFloat = 0
    @State private var pipController: AVPictureInPictureController?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            CustomPlayerVC(player: player, pipController: $pipController)
                .ignoresSafeArea()
                .onAppear {
                    forceLandscape()
                    player.play()
                    player.volume = volume
                    resetControlsTimer()
                    setupTimeObserver()
                }
                .onDisappear {
                    player.pause()
                    controlsTimer?.invalidate()
                }
                .onTapGesture { toggleControls() }
            
            if showVolumeSlider {
                HStack {
                    Spacer()
                    TinySlider(value: CGFloat(volume), icon: volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                        .padding(.trailing, 14)
                        .transition(.opacity)
                }
            }
            
            if showBrightnessSlider {
                HStack {
                    TinySlider(value: brightness, icon: "sun.max.fill")
                        .padding(.leading, 14)
                        .transition(.opacity)
                    Spacer()
                }
            }
            
            Color.clear
                .frame(width: 70)
                .position(x: UIScreen.main.bounds.width - 35, y: UIScreen.main.bounds.height / 2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            if !showVolumeSlider { showVolumeSlider = true; volumeDragStart = volume }
                            volume = min(max(volumeDragStart + Float(-v.translation.height / 100), 0), 1)
                            player.volume = volume
                            resetVolumeTimer()
                        }
                        .onEnded { _ in resetVolumeTimer() }
                )
            
            Color.clear
                .frame(width: 70)
                .position(x: 35, y: UIScreen.main.bounds.height / 2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            if !showBrightnessSlider { showBrightnessSlider = true; briDragStart = brightness }
                            brightness = min(max(briDragStart + (-v.translation.height / 100), 0.01), 1)
                            UIScreen.main.brightness = brightness
                            resetBrightnessTimer()
                        }
                        .onEnded { _ in resetBrightnessTimer() }
                )
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.white).scaleEffect(1.3)
                    Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.6))
                }
            }
            
            if let err = errorMessage, !isLoading {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.slash").font(.system(size: 36)).foregroundColor(.gray)
                    Text(err).font(.caption).foregroundColor(.gray)
                    HStack(spacing: 8) {
                        ForEach(MovieSource.allCases, id: \.self) { src in
                            Button { selectedSource = src; loadStream() } label: {
                                Text(src.rawValue).font(.caption2).foregroundColor(selectedSource == src ? .white : .gray)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Capsule().fill(selectedSource == src ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear)))
                            }
                        }
                    }
                    Button("Thử lại") { loadStream() }.font(.caption).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial))
                }
            }
            
            if showControls && errorMessage == nil {
                HStack(spacing: 64) {
                    Button { seek(-10) } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 20, weight: .light)).foregroundColor(.white.opacity(0.6))
                            .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                    Button { player.rate == 0 ? player.play() : player.pause() } label: {
                        Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            .padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3))).overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    Button { seek(10) } label: {
                        Image(systemName: "goforward.10").font(.system(size: 20, weight: .light)).foregroundColor(.white.opacity(0.6))
                            .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
                
                VStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                            isSeeking = editing
                            if !editing { player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600)) }
                        }.accentColor(.white).padding(.horizontal)
                        HStack {
                            Text(formatTime(currentTime)).font(.caption2).foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(formatTime(duration)).font(.caption2).foregroundColor(.white.opacity(0.7))
                        }.padding(.horizontal)
                        HStack {
                            Button { showSourceMenu = true } label: {
                                Text(selectedSource.rawValue).font(.caption2).foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.25))).overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                            Spacer()
                            Button { pipController?.startPictureInPicture() } label: {
                                Image(systemName: "pip.enter").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                    .padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                            Button { forcePortrait(); dismiss() } label: {
                                Image(systemName: "rotate.right").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                    .padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                        }.padding(.horizontal).padding(.bottom, 20)
                    }.background(LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                }
                
                VStack {
                    HStack {
                        Button { forcePortrait(); dismiss() } label: {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        }
                        Spacer()
                        Text(movieTitle).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        Button { showSourceMenu = true } label: {
                            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 14)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        }
                    }.padding(.horizontal, 12).padding(.top, 50)
                    Spacer()
                }
            }
            
            if showSourceMenu {
                ZStack {
                    Color.clear.ignoresSafeArea().onTapGesture { showSourceMenu = false }
                    VStack(spacing: 8) {
                        Text("nguồn phát").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.8))
                        ForEach(MovieSource.allCases, id: \.self) { src in
                            Button { selectedSource = src; showSourceMenu = false; loadStream() } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(sourceStatus[src] == true ? Color.green : (sourceStatus[src] == false ? Color.red : Color.gray)).frame(width: 5, height: 5)
                                    Text(src.rawValue).font(.system(size: 12, design: .rounded)).foregroundColor(.white)
                                    if selectedSource == src { Image(systemName: "checkmark").font(.system(size: 9)).foregroundColor(.white) }
                                }.padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.4)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            }
                        }
                        Text("© 2026 emmew").font(.system(size: 7, design: .rounded)).foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    .frame(width: 170)
                }
            }
        }
        .statusBarHidden()
        .task { loadStream() }
    }
    
    func forceLandscape() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    }
    
    func forcePortrait() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil
        Task {
            do {
                let imdbId: String
                if mediaType == "tv" { imdbId = try await APIService.shared.fetchExternalIDs(tvId: movieId) ?? "" }
                else { imdbId = try await fetchMovieIMDbId() }
                guard !imdbId.isEmpty else { throw StreamError.noStreamAvailable }
                let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId, season: seasonNumber, episode: episodeNumber)
                let item = AVPlayerItem(url: url)
                await MainActor.run { player.replaceCurrentItem(with: item); sourceStatus[selectedSource] = true; isLoading = false }
            } catch { await MainActor.run { errorMessage = error.localizedDescription; sourceStatus[selectedSource] = false; isLoading = false } }
        }
    }
    
    func fetchMovieIMDbId() async throws -> String {
        let (d, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: d).imdb_id else { throw StreamError.noStreamAvailable }
        return id
    }
    
    func setupTimeObserver() {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            if !isSeeking { currentTime = time.seconds }
            if let d = player.currentItem?.duration, d.isNumeric { duration = d.seconds }
        }
    }
    
    func seek(_ sec: Double) { let t = max(0, min(currentTime + sec, duration)); player.seek(to: CMTime(seconds: t, preferredTimescale: 600)); currentTime = t }
    func toggleControls() { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }; if showControls { resetControlsTimer() } }
    func resetControlsTimer() { controlsTimer?.invalidate(); controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    func resetVolumeTimer() { volumeTimer?.invalidate(); volumeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showVolumeSlider = false } } }
    func resetBrightnessTimer() { brightnessTimer?.invalidate(); brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showBrightnessSlider = false } } }
    
    func formatTime(_ s: Double) -> String { let m = Int(s) / 60; let sec = Int(s) % 60; return String(format: "%d:%02d", m, sec) }
}

// MARK: - Tiny Slider
struct TinySlider: View {
    let value: CGFloat
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
            ZStack(alignment: .bottom) {
                Capsule().fill(.ultraThinMaterial.opacity(0.1)).overlay(Capsule().stroke(Color.white.opacity(0.04), lineWidth: 0.5)).frame(width: 6, height: 60)
                Circle().fill(.white.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1)).frame(width: 16, height: 16).shadow(color: .white.opacity(0.15), radius: 4).offset(y: -value * 52)
            }
        }
    }
}

// MARK: - Custom Player VC
struct CustomPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var pipController: AVPictureInPictureController?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect
        vc.allowsPictureInPicturePlayback = true
        DispatchQueue.main.async {
            if let playerLayer = vc.view.layer.sublayers?.first as? AVPlayerLayer,
               AVPictureInPictureController.isPictureInPictureSupported() {
                pipController = AVPictureInPictureController(playerLayer: playerLayer)
            }
        }
        return vc
    }
    
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}