import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    enum StreamError: Error, LocalizedError {
        case noStreamAvailable
        case movieNotFound
        case unsupportedURL
        
        var errorDescription: String? {
            switch self {
            case .noStreamAvailable: return "Không tìm thấy stream"
            case .movieNotFound: return "Không tìm thấy phim"
            case .unsupportedURL: return "URL không hợp lệ"
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
        
        // Thử tìm slug qua nhiều cách
        let slug = try await findSlug(tmdbID: tmdbID, title: title)
        print("✅ Slug: \(slug)")
        
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StreamError.movieNotFound
        }
        
        // TV show - episodes
        if let episodes = json["episodes"] as? [[String: Any]], !episodes.isEmpty {
            let s = season ?? 1
            let ep = episode ?? 1
            
            for episodeItem in episodes {
                if let epSeason = episodeItem["season"] as? Int, epSeason == s,
                   let epNumber = episodeItem["episode"] as? Int, epNumber == ep,
                   let sources = episodeItem["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String {
                    if let streamURL = URL(string: sourceURL) {
                        print("✅ Episode source: \(sourceURL.prefix(80))")
                        return try await processMasterPlaylist(streamURL)
                    }
                }
            }
        }
        
        // Movie - sources từ movie
        if let movie = json["movie"] as? [String: Any] {
            // Lấy hlsUrl từ movie
            if let hlsUrl = movie["hlsUrl"] as? String {
                if let streamURL = URL(string: hlsUrl) {
                    print("✅ Movie hlsUrl: \(hlsUrl.prefix(80))")
                    return try await processMasterPlaylist(streamURL)
                }
            }
            
            // Lấy sources từ movie
            if let sources = movie["sources"] as? [[String: Any]],
               let firstSource = sources.first,
               let sourceURL = firstSource["url"] as? String {
                if let streamURL = URL(string: sourceURL) {
                    print("✅ Movie source: \(sourceURL.prefix(80))")
                    return try await processMasterPlaylist(streamURL)
                }
            }
        }
        
        // Root sources
        if let sources = json["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String {
            if let streamURL = URL(string: sourceURL) {
                print("✅ Root source: \(sourceURL.prefix(80))")
                return try await processMasterPlaylist(streamURL)
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func findSlug(tmdbID: Int, title: String) async throws -> String {
        let cleanTitle = removeVietnameseDiacritics(title.lowercased())
        
        // Tạo nhiều search terms
        var searchTerms: [String] = [cleanTitle]
        let words = cleanTitle.components(separatedBy: " ")
        if let first = words.first { searchTerms.append(first) }
        if let last = words.last { searchTerms.append(last) }
        searchTerms.append(contentsOf: words.filter { $0.count > 3 })
        
        // Thử search qua /api/home
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
                        // Check tmdbId trước
                        if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID,
                           let slug = item["slug"] as? String {
                            print("✅ Tìm theo TMDB: \(slug)")
                            return slug
                        }
                        
                        // Check title
                        let enTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["en"] as? String ?? "").lowercased()
                        let viTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["vi"] as? String ?? "").lowercased()
                        let slug = item["slug"] as? String ?? ""
                        
                        if enTitle.contains(cleanTitle) || cleanTitle.contains(enTitle) ||
                           viTitle.contains(cleanTitle) || cleanTitle.contains(viTitle) ||
                           enTitle.contains(term) || viTitle.contains(term) ||
                           cleanTitle.contains(enTitle) || cleanTitle.contains(viTitle) {
                            print("✅ Tìm theo title: \(slug)")
                            return slug
                        }
                    }
                }
            } catch {
                continue
            }
        }
        
        // Fallback: tạo slug từ title
        let fallbackSlug = cleanTitle
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        print("🔍 Fallback slug: \(fallbackSlug)")
        return fallbackSlug
    }
    
    private func processMasterPlaylist(_ masterURL: URL) async throws -> URL {
        var request = URLRequest(url: masterURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        // Kiểm tra JSON response (không phải m3u8)
        if content.hasPrefix("{") || content.hasPrefix("[") {
            print("🔍 JSON response: \(content.prefix(300))")
            // Đây là JSON - có thể chứa URL m3u8
            if let jsonData = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let sources = json["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String,
                   let streamURL = URL(string: sourceURL) {
                    return try await processMasterPlaylist(streamURL)
                }
                if let movie = json["movie"] as? [String: Any],
                   let sources = movie["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String,
                   let streamURL = URL(string: sourceURL) {
                    return try await processMasterPlaylist(streamURL)
                }
            }
            throw StreamError.unsupportedURL
        }
        
        // Master playlist - có variant
        if content.contains("#EXT-X-STREAM-INF") {
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                    let variantURLString: String
                    if trimmed.hasPrefix("http") {
                        variantURLString = trimmed
                    } else {
                        let base = masterURL.deletingLastPathComponent().absoluteString
                        variantURLString = "\(base)/\(trimmed)"
                    }
                    
                    if let url = URL(string: variantURLString) {
                        return try await processVariantPlaylist(url)
                    }
                }
            }
        }
        
        // Trả về chính nó nếu là variant trực tiếp
        return masterURL
    }
    
    private func processVariantPlaylist(_ variantURL: URL) async throws -> URL {
        var request = URLRequest(url: variantURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let absoluteURL: String
                if trimmed.hasPrefix("http") {
                    var fixed = trimmed
                    // Sửa // thừa giữa URL (không phải https://)
                    if let schemeRange = fixed.range(of: "://") {
                        let prefix = String(fixed[..<schemeRange.upperBound])
                        let rest = String(fixed[schemeRange.upperBound...])
                        fixed = prefix + rest.replacingOccurrences(of: "//", with: "/")
                    }
                    absoluteURL = fixed
    }
                } else {
                    let base = variantURL.deletingLastPathComponent().absoluteString
                    let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
                    let cleanPath = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
                    absoluteURL = "\(cleanBase)/\(cleanPath)"
                }
                newLines.append(absoluteURL)
            } else {
                newLines.append(line)
            }
        }
        
        let localContent = newLines.joined(separator: "\n")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
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