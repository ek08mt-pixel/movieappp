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
    
    let asianMovies: [Movie] = [
        Movie(id: 496243, title: "Parasite", overview: "Gia đình Kim nghèo khó dần thâm nhập vào gia đình Park giàu có bằng cách giả làm người giúp việc.", posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", backdropPath: "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: "기생충", popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 245891, title: "John Wick", overview: "Một sát thủ về hưu trở lại để trả thù sau khi bọn côn đồ giết chó của anh ta.", posterPath: "/fZPSd91yGE9fCcCe6OoQr6E3Bev.jpg", backdropPath: "/5vHssVvEH6hFA5gG6JqPwu0aKNz.jpg", voteAverage: 7.4, releaseDate: "2014", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 278, title: "The Shawshank Redemption", overview: "Một chủ ngân hàng bị kết án oan phải tìm cách vượt ngục khỏi nhà tù Shawshank.", posterPath: "/9O7gLzmreU0nGkIB6K3BsJbzvNv.jpg", backdropPath: "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg", voteAverage: 8.7, releaseDate: "1994", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 238, title: "The Godfather", overview: "Bố già Vito Corleone và con trai Michael điều hành đế chế mafia ở New York.", posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg", backdropPath: "/tmU7GeKVybMWFButWEGl2M4GeiP.jpg", voteAverage: 8.7, releaseDate: "1972", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 424, title: "Schindler's List", overview: "Oskar Schindler cứu hơn 1000 người Do Thái khỏi Holocaust trong Thế chiến II.", posterPath: "/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg", backdropPath: "/zb6fMjjCXJty3Q1A6MdCD0HCmRZ.jpg", voteAverage: 8.6, releaseDate: "1993", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
    ]
    
    let usukMovies: [Movie] = [
        Movie(id: 299534, title: "Avengers: Endgame", overview: "Sau cú búng tay của Thanos, các Avengers còn lại phải tập hợp để cứu vũ trụ.", posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", backdropPath: "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", voteAverage: 8.5, releaseDate: "2019", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 634649, title: "Spider-Man: No Way Home", overview: "Peter Parker tìm đến Doctor Strange để khôi phục danh tính bí mật.", posterPath: "/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg", backdropPath: "/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg", voteAverage: 8.2, releaseDate: "2021", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 27205, title: "Inception", overview: "Dom Cobb là một tên trộm chuyên đánh cắp bí mật từ tiềm thức trong giấc mơ.", posterPath: "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", voteAverage: 8.8, releaseDate: "2010", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 155, title: "The Dark Knight", overview: "Batman phải đối mặt với Joker - kẻ gây hỗn loạn và tội ác ở Gotham.", posterPath: "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", backdropPath: "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", voteAverage: 9.0, releaseDate: "2008", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
        Movie(id: 157336, title: "Interstellar", overview: "Nhóm phi hành gia du hành qua lỗ sâu để tìm hành tinh mới cho nhân loại.", posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", backdropPath: "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", voteAverage: 8.6, releaseDate: "2014", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: nil, originalLanguage: nil),
    ]
    
    func loadAll() async {
        trending = usukMovies + asianMovies
        nowPlaying = usukMovies
        upcoming = asianMovies
        topRated = usukMovies + asianMovies
        popular = usukMovies + asianMovies
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
 