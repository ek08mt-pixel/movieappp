import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
    // Mỗi collection có keyword_id riêng để gọi discover API
    let collections: [(String, String, Int?)] = [
        ("Oscar", "oscar", 2959),
        ("Cannes", "cannes", 133278),
        ("IMDb Top", "imdb top", nil),
        ("Netflix", "netflix", 213),
        ("Ghibli", "studio ghibli", 103538),
        ("Marvel", "marvel", 7506),
        ("DC", "dc comics", 102499),
        ("Pixar", "pixar", 3),
        ("Disney", "disney", 2),
        ("A24", "a24", 135334),
        ("Hàn Quốc", "korean", nil),
        ("Nhật Bản", "japanese", nil),
    ]
    
    // Poster cứng cho từng collection
    func posterFor(_ title: String) -> String {
        switch title {
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
        case "Hàn Quốc": return "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"
        case "Nhật Bản": return "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg"
        default: return "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"
        }
    }
    
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
                                        if let movie = movies.filter({ !($0.adult ?? false) }).randomElement() {
                                            randomMovie = movie; showRandom = true
                                        }
                                    } catch {}
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
                        }
                        .padding(.horizontal)
                        
                        // 12 ô thể loại - dùng poster cứng + discover API
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections, id: \.0) { title, query, keywordId in
                                NavigationLink(destination: CategoryMovieView(title: title, keywordId: keywordId, query: query)) {
                                    ZStack(alignment: .bottomLeading) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterFor(title))"))
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(Color.black.opacity(0.35))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        
                                        Text(title)
                                            .font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
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
            if let movie = randomMovie {
                NavigationStack { MovieDetailView(movie: movie).overlay(alignment: .topTrailing) { Button { showRandom = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding() } } }
            }
        }
    }
}

// MARK: - Category Movie View (Dùng discover/movie cho danh mục)
struct CategoryMovieView: View {
    let title: String
    let keywordId: Int?
    let query: String
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading { ProgressView().tint(.white) }
            else if movies.isEmpty { Text("Không tìm thấy phim").foregroundColor(.gray) }
            else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 4) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(height: 165).clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(movie.title).font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white).lineLimit(2).frame(maxWidth: 110)
                                    HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray) }
                                }
                            }
                        }
                    }.padding()
                }
            }
        }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                if let kid = keywordId {
                    // Dùng discover với keywords
                    movies = try await APIService.shared.discoverByKeyword(keywordId: kid)
                } else {
                    // Fallback: dùng discover với query làm từ khóa tìm kiếm
                    movies = try await APIService.shared.search(query: query)
                }
            } catch { movies = [] }
            isLoading = false
        }
    }
}

struct SectionWithSeeAll: View {
    let title: String; let movies: [Movie]; var query: String = ""
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white); Spacer(); NavigationLink(destination: CategoryMovieView(title: title, keywordId: nil, query: query)) { Text("See All").font(.caption).foregroundColor(.gray) } }.padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) { ForEach(movies.prefix(15)) { movie in NavigationLink(destination: MovieDetailView(movie: movie)) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 105, height: 158).clipShape(RoundedRectangle(cornerRadius: 10)) } } }.padding(.horizontal)
                }
            }
        }
    }
}