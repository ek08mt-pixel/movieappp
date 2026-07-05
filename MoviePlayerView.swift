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
    @State private var volume: Float = 1.0
    @State private var brightness: CGFloat = UIScreen.main.brightness
    @State private var showVolumeSlider = false
    @State private var showBrightnessSlider = false
    @State private var volumeTimer: Timer?
    @State private var brightnessTimer: Timer?
    
    var volumeAsCGFloat: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { CGFloat(volume) },
            set: { volume = Float($0); player.volume = Float($0) }
        )
    }
    
    var brightnessAsCGFloat: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { brightness },
            set: { brightness = $0; UIScreen.main.brightness = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            CustomPlayerVC(player: player)
                .ignoresSafeArea()
                .onAppear {
                    player.play()
                    player.volume = volume
                    resetControlsTimer()
                    setupTimeObserver()
                }
                .onDisappear { player.pause(); controlsTimer?.invalidate() }
                .onTapGesture { toggleControls() }
            
            // Volume slider (right)
            if showVolumeSlider || showControls {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                        VerticalSlider(value: volumeAsCGFloat, range: 0...1) { _ in resetVolumeTimer() }
                            .frame(width: 30, height: 150)
                        Text("\(Int(volume * 100))%").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.trailing, 8)
                    .opacity(showVolumeSlider ? 1 : 0.4)
                }
            }
            
            // Brightness slider (left)
            if showBrightnessSlider || showControls {
                HStack {
                    VStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                        VerticalSlider(value: brightnessAsCGFloat, range: 0...1) { _ in resetBrightnessTimer() }
                            .frame(width: 30, height: 150)
                        Text("\(Int(brightness * 100))%").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.leading, 8)
                    .opacity(showBrightnessSlider ? 1 : 0.4)
                    Spacer()
                }
            }
            
            // Loading
            if isLoading {
                VStack(spacing: 12) { ProgressView().tint(.white).scaleEffect(1.3); Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.6)) }
            }
            
            // Error
            if let err = errorMessage, !isLoading {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.slash").font(.system(size: 36)).foregroundColor(.gray)
                    Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
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
            
            // Main controls
            if showControls && errorMessage == nil {
                HStack(spacing: 56) {
                    Button { seek(-10) } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 20, weight: .light)).foregroundColor(.white.opacity(0.6))
                            .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2)))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                    Button { player.rate == 0 ? player.play() : player.pause() } label: {
                        Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            .padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    Button { seek(10) } label: {
                        Image(systemName: "goforward.10").font(.system(size: 20, weight: .light)).foregroundColor(.white.opacity(0.6))
                            .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2)))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
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
                                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.25)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                            Spacer()
                            Button { if let pipVC = findPiPController() { pipVC.startPictureInPicture() } } label: {
                                Image(systemName: "pip.enter").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                    .padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                            Button { toggleOrientation() } label: {
                                Image(systemName: "rotate.right").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                    .padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                            }
                        }.padding(.horizontal).padding(.bottom, 20)
                    }
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                }
                
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25)))
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        }
                        Spacer()
                        Text(movieTitle).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        Button { showSourceMenu = true } label: {
                            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 14)).foregroundColor(.white)
                                .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25)))
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        }
                    }.padding(.horizontal, 12).padding(.top, 50)
                    Spacer()
                }
            }
        }
        .statusBarHidden()
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let loc = value.location
                    if loc.x > UIScreen.main.bounds.width / 2 + 30 {
                        showVolumeSlider = true
                        let delta = -value.translation.height / 300
                        volume = min(max(volume + Float(delta), 0), 1)
                        player.volume = volume
                    } else if loc.x < 50 {
                        showBrightnessSlider = true
                        let delta = -value.translation.height / 300
                        brightness = min(max(brightness + delta, 0.01), 1)
                        UIScreen.main.brightness = brightness
                    }
                }
                .onEnded { _ in resetVolumeTimer(); resetBrightnessTimer() }
        )
        .task { loadStream() }
        .sheet(isPresented: $showSourceMenu) { SourceMenuView(selectedSource: $selectedSource, sourceStatus: $sourceStatus) { loadStream() } }
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
    
    func seek(_ sec: Double) {
        let newTime = max(0, min(currentTime + sec, duration))
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    func toggleControls() { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }; if showControls { resetControlsTimer() } }
    func resetControlsTimer() { controlsTimer?.invalidate(); controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    func resetVolumeTimer() { volumeTimer?.invalidate(); volumeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.5)) { showVolumeSlider = false } } }
    func resetBrightnessTimer() { brightnessTimer?.invalidate(); brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.5)) { showBrightnessSlider = false } } }
    
    func toggleOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: windowScene.interfaceOrientation == .portrait ? .landscapeRight : .portrait))
    }
    
    func findPiPController() -> AVPictureInPictureController? {
        guard let playerLayer = findPlayerLayer() else { return nil }
        if AVPictureInPictureController.isPictureInPictureSupported() { return AVPictureInPictureController(playerLayer: playerLayer) }
        return nil
    }
    
    func findPlayerLayer() -> AVPlayerLayer? {
        func search(in view: UIView) -> AVPlayerLayer? {
            if let layer = view.layer as? AVPlayerLayer { return layer }
            for subview in view.subviews { if let found = search(in: subview) { return found } }
            return nil
        }
        guard let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.windows.first }).first else { return nil }
        return search(in: window)
    }
    
    func formatTime(_ s: Double) -> String { let m = Int(s) / 60; let sec = Int(s) % 60; return String(format: "%d:%02d", m, sec) }
}

// MARK: - Vertical Slider
struct VerticalSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let onChanged: (CGFloat) -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.7))
                    .frame(height: geo.size.height * (value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    .animation(.interpolatingSpring(stiffness: 200, damping: 15), value: value)
            }
            .gesture(DragGesture().onChanged { gesture in
                let newValue = range.upperBound - (gesture.location.y / geo.size.height) * (range.upperBound - range.lowerBound)
                value = min(max(newValue, range.lowerBound), range.upperBound)
                onChanged(value)
            })
        }
    }
}

// MARK: - Custom Player VC
struct CustomPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController(); vc.player = player; vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect; vc.allowsPictureInPicturePlayback = true; return vc
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}

// MARK: - Source Menu
struct SourceMenuView: View {
    @Binding var selectedSource: MovieSource
    @Binding var sourceStatus: [MovieSource: Bool]
    let onSelect: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Chọn nguồn phát").font(.headline).foregroundColor(.white)
                ForEach(MovieSource.allCases, id: \.self) { src in
                    Button { selectedSource = src; onSelect(); dismiss() } label: {
                        HStack {
                            Circle().fill(sourceStatus[src] == true ? Color.green : (sourceStatus[src] == false ? Color.red : Color.gray)).frame(width: 8, height: 8)
                            Text(src.rawValue).font(.subheadline).foregroundColor(.white)
                            Spacer()
                            if selectedSource == src { Image(systemName: "checkmark").font(.caption).foregroundColor(.white) }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    }
                }
                Button("Đóng") { dismiss() }.font(.caption).foregroundColor(.gray)
            }.padding()
        }
    }
}