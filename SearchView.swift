import SwiftUI

// MARK: - Category Data
struct CategoryData: Identifiable {
    let id: Int
    let title: String
    let query: String
    let posterURL: String
    let isStudio: Bool
    let studioId: Int?
    
    static let allCategories: [CategoryData] = [
        CategoryData(id: 0, title: "Marvel", query: "marvel", posterURL: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", isStudio: true, studioId: 420),
        CategoryData(id: 1, title: "DC", query: "dc", posterURL: "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", isStudio: true, studioId: 429),
        CategoryData(id: 2, title: "Hành động", query: "action", posterURL: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", isStudio: false, studioId: 28),
        CategoryData(id: 3, title: "Viễn tưởng", query: "sci fi", posterURL: "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", isStudio: false, studioId: 878),
        CategoryData(id: 4, title: "Kinh dị", query: "horror", posterURL: "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg", isStudio: false, studioId: 27),
        CategoryData(id: 5, title: "Hài", query: "comedy", posterURL: "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg", isStudio: false, studioId: 35),
    ]
}

// MARK: - SearchView
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private let resultColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm phim...", text: $vm.query).focused($focused).foregroundColor(.white)
                            .onChange(of: vm.query) { _ in Task { await vm.search() } }
                        if !vm.query.isEmpty { Button { vm.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                        if focused { Button("Đóng") { focused = false }.foregroundColor(.orange).font(.caption) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)).padding()
                    
                    if vm.query.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Tìm kiếm phổ biến")
                                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.horizontal)
                                
                                LazyVGrid(columns: categoryColumns, spacing: 12) {
                                    ForEach(CategoryData.allCategories) { category in
                                        NavigationLink(destination: CategoryResultView(category: category)) {
                                            CategoryCard(category: category)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                Text("Xu hướng")
                                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.horizontal)
                                
                                ForEach(Array(vm.trending.prefix(10).enumerated()), id: \.element.id) { i, movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            Text("\(i+1)").font(.system(size: 18, weight: .bold)).foregroundColor(.gray).frame(width: 30)
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                                                HStack { Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 10)); Text(movie.ratingText).foregroundColor(.gray).font(.system(size: 12)) }
                                            }
                                            Spacer()
                                        }.padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    } else if vm.results.isEmpty {
                        Spacer(); Text("Không tìm thấy").foregroundColor(.gray); Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: resultColumns, spacing: 16) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: {
                                        VStack(spacing: 4) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                            HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                                        }
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Tìm kiếm").navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        }
        .onAppear { focused = true; Task { await vm.loadTrending() } }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: CategoryData
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(category.posterURL)"))
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            
            Text(category.title)
                .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                .padding(.vertical, 4).padding(.horizontal, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
        }
    }
}

// MARK: - Category Result View (Gọi discover API, load nhiều trang)
struct CategoryResultView: View {
    let category: CategoryData
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var currentPage = 1
    @State private var hasMore = true
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading && movies.isEmpty {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 4) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(movie.title)
                                        .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                    }
                                }
                                .onAppear {
                                    if movie == movies.last && hasMore && !isLoading {
                                        Task { await loadMore() }
                                    }
                                }
                            }
                        }
                    }.padding(.horizontal)
                    
                    if isLoading { ProgressView().tint(.white).padding() }
                }
            }
        }
        .navigationTitle(category.title).navigationBarTitleDisplayMode(.inline)
        .task {
            movies = []
            currentPage = 1
            hasMore = true
            await loadMore()
        }
    }
    
    func loadMore() async {
        isLoading = true
        do {
            let newMovies: [Movie]
            if category.isStudio, let studioId = category.studioId {
                newMovies = try await APIService.shared.discoverByStudio(studioId: studioId, page: currentPage)
            } else if let genreId = category.studioId {
                newMovies = try await APIService.shared.moviesByGenre(genreId: genreId, page: currentPage)
            } else {
                newMovies = try await APIService.shared.search(query: category.query, page: currentPage)
            }
            
            await MainActor.run {
                if newMovies.isEmpty {
                    hasMore = false
                } else {
                    movies.append(contentsOf: newMovies)
                    currentPage += 1
                }
                isLoading = false
            }
        } catch {
            await MainActor.run { hasMore = false; isLoading = false }
        }
    }
}