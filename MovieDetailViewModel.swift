import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var trailerKey: String?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    @Published var images: [URL] = []
    @Published var detail: MovieDetail?
    @Published var seasons: [SeasonInfo] = []
    
    func load(movieId: Int, mediaType: String?) async {
        async let t = APIService.shared.trailer(movieId: movieId)
        async let a = APIService.shared.actors(movieId: movieId)
        async let s = APIService.shared.similar(movieId: movieId)
        async let i = APIService.shared.movieImages(movieId: movieId)
        async let d = APIService.shared.movieDetail(movieId: movieId)
        
        do {
            trailerKey = try await t
            actors = try await a
            similar = try await s
            images = try await i
            detail = try await d
            seasons = []
        } catch { print("Error: \(error)") }
        
        if let title = detail?.title {
            if let tvId = try? await APIService.shared.searchTVId(title: title) {
                if let tv = try? await APIService.shared.fetchTVSeasons(tvId: tvId) { seasons = tv }
            }
        }
    }
}