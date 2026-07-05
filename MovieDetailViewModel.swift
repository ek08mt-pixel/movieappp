import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var trailerKey: String?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    @Published var images: [URL] = []
    
    func load(movieId: Int) async {
        async let t = APIService.shared.trailer(movieId: movieId)
        async let a = APIService.shared.actors(movieId: movieId)
        async let s = APIService.shared.similar(movieId: movieId)
        async let i = APIService.shared.movieImages(movieId: movieId)
        
        do {
            trailerKey = try await t
            actors = try await a
            similar = try await s
            images = try await i
        } catch {
            print("Error: \(error)")
        }
    }
}