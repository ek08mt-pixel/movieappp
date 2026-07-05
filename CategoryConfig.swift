import Foundation

struct CategoryConfig: Identifiable {
    let id: Int
    let name: String
    let posterName: String
    let type: CategoryType
    let tmdbId: Int
    
    enum CategoryType {
        case studio
        case keyword
        case genre
    }
    
    static let allCategories: [CategoryConfig] = [
        CategoryConfig(id: 0, name: "Oscar", posterName: "poster_oscar", type: .keyword, tmdbId: 2959),
        CategoryConfig(id: 1, name: "Cannes", posterName: "poster_cannes", type: .keyword, tmdbId: 133278),
        CategoryConfig(id: 2, name: "IMDb Top", posterName: "poster_imdb", type: .keyword, tmdbId: 210024),
        CategoryConfig(id: 3, name: "Netflix", posterName: "poster_netflix", type: .studio, tmdbId: 213),
        CategoryConfig(id: 4, name: "Ghibli", posterName: "poster_ghibli", type: .studio, tmdbId: 103538),
        CategoryConfig(id: 5, name: "Marvel", posterName: "poster_marvel", type: .studio, tmdbId: 420),
        CategoryConfig(id: 6, name: "DC", posterName: "poster_dc", type: .studio, tmdbId: 429),
        CategoryConfig(id: 7, name: "Pixar", posterName: "poster_pixar", type: .studio, tmdbId: 3),
        CategoryConfig(id: 8, name: "Disney", posterName: "poster_disney", type: .studio, tmdbId: 2),
        CategoryConfig(id: 9, name: "A24", posterName: "poster_a24", type: .studio, tmdbId: 135334),
        CategoryConfig(id: 10, name: "Hàn Quốc", posterName: "poster_korean", type: .genre, tmdbId: 0),
        CategoryConfig(id: 11, name: "Nhật Bản", posterName: "poster_japanese", type: .genre, tmdbId: 0),
    ]
}