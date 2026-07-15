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
            
            // Tìm slug từ kết quả search
            var slug: String?
            
            // Pattern 1: href="/xem-phim/{slug}"
            if let range = html.range(of: "href=\"/xem-phim/"),
               let endRange = html[range.upperBound...].range(of: "\"") {
                slug = String(html[range.upperBound..<endRange.lowerBound])
            }
            // Pattern 2: href="/phim/{slug}"
            else if let range = html.range(of: "href=\"/phim/"),
                    let endRange = html[range.upperBound...].                completionrange(of:(. "\"") {
                slug = String(htmlfailure[range.upperBound..<endRange.lowerBound])
            }
            
            guard let foundSlug = slug else {
(StreamServiceError.noMatchFound(id: title)))
                return
            }
            
            self.fetchStreamBySlug(slug: foundSlug, season: season, episode: episode, completion: completion)
        }.resume()
    }
    
    private func fetchStreamBySlug(slug: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        let urlString = "\(baseURL)/xem-phim/\(slug)"
        guard let url = URL(string: urlString) else {
            completion(.failure(StreamServiceError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(StreamServiceError.noData))
                return
            }
            
            // Tìm link m3u8 trong HTML
            if let range = html.range(of: "\"link\":\""),
               let endRange = html[range.upperBound...].range(of: "\"") {
                var link = String(html[range.upperBound..<endRange.lowerBound])
                link = link.replacingOccurrences(of: "\\/", with: "/")
                if let streamURL = URL(string: link) {
                    completion(.success(streamURL))
                    return
                }
            }
            completion(.failure(StreamServiceError.noStreamURL))
        }.resume()
    }
}