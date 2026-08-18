import SwiftUI
import WebKit
import UIKit

struct MovieDetailView: View {
    let movie: Movie
    var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showBookingSheet = false
    @State private var showFullOverview = false
    @State private var showImages = false
    @State private var playSeason: Int? = nil
    @State private var playEpisode: Int? = nil
    @State private var expandedSeason: Int? = nil
    @State private var ratings: (tmdb: String?, imdb: String?, rottenTomatoes: String?) = (nil, nil, nil)
    @State private var episodeSearchText = ""
    @State private var showEpisodeSearch = false
    @State private var selectedSource = "Emew 1"
    @State private var showSavePopup = false
    @State private var searchSeason: Int = 1
    @State private var searchedEpisode: Int? = nil
    @State private var searchText = ""
    @State private var useNewTheme = false
    
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    
    var playerMediaType: String? {
        if let mt = movie.mediaType { return mt }
        if playSeason != nil || playEpisode != nil { return "tv" }
        return nil
    }
    
    var isWatched: (Int, Int) -> Bool {
        { season, episode in
            appState.watchProgressList.contains { $0.movieId == movie.id && $0.season == season && $0.episode == episode && $0.currentTime > 0 }
        }
    }
    
    var body: some View {
    if useNewTheme {
        NewThemeDetailView(movie: movie, vm: vm)
            .environmentObject(appState)
    } else {
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
                            .frame(width: UIScreen.main.bounds.width, height: 320)
                            .clipped()
                            .overlay(LinearGradient(colors: [.clear, .clear, Color.black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
                        }
                        .padding(.top, 54).padding(.leading, 20)
                        
                        HStack {
    Spacer()
    Button {
        useNewTheme = true
    } label: {
        Image(systemName: "circle.grid.2x2")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(10)
            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
    }
}
.padding(.top, 54)
.padding(.trailing, 20)
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                if let r = vm.detail?.runtime, r > 0 {
                                    Text("\(r)m").font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                                }
                                if let g = vm.detail?.genres, !g.isEmpty {
                                    Text(g.prefix(2).compactMap { genre in
                                        let mapping: [String: String] = [
                                            "Phim Hành Động": "Action", "Phim Phiêu Lưu": "Adventure", "Phim Hoạt Hình": "Animation",
                                            "Phim Hài": "Comedy", "Phim Hình Sự": "Crime", "Phim Tài Liệu": "Documentary",
                                            "Phim Chính Kịch": "Drama", "Phim Gia Đình": "Family", "Phim Giả Tượng": "Fantasy",
                                            "Phim Lịch Sử": "History", "Phim Kinh Dị": "Horror", "Phim Nhạc": "Music",
                                            "Phim Bí Ẩn": "Mystery", "Phim Lãng Mạn": "Romance", "Phim Khoa Học Viễn Tưởng": "Sci-Fi",
                                            "Phim TV": "TV Movie", "Phim Gây Cấn": "Thriller", "Phim Chiến Tranh": "War",
                                            "Phim Miền Tây": "Western"
                                        ]
                                        return mapping[genre.name] ?? genre.name.replacingOccurrences(of: "Phim ", with: "")
                                    }.joined(separator: " • "))
                                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(.bottom, 16).padding(.trailing, 20)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack(alignment: .bottom) {
                                CachedAsyncImage(url: movie.posterURL, size: .detail)
                                    .aspectRatio(2/3, contentMode: .fill)
                                    .frame(width: 100, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: .black.opacity(0.6), radius: 8)
                                
                                if let quality = getBestQuality() {
                                    Text(quality)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.8)))
                                        .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5))
                                        .padding(.bottom, 6)
                                }
                            }
                            .offset(y: -45)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    if let tmdb = ratings.tmdb {
                                        HStack(spacing: 3) {
                                            Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow)
                                            Text(tmdb).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                        }
                                        Text("•").foregroundColor(.gray)
                                    }
                                    Text(releaseDateText).foregroundColor(.gray).font(.caption)
                                    Text("•").foregroundColor(.gray)
                                    Text(vm.detail?.productionCompanies?.first?.name ?? "N/A").foregroundColor(.gray).font(.caption)
                                }
                                
                                Button {
                                    showFullOverview.toggle()
                                } label: {
                                    Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview)
                                        .font(.system(size: 13)).foregroundColor(.gray)
                                        .lineLimit(showFullOverview ? nil : 4).multilineTextAlignment(.leading)
                                }
                            }
                        }
                        
                        if !vm.serverList.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(vm.serverList.prefix(3), id: \.name) { server in
                                    Text(server.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(.white.opacity(0.08)))
                                        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(["Emew 1", "Emew 2", "Emew 3"], id: \.self) { source in
                                Button {
                                    selectedSource = source
                                } label: {
                                    Text(source).font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedSource == source ? .white : .white.opacity(0.5))
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Capsule().fill(selectedSource == source ? .white.opacity(0.2) : .white.opacity(0.05)))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack(spacing: 10) {
                            Button(action: handlePlayButton) {
                                Label("Xem", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                if appState.favorites.contains(where: { $0.id == movie.id }) {
                                    appState.favorites.removeAll { $0.id == movie.id }
                                    appState.save()
                                } else {
                                    showSavePopup = true
                                }
                            } label: {
                                Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu",
                                      systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "bookmark.fill")
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                        }
                        
                        if !vm.collectionMovies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Cùng series").font(.title3).fontWeight(.bold).foregroundColor(.white)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(vm.collectionMovies.filter { $0.id != movie.id }) { part in
                                            NavigationLink(destination: MovieDetailView(movie: part)) {
                                                VStack(spacing: 6) {
                                                    CachedAsyncImage(url: part.posterURL)
                                                        .aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10))
                                                    Text(part.title).font(.system(size: 10)).foregroundColor(.white).lineLimit(2).frame(width: 100)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .center, spacing: 10) {
                                    Text("Seasons & Episodes")
                                        .font(.title3).fontWeight(.bold).foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Search box nhỏ ngang
                                    HStack(spacing: 4) {
                                        // Season picker tap - custom dropdown
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                showEpisodeSearch.toggle()
                                            }
                                        } label: {
                                            HStack(spacing: 2) {
                                                Text("S\(searchSeason)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                Image(systemName: showEpisodeSearch ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .frame(width: 40)
                                        }
                                        .overlay(alignment: .topLeading) {
                                            if showEpisodeSearch {
                                                VStack(spacing: 0) {
                                                    ForEach(vm.seasons) { season in
                                                        Button {
                                                            searchSeason = season.seasonNumber
                                                            searchedEpisode = nil
                                                            showEpisodeSearch = false
                                                        } label: {
                                                            Text(season.name)
                                                                .font(.system(size: 12, weight: searchSeason == season.seasonNumber ? .bold : .regular))
                                                                .foregroundColor(.white)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .padding(.horizontal, 10)
                                                                .padding(.vertical, 7)
                                                        }
                                                    }
                                                }
                                                .frame(width: 120)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.98)))
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15), lineWidth: 0.5))
                                                .offset(y: -CGFloat(vm.seasons.count) * 32 - 8)
                                                .zIndex(100)
                                            }
                                        }
                                        
                                        Divider()
                                            .frame(height: 18)
                                            .background(Color.white.opacity(0.2))
                                        
                                        TextField("Tập", text: $searchText)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 30)
                                            .toolbar {
                                                ToolbarItemGroup(placement: .keyboard) {
                                                    Spacer()
                                                    Button("OK") {
                                                        if let ep = Int(searchText), ep > 0 {
                                                            searchedEpisode = ep
                                                        }
                                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                    }
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                }
                                            }
                                            .onSubmit {
                                                if let ep = Int(searchText), ep > 0 {
                                                    searchedEpisode = ep
                                                }
                                            }
                                        
                                        Button {
                                            if let ep = Int(searchText), ep > 0 {
                                                searchedEpisode = ep
                                            }
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        } label: {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12), lineWidth: 0.5))
                                    )
                                    .zIndex(100)
                                }
                                
                                if let searchedEp = searchedEpisode {
                                    VStack(spacing: 0) {
                                        Button {
                                            let detail = vm.seasonDetails[searchSeason]
                                            let episodes = detail?.episodes ?? []
                                            if episodes.first(where: { $0.episodeNumber == searchedEp }) != nil {
                                                playSeason = searchSeason
                                                playEpisode = searchedEp
                                                presentPlayer()
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Text("Tập \(searchedEp)")
                                                    .font(.system(size: 13, weight: isWatched(searchSeason, searchedEp) ? .bold : .regular))
                                                    .foregroundColor(isWatched(searchSeason, searchedEp) ? .white : .white.opacity(0.6))
                                                Spacer()
                                                Image(systemName: "play.circle")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(isWatched(searchSeason, searchedEp) ? .white.opacity(0.8) : .white.opacity(0.5))
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isWatched(searchSeason, searchedEp) ? .white.opacity(0.12) : .white.opacity(0.05))
                                            )
                                        }
                                    }
                                    .padding(.top, 4)
                                } else {
                                    ForEach(vm.seasons) { season in
                                        VStack(spacing: 0) {
                                            Button {
                                                withAnimation {
                                                    expandedSeason = expandedSeason == season.seasonNumber ? nil : season.seasonNumber
                                                    if expandedSeason == season.seasonNumber {
                                                        Task { await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season.seasonNumber) }
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    if let url = season.posterURL {
                                                        CachedAsyncImage(url: url).aspectRatio(2/3, contentMode: .fill).frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 6))
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 40, height: 60)
                                                    }
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(season.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                                        Text("\(season.episodeCount) tập").font(.system(size: 11)).foregroundColor(.gray)
                                                    }
                                                    Spacer()
                                                    Image(systemName: expandedSeason == season.seasonNumber ? "chevron.up" : "chevron.down").foregroundColor(.gray)
                                                }.padding(.vertical, 8)
                                            }
                                            if expandedSeason == season.seasonNumber {
                                                if let slug = MappingCache.getDirectSlug(tmdbID: movie.id, season: season.seasonNumber) {
                                                    if vm.sourceEpisodes.isEmpty {
                                                        ProgressView().tint(.white).padding().onAppear {
                                                            vm.loadSourceEpisodes(tmdbID: movie.id, season: season.seasonNumber, slug: slug)
                                                        }
                                                    } else {
                                                        LazyVStack(spacing: 6) {
                                                            ForEach(vm.sourceEpisodes) { ep in
                                                                Button {
                                                                    playSeason = season.seasonNumber; playEpisode = ep.episodeNumber
                                                                    presentPlayer(directURL: URL(string: ep.linkM3u8))
                                                                } label: {
                                                                    episodeRowContent(season: season.seasonNumber, episode: ep.episodeNumber, name: ep.name)
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else if let detail = vm.seasonDetails[season.seasonNumber] {
                                                    LazyVStack(spacing: 6) {
                                                        ForEach(detail.episodes) { ep in
                                                            Button {
                                                                playSeason = ep.seasonNumber; playEpisode = ep.episodeNumber
                                                                presentPlayer()
                                                            } label: {
                                                                episodeRowContent(season: ep.seasonNumber, episode: ep.episodeNumber, name: ep.name, stillURL: ep.stillURL, runtime: ep.runtime)
                                                            }
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
                        }
                        
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vm.actors.prefix(15)) { a in
                                        NavigationLink(destination: ActorDetailView(actor: a)) {
                                            VStack(spacing: 4) {
                                                CachedAsyncImage(url: a.profileURL).aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(Circle())
                                                Text(a.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 70)
                                                if let character = a.character, !character.isEmpty {
                                                    Text(character).font(.system(size: 9)).foregroundColor(.gray).lineLimit(1).frame(width: 70)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.similar.prefix(12)) { m in
                                        NavigationLink(destination: MovieDetailView(movie: m)) {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 10))
                                                Text(m.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(width: 120)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await vm.load(movieId: movie.id, mediaType: movie.mediaType)
            await vm.loadServers(movieId: movie.id, mediaType: movie.mediaType, title: movie.title)
            if movie.mediaType == "tv" {
                for season in vm.seasons {
                    await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season.seasonNumber)
                }
            }
            if MappingCache.getDirectSlug(tmdbID: movie.id, season: 1) == nil {
                vm.autoFindSlug(tmdbID: movie.id, title: movie.title, year: movie.yearText, season: 1)
            }
            await fetchRatings()
        }
        .sheet(isPresented: $showImages) {
            MovieImagesView(images: vm.images, title: movie.title)
        }
        .sheet(isPresented: $showSavePopup) {
            SaveToListPopup(movie: movie)
                .environmentObject(appState)
                .presentationDetents([.medium])
        }
    }
    } 
    @ViewBuilder
    func episodeRowContent(season: Int, episode: Int, name: String, stillURL: URL? = nil, runtime: Int? = nil) -> some View {
        HStack(spacing: 10) {
            if let still = stillURL {
                CachedAsyncImage(url: still).aspectRatio(16/9, contentMode: .fill).frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isWatched(season, episode) ? AnyShapeStyle(.white.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
                    .frame(width: 80, height: 45)
                    .overlay(Image(systemName: "play.rectangle").foregroundColor(.white.opacity(0.4)))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Tập \(episode)")
                    .font(.system(size: 11, weight: isWatched(season, episode) ? .bold : .regular))
                    .foregroundColor(isWatched(season, episode) ? .white : .white.opacity(0.6))
                Text(name).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                if let rt = runtime { Text("\(rt) phút").font(.system(size: 9)).foregroundColor(.gray) }
            }
            Spacer()
            Image(systemName: "play.circle")
                .foregroundColor(isWatched(season, episode) ? .white.opacity(0.8) : .white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    func getBestQuality() -> String? {
        if !vm.serverList.isEmpty {
            for server in vm.serverList {
                let q = server.qualities.uppercased()
                if q.contains("4K") || q.contains("2160") { return "4K" }
                if q.contains("HD") || q.contains("1080") { return "FHD" }
                if q.contains("720") { return "HD" }
            }
            if let first = vm.serverList.first {
                return first.qualities
            }
        }
        return nil
    }
    
    func handlePlayButton() {
        if !vm.seasons.isEmpty || MappingCache.hasDirectSlug(tmdbID: movie.id, season: 1) {
            playSeason = 1; playEpisode = 1
        } else { playSeason = nil; playEpisode = nil }
        presentPlayer()
    }
    
    func presentPlayer(directURL: URL? = nil) {
        guard let topVC = UIApplication.topViewController() else { return }
        let src: MovieSource = selectedSource == "Emew 1" ? .phimapi : selectedSource == "Emew 2" ? .nguonc : .vsmov
        let moviePlayer = MoviePlayerView(movieId: movie.id, movieTitle: movie.originalTitle ?? movie.title, mediaType: playerMediaType, seasonNumber: playSeason, episodeNumber: playEpisode, posterURL: movie.posterURL, initialSource: src, directURL: directURL).environmentObject(appState)
        let hosting = LandscapeHostingController(rootView: AnyView(moviePlayer))
        hosting.modalPresentationStyle = .fullScreen
        topVC.present(hosting, animated: true)
    }
    
    func fetchRatings() async {
        let imdbID: String
        if movie.mediaType == "tv" {
            imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movie.id)) ?? ""
        } else {
            let (data, _) = try! await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movie.id)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
            struct E: Codable { let imdb_id: String? }
            imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
        }
        let tmdbScore: String? = movie.voteAverage > 0 ? String(format: "%.1f/10", movie.voteAverage) : nil
        var imdbRating: String? = nil; var rtRating: String? = nil
        if !imdbID.isEmpty {
            let omdbURL = "https://www.omdbapi.com/?i=\(imdbID)&apikey=3c3cfb9e"
            if let url = URL(string: omdbURL), let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let imdbScore = json["imdbRating"] as? String, imdbScore != "N/A" { imdbRating = "\(imdbScore)/10" }
                if let ratings = json["Ratings"] as? [[String: Any]] {
                    for r in ratings {
                        if let source = r["Source"] as? String, source == "Rotten Tomatoes", let value = r["Value"] as? String { rtRating = value }
                    }
                }
            }
        }
        await MainActor.run { self.ratings = (tmdbScore, imdbRating, rtRating) }
    }
}

// MARK: - Save To List Popup
struct SaveToListPopup: View {
    let movie: Movie
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var newListName = ""
    @State private var showNewListField = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.1).ignoresSafeArea()
                VStack(spacing: 0) {
                    Text("Lưu vào...").font(.headline).foregroundColor(.white).padding(.top, 20)
                    
                    Button {
                        if !appState.favorites.contains(where: { $0.id == movie.id }) {
                            appState.favorites.append(movie)
                            appState.save()
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "bookmark.fill").foregroundColor(.white)
                            Text("Danh sách mặc định").foregroundColor(.white)
                            Spacer()
                            if appState.favorites.contains(where: { $0.id == movie.id }) {
                                Image(systemName: "checkmark").foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
                    }
                    .padding(.horizontal, 20).padding(.top, 16)
                    
                    ScrollView {
                        ForEach(appState.movieLists) { list in
                            Button {
    if !list.movies.contains(where: { $0.id == movie.id }) {
        if let idx = appState.movieLists.firstIndex(where: { $0.id == list.id }) {
            appState.movieLists[idx].movies.append(movie)
            appState.save()
        }
    }
    dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill").foregroundColor(.gray)
                                    Text(list.name).foregroundColor(.white)
                                    Spacer()
                                    Text("\(list.movies.count)").font(.caption).foregroundColor(.gray)
                                    if list.movies.contains(where: { $0.id == movie.id }) {
    Image(systemName: "checkmark").foregroundColor(.green)
}
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
                            }
                            .padding(.horizontal, 20).padding(.top, 8)
                        }
                    }
                    .padding(.top, 8)
                    
                    if showNewListField {
                        HStack {
                            TextField("Tên list mới", text: $newListName)
                                .textFieldStyle(.plain).foregroundColor(.white)
                                .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1)))
                            Button("Tạo") {
    if !newListName.trimmingCharacters(in: .whitespaces).isEmpty {
        var newList = MovieList(name: newListName)
        newList.movies = [movie]
        appState.movieLists.append(newList)
        appState.save()
        newListName = ""
        showNewListField = false
        dismiss()
    }
}
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(.horizontal, 20).padding(.top, 8)
                    }
                    
                    Button {
                        withAnimation { showNewListField.toggle() }
                    } label: {
                        Label("Tạo list mới", systemImage: "plus")
                            .foregroundColor(.white.opacity(0.7)).font(.system(size: 13))
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Info Badge
struct InfoBadge: View {
    let label: String
    let quality: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text(quality).font(.system(size: 7)).foregroundColor(.gray)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
}

// MARK: - Movie Images View
struct MovieImagesView: View {
    let images: [URL]
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(title).font(.headline).foregroundColor(.white)
                    Spacer()
                    Button("Đóng") { dismiss() }.foregroundColor(.gray)
                }.padding()
                TabView {
                    ForEach(images, id: \.self) { url in
                        CachedAsyncImage(url: url).aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

// MARK: - Web View
struct WebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.backgroundColor = .black
        wv.isOpaque = false
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
// MARK: - New Theme Detail View
struct NewThemeDetailView: View {
    let movie: Movie
    @ObservedObject var vm: MovieDetailViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showFullOverview = false
    @State private var selectedSeason: Int? = nil
    @State private var showEpisodePopup = false
    @State private var selectedEpisode: Int? = nil
    @State private var showSavePopup = false
    
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    
    var body: some View {
        ZStack {
            // Background poster dọc full màn hình (mờ)
GeometryReader { geo in
    CachedAsyncImage(url: movie.posterURL, size: .detail)
        .aspectRatio(contentMode: .fill)
        .frame(width: geo.size.width, height: geo.size.height)
        .clipped()
        .overlay(Color.black.opacity(0.3))
        .ignoresSafeArea()
}
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // Khung vuông blur mờ bo cong nửa dưới
                    VStack(alignment: .leading, spacing: 12) {
                        // Tên phim
                        Text(movie.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Thể loại
                        if let genres = vm.detail?.genres, !genres.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(genres.prefix(3), id: \.id) { genre in
                                    Text(genre.name.replacingOccurrences(of: "Phim ", with: ""))
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(.white.opacity(0.1)))
                                }
                            }
                        }
                        
                        // Điểm TMDB + ngày + thời lượng
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", movie.voteAverage))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("•").foregroundColor(.gray)
                            Text(releaseDateText)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Text("•").foregroundColor(.gray)
                            if let runtime = vm.detail?.runtime, runtime > 0 {
                                Text("\(runtime) phút")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Nội dung phim
                        Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(showFullOverview ? nil : 3)
                            .multilineTextAlignment(.leading)
                        
                        if movie.overview.count > 120 {
                            Button(showFullOverview ? "Ẩn bớt" : "More") {
                                withAnimation { showFullOverview.toggle() }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Nút Xem ngay + Lưu
                        HStack(spacing: 10) {
                            // Xem ngay - khung trắng
                            Button {
                                presentPlayer()
                            } label: {
                                Text("Xem ngay")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(.white))
                            }
                            
                            // Lưu - khung viền trắng
                            Button {
                                if appState.favorites.contains(where: { $0.id == movie.id }) {
                                    appState.favorites.removeAll { $0.id == movie.id }
                                    appState.save()
                                } else {
                                    showSavePopup = true
                                }
                            } label: {
                                Text(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.85))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    )
                    .padding(.horizontal, 16)
                
                    
                    // Phần dưới - background đen
                    VStack(alignment: .leading, spacing: 20) {
                        // Seasons hoặc Related Movies
                        if !vm.seasons.isEmpty {
                            Text("Seasons")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.seasons) { season in
                                        Button {
                                            selectedSeason = season.seasonNumber
                                            showEpisodePopup = true
                                        } label: {
                                            VStack(spacing: 6) {
                                                if let url = season.posterURL {
                                                    CachedAsyncImage(url: url)
                                                        .aspectRatio(2/3, contentMode: .fill)
                                                        .frame(width: 100, height: 150)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(.ultraThinMaterial)
                                                        .frame(width: 100, height: 150)
                                                }
                                                Text(season.name)
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Text("\(season.episodeCount) tập")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            }
                        } else if !vm.similar.isEmpty {
                            Text("Related Movies")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.similar.prefix(10)) { m in
                                        NavigationLink(destination: MovieDetailView(movie: m)) {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: m.posterURL)
                                                    .aspectRatio(2/3, contentMode: .fill)
                                                    .frame(width: 100, height: 150)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                Text(m.title)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .frame(width: 100)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Top Cast
                        if !vm.actors.isEmpty {
                            Text("Top Cast")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vm.actors.prefix(15)) { actor in
                                        NavigationLink(destination: ActorDetailView(actor: actor)) {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: actor.profileURL)
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 70, height: 70)
                                                    .clipShape(Circle())
                                                if let character = actor.character, !character.isEmpty {
                                                    Text(character)
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                        .frame(width: 80)
                                                }
                                                Text(actor.name)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                                    .frame(width: 80)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .background(Color.black.ignoresSafeArea())
                    .padding(.bottom, 50)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Nút back - đặt ở top left
VStack {
    HStack {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(14)
                .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
        }
        Spacer()
    }
    Spacer()
}
.padding(.horizontal, 20)
.padding(.top, 54)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEpisodePopup) {
            EpisodePopupView(vm: vm, movie: movie, season: selectedSeason ?? 1)
                .environmentObject(appState)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSavePopup) {
            SaveToListPopup(movie: movie)
                .environmentObject(appState)
                .presentationDetents([.medium])
        }
    }
    
    func presentPlayer() {
        guard let topVC = UIApplication.topViewController() else { return }
        let moviePlayer = MoviePlayerView(
            movieId: movie.id,
            movieTitle: movie.title,
            mediaType: movie.mediaType,
            seasonNumber: nil,
            episodeNumber: nil,
            posterURL: movie.posterURL,
            initialSource: .phimapi
        ).environmentObject(appState)
        let hosting = LandscapeHostingController(rootView: AnyView(moviePlayer))
        hosting.modalPresentationStyle = .fullScreen
        topVC.present(hosting, animated: true)
    }
}

// MARK: - Episode Popup View
struct EpisodePopupView: View {
    @ObservedObject var vm: MovieDetailViewModel
    let movie: Movie
    let season: Int
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Tập phim - Season \(season)")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Button("Đóng") { dismiss() }.foregroundColor(.gray)
                }
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if let detail = vm.seasonDetails[season] {
                            ForEach(detail.episodes) { ep in
                                Button {
                                    presentPlayer(episode: ep.episodeNumber)
                                } label: {
                                    HStack(spacing: 10) {
                                        Text("Tập \(ep.episodeNumber)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if let runtime = ep.runtime {
                                            Text("\(runtime) phút")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                        Image(systemName: "play.circle")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                                }
                            }
                        } else {
                            ProgressView().tint(.white).padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season)
        }
    }
    
    func presentPlayer(episode: Int) {
        guard let topVC = UIApplication.topViewController() else { return }
        let moviePlayer = MoviePlayerView(
            movieId: movie.id,
            movieTitle: movie.title,
            mediaType: "tv",
            seasonNumber: season,
            episodeNumber: episode,
            posterURL: movie.posterURL,
            initialSource: .phimapi
        ).environmentObject(appState)
        let hosting = LandscapeHostingController(rootView: AnyView(moviePlayer))
        hosting.modalPresentationStyle = .fullScreen
        topVC.present(hosting, animated: true)
        dismiss()
    }
}