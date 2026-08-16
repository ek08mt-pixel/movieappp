import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var animeCurrentIndex = 0
    @State private var timer: Timer?
    @State private var animeTimer: Timer?
    @State private var showMenu = false
    @State private var menuOffset: CGFloat = -280
    @State private var showGenrePopup = false
    @State private var hideStatusBar = false
    
    @State private var continueMovieId: Int?
    @State private var continueMovieTitle = ""
    @State private var continueMediaType: String?
    @State private var continueSeason: Int?
    @State private var continueEpisode: Int?
    @State private var continuePosterURL: URL?
    @State private var continueCurrentTime: Double = 0
    
    @State private var showContinueDetail = false
    @State private var detailMovie: Movie?
    @State private var backdropCache: [Int: URL] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.08), Color(white: 0.04), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial.opacity(0.05))
                
                ScrollView {
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { offset in
                                if offset < -50 {
                                    withAnimation(.easeOut(duration: 0.25)) { hideStatusBar = true }
                                } else {
                                    withAnimation(.easeOut(duration: 0.25)) { hideStatusBar = false }
                                }
                            }
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        // Banner Hero
                        TabView(selection: $currentIndex) {
                            ForEach(Array(vm.trending24h.prefix(10).enumerated()), id: \.element.id) { i, movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    ZStack {
                                        if let bgURL = movie.backdropURL {
                                            CachedAsyncImage(url: bgURL, size: .backdrop)
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 480)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .blur(radius: 50)
                                                .overlay(Color.black.opacity(0.25))
                                                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
                                        } else {
                                            Rectangle().fill(.ultraThinMaterial.opacity(0.15)).frame(height: 480)
                                        }
                                        VStack(spacing: 0) {
                                            Spacer()
                                            if let posterURL = movie.posterURL {
                                                CachedAsyncImage(url: posterURL)
                                                    .aspectRatio(2/3, contentMode: .fit).frame(height: 320)
                                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                                    .shadow(color: .white.opacity(0.1), radius: 10, y: -5)
                                                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 1.5))
                                                    .overlay(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.05)))
                                            }
                                            Spacer().frame(height: 14)
                                            Text(movie.title).font(.system(size: 24, weight: .bold, design: .serif))
                                                .foregroundColor(.white).multilineTextAlignment(.center)
                                                .shadow(color: .black.opacity(0.9), radius: 8).padding(.horizontal, 24)
                                            Spacer().frame(height: 6)
                                            if let genres = movie.genreIds {
                                                let names = genres.prefix(3).compactMap { id in
                                                    vm.genres.first(where: { $0.id == id })?.name.replacingOccurrences(of: "Phim ", with: "")
                                                }
                                                if !names.isEmpty {
                                                    Text(names.joined(separator: " • ")).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.8))
                                                }
                                            }
                                            Spacer().frame(height: 14); Spacer().frame(height: 20)
                                        }
                                    }
                                }.tag(i)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 480)
                        .onAppear { startAutoScroll() }.onDisappear { stopAutoScroll() }
                        .overlay(alignment: .topLeading) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu.toggle(); menuOffset = showMenu ? 0 : -280 }
                            } label: {
                                Image(systemName: "line.3.horizontal").font(.system(size: 18, weight: .bold)).foregroundColor(.white).padding(10)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4))).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                            }.padding(.top, 50).padding(.leading, 16)
                        }
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, Color(white: 0.04).opacity(0.9)], startPoint: .top, endPoint: .bottom).frame(height: 40).allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottom) {
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { i in
                                    let active = i == (currentIndex % 5)
                                    Capsule()
                                        .fill(.white.opacity(active ? 0.8 : 0.2))
                                        .frame(width: active ? 20 : 6, height: 4)
                                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                                }
                            }.padding(.bottom, 16)
                        }
                        
                        if !vm.genres.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(uniqueGenres().prefix(12)) { g in
                                        NavigationLink(destination: GenreMovieView(genre: g)) {
                                            Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
                                                .font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.7))
                                                .padding(.horizontal, 14).padding(.vertical, 7).background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                                        }
                                    }
                                }.padding(.horizontal, 20)
                            }.padding(.vertical, 10)
                        }
                        
                        // Continue Watching
                        if !appState.watchProgressList.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.55)).frame(width: 3, height: 18)
                                    Text("Tiếp tục xem").font(.title3).fontWeight(.bold).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                                if uniqueProgressList().count <= 2 {
    HStack(spacing: 12) {
        ForEach(uniqueProgressList(), id: \.movieId) { prog in continueWatchingCard(prog) }
        Spacer()
    }
    .padding(.horizontal, 20)
} else {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(uniqueProgressList(), id: \.movieId) { prog in continueWatchingCard(prog) }
        }
        .padding(.horizontal, 20)
    }
}
                            }.padding(.top, 24)
                        }
                        
                        // Vì bạn đã xem
                        if let lastWatched = appState.watchHistory.first {
    SectionGrid(title: "Vì bạn đã xem \(lastWatched.title)", movies: vm.similarMovies)
}
                        
                        if let mod = vm.movieOfDay {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.55)).frame(width: 3, height: 18)
                                    Text("Movie of the Day").font(.title3).fontWeight(.bold).foregroundColor(.white)
                                }.padding(.horizontal, 20)
                                NavigationLink(destination: MovieDetailView(movie: mod)) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let url = mod.backdropURL {
                                            CachedAsyncImage(url: url, size: .backdrop).aspectRatio(16/9, contentMode: .fill).frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
                                        } else { RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.25)).frame(height: 180) }
                                        LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 16))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mod.title).font(.title3).fontWeight(.bold).foregroundColor(.white)
                                            if let genres = mod.genreIds {
                                                let names = genres.prefix(3).compactMap { id in uniqueGenres().first(where: { $0.id == id })?.name.replacingOccurrences(of: "Phim ", with: "") }
                                                if !names.isEmpty { Text(names.joined(separator: " • ")).font(.system(size: 11)).foregroundColor(.white.opacity(0.7)) }
                                            }
                                        }.padding()
                                    }.padding(.horizontal, 20)
                                }
                            }.padding(.top, 16)
                        }
                        
                        // Anime/Hoạt hình đang hot
