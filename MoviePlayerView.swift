import SwiftUI
import AVKit
import MediaPlayer

class IMDBCache {
    static let shared = IMDBCache()
    private var cache: [Int: String] = [:]
    init() { if let d = UserDefaults.standard.data(forKey: "imdbCache_v3"), let c = try? JSONDecoder().decode([Int:String].self, from: d) { cache = c } }
    func get(_ id: Int) -> String? { cache[id] }
    func set(_ id: Int, value: String) { cache[id] = value; if let d = try? JSONEncoder().encode(cache) { UserDefaults.standard.set(d, forKey: "imdbCache_v3") } }
}

enum MovieSource: String, CaseIterable { case ntl="NTL", mediafusion="MediaFusion", yastream="YasStream", nguonc="NguonC" }
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL, wrongEpisode
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link"; case .invalidURL: return "URL lỗi"; case .wrongEpisode: return "Không tìm thấy tập này" }
    }
}

class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(source: MovieSource, imdbId: String, season: Int?, episode: Int?) async throws -> URL {
        switch source {
        case .ntl: return try await fetchNTL(imdbId, season: season, episode: episode)
        case .mediafusion: return try await fetchMediaFusion(imdbId, season: season, episode: episode)
        case .yastream: return try await fetchStremio(imdbId: imdbId, season: season, episode: episode)
        case .nguonc: throw StreamError.noStreamAvailable
        }
    }
    
    func fetchNTL(_ id: String, season: Int?, episode: Int?) async throws -> URL {
        var path = "/stream/movie/\(id).json"; if let s=season, let e=episode { path="/stream/series/\(id):\(s):\(e).json" }
        var r=URLRequest(url:URL(string:"https://tnluannguyen-ntl-stream.hf.space\(path)")!)
        r.timeoutInterval=15; r.setValue("Mozilla/5.0",forHTTPHeaderField:"User-Agent")
        let (d,_)=try await URLSession.shared.data(for:r)
        struct R:Codable{let streams:[S]?}; struct S:Codable{let url:String?}
        guard let u=(try? JSONDecoder().decode(R.self,from:d))?.streams?.first(where:{$0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true)})?.url, let vu=URL(string:u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    func fetchMediaFusion(_ id: String, season: Int?, episode: Int?) async throws -> URL {
        let cleanId=id.replacingOccurrences(of:"tt",with:"")
        var path="/stream/movie/\(cleanId).json"; if let s=season, let e=episode { path="/stream/series/\(cleanId):\(s):\(e).json" }
        var r=URLRequest(url:URL(string:"https://mediafusion.elfhosted.com\(path)")!)
        r.timeoutInterval=15; r.setValue("Mozilla/5.0",forHTTPHeaderField:"User-Agent"); r.setValue("https://mediafusion.elfhosted.com/",forHTTPHeaderField:"Referer")
        let (d,_)=try await URLSession.shared.data(for:r)
        struct R:Codable{let streams:[S]?}; struct S:Codable{let url:String?; let type:String?; let infoHash:String?}
        guard let u=(try? JSONDecoder().decode(R.self,from:d))?.streams?.first(where:{($0.type=="url"||$0.type=="http") && $0.infoHash==nil})?.url, let vu=URL(string:u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    func fetchStremio(imdbId: String, season: Int?, episode: Int?) async throws -> URL {
        let base="https://yastream.tamthai.de"; let cleanId=imdbId.replacingOccurrences(of:"tt",with:"")
        var path="/stream/movie/\(cleanId).json"; if let s=season, let e=episode { path="/stream/series/\(cleanId):\(s):\(e).json" }
        var r=URLRequest(url:URL(string:"\(base)\(path)")!)
        r.timeoutInterval=15; r.setValue("Mozilla/5.0",forHTTPHeaderField:"User-Agent"); r.setValue(base,forHTTPHeaderField:"Referer")
        let (d,_)=try await URLSession.shared.data(for:r)
        struct R:Codable{let streams:[S]?}; struct S:Codable{let url:String?; let type:String?; let infoHash:String?}
        guard let u=(try? JSONDecoder().decode(R.self,from:d))?.streams?.first(where:{($0.type=="url"||$0.type=="http") && $0.infoHash==nil})?.url, let vu=URL(string:u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    func fetchNguonCEmbed(title: String, episode: Int, movieId: Int, mediaType: String?) async throws -> (URL, String) {
        var searchTitle = title
        if let viName = try? await getVietnameseTitle(movieId: movieId, mediaType: mediaType) {
            searchTitle = viName
        }
        var slugs = try await findAllNguonCSlugs(title: searchTitle)
        if slugs.isEmpty { slugs = try await findAllNguonCSlugs(title: title) }
        
        for slug in slugs {
            guard let dtUrl = URL(string: "https://phim.nguonc.com/api/film/\(slug)") else { continue }
            var req = URLRequest(url: dtUrl)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            do {
                let (dd, _) = try await URLSession.shared.data(for: req)
                struct NguonCResponse: Codable { let movie: NguonCMovie? }
                struct NguonCMovie: Codable { let name: String?; let episodes: [NguonCServer]? }
                struct NguonCServer: Codable { let server_name: String?; let items: [NguonCItem]? }
                struct NguonCItem: Codable { let name: String?; let embed: String? }
                if let response = try? JSONDecoder().decode(NguonCResponse.self, from: dd),
                   let servers = response.movie?.episodes {
                    for server in servers {
                        guard let items = server.items else { continue }
                        for item in items {
                            if let name = item.name, Int(name) == episode,
                               let embed = item.embed, !embed.isEmpty,
                               let embedURL = URL(string: embed) {
                                return (embedURL, response.movie?.name ?? title)
                            }
                        }
                    }
                }
            } catch {}
        }
        throw StreamError.wrongEpisode
    }
    
    private func getVietnameseTitle(movieId: Int, mediaType: String?) async throws -> String? {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlStr = "https://api.themoviedb.org/3/\(type)/\(movieId)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=vi"
        guard let url = URL(string: urlStr) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct TMDBResponse: Codable { let name: String?; let title: String? }
        let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
        return response.name ?? response.title
    }
    
    private func findAllNguonCSlugs(title: String) async throws -> [String] {
        let keywords = [title, title.lowercased(),
                        title.replacingOccurrences(of: " ", with: "-").lowercased(),
                        title.folding(options: .diacriticInsensitive, locale: .current),
                        title.folding(options: .diacriticInsensitive, locale: .current).lowercased()]
        for kw in keywords {
            let encoded = kw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? kw
            guard let url = URL(string: "https://phim.nguonc.com/api/films/search?keyword=\(encoded)") else { continue }
            var req = URLRequest(url: url)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            struct SearchResponse: Codable { let items: [Item]? }
            struct Item: Codable { let slug: String? }
            if let response = try? JSONDecoder().decode(SearchResponse.self, from: data),
               let items = response.items, !items.isEmpty {
                return items.compactMap { $0.slug }
            }
        }
        return []
    }
}

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    var mediaType: String?; @State var seasonNumber: Int?; @State var episodeNumber: Int?; var posterURL: URL?
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var appState: AppState
    
    @State private var player = AVPlayer(); @State private var isLoading = true; @State private var errorMessage: String?
    @State private var selectedSource: MovieSource = .ntl; @State private var sourceStatus: [MovieSource: Bool] = [:]
    @State private var showSourceMenu = false; @State private var showSettings = false; @State private var showControls = true
    @State private var currentTime: Double = 0; @State private var duration: Double = 1; @State private var isSeeking = false
    @State private var controlsTimer: Timer?; @State private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    @State private var brightness: CGFloat = UIScreen.main.brightness; @State private var showVolumeSlider = false; @State private var showBrightnessSlider = false
    @State private var volumeTimer: Timer?; @State private var brightnessTimer: Timer?; @State private var pipController: AVPictureInPictureController?
    @State private var showOverlay = false; @State private var overlayOffset: CGFloat = UIScreen.main.bounds.height
    @State private var similarMovies: [Movie] = []; @State private var seasons: [TVSeason] = []
    @State private var selectedSeasonDetail: TVSeasonDetail?; @State private var selectedSeasonNumber: Int?
    @State private var currentMovie: Movie?; @State private var collectionMovies: [Movie] = []; @State private var selectedMovie: Movie?
    @State private var showNguonCWebView = false
    @State private var nguonCEmbedURL: URL?
    @State private var nguonCEpisodeName = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomPlayerVC(player: player, pipController: $pipController).ignoresSafeArea()
                .onAppear { player.play(); player.volume = volume; setupTimeObserver(); resetControlsTimer(); loadOverlayData() }
                .onDisappear { player.pause(); player.replaceCurrentItem(with: nil); controlsTimer?.invalidate() }
                .onTapGesture { if showOverlay { closeOverlay() } else { toggleControls() } }
            
            if showVolumeSlider { HStack { Spacer(); TinySlider(value: CGFloat(volume), icon: volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill").padding(.trailing, 14) } }
            if showBrightnessSlider { HStack { TinySlider(value: brightness, icon: "sun.max.fill").padding(.leading, 14); Spacer() } }
            Color.clear.frame(width: 60).position(x: UIScreen.main.bounds.width-30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showVolumeSlider{showVolumeSlider=true}; volume=min(max(volume+Float(-v.translation.height/120),0),1); player.volume=volume; resetVolumeTimer()}.onEnded{_ in resetVolumeTimer()})
            Color.clear.frame(width: 60).position(x: 30, y: UIScreen.main.bounds.height/2).gesture(DragGesture(minimumDistance:0).onChanged{v in if !showBrightnessSlider{showBrightnessSlider=true}; brightness=min(max(brightness+(-v.translation.height/120),0.01),1); UIScreen.main.brightness=brightness; resetBrightnessTimer()}.onEnded{_ in resetBrightnessTimer()})
            
            if isLoading { VStack(spacing:16){ProgressView().tint(.white).scaleEffect(1.5); Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.7)); Button{dismiss()}label:{Text("Quay lại").font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            if let err=errorMessage, !isLoading { VStack(spacing:16){Image(systemName:"wifi.slash").font(.system(size:40)).foregroundColor(.gray); Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center); HStack(spacing:10){ForEach(MovieSource.allCases,id:\.self){s in Button{selectedSource=s;loadStream()}label:{Text(s.rawValue).font(.caption2).foregroundColor(selectedSource==s ? .white:.gray).padding(.horizontal,10).padding(.vertical,6).background(Capsule().fill(selectedSource==s ? AnyShapeStyle(.ultraThinMaterial):AnyShapeStyle(Color.clear)))}}}; HStack(spacing:16){Button("Thử lại"){loadStream()}.font(.caption).foregroundColor(.white).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial)); Button("Quay lại"){dismiss()}.font(.caption).foregroundColor(.white.opacity(0.6)).padding(.horizontal,16).padding(.vertical,8).background(Capsule().fill(.ultraThinMaterial))}} }
            
            if showControls && errorMessage == nil && !isLoading && !showOverlay {
                HStack(spacing:64){Button{seek(-10)}label:{Image(systemName:"gobackward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}; Button{player.rate==0 ? player.play():player.pause()}label:{Image(systemName:player.rate==0 ? "play.fill":"pause.fill").font(.system(size:28,weight:.bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3))).overlay(Circle().stroke(Color.white.opacity(0.15),lineWidth:0.5))}; Button{seek(10)}label:{Image(systemName:"goforward.10").font(.system(size:20,weight:.light)).foregroundColor(.white.opacity(0.6)).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.2))).overlay(Circle().stroke(Color.white.opacity(0.1),lineWidth:0.5))}}
                VStack{Spacer(); VStack(spacing:6){Slider(value:$currentTime,in:0...max(duration,1)){e in isSeeking=e; if !e{player.seek(to:CMTime(seconds:currentTime,preferredTimescale:600))}}.accentColor(.white).padding(.horizontal); HStack{Text(formatTime(currentTime)).font(.caption2).foregroundColor(.white.opacity(0.7));Spacer();Text(formatTime(duration)).font(.caption2).foregroundColor(.white.opacity(0.7))}.padding(.horizontal); HStack{Spacer();Button{toggleOrientation()}label:{Image(systemName:"rotate.right").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}}.padding(.horizontal).padding(.bottom,20)}.background(LinearGradient(colors:[.clear,.black.opacity(0.5)],startPoint:.top,endPoint:.bottom))}
                VStack{HStack{Button{if let ws=UIApplication.shared.connectedScenes.first as? UIWindowScene{ws.requestGeometryUpdate(.iOS(interfaceOrientations:.portrait))}; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){dismiss()}}label:{Image(systemName:"chevron.left").font(.system(size:16,weight:.semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Spacer();Text(movieTitle).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1);Spacer();HStack(spacing:8){Button{pipController?.startPictureInPicture()}label:{Image(systemName:"pip.enter").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Button{showSettings=true}label:{Image(systemName:"gearshape.fill").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))};Button{showSourceMenu=true}label:{Image(systemName:"antenna.radiowaves.left.and.right").font(.system(size:14)).foregroundColor(.white.opacity(0.8)).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.25))).overlay(Circle().stroke(Color.white.opacity(0.12),lineWidth:0.5))}}}.padding(.horizontal,8).padding(.top,50);Spacer()}
            }
            
            if showOverlay { youtubeOverlay }
            if showSourceMenu { popupBackground{showSourceMenu=false}; sourcePopup }
            if showSettings { popupBackground{showSettings=false}; settingsPopup }
        }
        .statusBarHidden()
        .gesture(DragGesture(minimumDistance:20).onChanged{v in if !showOverlay && v.translation.height < -40 && v.startLocation.y > UIScreen.main.bounds.height-250 { showOverlay=true; overlayOffset=300 }; if showOverlay && v.translation.height > 40 { overlayOffset=max(0,v.translation.height) }}.onEnded{v in if showOverlay && v.translation.height > 100 { closeOverlay() } else if showOverlay { withAnimation(.spring(response:0.3,dampingFraction:0.8)){overlayOffset=0} }})
        .task { loadStream() }
        .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        .fullScreenCover(isPresented: $showNguonCWebView) {
            if let url = nguonCEmbedURL {
                NguonCPlayerView(embedURL: url, episodeName: nguonCEpisodeName)
            }
        }
    }
    
    func openMovie(_ movie: Movie) { closeOverlay(); player.pause(); if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene { ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { selectedMovie = movie } }
    func closeOverlay() { withAnimation(.spring(response:0.25,dampingFraction:0.8)){overlayOffset=UIScreen.main.bounds.height}; DispatchQueue.main.asyncAfter(deadline:.now()+0.25){showOverlay=false} }
    
    var youtubeOverlay: some View {
        ZStack(alignment:.bottom){ Color.black.opacity(0.4).ignoresSafeArea().onTapGesture{closeOverlay()}
            VStack(spacing:0){ Capsule().fill(.white.opacity(0.5)).frame(width:40,height:5).padding(.top,10)
                ScrollView{ VStack(alignment:.leading,spacing:16){
                    if let movie=currentMovie { VStack(alignment:.leading,spacing:8){ Text("Đang xem").font(.title3).fontWeight(.bold).foregroundColor(.white); HStack(spacing:10){CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:70,height:105).clipShape(RoundedRectangle(cornerRadius:10)); VStack(alignment:.leading,spacing:4){Text(movie.title).font(.headline).foregroundColor(.white).lineLimit(2); Text("⭐ \(movie.ratingText)").font(.caption).foregroundColor(.yellow); if !seasons.isEmpty{Text("\(seasons.count) mùa • \(seasons.reduce(0){$0+$1.episodeCount}) tập").font(.caption).foregroundColor(.gray)}; if !collectionMovies.isEmpty{Text("\(collectionMovies.count) phần").font(.caption).foregroundColor(.gray)}};Spacer()}.padding(10).background(RoundedRectangle(cornerRadius:12).fill(.ultraThinMaterial.opacity(0.3))).overlay(RoundedRectangle(cornerRadius:12).stroke(Color.white.opacity(0.1),lineWidth:0.5))
                        if !collectionMovies.isEmpty { ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(collectionMovies.filter{$0.id != movieId}){part in Button{openMovie(part)}label:{VStack(spacing:4){CachedAsyncImage(url:part.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:70,height:105).clipShape(RoundedRectangle(cornerRadius:8)); Text(part.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:70)}}}}} }
                        if !seasons.isEmpty { ScrollView(.horizontal,showsIndicators:false){HStack(spacing:6){ForEach(seasons){season in Button{selectedSeasonNumber=season.seasonNumber; Task{selectedSeasonDetail=try? await APIService.shared.fetchSeasonDetail(tvId:movieId,seasonNumber:season.seasonNumber)}}label:{Text(season.name).font(.caption).fontWeight(selectedSeasonNumber==season.seasonNumber ? .bold:.regular).foregroundColor(selectedSeasonNumber==season.seasonNumber ? .white:.gray).padding(.horizontal,12).padding(.vertical,6).background(Capsule().fill(selectedSeasonNumber==season.seasonNumber ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5)):AnyShapeStyle(.ultraThinMaterial.opacity(0.2))))}}}}; if let detail=selectedSeasonDetail { LazyVGrid(columns:[GridItem(.flexible(),spacing:6),GridItem(.flexible(),spacing:6),GridItem(.flexible(),spacing:6)],spacing:6){ForEach(detail.episodes){ep in Button{loadStream(season: ep.seasonNumber, episode: ep.episodeNumber); closeOverlay()}label:{VStack(spacing:3){ZStack{RoundedRectangle(cornerRadius:6).fill(.ultraThinMaterial.opacity(0.3)).frame(height:50);Image(systemName:"play.circle.fill").foregroundColor(.white.opacity(0.7)).font(.system(size:18))};Text("Tập \(ep.episodeNumber)").font(.system(size:8)).foregroundColor(.white).lineLimit(1)}}}} } } } }
                    if !similarMovies.isEmpty { VStack(alignment:.leading,spacing:8){Text("Phim tương tự").font(.title3).fontWeight(.bold).foregroundColor(.white); ScrollView(.horizontal,showsIndicators:false){HStack(spacing:8){ForEach(similarMovies.prefix(15)){movie in Button{openMovie(movie)}label:{VStack(spacing:4){CachedAsyncImage(url:movie.posterURL).aspectRatio(2/3,contentMode:.fill).frame(width:90,height:135).clipShape(RoundedRectangle(cornerRadius:10));Text(movie.title).font(.system(size:9)).foregroundColor(.white).lineLimit(2).frame(width:90)}}}}}} }
                }.padding()}.clipped()
            }
            .frame(height:UIScreen.main.bounds.height*0.55)
            .background(RoundedRectangle(cornerRadius:20).fill(.ultraThinMaterial.opacity(0.7)).overlay(RoundedRectangle(cornerRadius:20).stroke(Color.white.opacity(0.15),lineWidth:0.5)))
            .offset(y:overlayOffset)
        }
    }
    
    var sourcePopup: some View { VStack(spacing:8){Text("nguồn phát").font(.system(size:11,weight:.medium,design:.rounded)).foregroundColor(.white.opacity(0.8)); ForEach(MovieSource.allCases,id:\.self){src in Button{selectedSource=src;showSourceMenu=false;loadStream()}label:{HStack(spacing:6){Circle().fill(sourceStatus[src]==true ? .green:sourceStatus[src]==false ? .red:.gray).frame(width:5,height:5);Text(src.rawValue).font(.system(size:12,design:.rounded)).foregroundColor(.white);if selectedSource==src{Image(systemName:"checkmark").font(.system(size:9)).foregroundColor(.white)}}.padding(.horizontal,12).padding(.vertical,8).background(RoundedRectangle(cornerRadius:10).fill(.ultraThinMaterial.opacity(0.4))).overlay(RoundedRectangle(cornerRadius:10).stroke(Color.white.opacity(0.15),lineWidth:0.5))}}; Text("© 2026 emmew").font(.system(size:7,design:.rounded)).foregroundColor(.white.opacity(0.3))}.padding(14).background(RoundedRectangle(cornerRadius:18).fill(.ultraThinMaterial.opacity(0.5))).overlay(RoundedRectangle(cornerRadius:18).stroke(Color.white.opacity(0.2),lineWidth:0.8)).shadow(color:.black.opacity(0.2),radius:10,y:5).frame(width:170) }
    var settingsPopup: some View { VStack(spacing:12){Text("Cài đặt").font(.system(size:13,weight:.bold,design:.rounded)).foregroundColor(.white); Text("Chất lượng").font(.system(size:11,design:.rounded)).foregroundColor(.white.opacity(0.6)); LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8){ForEach(["Auto","1080p","720p","480p","360p"],id:\.self){q in qualityButton(q)}}; Divider().background(Color.white.opacity(0.1)); Text("Phụ đề").font(.system(size:11,design:.rounded)).foregroundColor(.white.opacity(0.6)); Text("Không có sẵn").font(.system(size:12,design:.rounded)).foregroundColor(.white.opacity(0.5)); Divider().background(Color.white.opacity(0.1)); Text("Tốc độ").font(.system(size:11,design:.rounded)).foregroundColor(.white.opacity(0.6)); Text("1.0x").font(.system(size:12,design:.rounded)).foregroundColor(.white.opacity(0.5)); Text("© 2026 emmew").font(.system(size:7,design:.rounded)).foregroundColor(.white.opacity(0.2)).padding(.top,4) }.padding(18).frame(width:220).background(RoundedRectangle(cornerRadius:22).fill(.ultraThinMaterial.opacity(0.7)).overlay(RoundedRectangle(cornerRadius:22).stroke(Color.white.opacity(0.25),lineWidth:1))).shadow(color:.black.opacity(0.4),radius:20,y:10) }
    func qualityButton(_ q: String) -> some View { Button{loadStream();showSettings=false}label:{Text(q).font(.system(size:12,weight:.regular,design:.rounded)).foregroundColor(.white.opacity(0.6)).frame(maxWidth:.infinity).padding(.vertical,8).background(RoundedRectangle(cornerRadius:8).fill(Color.white.opacity(0.05)))} }
    func popupBackground(action:@escaping()->Void)->some View { Color.black.opacity(0.01).ignoresSafeArea().onTapGesture{action()} }
    
    func loadOverlayData() { Task { similarMovies=(try? await APIService.shared.similar(movieId:movieId,mediaType:mediaType)) ?? []; if mediaType=="tv"{seasons=(try? await APIService.shared.fetchTVSeasons(tvId:movieId)) ?? []}; if let detail=try? await APIService.shared.movieDetail(movieId:movieId),let cid=detail.belongsToCollection?.id,let col=try? await APIService.shared.collectionDetail(collectionId:cid){collectionMovies=col.parts}; currentMovie=Movie(id:movieId,title:movieTitle,overview:"",posterPath:posterURL?.absoluteString ?? "",backdropPath:nil,voteAverage:0,releaseDate:nil,genreIds:nil,originalTitle:nil,popularity:nil,voteCount:nil,adult:false,originalLanguage:nil,mediaType:mediaType) } }
    
    func loadStream(season: Int? = nil, episode: Int? = nil) {
        let s = season ?? seasonNumber; let e = episode ?? episodeNumber
        isLoading = true; errorMessage = nil; sourceStatus[selectedSource] = nil
        Task {
            do {
                if selectedSource == .nguonc {
                    guard let ep = e else { throw StreamError.wrongEpisode }
                    let (embedURL, movieName) = try await MovieStreamService.shared.fetchNguonCEmbed(title: movieTitle, episode: ep, movieId: movieId, mediaType: mediaType)
                    await MainActor.run {
                        nguonCEmbedURL = embedURL
                        nguonCEpisodeName = "\(movieName) - Tập \(ep)"
                        isLoading = false
                        showNguonCWebView = true
                    }
                    return
                }
                let imdbId: String
                if mediaType == "tv" { imdbId = try await APIService.shared.fetchExternalIDs(tvId: movieId) ?? "" }
                else { if let c = IMDBCache.shared.get(movieId) { imdbId = c } else { imdbId = try await fetchMovieIMDbId(); if !imdbId.isEmpty { IMDBCache.shared.set(movieId, value: imdbId) } } }
                guard !imdbId.isEmpty else { throw StreamError.noStreamAvailable }
                let url = try await MovieStreamService.shared.getStreamURL(source: selectedSource, imdbId: imdbId, season: s, episode: e)
                let item = AVPlayerItem(url: url)
                await MainActor.run { player.replaceCurrentItem(with: item); player.play(); sourceStatus[selectedSource] = true; isLoading = false }
                saveHistory()
            } catch { await MainActor.run { errorMessage = error.localizedDescription; isLoading = false } }
        }
    }
    
    func saveHistory() { let m=Movie(id:movieId,title:movieTitle,overview:"",posterPath:posterURL?.absoluteString ?? "",backdropPath:nil,voteAverage:0,releaseDate:nil,genreIds:nil,originalTitle:nil,popularity:nil,voteCount:nil,adult:false,originalLanguage:nil,mediaType:mediaType); if !appState.watchHistory.contains(where:{$0.id==movieId}){appState.watchHistory.insert(m,at:0); if appState.watchHistory.count>50{appState.watchHistory.removeLast()}; appState.save()} }
    func fetchMovieIMDbId() async throws -> String { let (d,_)=try await URLSession.shared.data(from:URL(string:"https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E:Codable{let imdb_id:String?}; guard let id=try JSONDecoder().decode(E.self,from:d).imdb_id else{throw StreamError.noStreamAvailable}; return id }
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
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController(); vc.player = player; vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect; vc.allowsPictureInPicturePlayback = true
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
        try? AVAudioSession.sharedInstance().setActive(true)
        return vc
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {
        DispatchQueue.main.async { if pipController == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer { pipController = AVPictureInPictureController(playerLayer: layer) } }
    }
}

struct TinySlider: View { let value: CGFloat; let icon: String
    var body: some View { VStack(spacing:4){ Image(systemName:icon).font(.system(size:9)).foregroundColor(.white.opacity(0.5)); ZStack(alignment:.bottom){ Capsule().fill(.ultraThinMaterial.opacity(0.1)).overlay(Capsule().stroke(Color.white.opacity(0.04),lineWidth:0.5)).frame(width:6,height:60); Circle().fill(.white.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.6),lineWidth:1)).frame(width:16,height:16).shadow(color:.white.opacity(0.15),radius:4).offset(y:-value*52) } } }
}