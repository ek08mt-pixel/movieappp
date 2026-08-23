import Foundation

class SpeedRaceLightExtractor {
    static let shared = SpeedRaceLightExtractor()
    private let baseAPI = "https://api.speedracelight.com"
    
    struct SeedResponse: Codable {
        let seed: String
        let ttlMs: Int?
    }
    
    struct StreamSource: Codable {
        let url: String?
        let quality: String?
        let type: String?
        let language: String?
        let label: String?
        let file: String?
    }
    
    struct Subtitle: Codable {
        let url: String?
        let language: String?
        let lang: String?
        let label: String?
    }
    
    struct SourcesResponse: Codable {
        let sources: [StreamSource]?
        let subtitles: [Subtitle]?
        let tracks: [Subtitle]?
    }
    
    enum StreamError: Error {
        case noStreamAvailable
        case decryptFailed
        case invalidResponse
        case seedExpired
    }
    
    // MARK: - Public Method
    
    func extractM3U8(
        tmdbId: Int,
        title: String,
        year: String? = nil,
        imdbId: String? = nil,
        mediaType: String = "movie",
        seasonId: String? = nil,
        episodeId: String? = nil,
        totalSeasons: String? = nil
    ) async throws -> (streamURL: URL, subtitles: [Subtitle], serverName: String) {
        
        let seed = try await fetchSeed(mediaId: tmdbId)
        
        let servers: [(name: String, endpoint: String)] = [
            ("Yoru", "\(baseAPI)/cdn/sources-with-title"),
            ("Neon", "\(baseAPI)/vsrc/sources-with-title"),
            ("Breach", "\(baseAPI)/m4uhd/sources-with-title"),
            ("Cypher", "\(baseAPI)/downloader2/sources-with-title"),
            ("Vyse", "\(baseAPI)/hdmovie/sources-with-title")
        ]
        
        for server in servers {
            do {
                let sources = try await fetchSources(
                    endpoint: server.endpoint,
                    title: title,
                    mediaType: mediaType,
                    year: year,
                    tmdbId: tmdbId,
                    imdbId: imdbId,
                    seasonId: seasonId,
                    episodeId: episodeId,
                    totalSeasons: totalSeasons,
                    seed: seed
                )
                
                if let m3u8URL = findBestM3U8(from: sources) {
                    let subtitles = sources.subtitles ?? sources.tracks ?? []
                    return (m3u8URL, subtitles, server.name)
                }
            } catch {
                print("⚠️ Server \(server.name) failed: \(error.localizedDescription)")
                continue
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - Fetch Seed
    
    private func fetchSeed(mediaId: Int) async throws -> String {
        let urlString = "\(baseAPI)/seed?mediaId=\(mediaId)"
        guard let url = URL(string: urlString) else { throw StreamError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://player.videasy.to/", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StreamError.invalidResponse
        }
        
        let seedResponse = try JSONDecoder().decode(SeedResponse.self, from: data)
        return seedResponse.seed
    }
    
    // MARK: - Fetch Sources
    
    private func fetchSources(
        endpoint: String,
        title: String,
        mediaType: String,
        year: String?,
        tmdbId: Int,
        imdbId: String?,
        seasonId: String?,
        episodeId: String?,
        totalSeasons: String?,
        seed: String
    ) async throws -> SourcesResponse {
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "mediaType", value: mediaType),
            URLQueryItem(name: "year", value: year),
            URLQueryItem(name: "tmdbId", value: "\(tmdbId)"),
            URLQueryItem(name: "imdbId", value: imdbId),
            URLQueryItem(name: "totalSeasons", value: totalSeasons),
            URLQueryItem(name: "episodeId", value: episodeId),
            URLQueryItem(name: "seasonId", value: seasonId),
            URLQueryItem(name: "enc", value: "2"),
            URLQueryItem(name: "seed", value: seed)
        ]
        
        guard let url = components.url else { throw StreamError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://player.videasy.to/", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StreamError.invalidResponse
        }
        
        // Kiểm tra nếu response là JSON error
        if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = jsonError["error"] as? String {
            print("❌ API Error: \(error)")
            throw StreamError.seedExpired
        }
        
        // Decrypt response
        let decryptedData = try decrypt(data: data, seed: seed)
        
        // Parse JSON
        do {
            let sourcesResponse = try JSONDecoder().decode(SourcesResponse.self, from: decryptedData)
            return sourcesResponse
        } catch {
            print("❌ JSON decode error: \(error)")
            if let text = String(data: decryptedData, encoding: .utf8) {
                print("📄 Decrypted text: \(text.prefix(500))")
            }
            throw StreamError.invalidResponse
        }
    }
    
    // MARK: - Find Best M3U8
    
    private func findBestM3U8(from response: SourcesResponse) -> URL? {
        let sources = response.sources ?? []
        
        let m3u8Sources = sources.filter { source in
            guard let url = source.url?.lowercased() else { return false }
            return url.contains("m3u8") || source.type?.lowercased() == "m3u8" || source.file?.lowercased() == "m3u8"
        }
        
        let sorted = m3u8Sources.sorted { source1, source2 in
            let q1 = parseQuality(source1.quality ?? source1.label)
            let q2 = parseQuality(source2.quality ?? source2.label)
            return q1 > q2
        }
        
        return sorted.first?.url.flatMap(URL.init)
    }
    
    private func parseQuality(_ quality: String?) -> Int {
        guard let quality = quality?.lowercased() else { return 0 }
        if quality.contains("4k") || quality.contains("2160") { return 2160 }
        if quality.contains("1440") { return 1440 }
        if quality.contains("1080") || quality.contains("fhd") { return 1080 }
        if quality.contains("720") || quality.contains("hd") { return 720 }
        if quality.contains("480") || quality.contains("sd") { return 480 }
        if quality.contains("360") { return 360 }
        return 0
    }
    
    // MARK: - Decrypt (Chính xác từ JS)
    
    private func decrypt(data: Data, seed: String) throws -> Data {
        // Bước 1: Decode Base64 URL-safe
        guard let base64String = String(data: data, encoding: .utf8) else {
            throw StreamError.decryptFailed
        }
        
        let normalized = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padded = normalized.padding(toLength: ((normalized.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let decodedData = Data(base64Encoded: padded) else {
            throw StreamError.decryptFailed
        }
        
        // Bước 2: RC4 decrypt
        let keyBytes = Array(seed.utf8)
        var sBox = Array(0...255)
        var j = 0
        
        for i in 0..<256 {
            j = (j + sBox[i] + Int(keyBytes[i % keyBytes.count])) & 255
            sBox.swapAt(i, j)
        }
        
        var decrypted = [UInt8](repeating: 0, count: decodedData.count)
        var i = 0
        j = 0
        
        for k in 0..<decodedData.count {
            i = (i + 1) & 255
            j = (j + sBox[i]) & 255
            sBox.swapAt(i, j)
            let t = (sBox[i] + sBox[j]) & 255
            decrypted[k] = decodedData[k] ^ UInt8(sBox[t])
        }
        
        // Bước 3: Kiểm tra magic bytes [109, 118, 109, 49] = "mvm1"
        let magicBytes: [UInt8] = [109, 118, 109, 49]
        guard decrypted.count > magicBytes.count else {
            throw StreamError.decryptFailed
        }
        
        for i in 0..<magicBytes.count {
            guard decrypted[i] == magicBytes[i] else {
                print("❌ Magic bytes mismatch at position \(i): expected \(magicBytes[i]) got \(decrypted[i])")
                throw StreamError.decryptFailed
            }
        }
        
        // Bước 4: Bỏ 4 byte magic
        return Data(decrypted.dropFirst(magicBytes.count))
    }
}