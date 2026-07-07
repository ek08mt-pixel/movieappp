import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var timer: Timer?
    
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
                    VStack(spacing: 0) {
                        // Banner Hero
                        TabView(selection: $currentIndex) {
                            ForEach(Array(vm.trending24h.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    ZStack {
                                        if let bgURL = movie.backdropURL {
                                            CachedAsyncImage(url: bgURL)
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 480)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .blur(radius: 50)
                                                .overlay(Color.black.opacity(0.25))
                                                .mask(
                                                    LinearGradient(
                                                        colors: [.black, .black, .clear],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                        } else {
                                            Rectangle()
                                                .fill(.ultraThinMaterial.opacity(0.15))
                                                .frame(height: 480)
                                        }
                                        
                                        VStack(spacing: 0) {
                                            Spacer()
                                            
                                            if let posterURL = movie.posterURL {
                                                CachedAsyncImage(url: posterURL)
                                                    .aspectRatio(2/3, contentMode: .fit)
                                                    .frame(height: 320)
                                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                                    .shadow(color: .white.opacity(0.1), radius: 10, y: -5)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 24)
                                                            .stroke(.white.opacity(0.15), lineWidth: 1.5)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 24)
                                                            .fill(.ultraThinMaterial.opacity(0.05))
                                                    )
                                            }
                                            
                                            Spacer().frame(height: 14)
                                            
                                            Text(movie.title)
                                                .font(.system(size: 24, weight: .bold, design: .serif))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .shadow(color: .black.opacity(0.9), radius: 8)
                                                .padding(.horizontal, 24)
                                            
                                            Spacer().frame(height: 6)
                                            
                                            if let genres = movie.genreIds {
                                                let names = genres.prefix(3).compactMap { id in
                                                    vm.genres.first(where: { $0.id == id })?.name.replacingOccurrences(of: "Phim ", with: "")
                                                }
                                                if !names.isEmpty {
                                                    Text(names.joined(separator: " • "))
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                            }
                                            
                                            Spacer().frame(height: 10)
                                            
                                            // Dots với hiệu ứng liquid glass bong bóng
                                            HStack(spacing: 10) {
                                                ForEach(0..<min(vm.trending24h.count, 5), id: \.self) { i in
                                                    Capsule()
                                                        .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                                                        .frame(width: i == currentIndex ? 24 : 8, height: 8)
                                                        .background(
                                                            Capsule()
                                                                .fill(.ultraThinMaterial.opacity(i == currentIndex ? 0.6 : 0.2))
                                                                .blur(radius: 2)
                                                        )
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(.white.opacity(i == currentIndex ? 0.5 : 0.1), lineWidth: 0.5)
                                                        )
                                                        .shadow(color: .white.opacity(i == currentIndex ? 0.3 : 0), radius: 4)
                                                        .scaleEffect(i == currentIndex ? 1.2 : 1)
                                                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3), value: currentIndex)
                                                }
                                            }
                                            
                                            Spacer().frame(height: 8)
                                        }
                                    }
                                }.tag(i)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 480)
                        .onAppear { startAutoScroll() }
                        .onDisappear { stopAutoScroll() }
                        .overlay(alignment: .topTrailing) {
                            HStack(spacing: 12) {
                                Button { if !vm.trending24h.isEmpty { randomMovie = vm.trending24h.randomElement(); showRandom = true } } label: {
                                    ZStack { Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36); Text("🎲").font(.system(size: 18)) }
                                }
                                NavigationLink(destination: ProfileView()) {
                                    ZStack { Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36); Image(systemName: appState.selectedAvatar).foregroundColor(.white.opacity(0.7)).font(.system(size: 16)) }
                                }
                            }.padding(.top, 50).padding(.trailing, 16)
                        }
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, Color(white: 0.04).opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                .frame(height: 40).allowsHitTesting(false)
                        }
                        
                        // Genres
                        if !vm.genres.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(vm.genres.prefix(12)) { g in
                                        NavigationLink(destination: GenreMovieView(genre: g)) {
                                            Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
                                                .font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.7))
                                                .padding(.horizontal, 14).padding(.vertical, 7)
                                                .background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                                        }
                                    }
                                }.padding(.horizontal, 20)
                            }.padding(.vertical, 10)
                        }
                        
                        // Movie of the Day
                        if let mod = vm.movieOfDay {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Movie of the Day").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 20)
                                NavigationLink(destination: MovieDetailView(movie: mod)) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let url = mod.backdropURL {
                                            CachedAsyncImage(url: url)
                                                .aspectRatio(16/9, contentMode: .fill)
                                                .frame(height: 180)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial.opacity(0.25))
                                                .frame(height: 180)
                                        }
                                        LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mod.title).font(.title3).fontWeight(.bold).foregroundColor(.white)
                                            if let genres = mod.genreIds {
                                                let names = genres.prefix(3).compactMap { id in
                                                    vm.genres.first(where: { $0.id == id })?.name.replacingOccurrences(of: "Phim ", with: "")
                                                }
                                                if !names.isEmpty {
                                                    Text(names.joined(separator: " • "))
                                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                        }.padding()
                                    }.padding(.horizontal, 20)
                                }
                            }.padding(.top, 16)
                        }
                        
                        if !appState.watchHistory.isEmpty { SectionGrid(title: "Tiếp tục khám phá", movies: appState.watchHistory) }
                        if let last = appState.watchHistory.last { SectionGrid(title: "Vì bạn đã xem \(last.title)", movies: vm.trending24h.shuffled()) }
                        
                        SectionGrid(title: "TV Shows", movies: vm.trendingTV)
                        SectionGrid(title: "24h qua", movies: vm.trending24h)
                        SectionGrid(title: "Đang chiếu rạp", movies: vm.nowPlaying, showBooking: true)
                        
                        HStack(spacing: 12) {
                            BigCard(title: "Phim Hot", icon: "flame.fill", movies: Array(vm.trending24h.shuffled()))
                            BigCard(title: "Phổ Biến", icon: "chart.line.uptrend.xyaxis", movies: Array(vm.trending24h.shuffled()))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        SectionGrid(title: "Đánh giá cao", movies: vm.topRated)
                        SectionGrid(title: "Âu Mỹ", movies: vm.usuk)
                        SectionGrid(title: "Hàn Quốc", movies: vm.korean)
                        SectionGrid(title: "Nhật Bản", movies: vm.japanese)
                        SectionGrid(title: "Việt Nam", movies: vm.vietnamese)
                        SectionGrid(title: "Anime", movies: vm.anime)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie {
                MovieDetailView(movie: movie)
                    .overlay(alignment: .topTrailing) {
                        Button { showRandom = false } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding()
                        }
                    }
            }
        }
    }
    
    func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75, blendDuration: 0.4)) {
                currentIndex = (currentIndex + 1) % min(vm.trending24h.count, 5)
            }
        }
    }
    
    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
}

struct SectionGrid: View {
    let title: String; let movies: [Movie]; var showBooking: Bool = false
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title).font(.title3).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: MovieListView(title: title, movies: movies, fixedQuery: title)) {
                        Text("Xem tất cả").font(.caption).foregroundColor(.gray)
                    }
                }.padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(movies.prefix(10)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(width: 115, height: 172)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.3), radius: 3)
                                    Text(movie.title).font(.system(size: 10)).fontWeight(.semibold).foregroundColor(.white).lineLimit(2).frame(width: 115, alignment: .leading)
                                }
                            }
                        }
                    }.padding(.horizontal, 20)
                }
            }.padding(.top, 24)
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
                    LazyVStack(spacing: 8) {
                        ForEach(movies.prefix(5)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                HStack(spacing: 10) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(width: 50, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(movie.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        Text(movie.yearText).font(.system(size: 9)).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.2)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }
}