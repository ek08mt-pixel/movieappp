 import SwiftUI

enum CardStyle {
    case poster
    case backdrop
}

struct MovieCard: View {
    let movie: Movie
    let style: CardStyle
    
    private var width: CGFloat { style == .poster ? 150 : 260 }
    private var height: CGFloat { style == .poster ? 225 : 150 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: style == .poster ? movie.posterURL : movie.backdropURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure(_):
                    Rectangle().fill(Color.gray.opacity(0.3))
                        .overlay(Image(systemName: "film").foregroundColor(.gray))
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.1))
                        .shimmer()
                @unknown default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: width, height: height)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            
            Text(movie.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: width)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(.yellow)
                Text(movie.ratingText).font(.caption2).foregroundColor(.gray)
                Spacer()
                Text(movie.yearText).font(.caption2).foregroundColor(.gray)
            }
            .frame(width: width)
        }
    }
}

struct MovieRow: View {
    let movie: Movie
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: movie.posterURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 120)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                    Text(movie.ratingText).foregroundColor(.gray).font(.caption)
                    Text("•").foregroundColor(.gray)
                    Text(movie.yearText).foregroundColor(.gray).font(.caption)
                }
                
                Text(movie.overview)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// Shimmer Effect
extension View {
    func shimmer() -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .offset(x: -200)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
        )
    }
}
