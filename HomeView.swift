import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var timer: Timer?
    @State private var showMenu = false
    @State private var menuOffset: CGFloat = -280
    @State private var showGenrePopup = false
    
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
                            LinearGradient(colors: [.clear, Color(white: 0.04).opacity(0.9)], startPoint: .top, endPoint: .bottom).frame(height: 40).allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottom) {
                            HStack(spacing: 12) {
                                ForEach(0..<5, id: \.self) { i in
                                    let active = i == (currentIndex % 5)
                                    ZStack {
                                        Circle().fill(.white.opacity(active ? 0.05 : 0.02)).frame(width: 10, height: 10)
                                        Circle().stroke(.white.opacity(active ? 0.3 : 0.1), lineWidth: 0.5).frame(width: 10, height: 10)
                                        if active {
                                            Circle().fill(.white.opacity(0.6)).frame(width: 3, height: 3).offset(x: -2, y: -2).blur(radius: 0.5)
                                            Circle().stroke(LinearGradient(colors: [.clear, .white.opacity(0.4), .purple.opacity(0.15), .cyan.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8).frame(width: 10, height: 10)
                                        }
                                    }.shadow(color: .white.opacity(active ? 0.3 : 0), radius: 4).scaleEffect(active ? 1.2 : 1)
                                    .animation(.interpolatingSpring(stiffness: 200, damping: 12), value: currentIndex)
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
                        
                        if let mod = vm.movieOfDay {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Movie of the Day").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 20)
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
                        
                        if !appState.watchHistory.isEmpty { SectionGrid(title: "Tiếp tục khám phá", movies: appState.watchHistory) }
                        if let last = appState.watchHistory.last { SectionGrid(title: "Vì bạn đã xem \(last.title)", movies: vm.trending24h) }
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
                        SectionGrid(title: "Anime", movies: vm.anime)
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
                                            Button { closeMenu() } label: {
                                                Text("\(year)").font(.system(size: 12)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                                                    .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.4)))
                                            }
                                        }
                                    }
                                }.frame(height: 36)
                                
                                Divider().background(Color.white.opacity(0.15))
                                
                                Text("Quốc gia").font(.headline).foregroundColor(.white.opacity(0.6))
                                let countries: [(String, String)] = [("Âu Mỹ", "usuk"), ("Hàn Quốc", "korean"), ("Nhật Bản", "japanese"), ("Việt Nam", "vietnamese"), ("Trung Quốc", "china"), ("Ấn Độ", "india"), ("Thái Lan", "thailand"), ("Pháp", "france"), ("Anh", "uk"), ("Úc", "australia"), ("Mexico", "mexico"), ("Tây Ban Nha", "spain"), ("Brazil", "brazil"), ("Nga", "russia"), ("Đức", "germany"), ("Ý", "italy"), ("Canada", "canada"), ("Thụy Điển", "sweden")]
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(countries, id: \.0) { name, _ in
                                        Button { closeMenu() } label: {
                                            Text(name).font(.system(size: 12)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8).frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.4))).overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
                                        }
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
            .ignoresSafeArea(edges: .top)
            .gesture(DragGesture().onChanged { v in
                if v.translation.width > 50 && !showMenu {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu = true; menuOffset = 0 }
                }
                if v.translation.width < -50 && showMenu {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMenu = false; menuOffset = -280 }
                }
            })
        }
        .task { await vm.loadAll() }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie {
                MovieDetailView(movie: movie)
                    .overlay(alignment: .topTrailing) { Button { showRandom = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding() } }
            }
        }
    }
    
    func uniqueGenres() -> [Genre] {
        var seen = Set<String>()
        return vm.genres.filter { genre in
            let name = genre.name.replacingOccurrences(of: "Phim ", with: "")
            if seen.contains(name) { return false }
            seen.insert(name)
            return true
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
}

struct SectionGrid: View {
    let title: String; let movies: [Movie]; var showBooking: Bool = false
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text(title).font(.title3).fontWeight(.bold).foregroundColor(.white); Spacer(); NavigationLink(destination: MovieListView(title: title, movies: movies, fixedQuery: title)) { Text("Xem tất cả").font(.caption).foregroundColor(.gray) } }.padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(movies.prefix(10)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 115, height: 172).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.3), radius: 3)
                                    Text(movie.title).font(.system(size: 10)).fontWeight(.semibold).foregroundColor(.white).lineLimit(2).frame(width: 115, alignment: .leading)
                                }
                            }
                        }
                    }.padding(.horizontal, 20).drawingGroup()
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
                    LazyVStack(spacing: 8) { ForEach(movies.prefix(5)) { movie in NavigationLink(destination: MovieDetailView(movie: movie)) { HStack(spacing: 10) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 50, height: 75).clipShape(RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading, spacing: 2) { Text(movie.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2); Text(movie.yearText).font(.system(size: 9)).foregroundColor(.gray) }; Spacer() } } } }
                }.frame(maxHeight: 200)
            }.padding(12).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }
}