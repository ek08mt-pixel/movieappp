import SwiftUI
import AVKit
import MediaPlayer
import WebKit

enum StreamError: Error, LocalizedError {
    case noStreamAvailable, wrongEpisode
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link"; case .wrongEpisode: return "Không tìm thấy tập này" }
    }
}

enum MovieSource: String, CaseIterable { case phimapi="Emew 1", nguonc="Emew 2", vsmov="Emew 3", ophim="Emew 4", addon="🧩 Addon", intl="🌐 Quốc tế", onflix="🎬 Onflix" }

struct CastDevice: Identifiable {
    let id = UUID(); let name: String; let icon: String; let type: CastDeviceType
    var isConnected: Bool = false; var signalStrength: Int = 3
}

enum CastDeviceType: String { case airplay = "AirPlay"; case chromecast = "Chromecast"; case smartTV = "Smart TV"; case webReceiver = "Web Receiver" }
enum CastMode: String, CaseIterable { case remote = "Remote Mode"; case dualScreen = "Dual Screen" }

enum VideoGravityMode: CaseIterable {
    case fit, fill, stretch
    var icon: String {
        switch self {
        case .fit: return "arrow.up.left.and.arrow.down.right"
        case .fill: return "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"
        case .stretch: return "rectangle.portrait.arrowtriangle.2.inward"
        }
    }
    mutating func next() { let all = Self.allCases; let idx = all.firstIndex(of: self)!; self = all[(idx + 1) % all.count] }
}

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    var mediaType: String?; @State var seasonNumber: Int?; @State var episodeNumber: Int?; var posterURL: URL?
    var resumeTime: Double = 0
    var initialSource: MovieSource = .phimapi
    @AppStorage("seekSeconds") var seekSeconds: Double = 10
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var appState: AppState
    @State private var player = AVPlayer(); @State private var isLoading = true; @State private var errorMessage: String?
    @State private var selectedSource: MovieSource = .phimapi; @State private var sourceStatus: [MovieSource: Bool] = [:]
    @State private var showSourceMenu = false; @State private var showSettings = false; @State private var showControls = true
    @State private var currentTime: Double = 0; @State private var duration: Double = 1; @State private var isSeeking = false
    @State private var controlsTimer: Timer?; @State private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var brightness: CGFloat = UIScreen.main.brightness; @State private var showVolumeSlider = false; @State private var showBrightnessSlider = false
    @State private var volumeTimer: Timer?; @State private var brightnessTimer: Timer?; @State private var pipController: AVPictureInPictureController?
    @State private var showOverlay = false; @State private var overlayOffset: CGFloat = UIScreen.main.bounds.height
    @State private var similarMovies: [Movie] = []; @State private var seasons: [TVSeason] = []
    @State private var selectedSeasonDetail: TVSeasonDetail?; @State private var selectedSeasonNumber: Int?
    @State private var currentMovie: Movie?; @State private var collectionMovies: [Movie] = []; @State private var selectedMovie: Movie?
    @State private var showNguonCWebView = false; @State private var nguonCEmbedURL: URL?; @State private var nguonCEpisodeName = ""
    @State private var imdbIDCache: String?; @State private var hasStartedPlaying = false; @State private var didResume = false
    @State private var isScreenLocked = false
    @State private var showAudioPopup = false; @State private var autoNextTriggered = false; @State private var showNextEpisodePopup = false
    @State private var phimapiServers: [String] = []
    @State private var selectedServerIndex: Int = UserDefaults.standard.integer(forKey: "lastAudioIndex_\(0)")
    @State private var selectedAudioLabel: String = UserDefaults.standard.string(forKey: "lastAudioLabel_\(0)") ?? "Original"
    @State private var selectedVideoGravity: VideoGravityMode = .fit
    @State private var selectedQuality: String = "Auto"; @State private var currentStreamURL: URL?; @State private var availableQualities: [String] = ["4K", "2880p", "2160p", "1440p", "1080p", "720p", "480p"]
    @State private var showCastSheet = false; @State private var showRemoteControl = false
    @State private var castDeviceName: String = ""; @State private var isCasting = false
    @State private var showEpisodePopup = false
    @State private var showSeekPreview = false
    @State private var seekPreviewImage: UIImage?
    @State private var seekPreviewTime: Double = 0
    
    var episodeInfo: String { if let s = seasonNumber, let e = episodeNumber { return "S\(s):E\(e)" }; return "" }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomPlayerVC(player: player, pipController: $pipController, gravity: selectedVideoGravity).ignoresSafeArea()
                .onAppear {
                    player.play(); player.volume = volume
                    setupTimeObserver(); resetControlsTimer(); loadOverlayData()
                    forceLandscape()
selectedSource = initialSource
                    if let i = UserDefaults.standard.value(forKey: "lastAudioIndex_\(movieId)") as? Int { selectedServerIndex = i }
                    if let l = UserDefaults.standard.string(forKey: "lastAudioLabel_\(movieId)") { selectedAudioLabel = l }
                }
                .onDisappear {
                    saveProgress(); player.pause(); player.replaceCurrentItem(with: nil)
                    controlsTimer?.invalidate(); stopCasting()
                    forcePortraitWithDelay()
                }
                .onTapGesture { if isScreenLocked { if showControls { isScreenLocked = false; showControls = true; resetControlsTimer() } else { showControls = true; resetControlsTimer() } } else if showOverlay { closeOverlay() } else { toggleControls() } }
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
    let lx = v.startLocation.x
    let screenW = UIScreen.main.bounds.width
    let dy = -v.translation.height / 1.5
    if lx < screenW * 0.55 {
        brightness = min(max(brightness + dy / 250, 0.01), 1.0)
        UIScreen.main.brightness = brightness
        showBrightnessSlider = true; showVolumeSlider = false
        resetBrightnessTimer()
    } else {
        volume = min(max(volume + Float(dy / 250), 0), 1.0)
        player.volume = volume
        showVolumeSlider = true; showBrightnessSlider = false
        resetVolumeTimer()
    }
})
                .overlay(
                    HStack {
                        Color.clear.frame(width: UIScreen.main.bounds.width * 0.25).contentShape(Rectangle()).onTapGesture(count: 2) { seek(false) }
                        Spacer()
                        Color.clear.frame(width: UIScreen.main.bounds.width * 0.25).contentShape(Rectangle()).onTapGesture(count: 2) { seek(true) }
                    }
                )
            
           if showVolumeSlider || showBrightnessSlider {
    VStack {
        Capsule()
            .fill(.ultraThinMaterial.opacity(0.5))
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.4))
            .frame(width: 120, height: 32)
            .overlay(
                HStack(spacing: 6) {
                    if showBrightnessSlider {
                        Image(systemName: "sun.max.fill").font(.system(size: 11)).foregroundColor(.yellow)
                        RoundedRectangle(cornerRadius: 2).fill(.yellow.opacity(0.6)).frame(width: 3, height: max(2, 22 * brightness)).animation(.easeInOut(duration: 0.15), value: brightness)
                    } else if showVolumeSlider {
                        Image(systemName: volume > 0.5 ? "speaker.wave.3.fill" : "speaker.wave.1.fill").font(.system(size: 11)).foregroundColor(.white)
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.6)).frame(width: 3, height: max(2, 22 * CGFloat(volume))).animation(.easeInOut(duration: 0.15), value: volume)
                    }
                    Text(showBrightnessSlider ? "\(Int(brightness * 100))%" : "\(Int(volume * 100))%").font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(.white)
                }.padding(.horizontal, 10)
            ).padding(.top, 75)
        Spacer()
    }
}
            
            if isLoading { VStack(spacing: 16) { ProgressView().tint(.white).scaleEffect(1.5); Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.7)); Button { dismiss() } label: { Text("Quay lại").font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)) } } }
            if let err = errorMessage, !isLoading { VStack(spacing: 16) { Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray); Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center); HStack(spacing: 10) { ForEach(MovieSource.allCases, id: \.self) { s in Button { selectedSource = s; loadStream() } label: { Text(s.rawValue).font(.caption2).foregroundColor(selectedSource == s ? .white : .gray).padding(.horizontal, 10).padding(.vertical, 6).background(Capsule().fill(selectedSource == s ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))) } } }; HStack(spacing: 16) { Button("Thử lại") { loadStream() }.font(.caption).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)); Button("Quay lại") { dismiss() }.font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)) } } }
            
            if showControls && errorMessage == nil && !isLoading && !showOverlay && !showSourceMenu && !showSettings && !showAudioPopup {
                HStack(spacing: 50) {
                    Button { prevEpisode() } label: { Image(systemName: "backward.end.fill").font(.system(size: 26)).foregroundColor(.white.opacity(0.9)).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.25))) }
                    Button { player.rate == 0 ? player.play() : player.pause() } label: { Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 44, weight: .bold)).foregroundColor(.white).padding(20).background(Circle().fill(.ultraThinMaterial.opacity(0.3))) }
                    Button { nextEpisode() } label: { Image(systemName: "forward.end.fill").font(.system(size: 26)).foregroundColor(.white.opacity(0.9)).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.25))) }
                }
                if showSeekPreview { Text(formatTime(seekPreviewTime)).font(.system(size: 12, design: .monospaced)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5).background(Capsule().fill(.ultraThinMaterial.opacity(0.7))).offset(y: -60) }
                VStack { Spacer()
                    VStack(spacing: 2) {
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.15)).frame(height: 5)
            Capsule().fill(.white.opacity(0.8)).frame(width: max(5, geo.size.width * CGFloat(min(max(currentTime / max(duration, 1), 0), 1))), height: 5)
        }.frame(height: 20).contentShape(Rectangle()).highPriorityGesture(DragGesture(minimumDistance: 0).onChanged { v in
            let r = min(max(v.location.x / geo.size.width, 0), 1)
            currentTime = r * duration; isSeeking = true; seekPreviewTime = currentTime; showSeekPreview = true
        }.onEnded { _ in player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600)); isSeeking = false; showSeekPreview = false })
    }.frame(height: 20)
    HStack { Text(formatTime(currentTime)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5)); Spacer(); Text(formatTime(duration)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }
}.padding(.horizontal, UIScreen.main.bounds.width * 0.15)
                    HStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Button { isScreenLocked.toggle(); showControls = !isScreenLocked } label: { Image(systemName: isScreenLocked ? "lock.fill" : "lock.open.fill").font(.system(size: 17)).foregroundColor(isScreenLocked ? .white : .white.opacity(0.4)) }
                            Button { cycleAspect() } label: { Image(systemName: selectedVideoGravity.icon).font(.system(size: 17)).foregroundColor(.white.opacity(0.9)) }
                            Button { showAudioPopup = true } label: { Image(systemName: "waveform").font(.system(size: 17)).foregroundColor(.white.opacity(0.9)) }
                        }.padding(.horizontal, 14).padding(.vertical, 7).padding(.leading, 8).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.6))).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 0.3))
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, UIScreen.main.bounds.height * 0.06)
                }
                VStack { HStack(spacing: 8) { Button { saveProgress(); dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)) }; Button { showEpisodePopup = true } label: { VStack(alignment: .leading, spacing: 0) { Text(movieTitle).font(.system(size: 14, weight: .medium)).foregroundColor(.white).lineLimit(1); if !episodeInfo.isEmpty { Text(episodeInfo).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) } } }; Spacer()
                    HStack(spacing: 8) { Button { showCastSheet = true } label: { Image(systemName: "airplayvideo").font(.system(size: 14)).foregroundColor(isCasting ? .blue : .white.opacity(0.8)).padding(8).background(Circle().fill(isCasting ? AnyShapeStyle(Color.blue.opacity(0.3)) : AnyShapeStyle(.ultraThinMaterial.opacity(0.25)))).overlay(Circle().stroke(isCasting ? Color.blue.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.5)) }; Button { showSettings = true } label: { Image(systemName: "gearshape.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)) } } }.padding(.horizontal, 12).padding(.top, 56); Spacer() }
                if isCasting { VStack { Spacer(); HStack { Spacer(); HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 6, height: 6); Text("Đang phát trên \(castDeviceName)").font(.system(size: 10)).foregroundColor(.white.opacity(0.7)) }.padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(.ultraThinMaterial.opacity(0.5))).padding(.trailing, 20).padding(.bottom, 100) } } }
            }
            if showEpisodePopup {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { showEpisodePopup = false }
                VStack(spacing: 10) {
                    HStack { Button { showEpisodePopup = false } label: { Image(systemName: "chevron.left").font(.system(size: 14)).foregroundColor(.white) }; Spacer(); Text("Chọn tập").font(.system(size: 13, weight: .bold)).foregroundColor(.white); Spacer(); Circle().fill(.clear).frame(width: 28) }
                    if let detail = selectedSeasonDetail {
                        ScrollView { LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) { ForEach(detail.episodes) { ep in Button { loadStream(season: ep.seasonNumber, episode: ep.episodeNumber); showEpisodePopup = false } label: { Text("\(ep.episodeNumber)").font(.system(size: 12, weight: .medium)).foregroundColor(ep.episodeNumber == (episodeNumber ?? 1) ? .black : .white).frame(height: 36).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 8).fill(ep.episodeNumber == (episodeNumber ?? 1) ? .white : Color.white.opacity(0.1))) } } } }.frame(maxHeight: UIScreen.main.bounds.height * 0.45) }
                }.padding(14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 0.4)).frame(width: 240)
            }
            if showNextEpisodePopup { }
            if showOverlay { youtubeOverlay }
            if showSourceMenu || showSettings || showAudioPopup { Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { showSourceMenu = false; showSettings = false; showAudioPopup = false }; if showSourceMenu { sourcePopup }; if showSettings { settingsPopup }; if showAudioPopup { audioPopup } }
        }
        .statusBarHidden()
        .task { loadStream() }
        .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        .fullScreenCover(isPresented: $showNguonCWebView) { if let url = nguonCEmbedURL { NguonCPlayerView(embedURL: url, episodeName: nguonCEpisodeName) } }
        .fullScreenCover(isPresented: $showRemoteControl) { CastRemoteView(movieTitle: movieTitle, episodeInfo: episodeInfo, posterURL: posterURL, castDeviceName: castDeviceName, player: player, currentTime: $currentTime, duration: $duration, isCasting: $isCasting) }
        .sheet(isPresented: $showCastSheet) { CastSheetView(showRemote: $showRemoteControl, castDeviceName: $castDeviceName, isCasting: $isCasting, player: player).presentationDetents([.medium, .large]).presentationDragIndicator(.hidden) }
    }
    
    func forceLandscape() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) } }
    func forcePortraitWithDelay() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) } }; DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) } } }
    func cycleAspect() { selectedVideoGravity.next() }
    func detectQuality(from url: URL) -> String { let s = url.absoluteString.lowercased(); if s.contains("4k") || s.contains("2160") { return "4K" }; if s.contains("2880") { return "2880p" }; if s.contains("1440") { return "1440p" }; if s.contains("1080") { return "1080p" }; if s.contains("720") { return "720p" }; if s.contains("480") { return "480p" }; return "Auto" }
    func applyQuality(_ q: String) { guard let u = currentStreamURL else { return }; selectedQuality = q; let nu = qualityURL(from: u, quality: q); let st = currentTime; let i = AVPlayerItem(url: nu); player.replaceCurrentItem(with: i); player.seek(to: CMTime(seconds: st, preferredTimescale: 600)) { _ in player.play() } }
    func qualityURL(from u: URL, quality: String) -> URL { guard quality != "Auto" else { return u }; let m = ["4K": "2160", "2880p": "2880", "2160p": "2160", "1440p": "1440", "1080p": "1080", "720p": "720", "480p": "480"]; guard let t = m[quality] else { return u }; for q in ["2160", "2880", "1440", "1080", "720", "480", "4k"] { if u.absoluteString.lowercased().contains(q) { return URL(string: u.absoluteString.replacingOccurrences(of: q, with: t, options: .caseInsensitive)) ?? u } }; return u }
    func stopCasting() { isCasting = false; castDeviceName = ""; EmmewCastManager.shared.stopCasting() }
    func closeOverlay() { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { overlayOffset = UIScreen.main.bounds.height }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showOverlay = false } }
    func openMovie(_ movie: Movie) { closeOverlay(); player.pause(); forcePortraitWithDelay(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { selectedMovie = movie } }
    func prevEpisode() { guard let ep = episodeNumber, ep > 1 else { return }; autoNextTriggered = false; showNextEpisodePopup = false; loadStream(season: seasonNumber, episode: ep - 1) }
    func nextEpisode() { guard let ep = episodeNumber, let detail = selectedSeasonDetail, ep < detail.episodes.count else { return }; showNextEpisodePopup = false; autoNextTriggered = true; loadStream(season: seasonNumber, episode: ep + 1); DispatchQueue.main.asyncAfter(deadline: .now() + 5) { autoNextTriggered = false } }
    func loadOverlayData() { Task { similarMovies = (try? await APIService.shared.similar(movieId: movieId, mediaType: mediaType)) ?? []; if mediaType == "tv" { seasons = (try? await APIService.shared.fetchTVSeasons(tvId: movieId)) ?? []; if let s = seasonNumber { selectedSeasonNumber = s; selectedSeasonDetail = try? await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: s) } }; if let detail = try? await APIService.shared.movieDetail(movieId: movieId), let cid = detail.belongsToCollection?.id, let col = try? await APIService.shared.collectionDetail(collectionId: cid) { collectionMovies = col.parts }; currentMovie = Movie(id: movieId, title: movieTitle, overview: "", posterPath: posterURL?.absoluteString ?? "", backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: mediaType) } }
    func loadStream(season: Int? = nil, episode: Int? = nil, resumeAt: Double? = nil) { if let s = season { seasonNumber = s }; if let e = episode { episodeNumber = e }; let ep = episodeNumber ?? 1; let s = seasonNumber; imdbIDCache = nil; autoNextTriggered = false; showNextEpisodePopup = false; if mediaType == "tv" || s != nil { selectedSeasonNumber = s; Task { selectedSeasonDetail = try? await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: s ?? 1) } }; isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil; Task { do { let imdbID = try await fetchIMDB(); switch selectedSource { case .phimapi: let result = try await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movieId, title: movieTitle, mediaType: mediaType, season: s, episode: ep, serverIndex: selectedServerIndex) { c.resume(with: $0) } }; await MainActor.run { phimapiServers = result.1; currentStreamURL = result.0; selectedQuality = detectQuality(from: result.0); let item = AVPlayerItem(url: result.0); player.replaceCurrentItem(with: item); if let rt = resumeAt { player.seek(to: CMTime(seconds: rt, preferredTimescale: 600)) { _ in player.play() } } else { player.play() }; hasStartedPlaying = true; sourceStatus[.phimapi] = true; isLoading = false; tryResume() }; saveHistory(); case .nguonc: let url = try await withCheckedThrowingContinuation { c in NguonCService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }; await MainActor.run { nguonCEmbedURL = url; nguonCEpisodeName = "\(movieTitle) - Tập \(ep)"; isLoading = false; sourceStatus[.nguonc] = true; hasStartedPlaying = true; showNguonCWebView = true }; case .vsmov: let url = try await withCheckedThrowingContinuation { c in VSMOVService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }; await MainActor.run { currentStreamURL = url; selectedQuality = detectQuality(from: url); player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.vsmov] = true; isLoading = false; tryResume() }; saveHistory(); case .ophim: let url = try await withCheckedThrowingContinuation { c in OphimService.shared.fetchStream(title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }; await MainActor.run { currentStreamURL = url; selectedQuality = detectQuality(from: url); player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.ophim] = true; isLoading = false; tryResume() }; saveHistory()
