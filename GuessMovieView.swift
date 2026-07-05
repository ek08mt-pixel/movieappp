import SwiftUI

struct GuessMovieView: View {
    @State private var movie: Movie?
    @State private var showHint = false
    @State private var guessed = false
    @State private var inputText = ""
    @State private var message = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(.white).font(.system(size: 18, weight: .medium))
                    }
                    Spacer()
                    Text("Guess Movie").font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Button {
                        loadNewMovie()
                    } label: {
                        Image(systemName: "arrow.clockwise").foregroundColor(.white).font(.system(size: 18))
                    }
                }.padding()
                
                Spacer()
                
                if let movie = movie {
                    VStack(spacing: 20) {
                        CachedAsyncImage(url: movie.backdropURL ?? movie.posterURL)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: 300, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .blur(radius: guessed ? 0 : 20)
                        
                        if showHint && !guessed {
                            VStack(spacing: 6) {
                                Text("Gợi ý:").font(.caption).foregroundColor(.white.opacity(0.6))
                                Text(movie.overview).font(.caption).foregroundColor(.white).lineLimit(4).multilineTextAlignment(.center)
                                Text("Năm: \(movie.yearText)").font(.caption).foregroundColor(.white.opacity(0.7))
                                Text("⭐ \(movie.ratingText)").font(.caption).foregroundColor(.yellow)
                            }.padding(.horizontal)
                        }
                        
                        if !guessed {
                            HStack(spacing: 8) {
                                TextField("Nhập tên phim...", text: $inputText)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                
                                Button("Đoán") {
                                    checkGuess(movie)
                                }
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Capsule().fill(.ultraThinMaterial))
                            }.padding(.horizontal, 30)
                            
                            Button("Xem gợi ý") {
                                withAnimation { showHint = true }
                            }
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                        }
                        
                        if !message.isEmpty {
                            Text(message)
                                .font(.caption).fontWeight(.medium)
                                .foregroundColor(message.contains("✅") ? .green : .white)
                                .padding()
                        }
                        
                        if guessed {
                            VStack(spacing: 8) {
                                Text(movie.title).font(.title3).fontWeight(.bold).foregroundColor(.white)
                                Text(movie.yearText).font(.caption).foregroundColor(.gray)
                                Text("⭐ \(movie.ratingText)").font(.caption).foregroundColor(.yellow)
                                Button("Phim mới") { loadNewMovie() }
                                    .font(.caption).foregroundColor(.white)
                                    .padding(.horizontal, 20).padding(.vertical, 8)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                    }
                } else {
                    ProgressView().tint(.white)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadNewMovie() }
    }
    
    func loadNewMovie() {
        guessed = false; showHint = false; inputText = ""; message = ""
        Task {
            let movies = (try? await APIService.shared.popular()) ?? []
            movie = movies.filter { !($0.adult ?? false) && !($0.overview.isEmpty) && ($0.popularity ?? 0) > 10 }.randomElement()
        }
    }
    
    func checkGuess(_ movie: Movie) {
        let guess = inputText.trimmingCharacters(in: .whitespaces).lowercased()
        let real = movie.title.lowercased()
        if guess == real {
            message = "✅ Chính xác!"
            guessed = true
        } else {
            message = "❌ Sai rồi, thử lại!"
        }
    }
}