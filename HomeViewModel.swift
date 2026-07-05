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
        
        async let d = APIService.shared.trending24h()
        async let n = APIService.shared.nowPlaying()
        async let u = APIService.shared.upcoming()
        async let tr = APIService.shared.topRated()
        async let p = APIService.shared.popular()
        async let ko = APIService.shared.koreanMovies()
        async let ja = APIService.shared.japaneseMovies()
        async let vi = APIService.shared.vietnameseMovies()
        async let us = APIService.shared.usukMovies()
        async let an = APIService.shared.animeMovies()
        async let g = APIService.shared.genres()
        async let tv = APIService.shared.trendingTV()
        
        do {
            var movies = try await d
            var tvShows = try await tv
            
            // Gán mediaType cho từng loại
            movies = movies.map { m in Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "movie") }
            tvShows = tvShows.map { m in Movie(id: m.id, title: m.title, overview: m.overview, posterPath: m.posterPath, backdropPath: m.backdropPath, voteAverage: m.voteAverage, releaseDate: m.releaseDate, genreIds: m.genreIds, originalTitle: m.originalTitle, popularity: m.popularity, voteCount: m.voteCount, adult: m.adult, originalLanguage: m.originalLanguage, mediaType: "tv") }
            
            trending24h = (movies + tvShows).filter { !($0.adult ?? false) }
            nowPlaying = try await n.filter { !($0.adult ?? false) }
            upcoming = try await u.filter { !($0.adult ?? false) }
            topRated = try await tr.filter { !($0.adult ?? false) }
            popular = try await p.filter { !($0.adult ?? false) }
            korean = try await ko.filter { !($0.adult ?? false) && $0.voteAverage > 5.0 }
            japanese = try await ja.filter { !($0.adult ?? false) && $0.voteAverage > 6.0 && ($0.popularity ?? 0) > 10 }
            vietnamese = try await vi.filter { !($0.adult ?? false) }
            usuk = try await us.filter { !($0.adult ?? false) }
            anime = try await an.filter { !($0.adult ?? false) }
            genres = try await g
            
            if !trending24h.isEmpty {
                let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                movieOfDay = trending24h[day % trending24h.count]
            }
        } catch { print("Error: \(error)") }
        
        isLoading = false
    }
}