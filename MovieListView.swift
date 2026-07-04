import SwiftUI

struct MovieListView: View {
    let title: String
    let movies: [Movie]
    
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 5) {
                                AsyncImage(url: movie.posterURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle().fill(Color.gray.opacity(0.08))
                                    }
                                }
                                .frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(movie.title).font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white).lineLimit(2).frame(width: 120)
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                    Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                }.frame(width: 120)
                            }
                        }
                    }
                }.padding()
            }
        }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
