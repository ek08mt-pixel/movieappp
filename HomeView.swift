import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    // Truy cập trực tiếp vào các thuộc tính của VM
                    ForEach(vm.nowPlayingMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack {
                                AsyncImage(url: movie.posterURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.1)
                                }
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text(movie.title)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
            .task {
                await vm.loadMovies()
            }
        }
    }
}
