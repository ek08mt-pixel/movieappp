import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    enum StreamError: Error, LocalizedError {
        case noStreamAvailable
        case movieNotFound
        
        var errorDescription: String? {
            switch self {
            case .noStreamAvailable: return "Không tìm thấy stream"
            case .movieNotFound: return "Không tìm thấy phim"
            }
        }
    }
    
    func fetchStream(
        tmdbID: Int,
        title: String,
        mediaType: String?,
        season: Int? = nil,
        episode: Int? = nil
    ) async throws -> URL {
        return try await fetchMovieStream(tmdbID: tmdbID, title: title)
    }
    
    private func fetchMovieStream(tmdbID: Int, title: String) async throws -> URL {
        let cleanTitle = removeVietnameseDiacritics(title.lowercased())
        
        // Thử tìm qua /api/home với từng từ khóa
        let words = cleanTitle.components(separatedBy: " ")
        let searchTerms = [cleanTitle] + words.filter { $0.count > 3 }
        
        for term in searchTerms {
            let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let homeURL = "\(baseURL)/api/home?q=\(encoded)"
            guard let url = URL(string: homeURL) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    var allItems: [[String: Any]] = []
                    if let list = json["list"] as? [[String: Any]] { allItems += list }
                    if let hero = json["hero"] as? [[String: Any]] { allItems += hero }
                    if let top = json["top"] as? [[String: Any]] { allItems += top }
                    
                    for item in allItems {
                        // Lấy title từ item
                        let enTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["en"] as? String ?? "").lowercased()
                        let viTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["vi"] as? String ?? "").lowercased()
                        let slug = item["slug"] as? String ?? ""
                        
                        // So sánh title
                        if enTitle.contains(cleanTitle) || cleanTitle.contains(enTitle) ||
                           viTitle.contains(cleanTitle) || cleanTitle.contains(viTitle) ||
                           enTitle.contains(term) || term.contains(enTitle) {
                            print("✅ Tìm thấy: \(slug)")
                            return try await fetchStreamBySlug(slug)
                        }
                    }
                }
            } catch {
                continue
            }
        }
        
        throw NSError(domain: "Phim1280", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy: \(title)"])
    }
    
    private func fetchStreamBySlug(_ slug: String) async throws -> URL {
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StreamError.movieNotFound
        }
        
        // Lấy trực tiếp CDN link
        if let movie = json["movie"] as? [String: Any],
           let sources = movie["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String,
           let streamURL = URL(string: sourceURL) {
            return streamURL
        }
        
        if let sources = json["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String,
           let streamURL = URL(string: sourceURL) {
            return streamURL
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func removeVietnameseDiacritics(_ text: String) -> String {
        let diacritics: [Character: String] = [
            "à": "a", "á": "a", "ả": "a", "ã": "a", "ạ": "a",
            "ă": "a", "ằ": "a", "ắ": "a", "ẳ": "a", "ẵ": "a", "ặ": "a",
            "â": "a", "ầ": "a", "ấ": "a", "ẩ": "a", "ẫ": "a", "ậ": "a",
            "è": "e", "é": "e", "ẻ": "e", "ẽ": "e", "ẹ": "e",
            "ê": "e", "ề": "e", "ế": "e", "ể": "e", "ễ": "e", "ệ": "e",
            "ì": "i", "í": "i", "ỉ": "i", "ĩ": "i", "ị": "i",
            "ò": "o", "ó": "o", "ỏ": "o", "õ": "o", "ọ": "o",
            "ô": "o", "ồ": "o", "ố": "o", "ổ": "o", "ỗ": "o", "ộ": "o",
            "ơ": "o", "ờ": "o", "ớ": "o", "ở": "o", "ỡ": "o", "ợ": "o",
            "ù": "u", "ú": "u", "ủ": "u", "ũ": "u", "ụ": "u",
            "ư": "u", "ừ": "u", "ứ": "u", "ử": "u", "ữ": "u", "ự": "u",
            "ỳ": "y", "ý": "y", "ỷ": "y", "ỹ": "y", "ỵ": "y",
            "đ": "d"
        ]
        var result = ""
        for char in text {
            if let replacement = diacritics[char] { result += replacement }
            else { result += String(char) }
        }
        return result
    }
}