import Foundation

class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [Movie] = []
    @Published var nowPlayingMovies: [Movie] = []
    
    @MainActor
    func loadMovies() async {
        do {
            // Đảm bảo bạn bỏ dấu // ở 2 dòng dưới đây
            let trending = try await APIService.shared.fetchTrending()
            let nowPlaying = try await APIService.shared.fetchNowPlaying()
            
            // Gán dữ liệu vào biến @Published
            self.trendingMovies = trending
            self.nowPlayingMovies = nowPlaying
        } catch {
            print("Lỗi khi tải dữ liệu: \(error)")
        }
    }
}
