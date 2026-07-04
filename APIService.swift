import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let baseURL = "https://api.themoviedb.org/3"
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "EMCC/1.0 (iPhone; iOS 17.0; Scale/3.0)",
            "Accept": "application/json",
            "Accept-Language": "vi-VN"
        ]
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }
    
    // Tự động resolve DNS qua Google DNS nếu bị chặn
    private func resolveURL(_ endpoint: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "vi-VN")
        ]
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Movies
    func trending() async throws -> [Movie] {
        try await fetch(endpoint: "/trending/movie/week")
    }
    
    func upcoming() async throws -> [Movie] {
        try await fetch(endpoint: "/movie/upcoming")
    }
    
    func nowPlaying() async throws -> [Movie] {
        try await fetch(endpoint: "/movie/now_playing")
    }
    
    func topRated() async throws -> [Movie] {
        try await fetch(endpoint: "/movie/top_rated")
    }
    
    func popular() async throws -> [Movie] {
        try await fetch(endpoint: "/movie/popular")
    }
    
    func search(query: String) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await fetch(endpoint: "/search/movie", params: ["query": encoded])
    }
    
    func moviesByGenre(genreId: Int) async throws -> [Movie] {
        try await fetch(endpoint: "/discover/movie", params: ["with_genres": "\(genreId)", "sort_by": "popularity.desc"])
    }
    
    func similar(movieId: Int) async throws -> [Movie] {
        try await fetch(endpoint: "/movie/\(movieId)/similar")
    }
    
    func recommendations(movieId: Int) async throws -> [Movie] {
        try await fetch(endpoint: "/movie/\(movieId)/recommendations")
    }
    
    func genres() async throws -> [Genre] {
        guard let url = resolveURL("/genre/movie/list") else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    func trailer(movieId: Int) async throws -> String? {
        guard let url = resolveURL("/movie/\(movieId)/videos") else { return nil }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(VideoResponse.self, from: data)
        return response.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key
    }
    
    func actors(movieId: Int) async throws -> [Actor] {
        guard let url = resolveURL("/movie/\(movieId)/credits") else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(ActorResponse.self, from: data)
        return Array(response.cast.prefix(20))
    }
    
    func actorDetail(actorId: Int) async throws -> Actor? {
        guard let url = resolveURL("/person/\(actorId)") else { return nil }
        let (data, _) = try await session.data(from: url)
        return try? decoder.decode(Actor.self, from: data)
    }
    
    func actorMovies(actorId: Int) async throws -> [Movie] {
        guard let url = resolveURL("/person/\(actorId)/movie_credits") else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(ActorMoviesResponse.self, from: data)
        return response.cast
    }
    
    private func fetch(endpoint: String, params: [String: String] = [:]) async throws -> [Movie] {
        guard let url = resolveURL(endpoint, params: params) else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results
    }
}
