import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2026
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(Int(selectedYear))").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .accentColor(.white)
                        .padding(.horizontal, 30)
                        .onChange(of: selectedYear) { _ in loadMovies() }
                }
                .padding(.top, 90)
                .padding(.bottom, 16)
                
                if isLoading { Spacer(); ProgressView().tint(.white); Spacer() }
                else if movies.isEmpty { Spacer(); Text("Không có phim").foregroundColor(.gray); Spacer() }
                else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                                    }
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .onAppear { loadMovies() }
    }
    
    func loadMovies() {
        isLoading = true
        Task { movies = (try? await APIService.shared.discoverMovies(year: Int(selectedYear))) ?? []; isLoading = false }
    }
}