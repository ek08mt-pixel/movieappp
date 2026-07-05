import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
    // Mỗi collection có query riêng để gọi API
    let collections: [(String, String)] = [
        ("Oscar", "oscar"),
        ("Cannes", "cannes"),
        ("IMDb Top", "top rated"),
        ("Netflix", "netflix"),
        ("Ghibli", "studio ghibli"),
        ("Marvel", "marvel"),
        ("DC", "dc comics"),
        ("Pixar", "pixar"),
        ("Disney", "disney"),
        ("A24", "a24"),
        ("Hàn Quốc", "korean"),
        ("Nhật Bản", "japanese"),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Khám phá")
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Nút Random + Mood + Timeline + Guess
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    do {
                                        let movies = try await APIService.shared.popular()
                                        if let movie = movies.filter({ !($0.adult ?? false) }).randomElement() {
                                            randomMovie = movie
                                            showRandom = true
                                        }
                                    } catch {}
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text("🎲").font(.system(size: 26))
                                    Text("Random").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: MoodPickerView()) {
                                VStack(spacing: 6) {
                                    Text("🎭").font(.system(size: 26))
                                    Text("Mood").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) {
                                    Text("📅").font(.system(size: 26))
                                    Text("Timeline").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: GuessMovieView()) {
                                VStack(spacing: 6) {
                                    Text("❓").font(.system(size: 26))
                                    Text("Guess").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Collections grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections, id: \.0) { title, query in
                                NavigationLink(destination: CollectionMovieView(title: title, query: query)) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.ultraThinMaterial)
                                            .frame(height: 100)
                                            .overlay(
                                                Image(systemName: iconFor(title))
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.white.opacity(0.3))
                                            )
                                        
                                        Text(title)
                                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                            .padding(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Staff Picks
                        if !staffMovies.isEmpty {
                            SectionWithSeeAll(title: "Staff Picks", movies: staffMovies, query: "best movies of all time")
                        }
                        
                        // Editor's Choice
                        if !editorMovies.isEmpty {
                            SectionWithSeeAll(title: "Editor's Choice", movies: editorMovies, query: "award winning films")
                        }
                        
                        // Hidden Gems
                        if !hiddenMovies.isEmpty {
                            SectionWithSeeAll(title: "Hidden Gems", movies: hiddenMovies, query: "underrated hidden gems")
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
            if let movie = randomMovie {
                NavigationStack {
                    MovieDetailView(movie: movie)
                        .overlay(alignment: .topTrailing) {
                            Button { showRandom = false } label: {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding()
                            }
                        }
                }
            }
        }
    }
    
    func iconFor(_ title: String) -> String {
        switch title {
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
        case "Hàn Quốc": return "globe.asia.australia.fill"
        case "Nhật Bản": return "globe.asia.australia.fill"
        default: return "film.fill"
        }
    }
}

// MARK: - Collection Movie View (gọi API search)
struct CollectionMovieView: View {
    let title: String
    let query: String
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(.white)
            } else if movies.isEmpty {
                Text("Không tìm thấy phim")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 4) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(height: 165)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(2).frame(maxWidth: 110)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                movies = try await APIService.shared.search(query: query)
            } catch {
                movies = []
            }
            isLoading = false
        }
    }
}

struct SectionWithSeeAll: View {
    let title: String; let movies: [Movie]; var query: String = ""
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: CollectionMovieView(title: title, query: query)) {
                        Text("See All").font(.caption).foregroundColor(.gray)
                    }
                }.padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(movies.prefix(15)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                CachedAsyncImage(url: movie.posterURL)
                                    .aspectRatio(2/3, contentMode: .fill)
                                    .frame(width: 105, height: 158)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}