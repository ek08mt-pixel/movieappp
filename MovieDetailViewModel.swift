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
    @Published var serverList: [(name: String, qualities: [String])] = []
    @Published var isLoadingServers = false
    
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
    
    func loadServers(movieId: Int, mediaType: String?, title: String) async {
    isLoadingServers = true
    let imdbID: String
    if mediaType == "tv" {
        imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movieId)) ?? ""
    } else {
        let (data, _) = try! await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
    }
    guard !imdbID.isEmpty else { await MainActor.run { isLoadingServers = false }; return }
    
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movieId, title: title, mediaType: mediaType, season: nil, episode: nil, serverIndex: 0) { result in
            switch result {
            case .success(let (_, servers)):
                var list: [(name: String, qualities: String)] = []
                for s in servers {
                    let q = self.detectQualityString(s)
                    list.append((name: s, qualities: q))
                }
                if list.isEmpty {
                    list = [
                        ("Vietsub", "4K • 2160p • 1080p • 720p"),
                        ("Lồng tiếng", "1080p • 720p"),
                        ("Thuyết minh", "4K • 2160p • 1080p • 720p")
                    ]
                }
                DispatchQueue.main.async { self.serverList = list; self.isLoadingServers = false }
            case .failure:
                DispatchQueue.main.async {
                    self.serverList = [
                        ("Vietsub", "4K • 2160p • 1080p • 720p"),
                        ("Lồng tiếng", "1080p • 720p"),
                        ("Thuyết minh", "4K • 2160p • 1080p • 720p")
                    ]
                    self.isLoadingServers = false
                }
            }
            cont.resume()
        }
    }
}

func detectQualityString(_ name: String) -> String {
    var qualities: [String] = []
    if name.contains("4K") || name.contains("2160") { qualities.append(contentsOf: ["4K", "2160p"]) }
    if name.contains("2880") { qualities.append("2880p") }
    if name.contains("1440") { qualities.append("1440p") }
    if name.contains("1080") { qualities.append("1080p") }
    if name.contains("720") { qualities.append("720p") }
    if name.contains("480") { qualities.append("480p") }
    if qualities.isEmpty { qualities = ["1080p", "720p"] }
    return qualities.joined(separator: " • ")
}
    
    func getVideoURL(movieId: Int, mediaType: String?, season: Int?, episode: Int?, title: String = "") async -> URL? {
        let cacheKey = "\(movieId)_\(mediaType ?? "movie")_S\(season ?? 0)E\(episode ?? 0)"
        if let cached = videoURLCache[cacheKey] { return cached }
        let s = season ?? 1; let ep = episode ?? 1; let type = mediaType ?? "movie"
        let imdbID: String
        if type == "tv" { imdbID = (try? await APIService.shared.fetchExternalIDs(tvId: movieId)) ?? "" }
        else {
            let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
            if let url = URL(string: urlString), let (data, _) = try? await URLSession.shared.data(from: url) {
                struct E: Codable { let imdb_id: String? }
                imdbID = (try? JSONDecoder().decode(E.self, from: data).imdb_id) ?? ""
            } else { imdbID = "" }
        }
        guard !imdbID.isEmpty else { return nil }
        return await withCheckedContinuation { continuation in
            OphimService.shared.fetchStream(title: title, season: s, episode: ep) { result in
                switch result {
                case .success(let url): self.videoURLCache[cacheKey] = url; continuation.resume(returning: url)
                case .failure: continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func loadSeasonDetail(tvId: Int, seasonNumber: Int) async {
        if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber) {
            selectedSeason = detail; seasonDetails[seasonNumber] = detail
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
}