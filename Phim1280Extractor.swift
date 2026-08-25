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
        
        if let s = season, let ep = episode {
            return try await fetchEpisodeStream(
                tmdbID: tmdbID,
                title: title,
                season: s,
                episode: ep
            )
        }
        
        return try await fetchMovieStream(tmdbID: tmdbID, title: title)
    }
    
    // MARK: - Fetch Movie Stream
    
    private func fetchMovieStream(tmdbID: Int, title: String) async throws -> URL {
    let cleanTitle = removeVietnameseDiacritics(title.lowercased())
    let words = cleanTitle.components(separatedBy: " ")
    
    // Bước 1: Tìm qua /api/home với từ khóa ngắn
    for word in words where word.count > 3 {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let homeURL = "\(baseURL)/api/home?q=\(encoded)"
        
        guard let url = URL(string: homeURL) else { continue }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var allItems: [[String: Any]] = []
                
                if let list = json["list"] as? [[String: Any]] {
                    allItems.append(contentsOf: list)
                }
                if let hero = json["hero"] as? [[String: Any]] {
                    allItems.append(contentsOf: hero)
                }
                if let top = json["top"] as? [[String: Any]] {
                    allItems.append(contentsOf: top)
                }
                
                for item in allItems {
                    if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID,
                       let slug = item["slug"] as? String {
                        print("✅ Tìm thấy slug qua /api/home: \(slug)")
                        return try await fetchStreamBySlug(slug)
                    }
                }
                
                // Tìm theo title
                let normalizedTitle = cleanTitle.trimmingCharacters(in: .whitespaces)
                for item in allItems {
                    if let titleObj = item["title"] as? [String: Any] {
                        let enTitle = (titleObj["en"] as? String ?? "").lowercased()
                        let viTitle = (titleObj["vi"] as? String ?? "").lowercased()
                        
                        if enTitle.contains(normalizedTitle) || normalizedTitle.contains(enTitle) ||
                           viTitle.contains(normalizedTitle) || normalizedTitle.contains(viTitle),
                           let slug = item["slug"] as? String {
                            print("✅ Tìm thấy slug theo title: \(slug)")
                            return try await fetchStreamBySlug(slug)
                        }
                    }
                }
            }
        } catch {
            continue
        }
    }
    
    // Bước 2: Thử slug trực tiếp
    // ... code slug cũ ...
    
    throw NSError(domain: "Phim1280", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy. Words: \(words)"])
}

private func fetchStreamBySlug(_ slug: String) async throws -> URL {
    let watchURL = "\(baseURL)/api/watch/\(slug)"
    guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw StreamError.movieNotFound
    }
    
    if let movie = json["movie"] as? [String: Any],
       let sources = movie["sources"] as? [[String: Any]],
       let firstSource = sources.first,
       let sourceURL = firstSource["url"] as? String,
       let streamURL = URL(string: sourceURL) {
        return try await processMasterPlaylist(streamURL)
    }
    
    if let sources = json["sources"] as? [[String: Any]],
       let firstSource = sources.first,
       let sourceURL = firstSource["url"] as? String,
       let streamURL = URL(string: sourceURL) {
        return try await processMasterPlaylist(streamURL)
    }
    
    throw StreamError.noStreamAvailable
}
    
    // MARK: - Fetch Episode Stream
    
    private func fetchEpisodeStream(
        tmdbID: Int,
        title: String,
        season: Int,
        episode: Int
    ) async throws -> URL {
        
        let slug = try await findSlug(tmdbID: tmdbID, title: title)
        
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let episodes = json["episodes"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        for ep in episodes {
            if let epSeason = ep["season"] as? Int, epSeason == season,
               let epNumber = ep["episode"] as? Int, epNumber == episode,
               let sources = ep["sources"] as? [[String: Any]],
               let firstSource = sources.first,
               let sourceURL = firstSource["url"] as? String,
               let streamURL = URL(string: sourceURL) {
                print("✅ Episode stream: \(sourceURL.prefix(100))")
                return try await processMasterPlaylist(streamURL)
            }
        }
        
        throw StreamError.movieNotFound
    }
    
    // MARK: - Find Slug
    
    private func findSlug(tmdbID: Int, title: String) async throws -> String {
        let fallbackSlug = removeVietnameseDiacritics(title.lowercased())
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
    
    // MARK: - Process Master Playlist
    
    private func processMasterPlaylist(_ masterURL: URL) async throws -> URL {
        var request = URLRequest(url: masterURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        print("📄 Master m3u8: \(content.prefix(300))")
        
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
                    print("🎯 Variant URL: \(variantURLString)")
                    return try await processVariantPlaylist(url)
                }
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - Process Variant Playlist
    
    private func processVariantPlaylist(_ variantURL: URL) async throws -> URL {
        var request = URLRequest(url: variantURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        print("📄 Variant m3u8 (first 300): \(content.prefix(300))")
        
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let absoluteURL: String
                if trimmed.hasPrefix("http") {
                    absoluteURL = trimmed
                        .replacingOccurrences(of: "//", with: "/")
                        .replacingOccurrences(of: "https:/", with: "https://")
                        .replacingOccurrences(of: "http:/", with: "http://")
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
        let fileURL = tempDir.appendingPathComponent("film4k_variant_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("✅ Local variant saved: \(fileURL)")
        
        return fileURL
    }
    
    // MARK: - Remove Vietnamese Diacritics
    
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
            if let replacement = diacritics[char] {
                result.append(replacement)
            } else {
                result.append(char)
            }
        }
        return result
    }
}