import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if appState.favorites.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 50)).foregroundColor(.gray.opacity(0.4))
                        Text("Chưa có phim trong thư viện")
                            .foregroundColor(.gray).font(.headline)
                        Text("Thêm phim yêu thích để xem sau")
                            .foregroundColor(.gray.opacity(0.5)).font(.subheadline)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.favorites) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 5) {
                                        AsyncImage(url: movie.posterURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Rectangle().fill(Color.gray.opacity(0.08))
                                            }
                                        }
                                        .frame(width: 120, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Text(movie.title)
                                            .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                            .lineLimit(2).frame(width: 120)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
