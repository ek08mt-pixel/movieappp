import SwiftUI

struct MovieSection: View {
    let title: String
    let movies: [Movie]
    let style: CardStyle
    
    var body: some View {
        if movies.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    NavigationLink(destination: MovieListView(title: title, movies: movies)) {
                        Text("Xem tất cả")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieCard(movie: movie, style: style)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
    }
}
