import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var detail: MovieDetail?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    @Published var images: [URL] = []
    @Published var seasons: [TVSeason] = []
    @Published var selectedSeason: TVSeasonDetail?
    @Published var collectionMovies: [Movie] = []
    @Published var isLoading = false
    
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
    
    private func loadSeasonsDirectly(tvId: Int) async -> [TVSeason] {
        let urlString = "https://api.themoviedb.org/3/tv/\(tvId)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct TVDetailResponse: Codable {
                let seasons: [TVSeason]?
            }
            let response = try JSONDecoder().decode(TVDetailResponse.self, from: data)
            return response.seasons?.filter { $0.seasonNumber > 0 } ?? []
        } catch {
            return []
        }
    }
    
    func loadSeasonDetail(tvId: Int, seasonNumber: Int) async {
        selectedSeason = try? await APIService.shared.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber)
    }
}