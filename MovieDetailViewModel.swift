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
    
    func getVideoURL(movieId: Int, mediaType: String?, season: Int?, episode: Int?, title: String = "") async -> URL? {
    let cacheKey = "\(movieId)_\(mediaType ?? "movie")_S\(season ?? 0)E\(episode ?? 0)"
    if let cached = videoURLCache[cacheKey] {
        return cached
    }
    
    let s = season ?? 1
    let ep = episode ?? 1
    let type = mediaType ?? "movie"
    
    let imdbID: String
    if type == "tv" {
        imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movieId)) ?? ""
    } else {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
        if let url = URL(string: urlString),
           let (data, _) = try? await URLSession.shared.data(from: url) {
            struct E: Codable { let imdb_id: String? }
            imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
        } else {
            imdbID = ""
        }
    }
    
    guard !imdbID.isEmpty else { return nil }
    
    return await withCheckedContinuation { continuation in
        PhimAPIService.shared.fetchStream(
            imdbID: imdbID,
            tmdbID: movieId,
            title: title,  // <<< SỬA: truyền title thật
            mediaType: type,
            season: s,
            episode: ep,
            serverIndex: 0
        ) { result in
            switch result {
            case .success(let (url, _)):
                self.videoURLCache[cacheKey] = url
                continuation.resume(returning: url)
            case .failure:
                continuation.resume(returning: nil)
            }
        }
    }
}
        
        // Dùng PhimAPIService để lấy stream
        return await withCheckedContinuation { continuation in
            PhimAPIService.shared.fetchStream(
                imdbID: imdbID,
                tmdbID: movieId,
                title: "",
                mediaType: type,
                season: s,
                episode: ep,
                serverIndex: 0
            ) { result in
                switch result {
                case .success(let (url, _)):
                    self.videoURLCache[cacheKey] = url
                    continuation.resume(returning: url)
                case .failure:
                    // Fallback sang Sofaflix
                    SofaflixService.shared.fetchStream(
                        imdbID: imdbID,
                        tmdbID: movieId,
                        title: "",
                        mediaType: type,
                        season: s,
                        episode: ep
                    ) { result in
                        switch result {
                        case .success(let url):
                            self.videoURLCache[cacheKey] = url
                            continuation.resume(returning: url)
                        case .failure:
                            continuation.resume(returning: nil)
                        }
                    }
                }
            }
        }
    }
    
    func getDebugInfo(movieId: Int, mediaType: String?, season: Int?, episode: Int?) async -> String {
        let type = mediaType ?? "movie"
        let s = season ?? 1
        let ep = episode ?? 1
        
        var info = "TMDB ID: \(movieId)\nType: \(type)\nSeason: \(s)\nEpisode: \(ep)\n\n"
        
        // Lấy imdbID
        let imdbID: String
        if type == "tv" {
            imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movieId)) ?? "N/A"
        } else {
            let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
            if let url = URL(string: urlString),
               let (data, _) = try? await URLSession.shared.data(from: url) {
                struct E: Codable { let imdb_id: String? }
                imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? "N/A"
            } else {
                imdbID = "N/A"
            }
        }
        
        info += "IMDB ID: \(imdbID)\n\n"
        
        // Kiểm tra cache
        let cacheKey = "\(movieId)_S\(s)E\(ep)_server0"
        if let cached = MappingCache.shared.dict(for: "phimapi_stream_cache")[cacheKey] {
            info += "PhimAPI cache: ✅\n\(cached.prefix(80))...\n"
        } else {
            info += "PhimAPI cache: ❌\n"
        }
        
        if let cached = MappingCache.shared.getSofaflixURL(tmdbID: movieId, season: s, episode: ep) {
            info += "Sofaflix cache: ✅\n\(cached.prefix(80))...\n"
        } else {
            info += "Sofaflix cache: ❌\n"
        }
        
        guard !imdbID.isEmpty, imdbID != "N/A" else {
            info += "\nKhông có IMDB ID để test"
            return info
        }
        
        return await withCheckedContinuation { continuation in
            PhimAPIService.shared.fetchStream(
                imdbID: imdbID,
                tmdbID: movieId,
                title: "test",
                mediaType: type,
                season: s,
                episode: ep,
                serverIndex: 0
            ) { result in
                switch result {
                case .success(let (url, servers)):
                    info += "\n✅ PhimAPI OK\nURL: \(url.absoluteString.prefix(100))...\nServers: \(servers.joined(separator: ", "))"
                    continuation.resume(returning: info)
                case .failure(let error):
                    info += "\n❌ PhimAPI: \(error.localizedDescription)"
                    continuation.resume(returning: info)
                }
            }
        }
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