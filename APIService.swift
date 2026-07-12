import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let baseURL = "https://api.themoviedb.org/3"
    
    private var language: String { LanguageManager.shared.currentLanguage.tmdbLanguage }
    private let decoder: JSONDecoder = { let d = JSONDecoder(); return d }()
    
    func trending24h() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/trending/movie/day?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func trendingTV() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/trending/tv/day?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { movie in
                Movie(id: movie.id, title: movie.title, overview: movie.overview, posterPath: movie.posterPath, backdropPath: movie.backdropPath, voteAverage: movie.voteAverage, releaseDate: movie.releaseDate, genreIds: movie.genreIds, originalTitle: movie.originalTitle, popularity: movie.popularity, voteCount: movie.voteCount, adult: movie.adult, originalLanguage: movie.originalLanguage, mediaType: "tv")
            }
        }
    }
    
    func searchMovies(query: String, page: Int = 1) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/movie?api_key=\(apiKey)&language=\(language)&query=\(encoded)&page=\(page)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func searchTVShows(query: String, page: Int = 1) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/tv?api_key=\(apiKey)&language=en-US&query=\(encoded)&page=\(page)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct TVSearchResponse: Codable { let results: [TVResult] }
        struct TVResult: Codable {
            let id: Int; let name: String?; let overview: String
            let poster_path: String?; let backdrop_path: String?
            let vote_average: Double; let first_air_date: String?
            let genre_ids: [Int]?; let popularity: Double?
            let vote_count: Int?; let original_language: String?
        }
        let response = try JSONDecoder().decode(TVSearchResponse.self, from: data)
        return response.results.map { tv in
            Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                  posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                  voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                  genreIds: tv.genre_ids, originalTitle: tv.name,
                  popularity: tv.popularity, voteCount: tv.vote_count,
                  adult: false, originalLanguage: tv.original_language, mediaType: "tv")
        }
    }
    
    func popular() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func topRated() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func nowPlaying() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func upcoming() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func genres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    func moviesByGenre(genreId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreId)&sort_by=popularity.desc&language=\(language)&page=\(page)&vote_count.gte=50"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    // Danh mục theo quốc gia - gọi API riêng
    func koreanMovies() async throws -> [Movie] {
        try await discoverMovies(lang: "ko", sortBy: "popularity.desc")
    }
    func japaneseMovies() async throws -> [Movie] {
        try await discoverMovies(lang: "ja", sortBy: "popularity.desc")
    }
    func vietnameseMovies() async throws -> [Movie] {
        try await discoverMovies(lang: "vi", sortBy: "popularity.desc")
    }
    func usukMovies() async throws -> [Movie] {
        try await discoverMovies(lang: "en", sortBy: "popularity.desc")
    }
    func animeMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=16&sort_by=popularity.desc&language=\(language)&page=\(page)&vote_count.gte=100"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.filter { !($0.adult ?? false) }.map { $0.withPlaceholder() }
        }
    }
    
    func discoverMovies(minRating: Double? = nil, minVotes: Int? = nil) async throws -> [Movie] {
        var urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&sort_by=popularity.desc&language=\(language)"
        if let r = minRating { urlString += "&vote_average.gte=\(r)" }
        if let v = minVotes { urlString += "&vote_count.gte=\(v)" }
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    private func discoverMovies(lang: String, sortBy: String) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=\(lang)&sort_by=\(sortBy)&language=\(language)&page=\(page)&vote_count.gte=30"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.filter { !($0.adult ?? false) }.map { $0.withPlaceholder() }
        }
    }
    
    func movieDetail(movieId: Int) async throws -> MovieDetail? {
        let urlString = "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=\(language)&append_to_response=credits"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(MovieDetail.self, from: data)
    }
    
    func similar(movieId: Int, mediaType: String? = nil) async throws -> [Movie] {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlString = "\(baseURL)/\(type)/\(movieId)/similar?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func actors(movieId: Int, mediaType: String? = nil) async throws -> [Actor] {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlString = "\(baseURL)/\(type)/\(movieId)/credits?api_key=\(apiKey)&language=\(language)"
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
        return response.cast.map { $0.withPlaceholder() }
    }
    
    func movieImages(movieId: Int, mediaType: String? = nil) async throws -> [URL] {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlString = "\(baseURL)/\(type)/\(movieId)/images?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct IR: Codable { let backdrops: [II]? }; struct II: Codable { let file_path: String? }
        let res = try decoder.decode(IR.self, from: data)
        return res.backdrops?.compactMap { $0.file_path != nil ? URL(string: "https://image.tmdb.org/t/p/w780\($0.file_path!)") : nil } ?? []
    }
    
    func fetchTVSeasons(tvId: Int) async throws -> [TVSeason] {
        let detail = try await tvDetail(tvId: tvId)
        return detail?.seasons?.filter { $0.seasonNumber > 0 } ?? []
    }
    
    func tvDetail(tvId: Int) async throws -> MovieDetail? {
        let urlString = "\(baseURL)/tv/\(tvId)?api_key=\(apiKey)&language=\(language)&append_to_response=credits"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(MovieDetail.self, from: data)
    }
    
    func fetchSeasonDetail(tvId: Int, seasonNumber: Int) async throws -> TVSeasonDetail {
        let urlString = "\(baseURL)/tv/\(tvId)/season/\(seasonNumber)?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TVSeasonDetail.self, from: data)
    }
    
    func fetchExternalIDs(tvId: Int) async throws -> String? {
        let urlString = "\(baseURL)/tv/\(tvId)/external_ids?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct E: Codable { let imdb_id: String? }
        return try decoder.decode(E.self, from: data).imdb_id
    }
    
    func collectionDetail(collectionId: Int) async throws -> CollectionDetail? {
        let urlString = "\(baseURL)/collection/\(collectionId)?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(CollectionDetail.self, from: data)
    }
    
    func discoverMoviesByYear(_ year: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&primary_release_year=\(year)&sort_by=popularity.desc&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func fetchMovies(by categoryID: Int, type: CategoryConfig.CategoryType) async throws -> [Movie] {
    let urlString: String
    switch type {
    case .studio:
    if categoryID == 213 {
        urlString = "\(baseURL)/discover/tv?api_key=\(apiKey)&with_networks=213&sort_by=popularity.desc&language=\(language)"
    } else {
        urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_companies=\(categoryID)&sort_by=popularity.desc&language=\(language)"
    }
    case .keyword: urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_keywords=\(categoryID)&sort_by=vote_average.desc&vote_count.gte=30&language=\(language)"
    case .genre: urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(categoryID)&sort_by=popularity.desc&language=\(language)"
    }
    return try await fetchMultiplePages { [self] page in
        guard let url = URL(string: "\(urlString)&page=\(page)") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
}
    
    private func fetchMultiplePages(fetcher: @escaping (Int) async throws -> [Movie]) async throws -> [Movie] {
        var all: [Movie] = []
        for page in 1...5 { let p = try await fetcher(page); all.append(contentsOf: p); if p.count < 20 { break } }
        return all
    }
}

extension Movie {
    func withPlaceholder() -> Movie {
        return Movie(id: id, title: title, overview: overview, posterPath: posterPath ?? "/placeholder.jpg", backdropPath: backdropPath, voteAverage: voteAverage, releaseDate: releaseDate, genreIds: genreIds, originalTitle: originalTitle, popularity: popularity, voteCount: voteCount, adult: adult, originalLanguage: originalLanguage, mediaType: mediaType)
    }
}