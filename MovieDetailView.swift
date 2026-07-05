import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie; var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @StateObject private var ost = OSTManager.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showPlayer = false; @State private var showBookingSheet = false
    @State private var showFullOverview = false; @State private var showImages = false
    @State private var commentText = ""; @State private var comments: [String] = []
    var isTVShow: Bool { movie.mediaType == "tv" }
    var releaseDateText: String { movie.releaseDate ?? movie.yearText }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL).aspectRatio(16/9, contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: 320).clipped().overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        HStack {
                            Button { dismiss() } label: { Image(systemName: "chevron.left.circle.fill").font(.system(size: 30)).foregroundColor(.white) }
                            Spacer()
                            Button { ost.toggle() } label: { Image(systemName: ost.isMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill").font(.system(size: 14)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial)) }
                        }.padding(.top, 54).padding(.horizontal, 20)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10)).offset(y: -45)
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                HStack(spacing: 6) { Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption); Text(movie.ratingText).foregroundColor(.white).font(.caption).bold(); Text("•").foregroundColor(.gray); Text(releaseDateText).foregroundColor(.gray).font(.caption) }
                                VStack(alignment: .leading, spacing: 4) { Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview).font(.system(size: 13)).foregroundColor(.gray).lineLimit(showFullOverview ? nil : 4).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true); if movie.overview.count > 200 { Button(showFullOverview ? "Thu gọn" : "Xem thêm") { withAnimation { showFullOverview.toggle() } }.font(.system(size: 12, weight: .medium)).foregroundColor(.orange) } }
                            }
                        }
                        HStack(spacing: 10) {
                            Button { showPlayer = true } label: { Label("Xem", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            NavigationLink(destination: AskAIView(movie: movie).toolbar(.hidden, for: .tabBar)) { Label("Hỏi AI", systemImage: "brain").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            Button { if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } } else { appState.favorites.append(movie) } } label: { Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu", systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                        }
                        if isTVShow && !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Seasons").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 10) { ForEach(vm.seasons) { s in Button { } label: { VStack(spacing: 6) { Text(s.name).font(.system(size: 13)).foregroundColor(.white); Text("\(s.episodeCount) tập").font(.system(size: 10)).foregroundColor(.gray) }.padding(.vertical, 10).padding(.horizontal, 16).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)) } } } }
                            }
                        }
                    }.padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }.ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true).toolbar(.hidden, for: .tabBar)
        .onAppear { Task { await ost.playOST(for: movie.title) } }
        .onDisappear { ost.stop() }
        .task { await vm.load(movieId: movie.id, mediaType: movie.mediaType) }
        .fullScreenCover(isPresented: $showPlayer) { MoviePlayerView(movieId: movie.id, movieTitle: movie.title) }
        .sheet(isPresented: $showImages) { MovieImagesView(images: vm.images, title: movie.title) }
        .sheet(isPresented: $showBookingSheet) { NavigationStack { WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))").ignoresSafeArea().toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } } } }
    }
}
struct MovieImagesView: View {
    let images: [URL]; let title: String; @Environment(\.dismiss) var dismiss
    var body: some View { ZStack { Color.black.opacity(0.95).ignoresSafeArea(); VStack(spacing: 0) { HStack { Text(title).font(.headline).foregroundColor(.white); Spacer(); Button("Đóng") { dismiss() }.foregroundColor(.gray) }.padding(); TabView { ForEach(images, id: \.self) { url in CachedAsyncImage(url: url).aspectRatio(contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16) } }.tabViewStyle(.page(indexDisplayMode: .always)) } } }
}
struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false; if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }; return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
