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
                            ZStack(alignment: .bottomLeading) {
                                TabView(selection: $currentIndex) {
                                    ForEach(Array(vm.trending.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            ZStack {
                                                AsyncImage(url: movie.backdropURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Rectangle().fill(Color.gray.opacity(0.08))
                                                    }
                                                }
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
                                
                                // Tên phim + rating dưới cùng
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.trending.indices.contains(currentIndex) ? vm.trending[currentIndex].title : "")
                                        .font(.system(size: 28, weight: .heavy))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .frame(maxWidth: 280, alignment: .leading)
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
                                    Circle()
                                        .fill(.regularMaterial.opacity(0.3))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.system(size: 16))
                                        )
                                }
                                .padding(.top, 50).padding(.trailing, 16)
                            }
                            
                            // Genres
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(12)) { g in
                                            NavigationLink(destination: GenreMovieView(genre: g)) {
                                                Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
                                                    .font(.caption).fontWeight(.medium)
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                                    .background(Capsule().fill(.ultraThinMaterial))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            // Sections
                            SectionGrid(title: "🔥 Xu hướng", movies: vm.trending)
                            SectionGrid(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying, showBooking: true)
                            SectionGrid(title: "📅 Sắp chiếu", movies: vm.upcoming)
                            SectionGrid(title: "⭐ Đánh giá cao", movies: vm.topRated)
                            SectionGrid(title: "🎯 Phổ biến", movies: vm.popular)
                            
                            if !vm.trending.isEmpty {
                                SectionGrid(title: "🎭 Phim hành động", movies: Array(vm.trending.shuffled().prefix(10)))
                                SectionGrid(title: "🌍 Phim Âu Mỹ", movies: Array(vm.trending.shuffled().prefix(8)))
                                SectionGrid(title: "🎌 Phim Châu Á", movies: Array(vm.trending.shuffled().prefix(8)))
                            }
                            
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
                    Text(title)
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: MovieListView(title: title, movies: movies)) {
                        Text("Xem tất cả").font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [
                        GridItem(.fixed(165)),
                        GridItem(.fixed(165))
                    ], spacing: 10) {
                        ForEach(movies.prefix(10)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie, showBooking: showBooking)) {
                                VStack(spacing: 4) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 110, height: 165)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.3), radius: 3)
                                    
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(2).frame(width: 110, alignment: .leading)
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                    }
                                    .frame(width: 110, alignment: .leading)
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
