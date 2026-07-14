import SwiftUI
import AVKit

// MARK: - Models & Service
struct TrailerVideo: Identifiable, Codable {
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
    var resolvedURL: URL?
}

class TrailerService {
    static let shared = TrailerService()
    private let tmdbAPI = "https://api.themoviedb.org/3"
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let pipedAPI = "https://pipedapi.kavin.rocks"
    
    func fetchTrendingTrailers() async -> [TrailerVideo] {
        guard let url = URL(string: "\(tmdbAPI)/trending/movie/week?api_key=\(apiKey)&language=en-US") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Response: Codable {
                struct Movie: Codable {
                    let id: Int; let title: String; let posterPath: String?
                    let backdropPath: String?; let voteAverage: Double
                    let releaseDate: String?; let overview: String
                    enum CodingKeys: String, CodingKey {
                        case id, title, overview
                        case posterPath = "poster_path"
                        case backdropPath = "backdrop_path"
                        case voteAverage = "vote_average"
                        case releaseDate = "release_date"
                    }
                }
                let results: [Movie]
            }
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            var trailers: [TrailerVideo] = []
            for movie in response.results.prefix(15) {
                if let trailer = await fetchTrailer(movieId: movie.id, movie: movie) {
                    trailers.append(trailer)
                }
            }
            return trailers
        } catch {
            return []
        }
    }
    
    private func fetchTrailer(movieId: Int, movie: Any) async -> TrailerVideo? {
        guard let url = URL(string: "\(tmdbAPI)/movie/\(movieId)/videos?api_key=\(apiKey)&language=en-US") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct VideoResponse: Codable {
                struct Video: Codable {
                    let id: String; let key: String; let name: String
                    let site: String; let type: String
                }
                let results: [Video]
            }
            let response = try JSONDecoder().decode(VideoResponse.self, from: data)
            guard let t = response.results.first(where: { $0.type == "Trailer" && $0.site == "YouTube" }) else { return nil }
            
            return TrailerVideo(
                id: t.id, key: t.key, name: t.name, site: t.site, type: t.type,
                movieTitle: (movie as? TMDBMovie)?.title ?? "",
                movieId: movieId,
                posterPath: (movie as? TMDBMovie)?.posterPath,
                backdropPath: (movie as? TMDBMovie)?.backdropPath,
                voteAverage: (movie as? TMDBMovie)?.voteAverage ?? 0,
                releaseDate: (movie as? TMDBMovie)?.releaseDate,
                overview: (movie as? TMDBMovie)?.overview ?? ""
            )
        } catch {
            return nil
        }
    }
    
    func resolveStreamURL(youtubeKey: String) async -> URL? {
    // Thử Invidious API
    let invidiousURLs = [
        "https://invidious.slipfox.xyz/api/v1/videos/\(youtubeKey)",
        "https://inv.nadeko.net/api/v1/videos/\(youtubeKey)",
        "https://invidious.privacyredirect.com/api/v1/videos/\(youtubeKey)"
    ]
    
    for urlStr in invidiousURLs {
        guard let url = URL(string: urlStr) else { continue }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct IVideo: Codable {
                struct FormatStream: Codable { let url: String; let quality: String; let container: String }
                let formatStreams: [FormatStream]
            }
            let video = try JSONDecoder().decode(IVideo.self, from: data)
            let stream = video.formatStreams
                .filter { $0.container == "mp4" }
                .first { $0.quality == "720p" } ?? video.formatStreams.first
            if let url = stream.flatMap({ URL(string: $0.url) }) {
                return url
            }
        } catch { continue }
    }
    
    // Fallback: YouTube embed direct
    return URL(string: "https://www.youtube.com/watch?v=\(youtubeKey)")
}

private struct TMDBMovie: Codable {
    let id: Int; let title: String; let posterPath: String?
    let backdropPath: String?; let voteAverage: Double
    let releaseDate: String?; let overview: String
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
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
                VStack(spacing: 12) {
                    Image(systemName: "film.slash").font(.system(size: 50)).foregroundColor(.gray)
                    Text("Không có trailer nào").foregroundColor(.gray)
                }
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(trailers.enumerated()), id: \.element.id) { index, trailer in
                        TrailerCardView(
                            trailer: trailer,
                            isActive: index == currentIndex
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                    }
                    
                    Spacer()
                    
                    Text("🎬 Trailers")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.clear)
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
            }
        }
        .task {
            trailers = await TrailerService.shared.fetchTrendingTrailers()
            isLoading = false
        }
    }
}

// MARK: - TrailerCardView
struct TrailerCardView: View {
    let trailer: TrailerVideo
    let isActive: Bool
    @State private var player: AVPlayer?
    @State private var resolvedURL: URL?
    @State private var isMuted = false
    @State private var showMovieDetail = false
    @State private var selectedMovie: Movie?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if let player = player {
                TrailerPlayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear { if isActive { player.play() } }
                    .onDisappear { player.pause() }
            } else {
                ZStack {
                    if let posterPath = trailer.backdropPath ?? trailer.posterPath,
                       let url = URL(string: "https://image.tmdb.org/t/p/w780\(posterPath)") {
                        CachedAsyncImage(url: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .blur(radius: 20)
                            .overlay(Color.black.opacity(0.4))
                    } else {
                        Color.black
                    }
                    
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Text("Đang tải trailer...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                .allowsHitTesting(false)
            }
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trailer.movieTitle)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", trailer.voteAverage))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            if let date = trailer.releaseDate {
                                Text(date.prefix(4).description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("Trailer")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.red.opacity(0.7)))
                        }
                        
                        if !trailer.overview.isEmpty {
                            Text(trailer.overview)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(3)
                                .frame(maxWidth: 280)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Button {
                            let movie = Movie(
                                id: trailer.movieId,
                                title: trailer.movieTitle,
                                overview: trailer.overview,
                                posterPath: trailer.posterPath,
                                backdropPath: trailer.backdropPath,
                                voteAverage: trailer.voteAverage,
                                releaseDate: trailer.releaseDate,
                                genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil,
                                adult: false, originalLanguage: nil, mediaType: "movie"
                            )
                            selectedMovie = movie
                            showMovieDetail = true
                            player?.pause()
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                Text("Xem")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: isActive) { active in
            if active {
                player?.play()
                loadStreamIfNeeded()
            } else {
                player?.pause()
            }
        }
        .onAppear {
            if isActive { loadStreamIfNeeded() }
        }
        .fullScreenCover(isPresented: $showMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailView(movie: movie)
            }
        }
    }
    
    private func loadStreamIfNeeded() {
        guard resolvedURL == nil else { return }
        
        Task {
            if let url = await TrailerService.shared.resolveStreamURL(youtubeKey: trailer.key) {
                await MainActor.run {
                    resolvedURL = url
                    let player = AVPlayer(url: url)
                    player.isMuted = isMuted
                    self.player = player
                }
            }
        }
    }
}

// MARK: - TrailerPlayerView
struct TrailerPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}