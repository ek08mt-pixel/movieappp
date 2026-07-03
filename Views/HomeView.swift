import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showAllTrending = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Banner
                        HeroBanner(movies: vm.trending)
                        
                        // Genre filter
                        GenreFilterRow(genres: vm.genres)
                        
                        // Trending
                        MovieSection(title: "🔥 Xu hướng", movies: vm.trending, style: .poster)
                        
                        // Now Playing
                        MovieSection(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying, style: .backdrop)
                        
                        // Upcoming
                        MovieSection(title: "📅 Sắp chiếu", movies: vm.upcoming, style: .poster)
                        
                        // Top Rated
                        MovieSection(title: "⭐ Xếp hạng cao", movies: vm.topRated, style: .poster)
                        
                        // Popular
                        MovieSection(title: "🎯 Phổ biến", movies: vm.popular, style: .backdrop)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationTitle("🍿 Phim Hay")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .task {
            await vm.loadAll()
        }
    }
}

struct GenreFilterRow: View {
    let genres: [Genre]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(genres) { genre in
                    Text(genre.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
}
