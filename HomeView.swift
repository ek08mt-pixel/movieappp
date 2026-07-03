import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
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
                            // Hero Banner
                            TabView(selection: $currentIndex) {
                                ForEach(Array(vm.trending.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        ZStack(alignment: .bottomLeading) {
                                            AsyncImage(url: movie.backdropURL) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    Rectangle().fill(Color.gray.opacity(0.08))
                                                }
                                            }
                                            .frame(height: 450).clipped()
                                            
                                            LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(movie.title)
    .font(.system(size: 28, weight: .heavy))
    .foregroundColor(.white)
    .lineLimit(2)
    .padding(.trailing, 40)
                                                HStack {
                                                    Image(systemName: "star.fill").foregroundColor(.white.opacity(0.6)).font(.caption)
                                                    Text(movie.ratingText).foregroundColor(.white).font(.caption)
                                                }
                                            }
                                            .padding()
                                        }
                                    }
                                    .tag(i)
                                }
                            }
                            .tabViewStyle(.page)
                            .frame(height: 450)
                            
                            // Genre Row
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(10)) { g in
                                            Text(g.name)
                                                .font(.caption).fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding(.horizontal, 14).padding(.vertical, 7)
                                                .background(Capsule().fill(.ultraThinMaterial))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            // Section: Trending
                            MovieSection(title: "🔥 Xu hướng", movies: vm.trending)
                            
                            // Section: Now Playing
                            MovieSection(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying)
                            
                            // Section: Upcoming
                            MovieSection(title: "📅 Sắp chiếu", movies: vm.upcoming)
                            
                            // Section: Top Rated
                            MovieSection(title: "⭐ Đánh giá cao", movies: vm.topRated)
                            
                            Spacer().frame(height: 120)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
    }
}

// Section component
struct MovieSection: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 6) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 145, height: 218)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    
                                    Text(movie.title)
                                        .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                                        .lineLimit(1).frame(width: 145)
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.white.opacity(0.5))
                                        Text(movie.ratingText).font(.system(size: 10)).foregroundColor(.gray)
                                    }
                                }
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
