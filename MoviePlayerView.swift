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

enum MovieSource: String, CaseIterable { case phimapi="Emew 1", nguonc="Emew 2", vsmov="Emew 3" }

// MARK: - Cast Device Model
struct CastDevice: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: CastDeviceType
    var isConnected: Bool = false
    var signalStrength: Int = 3
}

enum CastDeviceType: String {
    case airplay = "AirPlay"
    case chromecast = "Chromecast"
    case smartTV = "Smart TV"
    case webReceiver = "Web Receiver"
}

enum CastMode: String, CaseIterable {
    case remote = "Remote Mode"
    case dualScreen = "Dual Screen"
}

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    var mediaType: String?; @State var seasonNumber: Int?; @State var episodeNumber: Int?; var posterURL: URL?
    var resumeTime: Double = 0
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
    @State private var imdbIDCache: String?
    @State private var hasStartedPlaying = false; @State private var didResume = false
    @State private var isOrientationLocked = true
    @State private var showSubtitlePopup = false; @State private var showAudioPopup = false
    @State private var autoNextTriggered = false
    @State private var showNextEpisodePopup = false
    @State private var phimapiServers: [String] = []
    @State private var selectedServerIndex = 0
    @State private var selectedAudioLabel: String = "Original"
    
    // Cast
    @State private var showCastSheet = false
    @State private var showRemoteControl = false
    @State private var castDeviceName: String = ""
    @State private var isCasting = false
    
    var episodeInfo: String {
        if let s = seasonNumber, let e = episodeNumber { return "S\(s):E\(e)" }
        return ""
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomPlayerVC(player: player, pipController: $pipController).ignoresSafeArea()
                .onAppear { player.play(); player.volume = volume; setupTimeObserver(); resetControlsTimer(); loadOverlayData(); lockToLandscape() }
                .onDisappear { saveProgress(); player.pause(); player.replaceCurrentItem(with: nil); controlsTimer?.invalidate(); unlockOrientation(); stopCasting() }
                .onTapGesture { if showOverlay { closeOverlay() } else { toggleControls() } }
            if showVolumeSlider { HStack { Spacer(); TinySlider(value: CGFloat(volume), icon: volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill").padding(.trailing, 14) } }
            if showBrightnessSlider { HStack { TinySlider(value: brightness, icon: "sun.max.fill").padding(.leading, 14); Spacer() } }
            Color.clear.frame(width: 60).position(x: UIScreen.main.bounds.width-30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showVolumeSlider{showVolumeSlider=true}; volume=min(max(volume+Float(-v.translation.height/120),0),1); player.volume=volume; resetVolumeTimer()}.onEnded{_ in resetVolumeTimer()})
            Color.clear.frame(width: 60).position(x: 30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showBrightnessSlider{showBrightnessSlider=true}; brightness=min(max(brightness+(-v.translation.height/120),0.01),1); UIScreen.main.brightness=brightness; resetBrightnessTimer()}.onEnded{_ in resetBrightnessTimer()})
            if isLoading { VStack(spacing:16){ProgressView().tint(.white).scaleEffect(1.5); Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.7)); Button{dismiss()}label:{Text("Quay lại").font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            if let err=errorMessage, !isLoading { VStack(spacing:16){Image(systemName:"wifi.slash").font(.system(size:40)).foregroundColor(.gray); Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center); HStack(spacing:10){ForEach(MovieSource.allCases,id:\.self){s in Button{selectedSource=s;loadStream()}label:{Text(s.rawValue).font(.caption2).foregroundColor(selectedSource==s ? .white:.gray).padding(.horizontal,10).padding(.vertical,6).background(Capsule().fill(selectedSource==s ? AnyShapeStyle(.ultraThinMaterial):AnyShapeStyle(Color.clear)))}}}; HStack(spacing:16){Button("Thử lại"){loadStream()}.font(.caption).foregroundColor(.white).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial)); Button("Quay lại"){dismiss()}.font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            if showControls && errorMessage == nil && !isLoading && !showOverlay && !showSourceMenu && !showSettings && !showSubtitlePopup && !showAudioPopup {
                // Nút điều khiển trung tâm
                if !isCasting {
                    HStack(spacing:64){Button{seek(-10)}label:{Image(systemName:"gobackward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}; Button{player.rate==0 ? player.play():player.pause()}label:{Image(systemName:player.rate==0 ? "play.fill":"pause.fill").font(.system(size:28,weight:.bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3))).overlay(Circle().stroke(Color.white.opacity(0.15),lineWidth:0.5))}; Button{seek(10)}label:{Image(systemName:"goforward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}}
                }
                VStack{Spacer(); VStack(spacing:8){Slider(value:$currentTime,in:0...max(duration,1)){e in isSeeking=e; if !e{player.seek(to:CMTime(seconds:currentTime,preferredTimescale:600))}}.accentColor(.white).padding(.horizontal,30); HStack{Text(formatTime(currentTime)).font(.caption2).foregroundColor(.white.opacity(0.7));Spacer();Text(formatTime(duration)).font(.caption2).foregroundColor(.white.opacity(0.7))}.padding(.horizontal,30)
                    HStack(spacing:0){
                        Spacer()
                        HStack(spacing:40){
                            Button{prevEpisode()}label:{Image(systemName:"backward.end.fill").font(.system(size:26)).foregroundColor(.white.opacity(0.9))}
                            Button{toggleOrientationLock()}label:{Image(systemName:isOrientationLocked ? "lock.rotation":"lock.open.rotation").font(.system(size:26)).foregroundColor(.white.opacity(0.9))}
                            Button{showSubtitlePopup=true}label:{Image(systemName:"captions.bubble").font(.system(size:26)).foregroundColor(.white.opacity(0.9))}
                            Button{showAudioPopup=true}label:{Image(systemName:"waveform").font(.system(size:26)).foregroundColor(.white.opacity(0.9))}
                            Button{nextEpisode()}label:{Image(systemName:"forward.end.fill").font(.system(size:26)).foregroundColor(.white.opacity(0.9))}
                        }
                        Spacer()
                        Button{toggleOrientation()}label:{Image(systemName:"rotate.right").font(.system(size:18)).foregroundColor(.white.opacity(0.8)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}
                    }.padding(.horizontal,20).padding(.bottom,30)
                }.background(LinearGradient(colors:[.clear,.black.opacity(0.5)],startPoint:.top,endPoint:.bottom))}
                VStack{
                    HStack{
                        Button{if let ws=UIApplication.shared.connectedScenes.first as? UIWindowScene{ws.requestGeometryUpdate(.iOS(interfaceOrientations:.portrait))}; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){dismiss()}}label:{Image(systemName:"chevron.left").font(.system(size:16,weight:.semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}
                        Spacer()
                        VStack(spacing: 2) {
                            Text(movieTitle).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1).frame(maxWidth: .infinity, alignment: .center)
                            if !episodeInfo.isEmpty { Text(episodeInfo).font(.caption2).foregroundColor(.white.opacity(0.6)).frame(maxWidth: .infinity, alignment: .center) }
                        }
                        Spacer()
                        HStack(spacing:6){
                            Button{pipController?.startPictureInPicture()}label:{Image(systemName:"pip.enter").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}
                            Button{showCastSheet=true}label:{Image(systemName:"airplayvideo").font(.system(size:14)).foregroundColor(isCasting ? .blue : .white.opacity(0.8)).padding(8).background(Circle().fill(isCasting ? AnyShapeStyle(Color.blue.opacity(0.3)) : AnyShapeStyle(.ultraThinMaterial.opacity(0.25)))).overlay(Circle().stroke(isCasting ? Color.blue.opacity(0.5) : Color.white.opacity(0.12),lineWidth:0.5))}
                            Button{showSettings=true}label:{Image(systemName:"gearshape.fill").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}
                            Button{showSourceMenu=true}label:{Image(systemName:"antenna.radiowaves.left.and.right").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}
                        }
                    }.padding(.horizontal,8).padding(.top,50)
                    Spacer()
                }
                // Cast indicator
                if isCasting {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("Đang phát trên \(castDeviceName)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(.ultraThinMaterial.opacity(0.5)))
                            .padding(.trailing, 20).padding(.bottom, 100)
                        }
                    }
                }
            }
            if showNextEpisodePopup {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 0) {
                            Button { skipNextEpisode() } label: {
                                Text("Bỏ qua").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.85)).padding(.horizontal, 18).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.1)))
                            }
                            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 26)
                            Button { nextEpisode() } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "forward.end.fill").font(.system(size: 11))
                                    Text("Tập tiếp theo").font(.system(size: 13, weight: .semibold))
                                }.foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.25)))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                    .padding(.trailing, 24).padding(.bottom, 110)
                }
            }
            if showOverlay { youtubeOverlay }
            if showSourceMenu || showSettings || showSubtitlePopup || showAudioPopup {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { showSourceMenu = false; showSettings = false; showSubtitlePopup = false; showAudioPopup = false }
                if showSourceMenu { sourcePopup }
                if showSettings { settingsPopup }
                if showSubtitlePopup { subtitlePopup }
                if showAudioPopup { audioPopup }
            }
        }
        .statusBarHidden()
        .gesture(DragGesture(minimumDistance: 20).onChanged { v in
            let screenHeight = UIScreen.main.bounds.height
            let triggerZone = max(screenHeight * 0.6, screenHeight - 250)
            if !showOverlay && v.translation.height < -40 && v.startLocation.y > triggerZone { showOverlay = true; overlayOffset = 300 }
            if showOverlay && v.translation.height > 40 { overlayOffset = max(0, v.translation.height) }
        }.onEnded { v in
            if showOverlay && v.translation.height > 100 { closeOverlay() }
            else if showOverlay { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { overlayOffset = 0 } }
        })
        .task { loadStream() }
        .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        .fullScreenCover(isPresented: $showNguonCWebView) { if let url = nguonCEmbedURL { NguonCPlayerView(embedURL: url, episodeName: nguonCEpisodeName) } }
        .fullScreenCover(isPresented: $showRemoteControl) {
            CastRemoteView(
                movieTitle: movieTitle,
                episodeInfo: episodeInfo,
                posterURL: posterURL,
                castDeviceName: castDeviceName,
                player: player,
                currentTime: $currentTime,
                duration: $duration,
                isCasting: $isCasting
            )
        }
        .sheet(isPresented: $showCastSheet) {
            CastSheetView(showRemote: $showRemoteControl, castDeviceName: $castDeviceName, isCasting: $isCasting, player: player)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }
    
    func stopCasting() {
        isCasting = false
        castDeviceName = ""
        EmmewCastManager.shared.stopCasting()
    }
    
    @ViewBuilder func episodeRow(detail: TVSeasonDetail) -> some View {
        VStack(alignment:.leading,spacing:6){
            Text("Tập \(episodeNumber ?? 1)/\(detail.episodes.count)").font(.caption).foregroundColor(.white.opacity(0.6))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(detail.episodes){ep in Button{ loadStream(season: ep.seasonNumber, episode: ep.episodeNumber); closeOverlay() }label:{ Text("\(ep.episodeNumber)").font(.system(size:11,weight:.medium)).foregroundColor(ep.episodeNumber == (episodeNumber ?? 1) ? .black : .white).frame(height:36).frame(maxWidth:.infinity).background(RoundedRectangle(cornerRadius:10).fill(ep.episodeNumber == (episodeNumber ?? 1) ? .white : Color.white.opacity(0.15)).overlay(RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.15),lineWidth:0.5))) } }
            }
        }
    }
    var youtubeOverlay: some View { ZStack(alignment:.bottom){ Color.black.opacity(0.4).ignoresSafeArea().onTapGesture{closeOverlay()}; VStack(spacing:0){ Capsule().fill(.white.opacity(0.5)).frame(width:40,height:5).padding(.top,10); ScrollView{ VStack(alignment:.leading,spacing:16){ if let movie=currentMovie { VStack(alignment:.leading,spacing:8){ Text("Đang xem").font(.title3).fontWeight(.bold).foregroundColor(.white); movieInfoCard }; if !collectionMovies.isEmpty { collectionRow }; if !seasons.isEmpty { seasonRow } }; if !similarMovies.isEmpty { similarRow } }.padding()}.clipped() }.frame(height:UIScreen.main.bounds.height*0.55).background(RoundedRectangle(cornerRadius:20).fill(.ultraThinMaterial.opacity(0.7))).offset(y:overlayOffset) } }
    var movieInfoCard: some View { Group { if let movie = currentMovie { HStack(spacing:12){ CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:60,height:90).clipShape(RoundedRectangle(cornerRadius:10)); VStack(alignment:.leading,spacing:4){ Text(movie.title).font(.headline).foregroundColor(.white).lineLimit(2); if !seasons.isEmpty{Text("\(seasons.count) mùa").font(.caption).foregroundColor(.gray)}; if !collectionMovies.isEmpty{Text("\(collectionMovies.count) phần").font(.caption).foregroundColor(.gray)}; if let detail = selectedSeasonDetail { episodeRow(detail: detail) } }; Spacer() }.padding(10).background(RoundedRectangle(cornerRadius:12).fill(.ultraThinMaterial.opacity(0.3))) } } }
    var collectionRow: some View { ScrollView(.horizontal,showsIndicators:false){ HStack(spacing:8){ ForEach(collectionMovies.filter{$0.id != movieId}){part in Button{openMovie(part)}label:{ VStack(spacing:4){ CachedAsyncImage(url:part.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:70,height:105).clipShape(RoundedRectangle(cornerRadius:8)); Text(part.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:70) } } } } } }
    var seasonRow: some View { ScrollView(.horizontal,showsIndicators:false){ HStack(spacing:6){ ForEach(seasons){season in Button{ selectedSeasonNumber=season.seasonNumber; Task{selectedSeasonDetail=try? await APIService.shared.fetchSeasonDetail(tvId:movieId,seasonNumber:season.seasonNumber)} }label:{ Text(season.name).font(.caption).fontWeight(selectedSeasonNumber==season.seasonNumber ? .bold:.regular).foregroundColor(selectedSeasonNumber==season.seasonNumber ? .white:.gray).padding(.horizontal,12).padding(.vertical,6).background(Capsule().fill(selectedSeasonNumber==season.seasonNumber ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5)):AnyShapeStyle(.ultraThinMaterial.opacity(0.2)))) } } } } }
    var similarRow: some View { VStack(alignment:.leading,spacing:8){ Text("Phim tương tự").font(.title3).fontWeight(.bold).foregroundColor(.white); ScrollView(.horizontal,showsIndicators:false){ HStack(spacing:8){ ForEach(similarMovies.prefix(15)){movie in Button{openMovie(movie)}label:{ VStack(spacing:4){ CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:90,height:135).clipShape(RoundedRectangle(cornerRadius:10)); Text(movie.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:90) } } } } } } }
    var sourcePopup: some View { VStack(spacing:10){Text("Nguồn phát").font(.system(size:14,weight:.bold)).foregroundColor(.white); if !phimapiServers.isEmpty && selectedSource == .phimapi {
    Picker("Server", selection: $selectedServerIndex) {
        ForEach(0..<phimapiServers.count, id: \.self) { i in
            Text(phimapiServers[i]).tag(i)
        }
    }
    .pickerStyle(.segmented)
    .onChange(of: selectedServerIndex) { _ in
        let savedTime = currentTime
        loadStream(season: seasonNumber, episode: episodeNumber, resumeAt: savedTime)
    }
    .padding(.bottom, 8)
} 
ForEach(MovieSource.allCases,id:\.self){ src in Button{selectedSource=src;showSourceMenu=false;loadStream()}label:{HStack(spacing:8){Circle().fill(sourceStatus[src]==true ? .green:sourceStatus[src]==false ? .red:.gray).frame(width:6,height:6);Text(src.rawValue).font(.system(size:13)).foregroundColor(.white);Spacer();if selectedSource==src{Image(systemName:"checkmark").font(.system(size:11)).foregroundColor(.white)}}.padding(.horizontal,14).padding(.vertical,10).background(RoundedRectangle(cornerRadius:10).fill(selectedSource==src ? .white.opacity(0.15):.white.opacity(0.05)))} } }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240) }
    var settingsPopup: some View { VStack(spacing:12){Text("Cài đặt").font(.system(size:14,weight:.bold)).foregroundColor(.white); Text("Chất lượng").font(.system(size:11)).foregroundColor(.white.opacity(0.6)); LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8){ForEach(["4K","1080p","720p","480p","360p"],id:\.self){q in Button{showSettings=false}label:{Text(q).font(.system(size:12)).foregroundColor(.white.opacity(0.6)).frame(maxWidth:.infinity).padding(.vertical,8).background(RoundedRectangle(cornerRadius:8).fill(Color.white.opacity(0.05)))} }}; Divider().background(Color.white.opacity(0.1)); Text("Tốc độ").font(.system(size:11)).foregroundColor(.white.opacity(0.6)); HStack(spacing:8){ForEach(["0.5x","1.0x","1.5x","2.0x"],id:\.self){s in Button{player.rate=Float(s.replacingOccurrences(of:"x",with:"")) ?? 1.0;showSettings=false}label:{Text(s).font(.system(size:12)).foregroundColor(.white).padding(.horizontal,12).padding(.vertical,6).background(Capsule().fill(.white.opacity(0.1)))} } } }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:260) }
    var subtitlePopup: some View { VStack(spacing:10){Text("Phụ đề").font(.system(size:14,weight:.bold)).foregroundColor(.white); ForEach(["Tắt","Vietsub","English","Tiếng Việt (AI)"],id:\.self){sub in Button{showSubtitlePopup=false}label:{Text(sub).font(.system(size:13)).foregroundColor(.white).frame(maxWidth:.infinity).padding(.vertical,10).background(RoundedRectangle(cornerRadius:8).fill(.white.opacity(0.08)))} } }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240) }
    var audioPopup: some View { VStack(spacing:10){Text("Âm thanh").font(.system(size:14,weight:.bold)).foregroundColor(.white); ForEach(audioOptions(), id:\.self){aud in Button{selectAudio(aud)}label:{Text(aud).font(.system(size:13)).foregroundColor(aud == selectedAudioLabel ? .black : .white).frame(maxWidth:.infinity).padding(.vertical,10).background(RoundedRectangle(cornerRadius:8).fill(aud == selectedAudioLabel ? .white : Color.white.opacity(0.08)))} } }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240) }
    
    func audioOptions() -> [String] {
        if selectedSource == .phimapi && !phimapiServers.isEmpty {
            return phimapiServers
        }
        return ["Vietsub", "Lồng Tiếng", "Original"]
    }
    
    func selectAudio(_ label: String) {
        selectedAudioLabel = label
        if selectedSource == .phimapi, let idx = phimapiServers.firstIndex(of: label) {
            selectedServerIndex = idx
            let savedTime = currentTime
            loadStream(season: seasonNumber, episode: episodeNumber, resumeAt: savedTime)
        }
        showAudioPopup = false
    }
    
    func closeOverlay() { withAnimation(.spring(response:0.25,dampingFraction:0.8)){overlayOffset=UIScreen.main.bounds.height}; DispatchQueue.main.asyncAfter(deadline:.now()+0.25){showOverlay=false} }
    func openMovie(_ movie: Movie) { closeOverlay(); player.pause(); if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { selectedMovie = movie } }
    func prevEpisode() { guard let ep = episodeNumber, ep > 1 else { return }; autoNextTriggered = false; showNextEpisodePopup = false; loadStream(season: seasonNumber, episode: ep - 1) }
    func nextEpisode() {
        guard let ep = episodeNumber, let detail = selectedSeasonDetail, ep < detail.episodes.count else { return }
        showNextEpisodePopup = false
        autoNextTriggered = true
        loadStream(season: seasonNumber, episode: ep + 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { autoNextTriggered = false }
    }
    func skipNextEpisode() { showNextEpisodePopup = false; autoNextTriggered = true; DispatchQueue.main.asyncAfter(deadline: .now() + 5) { autoNextTriggered = false } }
    func toggleOrientationLock() { isOrientationLocked.toggle(); if isOrientationLocked { lockToLandscape() } }
    func loadOverlayData() { Task { similarMovies=(try? await APIService.shared.similar(movieId:movieId,mediaType:mediaType)) ?? []; if mediaType=="tv"{ seasons=(try? await APIService.shared.fetchTVSeasons(tvId:movieId)) ?? []; if let s = seasonNumber { selectedSeasonNumber = s; selectedSeasonDetail = try? await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: s) } }; if let detail=try? await APIService.shared.movieDetail(movieId:movieId),let cid=detail.belongsToCollection?.id,let col=try? await APIService.shared.collectionDetail(collectionId:cid){collectionMovies=col.parts}; currentMovie=Movie(id:movieId,title:movieTitle,overview:"",posterPath:posterURL?.absoluteString ?? "",backdropPath:nil,voteAverage:0,releaseDate:nil,genreIds:nil,originalTitle:nil,popularity:nil,voteCount:nil,adult:false,originalLanguage:nil,mediaType:mediaType) } }
    func loadStream(season: Int? = nil, episode: Int? = nil, resumeAt: Double? = nil) {
        if let s = season { seasonNumber = s }
        if let e = episode { episodeNumber = e }
        let ep = episodeNumber ?? 1; let s = seasonNumber
        imdbIDCache = nil; autoNextTriggered = false; showNextEpisodePopup = false
        if mediaType == "tv" || s != nil { selectedSeasonNumber = s; Task { selectedSeasonDetail = try? await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: s ?? 1) } }
        isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil
        Task { do { let imdbID = try await fetchIMDB()
                switch selectedSource {
                case .phimapi: 
    let result = try await withCheckedThrowingContinuation { c in 
        PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movieId, title: movieTitle, mediaType: mediaType, season: s, episode: ep, serverIndex: selectedServerIndex) { c.resume(with: $0) } 
    }
    await MainActor.run { 
        phimapiServers = result.1
        let item = AVPlayerItem(url: result.0)
        player.replaceCurrentItem(with: item)
        if let resumeTime = resumeAt {
            player.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 600)) { _ in
                player.play()
            }
        } else {
            player.play()
        }
        hasStartedPlaying = true
        sourceStatus[.phimapi] = true
        isLoading = false
        tryResume()
    }
    saveHistory()
                case .nguonc: let url = try await withCheckedThrowingContinuation { c in NguonCService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }; await MainActor.run { nguonCEmbedURL = url; nguonCEpisodeName = "\(movieTitle) - Tập \(ep)"; isLoading = false; sourceStatus[.nguonc] = true; showNguonCWebView = true }
                case .vsmov: let url = try await withCheckedThrowingContinuation { c in VSMOVService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }; await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.vsmov] = true; isLoading = false; tryResume() }; saveHistory()
                }
        } catch { await MainActor.run { sourceStatus[selectedSource] = false; errorMessage = error.localizedDescription; isLoading = false } } }
    }
    func tryResume() { guard !didResume, resumeTime > 0 else { return }; didResume = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { player.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 600)) } }
    func fetchIMDB() async throws -> String { if let cached = imdbIDCache { return cached }; var id: String?; if mediaType == "tv" || seasonNumber != nil { id = try? await APIService.shared.fetchExternalIDs(tvId: movieId) }; if id == nil || id?.isEmpty == true { let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E: Codable { let imdb_id: String? }; id = try? JSONDecoder().decode(E.self, from: data).imdb_id }; guard let finalID = id, !finalID.isEmpty else { throw StreamError.noStreamAvailable }; imdbIDCache = finalID; return finalID }
    func lockToLandscape() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) } }
    func unlockOrientation() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) } }
    func saveProgress() { guard hasStartedPlaying, currentTime > 0, duration > 0 else { return }; appState.updateProgress(WatchProgress(movieId: movieId, movieTitle: movieTitle, posterPath: posterURL?.absoluteString, mediaType: mediaType, season: seasonNumber, episode: episodeNumber, currentTime: currentTime, duration: duration, lastWatched: Date())) }
    func saveHistory() { let m = Movie(id: movieId, title: movieTitle, overview: "", posterPath: posterURL?.absoluteString ?? "", backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: mediaType); appState.watchHistory.removeAll { $0.id == movieId }; appState.watchHistory.insert(m, at: 0); if appState.watchHistory.count > 50 { appState.watchHistory.removeLast() }; appState.save() }
    func setupTimeObserver() { player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { t in if !isSeeking { currentTime = t.seconds }; if let d = player.currentItem?.duration, d.isNumeric { duration = d.seconds }; if duration > 240 && currentTime >= duration - 120 && !autoNextTriggered && !showNextEpisodePopup { showNextEpisodePopup = true } } }
    func seek(_ s:Double){let t=max(0,min(currentTime+s,duration));player.seek(to:CMTime(seconds:t,preferredTimescale:600));currentTime=t}
    func toggleControls(){withAnimation(.easeInOut(duration:0.2)){showControls.toggle()};if showControls{resetControlsTimer()}}
    func resetControlsTimer(){controlsTimer?.invalidate();controlsTimer=Timer.scheduledTimer(withTimeInterval:4,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showControls=false}}}
    func resetVolumeTimer(){volumeTimer?.invalidate();volumeTimer=Timer.scheduledTimer(withTimeInterval:1.0,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showVolumeSlider=false}}}
    func resetBrightnessTimer(){brightnessTimer?.invalidate();brightnessTimer=Timer.scheduledTimer(withTimeInterval:1.0,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showBrightnessSlider=false}}}
    func toggleOrientation(){guard let ws=UIApplication.shared.connectedScenes.first as? UIWindowScene else{return};ws.requestGeometryUpdate(.iOS(interfaceOrientations:ws.interfaceOrientation.isLandscape ? .portrait:.landscapeRight))}
    func formatTime(_ s:Double)->String{let m=Int(s)/60;let sec=Int(s)%60;return String(format:"%d:%02d",m,sec)}
}

