import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    
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
                                    ForEach(Array(vm.trending.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            ZStack {
                                                CachedAsyncImage(url: movie.backdropURL)
                                                    .frame(height: 450).clipped()
                                                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                                            }
                                        }
                                        .tag(i)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 450)
                                .animation(.easeInOut(duration: 0.4), value: currentIndex)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.trending.indices.contains(currentIndex) ? vm.trending[currentIndex].title : "")
                                        .font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                                        .lineLimit(2).frame(maxWidth: 280, alignment: .leading)
                                        .shadow(color: .black, radius: 6)
                                    HStack {
                                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                        Text(vm.trending.indices.contains(currentIndex) ? vm.trending[currentIndex].ratingText : "")
                                            .foregroundColor(.white).font(.caption).bold()
                                    }
                                }
                                .padding()
                            }
                            .overlay(alignment: .topTrailing) {
                                NavigationLink(destination: ProfileView()) {
                                    ZStack {
                                        Circle().fill(.thinMaterial).frame(width: 36, height: 36)
                                        Image(systemName: appState.selectedAvatar)
                                            .foregroundColor(.white.opacity(0.7)).font(.system(size: 16))
                                    }
                                    .shadow(color: .black.opacity(0.2), radius: 4)
                                }
                                .padding(.top, 50).padding(.trailing, 16)
                            }
                            
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(12)) { g in
                                            NavigationLink(destination: GenreMovieView(genre: g)) {
                                                Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
                                                    .font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.7))
                                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                                    .background(Capsule().fill(.ultraThinMaterial))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            SectionGrid(title: "🔥 Xu hướng", movies: vm.trending)
                            SectionGrid(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying, showBooking: true)
                            SectionGrid(title: "📅 Sắp chiếu", movies: vm.upcoming)
                            SectionGrid(title: "⭐ Đánh giá cao", movies: vm.topRated)
                            SectionGrid(title: "🎯 Phổ biến", movies: vm.popular)
                            SectionGrid(title: "🌍 Phim Âu Mỹ", movies: vm.usuk)
                            SectionGrid(title: "🎌 Phim Châu Á", movies: vm.asian)
                            
                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
    }
}

struct SectionGrid: View {
    let title: String
    let movies: [Movie]
    var showBooking: Bool = false
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: MovieListView(title: title, movies: movies)) {
                        Text("Xem tất cả").font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(165)), GridItem(.fixed(165))], spacing: 10) {
                        ForEach(movies.prefix(10)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                ZStack(alignment: .bottom) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(spacing: 2) {
                                        Text(movie.title).font(.system(size: 10)).fontWeight(.semibold).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 3) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(.horizontal, 6).padding(.vertical, 6).frame(width: 110)
                                    .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .frame(width: 110, height: 165)
                                .shadow(color: .black.opacity(0.3), radius: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 24)
        }
    }
}
