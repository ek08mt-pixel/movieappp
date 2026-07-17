import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var detail: MovieDetail?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    @Published var images: [URL] = []
    @Published var seasons: [TVSeason] = []
    @Published var selectedSeason: TVSeasonDetail?
    @Published var seasonDetails: [Int: TVSeasonDetail] = [:]
    @Published var collectionMovies: [Movie] = []
    @Published var isLoading = false
    
    // Cache video URLs
    private var videoURLCache: [String: URL] = [:]
    
    func load(movieId: Int, mediaType: String?) async {
        isLoading = true
        let type = mediaType ?? "movie"
        
        if type == "tv" {
            seasons = await loadSeasonsDirectly(tvId: movieId)
        } else {
            detail = try? await APIService.shared.movieDetail(movieId: movieId)
            if let collectionId = detail?.belongsToCollection?.id {
                if let colDetail = try? await APIService.shared.collectionDetail(collectionId: collectionId) {
                    collectionMovies = colDetail.parts.sorted { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }
                }
            }
        }
        isLoading = false
        
        async let actorsTask = APIService.shared.actors(movieId: movieId, mediaType: type)
        async let similarTask = APIService.shared.similar(movieId: movieId, mediaType: type)
        async let imagesTask = APIService.shared.movieImages(movieId: movieId, mediaType: type)
        
        actors = (try? await actorsTask) ?? []
        similar = (try? await similarTask) ?? []
        images = (try? await imagesTask) ?? []
    }
    
    func getVideoURL(movieId: Int, mediaType: String?, season: Int?, episode: Int?) async -> URL? {
        let cacheKey = "\(movieId)_\(mediaType ?? "movie")_S\(season ?? 0)E\(episode ?? 0)"
        if let cached = videoURLCache[cacheKey] {
            return cached
        }
        
        let type = mediaType ?? "movie"
        let urlString: String
        
        if type == "tv", let s = season, let e = episode {
            urlString = "https://phimapi.com/episode/\(movieId)?season=\(s)&episode=\(e)"
        } else {
            urlString = "https://phimapi.com/film/\(movieId)"
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Thử parse JSON trước
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Thử các field có thể chứa link video
                if let videoUrl = json["video"] as? String, !videoUrl.isEmpty,
                   let videoURL = URL(string: videoUrl) {
                    videoURLCache[cacheKey] = videoURL
                    return videoURL
                }
                if let streamUrl = json["url"] as? String, !streamUrl.isEmpty,
                   let streamURL = URL(string: streamUrl) {
                    videoURLCache[cacheKey] = streamURL
                    return streamURL
                }
                if let embedUrl = json["embed"] as? String, !embedUrl.isEmpty,
                   let embedURL = URL(string: embedUrl) {
                    videoURLCache[cacheKey] = embedURL
                    return embedURL
                }
            }
            
            // Thử parse HTML để tìm video source
            if let html = String(data: data, encoding: .utf8) {
                // Tìm .m3u8 trong HTML
                if let m3u8Range = html.range(of: "https?://[^\"'\\s]+\\.m3u8[^\"'\\s]*", options: .regularExpression) {
                    let m3u8URL = String(html[m3u8Range])
                    if let videoURL = URL(string: m3u8URL) {
                        videoURLCache[cacheKey] = videoURL
                        return videoURL
                    }
                }
                // Tìm src trong iframe hoặc video tag
                if let srcRange = html.range(of: "src=\"([^\"]+)\"", options: .regularExpression) {
                    let srcURL = String(html[srcRange]).replacingOccurrences(of: "src=\"", with: "").replacingOccurrences(of: "\"", with: "")
                    if let videoURL = URL(string: srcURL) {
                        videoURLCache[cacheKey] = videoURL
                        return videoURL
                    }
                }
            }
        } catch {
            print("Failed to get video URL: \(error)")
        }
        
        return nil
    }
    
    private func loadSeasonsDirectly(tvId: Int) async -> [TVSeason] {
        let urlString = "https://api.themoviedb.org/3/tv/\(tvId)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct TVDetailResponse: Codable { let seasons: [TVSeason]? }
            let response = try JSONDecoder().decode(TVDetailResponse.self, from: data)
            return response.seasons?.filter { $0.seasonNumber > 0 } ?? []
        } catch { return [] }
    }
    
    func loadSeasonDetail(tvId: Int, seasonNumber: Int) async {
        if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber) {
            selectedSeason = detail
            seasonDetails[seasonNumber] = detail
        }
    }
}