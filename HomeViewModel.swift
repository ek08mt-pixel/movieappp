import Foundation

struct OnThisDayItem { let movie: Movie; let subtitle: String }

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var trendingTV: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var anime: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var movieOfDay: Movie?
    @Published var onThisDayMovie: OnThisDayItem?
    @Published var isLoading = false
    
    init() {
        // Preload ngay khi init để có data sớm nhất
        Task { await loadAll() }
    }
    
    func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Ưu tiên 1: Load trending + genres trước (hiển thị banner + thể loại ngay)
        async let trendingTask = APIService.shared.trending24h()
        async let genresTask = APIService.shared.genres()
        
        if let trending = try? await trendingTask {
            trending24h = trending
            movieOfDay = trending.randomElement()
        }
        genres = (try? await genresTask) ?? []
        
        // Ưu tiên 2: Trending TV (section dưới banner)
        Task { [weak self] in
            guard let self = self else { return }
            let tv = await self.loadTrendingTVPages()
            await MainActor.run { self.trendingTV = tv }
        }
        
        // Ưu tiên 3: Các section còn lại - load song song nhưng không block UI
        Task {
            async let nowPlayingTask = APIService.shared.nowPlaying()
            async let topRatedTask = APIService.shared.topRated()
            async let koreanTask = APIService.shared.koreanMovies()
            async let usukTask = APIService.shared.usukMovies()
            
            let np = try? await nowPlayingTask
            let tr = try? await topRatedTask
            let ko = try? await koreanTask
            let us = try? await usukTask
            
            await MainActor.run {
                if let np = np { self.nowPlaying = np }
                if let tr = tr { self.topRated = tr }
                if let ko = ko { self.korean = ko }
                if let us = us { self.usuk = us }
            }
        }
        
        // Ưu tiên 4: Các section phụ
        Task {
            async let upcomingTask = APIService.shared.upcoming()
            async let japaneseTask = APIService.shared.japaneseMovies()
            async let vietnameseTask = APIService.shared.vietnameseMovies()
            async let animeTask = APIService.shared.animeMovies()
            
            let up = try? await upcomingTask
            let ja = try? await japaneseTask
            let vi = try? await vietnameseTask
            let an = try? await animeTask
            
            await MainActor.run {
                if let up = up { self.upcoming = up }
                if let ja = ja { self.japanese = ja }
                if let vi = vi { self.vietnamese = vi }
                if let an = an { self.anime = an }
            }
        }
        
        // OnThisDay - nhẹ, load cuối
        onThisDayMovie = await loadOnThisDay()
        
        isLoading = false
    }
    
    private func loadOnThisDay() async -> OnThisDayItem? {
        let today = Date()
        let fmt = DateFormatter(); fmt.dateFormat = "MM-dd"
        let md = fmt.string(from: today)
        let thisYear = Calendar.current.component(.year, from: today)
        
        let famousMovies: [(title: String, date: String, year: Int, tmdbId: Int, subtitle: String)] = [
            ("The Dark Knight", "07-18", 2008, 155, "Ra mắt cách đây \(thisYear-2008) năm"),
            ("Inception", "07-16", 2010, 27205, "Ra mắt cách đây \(thisYear-2010) năm"),
            ("Parasite", "05-30", 2019, 496243, "Đoạt Oscar Phim hay nhất 2020"),
            ("Interstellar", "11-07", 2014, 157336, "Ra mắt cách đây \(thisYear-2014) năm"),
            ("Joker", "10-04", 2019, 475557, "Ra mắt cách đây \(thisYear-2019) năm"),
            ("Avengers: Endgame", "04-26", 2019, 299534, "Ra mắt cách đây \(thisYear-2019) năm"),
            ("Titanic", "12-19", 1997, 597, "Ra mắt cách đây \(thisYear-1997) năm"),
            ("The Matrix", "03-31", 1999, 603, "Ra mắt cách đây \(thisYear-1999) năm"),
            ("Pulp Fiction", "10-14", 1994, 680, "Ra mắt cách đây \(thisYear-1994) năm"),
            ("Fight Club", "10-15", 1999, 550, "Ra mắt cách đây \(thisYear-1999) năm"),
            ("Forrest Gump", "07-06", 1994, 13, "Ra mắt cách đây \(thisYear-1994) năm"),
            ("The Shawshank Redemption", "09-23", 1994, 278, "Ra mắt cách đây \(thisYear-1994) năm"),
            ("Spirited Away", "07-20", 2001, 129, "Ra mắt cách đây \(thisYear-2001) năm"),
            ("Your Name", "08-26", 2016, 372058, "Ra mắt cách đây \(thisYear-2016) năm"),
            ("Oldboy", "11-21", 2003, 670, "Ra mắt cách đây \(thisYear-2003) năm"),
            ("Amélie", "04-25", 2001, 194, "Ra mắt cách đây \(thisYear-2001) năm"),
            ("The Godfather", "03-24", 1972, 238, "Ra mắt cách đây \(thisYear-1972) năm"),
            ("Schindler's List", "12-15", 1993, 424, "Ra mắt cách đây \(thisYear-1993) năm"),
            ("The Lion King", "06-24", 1994, 8587, "Ra mắt cách đây \(thisYear-1994) năm"),
            ("Back to the Future", "07-03", 1985, 105, "Ra mắt cách đây \(thisYear-1985) năm"),
            ("Jurassic Park", "06-11", 1993, 329, "Ra mắt cách đây \(thisYear-1993) năm"),
            ("E.T.", "06-11", 1982, 601, "Ra mắt cách đây \(thisYear-1982) năm"),
            ("Gladiator", "05-05", 2000, 98, "Ra mắt cách đây \(thisYear-2000) năm"),
            ("The Silence of the Lambs", "02-14", 1991, 274, "Ra mắt cách đây \(thisYear-1991) năm"),
            ("Saving Private Ryan", "07-24", 1998, 857, "Ra mắt cách đây \(thisYear-1998) năm"),
            ("The Prestige", "10-20", 2006, 1124, "Ra mắt cách đây \(thisYear-2006) năm"),
            ("Django Unchained", "12-25", 2012, 68718, "Ra mắt cách đây \(thisYear-2012) năm"),
            ("La La Land", "12-09", 2016, 313369, "Ra mắt cách đây \(thisYear-2016) năm"),
            ("Get Out", "02-24", 2017, 419430, "Ra mắt cách đây \(thisYear-2017) năm"),
            ("Mad Max: Fury Road", "05-15", 2015, 76341, "Ra mắt cách đây \(thisYear-2015) năm"),
            ("The Social Network", "10-01", 2010, 37799, "Ra mắt cách đây \(thisYear-2010) năm")
        ]
        
        let matched = famousMovies.filter { $0.date == md }
        let pick = matched.randomElement() ?? famousMovies.randomElement()!
        
        let movie = Movie(id: pick.tmdbId, title: pick.title, overview: "", posterPath: nil, backdropPath: nil, voteAverage: 0, releaseDate: "\(pick.year)", genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: "movie")
        return OnThisDayItem(movie: movie, subtitle: pick.subtitle)
    }
    
    private func loadTrendingTVPages() async -> [Movie] {
        var allTV: [Movie] = []
        // Giảm xuống 1 page, mỗi page 20 item là đủ hiển thị
        let urlString = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&page=1"
        guard let url = URL(string: urlString) else { return allTV }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct TVResponse: Codable { let results: [TVResult] }
            struct TVResult: Codable {
                let id: Int; let name: String?; let overview: String
                let poster_path: String?; let backdrop_path: String?
                let vote_average: Double; let first_air_date: String?
                let genre_ids: [Int]?; let popularity: Double?
                let vote_count: Int?; let original_language: String?
            }
            let response = try JSONDecoder().decode(TVResponse.self, from: data)
            let tvShows = response.results.map { tv in
                Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                      posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                      voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                      genreIds: tv.genre_ids, originalTitle: tv.name,
                      popularity: tv.popularity, voteCount: tv.vote_count,
                      adult: false, originalLanguage: tv.original_language, mediaType: "tv")
            }
            allTV.append(contentsOf: tvShows)
        } catch {}
        return allTV
    }
}