import SwiftUI

struct MovieOfDayView: View {
    @State private var movie: Movie?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let movie = movie {
                    ScrollView {
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottomLeading) {
                                CachedAsyncImage(url: movie.backdropURL)
                                    .frame(height: 500).clipped()
                                LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Movie of the Day")
                                        .font(.caption).foregroundColor(.orange).fontWeight(.bold)
                                    Text(movie.title)
                                        .font(.system(size: 32, weight: .heavy)).foregroundColor(.white)
                                    HStack { Image(systemName: "star.fill").foregroundColor(.yellow); Text(movie.ratingText).foregroundColor(.white) }
                                    Text(movie.overview).foregroundColor(.gray).lineLimit(3)
                                    
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        Text("Xem chi tiết").font(.subheadline).fontWeight(.bold)
                                            .foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 10)
                                            .background(Color.orange).clipShape(Capsule())
                                    }
                                }.padding()
                            }
                        }
                    }
                } else {
                    ProgressView().tint(.white)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task {
            do {
                let movies = try await APIService.shared.popular()
                let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                let index = dayOfYear % movies.count
                movie = movies[index]
            } catch {}
        }
    }
}