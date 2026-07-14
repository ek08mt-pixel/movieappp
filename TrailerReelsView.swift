import SwiftUI
import AVKit

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
            
            // Header
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
                    
                    // Placeholder để giữ layout
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
            // Video Player
            if let player = player {
                TrailerPlayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        if isActive {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // Loading placeholder
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
            
            // Overlay gradient bottom
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
            
            // Movie info + action buttons
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 16) {
                    // Movie info - bên trái
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
                    
                    // Action buttons - bên phải
                    VStack(spacing: 20) {
                        // Like button
                        Button {
                            // TODO: Add to favorites
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "heart")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                Text("Like")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Share button
                        Button {
                            // TODO: Share
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                Text("Share")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Xem phim button
                        Button {
                            let movie = Movie(
                                id: trailer.movieId,
                                title: trailer.movieTitle,
                                overview: trailer.overview,
                                posterPath: trailer.posterPath,
                                backdropPath: trailer.backdropPath,
                                voteAverage: trailer.voteAverage,
                                releaseDate: trailer.releaseDate,
                                genreIds: nil,
                                originalTitle: nil,
                                popularity: nil,
                                voteCount: nil,
                                adult: false,
                                originalLanguage: nil,
                                mediaType: "movie"
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
                        
                        // Mute/unmute
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
            if isActive {
                loadStreamIfNeeded()
            }
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

// MARK: - TrailerPlayerView (UIViewRepresentable cho AVPlayer)
struct TrailerPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)
        
        // Loop
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