import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dm = HLSDownloadManager.shared
    @State private var selectedTab: LibraryTab = .watched
    @State private var playMovie: Movie?
    @State private var showOfflinePlayer = false
    @State private var offlineURL: URL?
    @State private var offlineTitle = ""
    
    enum LibraryTab: String, CaseIterable {
        case watched = "Vừa xem"
        case saved = "Đã lưu"
        case downloads = "Đã tải"
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
                        tabButton(.downloads)
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    if selectedTab == .downloads {
                        downloadsView
                    } else if currentMovies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: selectedTab == .saved ? "bookmark.slash" : "eye.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(selectedTab == .saved ? "Chưa có phim đã lưu" : "Chưa có phim đã xem")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else if selectedTab == .saved {
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
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 100)
                        }
                    } else {
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
            .fullScreenCover(item: $playMovie) { movie in
                let progress = appState.watchProgressList.first { $0.movieId == movie.id }
                MoviePlayerView(
                    movieId: movie.id,
                    movieTitle: movie.originalTitle ?? movie.title,
                    mediaType: movie.mediaType,
                    seasonNumber: progress?.season,
                    episodeNumber: progress?.episode,
                    posterURL: movie.posterURL,
                    resumeTime: progress?.currentTime ?? 0
                )
                .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showOfflinePlayer) {
                if let url = offlineURL {
                    DownloadedPlayerView(url: url, title: offlineTitle)
                }
            }
        }
    }
    
    var downloadsView: some View {
        Group {
            if dm.downloads.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle").font(.system(size: 50)).foregroundColor(.gray)
                    Text("Chưa có phim tải về").foregroundColor(.gray)
                    Text("Bấm nút tải trong lúc xem phim").font(.system(size: 12)).foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dm.downloads) { item in
                            downloadRow(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    func downloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 12) {
            if let path = item.posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w200\(path)") {
                CachedAsyncImage(url: url)
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .frame(width: 60, height: 90)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.movieTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let ep = item.episodeNumber, let s = item.seasonNumber {
                    Text("S\(s):E\(ep)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                switch item.status {
                case .downloading:
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.1)).frame(height: 3)
                                Capsule().fill(.blue).frame(width: max(3, geo.size.width * CGFloat(item.progress)), height: 3)
                            }
                        }
                        .frame(height: 3)
                        Text("\(Int(item.progress * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                case .completed:
                    Text("Đã tải xong")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                case .failed:
                    Text("Tải thất bại")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                if item.status == .downloading {
                    Button {
                        dm.cancel(item.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                } else if item.status == .completed {
                    Button {
                        offlineURL = item.localURL
                        offlineTitle = item.movieTitle
                        showOfflinePlayer = true
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                }
                
                Button {
                    dm.delete(item.id)
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 0.5))
        )
    }
    
    func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Group {
                    if isSelected {
                        Capsule().fill(.ultraThinMaterial.opacity(0.5))
                    } else {
                        Capsule().fill(Color.clear)
                    }
                })
                .clipShape(Capsule())
        }
    }
    
    func watchHistoryRow(_ movie: Movie) -> some View {
        let progress = appState.watchProgressList.first { $0.movieId == movie.id }
        let hasProgress = (progress?.currentTime ?? 0) > 0 && (progress?.duration ?? 1) > 0
        let progressValue = hasProgress ? (progress!.currentTime / progress!.duration) : 0
        
        return HStack(spacing: 12) {
            ZStack(alignment: .center) {
                CachedAsyncImage(url: movie.posterURL)
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                Button {
                    playMovie = movie
                } label: {
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
            }
            
            VStack(alignment: .leading, spacing: 6) {
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    Text(movie.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                if let ep = progress?.episode, let s = progress?.season {
                    Text("S\(s):E\(ep)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                if hasProgress {
                    Text("Tiếp tục từ \(formatProgressTime(progress!.currentTime))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.1)).frame(height: 4)
                            Capsule().fill(.white.opacity(0.5)).frame(width: max(4, geo.size.width * CGFloat(progressValue)), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Button {
                        playMovie = movie
                    } label: {
                        Text("Xem tiếp")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Capsule().fill(.ultraThinMaterial.opacity(0.6)))
                            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 0.5))
        )
    }
    
    func formatProgressTime(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600; let m = (total % 3600) / 60; let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}