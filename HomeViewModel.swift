import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var isLoading = false
    
    func loadAll() async {
        trending = [
            Movie(id: 1, title: "Avengers: Endgame", overview: "Sau các sự kiện tàn khốc của Infinity War...", posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", backdropPath: "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", voteAverage: 8.5, releaseDate: "2019-04-26", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
            Movie(id: 2, title: "Spider-Man: No Way Home", overview: "Peter Parker tìm đến Doctor Strange...", posterPath: "/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg", backdropPath: "/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg", voteAverage: 8.2, releaseDate: "2021-12-17", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
            Movie(id: 3, title: "Inception", overview: "Một tên trộm đánh cắp bí mật từ tiềm thức...", posterPath: "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", voteAverage: 8.8, releaseDate: "2010-07-16", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        ]
    }
}
