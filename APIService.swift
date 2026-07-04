import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "6c4f4c67ae7d14bece6971cb64e3c415"
    private let baseURL = "https://api.themoviedb.org/3"
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
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
    
    // MARK: - Genres
    func genres() async throws -> [Genre] {
        let url = buildURL(endpoint: "/genre/movie/list", params: [:])
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    // MARK: - Video
    func trailer(movieId: Int) async throws -> String? {
        let url = buildURL(endpoint: "/movie/\(movieId)/videos", params: [:])
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(VideoResponse.self, from: data)
        return response.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key
    }
    
    // MARK: - Actors
    func actors(movieId: Int) async throws -> [Actor] {
        let url = buildURL(endpoint: "/movie/\(movieId)/credits", params: [:])
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(ActorResponse.self, from: data)
        return Array(response.cast.prefix(20))
    }
    
    func actorDetail(actorId: Int) async throws -> Actor? {
        let url = buildURL(endpoint: "/person/\(actorId)", params: [:])
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? decoder.decode(Actor.self, from: data)
    }
    
    func actorMovies(actorId: Int) async throws -> [Movie] {
        let url = buildURL(endpoint: "/person/\(actorId)/movie_credits", params: [:])
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(ActorMoviesResponse.self, from: data)
        return response.cast
    }
    
    // MARK: - Helpers
    private func fetch(endpoint: String, params: [String: String] = [:]) async throws -> [Movie] {
        let url = buildURL(endpoint: endpoint, params: params)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MovieResponse.self, from: data)
        return response.results
    }
    
    private func buildURL(endpoint: String, params: [String: String]) -> URL {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")!
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "language", value: "vi-VN")]
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        return components.url!
    }
}
