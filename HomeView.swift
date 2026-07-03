import SwiftUI

// MARK: - HomeView
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
                            // Hero Banner + Avatar
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
                                                
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(movie.title)
                                                        .font(.system(size: 28, weight: .heavy))
                                                        .foregroundColor(.white)
                                                        .lineLimit(2)
                                                        .frame(maxWidth: 280, alignment: .leading)
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
                            
                            // Genres
                            if !vm.genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(vm.genres.prefix(10)) { g in
                                            Text(g.name.replacingOccurrences(of: "Phim ", with: ""))
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
                            
                            // Sections
                            SectionRow(title: "🔥 Xu hướng", movies: vm.trending)
                            SectionRow(title: "🎬 Đang chiếu rạp", movies: vm.nowPlaying)
                            SectionRow(title: "📅 Sắp chiếu", movies: vm.upcoming)
                            SectionRow(title: "⭐ Đánh giá cao", movies: vm.topRated)
                            
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

// MARK: - SectionRow
struct SectionRow: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(165)), GridItem(.fixed(165))], spacing: 12) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 5) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 110, height: 165)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(1).frame(width: 110)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
        }
    }
}
