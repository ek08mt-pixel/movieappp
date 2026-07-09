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
    
    init() {}
    
    func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Load critical data first
        async let trendingTask = APIService.shared.trending24h()
        async let genresTask = APIService.shared.genres()
        
        if let trending = try? await trendingTask {
            trending24h = trending
            movieOfDay = trending.randomElement()
        }
        genres = (try? await genresTask) ?? []
        
        // Load TV in background
        Task.detached(priority: .background) { [weak self] in
            let tv = await self?.loadTrendingTVPages() ?? []
            await MainActor.run { self?.trendingTV = tv }
        }
        
        isLoading = false
        
        // Load remaining categories sequentially to avoid flooding
        let categories: [(inout [Movie], () async throws -> [Movie])] = [
            (&nowPlaying, APIService.shared.nowPlaying),
            (&upcoming, APIService.shared.upcoming),
            (&topRated, APIService.shared.topRated),
            (&korean, APIService.shared.koreanMovies),
            (&japanese, APIService.shared.japaneseMovies),
            (&vietnamese, APIService.shared.vietnameseMovies),
            (&usuk, APIService.shared.usukMovies),
            (&anime, APIService.shared.animeMovies),
        ]
        
        // Load 2 categories at a time
        for i in stride(from: 0, to: categories.count, by: 2) {
            async let first = categories[i].1()
            async let second = (i + 1 < categories.count) ? categories[i + 1].1() : nil
            
            if let result = try? await first {
                await MainActor.run { categories[i].0 = result }
            }
            if i + 1 < categories.count, let result = try? await second {
                await MainActor.run { categories[i + 1].0 = result }
            }
        }
    }
    
    private func loadTrendingTVPages() async -> [Movie] {
        var allTV: [Movie] = []
        for page in 1...2 {
            let urlString = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&page=\(page)"
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct TVResponse: Codable { let results: [TVResult] }
                struct TVResult: Codable {
                    let id: Int; let name: String?; let overview: String
                    let poster_path: String?; let backdrop_path: String?
                    let vote_average: Double; let first_air_date: String?
                    let genre_ids: [Int]?; let popularity: Double?
                    let vote_count: Int?; let original_language: String?
                }
                let response = try JSONDecoder().decode(TVResponse.self, from: data)
                let tvShows = response.results.map { tv in
                    Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                          posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                          voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                          genreIds: tv.genre_ids, originalTitle: tv.name,
                          popularity: tv.popularity, voteCount: tv.vote_count,
                          adult: false, originalLanguage: tv.original_language, mediaType: "tv")
                }
                allTV.append(contentsOf: tvShows)
            } catch {}
        }
        return allTV
    }
}