import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "b6be36c1c5788565fec6a24811e7cc9b"
    private let baseURL = "https://api.themoviedb.org/3"
    
    func trending() async throws -> [Movie] {
        let urlString = "\(baseURL)/trending/movie/week?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func nowPlaying() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func upcoming() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func topRated() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func popular() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func genres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GenreResponse.self, from: data)
        return response.genres
    }
    
    func search(query: String) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/movie?api_key=\(apiKey)&language=vi-VN&query=\(encoded)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func moviesByGenre(genreId: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreId)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func similar(movieId: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/\(movieId)/similar?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        return response.results
    }
    
    func trailer(movieId: Int) async throws -> String? {
        let urlString = "\(baseURL)/movie/\(movieId)/videos?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VideoResponse.self, from: data)
        return response.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key
    }
    
    func actors(movieId: Int) async throws -> [Actor] {
        let urlString = "\(baseURL)/movie/\(movieId)/credits?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ActorResponse.self, from: data)
        return Array(response.cast.prefix(20))
    }
    
    func actorDetail(actorId: Int) async throws -> Actor? {
        let urlString = "\(baseURL)/person/\(actorId)?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? JSONDecoder().decode(Actor.self, from: data)
    }
    
    func actorMovies(actorId: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/person/\(actorId)/movie_credits?api_key=\(apiKey)&language=vi-VN"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ActorMoviesResponse.self, from: data)
        return response.cast
    }
}