if !vm.trendingAnime.isEmpty {
    VStack(alignment: .leading, spacing: 12) {
        NavigationLink(destination: MovieListView(title: "Hoạt hình - Anime", movies: vm.anime, fixedQuery: "Hoạt hình - Anime")) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.55)).frame(width: 3, height: 18)
                Text("Hoạt hình - Anime").font(.title3).fontWeight(.bold).foregroundColor(.white)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.5))
            }
        }
        .buttonStyle(.plain).padding(.horizontal, 20)
        
        TabView(selection: $animeCurrentIndex) {
            ForEach(Array(vm.trendingAnime.prefix(8).enumerated()), id: \.element.id) { i, movie in
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    ZStack(alignment: .bottomLeading) {
                        if let bgURL = movie.backdropURL {
                            CachedAsyncImage(url: bgURL, size: .backdrop)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.2)).frame(height: 200)
                        }
                        LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(movie.title).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(2)
                            HStack(spacing: 8) {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(.yellow)
                                    Text(movie.ratingText).font(.system(size: 10)).foregroundColor(.white.opacity(0.8))
                                }
                                if let year = movie.releaseDate?.prefix(4) {
                                    Text(String(year)).font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(16)
                        
                        // Dots trong banner
                        VStack {
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(0..<min(vm.trendingAnime.count, 8), id: \.self) { j in
                                    Capsule()
                                        .fill(.white.opacity(j == (animeCurrentIndex % min(vm.trendingAnime.count, 8)) ? 0.9 : 0.25))
                                        .frame(width: j == (animeCurrentIndex % min(vm.trendingAnime.count, 8)) ? 16 : 5, height: 3)
                                        .animation(.easeInOut(duration: 0.3), value: animeCurrentIndex)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }.tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 216)
        .onAppear { startAnimeAutoScroll() }.onDisappear { stopAnimeAutoScroll() }
    }
    .padding(.top, 24)
}
                        
                        SectionGrid(title: "TV Shows", movies: vm.trendingTV)
                        SectionGrid(title: "24h qua", movies: vm.trending24h)
                        SectionGrid(title: "Đang chiếu rạp", movies: vm.nowPlaying, showBooking: true)
                        HStack(spacing: 12) {
                            BigCard(title: "Phim Hot", icon: "flame.fill", movies: Array(vm.trending24h.shuffled()))
                            BigCard(title: "Phổ Biến", icon: "chart.line.uptrend.xyaxis", movies: Array(vm.trending24h.shuffled()))
                        }.padding(.horizontal, 20).padding(.top, 24)
                        SectionGrid(title: "Đánh giá cao", movies: vm.topRated)
                        SectionGrid(title: "Âu Mỹ", movies: vm.usuk)
                        SectionGrid(title: "Hàn Quốc", movies: vm.korean)
                        SectionGrid(title: "Nhật Bản", movies: vm.japanese)
                        SectionGrid(title: "Việt Nam", movies: vm.vietnamese)
                        SectionGrid(title: "Hoạt hình - Anime", movies: vm.anime)
                        Spacer().frame(height: 120)
                    }
                }
                
                if showMenu {
                    Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { closeMenu() }
                }
                
                HStack {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Khám phá").font(.title2).fontWeight(.bold).foregroundColor(.white).padding(.top, 60)
                                
                                HStack {
                                    Text("Thể loại").font(.headline).foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showGenrePopup = true }
                                    } label: {
                                        Text("Xem thêm").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                                            .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                                    }
                                }
                                if !vm.genres.isEmpty {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(uniqueGenres().prefix(8)) { genre in genreButton(genre) }
                                    }
                                }
                                Divider().background(Color.white.opacity(0.15))
                                
                                Text("Năm phát hành").font(.headline).foregroundColor(.white.opacity(0.6))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 6) {
                                        ForEach([2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010, 2005, 2000], id: \.self) { year in
                                            NavigationLink(destination: MovieListView(title: "Năm \(year)", movies: [], fixedQuery: "\(year)")) {
                                                Text("\(year)").font(.system(size: 12)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                                                    .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.4)))
                                            }
                                            .simultaneousGesture(TapGesture().onEnded { closeMenu() })
                                        }
                                    }
                                }.frame(height: 36)
                                
                                Divider().background(Color.white.opacity(0.15))
                                
                                Text("Quốc gia").font(.headline).foregroundColor(.white.opacity(0.6))
                                let countries: [(String, String)] = [("Âu Mỹ", "usuk"), ("Hàn Quốc", "korean"), ("Nhật Bản", "japanese"), ("Việt Nam", "vietnamese"), ("Trung Quốc", "china"), ("Ấn Độ", "india"), ("Thái Lan", "thailand"), ("Pháp", "france"), ("Anh", "uk"), ("Úc", "australia"), ("Mexico", "mexico"), ("Tây Ban Nha", "spain"), ("Brazil", "brazil"), ("Nga", "russia"), ("Đức", "germany"), ("Ý", "italy"), ("Canada", "canada"), ("Thụy Điển", "sweden")]
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(countries, id: \.0) { name, key in
                                        NavigationLink(destination: MovieListView(title: name, movies: [], fixedQuery: key)) {
                                            Text(name).font(.system(size: 12)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8).frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.4))).overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
                                        }
                                        .simultaneousGesture(TapGesture().onEnded { closeMenu() })
                                    }
                                }
                                Spacer().frame(height: 50)
                            }.padding(.horizontal, 20)
                        }
                        
                        VStack(spacing: 4) {
                            Divider().background(Color.white.opacity(0.1))
                            Text("© 2026 Emmew. All rights reserved.")
                                .font(.system(size: 9)).foregroundColor(.white.opacity(0.3))
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(width: 280)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 40, bottomTrailingRadius: 40, topTrailingRadius: 40, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.95))
                            .ignoresSafeArea()
                    )
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 40, bottomTrailingRadius: 40, topTrailingRadius: 40, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            .ignoresSafeArea()
                    )
                    .shadow(color: .white.opacity(0.08), radius: 15, x: 5, y: 0)
                    .offset(x: menuOffset)
                    Spacer()
                }.ignoresSafeArea()
                
                if showGenrePopup {
                    Color.black.opacity(0.5).ignoresSafeArea().onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showGenrePopup = false }
                    }
                    VStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 16) {
                            HStack {
                                Spacer().frame(width: 36)
                                Spacer()
                                Text("Tất cả thể loại").font(.headline).foregroundColor(.white)
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showGenrePopup = false }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.6))
                                }
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(uniqueGenres()) { genre in genreButton(genre) }
                            }
                        }.padding(20)
                        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.98)))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 0.5))
                        .padding(.horizontal, 12)
                        Spacer()
                    }
                }
            }
            .statusBarHidden(hideStatusBar)
            .animation(.easeOut(duration: 0.3), value: hideStatusBar)
            .ignoresSafeArea(edges: .top)
            .gesture(DragGesture().onChanged { v in
                if v.translation.width > 50 && !showMenu {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu = true; menuOffset = 0 }
                }
                if v.translation.width < -50 && showMenu {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu = false; menuOffset = -280 }
                }
            })
            .navigationDestination(isPresented: $showContinueDetail) {
                if let movie = detailMovie {
                    MovieDetailView(movie: movie)
                }
            }
        }
        .task { await vm.loadAll() }
    }
    
    // MARK: - Continue Watching Card
    func continueWatchingCard(_ prog: WatchProgress) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) {
                if let backdrop = backdropCache[prog.movieId] {
                    CachedAsyncImage(url: backdrop)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: 200, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    CachedAsyncImage(url: URL(string: prog.posterPath ?? ""))
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: 200, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onAppear {
                            Task { await fetchBackdrop(for: prog) }
                        }
                }
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 4)
                
                VStack {
                    Spacer()
                    
                    // "CÒN XX PHÚT" - trên bên trái, không background
                    HStack {
                        Text(formatRemaining(prog).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.8), radius: 3)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    
                    // Thanh tiến trình cao hơn
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.15))
                            .frame(height: 6)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.7))
                                    .frame(width: max(5, geo.size.width * CGFloat(prog.progress)), height: 6)
                            }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            }
            .frame(width: 200, height: 112)
            
            Text(prog.movieTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)
                .padding(.top, 6)
            
            if let ep = prog.episode {
                Text("Tiếp tục P\(prog.season ?? 1), T\(ep)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .frame(width: 200, alignment: .leading)
                    .padding(.top, 2)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            continueMovieId = prog.movieId; continueMovieTitle = prog.movieTitle
            continueMediaType = prog.mediaType; continueSeason = prog.season
            continueEpisode = prog.episode; continuePosterURL = URL(string: prog.posterPath ?? "")
            continueCurrentTime = prog.currentTime; presentContinuePlayer()
        }
        .contextMenu {
            Button {
                detailMovie = Movie(id: prog.movieId, title: prog.movieTitle, overview: "", posterPath: prog.posterPath, backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: prog.mediaType)
                showContinueDetail = true
            } label: { Label("Thông tin", systemImage: "info.circle") }
            
            Button {
                appState.watchProgressList.removeAll { $0.movieId == prog.movieId }; appState.save()
            } label: { Label("Xóa", systemImage: "trash") }
        }
    }
    
    func presentContinuePlayer() {
        guard let id = continueMovieId, let topVC = UIApplication.topViewController() else { return }
        let prog = appState.watchProgressList.first(where: { $0.movieId == id })
        let src: MovieSource
        if let source = prog?.source {
            src = source == "Emew 1" ? .phimapi : source == "Emew 2" ? .nguonc : source == "Emew 3" ? .vsmov : .phimapi
        } else { src = .phimapi }
        let moviePlayer = MoviePlayerView(movieId: id, movieTitle: continueMovieTitle, mediaType: continueMediaType, seasonNumber: continueSeason, episodeNumber: continueEpisode, posterURL: continuePosterURL, resumeTime: continueCurrentTime, initialSource: src).environmentObject(appState)
        let hosting = LandscapeHostingController(rootView: AnyView(moviePlayer))
        hosting.modalPresentationStyle = .fullScreen
        topVC.present(hosting, animated: true)
    }
    
    func formatRemaining(_ prog: WatchProgress) -> String {
        let remaining = max(prog.duration - prog.currentTime, 0)
        let mins = Int(remaining) / 60
        if remaining <= 0 { return "Đã xem hết" }
        if mins > 0 { return "Còn \(mins) phút" }
        return "Sắp hết"
    }
    
    func uniqueProgressList() -> [WatchProgress] {
        var seen = Set<Int>()
        return appState.watchProgressList.filter { prog in
            if seen.contains(prog.movieId) { return false }
            seen.insert(prog.movieId)
            return true
        }
    }
    func fetchBackdrop(for prog: WatchProgress) async {
        guard backdropCache[prog.movieId] == nil else { return }
        if prog.mediaType == "tv" {
            // TV Show - dùng TV endpoint
            let urlString = "https://api.themoviedb.org/3/tv/\(prog.movieId)?api_key=b6be36c1c5788565fec6a24811e7cc9b"
            if let url = URL(string: urlString), let (data, _) = try? await URLSession.shared.data(from: url) {
                struct TVDetail: Codable { let backdrop_path: String? }
                if let detail = try? JSONDecoder().decode(TVDetail.self, from: data), let path = detail.backdrop_path {
                    await MainActor.run {
                        backdropCache[prog.movieId] = URL(string: "https://image.tmdb.org/t/p/w500\(path)")
                    }
                }
            }
        } else {
            if let detail = try? await APIService.shared.movieDetail(movieId: prog.movieId) {
                if let backdropPath = detail.backdropPath {
                    let url = URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath)")
                    await MainActor.run {
                        backdropCache[prog.movieId] = url
                    }
                }
            }
        }
    }
    func backdropURL(for movieId: Int) -> URL? {
        if let movie = appState.watchHistory.first(where: { $0.id == movieId }), let backdrop = movie.backdropURL {
            return backdrop
        }
        return nil
    }
    func uniqueGenres() -> [Genre] {
        var seen = Set<String>()
        return vm.genres.filter { genre in
            let name = genre.name.replacingOccurrences(of: "Phim ", with: "")
            if seen.contains(name) { return false }; seen.insert(name); return true
        }
    }
    
    func genreButton(_ genre: Genre) -> some View {
        NavigationLink(destination: GenreMovieView(genre: genre)) {
            Text(genre.name.replacingOccurrences(of: "Phim ", with: ""))
                .font(.system(size: 12)).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 8).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.4)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
        }
        .simultaneousGesture(TapGesture().onEnded {
            closeMenu()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showGenrePopup = false }
        })
    }
    
    func closeMenu() { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu = false; menuOffset = -280 } }
    func startAutoScroll() { timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) { currentIndex = (currentIndex + 1) % 10 } } }
    func stopAutoScroll() { timer?.invalidate(); timer = nil }
    func startAnimeAutoScroll() { animeTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) { animeCurrentIndex = (animeCurrentIndex + 1) % min(vm.anime.count, 8) } } }
    func stopAnimeAutoScroll() { animeTimer?.invalidate(); animeTimer = nil }
}

