import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
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
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(CategoryConfig.allCategories) { category in
                                NavigationLink(destination: CategoryFullView(category: category)) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.ultraThinMaterial)
                                            .frame(height: 100)
                                            .overlay(
                                                Image(systemName: iconFor(category.name))
                                                    .font(.system(size: 30)).foregroundColor(.white.opacity(0.3))
                                            )
                                        Text(category.name).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                        
                        if !staffMovies.isEmpty { SectionWithSeeAll(title: "Staff Picks", movies: staffMovies, query: "best movies") }
                        if !editorMovies.isEmpty { SectionWithSeeAll(title: "Editor's Choice", movies: editorMovies, query: "award winning") }
                        if !hiddenMovies.isEmpty { SectionWithSeeAll(title: "Hidden Gems", movies: hiddenMovies, query: "underrated gems") }
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
    
    func iconFor(_ name: String) -> String {
        switch name {
        case "Oscar": return "trophy.fill"
        case "Cannes": return "sparkles"
        case "IMDb Top": return "star.fill"
        case "Netflix": return "play.rectangle.fill"
        case "Ghibli": return "leaf.fill"
        case "Marvel": return "shield.fill"
        case "DC": return "bolt.fill"
        case "Pixar": return "circle.fill"
        case "Disney": return "moon.stars.fill"
        case "A24": return "film.fill"
        default: return "globe.fill"
        }
    }
}

// MARK: - Category Full View (Load 100 phim)
struct CategoryFullView: View {
    let category: CategoryConfig
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading && movies.isEmpty { ProgressView().tint(.white) }
            else if movies.isEmpty { Text("Không tìm thấy phim").foregroundColor(.gray) }
            else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieGridCard(movie: movie)
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
        .navigationTitle(category.name).navigationBarTitleDisplayMode(.inline)
        .task {
            do { movies = try await fetchFullCategory() } catch { movies = [] }
            isLoading = false
        }
    }
    
    func fetchFullCategory() async throws -> [Movie] {
        var allMovies: [Movie] = []
        for page in 1...5 {
            let pageMovies: [Movie]
            switch category.type {
            case .studio:
                pageMovies = try await APIService.shared.discoverByStudio(studioId: category.tmdbId, page: page)
            case .keyword:
                pageMovies = try await APIService.shared.discoverByKeyword(keywordId: category.tmdbId)
            case .genre:
                if category.name == "Hàn Quốc" { pageMovies = try await APIService.shared.koreanMovies() }
                else { pageMovies = try await APIService.shared.japaneseMovies() }
            }
            allMovies.append(contentsOf: pageMovies)
            if pageMovies.count < 20 { break }
        }
        return allMovies
    }
}

// MARK: - Movie Grid Card (Đồng nhất kích thước)
struct MovieGridCard: View {
    let movie: Movie
    
    var body: some View {
        VStack(spacing: 4) {
            if let url = movie.posterURL {
                CachedAsyncImage(url: url)
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .overlay(Image(systemName: "film.fill").foregroundColor(.gray))
            }
            Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
            HStack(spacing: 2) {
                Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
            }
        }
    }
}

struct SectionWithSeeAll: View {
    let title: String; let movies: [Movie]; var query: String = ""
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white); Spacer() }
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) { ForEach(movies.prefix(15)) { movie in NavigationLink(destination: MovieDetailView(movie: movie)) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 105, height: 158).clipShape(RoundedRectangle(cornerRadius: 10)) } } }.padding(.horizontal)
                }
            }
        }
    }
}