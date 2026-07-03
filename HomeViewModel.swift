import Foundation

class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [Movie] = []
    @Published var nowPlayingMovies: [Movie] = []
    
    @MainActor
    func loadMovies() async {
        do {
            self.trendingMovies = try await APIService.shared.fetchTrending()
            self.nowPlayingMovies = try await APIService.shared.fetchNowPlaying()
        } catch {
            print("Không thể tải dữ liệu: \(error)")
        }
    }
}
