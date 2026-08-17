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
                    allData = (try? await APIService.shared.discoverMovies(lang: "en", sortBy: "popularity.desc")) ?? initial
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
}