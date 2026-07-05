import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
    // 10 ô (bỏ Hàn Quốc, Nhật Bản)
    let collections: [(String, String, Int?, CategoryConfig.CategoryType)] = [
        ("Oscar", "oscar", 2959, .keyword),
        ("Cannes", "cannes", 133278, .keyword),
        ("IMDb Top", "imdb top", 210024, .keyword),
        ("Netflix", "netflix", 213, .studio),
        ("Ghibli", "studio ghibli", 103538, .studio),
        ("Marvel", "marvel", 420, .studio),
        ("DC", "dc comics", 429, .studio),
        ("Pixar", "pixar", 3, .studio),
        ("Disney", "disney", 2, .studio),
        ("A24", "a24", 135334, .studio),
    ]
    
    func posterFor(_ name: String) -> String {
        switch name {
        case "Oscar": return "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"
        case "Cannes": return "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg"
        case "IMDb Top": return "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg"
        case "Netflix": return "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg"
        case "Ghibli": return "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg"
        case "Marvel": return "/or06FN3Dka5tukK1e9sl16pB3iy.jpg"
        case "DC": return "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg"
        case "Pixar": return "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"
        case "Disney": return "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg"
        case "A24": return "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"
        default: return "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Khám phá").font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    let m = try? await APIService.shared.popular()
                                    if let movie = m?.filter({ !($0.adult ?? false) }).randomElement() { randomMovie = movie; showRandom = true }
                                }
                            } label: {
                                VStack(spacing: 6) { Text("🎲").font(.system(size: 26)); Text("Random").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: MoodPickerView()) {
                                VStack(spacing: 6) { Text("🎭").font(.system(size: 26)); Text("Mood").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) { Text("📅").font(.system(size: 26)); Text("Timeline").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: GuessMovieView()) {
                                VStack(spacing: 6) { Text("❓").font(.system(size: 26)); Text("Guess").font(.system(size: 10)).foregroundColor(.white) }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                        }.padding(.horizontal)
                        
                        // 10 ô
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections, id: \.0) { title, query, tmdbId, type in
                                NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: type, tmdbId: tmdbId ?? 0))) {
                                    ZStack(alignment: .bottomLeading) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterFor(title))"))
                                            .aspectRatio(contentMode: .fill).frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                        
                        // Staff Picks - Top Rated
                        if !staffMovies.isEmpty {
                            SectionWithSeeAll(title: "Staff Picks", movies: staffMovies, query: "top rated best movies")
                        }
                        
                        // Editor's Choice - Award Winning
                        if !editorMovies.isEmpty {
                            SectionWithSeeAll(title: "Editor's Choice", movies: editorMovies, query: "award winning critic choice")
                        }
                        
                        // Hidden Gems - Underrated
                        if !hiddenMovies.isEmpty {
                            SectionWithSeeAll(title: "Hidden Gems", movies: hiddenMovies, query: "underrated hidden masterpiece")
                        }
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .task {
            staffMovies = (try? await APIService.shared.topRated())?.filter { !($0.adult ?? false) } ?? []
            editorMovies = (try? await APIService.shared.discoverMovies(minRating: 8.0, minVotes: 1000))?.filter { !($0.adult ?? false) } ?? []
            hiddenMovies = (try? await APIService.shared.discoverMovies(minRating: 7.0, minVotes: 30))?.filter { !($0.adult ?? false) } ?? []
        }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie { NavigationStack { MovieDetailView(movie: movie).overlay(alignment: .topTrailing) { Button { showRandom = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding() } } } }
        }
    }
}

// MARK: - Section With See All (load 100+ phim)
struct SectionWithSeeAll: View {
    let title: String; let movies: [Movie]; var query: String = ""
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: .keyword, tmdbId: 0))) {
                        Text("See All").font(.caption).foregroundColor(.gray)
                    }
                }.padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(movies.prefix(15)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                CachedAsyncImage(url: movie.posterURL)
                                    .aspectRatio(2/3, contentMode: .fill).frame(width: 105, height: 158).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}