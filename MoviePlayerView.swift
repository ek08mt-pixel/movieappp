import SwiftUI
import AVKit

class MovieStreamService {
    static let shared = MovieStreamService()
    
    func fetchNguonCEmbed(title: String, episode: Int, movieId: Int, mediaType: String?) async throws -> (URL, String) {
        var searchTitle = title
        if let viName = try? await getVietnameseTitle(movieId: movieId, mediaType: mediaType) {
            searchTitle = viName
        }
        var allSlugs = try await findAllNguonCSlugs(title: searchTitle)
        if allSlugs.isEmpty { allSlugs = try await findAllNguonCSlugs(title: title) }
        
        for item in allSlugs {
            guard let dtUrl = URL(string: "https://phim.nguonc.com/api/film/\(item.slug)") else { continue }
            var req = URLRequest(url: dtUrl)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            do {
                let (dd, _) = try await URLSession.shared.data(for: req)
                struct NguonCResponse: Codable { let movie: NguonCMovie? }
                struct NguonCMovie: Codable { let name: String?; let episodes: [NguonCServer]? }
                struct NguonCServer: Codable { let server_name: String?; let items: [NguonCItem]? }
                struct NguonCItem: Codable { let name: String?; let embed: String? }
                if let response = try? JSONDecoder().decode(NguonCResponse.self, from: dd),
                   let servers = response.movie?.episodes {
                    for server in servers {
                        guard let items = server.items else { continue }
                        for item in items {
                            guard let itemName = item.name, !itemName.isEmpty,
                                  let embed = item.embed, !embed.isEmpty,
                                  let embedURL = URL(string: embed) else { continue }
                            // Chấp nhận FULL hoặc số tập khớp
                            if itemName == "FULL" || Int(itemName) == episode {
                                return (embedURL, response.movie?.name ?? title)
                            }
                        }
                    }
                }
            } catch {}
        }
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy tập này"])
    }
    
    private func getVietnameseTitle(movieId: Int, mediaType: String?) async throws -> String? {
        let type = (mediaType == "tv") ? "tv" : "movie"
        let urlStr = "https://api.themoviedb.org/3/\(type)/\(movieId)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=vi"
        guard let url = URL(string: urlStr) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct TMDBResponse: Codable { let name: String?; let title: String? }
        let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
        return response.name ?? response.title
    }
    
    private func findAllNguonCSlugs(title: String) async throws -> [(slug: String, name: String, originalName: String)] {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        guard let url = URL(string: "https://phim.nguonc.com/api/films/search?keyword=\(encoded)") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)
        struct SearchResponse: Codable { let items: [Item]? }
        struct Item: Codable { let slug: String?; let name: String?; let original_name: String? }
        if let response = try? JSONDecoder().decode(SearchResponse.self, from: data),
           let items = response.items, !items.isEmpty {
            return items.compactMap { item in
                guard let slug = item.slug else { return nil }
                return (slug, item.name ?? "", item.original_name ?? "")
            }
        }
        return []
    }
}

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    var mediaType: String?; @State var seasonNumber: Int?; @State var episodeNumber: Int?; var posterURL: URL?
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = true; @State private var errorMessage: String?
    @State private var showNguonCWebView = false
    @State private var nguonCEmbedURL: URL?
    @State private var nguonCEpisodeName = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đang tải...").font(.caption).foregroundColor(.white.opacity(0.7))
                    Button("Quay lại") { dismiss() }
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
            }
            
            if let err = errorMessage, !isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text(err).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                    Button("Thử lại") { loadStream() }
                        .font(.caption).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial))
                    Button("Quay lại") { dismiss() }
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
            }
        }
        .task { loadStream() }
        .fullScreenCover(isPresented: $showNguonCWebView) {
            if let url = nguonCEmbedURL {
                NguonCPlayerView(embedURL: url, episodeName: nguonCEpisodeName)
            }
        }
    }
    
    func loadStream() {
        let ep = episodeNumber ?? 1
        isLoading = true; errorMessage = nil
        Task {
            do {
                let (embedURL, movieName) = try await MovieStreamService.shared.fetchNguonCEmbed(
                    title: movieTitle, episode: ep, movieId: movieId, mediaType: mediaType
                )
                await MainActor.run {
                    nguonCEmbedURL = embedURL
                    nguonCEpisodeName = episodeNumber != nil ? "\(movieName) - Tập \(ep)" : movieName
                    isLoading = false
                    showNguonCWebView = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}