import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2024
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Movie Timeline")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    
                    Text("Năm: \(Int(selectedYear))")
                        .font(.headline).foregroundColor(.orange)
                    
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .tint(.orange).padding(.horizontal)
                        .onChange(of: selectedYear) { _ in Task { await loadMovies() } }
                    
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }.padding(.horizontal)
                    }
                    
                    if movies.isEmpty && !isLoading {
                        Text("Không có phim").foregroundColor(.gray)
                    }
                    
                    Spacer()
                }.padding(.top)
            }
        }
        .task { await loadMovies() }
    }
    
    func loadMovies() async {
        isLoading = true
        do {
            movies = try await APIService.shared.discoverMovies(year: Int(selectedYear))
        } catch {
            movies = []
        }
        isLoading = false
    }
}