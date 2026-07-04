import SwiftUI

struct QuoteView: View {
    let movieId: Int
    @State private var detail: MovieDetail?
    
    let fakeQuotes = [
        "I'm the king of the world!",
        "May the Force be with you.",
        "Why so serious?",
        "Here's looking at you, kid.",
        "I'll be back.",
        "To infinity and beyond!",
        "Keep your friends close, but your enemies closer.",
        "Just keep swimming.",
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tagline = detail?.tagline, !tagline.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quote nổi tiếng").font(.headline).foregroundColor(.white)
                    Text("\"\(tagline)\"").font(.title3).italic().foregroundColor(.orange)
                }
            }
            
            if let runtime = detail?.runtime {
                HStack {
                    Image(systemName: "clock.fill").foregroundColor(.gray)
                    Text("\(runtime) phút").foregroundColor(.gray).font(.subheadline)
                }
            }
            
            if let genres = detail?.genres, !genres.isEmpty {
                HStack {
                    Image(systemName: "film.fill").foregroundColor(.gray)
                    Text(genres.map { $0.name }.joined(separator: ", ")).foregroundColor(.gray).font(.subheadline)
                }
            }
            
            // Seasons
            VStack(alignment: .leading, spacing: 8) {
                Text("Seasons").font(.headline).foregroundColor(.white).padding(.top, 8)
                
                ForEach(1...5, id: \.self) { season in
                    HStack {
                        Text("Season \(season)")
                            .foregroundColor(.white).font(.subheadline).fontWeight(.medium)
                        Spacer()
                        Text("\(Int.random(in: 6...13)) episodes")
                            .foregroundColor(.gray).font(.caption)
                        Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
                    }
                    .padding(.vertical, 4)
                    
                    if season < 5 {
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
            
            Text("Quotes hay").font(.headline).foregroundColor(.white).padding(.top, 8)
            
            ForEach(fakeQuotes.prefix(5), id: \.self) { quote in
                HStack(alignment: .top, spacing: 8) {
                    Text("\"").font(.title).foregroundColor(.orange)
                    Text(quote).foregroundColor(.white).font(.subheadline).italic()
                    Text("\"").font(.title).foregroundColor(.orange)
                }
            }
        }
        .task {
            detail = try? await APIService.shared.movieDetail(movieId: movieId)
        }
    }
}