import SwiftUI

struct MovieListView: View {
    let title: String
    let movies: [Movie]
    var fixedQuery: String = ""
    
    @State private var allMovies: [Movie] = []
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var isLoading = false
    @State private var totalResults = 0
    
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var isYearQuery: Bool {
        Int(fixedQuery) != nil
    }
    
    var isCountryQuery: Bool {
        let countries = ["usuk", "korean", "japanese", "vietnamese", "china", "india", "thailand", "france", "uk", "australia", "mexico", "spain", "brazil", "russia", "germany", "italy", "canada", "sweden"]
        return countries.contains(fixedQuery.lowercased())
    }
    
    var isGenreQuery: Bool {
        let genres = ["Hành Động", "Hài Hước", "Cartoon Icons", "Tình Cảm", "Kinh Dị", "Giật Gân", "Bí Ẩn", "Khoa Học Viễn Tưởng", "Kỳ Ảo", "Gia Đình", "Chính Kịch", "Phiêu Lưu", "Âm Nhạc", "Võ Thuật", "Hình Sự", "Tâm Lý", "Lịch Sử", "Cổ Trang", "Sinh Tồn", "Zombie", "Siêu Anh Hùng", "Công Nghệ", "Thảm Họa", "Xuyên Không", "Học Đường", "Tài Liệu", "Truyền Hình", "Viễn Tây", "Thanh Xuân", "BL", "GL"]
        return genres.contains(fixedQuery)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Text(title)
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 80)
                            .id("top")
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(allMovies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        Text(movie.title)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                        }
                                    }
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if isLoading {
                            ProgressView().tint(.white)
                                .padding()
                        }
                        
                        if totalPages > 1 {
                            HStack(spacing: 8) {
                                ForEach(1...totalPages, id: \.self) { page in
                                    Button {
                                        currentPage = page
                                        Task {
                                            await loadPage(page)
                                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                                        }
                                    } label: {
                                        Text("\(page)")
                                            .font(.system(size: 12, weight: page == currentPage ? .bold : .regular))
                                            .foregroundColor(page == currentPage ? .black : .white)
                                            .frame(width: 28, height: 28)
                                            .background(page == currentPage ? .white : .white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                        
                        Spacer().frame(height: 50)
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            NotificationCenter.default.post(name: NSNotification.Name("HideTabBar"), object: nil)
        }
        .onDisappear {
            NotificationCenter.default.post(name: NSNotification.Name("ShowTabBar"), object: nil)
        }
        .task {
            await loadPage(1)
        }
    }
    
    func loadPage(_ page: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        var allData: [Movie] = []
        
        if isYearQuery, let year = Int(fixedQuery) {
            allData = (try? await APIService.shared.discoverMoviesByYear(year, page: page)) ?? []
        } else if isCountryQuery {
            let langMap: [String: String] = [
                "usuk": "en", "korean": "ko", "japanese": "ja",
                "vietnamese": "vi", "china": "zh", "india": "hi",
                "thailand": "th", "france": "fr", "uk": "en",
                "australia": "en", "mexico": "es", "spain": "es",
                "brazil": "pt", "russia": "ru", "germany": "de",
                "italy": "it", "canada": "en", "sweden": "sv"
            ]
            let lang = langMap[fixedQuery.lowercased()] ?? fixedQuery.lowercased()
            allData = (try? await APIService.shared.discoverMovies(lang: lang, sortBy: "popularity.desc", page: page)) ?? []
        } else if isGenreQuery {
    let genreId = genreID(for: fixedQuery)
    
    if fixedQuery == "Cartoon Icons" {
    allData = await loadCartoonMovies()
}
    if fixedQuery == "BL" {
        allData = (try? await APIService.shared.discoverMoviesWithKeyword(keywordId: 240305, page: page)) ?? []

         if allData.isEmpty {
            allData = (try? await APIService.shared.discoverMoviesWithKeyword(keywordId: 324058, page: page)) ?? []
        }
        if allData.isEmpty {
            allData = (try? await APIService.shared.discoverTVWithKeyword(keywordId: 240305, page: page)) ?? []
        }
    } else if fixedQuery == "GL" {
        allData = (try? await APIService.shared.discoverMoviesWithKeyword(keywordId: 315385, page: page)) ?? []
        if allData.isEmpty {
            allData = (try? await APIService.shared.discoverMoviesWithKeyword(keywordId: 319341, page: page)) ?? []
        }
        if allData.isEmpty {
            allData = (try? await APIService.shared.discoverTVWithKeyword(keywordId: 315385, page: page)) ?? []
        }
    } else if genreId > 0 {
        allData = (try? await APIService.shared.moviesByGenre(genreId: genreId, page: page)) ?? []
    } else {
        let keywordId = keywordID(for: fixedQuery)
        allData = (try? await APIService.shared.discoverMoviesWithKeyword(keywordId: keywordId, page: page)) ?? []
    }
        } else if fixedQuery == "Cartoon Icons" {
    allData = await loadCartoonMovies()
} else {
    let initial = movies.filter { !($0.adult ?? false) }
            
            if initial.count >= 30 {
                allData = initial
            } else {
                switch title {
                case "TV Shows":
                    allData = (try? await APIService.shared.trendingTV()) ?? initial
                case "24h qua":
                    allData = (try? await APIService.shared.trending24h()) ?? initial
                case "Đang chiếu rạp":
                    allData = (try? await APIService.shared.nowPlaying()) ?? initial
                case "Đánh giá cao":
                    allData = (try? await APIService.shared.topRated()) ?? initial
                case "Âu Mỹ":
                    allData = (try? await APIService.shared.usukMovies()) ?? initial
                case "Hàn Quốc":
                    allData = (try? await APIService.shared.koreanMovies()) ?? initial
                case "Nhật Bản":
                    allData = (try? await APIService.shared.japaneseMovies()) ?? initial
                case "Phim lẻ mới":
                    allData = (try? await APIService.shared.popular()) ?? initial
                case "Hoạt hình - Anime":
                    allData = (try? await APIService.shared.animeMovies()) ?? initial
                case "USUK Icons":
                    allData = initial
                default:
                    allData = initial
                }
            }
        }
        
        let filtered = allData.filter { !($0.adult ?? false) }
        await MainActor.run {
            if !filtered.isEmpty {
                let start = (page - 1) * 30
                let end = min(start + 30, filtered.count)
                if start < filtered.count {
                    allMovies = Array(filtered[start..<end])
                    totalPages = max(1, Int(ceil(Double(filtered.count) / 30.0)))
                } else {
                    allMovies = []
                }
            } else {
                allMovies = []
                totalPages = 1
            }
        }
    }
    
    func englishKeyword(for genre: String) -> String {
        let map: [String: String] = [
            "Hành Động": "action",
            "Hài Hước": "comedy",
            "Tình Cảm": "romance",
            "Kinh Dị": "horror",
            "Giật Gân": "thriller",
            "Bí Ẩn": "mystery",
            "Khoa Học Viễn Tưởng": "sci-fi",
            "Kỳ Ảo": "fantasy",
            "Gia Đình": "family",
            "Chính Kịch": "drama",
            "Phiêu Lưu": "adventure",
            "Âm Nhạc": "music",
            "Võ Thuật": "martial arts",
            "Hình Sự": "crime",
            "Tâm Lý": "psychological thriller",
            "Lịch Sử": "historical drama",
            "Cổ Trang": "period drama",
            "Sinh Tồn": "survival",
            "Zombie": "zombie",
            "Siêu Anh Hùng": "superhero",
            "Công Nghệ": "technology",
            "Thảm Họa": "disaster",
            "Xuyên Không": "time travel",
            "Học Đường": "high school",
            "Tài Liệu": "documentary",
            "Truyền Hình": "tv movie",
            "Talk Show": "talk show",
            "Thể Thao": "sports",
            "BL": "boy love",
            "GL": "girl love"
        ]
        return map[genre] ?? genre
    }
}
func genreID(for genre: String) -> Int {
        let map: [String: Int] = [
            "Hành Động": 28,
            "Hài Hước": 35,
            "Tình Cảm": 10749,
            "Kinh Dị": 27,
            "Giật Gân": 53,
            "Bí Ẩn": 9648,
            "Khoa Học Viễn Tưởng": 878,
            "Kỳ Ảo": 14,
            "Gia Đình": 10751,
            "Chính Kịch": 18,
            "Phiêu Lưu": 12,
            "Âm Nhạc": 10402,
            "Hình Sự": 80,
            "Lịch Sử": 36,
            "Tài Liệu": 99,
            "Truyền Hình": 10770,
            "Talk Show": 10767,
            "Thể Thao": 10770,
            "Võ Thuật": 0,
            "Tâm Lý": 0,
            "Cổ Trang": 0,
            "Sinh Tồn": 0,
            "Zombie": 0,
            "Siêu Anh Hùng": 0,
            "Công Nghệ": 0,
            "Thảm Họa": 0,
            "Xuyên Không": 0,
            "Học Đường": 0,
            "BL": 0,
            "GL": 0
        ]
        return map[genre] ?? 0
    }
    func keywordID(for genre: String) -> Int {
        let map: [String: Int] = [
            "BL": 167018,
            "GL": 167019,
            "LGBTQ+": 9672,
            "Zombie": 12377,
            "Sinh Tồn": 11322,
            "Xuyên Không": 9665,
            "Siêu Anh Hùng": 9663,
            "Học Đường": 13043,
            "Võ Thuật": 490,
            "Cổ Trang": 11322,
            "Tâm Lý": 11322,
            "Thảm Họa": 1538,
            "Công Nghệ": 4563
        ]
        return map[genre] ?? 0
    }
    func loadCartoonMovies() async -> [Movie] {
    let cartoonNames = [
        "The Powerpuff Girls", "Dexter's Laboratory", "Johnny Bravo", "Ed Edd n Eddy",
        "Samurai Jack", "Ben 10", "Teen Titans", "Courage the Cowardly Dog",
        "The Grim Adventures of Billy & Mandy", "Camp Lazlo", "Foster's Home for Imaginary Friends",
        "Chowder", "The Marvelous Misadventures of Flapjack", "Adventure Time", "Regular Show",
        "The Amazing World of Gumball", "Clarence", "Uncle Grandpa", "OK K.O.! Let's Be Heroes",
        "Craig of the Creek", "We Bare Bears", "Steven Universe", "Teen Titans Go!",
        "Phineas and Ferb", "Kim Possible", "Recess", "The Proud Family", "Lilo & Stitch: The Series",
        "The Emperor's New School", "American Dragon: Jake Long", "Gravity Falls", "The Owl House",
        "Amphibia", "Big City Greens", "Star vs. the Forces of Evil", "DuckTales",
        "Darkwing Duck", "Chip 'n Dale: Rescue Rangers", "TaleSpin", "Aladdin: The Series",
        "Hercules: The Animated Series", "The Little Mermaid: The Series", "Tarzan: The Series",
        "Jungle Cubs", "101 Dalmatians: The Series", "The Weekenders", "Fillmore!",
        "Lloyd in Space", "Dave the Barbarian", "Brandy & Mr. Whiskers", "The Replacements",
        "Yin Yang Yo!", "Mickey Mouse Clubhouse", "Sofia the First", "Doc McStuffins",
        "SpongeBob SquarePants", "The Fairly OddParents", "Danny Phantom", "Avatar: The Last Airbender",
        "Hey Arnold!", "Rugrats", "The Wild Thornberrys", "CatDog", "Rocko's Modern Life",
        "Aaahh!!! Real Monsters", "The Adventures of Jimmy Neutron: Boy Genius", "My Life as a Teenage Robot",
        "El Tigre: The Adventures of Manny Rivera", "The Mighty B!", "Bluey", "Dora the Explorer",
        "Paw Patrol", "Tom and Jerry", "Looney Tunes", "Scooby-Doo, Where Are You!",
        "The Flintstones", "The Jetsons", "Popeye the Sailor", "Teenage Mutant Ninja Turtles",
        "He-Man and the Masters of the Universe", "ThunderCats", "Transformers G1", "Family Guy"
    ]
    
    var movies: [Movie] = []
    for name in cartoonNames {
        if let results = try? await APIService.shared.searchTVShows(query: name, page: 1),
           let first = results.first {
            movies.append(first)
        }
    }
    return movies
}