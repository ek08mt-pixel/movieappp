import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?; @State private var showRandom = false
    @State private var staffMovies: [Movie] = []; @State private var editorMovies: [Movie] = []; @State private var hiddenMovies: [Movie] = []
    
    let collections: [(String, Int, CategoryConfig.CategoryType)] = [
        ("Oscar", 2959, .keyword), ("Cannes", 133278, .keyword), ("IMDb Top", 210024, .keyword),
        ("Netflix", 213, .studio), ("Ghibli", 103538, .studio), ("Marvel", 420, .studio),
        ("DC", 429, .studio), ("Pixar", 3, .studio), ("Disney", 2, .studio), ("A24", 135334, .studio)
    ]
    
    let posterMap: [String: String] = [
        "Oscar": "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", "Cannes": "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg",
        "IMDb Top": "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg", "Netflix": "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg",
        "Ghibli": "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", "Marvel": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
        "DC": "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", "Pixar": "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        "Disney": "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", "A24": "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Khám phá")
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                            .padding(.top, 8).padding(.horizontal, 16)
                        
                        HStack(spacing: 10) {
                            NavigationLink(destination: OSTView()) {
                                VStack(spacing: 6) { Text("🎵").font(.system(size: 26)); Text("OST").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: FilmHubView()) {
                                VStack(spacing: 6) { Text("🎬").font(.system(size: 26)); Text("Góc phim").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) { Text("📅").font(.system(size: 26)); Text("Timeline").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: GuessMovieView()) {
                                VStack(spacing: 6) { Text("❓").font(.system(size: 26)); Text("Guess").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                        }.padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(collections, id: \.0) { title, tmdbId, type in
                                NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: type, tmdbId: tmdbId))) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(height: 100)
                                        
                                        if let posterPath = posterMap[title], let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                                            CachedAsyncImage(url: url)
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                        
                                        LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                    .frame(height: 100)
                                }
                            }
                        }.padding(.horizontal, 16)
                        
                        if !staffMovies.isEmpty { movieRow(title: "Staff Picks", movies: staffMovies) }
                        if !editorMovies.isEmpty { movieRow(title: "Editor's Choice", movies: editorMovies) }
                        if !hiddenMovies.isEmpty { movieRow(title: "Hidden Gems", movies: hiddenMovies) }
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .task { loadData() }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie {
                NavigationStack {
                    MovieDetailView(movie: movie)
                        .overlay(alignment: .topTrailing) {
                            Button { showRandom = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding() }
                        }
                }
            }
        }
    }
    
    func loadData() {
        Task {
            staffMovies = (try? await APIService.shared.topRated())?.filter { !($0.adult ?? false) } ?? []
            editorMovies = (try? await APIService.shared.discoverMovies(minRating: 8.0, minVotes: 1000))?.filter { !($0.adult ?? false) } ?? []
            hiddenMovies = (try? await APIService.shared.discoverMovies(minRating: 7.0, minVotes: 30))?.filter { !($0.adult ?? false) } ?? []
        }
    }
    
    @ViewBuilder func movieRow(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(movies.prefix(20)) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            CachedAsyncImage(url: movie.posterURL)
                                .aspectRatio(2/3, contentMode: .fill)
                                .frame(width: 110, height: 165)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }.padding(.horizontal)
            }
        }
    }
}

// MARK: - Film Hub View (Góc phim)
struct FilmHubView: View {
    @Environment(\.dismiss) var dismiss
    
    let hubItems: [(String, String)] = [
        ("⭐", "Diễn viên hot"),
        ("🎬", "Đạo diễn tài ba"),
        ("🏆", "Phim đoạt giải"),
        ("📅", "Ngày này năm xưa"),
        ("👥", "Cặp bài trùng"),
        ("💬", "Quote huyền thoại"),
        ("🔗", "So sánh phim"),
        ("📊", "Top doanh thu"),
        ("🎪", "Vũ trụ điện ảnh"),
        ("🔥", "Trending hôm nay"),
    ]
    
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    Text("Góc phim")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                        .padding(.top, 60).padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(hubItems, id: \.1) { emoji, title in
                            NavigationLink(destination: hubDestination(for: title)) {
                                VStack(spacing: 8) {
                                    Text(emoji).font(.system(size: 36))
                                    Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    Text(hubSubtitle(for: title)).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 24)
                                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.25)))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer().frame(height: 120)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
            }
            .padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
    }
    
    func hubSubtitle(for title: String) -> String {
        switch title {
        case "Diễn viên hot": return "Ngôi sao đang được yêu thích"
        case "Đạo diễn tài ba": return "Nhà làm phim xuất sắc"
        case "Phim đoạt giải": return "Oscar, Cannes & more"
        case "Ngày này năm xưa": return "Phim công chiếu hôm nay"
        case "Cặp bài trùng": return "Bạn diễn ăn ý nhất"
        case "Quote huyền thoại": return "Câu thoại bất hủ"
        case "So sánh phim": return "Đối đầu điện ảnh"
        case "Top doanh thu": return "Phòng vé toàn cầu"
        case "Vũ trụ điện ảnh": return "MCU, DC, Star Wars..."
        case "Trending hôm nay": return "Phim & sao đang hot"
        default: return ""
        }
    }
    
    @ViewBuilder
    func hubDestination(for title: String) -> some View {
        switch title {
        case "Phim đoạt giải":
            CategoryFullView(category: CategoryConfig(id: 0, name: "Oscar Winners", posterName: "", type: .keyword, tmdbId: 2959))
        case "Top doanh thu":
            CategoryFullView(category: CategoryConfig(id: 0, name: "Top Revenue", posterName: "", type: .keyword, tmdbId: 210024))
        case "Vũ trụ điện ảnh":
            UniverseView()
        default:
            VStack(spacing: 20) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Đang phát triển")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

// MARK: - Universe View
struct UniverseView: View {
    @Environment(\.dismiss) var dismiss
    
    let universes: [(String, String, Int, CategoryConfig.CategoryType)] = [
        ("Marvel", "🦸", 420, .studio),
        ("DC", "🦇", 429, .studio),
        ("Star Wars", "⭐", 1, .studio),
        ("Harry Potter", "⚡", 174, .studio),
        ("Jurassic Park", "🦖", 56, .studio),
        ("Fast & Furious", "🏎️", 3325, .studio),
        ("James Bond", "🔫", 214, .studio),
        ("Transformers", "🤖", 248, .studio),
        ("Pirates of Caribbean", "🏴‍☠️", 285, .studio),
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    Text("Vũ trụ điện ảnh")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                        .padding(.top, 60).padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 10) {
                        ForEach(universes, id: \.0) { name, emoji, tmdbId, type in
                            NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: name, posterName: "", type: type, tmdbId: tmdbId))) {
                                HStack(spacing: 12) {
                                    Text(emoji).font(.system(size: 30))
                                    Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.25)))
                            }
                        }
                    }.padding(.horizontal, 16)
                    
                    Spacer().frame(height: 120)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
            }
            .padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - CategoryFullView (giữ nguyên)
struct CategoryFullView: View {
    let category: CategoryConfig
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            if isLoading && movies.isEmpty {
                ProgressView().tint(.white)
            } else if movies.isEmpty {
                Text("Không tìm thấy").foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom))
                                                .aspectRatio(2/3, contentMode: .fit)
                                        )
                                    Text(movie.title)
                                        .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                    }
                                }
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 90)
                    .padding(.bottom, 100)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
            }
            .padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .task {
            do { movies = try await APIService.shared.fetchMovies(by: category.tmdbId, type: category.type) } catch { movies = [] }
            isLoading = false
        }
    }
}