case .addon: let streamURL = try await AddonManager.shared.fetchBestStream(metaId: imdbID, title: movieTitle, mediaType: mediaType); guard let url = streamURL else { throw StreamError.noStreamAvailable }; await MainActor.run { currentStreamURL = url; selectedQuality = detectQuality(from: url); player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.addon] = true; isLoading = false; tryResume() }; saveHistory()
case .intl: InternationalEmbedService.shared.fetchStream(imdbID: imdbID) { result in DispatchQueue.main.async { switch result { case .success(let url): currentStreamURL = url; selectedQuality = detectQuality(from: url); player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.intl] = true; isLoading = false; tryResume(); saveHistory() case .failure(let error): sourceStatus[.intl] = false; errorMessage = error.localizedDescription; isLoading = false } } }
case .onflix: let slug = movieTitle.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "!", with: "").replacingOccurrences(of: "?", with: ""); OnflixService.shared.fetchStream(title: movieTitle, slug: slug) { result in DispatchQueue.main.async { switch result { case .success(let url): currentStreamURL = url; selectedQuality = detectQuality(from: url); player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.onflix] = true; isLoading = false; tryResume(); saveHistory() case .failure(let error): sourceStatus[.onflix] = false; errorMessage = error.localizedDescription; isLoading = false } } }
} } catch { await MainActor.run { sourceStatus[selectedSource] = false; errorMessage = error.localizedDescription; isLoading = false } } } }
    func tryResume() { guard !didResume, resumeTime > 0 else { return }; didResume = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { player.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 600)) } }
    func fetchIMDB() async throws -> String { if let c = imdbIDCache { return c }; var id: String?; if mediaType == "tv" || seasonNumber != nil { id = try? await APIService.shared.fetchExternalIDs(tvId: movieId) }; if id == nil || id?.isEmpty == true { let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E: Codable { let imdb_id: String? }; id = try? JSONDecoder().decode(E.self, from: data).imdb_id }; guard let f = id, !f.isEmpty else { throw StreamError.noStreamAvailable }; imdbIDCache = f; return f }
    func saveProgress() { 
    guard hasStartedPlaying, currentTime > 0 else { return }
    appState.updateProgress(WatchProgress(movieId: movieId, movieTitle: movieTitle, posterPath: posterURL?.absoluteString, mediaType: mediaType, season: seasonNumber, episode: episodeNumber, currentTime: currentTime, duration: max(duration, 1), lastWatched: Date(), source: selectedSource.rawValue))
}
    func saveHistory() { let m = Movie(id: movieId, title: movieTitle, overview: "", posterPath: posterURL?.absoluteString ?? "", backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: mediaType); appState.watchHistory.removeAll { $0.id == movieId }; appState.watchHistory.insert(m, at: 0); if appState.watchHistory.count > 50 { appState.watchHistory.removeLast() }; appState.save() }
    func setupTimeObserver() { player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { t in if !isSeeking { currentTime = t.seconds }; if let d = player.currentItem?.duration, d.isNumeric { duration = d.seconds } } }
    func seek(_ forward: Bool) { let s = forward ? seekSeconds : -seekSeconds; let t = max(0, min(currentTime + s, duration)); player.seek(to: CMTime(seconds: t, preferredTimescale: 600)); currentTime = t }
    func toggleControls() { if isScreenLocked { showControls = true; resetControlsTimer(); return }; withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }; if showControls { resetControlsTimer() } }
    func resetControlsTimer() { controlsTimer?.invalidate(); controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    func resetVolumeTimer() { volumeTimer?.invalidate(); volumeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in showVolumeSlider = false } }
    func resetBrightnessTimer() { brightnessTimer?.invalidate(); brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in showBrightnessSlider = false } }
    func toggleOrientation() { guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }; ws.requestGeometryUpdate(.iOS(interfaceOrientations: ws.interfaceOrientation.isLandscape ? .portrait : .landscapeRight)) }
    func formatTime(_ s: Double) -> String { let m = Int(s) / 60; let sec = Int(s) % 60; return String(format: "%d:%02d", m, sec) }
    
    @ViewBuilder func episodeRow(detail: TVSeasonDetail) -> some View { VStack(alignment: .leading, spacing: 6) { Text("Tập \(episodeNumber ?? 1)/\(detail.episodes.count)").font(.caption).foregroundColor(.white.opacity(0.6)); LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) { ForEach(detail.episodes) { ep in Button { loadStream(season: ep.seasonNumber, episode: ep.episodeNumber); closeOverlay() } label: { Text("\(ep.episodeNumber)").font(.system(size: 11, weight: .medium)).foregroundColor(ep.episodeNumber == (episodeNumber ?? 1) ? .black : .white).frame(height: 36).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 10).fill(ep.episodeNumber == (episodeNumber ?? 1) ? .white : Color.white.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.15), lineWidth: 0.5))) } } } } }
    var youtubeOverlay: some View { ZStack(alignment: .bottom) { Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { closeOverlay() }; VStack(spacing: 0) { Capsule().fill(.white.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 10); ScrollView { VStack(alignment: .leading, spacing: 16) { if let movie = currentMovie { VStack(alignment: .leading, spacing: 8) { Text("Đang xem").font(.title3).fontWeight(.bold).foregroundColor(.white); movieInfoCard }; if !collectionMovies.isEmpty { collectionRow }; if !seasons.isEmpty { seasonRow } }; if !similarMovies.isEmpty { similarRow } }.padding() }.clipped() }.frame(height: UIScreen.main.bounds.height * 0.55).background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.7))).offset(y: overlayOffset) } }
    var movieInfoCard: some View { Group { if let movie = currentMovie { HStack(spacing: 12) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2 / 3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 10)); VStack(alignment: .leading, spacing: 4) { Text(movie.title).font(.headline).foregroundColor(.white).lineLimit(2); if !seasons.isEmpty { Text("\(seasons.count) mùa").font(.caption).foregroundColor(.gray) }; if !collectionMovies.isEmpty { Text("\(collectionMovies.count) phần").font(.caption).foregroundColor(.gray) }; if let detail = selectedSeasonDetail { episodeRow(detail: detail) } }; Spacer() }.padding(10).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3))) } } }
    var collectionRow: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(collectionMovies.filter { $0.id != movieId }) { part in Button { openMovie(part) } label: { VStack(spacing: 4) { CachedAsyncImage(url: part.posterURL).aspectRatio(2 / 3, contentMode: .fill).frame(width: 70, height: 105).clipShape(RoundedRectangle(cornerRadius: 8)); Text(part.title).font(.system(size: 9)).foregroundColor(.white).lineLimit(2).frame(width: 70) } } } } } }
    var seasonRow: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 6) { ForEach(seasons) { season in Button { selectedSeasonNumber = season.seasonNumber; Task { selectedSeasonDetail = try? await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: season.seasonNumber) } } label: { Text(season.name).font(.caption).fontWeight(selectedSeasonNumber == season.seasonNumber ? .bold : .regular).foregroundColor(selectedSeasonNumber == season.seasonNumber ? .white : .gray).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(selectedSeasonNumber == season.seasonNumber ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5)) : AnyShapeStyle(.ultraThinMaterial.opacity(0.2)))) } } } } }
    var similarRow: some View { VStack(alignment: .leading, spacing: 8) { Text("Phim tương tự").font(.title3).fontWeight(.bold).foregroundColor(.white); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(similarMovies.prefix(15)) { movie in Button { openMovie(movie) } label: { VStack(spacing: 4) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2 / 3, contentMode: .fill).frame(width: 90, height: 135).clipShape(RoundedRectangle(cornerRadius: 10)); Text(movie.title).font(.system(size: 9)).foregroundColor(.white).lineLimit(2).frame(width: 90) } } } } } } }
    var sourcePopup: some View { VStack(spacing: 10) { Text("Nguồn phát").font(.system(size: 14, weight: .bold)).foregroundColor(.white); if !phimapiServers.isEmpty && selectedSource == .phimapi { Picker("Server", selection: $selectedServerIndex) { ForEach(0..<phimapiServers.count, id: \.self) { i in Text(phimapiServers[i]).tag(i) } }.pickerStyle(.segmented).onChange(of: selectedServerIndex) { _ in let st = currentTime; loadStream(season: seasonNumber, episode: episodeNumber, resumeAt: st) }.padding(.bottom, 8) }; ForEach(MovieSource.allCases, id: \.self) { src in Button { selectedSource = src; showSourceMenu = false; loadStream() } label: { HStack(spacing: 8) { Circle().fill(sourceStatus[src] == true ? .green : sourceStatus[src] == false ? .red : .gray).frame(width: 6, height: 6); Text(src.rawValue).font(.system(size: 13)).foregroundColor(.white); Spacer(); if selectedSource == src { Image(systemName: "checkmark").font(.system(size: 11)).foregroundColor(.white) } }.padding(.horizontal, 14).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(selectedSource == src ? .white.opacity(0.15) : .white.opacity(0.05))) } } }.padding(18).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 0.5)).frame(width: 240) }
    var settingsPopup: some View { VStack(spacing: 8) { Text("Cài đặt").font(.system(size: 13, weight: .bold)).foregroundColor(.white); Text("Nguồn phát").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)); HStack(spacing: 6) { ForEach(MovieSource.allCases, id: \.self) { src in Button { selectedSource = src; showSettings = false; loadStream() } label: { Text(src.rawValue).font(.system(size: 10)).foregroundColor(selectedSource == src ? .white : .white.opacity(0.5)).padding(.horizontal, 8).padding(.vertical, 5).background(Capsule().fill(selectedSource == src ? .white.opacity(0.15) : .clear)) } } }; Divider().background(Color.white.opacity(0.1)); Text("Chất lượng").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)); HStack(spacing: 4) { ForEach(availableQualities, id: \.self) { q in Button { applyQuality(q); showSettings = false } label: { Text(q).font(.system(size: 9)).foregroundColor(selectedQuality == q ? .white : .white.opacity(0.5)).fixedSize(horizontal: true, vertical: false).padding(.horizontal, 6).padding(.vertical, 4).background(Capsule().fill(selectedQuality == q ? .white.opacity(0.15) : .clear)) } } }; Divider().background(Color.white.opacity(0.1)); HStack(spacing: 6) { ForEach(["0.5x", "1.0x", "1.5x", "2.0x"], id: \.self) { s in Button { player.rate = Float(s.replacingOccurrences(of: "x", with: "")) ?? 1.0; showSettings = false } label: { Text(s).font(.system(size: 10)).foregroundColor(.white.opacity(0.7)).padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(.white.opacity(0.1))) } } } }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.4)).frame(width: 220) }
    var audioPopup: some View { 
    VStack(spacing: 10) { 
        Text("Âm thanh").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
        Text("Có \(phimapiServers.count) server").font(.system(size: 10)).foregroundColor(.gray)
        ForEach(Array(phimapiServers.enumerated()), id: \.offset) { idx, name in
            Text("\(idx): \(name)").font(.system(size: 10)).foregroundColor(.gray)
        }
        ForEach(audioOptions(), id: \.self) { aud in 
            Button { selectAudio(aud) } label: { 
                Text(aud).font(.system(size: 13))
                    .foregroundColor(aud == selectedAudioLabel ? .black : .white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(aud == selectedAudioLabel ? .white : Color.white.opacity(0.08)))
            } 
        } 
    }.padding(18).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 0.5)).frame(width: 260) 
}
    func audioOptions() -> [String] { 
    if selectedSource == .phimapi && !phimapiServers.isEmpty { return phimapiServers }
    return ["Vietsub", "Lồng Tiếng", "Thuyết minh"] 
}

