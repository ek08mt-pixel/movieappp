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
    @Published var isLoading = false
    
    init() {
        Task { await loadAll() }
    }
    
    func loadAll() async {
        isLoading = true
        
        async let trendingTask = APIService.shared.trending24h()
        async let genresTask = APIService.shared.genres()
        
        trending24h = (try? await trendingTask) ?? []
        genres = (try? await genresTask) ?? []
        movieOfDay = trending24h.randomElement()
        trendingTV = await loadTrendingTV()
        
        isLoading = false
        
        async let nowPlayingTask = APIService.shared.nowPlaying()
        async let upcomingTask = APIService.shared.upcoming()
        async let topRatedTask = APIService.shared.topRated()
        async let koreanTask = APIService.shared.koreanMovies()
        async let japaneseTask = APIService.shared.japaneseMovies()
        async let vietnameseTask = APIService.shared.vietnameseMovies()
        async let usukTask = APIService.shared.usukMovies()
        async let animeTask = APIService.shared.animeMovies()
        
        nowPlaying = (try? await nowPlayingTask) ?? []
        upcoming = (try? await upcomingTask) ?? []
        topRated = (try? await topRatedTask) ?? []
        korean = (try? await koreanTask) ?? []
        japanese = (try? await japaneseTask) ?? []
        vietnamese = (try? await vietnameseTask) ?? []
        usuk = (try? await usukTask) ?? []
        anime = (try? await animeTask) ?? []
    }
    
    private func loadTrendingTV() async -> [Movie] {
        let urlString = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct TVResponse: Codable {
                let results: [TVResult]
            }
            struct TVResult: Codable {
                let id: Int
                let name: String?
                let overview: String
                let poster_path: String?
                let backdrop_path: String?
                let vote_average: Double
                let first_air_date: String?
                let genre_ids: [Int]?
                let popularity: Double?
                let vote_count: Int?
                let original_language: String?
            }
            let response = try JSONDecoder().decode(TVResponse.self, from: data)
            return response.results.map { tv in
                Movie(
                    id: tv.id,
                    title: tv.name ?? "Unknown",
                    overview: tv.overview,
                    posterPath: tv.poster_path,
                    backdropPath: tv.backdrop_path,
                    voteAverage: tv.vote_average,
                    releaseDate: tv.first_air_date,
                    genreIds: tv.genre_ids,
                    originalTitle: tv.name,
                    popularity: tv.popularity,
                    voteCount: tv.vote_count,
                    adult: false,
                    originalLanguage: tv.original_language,
                    mediaType: "tv"
                )
            }
        } catch {
            print("TV Error: \(error)")
            return []
        }
    }
}