// MARK: - Cast Sheet View
struct CastSheetView: View {
    @Binding var showRemote: Bool
    @Binding var castDeviceName: String
    @Binding var isCasting: Bool
    let player: AVPlayer
    @Environment(\.dismiss) var dismiss
    @State private var devices: [CastDevice] = []
    @State private var selectedDevice: CastDevice?
    @State private var selectedMode: CastMode = .remote
    @State private var isScanning = true
    
    let dummyDevices: [CastDevice] = [
        CastDevice(name: "Apple TV 4K", icon: "appletv.fill", type: .airplay, signalStrength: 4),
        CastDevice(name: "Apple TV HD", icon: "appletv.fill", type: .airplay, signalStrength: 4),
        CastDevice(name: "Samsung Smart TV", icon: "tv.fill", type: .smartTV, signalStrength: 4),
        CastDevice(name: "LG Smart TV", icon: "tv.fill", type: .smartTV, signalStrength: 3),
        CastDevice(name: "Sony Bravia", icon: "tv.fill", type: .smartTV, signalStrength: 3),
        CastDevice(name: "TCL Smart TV", icon: "tv.fill", type: .smartTV, signalStrength: 3),
        CastDevice(name: "Panasonic TV", icon: "tv.fill", type: .smartTV, signalStrength: 3),
        CastDevice(name: "Philips Smart TV", icon: "tv.fill", type: .smartTV, signalStrength: 2),
        CastDevice(name: "Skyworth TV", icon: "tv.fill", type: .smartTV, signalStrength: 2),
        CastDevice(name: "Coocaa TV", icon: "tv.fill", type: .smartTV, signalStrength: 2),
        CastDevice(name: "Chromecast Ultra", icon: "rectangle.connected.to.line.below", type: .chromecast, signalStrength: 4),
        CastDevice(name: "Chromecast 4K", icon: "rectangle.connected.to.line.below", type: .chromecast, signalStrength: 4),
        CastDevice(name: "Chromecast HD", icon: "rectangle.connected.to.line.below", type: .chromecast, signalStrength: 3),
        CastDevice(name: "NVIDIA Shield TV", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 5),
        CastDevice(name: "Xiaomi Mi Box S", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 4),
        CastDevice(name: "Xiaomi TV Stick", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 4),
        CastDevice(name: "Tanix TV Box", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 3),
        CastDevice(name: "HK1 Box", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 3),
        CastDevice(name: "TX9 TV Box", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 3),
        CastDevice(name: "Rocktek G2", icon: "tv.and.hifispeaker.fill", type: .chromecast, signalStrength: 4),
        CastDevice(name: "Xbox Series X", icon: "gamecontroller.fill", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "PlayStation 5", icon: "playstation.logo", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "PlayStation 4", icon: "playstation.logo", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "MacBook Pro", icon: "laptopcomputer", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "MacBook Air", icon: "laptopcomputer", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "iMac", icon: "desktopcomputer", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "Windows PC", icon: "desktopcomputer", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "Windows Laptop", icon: "laptopcomputer", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "Linux PC", icon: "desktopcomputer", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "Máy chiếu Epson", icon: "rectangle.fill.badge.person.crop", type: .smartTV, signalStrength: 2),
        CastDevice(name: "Máy chiếu BenQ", icon: "rectangle.fill.badge.person.crop", type: .smartTV, signalStrength: 2),
        CastDevice(name: "Máy chiếu Optoma", icon: "rectangle.fill.badge.person.crop", type: .smartTV, signalStrength: 2),
        CastDevice(name: "iPad", icon: "ipad", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "Android Tablet", icon: "ipad.landscape", type: .webReceiver, signalStrength: 3),
        CastDevice(name: "iPhone khác", icon: "iphone", type: .webReceiver, signalStrength: 4),
        CastDevice(name: "Android Phone", icon: "smartphone", type: .webReceiver, signalStrength: 3),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                HStack {
                    Text("Phát đến thiết bị")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if isScanning {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Button {
                        scanDevices()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(devices) { device in
                            deviceCard(device)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .frame(maxHeight: 280)
                
                if selectedDevice != nil {
                    VStack(spacing: 10) {
                        Divider()
                            .background(Color.white.opacity(0.15))
                            .padding(.horizontal, 20)
                        
                        Text("Chế độ")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            ForEach(CastMode.allCases, id: \.self) { mode in
                                modeButton(mode)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Button {
                            startCasting()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 14))
                                Text("Bắt đầu phát")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                
                Spacer().frame(height: 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial.opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30, y: -10)
        }
        .onAppear {
            scanDevices()
        }
    }
    
    func deviceCard(_ device: CastDevice) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedDevice?.id == device.id {
                    selectedDevice = nil
                } else {
                    selectedDevice = device
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(selectedDevice?.id == device.id ? 0.15 : 0.08))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: device.icon)
                        .font(.system(size: 18))
                        .foregroundColor(selectedDevice?.id == device.id ? .white : .white.opacity(0.7))
                }
                .overlay(
                    Circle()
                        .stroke(
                            selectedDevice?.id == device.id ? Color.blue.opacity(0.6) : .white.opacity(0.08),
                            lineWidth: selectedDevice?.id == device.id ? 2 : 1
                        )
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(device.type.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(i < device.signalStrength ? Color.green.opacity(0.7) : .white.opacity(0.15))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if selectedDevice?.id == device.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedDevice?.id == device.id ? .white.opacity(0.08) : .white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selectedDevice?.id == device.id ? Color.blue.opacity(0.3) : .white.opacity(0.05),
                                lineWidth: 0.5
                            )
                    )
            )
        }
    }
    
