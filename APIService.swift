import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let baseURL = "https://api.themoviedb.org/3"
    
    private var language: String {
        LanguageManager.shared.currentLanguage.tmdbLanguage
    }
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    // MARK: - Movies (Load 5 trang)
    func trending24h() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/trending/movie/day?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func upcoming() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func nowPlaying() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func topRated() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func popular() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func koreanMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=ko&sort_by=popularity.desc&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func japaneseMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=ja&sort_by=popularity.desc&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func vietnameseMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=vi&sort_by=popularity.desc&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func usukMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=en&sort_by=popularity.desc&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func animeMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=16&with_original_language=ja&sort_by=popularity.desc&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func genres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    func search(query: String, page: Int = 1) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/movie?api_key=\(apiKey)&language=\(language)&query=\(encoded)&page=\(page)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholderIfNeeded() }
    }
    
    func moviesByGenre(genreId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreId)&sort_by=popularity.desc&language=\(language)&page=\(page)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholderIfNeeded() }
    }
    
    func discoverByKeyword(keywordId: Int) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_keywords=\(keywordId)&sort_by=vote_average.desc&vote_count.gte=30&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func discoverByStudio(studioId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_companies=\(studioId)&sort_by=popularity.desc&page=\(page)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholderIfNeeded() }
    }
    
    func fetchMovies(by categoryID: Int, type: CategoryConfig.CategoryType) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString: String
            switch type {
            case .studio:
                urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_companies=\(categoryID)&sort_by=popularity.desc&language=\(language)&page=\(page)"
            case .keyword:
                urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_keywords=\(categoryID)&sort_by=vote_average.desc&vote_count.gte=30&language=\(language)&page=\(page)"
            case .genre:
                urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(categoryID)&sort_by=popularity.desc&language=\(language)&page=\(page)"
            }
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholderIfNeeded() }
        }
    }
    
    func discoverMovies(year: Int? = nil, genreId: Int? = nil, minRating: Double? = nil, minVotes: Int? = nil, page: Int = 1) async throws -> [Movie] {
        var urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&sort_by=popularity.desc&language=\(language)&page=\(page)"
        if let year = year { urlString += "&primary_release_year=\(year)" }
        if let genreId = genreId { urlString += "&with_genres=\(genreId)" }
        if let minRating = minRating { urlString += "&vote_average.gte=\(minRating)" }
        if let minVotes = minVotes { urlString += "&vote_count.gte=\(minVotes)" }
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholderIfNeeded() }
    }
    
    func similar(movieId: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/\(movieId)/similar?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholderIfNeeded() }
    }
    
    func movieDetail(movieId: Int) async throws -> MovieDetail? {
        let urlString = "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=\(language)&append_to_response=credits"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(MovieDetail.self, from: data)
    }
    
    func trailer(movieId: Int) async throws -> String? {
        let urlString = "\(baseURL)/movie/\(movieId)/videos?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(VideoResponse.self, from: data)
        return response.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key
    }
    
    func actors(movieId: Int) async throws -> [Actor] {
        let urlString = "\(baseURL)/movie/\(movieId)/credits?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(ActorResponse.self, from: data)
        return Array(response.cast.prefix(20))
    }
    
    func actorDetail(actorId: Int) async throws -> Actor? {
        let urlString = "\(baseURL)/person/\(actorId)?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(Actor.self, from: data)
    }
    
    func actorMovies(actorId: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/person/\(actorId)/movie_credits?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(ActorMoviesResponse.self, from: data)
        return response.cast.map { $0.withPlaceholderIfNeeded() }
    }
    
    // MARK: - Helper
    private func fetchMultiplePages(fetcher: @escaping (Int) async throws -> [Movie]) async throws -> [Movie] {
        var allMovies: [Movie] = []
        for page in 1...5 {
            let pageMovies = try await fetcher(page)
            allMovies.append(contentsOf: pageMovies)
            if pageMovies.count < 20 { break }
        }
        return allMovies
    }
}

// MARK: - Extension Movie
extension Movie {
    func withPlaceholderIfNeeded() -> Movie {
        return Movie(
            id: id, title: title, overview: overview,
            posterPath: posterPath ?? "/placeholder.jpg",
            backdropPath: backdropPath, voteAverage: voteAverage,
            releaseDate: releaseDate, genreIds: genreIds,
            originalTitle: originalTitle, popularity: popularity,
            voteCount: voteCount, adult: adult, originalLanguage: originalLanguage
        )
    }
}