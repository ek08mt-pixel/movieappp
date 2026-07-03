import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        do {
            let t = try await APIService.shared.trending()
            let u = try await APIService.shared.upcoming()
            let n = try await APIService.shared.nowPlaying()
            let tr = try await APIService.shared.topRated()
            let g = try await APIService.shared.genres()
            
            trending = t
            upcoming = u
            nowPlaying = n
            topRated = tr
            genres = g
        } catch {
            print("Error: \(error)")
            trending = []
            upcoming = []
            nowPlaying = []
            topRated = []
            genres = []
        }
        
        isLoading = false
    }
}
