// File: HomeViewModel.swift
import Foundation

class HomeViewModel: ObservableObject {
    @Published var trendingMovies: [Movie] = []
    @Published var nowPlayingMovies: [Movie] = []
    
    @MainActor
    func loadMovies() async {
        do {
            // Giả sử APIService của bạn trả về dữ liệu
            // Hãy thêm lệnh print để debug trong Console của Xcode
            print("Đang bắt đầu tải phim...")
            
            let trending = try await APIService.shared.fetchTrending()
            let nowPlaying = try await APIService.shared.fetchNowPlaying()
            
            // Cập nhật lên UI
            self.trendingMovies = trending
            self.nowPlayingMovies = nowPlaying
            
            print("Đã tải xong: \(trending.count) phim xu hướng")
        } catch {
            print("Lỗi tải phim: \(error.localizedDescription)")
            // Dù lỗi, cũng nên gán mảng rỗng để thoát vòng xoay loading
            self.trendingMovies = []
            self.nowPlayingMovies = []
        }
    }
}
