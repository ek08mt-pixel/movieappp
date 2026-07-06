import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var trendingTV: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var anime: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var movieOfDay: Movie?
    @Published var isLoading = true
    
    func loadAll() async {
        // Load nhanh trending trước
        async let trendingTask = APIService.shared.trending24h()
        async let genresTask = APIService.shared.genres()
        
        trending24h = (try? await trendingTask) ?? []
        genres = (try? await genresTask) ?? []
        movieOfDay = trending24h.randomElement()
        isLoading = false
        
        // Load các phần còn lại sau
        async let trendingTVTask = fetchTrendingTV()
        async let nowPlayingTask = APIService.shared.nowPlaying()
        async let upcomingTask = APIService.shared.upcoming()
        async let topRatedTask = APIService.shared.topRated()
        async let koreanTask = APIService.shared.koreanMovies()
        async let japaneseTask = APIService.shared.japaneseMovies()
        async let vietnameseTask = APIService.shared.vietnameseMovies()
        async let usukTask = APIService.shared.usukMovies()
        async let animeTask = APIService.shared.animeMovies()
        
        trendingTV = (try? await trendingTVTask) ?? []
        nowPlaying = (try? await nowPlayingTask) ?? []
        upcoming = (try? await upcomingTask) ?? []
        topRated = (try? await topRatedTask) ?? []
        korean = (try? await koreanTask) ?? []
        japanese = (try? await japaneseTask) ?? []
        vietnamese = (try? await vietnameseTask) ?? []
        usuk = (try? await usukTask) ?? []
        anime = (try? await animeTask) ?? []
    }
    
    private func fetchTrendingTV() async throws -> [Movie] {
        let urlString = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results.map { movie in
            Movie(id: movie.id, title: movie.title, overview: movie.overview, posterPath: movie.posterPath, backdropPath: movie.backdropPath, voteAverage: movie.voteAverage, releaseDate: movie.releaseDate, genreIds: movie.genreIds, originalTitle: movie.originalTitle, popularity: movie.popularity, voteCount: movie.voteCount, adult: movie.adult, originalLanguage: movie.originalLanguage, mediaType: "tv")
        }
    }
}