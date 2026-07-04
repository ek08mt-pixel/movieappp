import SwiftUI

struct GuessMovieView: View {
    @State private var movie: Movie?
    @State private var options: [Movie] = []
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var score = 0
    @State private var usedMovieIds: Set<Int> = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Đoán phim qua Poster")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white).padding(.top, 20)
                    
                    Text("Score: \(score)")
                        .font(.headline).foregroundColor(.orange)
                    
                    if isLoading {
                        ProgressView().tint(.white).padding(.vertical, 100)
                    } else if let movie = movie {
                        CachedAsyncImage(url: movie.posterURL)
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(width: 180, height: 270)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .blur(radius: showResult ? 0 : 25)
                            .animation(.easeInOut(duration: 0.5), value: showResult)
                        
                        if showResult {
                            Text(isCorrect ? "✅ Chính xác!" : "❌ Sai rồi!")
                                .font(.title2).fontWeight(.bold)
                                .foregroundColor(isCorrect ? .green : .red)
                            
                            Text(movie.title)
                                .font(.title3).fontWeight(.heavy).foregroundColor(.white)
                            
                            Text(movie.overview)
                                .font(.caption).foregroundColor(.gray).lineLimit(3).padding(.horizontal)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                                Button {
                                    isCorrect = option.id == movie.id
                                    showResult = true
                                    if isCorrect { score += 1 }
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(["A", "B", "C", "D"][index])
                                            .font(.caption).fontWeight(.bold).foregroundColor(.orange).frame(width: 20)
                                        Text(option.title)
                                            .font(.caption).fontWeight(.medium).foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(showResult && option.id == movie.id
                                                  ? AnyShapeStyle(Color.green.opacity(0.3))
                                                  : AnyShapeStyle(.ultraThinMaterial))
                                    )
                                }.disabled(showResult)
                            }
                        }.padding(.horizontal)
                        
                        Button { loadNewMovie() } label: {
                            HStack { Image(systemName: "arrow.clockwise"); Text("Phim khác") }
                                .font(.caption).foregroundColor(.white)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                    }
                    Spacer().frame(height: 120)
                }
            }
        }
        .task { loadNewMovie() }
    }
    
    func loadNewMovie() {
        isLoading = true
        showResult = false
        movie = nil
        options = []
        
        Task {
            let movies = (try? await APIService.shared.popular())?.filter { !($0.adult ?? false) && !usedMovieIds.contains($0.id) } ?? []
            
            if let correct = movies.randomElement() {
                usedMovieIds.insert(correct.id)
                var opts = Array(movies.filter { $0.id != correct.id }.shuffled().prefix(3))
                opts.append(correct)
                let finalOpts = opts.shuffled()
                
                await MainActor.run {
                    movie = correct
                    options = finalOpts
                    isLoading = false
                }
            } else {
                usedMovieIds.removeAll()
                await MainActor.run { isLoading = false }
                loadNewMovie()
            }
        }
    }
}