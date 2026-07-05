import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var anime: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var movieOfDay: Movie?
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        // Chỉ gọi trending24h + trendingTV
        async let movies = APIService.shared.trending24h()
        async let tv = APIService.shared.trendingTV()
        async let g = APIService.shared.genres()
        
        do {
            var allMovies = try await movies.map { m in
                Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "movie")
            }
            
            let tvShows = (try? await tv)?.map { m in
                Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "tv")
            } ?? []
            
            allMovies.append(contentsOf: tvShows)
            trending24h = allMovies.filter { !($0.adult ?? false) }
            genres = try await g
            
            // Gán cho các section khác
            nowPlaying = trending24h
            upcoming = trending24h.shuffled()
            topRated = trending24h.shuffled()
            popular = trending24h.shuffled()
            korean = Array(trending24h.prefix(10))
            japanese = Array(trending24h.prefix(8))
            vietnamese = Array(trending24h.prefix(6))
            usuk = Array(trending24h.prefix(10))
            anime = Array(trending24h.prefix(8))
            
            if !trending24h.isEmpty {
                let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                movieOfDay = trending24h[day % trending24h.count]
            }
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
}