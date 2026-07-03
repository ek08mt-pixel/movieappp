import SwiftUI

struct HomeView: View {
    // Đổi thành @StateObject để khởi tạo chuẩn xác
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    // Truy cập trực tiếp qua vm thay vì thông qua binding
                    ForEach(vm.nowPlayingMovies, id: \.id) { movie in
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