func selectAudio(_ label: String) { 
    selectedAudioLabel = label
    UserDefaults.standard.set(label, forKey: "lastAudioLabel_\(movieId)")
    if selectedSource == .phimapi { 
        let idx = audioOptions().firstIndex(of: label) ?? 0
        selectedServerIndex = idx
        UserDefaults.standard.set(idx, forKey: "lastAudioIndex_\(movieId)")
        UserDefaults.standard.removeObject(forKey: "phimapi_stream_cache")
        let st = currentTime
        loadStream(season: seasonNumber, episode: episodeNumber, resumeAt: st) 
    }
    showAudioPopup = false 
}
}
struct CastSheetView: View {
    @Binding var showRemote: Bool; @Binding var castDeviceName: String; @Binding var isCasting: Bool
    let player: AVPlayer; @Environment(\.dismiss) var dismiss
    @State private var devices: [CastDevice] = []; @State private var selectedDevice: CastDevice?; @State private var selectedMode: CastMode = .remote; @State private var isScanning = true
    var body: some View { ZStack(alignment: .bottom) { Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { dismiss() }; VStack(spacing: 0) { Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 5).padding(.top, 10); HStack { Text("Phát đến thiết bị").font(.system(size: 18, weight: .bold)).foregroundColor(.white); Spacer(); if isScanning { ProgressView().tint(.white).scaleEffect(0.8) }; Button { scanDevices() } label: { Image(systemName: "arrow.clockwise").font(.system(size: 14)).foregroundColor(.white.opacity(0.7)).padding(8).background(Circle().fill(.white.opacity(0.1))) } }.padding(.horizontal, 20).padding(.top, 12); ScrollView { VStack(spacing: 10) { ForEach(devices) { device in deviceCard(device) } }.padding(.horizontal, 20).padding(.top, 12) }.frame(maxHeight: 280); if selectedDevice != nil { VStack(spacing: 10) { Divider().background(Color.white.opacity(0.15)).padding(.horizontal, 20); Text("Chế độ").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 8); HStack(spacing: 12) { ForEach(CastMode.allCases, id: \.self) { mode in modeButton(mode) } }.padding(.horizontal, 20); Button { startCasting() } label: { HStack(spacing: 8) { Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 14)); Text("Bắt đầu phát").font(.system(size: 15, weight: .semibold)) }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 14)) }.padding(.horizontal, 20).padding(.bottom, 30) } }; Spacer().frame(height: 20) }.background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial.opacity(0.98)).overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.12), lineWidth: 0.5))).shadow(color: .black.opacity(0.5), radius: 30, y: -10) }.onAppear { scanDevices() } }
    func deviceCard(_ device: CastDevice) -> some View { Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDevice = selectedDevice?.id == device.id ? nil : device } } label: { HStack(spacing: 14) { ZStack { Circle().fill(.white.opacity(selectedDevice?.id == device.id ? 0.15 : 0.08)).frame(width: 46, height: 46); Image(systemName: device.icon).font(.system(size: 18)).foregroundColor(selectedDevice?.id == device.id ? .white : .white.opacity(0.7)) }.overlay(Circle().stroke(selectedDevice?.id == device.id ? Color.blue.opacity(0.6) : .white.opacity(0.08), lineWidth: selectedDevice?.id == device.id ? 2 : 1)); VStack(alignment: .leading, spacing: 2) { Text(device.name).font(.system(size: 14, weight: .medium)).foregroundColor(.white); HStack(spacing: 4) { Text(device.type.rawValue).font(.system(size: 11)).foregroundColor(.white.opacity(0.5)); HStack(spacing: 2) { ForEach(0..<4, id: \.self) { i in Circle().fill(i < device.signalStrength ? Color.green.opacity(0.7) : .white.opacity(0.15)).frame(width: 3, height: 3) } } } }; Spacer(); if selectedDevice?.id == device.id { Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundColor(.blue).transition(.scale.combined(with: .opacity)) } }.padding(12).background(RoundedRectangle(cornerRadius: 14).fill(selectedDevice?.id == device.id ? .white.opacity(0.08) : .white.opacity(0.03)).overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedDevice?.id == device.id ? Color.blue.opacity(0.3) : .white.opacity(0.05), lineWidth: 0.5))) } }
    func modeButton(_ mode: CastMode) -> some View { Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedMode = mode } } label: { VStack(spacing: 6) { Image(systemName: mode == .remote ? "iphone.gen1" : "rectangle.split.2x1").font(.system(size: 20)); Text(mode.rawValue).font(.system(size: 11, weight: .medium)) }.foregroundColor(selectedMode == mode ? .white : .white.opacity(0.5)).frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 12).fill(selectedMode == mode ? Color.blue.opacity(0.3) : .white.opacity(0.05)).overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedMode == mode ? Color.blue.opacity(0.4) : .white.opacity(0.08), lineWidth: 0.5))) } }
    func scanDevices() { isScanning = true; devices.removeAll(); let routeDetector = AVRouteDetector(); routeDetector.isRouteDetectionEnabled = true; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { var foundDevices: [CastDevice] = []; if routeDetector.multipleRoutesDetected { foundDevices.append(CastDevice(name: "Apple TV / Smart TV", icon: "appletv.fill", type: .airplay, signalStrength: 4)) }; foundDevices.append(CastDevice(name: "AirPlay & Bluetooth", icon: "airplayaudio", type: .airplay, signalStrength: 4)); foundDevices.append(CastDevice(name: "MacBook / iMac", icon: "laptopcomputer", type: .airplay, signalStrength: 4)); foundDevices.append(CastDevice(name: "Chromecast / Android TV", icon: "rectangle.connected.to.line.below", type: .chromecast, signalStrength: 4)); foundDevices.append(CastDevice(name: "Xiaomi / Tanix TV Box", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 3)); foundDevices.append(CastDevice(name: "Windows / Linux PC", icon: "desktopcomputer", type: .webReceiver, signalStrength: 3)); foundDevices.append(CastDevice(name: "Xbox / PlayStation", icon: "gamecontroller.fill", type: .webReceiver, signalStrength: 3)); foundDevices.append(CastDevice(name: "Android Phone / Tablet", icon: "smartphone", type: .webReceiver, signalStrength: 3)); foundDevices.append(CastDevice(name: "Máy chiếu", icon: "rectangle.fill.badge.person.crop", type: .smartTV, signalStrength: 3)); self.devices = foundDevices; self.isScanning = false } }
    func startCasting() { guard let device = selectedDevice else { return }; castDeviceName = device.name; isCasting = true; player.allowsExternalPlayback = true; player.usesExternalPlaybackWhileExternalScreenIsActive = true; EmmewCastManager.shared.startCasting(with: player, deviceName: device.name); dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showRemote = true } }
}