struct SectionGrid: View {
    let title: String; let movies: [Movie]; var showBooking: Bool = false
    
    var isSpecialStyle: Bool {
        title == "TV Shows" || title == "24h qua" || title == "Đánh giá cao"
    }
    
    func subtitle(for movie: Movie) -> String? {
        if title == "TV Shows" {
            if let genreIds = movie.genreIds, let first = genreIds.first {
                let map: [Int: String] = [
                    28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy",
                    80: "Crime", 99: "Documentary", 18: "Drama", 10751: "Family",
                    14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music",
                    9648: "Mystery", 10749: "Romance", 878: "Sci-Fi", 10770: "TV Movie",
                    53: "Thriller", 10752: "War", 37: "Western"
                ]
                return map[first]
            }
            return nil
        } else {
            if let date = movie.releaseDate, date.count >= 4 {
                return String(date.prefix(4))
            }
            return movie.yearText
        }
    }
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(destination: MovieListView(title: title, movies: movies, fixedQuery: title)) {
                    HStack(spacing: 6) {
                        Text(title).font(.title3).fontWeight(.bold).foregroundColor(.white)
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.5))
                    }
                }
                .buttonStyle(.plain).padding(.horizontal, 20)
                
                if isSpecialStyle {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(Array(movies.prefix(8).enumerated()), id: \.element.id) { index, movie in
                                NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        // Poster ngang từ backdrop
                                        if let backdrop = movie.backdropURL {
                                            CachedAsyncImage(url: backdrop, size: .backdrop)
                                                .aspectRatio(16/9, contentMode: .fill)
                                                .frame(width: 200, height: 112)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .shadow(color: .black.opacity(0.3), radius: 3)
                                    
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.ultraThinMaterial.opacity(0.2))
                                                .frame(width: 200, height: 112)
                                        }
                                        
                                        // Số + Tên + Subtitle - canh giữa dọc với số
                                        HStack(alignment: .center, spacing: 8) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(movie.title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                
                                                if let sub = subtitle(for: movie) {
                                                    Text(sub)
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                            }
                                        }
                                        .frame(maxWidth: 200, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    // Style poster dọc cho các hàng khác
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 14) {
                            ForEach(movies.prefix(8)) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(width: 115, height: 172)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.3), radius: 3)
                                        Text(movie.title)
                                            .font(.system(size: 10))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .frame(width: 115, height: 26, alignment: .topLeading)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 24)
        }
    }
}

struct BigCard: View {
    let title: String; let icon: String; let movies: [Movie]
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).font(.headline).foregroundColor(.white)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) { ForEach(movies.prefix(4)) { movie in NavigationLink(destination: MovieDetailView(movie: movie)) { HStack(spacing: 10) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 50, height: 75).clipShape(RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading, spacing: 2) { Text(movie.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2); Text(movie.yearText).font(.system(size: 9)).foregroundColor(.gray) }; Spacer() } } } }
                }.frame(maxHeight: 200)
            }.padding(12).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }
}