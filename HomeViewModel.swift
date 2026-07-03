import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var isLoading = false
    
    func loadAll() async {
        // Data fake để test giao diện
        trending = [
            Movie(id: 1, title: "Test Phim 1", overview: "Mô tả phim 1", posterPath: nil, backdropPath: nil, voteAverage: 8.5, releaseDate: "2024-01-01", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
            Movie(id: 2, title: "Test Phim 2", overview: "Mô tả phim 2", posterPath: nil, backdropPath: nil, voteAverage: 7.8, releaseDate: "2024-02-01", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
            Movie(id: 3, title: "Test Phim 3", overview: "Mô tả phim 3", posterPath: nil, backdropPath: nil, voteAverage: 9.0, releaseDate: "2024-03-01", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        ]
    }
}
