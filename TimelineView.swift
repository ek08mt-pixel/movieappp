import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2024
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Movie Timeline")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    
                    Text("Năm: \(Int(selectedYear))")
                        .font(.headline).foregroundColor(.orange)
                    
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .tint(.orange)
                        .padding(.horizontal)
                        .onChange(of: selectedYear) { _ in
                            Task { await loadMovies() }
                        }
                    
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(movies.prefix(20)) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 5) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .frame(width: 120, height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(movie.title)
                                            .font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 120)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                    }
                    
                    if movies.isEmpty && !isLoading {
                        Text("Không có phim cho năm này").foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.top)
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