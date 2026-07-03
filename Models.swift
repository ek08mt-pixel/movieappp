import Foundation

// MARK: - Movie
struct MovieResponse: Codable {
    let results: [Movie]
    let totalPages: Int?
    let page: Int?
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
        case page
    }
}

struct Movie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let genreIds: [Int]?
    let originalTitle: String?
    let popularity: Double?
    let voteCount: Int?
    let adult: Bool?
    let originalLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, adult, popularity
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case genreIds = "genre_ids"
        case originalTitle = "original_title"
        case voteCount = "vote_count"
        case originalLanguage = "original_language"
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }
    
    var ratingText: String { String(format: "%.1f", voteAverage) }
    
    var yearText: String {
        guard let date = releaseDate, date.count >= 4 else { return "N/A" }
        return String(date.prefix(4))
    }
    
    var voteCountFormatted: String {
        guard let count = voteCount else { return "0" }
        if count >= 1000 { return "\(count/1000)K" }
        return "\(count)"
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Movie, rhs: Movie) -> Bool { lhs.id == rhs.id }
}

// MARK: - Actor
struct ActorResponse: Codable {
    let cast: [Actor]
}

struct Actor: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let biography: String?
    let birthday: String?
    let placeOfBirth: String?
    let knownForDepartment: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, character, biography, birthday
        case profilePath = "profile_path"
        case placeOfBirth = "place_of_birth"
        case knownForDepartment = "known_for_department"
    }
    
    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(path)")
    }
}

struct ActorMoviesResponse: Codable {
    let cast: [Movie]
}

// MARK: - Others
struct GenreResponse: Codable {
    let genres: [Genre]
}

struct Genre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct VideoResponse: Codable {
    let results: [Video]
}

struct Video: Codable {
    let key: String
    let site: String
    let type: String
    let name: String?
}
struct Cinema: Identifiable {
    let id = UUID()
    let name: String
    let bookingURL: String
}

struct Movie: Identifiable {
    let id = UUID()
    let title: String
    // ... các thuộc tính khác của phim
    let cinemas: [Cinema] // Thêm dòng này vào model Movie của bạn
}
