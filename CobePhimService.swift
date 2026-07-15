import Foundation

final class CobePhimService {
    static let shared = CobePhimService()
    private let baseURL = "https://cobephim.sbs"
    
    func fetchStream(title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let searchQuery = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        guard let searchURL = URL(string: "\(baseURL)/tim-kiem?q=\(searchQuery)") else {
            completion(.failure(StreamServiceError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: searchURL) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(StreamServiceError.noData))
                return
            }
            
            var slug: String?
            if let range = html.range(of: "href=\"/xem-phim/") {
                let start = range.upperBound
                if let end = html[start...].firstIndex(of: "\"") {
                    slug = String(html[start..<end])
                }
            }
            if slug == nil, let range = html.range(of: "href=\"/phim/") {
                let start = range.upperBound
                if let end = html[start...].firstIndex(of: "\"") {
                    slug = String(html[start..<end])
                }
            }
            
            guard let foundSlug = slug else {
                completion(.failure(StreamServiceError.noMatchFound(id: title)))
                return
            }
            
            self.fetchStreamBySlug(slug: foundSlug, season: season, episode: episode, completion: completion)
        }.resume()
    }
    
    private func fetchStreamBySlug(slug: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/xem-phim/\(slug)") else {
            completion(.failure(StreamServiceError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(StreamServiceError.noData))
                return
            }
            
            if let range = html.range(of: "\"link\":\"") {
                let start = range.upperBound
                if let end = html[start...].firstIndex(of: "\"") {
                    var link = String(html[start..<end])
                    link = link.replacingOccurrences(of: "\\/", with: "/")
                    if let streamURL = URL(string: link) {
                        completion(.success(streamURL))
                        return
                    }
                }
            }
            completion(.failure(StreamServiceError.noStreamURL))
        }.resume()
    }
}