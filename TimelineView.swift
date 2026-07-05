import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2026
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").foregroundColor(.white).font(.system(size: 18, weight: .medium)) }
                    Spacer()
                    Text("Timeline").font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer().frame(width: 30)
                }.padding().padding(.top, 40)
                
                VStack(spacing: 4) {
                    Text("\(Int(selectedYear))").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .accentColor(.white)
                        .padding(.horizontal, 30)
                        .onChange(of: selectedYear) { _ in loadMovies() }
                }.padding(.bottom, 16)
                
                if isLoading { Spacer(); ProgressView().tint(.white); Spacer() }
                else if movies.isEmpty { Spacer(); Text("Không có phim").foregroundColor(.gray); Spacer() }
                else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8))
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
        .navigationBarHidden(true)
        .onAppear { loadMovies() }
    }
    
    func loadMovies() {
        isLoading = true
        Task { movies = (try? await APIService.shared.discoverMovies(year: Int(selectedYear))) ?? []; isLoading = false }
    }
}