    func modeButton(_ mode: CastMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMode = mode
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode == .remote ? "iphone.gen1" : "rectangle.split.2x1")
                    .font(.system(size: 20))
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedMode == mode ? Color.blue.opacity(0.3) : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedMode == mode ? Color.blue.opacity(0.4) : .white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
            )
        }
    }
    
    func scanDevices() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            devices = dummyDevices
            isScanning = false
        }
    }
    
    func startCasting() {
        guard let device = selectedDevice else { return }
        castDeviceName = device.name
        isCasting = true
        
        // Bắt đầu cast với AirPlay
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        EmmewCastManager.shared.startCasting(with: player, deviceName: device.name)
        
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRemote = true
        }
    }
}

// MARK: - Cast Remote View
struct CastRemoteView: View {
    let movieTitle: String
    let episodeInfo: String
    var posterURL: URL?
    let castDeviceName: String
    let player: AVPlayer
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isCasting: Bool
    @Environment(\.dismiss) var dismiss
    @State private var isPlaying = true
    @State private var selectedAudio = "Vietsub"
    @State private var showAudioMenu = false
    @State private var showInfo = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.04), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(.ultraThinMaterial.opacity(0.05))
            
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .fill(Color.green.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(isPlaying ? 1.5 : 1)
                                    .opacity(isPlaying ? 0.6 : 0)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPlaying)
                            )
                        Text("Đang phát trên \(castDeviceName)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Button {
                        stopCasting()
                    } label: {
                        Text("Ngắt kết nối")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Poster + info
                VStack(spacing: 16) {
                    if let url = posterURL {
                        CachedAsyncImage(url: url)
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .white.opacity(0.15), radius: 20, y: -5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text(movieTitle)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if !episodeInfo.isEmpty {
                            Text(episodeInfo)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                if showInfo {
                    VStack(spacing: 8) {
                        Text("🎬 Đạo diễn: Đang cập nhật")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                        Text("⭐ IMDb: Đang cập nhật")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                        Text("🎵 Nhạc phim: Đang cập nhật")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.4)))
                }
                
                Spacer()
                
                // Progress bar
                VStack(spacing: 6) {
                    Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                        if !editing {
                            player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                        }
                    }
                    .accentColor(.white)
                    .padding(.horizontal, 30)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("-" + formatTime(max(duration - currentTime, 0)))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 34)
                }
                
                // Controls
                HStack(spacing: 50) {
                    Button { showAudioMenu.toggle() } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "waveform").font(.system(size: 22))
                            Text(selectedAudio).font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Button {
                        let newTime = max(currentTime - 10, 0)
                        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                        currentTime = newTime
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Button {
                        if player.rate == 0 {
                            player.play()
                            isPlaying = true
                        } else {
                            player.pause()
                            isPlaying = false
                        }
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                    }
                    
                    Button {
                        let newTime = min(currentTime + 10, duration)
                        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                        currentTime = newTime
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showInfo.toggle()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle").font(.system(size: 22))
                            Text("Info").font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 10)
                
                if showAudioMenu {
                    VStack(spacing: 8) {
                        ForEach(["Vietsub", "Thuyết minh", "Lồng tiếng", "Original"], id: \.self) { audio in
                            Button {
                                selectedAudio = audio
                                showAudioMenu = false
                            } label: {
                                HStack {
                                    Text(audio).font(.system(size: 14)).foregroundColor(.white)
                                    Spacer()
                                    if selectedAudio == audio {
                                        Image(systemName: "checkmark").font(.system(size: 12)).foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(selectedAudio == audio ? .white.opacity(0.15) : .white.opacity(0.05)))
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    .padding(.horizontal, 40)
                }
                
                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            isPlaying = player.rate > 0
        }
    }
    
    func stopCasting() {
        isCasting = false
        EmmewCastManager.shared.stopCasting()
        dismiss()
    }
    
    func formatTime(_ s: Double) -> String {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

struct CustomPlayerVC: UIViewControllerRepresentable { let player: AVPlayer; @Binding var pipController: AVPictureInPictureController?
    func makeUIViewController(context: Context) -> AVPlayerViewController { let vc = AVPlayerViewController(); vc.player = player; vc.showsPlaybackControls = false; vc.videoGravity = .resizeAspect; vc.allowsPictureInPicturePlayback = true; vc.canStartPictureInPictureAutomaticallyFromInline = true; try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay); try? AVAudioSession.sharedInstance().setActive(true); return vc }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) { DispatchQueue.main.async { if pipController == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer { pipController = AVPictureInPictureController(playerLayer: layer) } } }
}

struct TinySlider: View { let value: CGFloat; let icon: String
    var body: some View { VStack(spacing:4){Image(systemName:icon).font(.system(size:9)).foregroundColor(.white.opacity(0.5));ZStack(alignment:.bottom){Capsule().fill(.ultraThinMaterial.opacity(0.1)).overlay(Capsule().stroke(Color.white.opacity(0.04),lineWidth:0.5)).frame(width:6,height:60);Circle().fill(.white.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.6),lineWidth:1)).frame(width:16,height:16).shadow(color:.white.opacity(0.15),radius:4).offset(y:-value*52)} } }
}