import SwiftUI
import AVKit
import AVFoundation
import WebKit

// MARK: - TrailerVideo Model
struct TrailerVideo: Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let movieTitle: String
    let movieId: Int
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let overview: String
    let imdbID: String?
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
private struct TMDBExternalIDResp: Codable { let imdb_id: String? }
private struct InvidiousVideo: Codable {
    struct FS: Codable { let url: String; let quality: String; let container: String }
    let formatStreams: [FS]
}

// MARK: - TrailerService
class TrailerService {
    static let shared = TrailerService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    func fetchTrendingTrailers() async -> [TrailerVideo] {
        guard let url = URL(string: "https://api.themoviedb.org/3/trending/movie/week?api_key=\(apiKey)&language=en-US") else { return [] }
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
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(m.id)/videos?api_key=\(apiKey)&language=en-US") else { return nil }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            let v = try JSONDecoder().decode(TMDBVideoResp.self, from: d)
            guard let t = v.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" }) else { return nil }
            
            // Fetch IMDB ID
            var imdbID: String? = nil
            if let extURL = URL(string: "https://api.themoviedb.org/3/movie/\(m.id)/external_ids?api_key=\(apiKey)") {
                if let (ed, _) = try? await URLSession.shared.data(from: extURL),
                   let ext = try? JSONDecoder().decode(TMDBExternalIDResp.self, from: ed) {
                    imdbID = ext.imdb_id
                }
            }
            
            return TrailerVideo(id: t.id, key: t.key, name: t.name, site: t.site, type: t.type,
                                movieTitle: m.title, movieId: m.id, posterPath: m.poster_path,
                                backdropPath: m.backdrop_path, voteAverage: m.vote_average,
                                releaseDate: m.release_date, overview: m.overview, imdbID: imdbID)
        } catch { return nil }
    }
    
    func resolveStreamURL(trailer: TrailerVideo) async -> URL? {
        // Cách 1: IMDb direct MP4
        if let imdbID = trailer.imdbID, let url = await fetchIMDbTrailer(imdbID: imdbID) {
            return url
        }
        
        // Cách 2: Invidious
        if let url = await resolveInvidious(youtubeKey: trailer.key) {
            return url
        }
        
        // Cách 3: Piped fallback
        if let url = await resolvePiped(youtubeKey: trailer.key) {
            return url
        }
        
        return nil
    }
    
    private func fetchIMDbTrailer(imdbID: String) async -> URL? {
        guard let url = URL(string: "https://www.imdb.com/title/\(imdbID)/videogallery") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            
            // Tìm pattern video trong JSON-LD hoặc script
            let patterns = [
                "videoUrl\":\"",
                "\"contentUrl\":\"",
                "src=\"https://imdb-video"
            ]
            
            for pattern in patterns {
                if let range = html.range(of: pattern) {
                    let start = range.upperBound
                    if let endRange = html[start...].range(of: "\"") {
                        var videoPath = String(html[start..<endRange.lowerBound])
                            .replacingOccurrences(of: "\\u0026", with: "&")
                            .replacingOccurrences(of: "\\/", with: "/")
                        
                        if videoPath.hasPrefix("http") {
                            return URL(string: videoPath)
                        } else if videoPath.contains("imdb-video") {
                            return URL(string: "https://imdb-video.media-imdb.com/\(videoPath)")
                        }
                    }
                }
            }
            
            // Fallback: tìm .mp4 trực tiếp
            if let mp4Range = html.range(of: "https://imdb-video.media-imdb.com/"),
               let endRange = html[mp4Range.upperBound...].range(of: ".mp4") {
                let videoPath = String(html[mp4Range.lowerBound..<endRange.upperBound])
                return URL(string: videoPath)
            }
        } catch {}
        return nil
    }
    
    private func resolveInvidious(youtubeKey: String) async -> URL? {
        let urls = [
            "https://invidious.slipfox.xyz/api/v1/videos/\(youtubeKey)",
            "https://inv.nadeko.net/api/v1/videos/\(youtubeKey)",
            "https://invidious.privacyredirect.com/api/v1/videos/\(youtubeKey)"
        ]
        for urlStr in urls {
            guard let url = URL(string: urlStr) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let iv = try JSONDecoder().decode(InvidiousVideo.self, from: data)
                let s = iv.formatStreams.filter { $0.container == "mp4" }.first { $0.quality == "720p" } ?? iv.formatStreams.first
                if let u = s.flatMap({ URL(string: $0.url) }) { return u }
            } catch { continue }
        }
        return nil
    }
    
    private func resolvePiped(youtubeKey: String) async -> URL? {
        guard let url = URL(string: "https://pipedapi.kavin.rocks/streams/\(youtubeKey)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct PipedResp: Codable {
                struct Stream: Codable { let url: String; let quality: String }
                let videoStreams: [Stream]
            }
            let resp = try JSONDecoder().decode(PipedResp.self, from: data)
            let s = resp.videoStreams.first { $0.quality == "720p" } ?? resp.videoStreams.first
            return s.flatMap { URL(string: $0.url) }
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
                VStack {
                    Image(systemName: "film.slash").font(.system(size: 50)).foregroundColor(.gray)
                    Text("Không có trailer").foregroundColor(.gray)
                }
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
                    Spacer()
                    Circle().fill(.clear).frame(width: 36, height: 36)
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
    @State private var player: AVPlayer?
    @State private var loadFailed = false
    @State private var showDetail = false
    @State private var isLoadingStream = true
    
    var body: some View {
        ZStack {
            if let player = player {
                TrailerPlayerView(player: player).ignoresSafeArea()
                    .onAppear { player.play() }
            } else if loadFailed {
                ZStack {
                    if let path = trailer.backdropPath ?? trailer.posterPath {
                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780\(path)"))
                            .aspectRatio(contentMode: .fill).frame(maxWidth: .infinity, maxHeight: .infinity).blur(radius: 20)
                    }
                    Color.black.opacity(0.6)
                    VStack(spacing: 16) {
                        Image(systemName: "play.slash").font(.system(size: 50)).foregroundColor(.gray)
                        Text("Không thể tải trailer").font(.headline).foregroundColor(.white)
                        Text("Thử lại sau hoặc mở YouTube").font(.caption).foregroundColor(.gray)
                        Button {
                            if let url = URL(string: "youtube://watch?v=\(trailer.key)") {
                                UIApplication.shared.open(url)
                            } else if let url = URL(string: "https://youtube.com/watch?v=\(trailer.key)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text("Mở YouTube")
                            }
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 24).padding(.vertical, 10)
                            .background(Capsule().fill(.red))
                        }
                    }
                }.ignoresSafeArea()
            } else {
                ZStack {
                    if let path = trailer.backdropPath ?? trailer.posterPath {
                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780\(path)"))
                            .aspectRatio(contentMode: .fill).frame(maxWidth: .infinity, maxHeight: .infinity).blur(radius: 20)
                    }
                    Color.black.opacity(0.4)
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Text("Đang tải trailer...").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
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
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow)
                                Text(String(format: "%.1f", trailer.voteAverage)).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            }
                            Text("Trailer").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(.red.opacity(0.7)))
                        }
                    }
                    Spacer()
                    VStack(spacing: 20) {
                        Button { showDetail = true; player?.pause() } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "play.rectangle.fill").font(.system(size: 28)).foregroundColor(.white)
                                Text("Xem").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                }.padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .onAppear { loadStream() }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                MovieDetailView(movie: Movie(
                    id: trailer.movieId, title: trailer.movieTitle, overview: trailer.overview,
                    posterPath: trailer.posterPath, backdropPath: trailer.backdropPath,
                    voteAverage: trailer.voteAverage, releaseDate: trailer.releaseDate,
                    genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil,
                    adult: false, originalLanguage: nil, mediaType: "movie"
                ))
            }
        }
    }
    
    private func loadStream() {
        guard player == nil else { return }
        Task {
            if let url = await TrailerService.shared.resolveStreamURL(trailer: trailer) {
                await MainActor.run {
                    let p = AVPlayer(url: url)
                    self.player = p
                    isLoadingStream = false
                }
            } else {
                await MainActor.run {
                    loadFailed = true
                    isLoadingStream = false
                }
            }
        }
    }
}

// MARK: - TrailerPlayerView
struct TrailerPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        v.layer.addSublayer(layer)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        return v
    }
    
    func updateUIView(_ v: UIView, context: Context) {}
}