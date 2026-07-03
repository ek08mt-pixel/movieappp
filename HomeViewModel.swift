import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var genres: [Genre] = []
    
    func loadAll() async {
        async let t = APIService.shared.trending()
        async let u = APIService.shared.upcoming()
        async let n = APIService.shared.nowPlaying()
        async let tr = APIService.shared.topRated()
        async let g = APIService.shared.genres()
        
        do {
            trending = try await t
            upcoming = try await u
            nowPlaying = try await n
            topRated = try await tr
            genres = try await g
        } catch {
            print("Error: \(error)")
        }
    }
}
