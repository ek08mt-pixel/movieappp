import SwiftUI

struct QuoteView: View {
    let movieId: Int
    @State private var detail: MovieDetail?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tagline = detail?.tagline, !tagline.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quote").font(.headline).foregroundColor(.white)
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
        }
        .task {
            detail = try? await APIService.shared.movieDetail(movieId: movieId)
        }
    }
}