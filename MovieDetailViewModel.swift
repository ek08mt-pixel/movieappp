 import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var trailerKey: String?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    
    func load(movieId: Int) async {
        async let t = APIService.shared.trailer(movieId: movieId)
        async let a = APIService.shared.actors(movieId: movieId)
        async let s = APIService.shared.similar(movieId: movieId)
        
        do {
            trailerKey = try await t
            actors = try await a
            similar = try await s
        } catch {
            print("Detail error: \(error)")
        }
    }
}
