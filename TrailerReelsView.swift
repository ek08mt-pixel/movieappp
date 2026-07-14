import SwiftUI
import AVKit
import AVFoundation
import WebKit

// MARK: - TrailerVideo Model
struct TrailerVideo: Identifiable {
    let id: String; let key: String; let name: String
    let site: String; let type: String; let movieTitle: String
    let movieId: Int; let posterPath: String?; let backdropPath: String?
    let voteAverage: Double; let releaseDate: String?; let overview: String
}

// MARK: - Internal Models
private struct TMDBMovie: Codable {
    let id: Int; let title: String; let poster_path: String?
    let backdrop_path: String?; let vote_average: Double
    let release_date: String?; let overview: String
}
private struct TMDBTrendingResp: Codable { let results: [TMDBMovie] }
private struct TMDBVideoResp: Codable {
    struct V: Codable { let id: String; let key: String; let name: String; let site: String; let type: String }
    let results: [V]
}

// MARK: - TrailerService
class TrailerService {
    static let shared = TrailerService()
    private let key = "b6be36c1c5788565fec6a24811e7cc9b"
    
    func fetchTrendingTrailers() async -> [TrailerVideo] {
        guard let url = URL(string: "https://api.themoviedb.org/3/trending/movie/week?api_key=\(key)") else { return [] }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            let r = try JSONDecoder().decode(TMDBTrendingResp.self, from: d)
            var trailers: [TrailerVideo] = []
            for m in r.results.prefix(15) {
                if let t = await fetchTrailer(for: m) { trailers.append(t) }
            }
            return trailers
        } catch { return [] }
    }
    
    private func fetchTrailer(for m: TMDBMovie) async -> TrailerVideo? {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(m.id)/videos?api_key=\(key)") else { return nil }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            let v = try JSONDecoder().decode(TMDBVideoResp.self, from: d)
            guard let t = v.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" }) else { return nil }
            return TrailerVideo(id: t.id, key: t.key, name: t.name, site: t.site, type: t.type,
                                movieTitle: m.title, movieId: m.id, posterPath: m.poster_path,
                                backdropPath: m.backdrop_path, voteAverage: m.vote_average,
                                releaseDate: m.release_date, overview: m.overview)
        } catch { return nil }
    }
}

// MARK: - TrailerReelsView
struct TrailerReelsView: View {
    @State private var trailers: [TrailerVideo] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(.white).scaleEffect(1.5)
            } else if trailers.isEmpty {
                VStack { Image(systemName: "film.slash").font(.system(size: 50)).foregroundColor(.gray); Text("Không có trailer").foregroundColor(.gray) }
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(trailers.enumerated()), id: \.element.id) { i, t in
                        TrailerCardView(trailer: t).tag(i)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
            }
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    Spacer()
                    Text("🎬 Trailers").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Spacer(); Circle().fill(.clear).frame(width: 36, height: 36)
                }.padding(.horizontal, 20).padding(.top, 50)
                Spacer()
            }
        }
        .task { trailers = await TrailerService.shared.fetchTrendingTrailers(); isLoading = false }
    }
}

// MARK: - TrailerCardView
struct TrailerCardView: View {
    let trailer: TrailerVideo
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            YouTubeEmbedView(videoID: trailer.key).ignoresSafeArea().allowsHitTesting(false)
            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom).frame(height: 300)
            }
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trailer.movieTitle).font(.system(size: 20, weight: .bold)).foregroundColor(.white).lineLimit(2)
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow)
                                Text(String(format: "%.1f", trailer.voteAverage)).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            }
                            Text("Trailer").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9)).padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.red.opacity(0.7)))
                        }
                    }
                    Spacer()
                    VStack(spacing: 20) {
                        Button {
                            showDetail = true
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "play.rectangle.fill").font(.system(size: 28)).foregroundColor(.white)
                                Text("Xem").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                }.padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                MovieDetailView(movie: Movie(id: trailer.movieId, title: trailer.movieTitle, overview: trailer.overview, posterPath: trailer.posterPath, backdropPath: trailer.backdropPath, voteAverage: trailer.voteAverage, releaseDate: trailer.releaseDate, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: "movie"))
            }
        }
    }
}

// MARK: - YouTubeEmbedView
struct YouTubeEmbedView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        let html = """
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>body{margin:0;background:black;overflow:hidden}iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:0}</style></head>
        <body><iframe src="https://www.youtube.com/embed/\(videoID)?autoplay=1&playsinline=1&controls=0&showinfo=0&rel=0&modestbranding=1&loop=1&playlist=\(videoID)" allow="autoplay;encrypted-media;picture-in-picture" allowfullscreen></iframe></body></html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}