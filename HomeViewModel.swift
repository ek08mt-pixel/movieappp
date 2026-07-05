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
        
        do {
            // Movie
            let movies = try await APIService.shared.trending24h().map { m in
                Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "movie")
            }
            
            // TV shows (có thể fail)
            var tvShows: [Movie] = []
            if let tv = try? await APIService.shared.trendingTV() {
                tvShows = tv.map { m in
                    Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "tv")
                }
            }
            
            trending24h = (movies + tvShows).filter { !($0.adult ?? false) }
            
            // Các API khác
            nowPlaying = try await APIService.shared.nowPlaying().filter { !($0.adult ?? false) }
            upcoming = try await APIService.shared.upcoming().filter { !($0.adult ?? false) }
            topRated = try await APIService.shared.topRated().filter { !($0.adult ?? false) }
            popular = try await APIService.shared.popular().filter { !($0.adult ?? false) }
            korean = try await APIService.shared.koreanMovies().filter { !($0.adult ?? false) && $0.voteAverage > 5.0 }
            japanese = try await APIService.shared.japaneseMovies().filter { !($0.adult ?? false) && $0.voteAverage > 6.0 && ($0.popularity ?? 0) > 10 }
            vietnamese = try await APIService.shared.vietnameseMovies().filter { !($0.adult ?? false) }
            usuk = try await APIService.shared.usukMovies().filter { !($0.adult ?? false) }
            anime = try await APIService.shared.animeMovies().filter { !($0.adult ?? false) }
            genres = try await APIService.shared.genres()
            
            if !trending24h.isEmpty {
                let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                movieOfDay = trending24h[day % trending24h.count]
            }
        } catch {
            print("HomeViewModel error: \(error)")
        }
        
        isLoading = false
    }
}