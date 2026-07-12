import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: LibraryTab = .watched
    @State private var playMovie: Movie?
    @State private var playSeason: Int?
    @State private var playEpisode: Int?
    @State private var playResumeTime: Double = 0
    @State private var playMediaType: String?
    @State private var showPlayer = false
    
    enum LibraryTab: String, CaseIterable {
        case watched = "Vừa xem"
        case saved = "Đã lưu"
    }
    
    var currentMovies: [Movie] {
        selectedTab == .saved ? appState.favorites : appState.watchHistory
    }
    
    private let savedColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.12), Color(white: 0.05), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        tabButton(.watched)
                        tabButton(.saved)
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    )
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
                    
                    if currentMovies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: selectedTab == .saved ? "bookmark.slash" : "eye.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(selectedTab == .saved ? "Chưa có phim đã lưu" : "Chưa có phim đã xem")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else if selectedTab == .saved {
                        // Grid 3 cột cho Đã lưu
                        ScrollView {
                            LazyVGrid(columns: savedColumns, spacing: 16) {
                                ForEach(currentMovies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(height: 160)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                            Text(movie.title)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .frame(height: 30, alignment: .top)
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 100)
                        }
                    } else {
                        // List cho Từng xem
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(currentMovies) { movie in
                                    watchHistoryRow(movie)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let movie = playMovie {
                    MoviePlayerView(
                        movieId: movie.id,
                        movieTitle: movie.title,
                        mediaType: playMediaType,
                        seasonNumber: playSeason,
                        episodeNumber: playEpisode,
                        posterURL: movie.posterURL,
                        resumeTime: playResumeTime
                    )
                    .environmentObject(appState)
                }
            }
        }
    }
    
    func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(.ultraThinMaterial.opacity(0.5))
                        } else {
                            Capsule().fill(Color.clear)
                        }
                    }
                )
                .clipShape(Capsule())
        }
    }
    
    func watchHistoryRow(_ movie: Movie) -> some View {
        let progress = appState.watchProgressList.first { $0.movieId == movie.id }
        let hasProgress = (progress?.currentTime ?? 0) > 0 && (progress?.duration ?? 1) > 0
        let progressValue = hasProgress ? (progress!.currentTime / progress!.duration) : 0
        
        return Button {
            playMovie = movie
            playSeason = progress?.season
            playEpisode = progress?.episode
            playResumeTime = progress?.currentTime ?? 0
            playMediaType = progress?.mediaType
            showPlayer = true
        } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    CachedAsyncImage(url: movie.posterURL)
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    
                    Circle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(movie.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let ep = progress?.episode, let s = progress?.season {
                        Text("S\(s):E\(ep)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    } else if hasProgress {
                        Text(movie.yearText)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    if hasProgress {
                        Text("Tiếp tục từ \(formatProgressTime(progress!.currentTime))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(.white.opacity(0.5))
                                    .frame(width: max(4, geo.size.width * CGFloat(progressValue)), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("Xem tiếp")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Capsule().fill(.ultraThinMaterial.opacity(0.6)))
                            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    func formatProgressTime(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}