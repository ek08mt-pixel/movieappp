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

enum MovieSource: String, CaseIterable { case phimapi="PhimAPI", xem20="Xem20", nguonc="NguonC", vsmov="VSMOV", stravo="Stravo" }

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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomPlayerVC(player: player, pipController: $pipController).ignoresSafeArea()
                .onAppear { player.play(); player.volume = volume; setupTimeObserver(); resetControlsTimer(); loadOverlayData(); lockToLandscape() }
                .onDisappear { saveProgress(); player.pause(); player.replaceCurrentItem(with: nil); controlsTimer?.invalidate(); unlockOrientation() }
                .onTapGesture { if showOverlay { closeOverlay() } else { toggleControls() } }
            if showVolumeSlider { HStack { Spacer(); TinySlider(value: CGFloat(volume), icon: volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill").padding(.trailing, 14) } }
            if showBrightnessSlider { HStack { TinySlider(value: brightness, icon: "sun.max.fill").padding(.leading, 14); Spacer() } }
            Color.clear.frame(width: 60).position(x: UIScreen.main.bounds.width-30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showVolumeSlider{showVolumeSlider=true}; volume=min(max(volume+Float(-v.translation.height/120),0),1); player.volume=volume; resetVolumeTimer()}.onEnded{_ in resetVolumeTimer()})
            Color.clear.frame(width: 60).position(x: 30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showBrightnessSlider{showBrightnessSlider=true}; brightness=min(max(brightness+(-v.translation.height/120),0.01),1); UIScreen.main.brightness=brightness; resetBrightnessTimer()}.onEnded{_ in resetBrightnessTimer()})
            if isLoading { VStack(spacing:16){ProgressView().tint(.white).scaleEffect(1.5); Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.7)); Button{dismiss()}label:{Text("Quay lại").font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            if let err=errorMessage, !isLoading { VStack(spacing:16){Image(systemName:"wifi.slash").font(.system(size:40)).foregroundColor(.gray); Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center); HStack(spacing:10){ForEach(MovieSource.allCases,id:\.self){s in Button{selectedSource=s;loadStream()}label:{Text(s.rawValue).font(.caption2).foregroundColor(selectedSource==s ? .white:.gray).padding(.horizontal,10).padding(.vertical,6).background(Capsule().fill(selectedSource==s ? AnyShapeStyle(.ultraThinMaterial):AnyShapeStyle(Color.clear)))}}}; HStack(spacing:16){Button("Thử lại"){loadStream()}.font(.caption).foregroundColor(.white).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial)); Button("Quay lại"){dismiss()}.font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            if showControls && errorMessage == nil && !isLoading && !showOverlay && !showSourceMenu && !showSettings && !showSubtitlePopup && !showAudioPopup {
                HStack(spacing:64){Button{seek(-10)}label:{Image(systemName:"gobackward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}; Button{player.rate==0 ? player.play():player.pause()}label:{Image(systemName:player.rate==0 ? "play.fill":"pause.fill").font(.system(size:28,weight:.bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3))).overlay(Circle().stroke(Color.white.opacity(0.15),lineWidth:0.5))}; Button{seek(10)}label:{Image(systemName:"goforward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}}
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
                VStack{HStack{Button{if let ws=UIApplication.shared.connectedScenes.first as? UIWindowScene{ws.requestGeometryUpdate(.iOS(interfaceOrientations:.portrait))}; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){dismiss()}}label:{Image(systemName:"chevron.left").font(.system(size:16,weight:.semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Spacer();Text(movieTitle).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1);Spacer();HStack(spacing:6){Button{pipController?.startPictureInPicture()}label:{Image(systemName:"pip.enter").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Button{showSettings=true}label:{Image(systemName:"gearshape.fill").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Button{showSourceMenu=true}label:{Image(systemName:"antenna.radiowaves.left.and.right").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}}}.padding(.horizontal,8).padding(.top,50);Spacer()}
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
        .gesture(DragGesture(minimumDistance:20).onChanged{v in if !showOverlay && v.translation.height < -40 && v.startLocation.y > UIScreen.main.bounds.height-250 { showOverlay=true; overlayOffset=300 }; if showOverlay && v.translation.height > 40 { overlayOffset=max(0,v.translation.height) }}.onEnded{v in if showOverlay && v.translation.height > 100 { closeOverlay() } else if showOverlay { withAnimation(.spring(response:0.3,dampingFraction:0.8)){overlayOffset=0} }})
        .task { loadStream() }
        .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        .fullScreenCover(isPresented: $showNguonCWebView) { if let url = nguonCEmbedURL { NguonCPlayerView(embedURL: url, episodeName: nguonCEpisodeName) } }
    }
    
    // MARK: - Episode List Helper
    @ViewBuilder
    func episodeRow(detail: TVSeasonDetail) -> some View {
        VStack(alignment:.leading,spacing:4){
            Text("Tập \(episodeNumber ?? 1)/\(detail.episodes.count)").font(.caption2).foregroundColor(.white.opacity(0.6))
            ScrollView(.horizontal,showsIndicators:false){
                HStack(spacing:6){
                    ForEach(detail.episodes){ep in
                        Button{
                            loadStream(season: ep.seasonNumber, episode: ep.episodeNumber)
                            closeOverlay()
                        }label:{
                            Text("\(ep.episodeNumber)")
                                .font(.system(size:10,weight:.medium))
                                .foregroundColor(ep.episodeNumber == (episodeNumber ?? 1) ? .black : .white)
                                .frame(width:30,height:30)
                                .background(Circle().fill(ep.episodeNumber == (episodeNumber ?? 1) ? .white : .ultraThinMaterial.opacity(0.4)))
                                .overlay(Circle().stroke(.white.opacity(0.15),lineWidth:0.5))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Overlay
    var youtubeOverlay: some View {
        ZStack(alignment:.bottom){ Color.black.opacity(0.4).ignoresSafeArea().onTapGesture{closeOverlay()}
            VStack(spacing:0){ Capsule().fill(.white.opacity(0.5)).frame(width:40,height:5).padding(.top,10)
                ScrollView{ VStack(alignment:.leading,spacing:16){
                    if let movie=currentMovie {
                        VStack(alignment:.leading,spacing:8){
                            Text("Đang xem").font(.title3).fontWeight(.bold).foregroundColor(.white)
                            movieInfoCard(movie: movie)
                        }
                        if !collectionMovies.isEmpty { collectionRow }
                        if !seasons.isEmpty { seasonRow }
                    }
                    if !similarMovies.isEmpty { similarRow }
                }.padding()}.clipped()
            }.frame(height:UIScreen.main.bounds.height*0.55).background(RoundedRectangle(cornerRadius:20).fill(.ultraThinMaterial.opacity(0.7))).offset(y:overlayOffset)
        }
    }
    
    var movieInfoCard: some View {
        return Group {
            if let movie = currentMovie {
                HStack(spacing:12){
                    CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:60,height:90).clipShape(RoundedRectangle(cornerRadius:10))
                    VStack(alignment:.leading,spacing:4){
                        Text(movie.title).font(.headline).foregroundColor(.white).lineLimit(2)
                        if !seasons.isEmpty{Text("\(seasons.count) mùa").font(.caption).foregroundColor(.gray)}
                        if !collectionMovies.isEmpty{Text("\(collectionMovies.count) phần").font(.caption).foregroundColor(.gray)}
                        if let detail = selectedSeasonDetail { episodeRow(detail: detail) }
                    }
                    Spacer()
                }.padding(10).background(RoundedRectangle(cornerRadius:12).fill(.ultraThinMaterial.opacity(0.3)))
            }
        }
    }
    
    var collectionRow: some View {
        ScrollView(.horizontal,showsIndicators:false){
            HStack(spacing:8){
                ForEach(collectionMovies.filter{$0.id != movieId}){part in
                    Button{openMovie(part)}label:{
                        VStack(spacing:4){
                            CachedAsyncImage(url:part.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:70,height:105).clipShape(RoundedRectangle(cornerRadius:8))
                            Text(part.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:70)
                        }
                    }
                }
            }
        }
    }
    
    var seasonRow: some View {
        ScrollView(.horizontal,showsIndicators:false){
            HStack(spacing:6){
                ForEach(seasons){season in
                    Button{
                        selectedSeasonNumber=season.seasonNumber
                        Task{selectedSeasonDetail=try? await APIService.shared.fetchSeasonDetail(tvId:movieId,seasonNumber:season.seasonNumber)}
                    }label:{
                        Text(season.name).font(.caption).fontWeight(selectedSeasonNumber==season.seasonNumber ? .bold:.regular)
                            .foregroundColor(selectedSeasonNumber==season.seasonNumber ? .white:.gray)
                            .padding(.horizontal,12).padding(.vertical,6)
                            .background(Capsule().fill(selectedSeasonNumber==season.seasonNumber ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5)):AnyShapeStyle(.ultraThinMaterial.opacity(0.2))))
                    }
                }
            }
        }
    }
    
    var similarRow: some View {
        VStack(alignment:.leading,spacing:8){
            Text("Phim tương tự").font(.title3).fontWeight(.bold).foregroundColor(.white)
            ScrollView(.horizontal,showsIndicators:false){
                HStack(spacing:8){
                    ForEach(similarMovies.prefix(15)){movie in
                        Button{openMovie(movie)}label:{
                            VStack(spacing:4){
                                CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:90,height:135).clipShape(RoundedRectangle(cornerRadius:10))
                                Text(movie.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:90)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Popups
    var sourcePopup: some View {
        VStack(spacing:10){Text("Nguồn phát").font(.system(size:14,weight:.bold)).foregroundColor(.white)
            ForEach(MovieSource.allCases,id:\.self){ src in Button{selectedSource=src;showSourceMenu=false;loadStream()}label:{HStack(spacing:8){Circle().fill(sourceStatus[src]==true ? .green:sourceStatus[src]==false ? .red:.gray).frame(width:6,height:6);Text(src.rawValue).font(.system(size:13)).foregroundColor(.white);Spacer();if selectedSource==src{Image(systemName:"checkmark").font(.system(size:11)).foregroundColor(.white)}}.padding(.horizontal,14).padding(.vertical,10).background(RoundedRectangle(cornerRadius:10).fill(selectedSource==src ? .white.opacity(0.15):.white.opacity(0.05)))} }
        }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240)
    }
    
    var settingsPopup: some View {
        VStack(spacing:12){Text("Cài đặt").font(.system(size:14,weight:.bold)).foregroundColor(.white)
            Text("Tốc độ").font(.system(size:11)).foregroundColor(.white.opacity(0.6))
            HStack(spacing:8){ForEach(["0.5x","1.0x","1.5x","2.0x"],id:\.self){s in Button{player.rate=Float(s.replacingOccurrences(of:"x",with:"")) ?? 1.0;showSettings=false}label:{Text(s).font(.system(size:12)).foregroundColor(.white).padding(.horizontal,12).padding(.vertical,6).background(Capsule().fill(.white.opacity(0.1)))} } }
        }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:260)
    }
    
    var subtitlePopup: some View {
        VStack(spacing:10){Text("Phụ đề").font(.system(size:14,weight:.bold)).foregroundColor(.white)
            ForEach(["Tắt","Vietsub","English","Tiếng Việt (AI)"],id:\.self){sub in Button{showSubtitlePopup=false}label:{Text(sub).font(.system(size:13)).foregroundColor(.white).frame(maxWidth:.infinity).padding(.vertical,10).background(RoundedRectangle(cornerRadius:8).fill(.white.opacity(0.08)))} }
        }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240)
    }
    
    var audioPopup: some View {
        VStack(spacing:10){Text("Âm thanh").font(.system(size:14,weight:.bold)).foregroundColor(.white)
            ForEach(["Vietsub","Lồng Tiếng","Original"],id:\.self){aud in Button{showAudioPopup=false}label:{Text(aud).font(.system(size:13)).foregroundColor(.white).frame(maxWidth:.infinity).padding(.vertical,10).background(RoundedRectangle(cornerRadius:8).fill(.white.opacity(0.08)))} }
        }.padding(18).background(RoundedRectangle(cornerRadius:16).fill(.ultraThinMaterial.opacity(0.95))).overlay(RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.2),lineWidth:0.5)).frame(width:240)
    }
    
    // MARK: - Actions
    func closeOverlay() { withAnimation(.spring(response:0.25,dampingFraction:0.8)){overlayOffset=UIScreen.main.bounds.height}; DispatchQueue.main.asyncAfter(deadline:.now()+0.25){showOverlay=false} }
    func openMovie(_ movie: Movie) { closeOverlay(); player.pause(); if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { selectedMovie = movie } }
    func prevEpisode() { guard let ep = episodeNumber, ep > 1 else { return }; loadStream(season: seasonNumber, episode: ep - 1) }
    func nextEpisode() { guard let ep = episodeNumber, let detail = selectedSeasonDetail, ep < detail.episodes.count else { return }; loadStream(season: seasonNumber, episode: ep + 1) }
    func toggleOrientationLock() { isOrientationLocked.toggle(); if isOrientationLocked { lockToLandscape() } }
    
    func loadOverlayData() { Task { 
        similarMovies=(try? await APIService.shared.similar(movieId:movieId,mediaType:mediaType)) ?? []
        if mediaType=="tv"{seasons=(try? await APIService.shared.fetchTVSeasons(tvId:movieId)) ?? []}
        if let detail=try? await APIService.shared.movieDetail(movieId:movieId),let cid=detail.belongsToCollection?.id,let col=try? await APIService.shared.collectionDetail(collectionId:cid){collectionMovies=col.parts}
        currentMovie=Movie(id:movieId,title:movieTitle,overview:"",posterPath:posterURL?.absoluteString ?? "",backdropPath:nil,voteAverage:0,releaseDate:nil,genreIds:nil,originalTitle:nil,popularity:nil,voteCount:nil,adult:false,originalLanguage:nil,mediaType:mediaType)
    } }
    
    func loadStream(season: Int? = nil, episode: Int? = nil) {
        let ep = episode ?? episodeNumber ?? 1; let s = season ?? seasonNumber
        seasonNumber = s; episodeNumber = ep
        isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil
        Task {
            do {
                let imdbID = try await fetchIMDB()
                switch selectedSource {
                case .phimapi:
                    let url = try await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movieId, title: movieTitle, mediaType: mediaType, season: s, episode: ep) { c.resume(with: $0) } }
                    await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.phimapi] = true; isLoading = false; tryResume() }; saveHistory()
                case .xem20:
                    let url = try await withCheckedThrowingContinuation { c in Xem20Service.shared.fetchStream(title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }
                    await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.xem20] = true; isLoading = false; tryResume() }; saveHistory()
                case .nguonc:
                    let url = try await withCheckedThrowingContinuation { c in NguonCService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }
                    await MainActor.run { nguonCEmbedURL = url; nguonCEpisodeName = "\(movieTitle) - Tập \(ep)"; isLoading = false; sourceStatus[.nguonc] = true; showNguonCWebView = true }
                case .vsmov:
                    let url = try await withCheckedThrowingContinuation { c in VSMOVService.shared.fetchStream(imdbID: imdbID, title: movieTitle, season: s, episode: ep) { c.resume(with: $0) } }
                    await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); hasStartedPlaying = true; sourceStatus[.vsmov] = true; isLoading = false; tryResume() }; saveHistory()
                case .stravo:
                    let url = try await withCheckedThrowingContinuation { c in StravoService.shared.fetchStream(imdbID: imdbID, season: s, episode: ep) { c.resume(with: $0) } }
                    let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Referer": "https://lok-lok.cc/", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"]])
                    await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(asset: asset)); player.play(); hasStartedPlaying = true; sourceStatus[.stravo] = true; isLoading = false; tryResume() }; saveHistory()
                }
            } catch { await MainActor.run { sourceStatus[selectedSource] = false; errorMessage = error.localizedDescription; isLoading = false } }
        }
    }
    
    func tryResume() { guard !didResume, resumeTime > 0 else { return }; didResume = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { player.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 600)) } }
    func fetchIMDB() async throws -> String {
        if let cached = imdbIDCache { return cached }
        var id: String?
        if mediaType == "tv" || seasonNumber != nil { id = try? await APIService.shared.fetchExternalIDs(tvId: movieId) }
        if id == nil || id?.isEmpty == true {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
            struct E: Codable { let imdb_id: String? }; id = try? JSONDecoder().decode(E.self, from: data).imdb_id
        }
        guard let finalID = id, !finalID.isEmpty else { throw StreamError.noStreamAvailable }
        imdbIDCache = finalID; return finalID
    }
    func lockToLandscape() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) } }
    func unlockOrientation() { if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) } }
    func saveProgress() { guard hasStartedPlaying, currentTime > 0, duration > 0 else { return }; appState.updateProgress(WatchProgress(movieId: movieId, movieTitle: movieTitle, posterPath: posterURL?.absoluteString, mediaType: mediaType, season: seasonNumber, episode: episodeNumber, currentTime: currentTime, duration: duration, lastWatched: Date())) }
    func saveHistory() { let m = Movie(id: movieId, title: movieTitle, overview: "", posterPath: posterURL?.absoluteString ?? "", backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: mediaType); if !appState.watchHistory.contains(where: { $0.id == movieId }) { appState.watchHistory.insert(m, at: 0); if appState.watchHistory.count > 50 { appState.watchHistory.removeLast() }; appState.save() } }
    func setupTimeObserver() { player.addPeriodicTimeObserver(forInterval:CMTime(seconds:0.5,preferredTimescale:600),queue:.main){t in if !isSeeking{currentTime=t.seconds}; if let d=player.currentItem?.duration,d.isNumeric{duration=d.seconds}} }
    func seek(_ s:Double){let t=max(0,min(currentTime+s,duration));player.seek(to:CMTime(seconds:t,preferredTimescale:600));currentTime=t}
    func toggleControls(){withAnimation(.easeInOut(duration:0.2)){showControls.toggle()};if showControls{resetControlsTimer()}}
    func resetControlsTimer(){controlsTimer?.invalidate();controlsTimer=Timer.scheduledTimer(withTimeInterval:4,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showControls=false}}}
    func resetVolumeTimer(){volumeTimer?.invalidate();volumeTimer=Timer.scheduledTimer(withTimeInterval:1.0,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showVolumeSlider=false}}}
    func resetBrightnessTimer(){brightnessTimer?.invalidate();brightnessTimer=Timer.scheduledTimer(withTimeInterval:1.0,repeats:false){_ in withAnimation(.easeInOut(duration:0.3)){showBrightnessSlider=false}}}
    func toggleOrientation(){guard let ws=UIApplication.shared.connectedScenes.first as? UIWindowScene else{return};ws.requestGeometryUpdate(.iOS(interfaceOrientations:ws.interfaceOrientation.isLandscape ? .portrait:.landscapeRight))}
    func formatTime(_ s:Double)->String{let m=Int(s)/60;let sec=Int(s)%60;return String(format:"%d:%02d",m,sec)}
}

struct CustomPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer; @Binding var pipController: AVPictureInPictureController?
    func makeUIViewController(context: Context) -> AVPlayerViewController { let vc = AVPlayerViewController(); vc.player = player; vc.showsPlaybackControls = false; vc.videoGravity = .resizeAspect; vc.allowsPictureInPicturePlayback = true; vc.canStartPictureInPictureAutomaticallyFromInline = true; try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay); try? AVAudioSession.sharedInstance().setActive(true); return vc }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) { DispatchQueue.main.async { if pipController == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer { pipController = AVPictureInPictureController(playerLayer: layer) } } }
}

struct TinySlider: View { let value: CGFloat; let icon: String
    var body: some View { VStack(spacing:4){Image(systemName:icon).font(.system(size:9)).foregroundColor(.white.opacity(0.5));ZStack(alignment:.bottom){Capsule().fill(.ultraThinMaterial.opacity(0.1)).overlay(Capsule().stroke(Color.white.opacity(0.04),lineWidth:0.5)).frame(width:6,height:60);Circle().fill(.white.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.6),lineWidth:1)).frame(width:16,height:16).shadow(color:.white.opacity(0.15),radius:4).offset(y:-value*52)} } }
}