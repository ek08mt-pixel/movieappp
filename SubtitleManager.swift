import SwiftUI
import AVKit

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Subtitle Manager
class SubtitleManager: ObservableObject {
    static let shared = SubtitleManager()
    private let apiKey = "eVezeb6BgZxEM9Jqtb2kAeNiewyjl1jw"
    private let baseURL = "https://api.opensubtitles.com/api/v1"
    
    @AppStorage("subPosition") var position: SubPosition = .bottom
    @AppStorage("subColor") var colorHex: String = "#FFFF00"
    @AppStorage("subBackground") var background: SubBackground = .outline
    @AppStorage("subFontSize") var fontSizeDouble: Double = 16
    
    var fontSize: CGFloat {
        get { CGFloat(fontSizeDouble) }
        set { fontSizeDouble = Double(newValue) }
    }
    
    @Published var currentOffset: Double = 0
    @Published var isDownloading = false
    @Published var engSubtitleURL: URL?
    private var offsets: [String: Double] = [:]
    private var cache: [String: URL] = [:]
    
    var subtitleColor: Color {
        Color(hex: colorHex) ?? .yellow
    }
    
    enum SubPosition: String, CaseIterable {
        case top = "Trên"
        case middle = "Giữa"
        case bottom = "Dưới"
    }
    
    enum SubBackground: String, CaseIterable {
        case none = "Không nền"
        case outline = "Viền chữ"
        case darken = "Nền mờ"
    }
    
    // MARK: - Offset management
    func offsetKey(movieId: Int, season: Int?, episode: Int?) -> String {
        "\(movieId)_S\(season ?? 0)_E\(episode ?? 0)"
    }
    
    func loadOffset(movieId: Int, season: Int?, episode: Int?) {
        currentOffset = offsets[offsetKey(movieId: movieId, season: season, episode: episode)] ?? 0
    }
    
    func saveOffset(movieId: Int, season: Int?, episode: Int?, offset: Double) {
        offsets[offsetKey(movieId: movieId, season: season, episode: episode)] = offset
        currentOffset = offset
    }
    
    // MARK: - Download English subtitle
    func fetchEnglishSubtitle(imdbID: String, movieId: Int, season: Int?, episode: Int?) async -> URL? {
        let key = offsetKey(movieId: movieId, season: season, episode: episode)
        if let cached = cache[key] { return cached }
        
        isDownloading = true
        defer { isDownloading = false }
        
        // Search subtitle
        var searchURL = "\(baseURL)/subtitles?ai_translated=exclude&languages=en&imdb_id=\(imdbID)&order_by=download_count"
        if let s = season, let e = episode {
            searchURL += "&season_number=\(s)&episode_number=\(e)"
        }
        
        guard let url = URL(string: searchURL) else { return nil }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            struct SearchResponse: Codable { let data: [SubResult] }
            struct SubResult: Codable {
                let id: String
                let attributes: SubAttributes
            }
            struct SubAttributes: Codable {
                let download_count: Int
                let language: String
                let files: [SubFile]
            }
            struct SubFile: Codable {
                let file_id: Int
                let file_name: String
            }
            
            let result = try JSONDecoder().decode(SearchResponse.self, from: data)
            guard let best = result.data.first else { return nil }
            
            // Download subtitle file
            let downloadURL = "\(baseURL)/download"
            var dlRequest = URLRequest(url: URL(string: downloadURL)!)
            dlRequest.httpMethod = "POST"
            dlRequest.setValue(apiKey, forHTTPHeaderField: "Api-Key")
            dlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["file_id": best.attributes.files.first?.file_id ?? 0]
            dlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (dlData, _) = try await URLSession.shared.data(for: dlRequest)
            struct DLResponse: Codable { let link: String }
            let dlResult = try JSONDecoder().decode(DLResponse.self, from: dlData)
            
            guard let subURL = URL(string: dlResult.link) else { return nil }
            
            // Cache locally
            let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(key).srt")
            let (fileData, _) = try await URLSession.shared.data(from: subURL)
            try fileData.write(to: localURL)
            
            cache[key] = localURL
            return localURL
        } catch {
            print("Subtitle error: \(error)")
            return nil
        }
    }
}