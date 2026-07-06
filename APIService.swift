import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let baseURL = "https://api.themoviedb.org/3"
    
    private var language: String { LanguageManager.shared.currentLanguage.tmdbLanguage }
    private let decoder: JSONDecoder = { let d = JSONDecoder(); return d }()
    
    func trendingAll() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/trending/all/day?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
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
    
    func upcoming() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=\(language)&page=\(page)"
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
    
    func topRated() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
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
    
    func koreanMovies() async throws -> [Movie] { try await discoverMovies(lang: "ko") }
    func japaneseMovies() async throws -> [Movie] { try await discoverMovies(lang: "ja", minVotes: 50, minRating: 5.0) }
    func vietnameseMovies() async throws -> [Movie] { try await discoverMovies(lang: "vi") }
    func usukMovies() async throws -> [Movie] { try await discoverMovies(lang: "en") }
    
    func animeMovies() async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=16&with_original_language=ja&sort_by=popularity.desc&language=\(language)&page=\(page)&vote_count.gte=50&vote_average.gte=5.0"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.filter { !($0.adult ?? false) }.map { $0.withPlaceholder() }
        }
    }
    
    private func discoverMovies(lang: String, minVotes: Int? = nil, minRating: Double? = nil) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            var urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_original_language=\(lang)&sort_by=popularity.desc&language=\(language)&page=\(page)&vote_count.gte=30"
            if let v = minVotes { urlString += "&vote_count.gte=\(v)" }
            if let r = minRating { urlString += "&vote_average.gte=\(r)" }
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.filter { !($0.adult ?? false) }.map { $0.withPlaceholder() }
        }
    }
    
    func genres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(GenreResponse.self, from: data)
        return response.genres
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
    
    func moviesByGenre(genreId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreId)&sort_by=popularity.desc&language=\(language)&page=\(page)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func discoverByKeyword(keywordId: Int) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_keywords=\(keywordId)&sort_by=vote_average.desc&vote_count.gte=30&language=\(language)&page=\(page)"
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
        }
    }
    
    func discoverByStudio(studioId: Int, page: Int = 1) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_companies=\(studioId)&sort_by=popularity.desc&page=\(page)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func fetchMovies(by categoryID: Int, type: CategoryConfig.CategoryType) async throws -> [Movie] {
        try await fetchMultiplePages { [self] page in
            let urlString: String
            switch type {
            case .studio: urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_companies=\(categoryID)&sort_by=popularity.desc&language=\(language)&page=\(page)"
            case .keyword: urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_keywords=\(categoryID)&sort_by=vote_average.desc&vote_count.gte=30&language=\(language)&page=\(page)"
            case .genre: urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(categoryID)&sort_by=popularity.desc&language=\(language)&page=\(page)"
            }
            guard let url = URL(string: urlString) else { return [] }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(MovieResponse.self, from: data)
            return response.results.map { $0.withPlaceholder() }
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
        return response.results.map { $0.withPlaceholder() }
    }
    
    func similar(movieId: Int, mediaType: String? = nil) async throws -> [Movie] {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlString = "\(baseURL)/\(type)/\(movieId)/similar?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results.map { $0.withPlaceholder() }
    }
    
    func movieDetail(movieId: Int) async throws -> MovieDetail? {
        let urlString = "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=\(language)&append_to_response=credits"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(MovieDetail.self, from: data)
    }
    
    func tvDetail(tvId: Int) async throws -> MovieDetail? {
        let urlString = "\(baseURL)/tv/\(tvId)?api_key=\(apiKey)&language=\(language)&append_to_response=credits"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(MovieDetail.self, from: data)
    }
    
    func collectionDetail(collectionId: Int) async throws -> CollectionDetail? {
        let urlString = "\(baseURL)/collection/\(collectionId)?api_key=\(apiKey)&language=\(language)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(CollectionDetail.self, from: data)
    }
    
    func trailer(movieId: Int, mediaType: String? = nil) async throws -> String? {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlString = "\(baseURL)/\(type)/\(movieId)/videos?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(VideoResponse.self, from: data)
        return response.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key
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