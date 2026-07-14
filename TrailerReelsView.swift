import SwiftUI
import AVKit

struct TrailerVideo: Identifiable {
    let id: String
    let name: String
    let movieTitle: String
    let movieId: Int
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let overview: String
    let streamURL: URL
}

@MainActor
class TrailerService {
    static let shared = TrailerService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    func fetchTrendingTrailers() async -> [TrailerVideo] {
        guard let url = URL(string: "https://api.themoviedb.org/3/trending/movie/week?api_key=\(apiKey)") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Resp: Codable {
                struct M: Codable { let id: Int; let title: String; let poster_path: String?; let backdrop_path: String?; let vote_average: Double; let release_date: String?; let overview: String }
                let results: [M]
            }
            let resp = try JSONDecoder().decode(Resp.self, from: data)
            
            var trailers: [TrailerVideo] = []
            for m in resp.results.prefix(15) {
                if let video = await fetchTrailer(movieId: m.id, movie: m) {
                    trailers.append(video)
                }
            }
            return trailers
        } catch { return [] }
    }
    
    private func fetchTrailer(movieId: Int, movie: Any) async -> TrailerVideo? {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/videos?api_key=\(apiKey)") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct VResp: Codable {
                struct V: Codable { let id: String; let key: String; let name: String; let site: String; let type: String }
                let results: [V]
            }
            let vResp = try JSONDecoder().decode(VResp.self, from: data)
            guard let v = vResp.results.first(where: { $0.type == "Trailer" }) else { return nil }
            
            // Lấy direct MP4 từ TMDB
            guard let streamURL = await fetchTMDBDirectVideo(movieId: movieId, videoKey: v.key) else { return nil }
            
            let m = movie as! Resp.M
            return TrailerVideo(id: v.id, name: v.name, movieTitle: m.title, movieId: m.id, posterPath: m.poster_path, backdropPath: m.backdrop_path, voteAverage: m.vote_average, releaseDate: m.release_date, overview: m.overview, streamURL: streamURL)
        } catch { return nil }
    }
    
    private func fetchTMDBDirectVideo(movieId: Int, videoKey: String) async -> URL? {
        // TMDB lưu video ở nhiều định dạng, thử lấy direct MP4
        let urls = [
            "https://api.themoviedb.org/3/movie/\(movieId)/videos?api_key=\(apiKey)&include_video_language=true",
            "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(apiKey)&append_to_response=videos,images"
        ]
        
        for urlStr in urls {
            guard let url = URL(string: urlStr) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let videos = json["videos"] as? [String: Any],
                   let results = videos["results"] as? [[String: Any]] {
                    for result in results {
                        if let site = result["site"] as? String, site == "YouTube",
                           let key = result["key"] as? String, key == videoKey {
                            // TMDB không host video trực tiếp, dùng youtube-nocookie qua WKWebView
                            // Fallback: dùng piped/invidious
                            return await resolveYouTubeURL(key: key)
                        }
                    }
                }
            } catch { continue }
        }
        return nil
    }
    
    private func resolveYouTubeURL(key: String) async -> URL? {
        let instances = [
            "https://pipedapi.kavin.rocks/streams/\(key)",
            "https://invidious.slipfox.xyz/api/v1/videos/\(key)"
        ]
        for urlStr in instances {
            guard let url = URL(string: urlStr) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct StreamResp: Codable {
                    struct Stream: Codable { let url: String; let quality: String; let container: String? }
                    let videoStreams: [Stream]?
                    let formatStreams: [Stream]?
                }
                let resp = try JSONDecoder().decode(StreamResp.self, from: data)
                let streams = resp.videoStreams ?? resp.formatStreams ?? []
                let mp4 = streams.filter { $0.container == "mp4" || $0.container == nil }.first { $0.quality == "720p" } ?? streams.first
                if let u = mp4.flatMap({ URL(string: $0.url) }) { return u }
            } catch { continue }
        }
        return nil
    }
}

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
                    ForEach(Array(trailers.enumerated()), id: \.offset) { i, t in
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
                    Spacer()
                    Circle().fill(.clear).frame(width: 36, height: 36)
                }.padding(.horizontal, 20).padding(.top, 50)
                Spacer()
            }
        }
        .task { trailers = await TrailerService.shared.fetchTrendingTrailers(); isLoading = false }
    }
}

struct TrailerCardView: View {
    let trailer: TrailerVideo
    @State private var player: AVPlayer?
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            if let player = player {
                TrailerPlayerView(player: player).ignoresSafeArea()
                    .onAppear { player.play() }
            } else {
                ZStack {
                    if let path = trailer.backdropPath ?? trailer.posterPath {
                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780\(path)"))
                            .aspectRatio(contentMode: .fill).frame(maxWidth: .infinity, maxHeight: .infinity).blur(radius: 20)
                    }
                    Color.black.opacity(0.4)
                    ProgressView().tint(.white).scaleEffect(1.2)
                }.ignoresSafeArea()
            }
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
                            HStack(spacing: 3) { Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow); Text(String(format: "%.1f", trailer.voteAverage)).font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                            Text("Trailer").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9)).padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.red.opacity(0.7)))
                        }
                    }
                    Spacer()
                    VStack(spacing: 20) {
                        Button { showDetail = true } label: {
                            VStack(spacing: 3) { Image(systemName: "play.rectangle.fill").font(.system(size: 28)).foregroundColor(.white); Text("Xem").font(.system(size: 9, weight: .bold)).foregroundColor(.white) }
                        }
                    }
                }.padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .onAppear { player = AVPlayer(url: trailer.streamURL) }
        .sheet(isPresented: $showDetail) {
            NavigationStack { MovieDetailView(movie: Movie(id: trailer.movieId, title: trailer.movieTitle, overview: trailer.overview, posterPath: trailer.posterPath, backdropPath: trailer.backdropPath, voteAverage: trailer.voteAverage, releaseDate: trailer.releaseDate, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: "movie")) }
        }
    }
}

struct TrailerPlayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        v.layer.addSublayer(layer)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in player.seek(to: .zero); player.play() }
        return v
    }
    func updateUIView(_ v: UIView, context: Context) {}
}