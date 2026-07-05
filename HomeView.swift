import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottomLeading) {
                                TabView(selection: $currentIndex) {
                                    ForEach(Array(vm.trending24h.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            CachedAsyncImage(url: movie.backdropURL)
                                                .aspectRatio(16/9, contentMode: .fill)
                                                .frame(height: 450).clipped()
                                                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom))
                                        }.tag(i)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 450)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.trending24h.indices.contains(currentIndex) ? vm.trending24h[currentIndex].title : "")
                                        .font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                                        .lineLimit(2).frame(maxWidth: 280, alignment: .leading).shadow(color: .black, radius: 6)
                                    HStack {
                                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                        Text(vm.trending24h.indices.contains(currentIndex) ? vm.trending24h[currentIndex].ratingText : "")
                                            .foregroundColor(.white).font(.caption).bold()
                                    }
                                }.padding()
                            }
                            .overlay(alignment: .topTrailing) {
                                HStack(spacing: 12) {
                                    Button {
                                        if !vm.trending24h.isEmpty {
                                            randomMovie = vm.trending24h.randomElement()
                                            showRandom = true
                                        }
                                    } label: {
                                        ZStack { Circle().fill(.thinMaterial).frame(width: 36, height: 36); Text("🎲").font(.system(size: 18)) }
                                    }
                                    NavigationLink(destination: ProfileView()) {
                                        ZStack { Circle().fill(.thinMaterial).frame(width: 36, height: 36); Image(systemName: appState.selectedAvatar).foregroundColor(.white.opacity(0.7)).font(.system(size: 16)) }
                                    }
                                }.padding(.top, 50).padding(.trailing, 16)
                            }
                            
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(12)) { g in
                                            NavigationLink(destination: GenreMovieView(genre: g)) {
                                                Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
                                                    .font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.7))
                                                    .padding(.horizontal, 14).padding(.vertical, 7).background(Capsule().fill(.ultraThinMaterial))
                                            }
                                        }
                                    }.padding(.horizontal, 20)
                                }.padding(.vertical, 12)
                            }
                            
                            if let mod = vm.movieOfDay {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Movie of the Day").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 20)
                                    NavigationLink(destination: MovieDetailView(movie: mod)) {
                                        ZStack(alignment: .bottomLeading) {
                                            CachedAsyncImage(url: mod.backdropURL).aspectRatio(16/9, contentMode: .fill).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                                            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 16))
                                            VStack(alignment: .leading, spacing: 4) { Text(mod.title).font(.title3).fontWeight(.bold).foregroundColor(.white); Text(mod.overview).font(.caption).foregroundColor(.gray).lineLimit(2) }.padding()
                                        }.padding(.horizontal, 20)
                                    }
                                }.padding(.top, 24)
                            }
                            
                            if !appState.watchHistory.isEmpty { SectionGrid(title: "Tiếp tục khám phá", movies: appState.watchHistory) }
                            if let last = appState.watchHistory.last { SectionGrid(title: "Vì bạn đã xem \(last.title)", movies: vm.trending24h.shuffled()) }
                            
                            SectionGrid(title: "TV Shows", movies: vm.trendingTV)
                            SectionGrid(title: "24h qua", movies: vm.trending24h)
                            SectionGrid(title: "Đang chiếu rạp", movies: vm.nowPlaying, showBooking: true)
                            SectionGrid(title: "Sắp chiếu", movies: vm.upcoming)
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
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie {
                NavigationStack {
                    MovieDetailView(movie: movie)
                        .overlay(alignment: .topTrailing) {
                            Button { showRandom = false } label: {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding()
                            }
                        }
                }
            }
        }
    }
}

struct SectionGrid: View {
    let title: String; let movies: [Movie]; var showBooking: Bool = false
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title).font(.title3).fontWeight(.bold).foregroundColor(.white); Spacer()
                    NavigationLink(destination: MovieListView(title: title, movies: movies, fixedQuery: title)) { Text("Xem tất cả").font(.caption).foregroundColor(.gray) }
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
                                    HStack(spacing: 3) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray) }
                                }.frame(width: 115)
                            }
                        }
                    }.padding(.horizontal, 20)
                }
            }.padding(.top, 24)
        }
    }
}