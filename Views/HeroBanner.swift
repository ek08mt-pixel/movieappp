import SwiftUI

struct HeroBanner: View {
    let movies: [Movie]
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(movies.prefix(8).enumerated()), id: \.element.id) { index, movie in
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: movie.backdropURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 500)
                        .clipped()
                        
                        LinearGradient(
                            colors: [.clear, .clear, .black],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                Text(movie.ratingText).foregroundColor(.white).font(.caption).fontWeight(.bold)
                                Text("•").foregroundColor(.gray)
                                Text(movie.yearText).foregroundColor(.gray).font(.caption)
                                Text("•").foregroundColor(.gray)
                                Text(movie.voteCountFormatted + " votes").foregroundColor(.gray).font(.caption)
                            }
                            
                            Text(movie.title)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(movie.overview)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                            
                            HStack {
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    Label("Xem Trailer", systemImage: "play.fill")
                                        .font(.subheadline).fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20).padding(.vertical, 10)
                                        .background(Color.orange)
                                        .cornerRadius(20)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(24)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 500)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % min(movies.count, 8)
            }
        }
    }
}
