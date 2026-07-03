import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeroHeader(movies: vm.trending)
                    
                    VStack(spacing: 28) {
                        GenreRow(genres: vm.genres)
                        
                        PosterSection(title: "🔥 Xu hướng", movies: vm.trending)
                        BackdropSection(title: "🎬 Đang chiếu", movies: vm.nowPlaying)
                        PosterSection(title: "📅 Sắp chiếu", movies: vm.upcoming)
                        PosterSection(title: "⭐ Đánh giá cao", movies: vm.topRated)
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color.black)
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
    }
}

struct HeroHeader: View {
    let movies: [Movie]
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(movies.prefix(5).enumerated()), id: \.element.id) { i, movie in
                ZStack(alignment: .bottom) {
                    AsyncImage(url: movie.backdropURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.15))
                        }
                    }
                    .frame(height: 520)
                    .clipped()
                    
                    LinearGradient(
                        stops: [.init(color: .clear, location: 0.4), .init(color: .black, location: 0.95)],
                        startPoint: .top, endPoint: .bottom
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                            Text(movie.ratingText).foregroundColor(.white).font(.caption).bold()
                            Text("•").foregroundColor(.gray)
                            Text(movie.yearText).foregroundColor(.gray).font(.caption)
                            Text("•").foregroundColor(.gray)
                            Text("Phim lẻ").foregroundColor(.gray).font(.caption)
                        }
                        
                        Text(movie.title)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text(movie.overview)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Xem Trailer")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 22).padding(.vertical, 11)
                                .background(Color.orange)
                                .clipShape(Capsule())
                            }
                            
                            Button {} label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Thư viện")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22).padding(.vertical, 11)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 24)
                }
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 520)
        .overlay(alignment: .bottom) {
            HStack(spacing: 6) {
                ForEach(0..<min(movies.count, 5), id: \.self) { i in
                    Capsule()
                        .fill(i == currentIndex ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: i == currentIndex ? 20 : 6, height: 6)
                        .animation(.spring(), value: currentIndex)
                }
            }
            .padding(.vertical, 8).padding(.horizontal, 16)
            .background(Capsule().fill(.ultraThinMaterial))
            .offset(y: -10)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) { currentIndex = (currentIndex + 1) % min(movies.count, 5) }
        }
    }
}

struct GenreRow: View {
    let genres: [Genre]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(genres.prefix(8)) { g in
                    Text(g.name)
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.08)).overlay(Capsule().stroke(Color.white.opacity(0.1))))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct PosterSection: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.1))
                                        }
                                    }
                                    .frame(width: 145, height: 218)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: .black.opacity(0.4), radius: 5, y: 2)
                                    
                                    Text(movie.title).font(.caption).fontWeight(.semibold).foregroundColor(.white).lineLimit(1).frame(width: 145)
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 10)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct BackdropSection: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    AsyncImage(url: movie.backdropURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.1))
                                        }
                                    }
                                    .frame(width: 260, height: 146)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: .black.opacity(0.4), radius: 5, y: 2)
                                    
                                    Text(movie.title).font(.caption).fontWeight(.semibold).foregroundColor(.white).lineLimit(1).frame(width: 260)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
