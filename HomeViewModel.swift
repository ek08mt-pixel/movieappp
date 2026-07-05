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
        
        async let movies = APIService.shared.trending24h()
        async let tv = APIService.shared.trendingTV()
        async let np = APIService.shared.nowPlaying()
        async let up = APIService.shared.upcoming()
        async let tr = APIService.shared.topRated()
        async let pop = APIService.shared.popular()
        async let ko = APIService.shared.koreanMovies()
        async let ja = APIService.shared.japaneseMovies()
        async let vi = APIService.shared.vietnameseMovies()
        async let us = APIService.shared.usukMovies()
        async let an = APIService.shared.animeMovies()
        async let g = APIService.shared.genres()
        
        do {
            let m = try await movies.map { Movie(id: $0.id, title: $0.title, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, voteAverage: $0.voteAverage, releaseDate: $0.releaseDate, genreIds: $0.genreIds, originalTitle: $0.originalTitle, popularity: $0.popularity, voteCount: $0.voteCount, adult: $0.adult, originalLanguage: $0.originalLanguage, mediaType: "movie") }
            let t = (try? await tv)?.map { Movie(id: $0.id, title: $0.title, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, voteAverage: $0.voteAverage, releaseDate: $0.releaseDate, genreIds: $0.genreIds, originalTitle: $0.originalTitle, popularity: $0.popularity, voteCount: $0.voteCount, adult: $0.adult, originalLanguage: $0.originalLanguage, mediaType: "tv") } ?? []
            
            trending24h = (m + t).filter { !($0.adult ?? false) }
            nowPlaying = try await np.filter { !($0.adult ?? false) }
            upcoming = try await up.filter { !($0.adult ?? false) }
            topRated = try await tr.filter { !($0.adult ?? false) }
            popular = try await pop.filter { !($0.adult ?? false) }
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