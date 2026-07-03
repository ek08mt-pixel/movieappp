import SwiftUI

struct MovieListView: View {
    let title: String
    let movies: [Movie]
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 14)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            MovieCard(movie: movie, style: .poster)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
