import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie; var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @StateObject private var music = MusicManager.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showPlayer = false; @State private var showBookingSheet = false
    @State private var showFullOverview = false; @State private var showImages = false
    @State private var commentText = ""; @State private var comments: [String] = []
    @State private var selectedSeason: SeasonInfo?
    
    var isTVShow: Bool { movie.mediaType == "tv" }
    var releaseDateText: String { if let date = movie.releaseDate, !date.isEmpty { return date }; return movie.yearText }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL).aspectRatio(16/9, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 320).clipped()
                            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left.circle.fill").font(.system(size: 30)).foregroundColor(.white).shadow(color: .black.opacity(0.5), radius: 4)
                            }
                            Spacer()
                            Button { music.toggle() } label: {
                                Image(systemName: music.isMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.system(size: 14)).foregroundColor(.white)
                                    .padding(8).background(Circle().fill(.ultraThinMaterial))
                            }
                        }.padding(.top, 54).padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.4), radius: 6).offset(y: -45)
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                    Text(movie.ratingText).foregroundColor(.white).font(.caption).bold()
                                    Text("•").foregroundColor(.gray)
                                    Text(releaseDateText).foregroundColor(.gray).font(.caption)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview).font(.system(size: 13)).foregroundColor(.gray).lineLimit(showFullOverview ? nil : 4).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                                    if movie.overview.count > 200 { Button(showFullOverview ? "Thu gọn" : "Xem thêm") { withAnimation { showFullOverview.toggle() } }.font(.system(size: 12, weight: .medium)).foregroundColor(.orange) }
                                }
                            }
                        }
                        
                        HStack(spacing: 10) {
                            Button { showPlayer = true } label: { Label("Xem", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            NavigationLink(destination: AskAIView(movie: movie).toolbar(.hidden, for: .tabBar)) { Label("Hỏi AI", systemImage: "brain").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                            Button { if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } } else { appState.favorites.append(movie) } } label: { Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu", systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }
                        }
                        
                        if showBooking { Button { showBookingSheet = true } label: { Label("Đặt vé", systemImage: "ticket.fill").frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5)).clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) } }
                        
                        if isTVShow && !vm.seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Seasons").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.seasons) { season in
                                            Button { withAnimation(.spring()) { selectedSeason = season } } label: {
                                                VStack(spacing: 6) { Text(season.name).font(.system(size: 13, weight: selectedSeason?.id == season.id ? .bold : .medium)).foregroundColor(selectedSeason?.id == season.id ? .white : .gray); Text("\(season.episodeCount) tập").font(.system(size: 10)).foregroundColor(selectedSeason?.id == season.id ? .white.opacity(0.7) : .gray.opacity(0.5)) }.padding(.vertical, 10).padding(.horizontal, 16).background(RoundedRectangle(cornerRadius: 14).fill(selectedSeason?.id == season.id ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.white.opacity(0.04))).overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedSeason?.id == season.id ? Color.white.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 0.5)))
                                            }
                                        }
                                    }
                                }
                                if let s = selectedSeason {
                                    VStack(spacing: 6) { ForEach(1...s.episodeCount, id: \.self) { ep in Button { showPlayer = true } label: { HStack(spacing: 12) { ZStack { RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial).frame(width: 48, height: 32); Image(systemName: "play.fill").font(.system(size: 10)).foregroundColor(.white.opacity(0.6)) }; Text("Tập \(ep)").font(.system(size: 13, weight: .medium)).foregroundColor(.white); Spacer(); Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.gray) }.padding(.vertical, 4) }; if ep < s.episodeCount { Divider().background(Color.white.opacity(0.05)) } } }.padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                            }
                        }
                        
                        if !isTVShow, let runtime = vm.detail?.runtime, runtime > 0 {
                            HStack(spacing: 12) { Label("\(runtime) phút", systemImage: "clock.fill").font(.system(size: 11)).foregroundColor(.gray); if let g = vm.detail?.genres, !g.isEmpty { Text(g.prefix(3).map{$0.name}.joined(separator: " • ")).font(.system(size: 11)).foregroundColor(.gray) } }
                        }
                        
                        if !vm.images.isEmpty {
                            VStack(alignment: .leading, spacing: 10) { HStack { Text("Hình ảnh").font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Spacer(); Button("Xem tất cả") { showImages = true }.font(.system(size: 12)).foregroundColor(.orange) }; ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(vm.images.prefix(8), id: \.self) { url in CachedAsyncImage(url: url).aspectRatio(16/9, contentMode: .fill).frame(width: 180, height: 100).clipShape(RoundedRectangle(cornerRadius: 10)) } } } }
                        }
                        
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(vm.actors.prefix(15)) { actor in NavigationLink(destination: ActorDetailView(actor: actor)) { VStack(spacing: 6) { CachedAsyncImage(url: actor.profileURL).aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(Circle()); Text(actor.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60) } } } }.padding(.horizontal) }
                        }
                        
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) { LazyHStack(spacing: 12) { ForEach(vm.similar.prefix(12)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { VStack(spacing: 6) { CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.3), radius: 4); Text(m.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(width: 120) } } } }.padding(.horizontal) }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bình luận").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            HStack(spacing: 8) { TextField("Viết bình luận...", text: $commentText).textFieldStyle(.plain).foregroundColor(.white).padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)); Button { if !commentText.isEmpty { comments.append(commentText); commentText = "" } } label: { Text("Gửi").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.7)) } }
                            ForEach(comments, id: \.self) { c in HStack(alignment: .top, spacing: 8) { Circle().fill(.ultraThinMaterial).frame(width: 30, height: 30).overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.6)).font(.system(size: 14))); VStack(alignment: .leading, spacing: 2) { Text("Người dùng").font(.caption).fontWeight(.bold).foregroundColor(.white); Text(c).font(.caption).foregroundColor(.gray) }; Spacer() } }
                        }.padding(.top, 8)
                    }.padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }.ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true).toolbar(.hidden, for: .tabBar)
        .onAppear { music.play() }
        .onDisappear { music.stop() }
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