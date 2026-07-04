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
    
    private let fakeMovies: [Movie] = [
        Movie(id: 1, title: "Avengers: Endgame", overview: "", posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", backdropPath: "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 2, title: "Spider-Man: No Way Home", overview: "", posterPath: "/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg", backdropPath: "/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg", voteAverage: 8.2, releaseDate: "2021", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 3, title: "Inception", overview: "", posterPath: "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", voteAverage: 8.8, releaseDate: "2010", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 4, title: "The Dark Knight", overview: "", posterPath: "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", backdropPath: "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", voteAverage: 9.0, releaseDate: "2008", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 5, title: "Interstellar", overview: "", posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", backdropPath: "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", voteAverage: 8.6, releaseDate: "2014", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 6, title: "Parasite", overview: "", posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", backdropPath: "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 7, title: "Joker", overview: "", posterPath: "/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg", backdropPath: "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg", voteAverage: 8.4, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 8, title: "The Matrix", overview: "", posterPath: "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg", backdropPath: "/fNG7i7RqMEr4p1o1gE5qMqK4KNU.jpg", voteAverage: 8.7, releaseDate: "1999", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 9, title: "Pulp Fiction", overview: "", posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg", backdropPath: "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg", voteAverage: 8.9, releaseDate: "1994", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 10, title: "Fight Club", overview: "", posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg", backdropPath: "/hZkgoQYus5dQoHw8oYrR4rKqNM.jpg", voteAverage: 8.8, releaseDate: "1999", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
    ]
    
    func loadAll() async {
        isLoading = true
        trending = fakeMovies
        nowPlaying = fakeMovies
        upcoming = fakeMovies
        topRated = fakeMovies
        popular = fakeMovies
        genres = [
            Genre(id: 28, name: "Hành động"),
            Genre(id: 12, name: "Phiêu lưu"),
            Genre(id: 16, name: "Hoạt hình"),
            Genre(id: 35, name: "Hài"),
            Genre(id: 80, name: "Hình sự"),
            Genre(id: 18, name: "Chính kịch"),
            Genre(id: 14, name: "Giả tưởng"),
            Genre(id: 27, name: "Kinh dị"),
            Genre(id: 878, name: "Khoa học viễn tưởng"),
            Genre(id: 53, name: "Giật gân"),
        ]
        isLoading = false
    }
}
