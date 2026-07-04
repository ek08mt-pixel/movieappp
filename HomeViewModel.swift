import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        trending = [
            Movie(id: 1, title: "Test Phim 1", overview: "Mô tả", posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", backdropPath: "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", voteAverage: 8.5, releaseDate: "2024-01-01", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
            Movie(id: 2, title: "Test Phim 2", overview: "Mô tả", posterPath: "/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg", backdropPath: "/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg", voteAverage: 8.2, releaseDate: "2024-02-01", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        ]
        nowPlaying = trending
        upcoming = trending
        topRated = trending
        popular = trending
        genres = [Genre(id: 1, name: "Hành động"), Genre(id: 2, name: "Hài")]
        isLoading = false
    }
}
