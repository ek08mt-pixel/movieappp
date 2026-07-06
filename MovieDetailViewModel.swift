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
        
        // Load detail trước
        if type == "tv" {
            detail = try? await APIService.shared.tvDetail(tvId: movieId)
        } else {
            detail = try? await APIService.shared.movieDetail(movieId: movieId)
        }
        isLoading = false
        
        // Load collection ngay sau detail
        if let collectionId = detail?.belongsToCollection?.id {
            if let colDetail = try? await APIService.shared.collectionDetail(collectionId: collectionId) {
                collectionMovies = colDetail.parts.sorted { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }
            }
        }
        
        // Load seasons nếu là TV
        if type == "tv" {
            seasons = (try? await APIService.shared.fetchTVSeasons(tvId: movieId)) ?? []
        }
        
        // Load các phần còn lại song song
        async let actorsTask = APIService.shared.actors(movieId: movieId, mediaType: type)
        async let similarTask = APIService.shared.similar(movieId: movieId, mediaType: type)
        async let imagesTask = APIService.shared.movieImages(movieId: movieId, mediaType: type)
        
        actors = (try? await actorsTask) ?? []
        similar = (try? await similarTask) ?? []
        images = (try? await imagesTask) ?? []
    }
    
    func loadSeasonDetail(tvId: Int, seasonNumber: Int) async {
        selectedSeason = try? await APIService.shared.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber)
    }
}