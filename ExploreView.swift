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
                            .padding(.top, 60).padding(.horizontal, 16)
                        
                        HStack(spacing: 10) {
                            Button {
                                Task {
                                    let m = try? await APIService.shared.popular()
                                    if let movie = m?.filter({ !($0.adult ?? false) }).randomElement() { randomMovie = movie; showRandom = true }
                                }
                            } label: {
                                VStack(spacing: 6) { Text("🎲").font(.system(size: 26)); Text("Random").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: MoodPickerView()) {
                                VStack(spacing: 6) { Text("🎭").font(.system(size: 26)); Text("Mood").font(.system(size: 10)).foregroundColor(.white) }
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
                        
                        // 10 ô danh mục - aspectRatio cố định 16:9
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(collections, id: \.0) { title, tmdbId, type in
                                NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: type, tmdbId: tmdbId))) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let posterPath = posterMap[title], let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                                            CachedAsyncImage(url: url)
                                                .aspectRatio(16/9, contentMode: .fill)
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        } else {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: 100)
                                                .overlay(
                                                    Text(title)
                                                        .font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.7))
                                                )
                                        }
                                        // Overlay gradient + text
                                        LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
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