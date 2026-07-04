import SwiftUI

struct GuessMovieView: View {
    @State private var movie: Movie?
    @State private var options: [Movie] = []
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
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
                        .frame(width: 200, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .blur(radius: 25)
                    
                    if showResult {
                        Text(isCorrect ? "✅ Chính xác!" : "❌ Sai rồi!")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(movie.title)
                            .font(.title3).fontWeight(.heavy).foregroundColor(.white)
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(options) { option in
                            Button {
                                isCorrect = option.id == movie.id
                                showResult = true
                                if isCorrect { score += 1 }
                            } label: {
                                Text(option.title)
                                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(showResult && option.id == movie.id ? Color.green.opacity(0.3) : .ultraThinMaterial)
                                    )
                            }
                            .disabled(showResult)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button {
                        loadNewMovie()
                    } label: {
                        Text("Phim khác")
                            .font(.caption).foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .task { loadNewMovie() }
    }
    
    func loadNewMovie() {
        showResult = false
        Task {
            do {
                let movies = try await APIService.shared.popular().filter { !($0.adult ?? false) }
                if let correct = movies.randomElement() {
                    movie = correct
                    var opts = Array(movies.shuffled().prefix(4))
                    if !opts.contains(where: { $0.id == correct.id }) {
                        opts[Int.random(in: 0..<4)] = correct
                    }
                    options = opts
                }
            } catch {}
        }
    }
}