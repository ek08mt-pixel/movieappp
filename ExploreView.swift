import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
    let collections: [(String, String, Int)] = [
        ("Oscar", "oscar winner", 0),
        ("Cannes", "cannes film festival", 0),
        ("IMDb Top", "imdb top", 0),
        ("Netflix", "netflix", 0),
        ("Ghibli", "studio ghibli", 0),
        ("Marvel", "marvel", 0),
        ("DC", "dc comics", 0),
        ("Pixar", "pixar", 0),
        ("Disney", "disney", 0),
        ("A24", "a24", 0),
        ("Hàn Quốc", "korean", 0),
        ("Nhật Bản", "japanese", 0),
    ]
    
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
                                    if let movie = m?.filter({ !($0.adult ?? false) }).randomElement() {
                                        randomMovie = movie; showRandom = true
                                    }
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
                            ForEach(collections, id: \.0) { title, query, _ in
                                NavigationLink(destination: MovieListView(title: title, movies: [], fixedQuery: query)) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).frame(height: 100)
                                            .overlay(Image(systemName: "star.fill").font(.largeTitle).foregroundColor(.white.opacity(0.3)))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                        
                        SectionWithSeeAll(title: "Staff Picks", movies: staffMovies, query: "top rated movies")
                        SectionWithSeeAll(title: "Editor's Choice", movies: editorMovies, query: "award winning movies")
                        SectionWithSeeAll(title: "Hidden Gems", movies: hiddenMovies, query: "underrated movies")
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .task {
            async let s = APIService.shared.topRated()
            async let e = APIService.shared.discoverMovies(minRating: 8.0, minVotes: 500)
            async let h = APIService.shared.discoverMovies(minRating: 7.0, minVotes: 50)
            staffMovies = (try? await s)?.filter { !($0.adult ?? false) } ?? []
            editorMovies = (try? await e)?.filter { !($0.adult ?? false) } ?? []
            hiddenMovies = (try? await h)?.filter { !($0.adult ?? false) } ?? []
        }
        .sheet(isPresented: $showRandom) {
            if let movie = randomMovie {
                NavigationStack {
                    MovieDetailView(movie: movie)
                        .overlay(alignment: .topTrailing) { Button { showRandom = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding() } }
                }
            }
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
                    NavigationLink(destination: MovieListView(title: title, movies: movies, fixedQuery: query)) { Text("See All").font(.caption).foregroundColor(.gray) }
                }.padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(movies.prefix(15)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                CachedAsyncImage(url: movie.posterURL).frame(width: 105, height: 158).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}