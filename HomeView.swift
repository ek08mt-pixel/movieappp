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
                            ZStack(alignment: .topTrailing) {
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
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(movie.title)
                                                        .font(.system(size: 24, weight: .heavy))
                                                        .foregroundColor(.white)
                                                        .lineLimit(2)
                                                        .frame(maxWidth: 250, alignment: .leading)
                                                        .shadow(color: .black.opacity(0.8), radius: 4)
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                                        Text(movie.ratingText).foregroundColor(.white).font(.caption).bold()
                                                    }
                                                }
                                                .padding()
                                            }
                                        }
                                        .tag(i)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 450)
                                .animation(.easeInOut(duration: 0.4), value: currentIndex)
                                
                                // Avatar
                                NavigationLink(destination: ProfileView()) {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white.opacity(0.8))
                                                .font(.system(size: 18))
                                        )
                                }
                                .padding(.top, 50).padding(.trailing, 20)
                            }
                            
                            // Genres - bấm được
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(10)) { g in
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
                            SectionRow(title: "🔥 Xu hướng", movies: vm.trending)
                            SectionRow(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying)
                            SectionRow(title: "📅 Sắp chiếu", movies: vm.upcoming)
                            SectionRow(title: "⭐ Đánh giá cao", movies: vm.topRated)
                            SectionRow(title: "🎯 Phổ biến", movies: vm.popular)
                            
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

struct SectionRow: View {
    let title: String
    let movies: [Movie]
    
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
                    LazyHStack(spacing: 12) {
                        ForEach(movies.prefix(10)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 5) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 120, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                                    
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(2).frame(width: 120, alignment: .leading)
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                    }
                                    .frame(width: 120, alignment: .leading)
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
