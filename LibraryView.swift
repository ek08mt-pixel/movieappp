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
        case watched2 = "Đã xem"
    }
    
    var currentMovies: [Movie] {
        switch selectedTab {
        case .saved: return appState.favorites
        case .watched: return appState.watchHistory
        case .watched2: return appState.watchedMovies
        }
    }
    
    private let savedColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        tabButton(.watched)
                        tabButton(.saved)
                        tabButton(.watched2)
                    }
                    .padding(4)
                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
                    .padding(.horizontal, 20).padding(.top, 8)
                    
                    if currentMovies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: emptyIcon).font(.system(size: 50)).foregroundColor(.gray)
                            Text(emptyText).foregroundColor(.gray)
                        }.frame(maxHeight: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Xóa tất cả") {
                                    withAnimation {
                                        switch selectedTab {
                                        case .watched: appState.watchHistory.removeAll(); appState.save()
                                        case .saved: appState.favorites.removeAll(); appState.save()
                                        case .watched2: appState.watchedMovies.removeAll(); appState.save()
                                        }
                                    }
                                }
                                .font(.system(size: 12)).foregroundColor(.red.opacity(0.7))
                            }
                            .padding(.horizontal, 20).padding(.top, 8)
                            
                            if selectedTab == .saved {
                                savedGridView
                            } else if selectedTab == .watched {
                                watchedListView
                            } else {
                                watchedListView
                            }
                        }
                    }
                }
            }
            .fullScreenCover(item: $playMovie) { movie in
                let p = appState.watchProgressList.first { $0.movieId == movie.id }
                MoviePlayerView(movieId: movie.id, movieTitle: movie.originalTitle ?? movie.title, mediaType: movie.mediaType, seasonNumber: p?.season, episodeNumber: p?.episode, posterURL: movie.posterURL, resumeTime: p?.currentTime ?? 0).environmentObject(appState)
            }
        }
    }
    
    var emptyIcon: String {
        switch selectedTab {
        case .watched: return "eye.slash"
        case .saved: return "bookmark.slash"
        case .watched2: return "checkmark.circle.slash"
        }
    }
    var emptyText: String {
        switch selectedTab {
        case .watched: return "Chưa có phim đã xem"
        case .saved: return "Chưa có phim đã lưu"
        case .watched2: return "Chưa có phim đánh dấu đã xem"
        }
    }
    
    var savedGridView: some View {
        ScrollView {
            LazyVGrid(columns: savedColumns, spacing: 16) {
                ForEach(currentMovies) { movie in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 6) {
                                CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(height: 160).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                Text(movie.title).font(.system(size: 10, weight: .medium)).foregroundColor(.white).lineLimit(2)
                            }
                        }
                        Button {
                            withAnimation { appState.favorites.removeAll { $0.id == movie.id }; appState.save() }
                        } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(.white.opacity(0.8)).padding(4)
                        }
                    }
                }
            }.padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 100)
        }
    }
    
    var watchedListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentMovies) { movie in
                    let p = appState.watchProgressList.first { $0.movieId == movie.id }
                    let has = (p?.currentTime ?? 0) > 0 && (p?.duration ?? 1) > 0
                    ZStack(alignment: .trailing) {
                        HStack(spacing: 12) {
                            ZStack(alignment: .center) {
                                CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 80, height: 120).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                Button { playMovie = movie } label: { Circle().fill(.black.opacity(0.6)).frame(width: 36, height: 36).overlay(Image(systemName: "play.fill").font(.system(size: 14)).foregroundColor(.white).offset(x: 1)) }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                NavigationLink(destination: MovieDetailView(movie: movie)) { Text(movie.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(1) }
                                if let ep = p?.episode, let s = p?.season { Text("S\(s):E\(ep)").font(.system(size: 11)).foregroundColor(.gray) }
                                if has {
                                    Text("Tiếp tục từ \(formatProgressTime(p!.currentTime))").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                                    GeometryReader { g in ZStack(alignment: .leading) { Capsule().fill(.white.opacity(0.1)).frame(height: 4); Capsule().fill(.white.opacity(0.5)).frame(width: max(4, g.size.width * CGFloat(min(p!.currentTime / p!.duration, 1))), height: 4) } }.frame(height: 4)
                                    Button { playMovie = movie } label: { Text("Xem tiếp").font(.system(size: 12, weight: .medium)).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 6).background(Capsule().fill(.ultraThinMaterial.opacity(0.6))).overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5)) }
                                }
                            }
                            Spacer()
                        }
                        .padding(12).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.25)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 0.5)))
                        
                        // Swipe to delete
                        if selectedTab == .watched {
                            Button {
                                withAnimation {
                                    appState.watchHistory.removeAll { $0.id == movie.id }
                                    appState.watchProgressList.removeAll { $0.movieId == movie.id }
                                    appState.save()
                                }
                            } label: {
                                Image(systemName: "trash.fill").font(.system(size: 16)).foregroundColor(.red).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                            .offset(x: 60)
                        }
                        if selectedTab == .watched2 {
                            Button {
                                withAnimation { appState.watchedMovies.removeAll { $0.id == movie.id }; appState.save() }
                            } label: {
                                Image(systemName: "trash.fill").font(.system(size: 16)).foregroundColor(.red).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                            .offset(x: 60)
                        }
                    }
                }
            }.padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 100)
        }
    }
    
    func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = tab }
        } label: {
            Text(tab.rawValue).font(.system(size: 13, weight: isSelected ? .bold : .regular)).foregroundColor(isSelected ? .white : .gray).frame(maxWidth: .infinity).padding(.vertical, 10).background(Group { if isSelected { Capsule().fill(.ultraThinMaterial.opacity(0.5)) } else { Capsule().fill(Color.clear) } }).clipShape(Capsule())
        }
    }
    
    func formatProgressTime(_ s: Double) -> String {
        let t = Int(max(0, s)); let h = t/3600; let m = (t%3600)/60; let sec = t%60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}