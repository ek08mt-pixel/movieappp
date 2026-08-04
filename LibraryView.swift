import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: LibraryTab = .watched
    @State private var selectedListID: String? = nil
    @State private var playMovie: Movie?
    @State private var showNewListAlert = false
    @State private var newListName = ""
    
    enum LibraryTab: String, CaseIterable {
        case watched = "Vừa xem"
        case saved = "Đã lưu"
    }
    
    var currentMovies: [Movie] {
    switch selectedTab {
    case .saved:
        if let listID = selectedListID, let list = appState.movieLists.first(where: { $0.id == listID }) {
            return list.movies
        }
        return appState.favorites
    case .watched:
        return appState.watchHistory
    }
}
    
    private let savedColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Tab buttons
                    HStack(spacing: 0) {
                        tabButton(.watched)
                        tabButton(.saved)
                    }
                    .padding(4)
                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
                    .padding(.horizontal, 20).padding(.top, 8)
                    
                    // List selector - chỉ hiện ở tab Đã lưu
                    if selectedTab == .saved && !appState.movieLists.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // Nút "Tất cả"
                                Button {
                                    withAnimation { selectedListID = nil }
                                } label: {
                                    Text("Tất cả")
                                        .font(.system(size: 12, weight: selectedListID == nil ? .bold : .regular))
                                        .foregroundColor(selectedListID == nil ? .white : .gray)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Capsule().fill(selectedListID == nil ? .white.opacity(0.2) : .white.opacity(0.05)))
                                }
                                
                                ForEach(appState.movieLists) { list in
                                    Button {
                                        withAnimation { selectedListID = list.id }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(list.name)
                                                .font(.system(size: 12, weight: selectedListID == list.id ? .bold : .regular))
                                                .foregroundColor(selectedListID == list.id ? .white : .gray)
                                            Text("\(list.movieIds.count)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Capsule().fill(selectedListID == list.id ? .white.opacity(0.2) : .white.opacity(0.05)))
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            appState.movieLists.removeAll { $0.id == list.id }
                                            if selectedListID == list.id { selectedListID = nil }
                                            appState.save()
                                        } label: {
                                            Label("Xóa list", systemImage: "trash")
                                        }
                                    }
                                }
                                
                                // Nút thêm list mới
                                Button {
                                    showNewListAlert = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(.white.opacity(0.1)))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                    }
                    
                    if currentMovies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: emptyIcon).font(.system(size: 50)).foregroundColor(.gray)
                            Text(emptyText).foregroundColor(.gray)
                        }.frame(maxHeight: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                if selectedListID != nil {
                                    Button("Bỏ lọc") {
                                        withAnimation { selectedListID = nil }
                                    }
                                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                                }
                                Button("Xóa tất cả") {
                                    withAnimation {
                                        switch selectedTab {
                                        case .watched: appState.watchHistory.removeAll(); appState.watchProgressList.removeAll(); appState.save()
                                        case .saved: appState.favorites.removeAll(); appState.save()
                                        }
                                    }
                                }
                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 20).padding(.top, 8)
                            
                            if selectedTab == .saved {
                                savedGridView
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
            .alert("Tạo list mới", isPresented: $showNewListAlert) {
                TextField("Tên list", text: $newListName)
                Button("Tạo") {
                    if !newListName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let newList = MovieList(name: newListName)
                        appState.movieLists.append(newList)
                        appState.save()
                        newListName = ""
                    }
                }
                Button("Hủy", role: .cancel) { newListName = "" }
            }
        }
    }
    
    var emptyIcon: String {
        switch selectedTab {
        case .watched: return "eye.slash"
        case .saved: return "bookmark.slash"
        }
    }
    var emptyText: String {
        switch selectedTab {
        case .watched: return "Chưa có phim đã xem"
        case .saved: return "Chưa có phim đã lưu"
        }
    }
    
    var savedGridView: some View {
        ScrollView {
            LazyVGrid(columns: savedColumns, spacing: 12) {
                ForEach(currentMovies) { movie in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 6) {
                                CachedAsyncImage(url: movie.posterURL)
                                    .aspectRatio(2/3, contentMode: .fill)
                                    .frame(width: (UIScreen.main.bounds.width - 56) / 3, height: ((UIScreen.main.bounds.width - 56) / 3) * 1.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(movie.title).font(.system(size: 10, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(height: 28)
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
        List {
            ForEach(currentMovies) { movie in
                let p = appState.watchProgressList.first { $0.movieId == movie.id }
                let has = (p?.currentTime ?? 0) > 0 && (p?.duration ?? 1) > 0
                
                HStack(spacing: 12) {
                    ZStack(alignment: .center) {
                        CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 80, height: 120).clipShape(RoundedRectangle(cornerRadius: 12))
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
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation {
                            switch selectedTab {
                            case .watched:
                                appState.watchHistory.removeAll { $0.id == movie.id }
                                appState.watchProgressList.removeAll { $0.movieId == movie.id }
                            default: break
                            }
                            appState.save()
                        }
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                    .tint(.white.opacity(0.3))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = tab; selectedListID = nil }
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