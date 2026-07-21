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
    
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    
    var playerMediaType: String? {
        if let mt = movie.mediaType { return mt }
        if playSeason != nil || playEpisode != nil { return "tv" }
        return nil
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geo in CachedAsyncImage(url: movie.backdropURL, size: .backdrop).aspectRatio(contentMode: .fill).frame(width: geo.size.width, height: geo.size.height + 100).blur(radius: 60).overlay(Color.black.opacity(0.55)).ignoresSafeArea() }
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL, size: .backdrop).aspectRatio(16/9, contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: 320).clipped().overlay(LinearGradient(colors: [.clear, .clear, Color.black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 20)
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
                        HStack(spacing: 8) {
                            InfoBadge(label: "Vietsub", quality: "UHD")
                            InfoBadge(label: "Lồng tiếng", quality: "FHD")
                            InfoBadge(label: "Thuyết minh", quality: "4K")
                        }
                        HStack(spacing: 10) {
                            Button { playSeason = nil; playEpisode = nil; presentPlayer() } label: { Label("Xem", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            Button { if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } } else { appState.favorites.append(movie) }; appState.save() } label: { Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu", systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            Button { if appState.watchedMovies.contains(where: { $0.id == movie.id }) { appState.watchedMovies.removeAll { $0.id == movie.id } } else { appState.watchedMovies.append(movie) }; appState.save() } label: { Label(appState.watchedMovies.contains(where: { $0.id == movie.id }) ? "Đã xem" : "Đánh dấu đã xem", systemImage: appState.watchedMovies.contains(where: { $0.id == movie.id }) ? "checkmark.circle.fill" : "checkmark.circle").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                        }
                    }.padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }.ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true).toolbar(.hidden, for: .tabBar)
        .task { await vm.load(movieId: movie.id, mediaType: movie.mediaType); await fetchRatings() }
        .sheet(isPresented: $showImages) { MovieImagesView(images: vm.images, title: movie.title) }
    }
    
    func presentPlayer() {
        guard let topVC = UIApplication.topViewController() else { return }
        let moviePlayer = MoviePlayerView(movieId: movie.id, movieTitle: movie.originalTitle ?? movie.title, mediaType: playerMediaType, seasonNumber: playSeason, episodeNumber: playEpisode, posterURL: movie.posterURL).environmentObject(appState)
        let hosting = LandscapeHostingController(rootView: AnyView(moviePlayer))
        hosting.modalPresentationStyle = .fullScreen
        topVC.present(hosting, animated: true)
    }
    
    var ratingsBar: some View { EmptyView() }
    
    func fetchRatings() async {}
}

struct InfoBadge: View {
    let label: String; let quality: String
    var body: some View { VStack(spacing: 2) { Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.7)); Text(quality).font(.system(size: 8)).foregroundColor(.gray) }.padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.05))).overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.1), lineWidth: 0.5)) }
}
struct MovieImagesView: View {
    let images: [URL]; let title: String
    @Environment(\.dismiss) var dismiss
    var body: some View { ZStack { Color.black.opacity(0.95).ignoresSafeArea(); VStack(spacing: 0) { HStack { Text(title).font(.headline).foregroundColor(.white); Spacer(); Button("Đóng") { dismiss() }.foregroundColor(.gray) }.padding(); TabView { ForEach(images, id: \.self) { url in CachedAsyncImage(url: url).aspectRatio(contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16) } }.tabViewStyle(.page(indexDisplayMode: .always)) } } }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false; if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }; return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}