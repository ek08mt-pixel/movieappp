import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if appState.favorites.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 50)).foregroundColor(.gray.opacity(0.5))
                        Text("Chưa có phim trong thư viện")
                            .foregroundColor(.gray).font(.headline)
                        Text("Thêm phim yêu thích để xem sau")
                            .foregroundColor(.gray.opacity(0.6)).font(.subheadline)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(appState.favorites) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        AsyncImage(url: movie.posterURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Rectangle().fill(Color.gray.opacity(0.1))
                                            }
                                        }
                                        .frame(width: 150, height: 225)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        
                                        Text(movie.title).font(.caption).fontWeight(.semibold).foregroundColor(.white).lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Thư viện")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
