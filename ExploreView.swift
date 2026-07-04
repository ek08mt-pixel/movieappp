import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
    let collections: [(String, String, String)] = [
        ("Oscar", "oscar", "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"),
        ("Cannes", "cannes", "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg"),
        ("IMDb Top", "top rated", "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg"),
        ("Netflix", "netflix original", "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg"),
        ("Ghibli", "studio ghibli", "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg"),
        ("Marvel", "marvel studios", "/or06FN3Dka5tukK1e9sl16pB3iy.jpg"),
        ("DC", "dc films", "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg"),
        ("Pixar", "pixar", "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
        ("Disney", "disney", "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg"),
        ("A24", "a24 films", "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"),
        ("Hàn Quốc", "korean movies", "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"),
        ("Nhật Bản", "japanese anime", "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg"),
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
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    do {
                                        let movies = try await APIService.shared.popular()
                                        if let movie = movies.randomElement() {
                                            randomMovie = movie
                                            showRandom = true
                                        }
                                    } catch {}
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text("🎲").font(.system(size: 28))
                                    Text("Random").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: MoodPickerView()) {
                                VStack(spacing: 6) {
                                    Text("🎭").font(.system(size: 28))
                                    Text("Mood").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) {
                                    Text("📅").font(.system(size: 28))
                                    Text("Timeline").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            
                            NavigationLink(destination: GuessMovieView()) {
                                VStack(spacing: 6) {
                                    Text("❓").font(.system(size: 28))
                                    Text("Guess").font(.system(size: 10)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections, id: \.0) { title, query, poster in
                                NavigationLink(destination: MovieListView(title: title, movies: [])) {
                                    ZStack(alignment: .bottomLeading) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(Color.black.opacity(0.35))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Staff Picks
                        SectionWithSeeAll(title: "Staff Picks", movies: staffMovies)
                        
                        // Editor's Choice
                        SectionWithSeeAll(title: "Editor's Choice", movies: editorMovies)
                        
                        // Hidden Gems
                        SectionWithSeeAll(title: "Hidden Gems", movies: hiddenMovies)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .task {
            async let s = APIService.shared.topRated()
            async let e = APIService.shared.popular()
            async let h = APIService.shared.discoverMovies(minRating: 7.5, minVotes: 100)
            do {
                staffMovies = try await s
                editorMovies = try await e
                hiddenMovies = try await h
            } catch {}
        }
        .fullScreenCover(isPresented: $showRandom) {
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
}

struct SectionWithSeeAll: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    NavigationLink(destination: MovieListView(title: title, movies: movies)) {
                        Text("See All").font(.caption).foregroundColor(.gray)
                    }
                }.padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(movies.prefix(15)) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                CachedAsyncImage(url: movie.posterURL)
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