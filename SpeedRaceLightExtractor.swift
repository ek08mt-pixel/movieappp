import Foundation

class SpeedRaceLightExtractor {
    static let shared = SpeedRaceLightExtractor()
    private let baseAPI = "https://api.speedracelight.com"
    
    // MARK: - Models
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
    
    enum StreamError: Error, LocalizedError {
        case noStreamAvailable
        case decryptFailed
        case invalidResponse
        case seedExpired
        
        var errorDescription: String? {
            switch self {
            case .noStreamAvailable: return "Không tìm thấy stream"
            case .decryptFailed: return "Giải mã thất bại"
            case .invalidResponse: return "Response không hợp lệ"
            case .seedExpired: return "Seed hết hạn"
            }
        }
    }
    
    // MARK: - Server Endpoints
    private var servers: [(name: String, endpoint: String)] {
        [
            ("Yoru", "\(baseAPI)/cdn/sources-with-title"),
            ("Neon", "\(baseAPI)/vsrc/sources-with-title"),
            ("Breach", "\(baseAPI)/m4uhd/sources-with-title"),
            ("Cypher", "\(baseAPI)/downloader2/sources-with-title"),
            ("Vyse", "\(baseAPI)/hdmovie/sources-with-title")
        ]
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
        
        var debugLog = ""
        
        // Bước 1: Lấy seed
        let seed: String
        do {
            seed = try await fetchSeed(mediaId: tmdbId)
            debugLog += "✅ Seed OK: \(seed.prefix(20))...\n"
        } catch {
            debugLog += "❌ Seed fail: \(error.localizedDescription)\n"
            throw NSError(domain: "Videasy", code: 1, userInfo: [NSLocalizedDescriptionKey: debugLog])
        }
        
        // Bước 2: Thử từng server
        for server in servers {
            do {
                debugLog += "🔍 Thử \(server.name)...\n"
                
                let sources = try await fetchSources(
    endpoint: server.endpoint,
    title: title,
    mediaType: "movie",
    year: year,
    tmdbId: tmdbId,
    imdbId: imdbId,
    seasonId: nil,
    episodeId: nil,
    totalSeasons: nil,
    seed: seed
)
                
                debugLog += "   Sources: \(sources.sources?.count ?? 0)\n"
                
                if let m3u8URL = findBestM3U8(from: sources) {
                    debugLog += "✅ Tìm thấy m3u8!\n"
                    let subtitles = sources.subtitles ?? sources.tracks ?? []
                    return (m3u8URL, subtitles, server.name)
                } else {
                    debugLog += "   ❌ Không có m3u8\n"
                }
            } catch {
                debugLog += "   ❌ \(error.localizedDescription)\n"
            }
        }
        
        debugLog += "❌ Tất cả server thất bại"
        throw NSError(domain: "Videasy", code: 2, userInfo: [NSLocalizedDescriptionKey: debugLog])
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
            throw NSError(domain: "Seed", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP status không phải 200"])
        }
        
        // Kiểm tra error response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String {
            throw NSError(domain: "Seed", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
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
            // Bỏ qua season/episode cho movie
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
    throw NSError(domain: "Sources", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không phải HTTP response"])
}

guard httpResponse.statusCode == 200 else {
    // In response body để debug
    let bodyText = String(data: data, encoding: .utf8) ?? "Không đọc được"
    throw NSError(domain: "Sources", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(bodyText.prefix(200))"])
}
        
        // Kiểm tra nếu response là JSON error
        if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = jsonError["error"] as? String {
            throw NSError(domain: "Sources", code: 1, userInfo: [NSLocalizedDescriptionKey: "API: \(error)"])
        }
        
        // Decrypt response
        do {
            let decryptedData = try decrypt(data: data, seed: seed)
            let sourcesResponse = try JSONDecoder().decode(SourcesResponse.self, from: decryptedData)
            return sourcesResponse
        } catch {
            throw NSError(domain: "Decrypt", code: 2, userInfo: [NSLocalizedDescriptionKey: "Decrypt/parse: \(error.localizedDescription)"])
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
    
    // MARK: - Decrypt (RC4 + Base64)
    
    private func decrypt(data: Data, seed: String) throws -> Data {
    // Bước 1: Decode Base64 URL-safe
    guard let base64String = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "Decrypt", code: 3, userInfo: [NSLocalizedDescriptionKey: "Không thể convert data sang string"])
    }
    
    let normalized = base64String
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    
    let padded = normalized.padding(toLength: ((normalized.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
    
    guard let decodedData = Data(base64Encoded: padded) else {
        throw NSError(domain: "Decrypt", code: 4, userInfo: [NSLocalizedDescriptionKey: "Base64 decode failed"])
    }
    
    let bytes = [UInt8](decodedData)
    
    // Bước 2: Thuật toán từ JS
    // Constants
    let f: [UInt32] = [
        1116352408, 1899447441, 3049323471, 3921009573,
        961987163, 1508970993, 2453635748, 2870763221,
        3624381080, 310598401, 607225278, 1426881987,
        1925078388, 2162078206, 2614888103, 3248222580
    ]
    
    let h: [UInt8] = [109, 118, 109, 49] // "mvm1"
    
    // FNV hash của seed
    func fnvHash(_ str: String) -> UInt32 {
        var hash: UInt32 = 2166136261
        for byte in str.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16777619
        }
        return hash
    }
    
    func w(_ x: UInt32) -> UInt32 {
        var y = x
        y ^= y >> 16
        y = y &* 2246822507
        y ^= y >> 13
        y = y &* 3266489909
        y ^= y >> 16
        return y
    }
    
    func rotl(_ x: UInt32, _ n: Int) -> UInt32 {
        return (x << UInt32(n)) | (x >> UInt32(32 - n))
    }
    
    // Tạo S-box 61 phần tử
    var sBox = [UInt32](repeating: 0, count: 61)
    
    let seedHash = w(fnvHash(seed) ^ w(0 ^ 2654435769))
    
    var acc = seedHash
    
    for i in 0..<8 {
        if (i * (i + 1) & 1) == 0 {
            let idx = Int(acc % 61)
            acc = rotl((acc &+ 2654435769) & 0xFFFFFFFF, 7 + (7 & i))
            sBox[idx] = (acc ^ w(acc)) & 0xFFFFFFFF
            acc = w((acc &+ UInt32(idx)) & 0xFFFFFFFF)
        } else {
            sBox[i] = f[15 & i]
        }
    }
    
    var finalAcc = w(2779096485 ^ acc)
    
    // Giải mã
    var decrypted = [UInt8]()
    var byteIndex = 0
    
    for byte in bytes {
        let idx = Int(finalAcc % 61)
        
        var d = sBox[idx] & 0xFFFFFFFF
        let xorVal = (d ^ (2654435769 &* UInt32(byteIndex + 1))) & 0xFFFFFFFF
        
        let iVal = 0 - (idx in sBox ? 1 : 0)  // Trong Swift cần check index có trong range không
        
        let s = finalAcc
        let a = xorVal
        
        var l = (s ^ a) & 0xFFFFFFFF
        l = (l | ((s & a & UInt32(iVal)) & 0xFFFFFFFF)) & 0xFFFFFFFF
        
        let shifted = rotl((l &+ finalAcc) & 0xFFFFFFFF, 31 & idx)
        let shifted2 = rotl(finalAcc, 31 & (idx * 7))
        
        finalAcc = w((shifted ^ shifted2) &+ 2654435769)
        
        sBox[idx] = finalAcc
        
        decrypted.append(UInt8(byte ^ UInt8(finalAcc & 0xFF)))
        
        byteIndex += 1
    }
    
    // Bước 3: Kiểm tra magic bytes
    let magicBytes: [UInt8] = [109, 118, 109, 49]
    
    guard decrypted.count > magicBytes.count else {
        throw NSError(domain: "Decrypt", code: 5, userInfo: [NSLocalizedDescriptionKey: "Decrypted quá ngắn"])
    }
    
    for i in 0..<magicBytes.count {
        guard decrypted[i] == magicBytes[i] else {
            throw NSError(domain: "Decrypt", code: 6, userInfo: [NSLocalizedDescriptionKey: "Magic bytes sai tại \(i): expected \(magicBytes[i]) got \(decrypted[i])"])
        }
    }
    
    return Data(decrypted.dropFirst(magicBytes.count))
}
}