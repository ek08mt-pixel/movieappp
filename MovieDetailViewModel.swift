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
            async let detailTask = APIService.shared.tvDetail(tvId: movieId)
            async let actorsTask = APIService.shared.actors(movieId: movieId, mediaType: "tv")
            async let similarTask = APIService.shared.similar(movieId: movieId, mediaType: "tv")
            async let imagesTask = APIService.shared.movieImages(movieId: movieId, mediaType: "tv")
            async let seasonsTask = APIService.shared.fetchTVSeasons(tvId: movieId)
            
            detail = try? await detailTask
            actors = (try? await actorsTask) ?? []
            similar = (try? await similarTask) ?? []
            images = (try? await imagesTask) ?? []
            seasons = (try? await seasonsTask) ?? []
        } else {
            async let detailTask = APIService.shared.movieDetail(movieId: movieId)
            async let actorsTask = APIService.shared.actors(movieId: movieId)
            async let similarTask = APIService.shared.similar(movieId: movieId)
            async let imagesTask = APIService.shared.movieImages(movieId: movieId)
            
            detail = try? await detailTask
            actors = (try? await actorsTask) ?? []
            similar = (try? await similarTask) ?? []
            images = (try? await imagesTask) ?? []
            
            // Load collection if exists
            if let collectionId = detail?.belongsToCollection?.id {
                if let colDetail = try? await APIService.shared.collectionDetail(collectionId: collectionId) {
                    collectionMovies = colDetail.parts.sorted { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }
                }
            }
        }
        isLoading = false
    }
    
    func loadSeasonDetail(tvId: Int, seasonNumber: Int) async {
        selectedSeason = try? await APIService.shared.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber)
    }
}