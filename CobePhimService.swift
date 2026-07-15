// CobePhimService.swift
class CobePhimService {
    static let shared = CobePhimService()
    private let baseURL = "https://cobephim.sbs"
    
    func fetchStream(slug: String, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let urlString = "\(baseURL)/xem-phim/\(slug)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            
            // Tìm JSON chứa link m3u8
            if let range = html.range(of: "\"link\":\""),
               let endRange = html[range.upperBound...].range(of: "\"") {
                var link = String(html[range.upperBound..<endRange.lowerBound])
                link = link.replacingOccurrences(of: "\\/", with: "/")
                if let streamURL = URL(string: link) {
                    completion(.success(streamURL))
                    return
                }
            }
            completion(.failure(NSError(domain: "Not found", code: -1)))
        }.resume()
    }
}