struct CastRemoteView: View {
    let movieTitle: String; let episodeInfo: String; var posterURL: URL?; let castDeviceName: String
    let player: AVPlayer; @Binding var currentTime: Double; @Binding var duration: Double; @Binding var isCasting: Bool
    @Environment(\.dismiss) var dismiss
    @AppStorage("seekSeconds") var seekSeconds: Double = 10
    @State private var isPlaying = true; @State private var selectedAudio = "Vietsub"; @State private var showAudioMenu = false; @State private var showInfo = false
    var body: some View { ZStack { LinearGradient(colors: [Color(white: 0.12), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea().overlay(.ultraThinMaterial.opacity(0.05)); VStack(spacing: 0) { HStack { HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 6, height: 6).overlay(Circle().fill(Color.green.opacity(0.4)).frame(width: 12, height: 12).scaleEffect(isPlaying ? 1.5 : 1).opacity(isPlaying ? 0.6 : 0).animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPlaying)); Text("Đang phát trên \(castDeviceName)").font(.system(size: 11)).foregroundColor(.white.opacity(0.6)) }; Spacer(); Button { stopCasting() } label: { Text("Ngắt kết nối").font(.system(size: 11, weight: .medium)).foregroundColor(.red.opacity(0.8)).padding(.horizontal, 12).padding(.vertical, 5).background(Capsule().fill(.white.opacity(0.1))) } }.padding(.horizontal, 20).padding(.top, 50); Spacer()
        VStack(spacing: 16) { if let url = posterURL { CachedAsyncImage(url: url).aspectRatio(2 / 3, contentMode: .fit).frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .white.opacity(0.15), radius: 20, y: -5).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.15), lineWidth: 1)) }; VStack(spacing: 4) { Text(movieTitle).font(.system(size: 20, weight: .bold, design: .serif)).foregroundColor(.white).multilineTextAlignment(.center); if !episodeInfo.isEmpty { Text(episodeInfo).font(.system(size: 12)).foregroundColor(.white.opacity(0.5)) } }.padding(.horizontal, 40) }
        if showInfo { VStack(spacing: 8) { Text("🎬 Đạo diễn: Đang cập nhật").font(.system(size: 12)).foregroundColor(.white.opacity(0.8)); Text("⭐ IMDb: Đang cập nhật").font(.system(size: 12)).foregroundColor(.white.opacity(0.8)); Text("🎵 Nhạc phim: Đang cập nhật").font(.system(size: 12)).foregroundColor(.white.opacity(0.8)) }.padding(16).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.4))) }; Spacer()
        VStack(spacing: 6) { Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in if !editing { player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600)) } }.accentColor(.white).padding(.horizontal, 30); HStack { Text(formatTime(currentTime)).font(.system(size: 11, design: .monospaced)).foregroundColor(.white.opacity(0.5)); Spacer(); Text("-" + formatTime(max(duration - currentTime, 0))).font(.system(size: 11, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }.padding(.horizontal, 34) }
        HStack(spacing: 50) { Button { showAudioMenu.toggle() } label: { VStack(spacing: 4) { Image(systemName: "waveform").font(.system(size: 22)); Text(selectedAudio).font(.system(size: 10)) }.foregroundColor(.white.opacity(0.8)) }; Button { let newTime = max(currentTime - seekSeconds, 0); player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600)); currentTime = newTime } label: { Image(systemName: "gobackward.10").font(.system(size: 28)).foregroundColor(.white.opacity(0.9)) }; Button { if player.rate == 0 { player.play(); isPlaying = true } else { player.pause(); isPlaying = false } } label: { Image(systemName: isPlaying ? "pause.fill" : "play.fill").font(.system(size: 40)).foregroundColor(.white).padding(20).background(Circle().fill(.ultraThinMaterial.opacity(0.3))).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)) }; Button { let newTime = min(currentTime + seekSeconds, duration); player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600)); currentTime = newTime } label: { Image(systemName: "goforward.10").font(.system(size: 28)).foregroundColor(.white.opacity(0.9)) }; Button { withAnimation(.easeInOut(duration: 0.3)) { showInfo.toggle() } } label: { VStack(spacing: 4) { Image(systemName: "info.circle").font(.system(size: 22)); Text("Info").font(.system(size: 10)) }.foregroundColor(.white.opacity(0.8)) } }.padding(.top, 10)
        if showAudioMenu { VStack(spacing: 8) { ForEach(["Vietsub", "Thuyết minh", "Lồng tiếng", "Original"], id: \.self) { audio in Button { selectedAudio = audio; showAudioMenu = false } label: { HStack { Text(audio).font(.system(size: 14)).foregroundColor(.white); Spacer(); if selectedAudio == audio { Image(systemName: "checkmark").font(.system(size: 12)).foregroundColor(.white) } }.padding(.horizontal, 16).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(selectedAudio == audio ? .white.opacity(0.15) : .white.opacity(0.05))) } } }.padding(14).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 0.5)).padding(.horizontal, 40) }; Spacer().frame(height: 50) } }.onAppear { isPlaying = player.rate > 0 } }
    func stopCasting() { isCasting = false; EmmewCastManager.shared.stopCasting(); dismiss() }
    func formatTime(_ s: Double) -> String { let m = Int(s) / 60; let sec = Int(s) % 60; return String(format: "%d:%02d", m, sec) }
}

struct CustomPlayerVC: UIViewControllerRepresentable { let player: AVPlayer; @Binding var pipController: AVPictureInPictureController?; var gravity: VideoGravityMode = .fit
    func makeUIViewController(context: Context) -> AVPlayerViewController { let vc = AVPlayerViewController(); vc.player = player; vc.showsPlaybackControls = false; vc.videoGravity = gravity.avGravity; vc.allowsPictureInPicturePlayback = true; vc.canStartPictureInPictureAutomaticallyFromInline = true; try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay); try? AVAudioSession.sharedInstance().setActive(true); return vc }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) { ui.videoGravity = gravity.avGravity; DispatchQueue.main.async { if pipController == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer { pipController = AVPictureInPictureController(playerLayer: layer) } } }
}

extension VideoGravityMode { var avGravity: AVLayerVideoGravity { switch self { case .fit: return .resizeAspect; case .fill: return .resizeAspectFill; case .stretch: return .resize } } }