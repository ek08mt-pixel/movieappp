import SwiftUI

struct GuessMovieView: View {
    @State private var movie: Movie?
    @State private var blurredPoster: Bool = true
    @State private var showAnswer: Bool = false
    @State private var score: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Đoán phim qua Poster")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    
                    Text("Score: \(score)")
                        .font(.headline).foregroundColor(.orange)
                    
                    if let movie = movie {
                        ZStack {
                            CachedAsyncImage(url: movie.posterURL)
                                .frame(width: 250, height: 375)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .blur(radius: blurredPoster ? 30 : 0)
                                .animation(.easeInOut(duration: 0.5), value: blurredPoster)
                        }
                        
                        if showAnswer {
                            Text(movie.title)
                                .font(.title).fontWeight(.heavy).foregroundColor(.white)
                            Text(movie.overview)
                                .foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                        }
                        
                        HStack(spacing: 20) {
                            Button {
                                blurredPoster = false
                                showAnswer = true
                            } label: {
                                Text("Xem đáp án")
                                    .foregroundColor(.white).padding().background(Capsule().fill(.ultraThinMaterial))
                            }
                            
                            Button {
                                score += 1
                                loadNewMovie()
                            } label: {
                                Text("Tôi đoán đúng! +1")
                                    .foregroundColor(.black).padding().background(Capsule().fill(Color.green))
                            }
                            
                            Button {
                                loadNewMovie()
                            } label: {
                                Text("Phim khác")
                                    .foregroundColor(.white).padding().background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                    }
                }
            }
        }
        .task { loadNewMovie() }
    }
    
    func loadNewMovie() {
        blurredPoster = true
        showAnswer = false
        Task {
            do {
                let movies = try await APIService.shared.popular()
                movie = movies.randomElement()
            } catch {}
        }
    }
}