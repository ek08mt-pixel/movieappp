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
    @State private var showDownloadSheet = false
    @State private var downloadSeason: Int? = nil
    @State private var downloadEpisode: Int? = nil
    
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
                        
                        HStack(spacing: 10) {
                            Button {
                                playSeason = nil
                                playEpisode = nil
                                showPlayer = true
                            } label: {
                                Label("Xem", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                if appState.favorites.contains(where: { $0.id == movie.id }) {
                                    appState.favorites.removeAll { $0.id == movie.id }
                                } else {
                                    appState.favorites.append(movie)
                                }
                                appState.save()
                            } label: {
                                Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu",
                                      systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus")
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                showDownloadSheet = true
                            } label: {
                                Label("Tải", systemImage: "arrow.down.circle")
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
                                    HStack(spacing: 12) {
                                        ForEach(vm.collectionMovies.filter { $0.id != movie.id }) { part in
                                            NavigationLink(destination: MovieDetailView(movie: part)) {
                                                VStack(spacing: 6) {
                                                    CachedAsyncImage(url: part.posterURL, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10))
                                                    Text(part.title).font(.system(size: 10)).foregroundColor(.white).lineLimit(2).frame(width: 100)
                                                    Text(part.yearText).font(.system(size: 9)).foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Seasons & Episodes").font(.title3).fontWeight(.bold).foregroundColor(.white)
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
                                                    CachedAsyncImage(url: url, size: .detail).aspectRatio(2/3, contentMode: .fill).frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 6))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 40, height: 60).overlay(Image(systemName: "tv").foregroundColor(.white.opacity(0.5)))
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(season.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                                    Text("\(season.episodeCount) tập").font(.system(size: 11)).foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Image(systemName: expandedSeason == season.seasonNumber ? "chevron.up" : "chevron.down").foregroundColor(.gray).font(.caption)
                                            }.padding(.vertical, 8)
                                        }
                                        if expandedSeason == season.seasonNumber {
                                            Divider().background(Color.white.opacity(0.15))
                                            if let detail = vm.selectedSeason, detail.seasonNumber == season.seasonNumber {
                                                LazyVStack(spacing: 6) {
                                                    ForEach(detail.episodes) { ep in
                                                        Button {
                                                            playSeason = ep.seasonNumber
                                                            playEpisode = ep.episodeNumber
                                                            showPlayer = true
                                                        } label: {
                                                            HStack(spacing: 10) {
                                                                if let still = ep.stillURL {
                                                                    CachedAsyncImage(url: still, size: .detail).aspectRatio(16/9, contentMode: .fill).frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 6))
                                                                } else {
                                                                    RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 80, height: 45).overlay(Image(systemName: "play.rectangle").foregroundColor(.white.opacity(0.4)))
                                                                }
                                                                VStack(alignment: .leading, spacing: 2) {
                                                                    Text("Tập \(ep.episodeNumber)").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                                                    Text(ep.name).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                                                                    if let rt = ep.runtime { Text("\(rt) phút").font(.system(size: 9)).foregroundColor(.gray) }
                                                                }
                                                                Spacer()
                                                                Image(systemName: "play.circle").foregroundColor(.white.opacity(0.6)).font(.system(size: 18))
                                                            }.padding(.vertical, 6)
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
        .task { await vm.load(movieId: movie.id, mediaType: movie.mediaType) }
        .fullScreenCover(isPresented: $showPlayer) {
            MoviePlayerView(
                movieId: movie.id,
                movieTitle: movie.originalTitle ?? movie.title,
                mediaType: playerMediaType,
                seasonNumber: playSeason,
                episodeNumber: playEpisode,
                posterURL: movie.posterURL
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showImages) { MovieImagesView(images: vm.images, title: movie.title) }
        .sheet(isPresented: $showBookingSheet) {
            NavigationStack {
                WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))")
                    .ignoresSafeArea()
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } }
            }
        }
        .sheet(isPresented: $showDownloadSheet) {
            downloadPickerView
        }
    }
    
    var downloadPickerView: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Chọn tập để tải").font(.title3.bold()).foregroundColor(.white).padding(.top, 20)
                        
                        if vm.seasons.isEmpty {
                            VStack(spacing: 12) {
                                if let posterURL = movie.posterURL {
                                    CachedAsyncImage(url: posterURL, size: .detail)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(width: 120, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Text(movie.title).font(.headline).foregroundColor(.white)
                                Button {
                                    downloadEpisode = nil; downloadSeason = nil
                                    showDownloadSheet = false
                                    triggerDownload()
                                } label: {
                                    Text("Tải phim này").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(Capsule().fill(.blue))
                                }
                            }.padding(20).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.3)))
                        } else {
                            ForEach(vm.seasons) { season in
                                VStack(spacing: 8) {
                                    Text(season.name).font(.headline).foregroundColor(.white)
                                    if let detail = vm.seasonDetails[season.seasonNumber] {
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                            ForEach(detail.episodes) { ep in
                                                Button {
                                                    downloadSeason = ep.seasonNumber
                                                    downloadEpisode = ep.episodeNumber
                                                    showDownloadSheet = false
                                                    triggerDownload()
                                                } label: {
                                                    Text("\(ep.episodeNumber)").font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.white).frame(height: 36).frame(maxWidth: .infinity)
                                                        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.4)))
                                                }
                                            }
                                        }
                                    } else {
                                        ProgressView().tint(.white).onAppear {
                                            Task { await vm.loadSeasonDetail(tvId: movie.id, seasonNumber: season.seasonNumber) }
                                        }
                                    }
                                }
                                .padding(16).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.2)))
                            }
                        }
                    }.padding(20)
                }
            }
        }
    }
    
    func triggerDownload() {
        Task {
            let imdbID: String
            if let mt = movie.mediaType, mt == "tv" {
                imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movie.id)) ?? ""
            } else {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movie.id)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
                struct E: Codable { let imdb_id: String? }
                imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
            }
            
            guard !imdbID.isEmpty else { return }
            
            let url = try? await withCheckedThrowingContinuation { c in
                PhimAPIService.shared.fetchStream(
                    imdbID: imdbID, tmdbID: movie.id, title: movie.title,
                    mediaType: movie.mediaType,
                    season: downloadSeason, episode: downloadEpisode
                ) { c.resume(with: $0) }
            }
            
            guard let streamURL = url else { return }
            
            DownloadManager.shared.download(
                url: streamURL,
                movieId: movie.id,
                title: movie.title,
                posterPath: movie.posterPath,
                mediaType: movie.mediaType,
                season: downloadSeason,
                episode: downloadEpisode
            )
        }
    }
}

struct MovieImagesView: View {
    let images: [URL]; let title: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack { Text(title).font(.headline).foregroundColor(.white); Spacer(); Button("Đóng") { dismiss() }.foregroundColor(.gray) }.padding()
                TabView {
                    ForEach(images, id: \.self) { url in
                        CachedAsyncImage(url: url, size: .backdrop).aspectRatio(contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}