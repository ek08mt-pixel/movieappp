import SwiftUI

struct MovieListView: View {
    let title: String
    let movies: [Movie]
    var fixedQuery: String = ""
    
    @State private var allMovies: [Movie] = []
    @State private var currentPage = 1
    @State private var totalPages = 10
    @State private var isLoading = false
    @State private var hasMore = true
    
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
            
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    Text(title)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 80)
                    
                    // Grid phim
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
                    
                    // Phân trang
                    HStack(spacing: 12) {
                        Button {
                            if currentPage > 1 {
                                currentPage -= 1
                                Task { await loadPage(currentPage) }
                            }
                        } label: {
                            Text("< trước")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(currentPage > 1 ? .white : .gray.opacity(0.5))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(1...totalPages, id: \.self) { page in
                                    Button {
                                        currentPage = page
                                        Task { await loadPage(page) }
                                    } label: {
                                        Text("\(page)")
                                            .font(.system(size: 12, weight: page == currentPage ? .bold : .regular))
                                            .foregroundColor(page == currentPage ? .black : .white)
                                            .frame(width: 30, height: 30)
                                            .background(page == currentPage ? .white : .white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        
                        Button {
                            if currentPage < totalPages {
                                currentPage += 1
                                Task { await loadPage(currentPage) }
                            }
                        } label: {
                            Text("sau >")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(currentPage < totalPages ? .white : .gray.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.bottom, 50)
                }
            }
            
            // Nút back
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
            // Nếu có movies truyền vào thì dùng luôn
            let initialMovies = movies.filter { !($0.adult ?? false) }
            if !initialMovies.isEmpty {
                allMovies = Array(initialMovies.prefix(21))
            } else {
                await loadPage(1)
            }
        }
    }
    
    func loadPage(_ page: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        let newMovies: [Movie]?
        
        if isYearQuery, let year = Int(fixedQuery) {
            newMovies = try? await APIService.shared.discoverMoviesByYear(year, page: page)
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
            newMovies = try? await APIService.shared.discoverMovies(lang: lang, sortBy: "popularity.desc", page: page)
        } else {
            let q = fixedQuery.isEmpty ? title : fixedQuery
            newMovies = try? await APIService.shared.searchMovies(query: q, page: page)
        }
        
        if let new = newMovies, !new.isEmpty {
            let filtered = new.filter { !($0.adult ?? false) }
            await MainActor.run {
                allMovies = Array(filtered.prefix(21))
            }
        } else {
            await MainActor.run {
                allMovies = []
            }
        }
    }
}