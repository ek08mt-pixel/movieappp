import SwiftUI

struct QuoteView: View {
    let movieId: Int
    @State private var detail: MovieDetail?
    @State private var quotes: [String] = []
    
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
                    Text("Quote nổi tiếng")
                        .font(.headline).foregroundColor(.white)
                    Text("\"\(tagline)\"")
                        .font(.title3).italic().foregroundColor(.orange)
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
                    Text(genres.map { $0.name }.joined(separator: ", "))
                        .foregroundColor(.gray).font(.subheadline)
                }
            }
            
            Text("Quotes hay")
                .font(.headline).foregroundColor(.white).padding(.top, 8)
            
            ForEach(fakeQuotes.prefix(5), id: \.self) { quote in
                HStack(alignment: .top, spacing: 8) {
                    Text("\"")
                        .font(.title).foregroundColor(.orange)
                    Text(quote)
                        .foregroundColor(.white).font(.subheadline).italic()
                    Text("\"")
                        .font(.title).foregroundColor(.orange)
                }
            }
        }
        .task {
            detail = try? await APIService.shared.movieDetail(movieId: movieId)
        }
    }
}