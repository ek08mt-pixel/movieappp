import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var trailerKey: String?
    @Published var actors: [Actor] = []
    @Published var similar: [Movie] = []
    
    func load(movieId: Int) async {
        do {
            trailerKey = try await APIService.shared.trailer(movieId: movieId)
        } catch {
            print("Trailer error: \(error)")
        }
        
        do {
            actors = try await APIService.shared.actors(movieId: movieId)
        } catch {
            print("Actors error: \(error)")
        }
        
        do {
            similar = try await APIService.shared.similar(movieId: movieId)
        } catch {
            print("Similar error: \(error)")
        }
    }
}
