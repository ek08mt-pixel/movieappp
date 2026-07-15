import Foundation

final class CobePhimService {
    static let shared = CobePhimService()
    private let baseURL = "https://cobephim.sbs"
    
    func fetchStream(title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        // Chuyển title sang slug (cơ bản)
        let slug = title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .folding(options: .diacriticInsensitive, locale: .current)
        
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