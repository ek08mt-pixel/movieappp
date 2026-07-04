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
    
    let allMovies: [Movie] = [
        Movie(id: 299534, title: "Avengers: Endgame", overview: "Sau các sự kiện tàn khốc của Infinity War, các Avengers tập hợp lại để đảo ngược hành động của Thanos và khôi phục vũ trụ.", posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", backdropPath: "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 634649, title: "Spider-Man: No Way Home", overview: "Peter Parker tìm đến Doctor Strange để giúp khôi phục danh tính bí mật của mình.", posterPath: "/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg", backdropPath: "/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg", voteAverage: 8.2, releaseDate: "2021", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 27205, title: "Inception", overview: "Một tên trộm đánh cắp bí mật từ tiềm thức của con người trong khi họ đang mơ.", posterPath: "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", voteAverage: 8.8, releaseDate: "2010", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 155, title: "The Dark Knight", overview: "Batman đối mặt với Joker - kẻ gây hỗn loạn ở Gotham.", posterPath: "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", backdropPath: "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", voteAverage: 9.0, releaseDate: "2008", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 157336, title: "Interstellar", overview: "Một nhóm phi hành gia du hành qua lỗ sâu để tìm hành tinh mới cho nhân loại.", posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", backdropPath: "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", voteAverage: 8.6, releaseDate: "2014", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 496243, title: "Parasite", overview: "Gia đình Kim nghèo khó dần thâm nhập vào gia đình Park giàu có.", posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", backdropPath: "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 475557, title: "Joker", overview: "Arthur Fleck, một diễn viên hài thất bại, dần trở thành Joker.", posterPath: "/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg", backdropPath: "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg", voteAverage: 8.4, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 603, title: "The Matrix", overview: "Một hacker phát hiện ra thế giới thực chỉ là một giả lập.", posterPath: "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg", backdropPath: "/fNG7i7RqMEr4p1o1gE5qMqK4KNU.jpg", voteAverage: 8.7, releaseDate: "1999", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 680, title: "Pulp Fiction", overview: "Những câu chuyện đan xen về tội phạm ở Los Angeles.", posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg", backdropPath: "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg", voteAverage: 8.9, releaseDate: "1994", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 550, title: "Fight Club", overview: "Một người đàn ông bất mãn tạo ra câu lạc bộ đánh nhau bí mật.", posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg", backdropPath: "/hZkgoQYus5dQoHw8oYrR4rKqNM.jpg", voteAverage: 8.8, releaseDate: "1999", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
    ]
    
    func loadAll() async {
        trending = allMovies
        nowPlaying = allMovies
        upcoming = allMovies
        topRated = allMovies
        popular = allMovies
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
