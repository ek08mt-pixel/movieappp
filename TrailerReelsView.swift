import SwiftUI
import AVKit
import AVFoundation

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
}

// MARK: - TMDB Movie (internal)
private struct TMDBMovie: Codable {
    let id: Int; let title: String; let poster_path: String?
    let backdrop_path: String?; let vote_average: Double
    let release_date: String?; let overview: String
}

private struct TMDBTrendingResponse: Codable {
    let results: [TMDBMovie]
}

private struct TMDBVideoResponse: Codable {
    struct Video: Codable { let id: String; let key: String; let name: String; let site: String; let type: String }
    let results: [Video]
}

private struct InvidiousVideo: Codable {
    struct FormatStream: Codable { let url: String; let quality: String; let container: String }
    let formatStreams: [FormatStream]
}

// MARK: - TrailerService
class TrailerService {
    static let shared = TrailerService()
    private let tmdbAPI = "https://api.themoviedb.org/3"
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    
    func fetchTrendingTrailers() async -> [TrailerVideo] {
        guard let url = URL(string: "\(tmdbAPI)/trending/movie/week?api_key=\(apiKey)&language=en-US") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(TMDBTrendingResponse.self, from: data)
            
            var trailers: [TrailerVideo] = []
            for movie in resp.results.prefix(15) {
                if let trailer = await fetchTrailer(for: movie) {
                    trailers.append(trailer)
                }
            }
            return trailers
        } catch {
            return []
        }
    }
    
    private func fetchTrailer(for movie: TMDBMovie) async -> TrailerVideo? {
        guard let url = URL(string: "\(tmdbAPI)/movie/\(movie.id)/videos?api_key=\(apiKey)&language=en-US") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let vResp = try JSONDecoder().decode(TMDBVideoResponse.self, from: data)
            guard let v = vResp.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" }) else { return nil }
            
            return TrailerVideo(
                id: v.id, key: v.key, name: v.name, site: v.site, type: v.type,
                movieTitle: movie.title, movieId: movie.id,
                posterPath: movie.poster_path, backdropPath: movie.backdrop_path,
                voteAverage: movie.vote_average, releaseDate: movie.release_date, overview: movie.overview
            )
        } catch {
            return nil
        }
    }
    
    func resolveStreamURL(youtubeKey: String) async -> URL? {
        let urls = [
            "https://invidious.slipfox.xyz/api/v1/videos/\(youtubeKey)",
            "https://inv.nadeko.net/api/v1/videos/\(youtubeKey)"
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
                    Text("Không có trailer nào").foregroundColor(.gray)
                }
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(trailers.enumerated()), id: \.element.id) { i, t in
                        TrailerCardView(trailer: t, isActive: i == currentIndex).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    Spacer()
                    Text("🎬 Trailers").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Circle().fill(.clear).frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20).padding(.top, 50)
                Spacer()
            }
        }
        .task { trailers = await TrailerService.shared.fetchTrendingTrailers(); isLoading = false }
    }
}

// MARK: - TrailerCardView
struct TrailerCardView: View {
    let trailer: TrailerVideo
    let isActive: Bool
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            YouTubeEmbedView(videoID: trailer.key)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
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
                                .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.red.opacity(0.7)))
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
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
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