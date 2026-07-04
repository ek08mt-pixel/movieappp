import SwiftUI

struct GuessMovieView: View {
    @State private var movie: Movie?
    @State private var blurredPoster: Bool = true
    @State private var showAnswer: Bool = false
    @State private var score: Int = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Đoán phim qua Poster")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                
                Text("Score: \(score)")
                    .font(.headline).foregroundColor(.orange)
                
                if let movie = movie {
                    CachedAsyncImage(url: movie.posterURL)
                        .frame(width: 220, height: 330)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .blur(radius: blurredPoster ? 25 : 0)
                        .animation(.easeInOut(duration: 0.5), value: blurredPoster)
                    
                    if showAnswer {
                        Text(movie.title)
                            .font(.title).fontWeight(.heavy).foregroundColor(.white)
                        Text(movie.overview)
                            .foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal).lineLimit(3)
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            blurredPoster = false; showAnswer = true
                        } label: {
                            Text("Xem đáp án").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                        
                        Button {
                            score += 1; loadNewMovie()
                        } label: {
                            Text("Đoán đúng! +1").foregroundColor(.black).padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().fill(Color.green))
                        }
                        
                        Button { loadNewMovie() } label: {
                            Text("Phim khác").foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                    }
                    .font(.caption)
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .task { loadNewMovie() }
    }
    
    func loadNewMovie() {
        blurredPoster = true; showAnswer = false
        Task {
            do {
                let movies = try await APIService.shared.popular()
                movie = movies.filter { ($0.adult ?? false) == false }.randomElement()
            } catch {}
        }
    }
}