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
    
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 320).clipped()
                            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 30)).foregroundColor(.white).shadow(color: .black.opacity(0.5), radius: 4)
                        }.padding(.top, 54).padding(.leading, 20)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.4), radius: 6).offset(y: -45)
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                HStack(spacing: 6) { Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption); Text(movie.ratingText).foregroundColor(.white).font(.caption).bold(); Text("•").foregroundColor(.gray); Text(releaseDateText).foregroundColor(.gray).font(.caption) }
                                Button { showFullOverview.toggle() } label: { Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview).font(.system(size: 13)).foregroundColor(.gray).lineLimit(showFullOverview ? nil : 4).multilineTextAlignment(.leading) }
                            }
                        }
                        HStack(spacing: 10) {
                            Button { showPlayer = true } label: { Label("Xem", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            Button { if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } } else { appState.favorites.append(movie) } } label: { Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu", systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                        }
                        if showBooking { Button { showBookingSheet = true } label: { Label("Đặt vé", systemImage: "ticket.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) } }
                        if let r = vm.detail?.runtime, r > 0 { HStack(spacing: 12) { Label("\(r) phút", systemImage: "clock.fill").font(.system(size: 11)).foregroundColor(.gray); if let g = vm.detail?.genres, !g.isEmpty { Text(g.prefix(3).map{$0.name}.joined(separator: " • ")).font(.system(size: 11)).foregroundColor(.gray) } } }
                        
                        // MARK: - Seasons & Episodes
                        if !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mùa & Tập").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
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
                                                    RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 40, height: 60).overlay(Image(systemName: "tv").foregroundColor(.white.opacity(0.5)))
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(season.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                                    Text("\(season.episodeCount) tập").font(.system(size: 11)).foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Image(systemName: expandedSeason == season.seasonNumber ? "chevron.up" : "chevron.down").foregroundColor(.gray).font(.caption)
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        
                                        if expandedSeason == season.seasonNumber {
                                            Divider().background(Color.white.opacity(0.15))
                                            if let detail = vm.selectedSeason, detail.seasonNumber == season.seasonNumber {
                                                LazyVStack(spacing: 6) {
                                                    ForEach(detail.episodes) { ep in
                                                        Button {
                                                            playSeason = season.seasonNumber
                                                            playEpisode = ep.episodeNumber
                                                            showPlayer = true
                                                        } label: {
                                                            HStack(spacing: 10) {
                                                                if let still = ep.stillURL {
                                                                    CachedAsyncImage(url: still).aspectRatio(16/9, contentMode: .fill).frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 6))
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
                                                            }
                                                            .padding(.vertical, 6)
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
                        
                        if !vm.images.isEmpty { VStack(alignment: .leading, spacing: 10) { HStack { Text("Hình ảnh").font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Spacer(); Button("Xem tất cả") { showImages = true }.font(.system(size: 12)).foregroundColor(.orange) }; ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(vm.images.prefix(8), id: \.self) { u in CachedAsyncImage(url: u).aspectRatio(16/9, contentMode: .fill).frame(width: 180, height: 100).clipShape(RoundedRectangle(cornerRadius: 10)) } } } } }
                        if !vm.actors.isEmpty { Text("Diễn viên").font(.system(size: 15, weight: .semibold)).foregroundColor(.white); ScrollView(.horizontal) { HStack(spacing: 16) { ForEach(vm.actors.prefix(15)) { a in NavigationLink(destination: ActorDetailView(actor: a)) { VStack(spacing: 6) { CachedAsyncImage(url: a.profileURL).aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(Circle()); Text(a.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60) } } } } } }
                        if !vm.similar.isEmpty { Text("Phim tương tự").font(.system(size: 15, weight: .semibold)).foregroundColor(.white); ScrollView(.horizontal) { LazyHStack(spacing: 12) { ForEach(vm.similar.prefix(12)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { VStack(spacing: 6) { CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.3), radius: 4); Text(m.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(width: 120) } } } } } }
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
                movieTitle: movie.title,
                mediaType: movie.mediaType,
                seasonNumber: playSeason,
                episodeNumber: playEpisode
            )
        }
        .sheet(isPresented: $showImages) { MovieImagesView(images: vm.images, title: movie.title) }
        .sheet(isPresented: $showBookingSheet) { NavigationStack { WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))").ignoresSafeArea().toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } } } }
    }
}

struct MovieImagesView: View { let images: [URL]; let title: String; @Environment(\.dismiss) var dismiss; var body: some View { ZStack { Color.black.opacity(0.95).ignoresSafeArea(); VStack(spacing: 0) { HStack { Text(title).font(.headline).foregroundColor(.white); Spacer(); Button("Đóng") { dismiss() }.foregroundColor(.gray) }.padding(); TabView { ForEach(images, id: \.self) { url in CachedAsyncImage(url: url).aspectRatio(contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16) } }.tabViewStyle(.page(indexDisplayMode: .always)) } } } }

struct WebView: UIViewRepresentable { let urlString: String; func makeUIView(context: Context) -> WKWebView { let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false; if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }; return wv }; func updateUIView(_ uiView: WKWebView, context: Context) {} }