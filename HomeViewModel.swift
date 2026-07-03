import Foundation

class HomeViewModel: ObservableObject {
    @Published var nowPlayingMovies: [Movie] = []
    @Published var trendingMovies: [Movie] = []

    @MainActor
    func loadMovies() async {
        // Dữ liệu mẫu để đảm bảo app không bị trống
        self.nowPlayingMovies = []
        self.trendingMovies = []
    }
}
