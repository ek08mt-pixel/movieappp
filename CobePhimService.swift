func fetchStream(title: String, completion: @escaping (Result<URL, Error>) -> Void) {
    let slug = title.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .folding(options: .diacriticInsensitive, locale: .current)
    
    let urlString = "\(baseURL)/xem-phim/\(slug)"
    guard let url = URL(string: urlString) else { return }
    
    URLSession.shared.dataTask(with: url) { data, _, error in
        guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
        
        // Parse self.__next_f.push data để lấy JSON
        // Tìm pattern: "link\":\"...m3u8\"
        let pattern = "\"link\":\"[^\"]*\\.m3u8[^\"]*\""
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
            let matchStr = (html as NSString).substring(with: match.range)
            let link = matchStr
                .replacingOccurrences(of: "\"link\":\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\\/", with: "/")
            if let streamURL = URL(string: link) {
                completion(.success(streamURL))
                return
            }
        }
        completion(.failure(StreamServiceError.noStreamURL))
    }.resume()
}