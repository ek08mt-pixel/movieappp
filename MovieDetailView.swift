import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie
    var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showPlayer = false
    @State private var showBookingSheet = false
    @State private var showFullOverview = false
    @State private var showImages = false
    @State private var playSeason: Int? = nil
    @State private var playEpisode: Int? = nil
    @State private var expandedSeason: Int? = nil
    @State private var ratings: (tmdb: String?, imdb: String?, rottenTomatoes: String?) = (nil, nil, nil)
    @State private var episodeSearchText = ""
    @State private var showEpisodeSearch = false
    @StateObject private var downloadManager = DownloadManager.shared
    
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    
    var playerMediaType: String? {
        if let mt = movie.mediaType { return mt }
        if playSeason != nil || playEpisode != nil { return "tv" }
        return nil
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                CachedAsyncImage(url: movie.backdropURL, size: .backdrop)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height + 100)
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.55))
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL, size: .backdrop)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 320).clipped()
                            .overlay(LinearGradient(colors: [.clear, .clear, Color.black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
                        }.padding(.top, 54).padding(.leading, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.6), radius: 8).offset(y: -45)
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                HStack(spacing: 6) { Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption); Text(movie.ratingText).foregroundColor(.white).font(.caption).bold(); Text("•").foregroundColor(.gray); Text(releaseDateText).foregroundColor(.gray).font(.caption) }
                                Button { showFullOverview.toggle() } label: { Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview).font(.system(size: 13)).foregroundColor(.gray).lineLimit(showFullOverview ? nil : 4).multilineTextAlignment(.leading) }
                            }
                        }
                        
                        ratingsBar
                        
                        HStack(spacing: 10) {
                            Button { playSeason = nil; playEpisode = nil; showPlayer = true } label: {
                                Label("Xem", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } }
                                else { appState.favorites.append(movie) }
                                appState.save()
                            } label: {
                                Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu", systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                if appState.watchedMovies.contains(where: { $0.id == movie.id }) {
                                    appState.watchedMovies.removeAll { $0.id == movie.id }
                                } else {
                                    appState.watchedMovies.append(movie)
                                }
                                appState.save()
                            } label: {
                                Label(appState.watchedMovies.contains(where: { $0.id == movie.id }) ? "Đã xem" : "Đánh dấu đã xem",
                                      systemImage: appState.watchedMovies.contains(where: { $0.id == movie.id }) ? "checkmark.circle.fill" : "checkmark.circle")
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                        }
                        
                        if showBooking { Button { showBookingSheet = true } label: { Label("Đặt vé", systemImage: "ticket.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) } }
                        if let r = vm.detail?.runtime, r > 0 { HStack(spacing: 12) { Label("\(r) phút", systemImage: "clock.fill").font(.system(size: 11)).foregroundColor(.gray); if let g = vm.detail?.genres, !g.isEmpty { Text(g.prefix(3).map{$0.name}.joined(separator: " • ")).font(.system(size: 11)).foregroundColor(.gray) } } }
                        
                        if !vm.collectionMovies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Cùng series").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.top, 8)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) { ForEach(vm.collectionMovies.filter { $0.id != movie.id }) { part in NavigationLink(destination: MovieDetailView(movie: part)) { VStack(spacing: 6) { CachedAsyncImage(url: part.posterURL, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10)); Text(part.title).font(.system(size: 10)).foregroundColor(.white).lineLimit(2).frame(width: 100); Text(part.yearText).font(.system(size: 9)).foregroundColor(.gray) } } } }
                                }
                            }
                        }
                        
                        if !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Seasons & Episodes").font(.title3).fontWeight(.bold).foregroundColor(.white)
                                    Spacer()
                                    Button {
                                        withAnimation { showEpisodeSearch.toggle() }
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(8)
                                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                                    }
                                }
                                
                                if showEpisodeSearch {
                                    HStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass").foregroundColor(.gray).font(.system(size: 13))
                                        TextField("Nhập số tập...", text: $episodeSearchText)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .keyboardType(.numberPad)
                                            .onChange(of: episodeSearchText) { query in
                                                searchAndJumpToEpisode(query: query)
                                            }
                                        if !episodeSearchText.isEmpty {
                                            Button {
                                                episodeSearchText = ""
                                                withAnimation { showEpisodeSearch = false }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.system(size: 14))
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.3)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
                                ForEach(vm.seasons) { season in
                                    VStack(spacing: 0) {
                                        Button {
                                            withAnimation { expandedSeason = expandedSeason == season.seasonNumber ? nil : season.seasonNumber
                                                if expandedSeason == season.seasonNumber { Task { await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season.seasonNumber) } }
                                            }
                                        } label: {
                                            HStack {
                                                if let url = season.posterURL { CachedAsyncImage(url: url, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 6)) }
                                                else { RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 40, height: 60).overlay(Image(systemName: "tv").foregroundColor(.white.opacity(0.5))) }
                                                VStack(alignment: .leading, spacing: 2) { Text(season.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white); Text("\(season.episodeCount) tập").font(.system(size: 11)).foregroundColor(.gray) }
                                                Spacer()
                                                Image(systemName: expandedSeason == season.seasonNumber ? "chevron.up" : "chevron.down").foregroundColor(.gray).font(.caption)
                                            }.padding(.vertical, 8)
                                        }
                                        if expandedSeason == season.seasonNumber {
                                            Divider().background(Color.white.opacity(0.15))
                                            if let detail = vm.selectedSeason, detail.seasonNumber == season.seasonNumber {
                                                LazyVStack(spacing: 6) {
                                                    ForEach(detail.episodes) { ep in
                                                        HStack(spacing: 10) {
                                                            Button {
                                                                playSeason = ep.seasonNumber
                                                                playEpisode = ep.episodeNumber
                                                                showPlayer = true
                                                            } label: {
                                                                HStack(spacing: 10) {
                                                                    if let still = ep.stillURL {
                                                                        CachedAsyncImage(url: still, size: .detail)
                                                                            .aspectRatio(16/9, contentMode: .fill)
                                                                            .frame(width: 80, height: 45)
                                                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                                                    } else {
                                                                        RoundedRectangle(cornerRadius: 6)
                                                                            .fill(.ultraThinMaterial)
                                                                            .frame(width: 80, height: 45)
                                                                            .overlay(Image(systemName: "play.rectangle").foregroundColor(.white.opacity(0.4)))
                                                                    }
                                                                    VStack(alignment: .leading, spacing: 2) {
                                                                        Text("Tập \(ep.episodeNumber)")
                                                                            .font(.system(size: 11, weight: .bold))
                                                                            .foregroundColor(.white)
                                                                        Text(ep.name)
                                                                            .font(.system(size: 10))
                                                                            .foregroundColor(.gray)
                                                                            .lineLimit(1)
                                                                        if let rt = ep.runtime {
                                                                            Text("\(rt) phút")
                                                                                .font(.system(size: 9))
                                                                                .foregroundColor(.gray)
                                                                        }
                                                                    }
                                                                    Spacer()
                                                                    Image(systemName: "play.circle")
                                                                        .foregroundColor(.white.opacity(0.6))
                                                                        .font(.system(size: 18))
                                                                }
                                                            }
                                                            
                                                            EpisodeDownloadButton(
                                                                movieId: movie.id,
                                                                title: movie.title,
                                                                posterPath: movie.posterPath,
                                                                mediaType: movie.mediaType,
                                                                season: ep.seasonNumber,
                                                                episode: ep.episodeNumber,
                                                                episodeName: ep.name
                                                            )
                                                        }
                                                        .padding(.vertical, 6)
                                                    }
                                                }
                                            } else {
                                                ProgressView().tint(.white).padding()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !vm.images.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack { Text("Hình ảnh").font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Spacer(); Button("Xem tất cả") { showImages = true }.font(.system(size: 12)).foregroundColor(.white) }
                                ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(vm.images.prefix(8), id: \.self) { u in CachedAsyncImage(url: u, size: .backdrop).aspectRatio(16/9, contentMode: .fill).frame(width: 180, height: 100).clipShape(RoundedRectangle(cornerRadius: 10)) } } }
                            }
                        }
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal) { HStack(spacing: 16) { ForEach(vm.actors.prefix(15)) { a in NavigationLink(destination: ActorDetailView(actor: a)) { VStack(spacing: 6) { CachedAsyncImage(url: a.profileURL, size: .detail).aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(Circle()); Text(a.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60) } } } } }
                        }
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal) { LazyHStack(spacing: 12) { ForEach(vm.similar.prefix(12)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { VStack(spacing: 6) { CachedAsyncImage(url: m.posterURL, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.3), radius: 4); Text(m.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(width: 120) } } } } }
                        }
                    }.padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }.ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true).toolbar(.hidden, for: .tabBar)
        .task {
            await vm.load(movieId: movie.id, mediaType: movie.mediaType)
            await fetchRatings()
        }
        .fullScreenCover(isPresented: $showPlayer) { 
    MoviePlayerView(movieId: movie.id, movieTitle: movie.originalTitle ?? movie.title, mediaType: playerMediaType, seasonNumber: playSeason, episodeNumber: playEpisode, posterURL: movie.posterURL)
        .environmentObject(appState)
        .modifier(LandscapeModifier())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                }
            }
        }
}
.sheet(isPresented: $showImages) { MovieImagesView(images: vm.images, title: movie.title) }
.sheet(isPresented: $showBookingSheet) { NavigationStack { WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))").ignoresSafeArea().toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } } } }
.onDisappear {
    if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    }
}
    
    func searchAndJumpToEpisode(query: String) {
        guard let episodeNumber = Int(query), episodeNumber > 0 else { return }
        
        var accumulatedEps = 0
        for season in vm.seasons {
            let count = season.episodeCount
            if episodeNumber <= accumulatedEps + count {
                _ = episodeNumber - accumulatedEps
                withAnimation {
                    expandedSeason = season.seasonNumber
                }
                Task {
                    await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season.seasonNumber)
                }
                return
            }
            accumulatedEps += count
        }
    }
    
    var ratingsBar: some View {
        let hasAnyRating = ratings.tmdb != nil || ratings.imdb != nil || ratings.rottenTomatoes != nil
        guard hasAnyRating else { return AnyView(EmptyView()) }
        
        return AnyView(
            HStack(spacing: 0) {
                if let tmdb = ratings.tmdb {
                    ratingItem(icon: "t.square.fill", color: .yellow, label: "TMDb", value: tmdb)
                }
                
                if ratings.tmdb != nil && (ratings.imdb != nil || ratings.rottenTomatoes != nil) {
                    Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 24)
                }
                
                if let imdb = ratings.imdb {
                    ratingItem(icon: "i.square.fill", color: .orange, label: "IMDb", value: imdb)
                }
                
                if ratings.imdb != nil && ratings.rottenTomatoes != nil {
                    Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 24)
                }
                
                if let rt = ratings.rottenTomatoes {
                    ratingItem(icon: "r.square.fill", color: .red, label: "RT", value: rt)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
        )
    }
    
    func ratingItem(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    func fetchRatings() async {
        let imdbID: String
        if movie.mediaType == "tv" {
            imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movie.id)) ?? ""
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movie.id)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
                struct E: Codable { let imdb_id: String? }
                imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
            } catch { return }
        }
        
        guard !imdbID.isEmpty else { return }
        
        let tmdbScore: String? = {
            if movie.voteAverage > 0 {
                return String(format: "%.1f/10", movie.voteAverage)
            }
            return nil
        }()
        
        var imdbRating: String? = nil
        var rtRating: String? = nil
        
        if !imdbID.isEmpty {
            let omdbURL = "https://www.omdbapi.com/?i=\(imdbID)&apikey=3c3cfb9e"
            if let url = URL(string: omdbURL),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let imdbScore = json["imdbRating"] as? String, imdbScore != "N/A" {
                    imdbRating = "\(imdbScore)/10"
                }
                
                if let ratings = json["Ratings"] as? [[String: Any]] {
                    for rating in ratings {
                        if let source = rating["Source"] as? String, source == "Rotten Tomatoes",
                           let value = rating["Value"] as? String {
                            rtRating = value
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            ratings = (tmdbScore, imdbRating, rtRating)
        }
    }
}
}
struct EpisodeDownloadButton: View {
    let movieId: Int
    let title: String
    let posterPath: String?
    let mediaType: String?
    let season: Int
    let episode: Int
    let episodeName: String?
    
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoadingURL = false
    
