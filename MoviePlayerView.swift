import SwiftUI
import AVKit

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
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player = AVPlayer()
    @State private var selectedSource: MovieSource = .ntl
    @State private var sourceStatus: [MovieSource: Bool] = [:]
    @State private var showSourceMenu = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var volume: Float = 1.0
    @State private var isFullscreen = false
    @State private var controlsTimer: Timer?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                        startControlsTimer()
                    }
                    .onDisappear { player.pause(); controlsTimer?.invalidate() }
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle(); if showControls { startControlsTimer() } } }
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang tải...").foregroundColor(.white.opacity(0.7)).font(.headline)
                    }
                }
                
                if let error = errorMessage, !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                        Text(error).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                        HStack(spacing: 10) {
                            ForEach(MovieSource.allCases, id: \.self) { src in
                                Button { selectedSource = src; loadStream() } label: {
                                    Text(src.rawValue).font(.caption).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedSource == src ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    }
                }
                
                if showControls && !isLoading && errorMessage == nil {
                    // Center skip buttons
                    HStack(spacing: 50) {
                        Button { seek(by: -10) } label: {
                            Image(systemName: "gobackward.10").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                                .padding(16).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                        Button { player.rate == 0 ? player.play() : player.pause() } label: {
                            Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 40, weight: .bold)).foregroundColor(.white)
                                .padding(20).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Button { seek(by: 10) } label: {
                            Image(systemName: "goforward.10").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                                .padding(16).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    
                    // Bottom controls
                    VStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 8) {
                            // Progress bar
                            CustomSlider(value: $currentTime, range: 0...duration) { editing in
                                if !editing { player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600)) }
                            }
                            .frame(height: 6)
                            .padding(.horizontal, 16)
                            
                            HStack {
                                Text(timeString(from: currentTime)).font(.caption).foregroundColor(.white)
                                Spacer()
                                Text(timeString(from: duration)).font(.caption).foregroundColor(.white)
                            }.padding(.horizontal, 16)
                            
                            HStack {
                                Button { showSourceMenu = true } label: {
                                    Text(selectedSource.rawValue).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                                }
                                Spacer()
                                Button { isFullscreen.toggle() } label: {
                                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                        .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                }
                                // Volume slider
                                HStack(spacing: 4) {
                                    Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill").font(.caption).foregroundColor(.white)
                                    Slider(value: $volume, in: 0...1).accentColor(.white).frame(width: 60)
                                        .onChange(of: volume) { player.volume = $0 }
                                }
                            }.padding(.horizontal, 16).padding(.bottom, 20)
                        }
                        .background(
                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                    }
                    
                    // Top bar
                    VStack {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                    .padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                            Spacer()
                            Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                            Spacer()
                            Button { showSourceMenu = true } label: {
                                Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                    .padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                        }.padding(.horizontal, 16).padding(.top, 50)
                        Spacer()
                    }
                }
            }
        }
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .task { loadStream(); setupPlayerObservers() }
        .sheet(isPresented: $showSourceMenu) {
            SourceMenuView(selectedSource: $selectedSource, sourceStatus: $sourceStatus) {
                loadStream()
            }
        }
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil
        Task {
            do {
                let imdbId: String
                if mediaType == "tv", let tvId = movieId as? Int {
                    imdbId = try await APIService.shared.fetchExternalIDs(tvId: tvId) ?? ""
                } else {
                    imdbId = try await fetchMovieIMDbId()
                }
                guard !imdbId.isEmpty else { throw StreamError.noStreamAvailable }
                let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId, season: seasonNumber, episode: episodeNumber)
                let item = AVPlayerItem(url: url)
                await MainActor.run {
                    player.replaceCurrentItem(with: item)
                    sourceStatus[selectedSource] = true
                    isLoading = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; sourceStatus[selectedSource] = false; isLoading = false }
            }
        }
    }
    
    func fetchMovieIMDbId() async throws -> String {
        let (d, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: d).imdb_id else { throw StreamError.noStreamAvailable }
        return id
    }
    
    func setupPlayerObservers() {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            if let d = player.currentItem?.duration, d.isNumeric { duration = d.seconds }
        }
    }
    
    func seek(by seconds: Double) {
        let newTime = max(0, min(currentTime + seconds, duration))
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) { showControls = false }
        }
    }
    
    func timeString(from seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Custom Slider
struct CustomSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.2)
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.touchDown(_:)), for: .touchDown)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.touchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) { uiView.value = Float(value) }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator {
        let parent: CustomSlider
        init(_ parent: CustomSlider) { self.parent = parent }
        @objc func valueChanged(_ sender: UISlider) { parent.value = Double(sender.value) }
        @objc func touchDown(_ sender: UISlider) { parent.onEditingChanged(true) }
        @objc func touchUp(_ sender: UISlider) { parent.onEditingChanged(false) }
    }
}

// MARK: - Source Menu
struct SourceMenuView: View {
    @Binding var selectedSource: MovieSource
    @Binding var sourceStatus: [MovieSource: Bool]
    let onSelect: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Chọn nguồn").font(.headline).foregroundColor(.white)
                ForEach(MovieSource.allCases, id: \.self) { source in
                    Button {
                        selectedSource = source; onSelect(); dismiss()
                    } label: {
                        HStack {
                            Circle().fill(sourceStatus[source] == true ? Color.green : (sourceStatus[source] == false ? Color.red : Color.gray)).frame(width: 10, height: 10)
                            Text(source.rawValue).foregroundColor(.white).font(.system(size: 16, weight: .medium))
                            Spacer()
                            if selectedSource == source { Image(systemName: "checkmark").foregroundColor(.white) }
                        }.padding().background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3)))
                    }
                }
                Button("Đóng") { dismiss() }.foregroundColor(.gray)
            }.padding()
        }
    }
}