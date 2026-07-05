import Foundation

struct MovieResponse: Codable {
    let results: [Movie]
    let totalPages: Int?
    let page: Int?
    enum CodingKeys: String, CodingKey { case results, page; case totalPages = "total_pages" }
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
    let mediaType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, adult, popularity
        case posterPath = "poster_path"; case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"; case releaseDate = "release_date"
        case genreIds = "genre_ids"; case originalTitle = "original_title"
        case voteCount = "vote_count"; case originalLanguage = "original_language"
        case mediaType = "media_type"
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
    var isTVShow: Bool { mediaType == "tv" }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Movie, rhs: Movie) -> Bool { lhs.id == rhs.id }
}

struct MovieDetail: Codable {
    let id: Int; let title: String; let overview: String?
    let posterPath: String?; let backdropPath: String?
    let voteAverage: Double?; let releaseDate: String?
    let runtime: Int?; let genres: [Genre]?; let tagline: String?
    let credits: Credits?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let seasons: [TVSeason]?
    let belongsToCollection: MovieCollection?
    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, tagline, genres, credits
        case posterPath = "poster_path"; case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"; case releaseDate = "release_date"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case seasons
        case belongsToCollection = "belongs_to_collection"
    }
}

struct MovieCollection: Codable, Identifiable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?
    enum CodingKeys: String, CodingKey {
        case id, name
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(path)")
    }
}

struct CollectionDetail: Codable {
    let id: Int
    let name: String
    let parts: [Movie]
}

struct TVSeason: Codable, Identifiable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?
    let overview: String?
    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
    }
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(path)")
    }
}

struct TVSeasonDetail: Codable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodes: [TVEpisode]
    enum CodingKeys: String, CodingKey {
        case id, name, episodes
        case seasonNumber = "season_number"
    }
}

struct TVEpisode: Codable, Identifiable {
    let id: Int
    let name: String
    let episodeNumber: Int
    let seasonNumber: Int
    let overview: String?
    let stillPath: String?
    let runtime: Int?
    let airDate: String?
    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case airDate = "air_date"
    }
    var stillURL: URL? {
        guard let path = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(path)")
    }
}

struct Credits: Codable { let cast: [Actor]; let crew: [Crew] }
struct Crew: Codable, Identifiable { let id: Int; let name: String; let job: String; let department: String }

struct ActorResponse: Codable { let cast: [Actor] }
struct Actor: Codable, Identifiable {
    let id: Int; let name: String; let character: String?
    let profilePath: String?; let biography: String?; let birthday: String?
    let placeOfBirth: String?; let knownForDepartment: String?
    enum CodingKeys: String, CodingKey {
        case id, name, character, biography, birthday
        case profilePath = "profile_path"; case placeOfBirth = "place_of_birth"
        case knownForDepartment = "known_for_department"
    }
    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(path)")
    }
}

struct ActorMoviesResponse: Codable { let cast: [Movie] }
struct GenreResponse: Codable { let genres: [Genre] }
struct Genre: Codable, Identifiable { let id: Int; let name: String }
struct VideoResponse: Codable { let results: [Video] }
struct Video: Codable { let key: String; let site: String; let type: String; let name: String? }

struct SeasonInfo: Identifiable {
    let id: Int; let name: String; let episodeCount: Int; let posterURL: URL?
}