    var body: some View {
        Button {
            handleDownload()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: geo.size.width * currentProgress, height: 40)
                        .animation(.easeInOut(duration: 0.3), value: currentProgress)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Group {
                    if isLoadingURL {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        switch currentStatus {
                        case .waiting:
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        case .downloading:
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        case .paused:
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        case .completed:
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        case .failed:
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoadingURL)
        .alert("Thông báo", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var currentStatus: DownloadManager.DownloadStatus {
        downloadManager.downloadStatus(movieId: movieId, season: season, episode: episode)
    }
    
    private var currentProgress: Double {
        downloadManager.downloadProgress(movieId: movieId, season: season, episode: episode)
    }
    
    private func handleDownload() {
        switch currentStatus {
        case .waiting:
            resolveAndStartDownload()
        case .downloading:
            downloadManager.pauseDownload(movieId: movieId, season: season, episode: episode)
        case .paused:
            downloadManager.resumeDownload(movieId: movieId, season: season, episode: episode)
        case .completed:
            alertMessage = "Đã tải xong: \(title) - Tập \(episode)"
            showAlert = true
        case .failed:
            isLoadingURL = true
            Task {
                let viewModel = MovieDetailViewModel()
                let debugInfo = await viewModel.getDebugInfo(
                    movieId: movieId,
                    mediaType: mediaType,
                    season: season,
                    episode: episode
                )
                await MainActor.run {
                    alertMessage = "Lỗi tải\n\nDebug:\n\(debugInfo)"
                    showAlert = true
                    isLoadingURL = false
                }
            }
        }
    }
    
    private func resolveAndStartDownload() {
        guard !isLoadingURL else { return }
        isLoadingURL = true
        
        Task {
            let viewModel = MovieDetailViewModel()
            if let url = await viewModel.getVideoURL(
                movieId: movieId,
                mediaType: mediaType,
                season: season,
                episode: episode,
                title: title
            ) {
                await MainActor.run {
                    downloadManager.startDownload(
                        url: url,
                        movieId: movieId,
                        title: title,
                        posterPath: posterPath,
                        mediaType: mediaType,
                        season: season,
                        episode: episode,
                        episodeName: episodeName
                    )
                    isLoadingURL = false
                }
            } else {
                await MainActor.run {
                    alertMessage = "Không tìm thấy link video"
                    showAlert = true
                    isLoadingURL = false
                }
            }
        }
    }
}

struct MovieImagesView: View {
    let images: [URL]; let title: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 0) { HStack { Text(title).font(.headline).foregroundColor(.white); Spacer(); Button("Đóng") { dismiss() }.foregroundColor(.gray) }.padding()
                TabView { ForEach(images, id: \.self) { url in CachedAsyncImage(url: url, size: .backdrop).aspectRatio(contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16) } }.tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false; if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }; return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}